# ==================================================
# Archivo generado automaticamente para: eclipse
# No editar a mano
# ==================================================










# +---------+------------------------------------------------------------------+
# | DEPLOY  | Cambiar aqui para configurara cada script portable               |
# +---------+------------------------------------------------------------------+


# --- INICIO INYECCION CONFIG DEPLOY: eclipse ---
# +---------+------------------------------------------------------------------+
# | DEPLOY  | Cambiar aqui para configurara cada script portable               |
# +---------+------------------------------------------------------------------+

# Espacio inicial requerido por ubicaciÃ³n
$FREESPACE_CACHE = 2
$FREESPACE_DRIVE = 3

# portable
$PORTABLE_DESCRIPTION = "Eclipse STS (portable) for Java"
$PORTABLE_DRIVE = "C:"
$PORTABLE_PKGNAME = "java64"
$PORTABLE_HOME = "$PORTABLE_DRIVE\Java64"
$PORTABLE_MAINPROC = "$PORTABLE_HOME\RunEclipse.bat"
$PORTABLE_ARGLIST = "$PORTABLE_DRIVE\"
$PORTABLE_BACKUPPATHS = @("$PORTABLE_HOME\Workspace")

# Url para descargar el archivo (apunta a manifest.json de desarrollo)
$MANIFEST_URL = "https://drive.google.com/uc?export=download&id=18AlgTysKYeY7vsJTyNbH1CvzHACMnwPm"


$targetPath = "$PORTABLE_HOME\eclipse\SpringToolSuite4.exe"
$SHORTCUT = [PSCustomObject]@{ 
    Name = "eclipse"
    TargetPath       = $targetPath
    Arguments        = ""
    WorkingDirectory = $PORTABLE_HOME
    Description      = "Ejecuta Eclipse Spring Tool Suite"
    IconLocation     = "$targetPath,0"
    WindowStyle      = 1
}


# --- FIN INYECCION CONFIG DEPLOY ---

# +---------+------------------------------------------------------------------+
# | GENERAL | Cambiar aqui para configurar el funcionamiento general           |
# +---------+------------------------------------------------------------------+

$ENVIRONMENT = "prod"

# sufijo que da acceso al instalador inteligente
$WIZARD_MODE = "-wiz.ps1"

# Carpetas del usuario
$DOWNLOAD_FOLDER = "$env:USERPROFILE\Downloads"
$DESKTOP_FOLDER = "$env:USERPROFILE\Desktop"
$USER_FOLDER = $env:USERPROFILE
$CURRENT_FOLDER = "."

# de voy a buscar el archivo
$SEARCH_FOLDERS = @($DOWNLOAD_FOLDER, $DESKTOP_FOLDER, $CURRENT_FOLDER)

# Raiz de los cache 
$CACHE_ROOT = "$env:USERPROFILE\temp\.cache\$PORTABLE_PKGNAME"
$TOOLS_ROOT = "$env:USERPROFILE\temp\tools"

function main()
{
    # hook inicial
    beforeScriptHook $DOWNLOAD_FOLDER $DESKTOP_FOLDER $USER_FOLDER $SEARCH_FOLDERS $CACHE_ROOT $TOOLS_ROOT

    #deshabilito restriccion de scripts para el usuario
    Set-ExecutionPolicy Bypass -Scope CurrentUser

    #presentaciÃ³n
    cStep "Comenzando instalacion."
    cInfo "  - $PORTABLE_DESCRIPTION."

    # veo quÃ© versiÃ³n local tengo instalada (si la tengo)
    cStep "Verificando existencia de cache local."
    $localVer = portableReadCacheVersion $CACHE_ROOT

    # el usuario escoge el disco
    $driveOk = mainObtenerDiscoInstall $PORTABLE_PKGNAME $PORTABLE_DRIVE $FREESPACE_DRIVE 
    deployRefreshVariables $driveOk
    #mainActualizarConfig $driveOk

    #ASSERT
    # Verifico condiciones iniciales de espacio y bloqueo cruzado
    cStep "Verificando condiciones iniciales."    
    mainAsegurarCondicionesInicial $FREESPACE_CACHE $FREESPACE_DRIVE $PORTABLE_HOME $USER_FOLDER
    
    # verifico actualizaciones disponibles
    cStep "Verificando actualizaciones."
    $remote = portableReadManifest $MANIFEST_URL $ENVIRONMENT

    if( $null -ne $remote )
    {
        portableEvalUpdateType $localVer $remote.ver 
        portableCheckForScriptUpdates $remote 
    }
    
    $hasLocal  = $null -ne $localVer
    $hasRemote = $null -ne $remote

    $ver = $null

    # local y remota
    if($hasLocal -and $hasRemote)
    {
        # son distintas 
        if( $localVer -ne $remote.ver )
        {
            # pregunto si desea restaurar (0) o actualizar (1)
            $op = mainPreguntarSiRestaurarOActualizar $localVer $remote.ver
            if( $op -eq 0 )
            {
                # creo respaldo
                cStep "Respaldando archivos de usuario."
                mainRespaldarArchivosDeUsuario $PORTABLE_BACKUPPATHS $USER_FOLDER $PORTABLE_PKGNAME

                # restauro instalacion
                cStep "Restaurando version: $localVer."   
                $cacheFolder = mainGetCacheFolder $localVer
                cacheRestore $cacheFolder $PORTABLE_HOME
                $ver = $localVer
            }
            else
            {
                # resuelvo archivo
                cStep "Resolviendo ubicacion de: $($remote.ver)."            
                $zipPath = mainResolver $remote $SEARCH_FOLDERS $DOWNLOAD_FOLDER
                
                # borro cache anterior
                $null = folderDelete $CACHE_ROOT

                cStep "Resolviendo 7zip tool."
                $exe7z = mainObtener7z $TOOLS_ROOT $remote.szURL $remote.szZipName $remote.szExeName $remote.szMD5 

                # creo cache
                cStep "Creando cache para: $($remote.ver)."
                $cacheExpanded = "$CACHE_ROOT\$($remote.ver)"
                cacheCreate $zipPath $CACHE_ROOT $cacheExpanded $exe7z

                # creo respaldo
                cStep "Respaldando archivos de usuario."
                mainRespaldarArchivosDeUsuario $PORTABLE_BACKUPPATHS $USER_FOLDER $PORTABLE_PKGNAME

                # borro instalacion previa
                cStep "Eliminando instalacion anterior"
                mainEliminarInstalacionAnterior $PORTABLE_HOME

                # restauro instalacion
                cStep "Instalando version: $($remote.ver)."            
                $cacheFolder = mainGetCacheFolder $remote.ver            
                cacheRestore $cacheFolder $PORTABLE_HOME

                $ver = $remote.ver
            }
        }
        else
        {
            # son iguales => local
            cStep "Respaldando archivos de usuario."
            mainRespaldarArchivosDeUsuario $PORTABLE_BACKUPPATHS $USER_FOLDER $PORTABLE_PKGNAME

            # restauro instalacion
            cStep "Restaurando version: $localVer."   
            $cacheFolder = mainGetCacheFolder $localVer
            cacheRestore $cacheFolder $PORTABLE_HOME    
            
            $ver = $localVer
        }
    }
    # solo local => restaurar
    elseif($hasLocal)
    {
        # creo respaldo
        cStep "Respaldando archivos de usuario."
        mainRespaldarArchivosDeUsuario $PORTABLE_BACKUPPATHS $USER_FOLDER $PORTABLE_PKGNAME

        cStep "Restaurando: $localVer."
        $cacheFolder = mainGetCacheFolder $localVer        
        cacheRestore $cacheFolder $PORTABLE_HOME
        $ver = $localVer
    }
    # solo remoto
    elseif($hasRemote)
    {
        # resuelvo archivo
        cStep "Resolviendo ubicacion de: $($remote.ver)."            
        $zipPath = mainResolver $remote $SEARCH_FOLDERS $DOWNLOAD_FOLDER
        
        # borro cache anterior
        $null = folderDelete $CACHE_ROOT

        cStep "Resolviendo 7zip tool."
        $exe7z = mainObtener7z $TOOLS_ROOT $remote.szURL $remote.szZipName $remote.szExeName $remote.szMD5 

        # creo cache
        cStep "Creando cache para: $($remote.ver)."
        $cacheExpanded = "$CACHE_ROOT\$($remote.ver)"
        cacheCreate $zipPath $CACHE_ROOT $cacheExpanded $exe7z

        # creo respaldo
        cStep "Respaldando archivos de usuario."
        mainRespaldarArchivosDeUsuario $PORTABLE_BACKUPPATHS $USER_FOLDER $PORTABLE_PKGNAME

        # borro la instalacion anterior
        cStep "Eliminando instalacion anterior"
        mainEliminarInstalacionAnterior $PORTABLE_HOME

        # restauro instalacion
        cStep "Instalando version: $($remote.ver)."            
        $cacheFolder = mainGetCacheFolder $remote.ver            
        cacheRestore $cacheFolder $PORTABLE_HOME

        $ver = $remote.ver
    }
    # ni local ni remota
    else
    {
        cError "  - No hay cache local ni informacion remota."
        cError "  - No es posible continuar."
        pressAnyKey
        exit
    }

    # autocopiado y lnk
    cStep "Creando accesos directos."
    mainAutocopiarScript $USER_FOLDER $PORTABLE_HOME $DESKTOP_FOLDER $SHORTCUT

    # escribo la version del portable instalado
    cStep "Identificando la version instalada/restaurada."
    portableWriteInstalledVersion "version.json" $PORTABLE_HOME $PORTABLE_PKGNAME $ver 

    # hook final
    afterScriptHook $DOWNLOAD_FOLDER $DESKTOP_FOLDER $USER_FOLDER $SEARCH_FOLDERS $CACHE_ROOT $TOOLS_ROOT

    # ejecuto y verifico que todo salio bien
    explorerOpen $PORTABLE_HOME
}

