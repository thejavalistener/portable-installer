
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
            # El destino final será la carpeta + el nombre del archivo original
            Copy-Item -LiteralPath $filenameSource -Destination $target -Force -ErrorAction Stop
        }
        else
        {
            # Si el target NO existe, verificamos si el directorio padre existe
            $parentDir = Split-Path $target -Parent
            
            # Si el target es solo un nombre de archivo en la ruta actual, parentDir será vacío
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

    # El parámetro -Force evita el error si el directorio ya existe
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
    # 1. Intentamos obtener el comando que invocó esta función desde la pila de llamadas
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

    # Forzamos la creación del objeto COM de Windows
    $shell = New-Object -ComObject WScript.Shell
    $lnk = $shell.CreateShortcut($finalPath)

    # Asignamos los parámetros asegurando que si están vacíos pasemos un String vacío
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

Export-ModuleMember -Function *
