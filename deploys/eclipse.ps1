# +---------+------------------------------------------------------------------+
# | DEPLOY  | Cambiar aqui para configurara cada script portable               |
# +---------+------------------------------------------------------------------+

# Espacio inicial requerido por ubicación
$FREESPACE_CACHE = 2
$FREESPACE_DRIVE = 3

# portable
$PORTABLE_DESCRIPTION = "Eclipse STS (portable) for Java"
$PORTABLE_DRIVE = "C:"
$PORTABLE_PKGNAME = "java64"
$PORTABLE_HOME = "$PORTABLE_DRIVE\Java64"
$PORTABLE_MAINPROC = "$PORTABLE_HOME\RunEclipse.bat"
$PORTABLE_ARGLIST = "$PORTABLE_DRIVE\"
$PORTABLE_BACKUPPATHS = @("$PORTABLE_HOME\Workspace")

# Url para descargar el archivo (apunta a manifest.json de desarrollo)
$MANIFEST_URL = "https://drive.google.com/uc?export=download&id=18AlgTysKYeY7vsJTyNbH1CvzHACMnwPm"


$targetPath = "$PORTABLE_HOME\eclipse\SpringToolSuite4.exe"
$SHORTCUT = [PSCustomObject]@{ 
    Name = "eclipse"
    TargetPath       = $targetPath
    Arguments        = ""
    WorkingDirectory = $PORTABLE_HOME
    Description      = "Ejecuta Eclipse Spring Tool Suite"
    IconLocation     = "$targetPath,0"
    WindowStyle      = 1
}