function mainEliminarInstalacionAnterior($portableHome)
{
    if( -not (folderExists $portableHome) )
    {
        cInfo "  - No se encontro una instalacion anterior."
        return
    }

    cOut "  - Esta operacion podria demorar unos minutos."
    if( folderDelete $portableHome )
    {
        cInfo "  - La instalacion anterior fue removida."
    }
    else
    {
        cWarn "  - La instalacion no pudo ser removida."
    }
}


function mainGetCacheFolder($ver)
{
    $cacheExpanded = "$CACHE_ROOT\$ver"
    return "$cacheExpanded\$PORTABLE_PKGNAME"
}

function mainRespaldarArchivosDeUsuario($foldersToBkp,$userFolder,$pkgName)
{
    if( $null -eq $foldersToBkp -or $foldersToBkp.count -eq 0 )    
    {
        cInfo "  - No se especificaron carpetas para respaldar."
        return
    }

    # sÃ³lo continÃºo si existe al menos un folder para backupear
    $existeAlgunFolder = $false
    foreach ($f in $foldersToBkp)
    {
        if (folderExists $f)
        {
            $existeAlgunFolder = $true
            break
        }
    }

    if( -not $existeAlgunFolder )
    {
        cInfo "  - No se encontraron archivos para respalaldar."
        return
    }

    $bkpNames = @(foldersBackup $foldersToBkp $userFolder $pkgName)
    $names = arrayToString $bkpNames
    if( $bkpNames.count -eq $foldersToBkp.count )
    {
        cInfo "  - Archivos de usuario respaldados en: $userFolder ($names)."    
    }
    else
    {
        cWarn "  - No se pudieron respaldar las carpetas del usuario."
        cAsk  "  - Continuar el proceso o cancelar la instalacion?"
        $opciones = @("Continuar","Cancelar")
        $op = cMenu $opciones 
        if( $op -ne 0 )
        {
            cError "  - Instalacion cancelada."                
            pressAnyKey
            exit
        }
        else
        {
            cWarn "  - Continua instalacion sin respaldo."
        }
    }
}

function mainPreguntarSiRestaurarOActualizar($localVer,$remoteVer)
{
    cAsk "  - Restaurar $localVer o actualizar a ${remoteVer}?"
    $options = @("Restaurar","Actualizar")
    $op = cMenu $options -defaultIndex 0 -indent 5
    return $op
}

function mainResolver($remote,$searchFolders,$downloadFolder)
{
    # veo si ya lo tengo descargado
    $filePath  = fileSearchOnFolders $remote.ver $searchFolders

    if( $null -ne $filePath )
    {
        cInfo "  - $($remote.ver) encontrado en: $filePath."    
    }
    else
    {
        # no lo tiene => descargo
        cWarn "  - Archivo no encontrado. Se requiere descarga."
        portableOpenDownloadURL $remote $downloadFolder
        $filePath = $downloadFolder
    }

    # descomprimo y genero el header
    return "$filePath\$($remote.ver)"
}

function mainAsegurarCondicionesInicial($minCache, $minDrive, $portableHome, $userFolder)
{
    # Obtener las letras de unidad (ej: "C:")
    $cacheDrive = driveGetFromPath $userFolder
    $portableDrive = driveGetFromPath $portableHome

    # Caso 1: Todo estÃ¡ en el mismo disco
    if ($cacheDrive -ieq $portableDrive)
    {
        $totalRequired = $minCache + $minDrive
        $freeSpace = driveGetFreeSpace $cacheDrive

        if ($freeSpace -lt $totalRequired)
        {
            cError "  - Espacio insuficiente en $cacheDrive. Requeridos: ${minCache}GB libres."
            pressAnyKey
            exit
        }
    }
    # Caso 2: El portable va a un disco diferente del cachÃ© de usuario
    else
    {
        $freeSpaceCache = driveGetFreeSpace $cacheDrive
        $freeSpaceDrive = driveGetFreeSpace $portableDrive

        # Validar disco de cachÃ©
        if ($freeSpaceCache -lt $minCache)
        {
            cError "  - Espacio insuficiente en $cacheDrive (cache). Requeridos: ${minCache}GB libres."
            pressAnyKey
            exit
        }

        # Validar disco del portable
        if ($freeSpaceDrive -lt $minDrive)
        {
            cError "  - Espacio insuficiente en $portableDrive (soft). Requeridos: ${minDrive}GB libres."
            pressAnyKey
            exit
        }
    }

    # Comprobar si la carpeta destino estÃ¡ bloqueada
    if (folderIsLocked $portableHome)
    {
        cError "  - La carpeta $portableHome esta en uso. No se puede continuar."
        pressAnyKey
        exit
    }

    cInfo "  - El equipo cumple los requisitos de almacenamiento."
}

function mainObtener7z($toolsRoot, $szURL,$szZipName,$szExeName,$szMD5) 
{
    $exePath = Join-Path $toolsRoot $szExeName
    $zipPath = Join-Path $toolsRoot $szZipName
    
    if (Test-Path $exePath) 
    {
        cInfo "  - Se encontro en: $exePath."
        return $exePath
    }

    # 2. Intento de descarga
    gdriveDownload $szURL $zipPath

    $ret = $null
    if (Test-Path $zipPath) 
    {
        # Validar ANTES de descomprimir
        $hash = fileGetHash $zipPath
        if ($hash -eq $szMD5) 
        {
            # Descomprimir sÃ³lo si el hash coincide
            if (fileUnzip $zipPath $toolsRoot $false) 
            {
                cInfo "  - 7zip se descargo correctamente."
                $ret = $exePath
            }
        }
        else 
        {
            cError "  - Error de integridad en la descarga de 7zip."
        }

        Remove-Item $zipPath -Force
    }

    return $ret
}

# function mainAutocopiarScript($scriptTargetFolder, $portableHomeFolder, $desktopFolder, $executableShortcutObject)
# {
#     $fullfileName = $PSCommandPath

#     # 0. VALIDACIÃ“N: Â¿Ya nos estamos ejecutando desde la carpeta de destino?
#     $currentFolder = Split-Path $fullfileName -Parent
#     $resolvedTarget = (Resolve-Path $scriptTargetFolder -ErrorAction SilentlyContinue).Path
#     if ($null -eq $resolvedTarget) { $resolvedTarget = $scriptTargetFolder }

#     try 
#     {
#         # Obtener el nombre del script usando tu funciÃ³n
#         $scriptNameWithExt = scriptGetName 
#         $scriptNameNoExt   = [System.IO.Path]::GetFileNameWithoutExtension($scriptNameWithExt)

#         # 1. Copiar el script en ejecuciÃ³n a la carpeta destino ($USER_FOLDER)
#         if ($currentFolder -ne $resolvedTarget)
#         {
#             [void](fileCopy $fullfileName $scriptTargetFolder)
#         }

#         # Calcular la ruta exacta del script copiado
#         $copiedScriptPath = Join-Path $scriptTargetFolder $scriptNameWithExt

