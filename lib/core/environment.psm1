
# Retorna true si la variable contiene el valor exacto entre sus elementos separados por ";"
function environmentHas($varName, $value) 
{
    if (-not (Test-Path "Env:\$varName")) { return $false }
    
    # Obtenemos el valor actual y lo dividimos por el separador ";"
    $currentValues = (Get-Content "Env:\$varName") -split ';'
    
    # Retorna verdadero si el valor existe (ignoring case por defecto en PS)
    return $currentValues -contains $value
}

# Agrega el valor al final, sí y sólo sí no existía previamente
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

# Remueve el valor si existía dentro de la cadena
function environmentRmv($varName, $value) 
{
    if (environmentHas $varName $value) {
        $currentValue = [Environment]::GetEnvironmentVariable($varName, "User")
        
        # Filtramos el valor exacto que queremos eliminar
        $elements = $currentValue -split ';' | Where-Object { $_ -ne $value -and -not [string]::IsNullOrWhiteSpace($_) }
        $newValue = $elements -join ';'
        
        # Si quedó vacía tras la limpieza, la deseteamos
        if ([string]::IsNullOrEmpty($newValue)) {
            environmentSet $varName $null
        } else {
            environmentSet $varName $newValue
        }
    }
}

# Asigna el valor pisando todo. Si es $null o vacío, la elimina.
function environmentSet($varName, $value) 
{
    if ($null -eq $value -or [string]::IsNullOrEmpty($value)) {
        # Remover de la sesión actual
        Remove-Item "Env:\$varName" -ErrorAction SilentlyContinue
        # Remover del registro de usuario permanentemente
        [Environment]::SetEnvironmentVariable($varName, $null, "User")
    } else {
        # Actualizar la sesión actual de PowerShell
        Set-Item "Env:\$varName" -Value $value
        # Guardar permanentemente en el entorno de Usuario
        [Environment]::SetEnvironmentVariable($varName, $value, "User")
    }
}

Export-ModuleMember -Function *