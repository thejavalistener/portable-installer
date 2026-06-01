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

Export-ModuleMember -Function *