#         # 2. Armar el objeto para el acceso directo del SCRIPT
#         $SHORTCUT_LAUNCHER = [PSCustomObject]@{ 
#             Name             = $scriptNameNoExt
#             TargetPath       = "powershell.exe"
#             Arguments        = "-NoProfile -ExecutionPolicy Bypass -File `"$copiedScriptPath`""
#             WorkingDirectory = $scriptTargetFolder
#             Description      = "Lanzador del instalador/sincronizador de $PORTABLE_PKGNAME"
#             IconLocation     = "powershell.exe,0"
#             WindowStyle      = 1
#         }

#         # ============================================================
#         # LAS 4 INVOCACIONES A LINKCREATE (Usando los parÃ¡metros)
#         # ============================================================
        
#         # A) Los 2 accesos directos para el SCRIPT (Instalador)
#         cInfo "  - Generando enlaces para el instalador/actualizador..."
#         linkCreate $SHORTCUT_LAUNCHER $portableHomeFolder
#         linkCreate $SHORTCUT_LAUNCHER $desktopFolder

#         # B) Los 2 accesos directos para el EJECUTABLE final (Programa)
#         cInfo "  - Generando enlaces para la aplicacion... "
#         linkCreate $executableShortcutObject $portableHomeFolder
#         linkCreate $executableShortcutObject $desktopFolder
#     }
#     catch 
#     {
#         cError "Error en mainAutocopiarScript: $_"
#     }
# }



