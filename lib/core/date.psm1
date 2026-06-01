#Set-StrictMode -Version Latest


# +---------+------------------------------------------------------------------+
# | CORE | Date & Time                                                            |
# +---------+------------------------------------------------------------------+

function dateAsYYYYMMDD_HHMM()
{
    return Get-Date -Format "yyyy-MM-dd_HHmm"
}

Export-ModuleMember -Function *