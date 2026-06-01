# +---------+------------------------------------------------------------------+
# | DEPLOY  | Cambiar aqui para configurara cada script portable               |
# +---------+------------------------------------------------------------------+

# Espacio inicial requerido por ubicación
$FREESPACE_CACHE = 5
$FREESPACE_DRIVE = 3

# portable
$PORTABLE_DESCRIPTION = "Test Installer"
$PORTABLE_DRIVE = "C:"
$PORTABLE_PKGNAME = "testInstaller"
$PORTABLE_HOME = "$PORTABLE_DRIVE\testInstaller"
$PORTABLE_MAINPROC = "$PORTABLE_HOME\ejecutable\runTest.bat"
$PORTABLE_ARGLIST = $PORTABLE_DRIVE
$PORTABLE_BACKUPPATHS = @("$PORTABLE_HOME\carpeta1")

$OUTPUT_PATH = "test"

# url para descargar el manifest
$MANIFEST_URL = "https://drive.google.com/uc?export=download&id=1Boaau5v_0idDnge52glLmayb7WTb2evP"

# datos para el .lnk 
$targetPath = "$PORTABLE_HOME\ejecutable\runTest.bat"

$SHORTCUT = [PSCustomObject]@{ 
    Name             = "runTest"
    TargetPath       = "cmd.exe"
    Arguments        = "/c `"$targetPath`"" 
    WorkingDirectory = "$PORTABLE_HOME\ejecutable" 
    Description      = "Levanta el ejecutable de Test"
    IconLocation     = "cmd.exe,0" 
    WindowStyle      = 7 
}

function beforeScriptHook($downloadFolder,$desktopFolder,$userFolder,$searchFolders,$cacheRoot,$toolsRoot)
{
    cInfo "beforeScriptHook"
    $folder = "$PORTABLE_HOME\carpeta1\oculta"

    New-Item -ItemType Directory -Path $folder -Force | Out-Null

    "archivo 1" | Set-Content "$folder\a.txt"
    "archivo 2" | Set-Content "$folder\b.txt"
    "archivo 3" | Set-Content "$folder\c.txt"

    attrib +h $folder
}

function afterScriptHook($downloadFolder,$desktopFolder,$userFolder,$searchFolders,$cacheRoot,$toolsRoot)
{
    cInfo "afterScriptHook"
}

function deployRefreshVariables($drive)
{
    $script:PORTABLE_DRIVE = $drive
    $script:PORTABLE_HOME = "$drive\testInstaller"
    $script:PORTABLE_MAINPROC = "$PORTABLE_HOME\runTest.bat"
    $script:PORTABLE_ARGLIST = $drive
    $script:PORTABLE_BACKUPPATHS = @("$PORTABLE_HOME\carpeta1")
}