function mainAutocopiarScript($scriptTargetFolder, $portableHomeFolder, $desktopFolder, $executableShortcutObject)
{
    $fullfileName = $PSCommandPath

    try
    {
        # install-vscode (1).ps1 => install-vscode.ps1
        $scriptNameWithExt = scriptGetName
        $scriptNameWithExt = $scriptNameWithExt -replace ' \(\d+\)(?=\.ps1$)', ''
        $scriptNameNoExt   = [System.IO.Path]::GetFileNameWithoutExtension($scriptNameWithExt)

        # Ruta final del script copiado
        $copiedScriptPath = Join-Path $scriptTargetFolder $scriptNameWithExt

        # Copiar el script con nombre normalizado
        if ($fullfileName -ne $copiedScriptPath)
        {
            [void](Copy-Item -LiteralPath $fullfileName -Destination $copiedScriptPath -Force)
        }

        # 2. Armar el objeto para el acceso directo del SCRIPT
        $SHORTCUT_LAUNCHER = [PSCustomObject]@{
            Name             = $scriptNameNoExt
            TargetPath       = "powershell.exe"
            Arguments        = "-NoProfile -ExecutionPolicy Bypass -File `"$copiedScriptPath`""
            WorkingDirectory = $scriptTargetFolder
            Description      = "Lanzador del instalador/sincronizador de $PORTABLE_PKGNAME"
            IconLocation     = "powershell.exe,0"
            WindowStyle      = 1
        }

        # A) Los 2 accesos directos para el SCRIPT (Instalador)
        cInfo "  - Generando enlaces para el instalador/actualizador..."
        linkCreate $SHORTCUT_LAUNCHER $portableHomeFolder
        linkCreate $SHORTCUT_LAUNCHER $desktopFolder

        # B) Los 2 accesos directos para el EJECUTABLE final (Programa)
        cInfo "  - Generando enlaces para la aplicacion..."
        linkCreate $executableShortcutObject $portableHomeFolder
        linkCreate $executableShortcutObject $desktopFolder
    }
    catch
    {
        cError "Error en mainAutocopiarScript: $_"
    }
}


function mainObtenerDiscoInstall($pkgName, $defaultDrive, $minFreeSpace)
{
    $sn = (scriptGetName)
    if( -not (stringContains $sn $WIZARD_MODE) )
    {
        return $defaultDrive
    }

    cStep "Estableciendo disco de destino."
    
    # 1. Obtener discos fijos y extraÃ­bles listos
    $discosValidos = [System.IO.DriveInfo]::GetDrives() | 
        Where-Object { $_.IsReady -and ($_.DriveType -eq 'Fixed' -or $_.DriveType -eq 'Removable') }

    $opcionesMenu = @()       
    $letrasFiltradas = @()    
    $indicesInstalados = @()  # Guarda quÃ© posiciones del menÃº tienen la app

    foreach ($d in $discosValidos) 
    {
        $letra = $d.Name.TrimEnd('\')
        $freeGB = [Math]::Truncate($d.TotalFreeSpace / 1GB)

        # REGLA 2 y 6: Filtrar por espacio mÃ­nimo
        if ($freeGB -lt $minFreeSpace) { continue }

        # Detectar instalaciÃ³n fÃ­sica real
        $rutaCheck = "$letra\$pkgName"
        $marker = ""
        
        if ([System.IO.Directory]::Exists($rutaCheck)) 
        {
            $marker = " [Instalado]"
            $indicesInstalados += $opcionesMenu.Count
        }

        # --- ALINEACIÃ“N CORREGIDA ---
        # Forzamos a string limpio sin espacios extras antes de rellenar
        $numString = $freeGB.ToString().Trim()
        $freeGBAlined = stringLpad $numString " " 3

        # Armamos el string sin espacios manuales dentro del parÃ©ntesis
        $opcionesMenu += "$letra (${freeGBAlined}GB)$marker"
        $letrasFiltradas += $letra
        #$opcionesMenu += "$letra (${freeGB}GB)$marker"
        #$letrasFiltradas += $letra
    }

    # REGLA 6: Caso catastrÃ³fico (NingÃºn disco apto)
    if ($letrasFiltradas.Count -eq 0) {
        cError "  - Error: No se encontrÃ³ ninguna unidad con espacio suficiente (${minFreeSpace}GB requeridos)."
        pressAnyKey
        exit
    }
    
    # REGLA 1 y 2: Disco Ãºnico o un solo disco con espacio
    if ($letrasFiltradas.Count -eq 1) 
    {
        cInfo "  - La instalacion se realizara en el disco: $($letrasFiltradas[0])."
        return $letrasFiltradas[0]
    }

    # REGLA 3: InstalaciÃ³n Ãºnica (Sin menÃº, restauraciÃ³n automÃ¡tica)
    if ($indicesInstalados.Count -eq 1) {
        $indiceUnico = $indicesInstalados[0]
        cInfo "  - La instalacion se realizara en el disco: $($letrasFiltradas[$indiceUnico])."
        return $letrasFiltradas[$indiceUnico]
    }

    # REGLAS 4 y 5: MÃºltiples opciones aptas (Multi-instalaciÃ³n o ElecciÃ³n limpia)
    # Si hay multi-instalaciÃ³n, hace foco en la primera de ellas. Si no, va al Ã­ndice 0.
    $indicePreseleccion = 0
    if ($indicesInstalados.Count -gt 1) {
        $indicePreseleccion = $indicesInstalados[0]
    }

    # Lanzamos el menÃº interactivo con timeout
    cAsk "  - Seleccione en que disco prefiere realizar la instalacion."

    $opSelec = cMenu $opcionesMenu  # -timeoutSeconds 2
    
    # Fallback por timeout o cancelaciÃ³n
    if ($null -eq $opSelec -or $opSelec -lt 0 -or $opSelec -ge $letrasFiltradas.Count) {
        $opSelec = $indicePreseleccion
    }

    cInfo "  - La instalacion se realizara en el disco: $($letrasFiltradas[$opSelec])."
    return $letrasFiltradas[$opSelec]
}

# function mainActualizarConfig($driveOk)
# {
#     # Si la unidad elegida es distinta a la que venÃ­a por defecto en el deploy
#     if ($driveOk -ine $PORTABLE_DRIVE) 
#     {
#         # Usamos el prefijo $script: para modificar las variables a nivel de archivo
#         $script:PORTABLE_DRIVE = $driveOk
        
#         # El regex "^[a-zA-Z]:" busca la letra de unidad al principio del string y la reemplaza
#         $script:PORTABLE_HOME = $PORTABLE_HOME -replace "^[a-zA-Z]:", $driveOk
#         $script:PORTABLE_MAINPROC = $PORTABLE_MAINPROC -replace "^[a-zA-Z]:", $driveOk
#         $script:PORTABLE_ARGLIST = $driveOk
        
#         # Como PORTABLE_BACKUPPATHS es un array, procesamos cada ruta interna
#         if ($null -ne $PORTABLE_BACKUPPATHS) {
#             $script:PORTABLE_BACKUPPATHS = $PORTABLE_BACKUPPATHS | ForEach-Object { 
#                 $_ -replace "^[a-zA-Z]:", $driveOk 
#             }
#         }
#     }
# }


# --- MODULOS E INFRAESTRUCTURA COMPACTADOS ---

# ================= MODULE: environment.psm1 =================

# Retorna true si la variable contiene el valor exacto entre sus elementos separados por ";"
function environmentHas($varName, $value) 
{
    if (-not (Test-Path "Env:\$varName")) { return $false }
    
    # Obtenemos el valor actual y lo dividimos por el separador ";"
    $currentValues = (Get-Content "Env:\$varName") -split ';'
    
    # Retorna verdadero si el valor existe (ignoring case por defecto en PS)
    return $currentValues -contains $value
}

# Agrega el valor al final, sÃ­ y sÃ³lo sÃ­ no existÃ­a previamente
function environmentAdd($varName, $value) 
{
    if (-not (environmentHas $varName $value)) 
    {
        $currentValue = [Environment]::GetEnvironmentVariable($varName, "User")
        
        if ([string]::IsNullOrEmpty($currentValue)) {
            $newValue = $value
        } else {
            # Nos aseguramos de no duplicar puntos y comas intermedios
            $newValue = if ($currentValue.EndsWith(';')) { "$currentValue$value" } else { "$currentValue;$value" }
        }
        
        environmentSet $varName $newValue
    }
}

# Remueve el valor si existÃ­a dentro de la cadena
function environmentRmv($varName, $value) 
{
    if (environmentHas $varName $value) {
        $currentValue = [Environment]::GetEnvironmentVariable($varName, "User")
        
        # Filtramos el valor exacto que queremos eliminar
        $elements = $currentValue -split ';' | Where-Object { $_ -ne $value -and -not [string]::IsNullOrWhiteSpace($_) }
        $newValue = $elements -join ';'
        
        # Si quedÃ³ vacÃ­a tras la limpieza, la deseteamos
        if ([string]::IsNullOrEmpty($newValue)) {
            environmentSet $varName $null
        } else {
            environmentSet $varName $newValue
        }
    }
}

# Asigna el valor pisando todo. Si es $null o vacÃ­o, la elimina.
function environmentSet($varName, $value) 
{
    if ($null -eq $value -or [string]::IsNullOrEmpty($value)) {
        # Remover de la sesiÃ³n actual
        Remove-Item "Env:\$varName" -ErrorAction SilentlyContinue
        # Remover del registro de usuario permanentemente
        [Environment]::SetEnvironmentVariable($varName, $null, "User")
    } else {
        # Actualizar la sesiÃ³n actual de PowerShell
        Set-Item "Env:\$varName" -Value $value
        # Guardar permanentemente en el entorno de Usuario
        [Environment]::SetEnvironmentVariable($varName, $value, "User")
    }
}


# ================= MODULE: string.psm1 =================

function stringSubstring([string]$str, [int]$desde, [int]$hasta)
{
    $longitud = $hasta - $desde
    return $str.Substring($desde, $longitud)
}

function stringLpad($s, $c, $len)
{
    # Si la cadena es nula, la tratamos como vacÃ­a
    if ($null -eq $s) { $s = "" }
    
    # Si len es menor o igual al largo actual, retornamos s directo
    if ($s.Length -ge $len) {
        return $s
    }

    # Calculamos cuÃ¡ntos caracteres faltan agregar
    $faltan = $len - $s.Length

    # Multiplicamos el caracter 'c' por la cantidad faltante y lo concatenamos a la izquierda
    return ($c * $faltan) + $s
}

function stringContains([string]$s, [string]$substr)
{
    if ([string]::IsNullOrEmpty($s) -or [string]::IsNullOrEmpty($substr)) {
        return $false
    }
    
    return $s.Contains($substr)
}

function stringEndsWith($s, $suffix, $ic = $true)
{
    if($null -eq $s -or $null -eq $suffix)
    {
        return $false
    }

    $comparison = if($ic)
    {
        [System.StringComparison]::OrdinalIgnoreCase
    }
    else
    {
        [System.StringComparison]::Ordinal
    }

    return $s.EndsWith($suffix, $comparison)
}


# ================= MODULE: net.psm1 =================
# +---------+------------------------------------------------------------------+
# | CORE    | Network                                                          |
# +---------+------------------------------------------------------------------+

function internetIsWorking()
{
    try
    {
        $req = [System.Net.WebRequest]::Create("https://www.google.com/generate_204")
        $req.Timeout = 3000
        $req.Method = "GET"

        $res = $req.GetResponse()
        $res.Close()

        return $true
    }
    catch
    {
        return $false
    }
}

function internetDisable()
{
    Set-ItemProperty `
        -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" `
        -Name ProxyEnable `
        -Value 1

    Set-ItemProperty `
        -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" `
        -Name ProxyServer `
        -Value "127.0.0.1:9"
}

function internetEnable()
{
    Set-ItemProperty `
        -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings" `
        -Name ProxyEnable `
        -Value 0
}




# ================= MODULE: date.psm1 =================
#Set-StrictMode -Version Latest


# +---------+------------------------------------------------------------------+
# | CORE | Date & Time                                                            |
# +---------+------------------------------------------------------------------+

function dateAsYYYYMMDD_HHMM()
{
    return Get-Date -Format "yyyy-MM-dd_HHmm"
}


# ================= MODULE: console.psm1 =================
#Set-StrictMode -Version Latest

$endl = "`n"

# function cMenu($options,$indent=3,$defaultIndex = 0,$timeoutSeconds = -1)
# {
#     if($NULL -eq $options -or $options.Count -eq 0)
#     {
#         return -1
#     }

#     $oldCursorVisible = [Console]::CursorVisible
#     [Console]::CursorVisible = $false

#     try
#     {
#         $index = $defaultIndex
#         $maxLen = ($options | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum

#         # reservar espacio para menu + timer
#         #for($i = 0; $i -lt ($options.Count + 1); $i++)
#         for($i = 0; $i -lt $options.Count; $i++)
#         {
#             Write-Host ""
#         }

#         #$top = [Console]::CursorTop - ($options.Count + 1)
#         $top = [Console]::CursorTop - $options.Count
#         $startTime = Get-Date

#         while($true)
#         {
#             for($i = 0; $i -lt $options.Count; $i++)
#             {
#                 [Console]::SetCursorPosition(0, $top + $i)

#                 $text = $options[$i].PadRight($maxLen)

#                 if($i -eq $index)
#                 {
#                      $extra = ""

#                     if($timeoutSeconds -ge 0)
#                     {
#                         $extra = " ($remaining)"
#                     }

#                     $line = (" " * $indent)+">[$text]$extra"
#                 }
#                 else
#                 {
#                     $line = (" " * $indent)+"  $text "
#                 }

#                 Write-Host ($line.PadRight([Console]::WindowWidth - 1)) -NoNewline
#             }

#             # [Console]::SetCursorPosition(0, $top + $options.Count)

#             # if($timeoutSeconds -ge 0)
#             # {
#             #     $elapsed = ((Get-Date) - $startTime).TotalSeconds
#             #     $remaining = [Math]::Ceiling($timeoutSeconds - $elapsed)

#             #     if($remaining -lt 0)
#             #     {
#             #         $remaining = 0
#             #     }

#             #     $linex = (" " * ($($indent)+2))
#             #     $timerLine = "$($linex)Seleccion automatica en $remaining segundos..."
#             #     Write-Host ($timerLine.PadRight([Console]::WindowWidth - 1)) -ForegroundColor DarkGray -NoNewline

#             #     if($elapsed -ge $timeoutSeconds)
#             #     {
#             #         # [Console]::SetCursorPosition(0, $top + $options.Count + 1)
#             #         # Write-Host ""
#             #         #return $index

#             #         [Console]::SetCursorPosition(0, $top + $options.Count)
#             #         Write-Host "`r$(' ' * ([Console]::WindowWidth - 1))" -NoNewline
#             #         return $index
#             #     }
#             # }

#             Start-Sleep -Milliseconds 100

#             if([Console]::KeyAvailable)
#             {
#                 $key = [Console]::ReadKey($true)

#                 switch($key.Key)
#                 {
#                     "UpArrow"
#                     {
#                         if($index -gt 0)
#                         {
#                             $index--
#                         }
#                     }

#                     "DownArrow"
#                     {
#                         if($index -lt ($options.Count - 1))
#                         {
#                             $index++
#                         }
#                     }

#                     #"Enter"
#                     #{
#                     #    [Console]::SetCursorPosition(0, $top + $options.Count + 1)
#                     #    #Write-Host " PEPINO"
#                     #    return $index
#                     #}
#                     "Enter"
#                     {
#                         # Calculamos la posiciÃ³n donde termina el menÃº
#                         $finalPos = $top + $options.Count
                        
#                         # Subimos el cursor un lugar antes de salir
#                         [Console]::SetCursorPosition(0, $finalPos)
                        
#                         return $index
#                     }
#                 }
#             }
#         }
#     }
#     finally
#     {
#         [Console]::CursorVisible = $oldCursorVisible
#     }
# }

function cMenu($options,$indent=3,$defaultIndex = 0,$timeoutSeconds = -1)
{
    if($NULL -eq $options -or $options.Count -eq 0)
    {
        return -1
    }

    $oldCursorVisible = [Console]::CursorVisible
    [Console]::CursorVisible = $false

    try
    {
        $index = $defaultIndex
        $maxLen = ($options | ForEach-Object { $_.Length } | Measure-Object -Maximum).Maximum

        for($i = 0; $i -lt $options.Count; $i++)
        {
            Write-Host ""
        }

        $top = [Console]::CursorTop - $options.Count
        $startTime = Get-Date

        while($true)
        {
            $remaining = 0

            if($timeoutSeconds -ge 0)
            {
                $elapsed = ((Get-Date) - $startTime).TotalSeconds
                $remaining = [Math]::Ceiling($timeoutSeconds - $elapsed)

                if($remaining -lt 0)
                {
                    $remaining = 0
                }

                if($elapsed -ge $timeoutSeconds)
                {
                    [Console]::SetCursorPosition(0, $top + $options.Count)
                    return $index
                }
            }

            for($i = 0; $i -lt $options.Count; $i++)
            {
                [Console]::SetCursorPosition(0, $top + $i)

                $text = $options[$i].PadRight($maxLen)

                if($i -eq $index)
                {
                    $extra = ""

                    if($timeoutSeconds -ge 0)
                    {
                        $extra = " ($remaining)"
                    }

                    $line = (" " * $indent) + ">[$text]$extra"
                }
                else
                {
                    $line = (" " * $indent) + "  $text "
                }

                Write-Host ($line.PadRight([Console]::WindowWidth - 1)) -NoNewline
            }

            Start-Sleep -Milliseconds 100

            if([Console]::KeyAvailable)
            {
                $key = [Console]::ReadKey($true)

                switch($key.Key)
                {
                    "UpArrow"
                    {
                        if($index -gt 0)
                        {
                            $index--
                        }
                    }

                    "DownArrow"
                    {
                        if($index -lt ($options.Count - 1))
                        {
                            $index++
                        }
                    }

                    "Enter"
                    {
                        [Console]::SetCursorPosition(0, $top + $options.Count)
                        return $index
                    }
                }
            }
        }
    }
    finally
    {
        [Console]::CursorVisible = $oldCursorVisible
    }
}

function cBlink($message, $durationInMillis, $color = "white", $attr = "regular")
{
    $end = (Get-Date).AddMilliseconds($durationInMillis)

    while ((Get-Date) -lt $end)
    {
        Write-Host "`r$message" -ForegroundColor $color -NoNewline
        Start-Sleep -Milliseconds 400

        Write-Host "`r$(' ' * $message.Length)`r" -NoNewline
        Start-Sleep -Milliseconds 300
    }

#    Write-Host "`r$(' ' * $message.Length)`r" -NoNewline

    Write-Host "`r$message" -ForegroundColor $color
}

function cPause($millis=500)
{
    Start-Sleep -Milliseconds $millis    
}

#function cStep($mssg,$delay=1000)
#{
#    Write-Host `n$mssg -ForegroundColor Cyan
#    cPause $delay
#}

function cStep($mssg,$delay=1000)
{
    if ($null -eq $script:cStepNumber)
    {
        $script:cStepNumber = 0
    }

    $script:cStepNumber++

    [Console]::WriteLine()
    Write-Host "[$script:cStepNumber] $mssg" -ForegroundColor Cyan
    cPause $delay
}


function cAsk($mssg,$delay=500)
{
    Write-Host $mssg -ForegroundColor Magenta
    cPause $delay
}

function cError($mssg,$delay=1000)
{
    Write-Host $mssg -ForegroundColor Red
    cPause $delay
}

function cWarn($mssg,$delay=500)
{
    Write-Host $mssg -ForegroundColor Yellow
    cPause $delay
}

function cInfo($mssg,$delay=500)
{
    Write-Host $mssg -ForegroundColor Green
    cPause $delay
}
    
function cOut($mssg,$delay=500)
{
    Write-Host $mssg 
    cPause $delay
}

function pressAnyKey($prefix="")
{
    cOut "${prefix}Presione una tecla para continuar..." 
    [void][System.Console]::ReadKey($true)
}

function arrayToString($array)
{
    $ret = ""

    for( $i = 0; $i -lt $array.Length; $i++ )
    {
        if( $i -gt 0 )
        {
            $ret += ", "
        }

        $ret += $array[$i]
    }

    return $ret
}


# ================= MODULE: filesystem.psm1 =================

# +---------+------------------------------------------------------------------+
# | CORE    | Folder                                                           |
# +---------+------------------------------------------------------------------+

function folderCreateStats($path)
{
    if(-not (folderExists $path))
    {
        return $false
    }

    $folderName = Split-Path $path -Leaf
    $statsFileName = "${folderName}_stats.json"
    $statsPath = Join-Path $path $statsFileName

    $files = Get-ChildItem -LiteralPath $path -Recurse -File | Where-Object { $_.FullName -ne $statsPath }

    $folders = Get-ChildItem -LiteralPath $path -Recurse -Directory

    $stats = @{
        fileCount   = $files.Count
        folderCount = $folders.Count
        totalSize   = ($files | Measure-Object -Property Length -Sum).Sum
    }

    $stats | ConvertTo-Json | Set-Content -LiteralPath $statsPath
    fileSetAttributes $statsPath "+h"
    return $true
}

function folderVerifyStats($path)
{
    if(-not (folderExists $path))
    {
        return $false
    }

    $folderName = Split-Path $path -Leaf
    $statsPath = Join-Path $path "${folderName}_stats.json"

    if(-not (fileExists $statsPath))
    {
        return $false
    }

    try
    {
        $savedStats = Get-Content -LiteralPath $statsPath -Raw | ConvertFrom-Json

        $files = Get-ChildItem -LiteralPath $path -Recurse -File |
                 Where-Object { $_.FullName -ne $statsPath }

        $folders = Get-ChildItem -LiteralPath $path -Recurse -Directory

        $currentFileCount   = $files.Count
        $currentFolderCount = $folders.Count
        $currentTotalSize   = ($files | Measure-Object -Property Length -Sum).Sum

        return (
            $savedStats.fileCount   -eq $currentFileCount   -and
            $savedStats.folderCount -eq $currentFolderCount -and
            $savedStats.totalSize   -eq $currentTotalSize
        )
    }
    catch
    {
        return $false
    }
}

function folderBackup($folderToZip, $zipFolder, $zipPrefix)
{
    if (folderExists $folderToZip)
    {
        $backupName = "${zipPrefix}_$(dateAsYYYYMMDD_HHMM).zip"
        $backupPath = "$zipFolder\$backupName"

        fileZip $folderToZip $backupPath | Out-Null

        return $backupName
    }

    return $null
}

function foldersBackup($foldersToBkp,$foldersTarget,$prefix)
{
    $ret = @()

    foreach( $folder in $foldersToBkp )
    {
        if( folderExists $folder )
        {
            try
            {
                $folderName = Split-Path $folder -Leaf
                $folderName = $folderName.Substring(0,1).ToUpper() + $folderName.Substring(1)

                $backupName = "${prefix}${folderName}_$(dateAsYYYYMMDD_HHMM).zip"
                $backupPath = "$foldersTarget\$backupName"

                fileZip $folder $backupPath | Out-Null

                $ret += $backupName
            }
            catch
            {
                cError "  - No se pudo respaldar $folder."
                cError $_.Exception.Message
            }
        }
    }

    return $ret
}

function folderCreate($path)
{
    if (folderExists $path)
    {
        return $false
    }

    New-Item -ItemType Directory -Path $path | Out-Null
    return $true
}

function folderDelete($path)
{
    if (folderExists $path)
    {
        Remove-Item -LiteralPath $path -Recurse -Force
        return $true
    }

    return $false
}

function folderIsLocked($targetPath)
{
    if( -not (folderExists $targetPath) )
    {
        return $false
    }

    try 
    {
        # Genero un nombre temporal para probar el rename
        $tempPath = $targetPath + "_test_" + [guid]::NewGuid().ToString()

        # Intento renombrar la carpeta
        Rename-Item -Path $targetPath -NewName (Split-Path $tempPath -Leaf) -ErrorAction Stop

        # Si se pudo renombrar, la vuelvo a dejar con su nombre original
        Rename-Item -Path $tempPath -NewName (Split-Path $targetPath -Leaf) -ErrorAction Stop

        return $false
    }
    catch 
    {
        return $true
    }

}

function folderExists($path)
{
    return Test-Path -LiteralPath $path -PathType Container
}

function folderGetSubfolders($path)
{
    # -Force permite ver carpetas ocultas y de sistema
    return Get-ChildItem -LiteralPath $path -Directory -Force
}

function folderRename($path, $newName)
{
    if (-not (folderExists $path))
    {
        return $false
    }

    Rename-Item -LiteralPath $path -NewName $newName
    return $true
}

# +---------+------------------------------------------------------------------+
# | CORE    | File                                                             |
# +---------+------------------------------------------------------------------+

function fileRename($path, $newName)
{
    if (-not (fileExists $path))
    {
        return $false
    }

    Rename-Item -LiteralPath $path -NewName $newName

    return $true
}

function fileDelete($fileName)
{
    if(fileExists $fileName )
    {
        Remove-Item -LiteralPath $fileName -Force | Out-null
        return $true
    }

    return $false
}

function fileCopy($filenameSource, $target)
{
    # Verifico que el origen exista
    if (-not (fileExists $filenameSource))
    {
        return $false
    }

    try 
    {
        # Si el target es una carpeta que ya existe
        if (folderExists $target)
        {
            # El destino final serÃ¡ la carpeta + el nombre del archivo original
            Copy-Item -LiteralPath $filenameSource -Destination $target -Force -ErrorAction Stop
        }
        else
        {
            # Si el target NO existe, verificamos si el directorio padre existe
            $parentDir = Split-Path $target -Parent
            
            # Si el target es solo un nombre de archivo en la ruta actual, parentDir serÃ¡ vacÃ­o
            if ($parentDir -and -not (folderExists $parentDir))
            {
                New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
            }

            # Copiamos asumiendo que target es la ruta completa del archivo nuevo
            Copy-Item -LiteralPath $filenameSource -Destination $target -Force -ErrorAction Stop
        }
        return $true
    }
    catch 
    {
        cError "  - Error al copiar: $($_.Exception.Message)"
        return $false
    }
}

function fileGetHash($file)
{
    if (Test-Path $file) 
    {
        # Algorithm MD5 
        return (Get-FileHash -LiteralPath $file -Algorithm MD5).Hash
    }

    return $null
}

function fileExists($path)
{
    return Test-Path -LiteralPath $path -PathType Leaf
}

function fileExists($path)
{
    return Test-Path -LiteralPath $path -PathType Leaf
}

function fileSearchOnFolders($fileName, $searchFolders)
{
    foreach ($folder in $searchFolders)
    {
        $path = "$folder\$fileName"

        if (fileExists $path)
        {
            return $folder
        }
    }

    return $null
}

function fileUnzip($zipPath, $dest, $cleanDestFolderIfExists=$true)
{
    if ($cleanDestFolderIfExists -and (folderExists $dest))
    {
        $null = folderDelete $dest
    }

    # El parÃ¡metro -Force evita el error si el directorio ya existe
    #New-Item -ItemType Directory -Path $dest -Force | Out-Null
    #cmd /c attrib +h "$dest"
    
    folderCreate $dest

    try
    {
        Expand-Archive -LiteralPath $zipPath -DestinationPath $dest -Force
        return $true
    }
    catch
    {
        return $false
    }
}

function file7Unzip($zipPath, $dest, $szExe)
{
    if (folderExists $dest)
    {
        $null = folderDelete $dest
    }

    #New-Item -ItemType Directory -Path $dest | Out-Null
    #cmd /c attrib +h "$dest"
    folderCreate $dest

    try
    {
        # x: eXtract con rutas completas
        # -o: Carpeta de destino (sin espacio entre -o y la ruta)
        # -y: Assume Yes a todo (overwrite) 
        & $szExe x "$zipPath" "-o$dest" -y -bsp1 | Where-Object { $_.trim() -ne "" } | Write-Host

        if ($LASTEXITCODE -eq 0) 
        {
            return $true
        }
        return $false
    }
    catch
    {
        return $false
    }
}

function fileZip($sourcePath, $zipPath)
{
    if (-not (Test-Path -LiteralPath $sourcePath))
    {
        return $false
    }

    $zipFolder = Split-Path $zipPath -Parent

    if ($zipFolder -and (-not (folderExists $zipFolder)))
    {
        New-Item -ItemType Directory -Path $zipFolder | Out-Null
    }

    try
    {
        if (fileExists $zipPath)
        {
            Remove-Item -LiteralPath $zipPath -Force
        }

        Add-Type -AssemblyName System.IO.Compression.FileSystem

        [System.IO.Compression.ZipFile]::CreateFromDirectory(
            $sourcePath,
            $zipPath,
            [System.IO.Compression.CompressionLevel]::Optimal,
            $false
        )

        return $true
    }
    catch
    {
        return $false
    }
}

# function fileZip($sourcePath, $zipPath)
# {
#     if (-not (Test-Path -LiteralPath $sourcePath))
#     {
#         return $false
#     }

#     $zipFolder = Split-Path $zipPath -Parent

#     if ($zipFolder -and (-not (folderExists $zipFolder)))
#     {
#         New-Item -ItemType Directory -Path $zipFolder | Out-Null
#     }

#     try
#     {
#         if (fileExists $zipPath)
#         {
#             Remove-Item -LiteralPath $zipPath -Force
#         }

#         Compress-Archive -LiteralPath $sourcePath -DestinationPath $zipPath -Force
#         return $true
#     }
#     catch
#     {
#         return $false
#     }
# }

# function fileSetAttributes($path, $attributes)
# {
#     if (Test-Path -LiteralPath $path)
#     {
#         cmd /c attrib $attributes "$path"
#     }
# }

function fileSetAttributes($path, $attributes)
{
    if (Test-Path -LiteralPath $path)
    {
        # Obtenemos el objeto del archivo o carpeta de forma nativa
        $file = Get-Item -LiteralPath $path -Force
        
        # Evaluamos el string enviado (+h para ocultar, -h para desocultar)
        if ($attributes -match '\+h')
        {
            # Operacion de bits (OR) para prender el flag de oculto manteniendo los demas (ej: Directory)
            $file.Attributes = $file.Attributes -bor [System.IO.FileAttributes]::Hidden
        }
        elseif ($attributes -match '-h')
        {
            # Operacion de bits (AND NOT) para apagar el flag de oculto
            $file.Attributes = $file.Attributes -band -bnot [System.IO.FileAttributes]::Hidden
        }
    }
}

# +---------+------------------------------------------------------------------+
# | CORE    | Drive                                                            |
# +---------+------------------------------------------------------------------+

function driveGetFreeSpace($drive)
{
    $driveName = $drive.Replace(":", "")
    $d = Get-PSDrive -Name $driveName
    return [math]::Floor($d.Free / 1GB)
}

function driveGetFromPath($path)
{
    if( $path -match '^[A-Za-z]:' )
    {
        return Split-Path $path -Qualifier
    }

    return $null
}

function driveGetSystemDrives() 
{
    return [System.IO.DriveInfo]::GetDrives() | 
        Where-Object { $_.IsReady -and ($_.DriveType -eq 'Fixed' -or $_.DriveType -eq 'Removable') } | 
        ForEach-Object { $_.Name.TrimEnd('\') }
}

function driveGetSystemDrivesStatus() 
{
    return [System.IO.DriveInfo]::GetDrives() | 
        Where-Object { $_.IsReady -and ($_.DriveType -eq 'Fixed' -or $_.DriveType -eq 'Removable') } | 
        ForEach-Object {
            $letter = $_.Name.TrimEnd('\')
            # Convertimos los bytes libres a GB enteros
            $freeGB = [Math]::Truncate($_.TotalFreeSpace / 1GB)
            return "$letter (${freeGB}GB)"
        }
}

function scriptGetName
{
    # 1. Intentamos obtener el comando que invocÃ³ esta funciÃ³n desde la pila de llamadas
    $Caller = Get-PSCallStack | Select-Object -Skip 1 -First 1

    if ($Caller -and $Caller.ScriptName) {
        return [System.IO.Path]::GetFileName($Caller.ScriptName)
    }

    # 2. Respaldo por si se invoca directamente en la consola o un contexto raro
    if ($MyInvocation.ScriptName) {
        return [System.IO.Path]::GetFileName($MyInvocation.ScriptName)
    }

    return "Consola_o_ScriptDesconocido"
}

function linkCreate($linkStructure, $folderPath)
{
    # Forzamos a que el nombre sea un String limpio y armamos la ruta
    $nameString = $linkStructure.Name.ToString()
    $finalPath = Join-Path $folderPath "$nameString.lnk"

    # Forzamos la creaciÃ³n del objeto COM de Windows
    $shell = New-Object -ComObject WScript.Shell
    $lnk = $shell.CreateShortcut($finalPath)

    # Asignamos los parÃ¡metros asegurando que si estÃ¡n vacÃ­os pasemos un String vacÃ­o
    $lnk.TargetPath       = if ($linkStructure.TargetPath) { $linkStructure.TargetPath.ToString() } else { "" }
    $lnk.Arguments        = if ($linkStructure.Arguments) { $linkStructure.Arguments.ToString() } else { "" }
    $lnk.WorkingDirectory = if ($linkStructure.WorkingDirectory) { $linkStructure.WorkingDirectory.ToString() } else { "" }
    $lnk.Description      = if ($linkStructure.Description) { $linkStructure.Description.ToString() } else { "" }
    $lnk.IconLocation     = if ($linkStructure.IconLocation) { $linkStructure.IconLocation.ToString() } else { "" }
    $lnk.WindowStyle      = if ($linkStructure.WindowStyle) { [int]$linkStructure.WindowStyle } else { 1 }

    # Guardamos el archivo binario
    $lnk.Save()
    
    # Liberamos el objeto COM de la memoria para que no bloquee el archivo
    [System.Runtime.InteropServices.Marshal]::ReleaseComObject($shell) | Out-Null
}

function explorerOpen($folder)
{
    if (Test-Path $folder) {
        Start-Process explorer.exe -ArgumentList "`"$folder`""
    } else {
        Write-Warning "No se pudo abrir el Explorador: La carpeta '$folder' no existe."
    }
}



# ================= MODULE: web.psm1 =================
# +---------+------------------------------------------------------------------+
# | NO CORE | GDrive                                                           |
# +---------+------------------------------------------------------------------+

#function gdriveDownload($url, $OutFile)
#{
#    $dir = Split-Path -Parent $OutFile
#    if (!(Test-Path $dir)) {
#        New-Item -ItemType Directory -Path $dir -Force | Out-Null
#    }
#    
#    curl.exe -s -L $url -o $OutFile
#}

function gdriveDownload($url, $OutFile)
{
    $dir = Split-Path -Parent $OutFile

    if (!(Test-Path $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }

    if (Test-Path $OutFile) {
        Remove-Item $OutFile -Force
    }
    
    curl.exe -s -L $url -o $OutFile
}

function gdriveReadFileHeader($url)
{
    $response = Invoke-WebRequest `
        -Uri $url `
        -Method Head `
        -UseBasicParsing

    $cd = $response.Headers["Content-Disposition"]

    $name = $null
    if ($cd -match 'filename="(.+)"')
    {
        $name = $matches[1]
    }

    $dt = [datetime]::Parse($response.Headers["Last-Modified"])

    return @{
        name = $name
        date  = $dt.ToString("yyyy-MM-dd")
        hour   = $dt.ToString("HH:mm:ss")
        size   = [long]$response.Headers["Content-Length"]
    } | ConvertTo-Json
}

# +---------+------------------------------------------------------------------+
# | NO CORE | Download                                                            |
# +---------+------------------------------------------------------------------+

function downloadEsperarDescarga($zipPath)
{
    cOut "  - Esperando descarga del archivo..."

    while (-not (fileExists $zipPath))
    {
        Start-Sleep -Seconds 1
    }

    cInfo "  - Archivo detectado. Esperando finalizacion de la descarga..."

    $tamanoAnterior = -1
    while ($true)
    {
        Start-Sleep -Seconds 2
        $tamanoActual = (Get-Item -LiteralPath $zipPath).Length

        if ($tamanoActual -eq $tamanoAnterior)
        {
            break
        }

        $tamanoAnterior = $tamanoActual
    }

    cInfo "  - Descarga finalizada: $zipPath."
}

function navegadorAbrir($url)
{
    do {
        $k = [System.Console]::ReadKey($true)
    } while ($k.Key -ne [System.ConsoleKey]::Enter)

    Start-Process $url    
}

function downloadAbrirNavegador($url)
{
    cInfo  "  - Se abrira el navegador para descargar el archivo."
    cBlink "  - IMPORTANTE: NO CIERRE ESTA VENTANA." 2500
    cAsk   "  - Presione [ENTER] para descargar..." 

    do {
        $k = [System.Console]::ReadKey($true)
    } while ($k.Key -ne [System.ConsoleKey]::Enter)

    Start-Process $url
}


# ================= MODULE: cache.psm1 =================
# +---------+------------------------------------------------------------------+
# | NO CORE | Cache                                                           |
# +---------+------------------------------------------------------------------+

function cacheCreate($zipPath, $cacheRoot, $cacheExpanded, $exe7z)
{
    $okUnzip = $false
    
    if ($null -ne $exe7z -and (Test-Path $exe7z))
    {
        cInfo "  - Iniciando extraccion con 7-Zip..."
        $okUnzip = file7Unzip $zipPath $cacheExpanded $exe7z
    }
    else
    {
        cInfo "  - Iniciando extraccion con el motor del sistema."
        $okUnzip = fileUnzip $zipPath $cacheExpanded
    }

    if (-not $okUnzip)
    {
        cError "  - No se pudo extraer el contenido de $zipPath."
        pressAnyKey
        exit
    }

    # oculto el cache
    fileSetAttributes $cacheRoot "+h"

    folderCreateStats $cacheExpanded | Out-Null
    fileSetAttributes $cacheExpanded "+h"
    cInfo "  - Cache generado correctamente."
}

function cacheRestore($source, $dest)
{
    cInfo  "  - Sincronizando archivos."

    $source = (Resolve-Path $source).Path
    $dest   = $dest.TrimEnd('\')

    if (!(Test-Path -LiteralPath $dest))
    {
        New-Item -ItemType Directory -Path $dest | Out-Null
    }

    $dest = (Resolve-Path $dest).Path

    $srcFiles  = Get-ChildItem -LiteralPath $source -Recurse -File
    $destFiles = Get-ChildItem -LiteralPath $dest   -Recurse -File

    $script:total    = $srcFiles.Count + $destFiles.Count
    $script:actual   = 0
    $script:lastPct  = -1

    function tickProgress()
    {
        if ($script:total -le 0) { return }

        $script:actual++

        $pct = [int](($script:actual * 100) / $script:total)

        if ($pct -ne $script:lastPct)
        {
            Write-Host "`r     [$pct%] Sincronizando archivos..." -NoNewline
            $script:lastPct = $pct
        }
    }

    # --- CREAR DIRECTORIOS FALTANTES ---
    $dirs = Get-ChildItem -LiteralPath $source -Recurse -Directory

    foreach ($dir in $dirs)
    {
        $relative  = $dir.FullName.Substring($source.Length).TrimStart('\')
        $targetDir = Join-Path $dest $relative

        if (!(Test-Path -LiteralPath $targetDir))
        {
            New-Item -ItemType Directory -Path $targetDir | Out-Null
        }
    }

    # --- AGREGAR / RECUPERAR ARCHIVOS ---
    foreach ($file in $srcFiles)
    {
        $relative = $file.FullName.Substring($source.Length).TrimStart('\')
        $target   = Join-Path $dest $relative

        $targetDir = Split-Path $target

        if (!(Test-Path -LiteralPath $targetDir))
        {
            New-Item -ItemType Directory -Path $targetDir | Out-Null
        }

        $copiar = $true
        $accion = "agregado"

        if (Test-Path -LiteralPath $target)
        {
            $destFile = Get-Item -LiteralPath $target
            $accion = "recuperado"

            if ($destFile.Length -eq $file.Length)
            {
                if ($destFile.LastWriteTime -eq $file.LastWriteTime)
                {
                    $copiar = $false
                }
                else
                {
                    $h1 = (Get-FileHash -LiteralPath $file.FullName).Hash
                    $h2 = (Get-FileHash -LiteralPath $target).Hash

                    if ($h1 -eq $h2)
                    {
                        $copiar = $false
                    }
                }
            }
        }

        if ($copiar)
        {
            Copy-Item -LiteralPath $file.FullName -Destination $target -Force
        }

        tickProgress
    }

    # --- ELIMINAR ARCHIVOS SOBRANTES ---
    foreach ($d in $destFiles)
    {
        $relative = $d.FullName.Substring($dest.Length).TrimStart('\')
        $srcFile  = Join-Path $source $relative

        if (!(Test-Path -LiteralPath $srcFile))
        {
            Remove-Item -LiteralPath $d.FullName -Force
        }

        tickProgress
    }

    # --- ELIMINAR DIRECTORIOS SOBRANTES ---
    $destDirs = Get-ChildItem -LiteralPath $dest -Recurse -Directory | Sort-Object FullName -Descending

    foreach ($d in $destDirs)
    {
        $relative = $d.FullName.Substring($dest.Length).TrimStart('\')
        $srcDir   = Join-Path $source $relative

        if (!(Test-Path -LiteralPath $srcDir))
        {
            Remove-Item -LiteralPath $d.FullName -Recurse -Force
        }
    }

    Write-Host ""
    cInfo "  - Sincronizacion finalizada."
}

function cacheGetVersion($cacheRoot)
{
    $dirs = Get-ChildItem -LiteralPath $cacheRoot -Directory

    if($dirs.Count -ne 1)
    {
        throw "Se esperaba una unica version en cache, pero hay $($dirs.Count)."
    }

    return $dirs[0].Name
}


# ================= MODULE: portable.psm1 =================
# +---------+------------------------------------------------------------------+
# | NO CORE | VSCode                                                           |
# +---------+------------------------------------------------------------------+

function portableReadManifest($manifestUrl,$activeEnv="prod")
{
    if( -not (internetIsWorking) )
    {
        cWarn "  - ATENCION: Trabajando sin conexion a Internet."
        return $null
    }

    try 
    {
        # leo el manifest
        $response = Invoke-WebRequest -Uri $manifestUrl -UseBasicParsing
        $content = $response.Content

        # Manejo de encoding para evitar caracteres rotos
        if($content -is [byte[]]) 
        {
            $content = [System.Text.Encoding]::UTF8.GetString($content)
        }

        $json = $content | ConvertFrom-Json
        $envConfig = $json.environments.$activeEnv
        $remoteUrl = $envConfig.url
        $remoteMD5 = $envConfig.md5
        $remoteVer = $envConfig.version

        # retorno una estructura
        $ret = [pscustomobject]@{
                ver = $remoteVer
                url = $remoteUrl
                md5 = $remoteMD5
                szZipName = $json.tools.sevenZip.zipName
                szExeName = $json.tools.sevenZip.exeName
                szURL = $json.tools.sevenZip.url
                szMD5 = $json.tools.sevenZip.md5
                scriptLastUpdate = $json.script.last_update
                scriptUrl = $json.script.url
                scriptCritical = $json.script.critical
            }

        return $ret            
    }
    catch 
    {
        return $null
    }
}

function portableReadCacheVersion($cacheRoot)
{
    # si no existe el root retorno null
    if(-not (folderExists $cacheRoot))
    {
        cWarn "  - No se encontro cache local."
        return $null
    }

    # pido las carpetas hijas directas
    $folders = folderGetSubfolders "$cacheRoot\"

    # debe existir exactamente una carpeta
    if($folders.Count -ne 1)
    {
        cWarn "  - Cache local invalido."
        return $null
    }

    # LA carpeta que tiene el cache
    $folder = $folders[0]

    # verifico integridad del cache
    $cacheOk = folderVerifyStats $folder.FullName

    if(-not $cacheOk)
    {
        cWarn "  - El cache local esta corrupto."
        return $null
    }

    cInfo "  - Cache encontrado: $($folder.Name)."
    return $folder.Name
}


function portableOpenDownloadUrl($remote,$downloadFolder)
{
    $url = $remote.url
    $fileName = $remote.ver
    $md5 = $remote.md5

    downloadAbrirNavegador $url
    downloadEsperarDescarga "$downloadFolder\$fileName"

    # verifico que exista en downloads
    if (-not (fileExists "$downloadFolder\$fileName"))
    {
        cError "  - No se encontro $fileName en: $downloadFolder." 500
        cError "  - Verifique la descarga y vuelva a ejecutar el script."
        pressAnyKey
        exit
    }

    # verifico el hash
    $hash = fileGetHash "$downloadFolder\$fileName"
    if( $hash.ToUpper() -ne $md5.ToUpper() )    
    {
        cError "  - $fileName no se descargo correctamente." 500      
        cError "  - Vuelva a ejecutar el script."
        pressAnyKey
        exit
    }
}

function portableVersionCompare($localVer, $remoteVer)
{
    $local  = [regex]::Match($localVer,  '(\d+)\.(\d+)\.(\d+)')
    $remote = [regex]::Match($remoteVer, '(\d+)\.(\d+)\.(\d+)')

    if (!$local.Success -or !$remote.Success)
    {
        return 0
    }

    $localMajor  = [int]$local.Groups[1].Value
    $localMinor  = [int]$local.Groups[2].Value
    $localPatch  = [int]$local.Groups[3].Value

    $remoteMajor = [int]$remote.Groups[1].Value
    $remoteMinor = [int]$remote.Groups[2].Value
    $remotePatch = [int]$remote.Groups[3].Value

    # 1. Evaluar Major (Version Critica o Downgrade Mayor)
    if ($remoteMajor -gt $localMajor) { return 3 }  # Actualizacion Critica
    if ($remoteMajor -lt $localMajor) { return -1 } # Downgrade

    # Si llego aca, los Major son iguales. Evaluamos Minor.
    if ($remoteMinor -gt $localMinor) { return 2 }  # Actualizacion Importante
    if ($remoteMinor -lt $localMinor) { return -1 } # Downgrade

    # Si llego aca, Major y Minor son iguales. Evaluamos Patch.
    if ($remotePatch -gt $localPatch) { return 1 }  # Actualizacion Menor
    if ($remotePatch -lt $localPatch) { return -1 } # Downgrade

    return 0 # Son exactamente iguales, no hay cambios
}




function portableEvalUpdateType($localVer,$remoteVer)
{    
    if( $null -eq $remoteVer )
    {
        cWarn "  - No se pudo obtener informacion sobre actualizaciones."
        return
    }

    if( $null -eq $localVer )
    {
        cInfo "  - Version disponible para descargar: $remoteVer."
        return
    }

    $tipoAct = portableVersionCompare $localVer $remoteVer

    switch ($tipoAct)
    {
        0  { cInfo "  - No hay actualizaciones. Version actual: $localVer." }
        1  { cInfo "  - Actualizacion disponible (menor): $localVer -> $remoteVer." }
        2  { cWarn "  - Actualizacion disponible (IMPORTANTE): $localVer -> $remoteVer." }
        3  { cWarn "  - Actualizacion disponible (CRITICA): $localVer -> $remoteVer." }
        -1 { cWarn "  - Downgrade disponible: $localVer -> $remoteVer." }
    }
}

function portableCheckForScriptUpdates($remote)
{
    $scriptPath = $PSCommandPath

    if (-not (fileExists $scriptPath))
    {
        cWarn "  - No es posible verificar actualizaciones del script."
        return
    }

    $remoteDate = [datetime]::ParseExact($remote.scriptLastUpdate,"yyyy-MM-dd_HH:mm",$null)
    $localDate = (Get-Item -LiteralPath $scriptPath).LastWriteTime
    $localDate = $localDate.AddSeconds(-$localDate.Second).AddMilliseconds(-$localDate.Millisecond)

    if ($remoteDate -gt $localDate)
    {
        cWarn "  - Nueva version del script disponible en:"
        $url = $remote.scriptUrl 
        cWarn "    $url"
        $url | Set-Clipboard
        cAsk "  - Continuar o cancelar y descargar?"
        $ops = @(
            "Continuar instalacion",
            "Descargar actualizacion"
        )

        $x = cMenu $ops -timeout 15
        if( $x -ne 0 )
        {
            cInfo "  - La URL del script actualizado se copio al clipboard."
            cInfo "  - Descargue la nueva version y vuelva a ejecutar."
            pressAnyKey
            exit
        }
    }
}

function portableWriteInstalledVersion($fileName,$portableHome, $pkgName, $version)
{
    if( $null -eq $ver )
    {
        cError "  - No fue posible determinar la version instalada."
        return
    }

    $info = [pscustomobject]@{
        version     = $version
        installedAt = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    }

    $file = Join-Path $portableHome $fileName

    $info | ConvertTo-Json | Set-Content -Encoding UTF8 $file
    fileSetAttributes $file "+h"

    cInfo "  - Version instalada/restaurada: $ver."
}



# llamo a main
main

