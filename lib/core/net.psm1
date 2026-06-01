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

Export-ModuleMember -Function *

