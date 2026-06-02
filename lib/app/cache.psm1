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

# function cacheRestore($source, $dest)
# {
#     cInfo  "  - Sincronizando archivos."

#     $source = (Resolve-Path $source).Path
#     $dest   = $dest.TrimEnd('\')

#     if (!(Test-Path -LiteralPath $dest))
#     {
#         New-Item -ItemType Directory -Path $dest | Out-Null
#     }

#     $dest = (Resolve-Path $dest).Path

#     $srcFiles  = Get-ChildItem -LiteralPath $source -Recurse -File
#     $destFiles = Get-ChildItem -LiteralPath $dest   -Recurse -File

#     $script:total    = $srcFiles.Count + $destFiles.Count
#     $script:actual   = 0
#     $script:lastPct  = -1

#     function tickProgress()
#     {
#         if ($script:total -le 0) { return }

#         $script:actual++

#         $pct = [int](($script:actual * 100) / $script:total)

#         if ($pct -ne $script:lastPct)
#         {
#             Write-Host "`r     [$pct%] Sincronizando archivos..." -NoNewline
#             $script:lastPct = $pct
#         }
#     }

#     # --- CREAR DIRECTORIOS FALTANTES ---
#     $dirs = Get-ChildItem -LiteralPath $source -Recurse -Directory

#     foreach ($dir in $dirs)
#     {
#         $relative  = $dir.FullName.Substring($source.Length).TrimStart('\')
#         $targetDir = Join-Path $dest $relative

#         if (!(Test-Path -LiteralPath $targetDir))
#         {
#             New-Item -ItemType Directory -Path $targetDir | Out-Null
#         }
#     }

#     # --- AGREGAR / RECUPERAR ARCHIVOS ---
#     foreach ($file in $srcFiles)
#     {
#         $relative = $file.FullName.Substring($source.Length).TrimStart('\')
#         $target   = Join-Path $dest $relative

#         $targetDir = Split-Path $target

#         if (!(Test-Path -LiteralPath $targetDir))
#         {
#             New-Item -ItemType Directory -Path $targetDir | Out-Null
#         }

#         $copiar = $true
#         $accion = "agregado"

#         if (Test-Path -LiteralPath $target)
#         {
#             $destFile = Get-Item -LiteralPath $target
#             $accion = "recuperado"

#             if ($destFile.Length -eq $file.Length)
#             {
#                 if ($destFile.LastWriteTime -eq $file.LastWriteTime)
#                 {
#                     $copiar = $false
#                 }
#                 else
#                 {
#                     $h1 = (Get-FileHash -LiteralPath $file.FullName).Hash
#                     $h2 = (Get-FileHash -LiteralPath $target).Hash

#                     if ($h1 -eq $h2)
#                     {
#                         $copiar = $false
#                     }
#                 }
#             }
#         }

#         if ($copiar)
#         {
#             Copy-Item -LiteralPath $file.FullName -Destination $target -Force
#         }

#         tickProgress
#     }

#     # --- ELIMINAR ARCHIVOS SOBRANTES ---
#     foreach ($d in $destFiles)
#     {
#         $relative = $d.FullName.Substring($dest.Length).TrimStart('\')
#         $srcFile  = Join-Path $source $relative

#         if (!(Test-Path -LiteralPath $srcFile))
#         {
#             Remove-Item -LiteralPath $d.FullName -Force
#         }

#         tickProgress
#     }

#     # --- ELIMINAR DIRECTORIOS SOBRANTES ---
#     $destDirs = Get-ChildItem -LiteralPath $dest -Recurse -Directory | Sort-Object FullName -Descending

#     foreach ($d in $destDirs)
#     {
#         $relative = $d.FullName.Substring($dest.Length).TrimStart('\')
#         $srcDir   = Join-Path $source $relative

#         if (!(Test-Path -LiteralPath $srcDir))
#         {
#             Remove-Item -LiteralPath $d.FullName -Recurse -Force
#         }
#     }

#     Write-Host ""
#     cInfo "  - Sincronizacion finalizada."
# }

function cacheGetVersion($cacheRoot)
{
    $dirs = Get-ChildItem -LiteralPath $cacheRoot -Directory

    if($dirs.Count -ne 1)
    {
        throw "Se esperaba una unica version en cache, pero hay $($dirs.Count)."
    }

    return $dirs[0].Name
}

function cacheRestore($source, $dest)
{
    cInfo  "  - Sincronizando archivos."

    folderSyncMirror $source $dest $_cacheRetoreProgress 

    Write-Host ""
    cInfo "  - Sincronizacion finalizada."

}

function _cacheRestoreProgress($pct)
{
    Write-Host "`r     [$pct%] Restaurando..." -NoNewline
}


Export-ModuleMember -Function *