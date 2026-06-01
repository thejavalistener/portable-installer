# +---------+------------------------------------------------------------------+
# | DEPLOY  | Cambiar aqui para configurara cada script portable               |
# +---------+------------------------------------------------------------------+

# Espacio inicial requerido por ubicación
$FREESPACE_CACHE = 5
$FREESPACE_DRIVE = 3

# portable
$PORTABLE_DESCRIPTION = "Visual Studio Code (portable) for C++"
$PORTABLE_DRIVE = "C:"
$PORTABLE_PKGNAME = "vscode"
$PORTABLE_HOME = "$PORTABLE_DRIVE\vscode"
$PORTABLE_MAINPROC = "$PORTABLE_HOME\RunVSCode.bat"
$PORTABLE_ARGLIST = $PORTABLE_DRIVE
$PORTABLE_BACKUPPATHS = @("$PORTABLE_HOME\Workspace")

# url para descargar el manifest
$MANIFEST_URL = "https://drive.google.com/uc?export=download&id=1OdcuIkuy6Sd9km4GRwyKk8CTAqlooJt1"

# datos para el .lnk 
$targetPath = "$PORTABLE_HOME\vscode\Code.exe"
$SHORTCUT = [PSCustomObject]@{ 
    Name             = "vscode" # O el nombre que le des a VS Code
    TargetPath       = "cmd.exe"
    Arguments        = "/c set `"PATH=$PORTABLE_HOME\MinGW\bin;%PATH%`" && start `"`" `"$PORTABLE_HOME\vscode\Code.exe`" `"$PORTABLE_HOME\Workspace\Workspace.code-workspace`""
    WorkingDirectory = $PORTABLE_HOME
    Description      = "Arranca VS Code con entorno MinGW"
    IconLocation     = "$PORTABLE_HOME\vscode\Code.exe,0"
    WindowStyle      = 7 # 7 = Minimizada, para que no parpadee la ventana negra de CMD
}

function beforeScriptHook()
{
}

function afterScriptHook()
{
    $toDelete = "$PORTABLE_HOME\RunVSCode.bat"
    $null = fileDelete $toDelete
}

function deployRefreshVariables($drive)
{
    $script:PORTABLE_DRIVE = $drive
    $script:PORTABLE_HOME = "$drive\vscode"
    $script:PORTABLE_MAINPROC = "$PORTABLE_HOME\RunVSCode.bat"
    $script:PORTABLE_ARGLIST = $drive
    $script:PORTABLE_BACKUPPATHS = @("$PORTABLE_HOME\Workspace")

    $script:SHORTCUT = [PSCustomObject]@{
        Name             = "vscode"
        TargetPath       = "cmd.exe"
        Arguments        = "/c set `"PATH=$PORTABLE_HOME\MinGW\bin;%PATH%`" && start `"`" `"$PORTABLE_HOME\vscode\Code.exe`" `"$PORTABLE_HOME\Workspace\Workspace.code-workspace`""
        WorkingDirectory = $PORTABLE_HOME
        Description      = "Arranca VS Code con entorno MinGW"
        IconLocation     = "$PORTABLE_HOME\vscode\Code.exe,0"
        WindowStyle      = 7
    }
}