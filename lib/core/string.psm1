
function stringSubstring([string]$str, [int]$desde, [int]$hasta)
{
    $longitud = $hasta - $desde
    return $str.Substring($desde, $longitud)
}

function stringLpad($s, $c, $len)
{
    # Si la cadena es nula, la tratamos como vacía
    if ($null -eq $s) { $s = "" }
    
    # Si len es menor o igual al largo actual, retornamos s directo
    if ($s.Length -ge $len) {
        return $s
    }

    # Calculamos cuántos caracteres faltan agregar
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

Export-ModuleMember -Function *