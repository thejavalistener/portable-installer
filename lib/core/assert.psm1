
function assertTrue($expr,$mssg)
{
    if( -not $expr )
    {
        Write-Host $mssg -ForegroundColor Red
        exit
    }
}

function assertFalse($expr,$mssg)
{
    if( $expr )
    {
        Write-Host $mssg -ForegroundColor Red
        exit
    }
}



Export-ModuleMember -Function * -Variable *