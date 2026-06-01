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

Export-ModuleMember -Function *