# build.ps1

#$MAIN_SCRIPT = ".\install-template.ps1"
#$DEPLOYS_FOLDER = ".\deploys"
#$DEFAULT_DIST_FOLDER = ".\builds" # Carpeta por defecto si el deploy no especifica una

$MAIN_SCRIPT = Join-Path $PSScriptRoot "install-template.ps1"
$DEPLOYS_FOLDER = Join-Path $PSScriptRoot "deploys"
$DEFAULT_DIST_FOLDER = Join-Path $PSScriptRoot "builds"

# function Resolve-FullPath($path) {
#     return [System.IO.Path]::GetFullPath($path)
# }

function Resolve-FullPath($path)
{
    if([System.IO.Path]::IsPathRooted($path))
    {
        return [System.IO.Path]::GetFullPath($path)
    }

    return [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot $path))
}



function Get-ImportedModules($file, [hashtable]$visited) {
    $fullFile = Resolve-FullPath $file
    if ($visited.ContainsKey($fullFile)) { return @() }
    $visited[$fullFile] = $true

    $baseFolder = Split-Path $fullFile -Parent
    $content = Get-Content $fullFile
    $modules = @()

    foreach ($line in $content) {
        if ($line -match '^\s*Import-Module\s+"(.+?\.psm1)"') {
            $relative = $matches[1]
            if ($relative.StartsWith('$PSScriptRoot')) {
                $relative = $relative.Replace('$PSScriptRoot', $baseFolder)
                $modulePath = Resolve-FullPath $relative
            } else {
                $modulePath = Resolve-FullPath (Join-Path $baseFolder $relative)
            }
            $modules += Get-ImportedModules $modulePath $visited
            $modules += $modulePath
        }
    }
    return $modules
}

# Validaciones de entorno
if (!(Test-Path $MAIN_SCRIPT)) { throw "No existe el script principal: $MAIN_SCRIPT" }
if (!(Test-Path $DEPLOYS_FOLDER)) { throw "No existe la carpeta de deploys: $DEPLOYS_FOLDER" }
if (!(Test-Path $DEFAULT_DIST_FOLDER)) { New-Item -ItemType Directory -Path $DEFAULT_DIST_FOLDER | Out-Null }

# 1. Resolver modulos compartidos
$visited = @{}
$modules = Get-ImportedModules $MAIN_SCRIPT $visited | Select-Object -Unique

# Leemos el template como un string unico
$templateRaw = Get-Content $MAIN_SCRIPT -Raw
$templateRaw = $templateRaw -replace '(?m)^\s*Import-Module\s+.*$', ''

$wizardSuffix = ""
if ($templateRaw -match '\$WIZARD_MODE\s*=\s*["''](.+?)["'']') {
    $wizardSuffix = $matches[1]
}

# 2. Iterar sobre cada archivo de configuracion en .\deploys
$deployFiles = Get-ChildItem -Path $DEPLOYS_FOLDER -Filter "*.ps1"

foreach ($deployFile in $deployFiles) {
    $deployName = $deployFile.BaseName
    Write-Host "Compilando instalador para: $deployName..." -ForegroundColor Cyan
    
    $deployConfig = Get-Content $deployFile.FullName -Raw
    
    # --- DETECTAR RUTA DE SALIDA PERSONALIZADA ---
    $customDistFolder = $DEFAULT_DIST_FOLDER
    if ($deployConfig -match '\$OUTPUT_PATH\s*=\s*["''](.+?)["'']') {
        $customDistFolder = $matches[1]
        
        # Si la ruta es relativa (ej: ".\mis-builds"), la resuelve respecto a la raiz del proyecto
        if ($customDistFolder.StartsWith(".")) {
            $customDistFolder = Resolve-FullPath (Join-Path $PSScriptRoot $customDistFolder)
        }
        
        # Crear la carpeta si no existe
        if (!(Test-Path $customDistFolder)) {
            New-Item -ItemType Directory -Path $customDistFolder -Force | Out-Null
            Write-Host "Creado directorio personalizado: $customDistFolder" -ForegroundColor DarkGray
        }
    }

    # --- PROCESAR DEPLOY COMPLETO ---
    # El deploy se inyecta entero, como si fuera un include.
    # No se parsean hooks con regex para no romper funciones con llaves internas.

    $firstPlaceholderContent = @"

# --- INICIO INYECCION CONFIG DEPLOY: $deployName ---
$deployConfig
# --- FIN INYECCION CONFIG DEPLOY ---
"@

    # --- PROCESAR SEGUNDO PLACEHOLDER: MODULOS ---
    $modulesBlock = "`r`n# --- MODULOS E INFRAESTRUCTURA COMPACTADOS ---`r`n"
    foreach ($module in $modules) {
        $modulesBlock += "`r`n# ================= MODULE: $(Split-Path $module -Leaf) =================`r`n"
        $moduleContent = Get-Content $module -Raw
        $moduleContent = $moduleContent -replace '(?m)^\s*Import-Module\s+.*$', ''
        $moduleContent = $moduleContent -replace '(?m)^\s*Export-ModuleMember\s+.*$', ''
        $modulesBlock += $moduleContent + "`r`n"
    }

    # --- ARMAR EL ROMPECABEZAS FINAL ---
    $finalScriptContent = $templateRaw.Replace('#_DEPLOY_CONFIG_PLACEHOLDER_', $firstPlaceholderContent)
    $finalScriptContent = $finalScriptContent.Replace('#_MODULES_PLACEHOLDER_', $modulesBlock)

    $header = @"
# ==================================================
# Archivo generado automaticamente para: $deployName
# No editar a mano
# ==================================================

"@
    $finalScriptContent = $header + $finalScriptContent

    # --- GUARDAR SCRIPT FINAL EN LA RUTA DETECTADA ---
    $outFile = Join-Path $customDistFolder "install-$deployName.ps1"
    Set-Content -Path $outFile -Value $finalScriptContent -Encoding UTF8
    Write-Host "Generado con exito: $outFile" -ForegroundColor Green

    if ($wizardSuffix) {
        $clonFile = Join-Path $customDistFolder "install-$deployName$wizardSuffix"
        Copy-Item -Path $outFile -Destination $clonFile -Force
        Write-Host "Generado clon inteligente: $clonFile" -ForegroundColor Yellow
    }
    Write-Host ""
}

Write-Host "Sufijo detectado: $wizardSuffix"