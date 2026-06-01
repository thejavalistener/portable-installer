Import-Module "$PSScriptRoot\lib\core\environment.psm1" -Force
Import-Module "$PSScriptRoot\lib\core\string.psm1" -Force
Import-Module "$PSScriptRoot\lib\core\net.psm1" -Force
Import-Module "$PSScriptRoot\lib\core\date.psm1" -Force
Import-Module "$PSScriptRoot\lib\core\console.psm1" -Force
Import-Module "$PSScriptRoot\lib\core\filesystem.psm1" -Force
Import-Module "$PSScriptRoot\lib\core\web.psm1" -Force
Import-Module "$PSScriptRoot\lib\app\cache.psm1" -Force
Import-Module "$PSScriptRoot\lib\app\portable.psm1" -Force

# +---------+------------------------------------------------------------------+
# | DEPLOY  | Cambiar aqui para configurara cada script portable               |
# +---------+------------------------------------------------------------------+

#_DEPLOY_CONFIG_PLACEHOLDER_

# +---------+------------------------------------------------------------------+
# | GENERAL | Cambiar aqui para configurar el funcionamiento general           |
# +---------+------------------------------------------------------------------+

$ENVIRONMENT = "prod"

# sufijo que da acceso al instalador inteligente
$WIZARD_MODE = "-wiz.ps1"

# Carpetas del usuario
$DOWNLOAD_FOLDER = "$env:USERPROFILE\Downloads"
$DESKTOP_FOLDER = "$env:USERPROFILE\Desktop"
$USER_FOLDER = $env:USERPROFILE
$CURRENT_FOLDER = "."

# de voy a buscar el archivo
$SEARCH_FOLDERS = @($DOWNLOAD_FOLDER, $DESKTOP_FOLDER, $CURRENT_FOLDER)

# Raiz de los cache 
$CACHE_ROOT = "$env:USERPROFILE\temp\.cache\$PORTABLE_PKGNAME"
$TOOLS_ROOT = "$env:USERPROFILE\temp\tools"

function main()
{
    # hook inicial
    beforeScriptHook $DOWNLOAD_FOLDER $DESKTOP_FOLDER $USER_FOLDER $SEARCH_FOLDERS $CACHE_ROOT $TOOLS_ROOT

    #deshabilito restriccion de scripts para el usuario
    Set-ExecutionPolicy Bypass -Scope CurrentUser

    #presentación
    cStep "Comenzando instalacion."
    cInfo "  - $PORTABLE_DESCRIPTION."

    # veo qué versión local tengo instalada (si la tengo)
    cStep "Verificando existencia de cache local."
    $localVer = portableReadCacheVersion $CACHE_ROOT

    # el usuario escoge el disco
    $driveOk = mainObtenerDiscoInstall $PORTABLE_PKGNAME $PORTABLE_DRIVE $FREESPACE_DRIVE 
    deployRefreshVariables $driveOk
    #mainActualizarConfig $driveOk

    #ASSERT
    # Verifico condiciones iniciales de espacio y bloqueo cruzado
    cStep "Verificando condiciones iniciales."    
    mainAsegurarCondicionesInicial $FREESPACE_CACHE $FREESPACE_DRIVE $PORTABLE_HOME $USER_FOLDER
    
    # verifico actualizaciones disponibles
    cStep "Verificando actualizaciones."
    $remote = portableReadManifest $MANIFEST_URL $ENVIRONMENT

    if( $null -ne $remote )
    {
        portableEvalUpdateType $localVer $remote.ver 
        portableCheckForScriptUpdates $remote 
    }
    
    $hasLocal  = $null -ne $localVer
    $hasRemote = $null -ne $remote

    $ver = $null

    # local y remota
    if($hasLocal -and $hasRemote)
    {
        # son distintas 
        if( $localVer -ne $remote.ver )
        {
            # pregunto si desea restaurar (0) o actualizar (1)
            $op = mainPreguntarSiRestaurarOActualizar $localVer $remote.ver
            if( $op -eq 0 )
            {
                # creo respaldo
                cStep "Respaldando archivos de usuario."
                mainRespaldarArchivosDeUsuario $PORTABLE_BACKUPPATHS $USER_FOLDER $PORTABLE_PKGNAME

                # restauro instalacion
                cStep "Restaurando version: $localVer."   
                $cacheFolder = mainGetCacheFolder $localVer
                cacheRestore $cacheFolder $PORTABLE_HOME
                $ver = $localVer
            }
            else
            {
                # resuelvo archivo
                cStep "Resolviendo ubicacion de: $($remote.ver)."            
                $zipPath = mainResolver $remote $SEARCH_FOLDERS $DOWNLOAD_FOLDER
                
                # borro cache anterior
                $null = folderDelete $CACHE_ROOT

                cStep "Resolviendo 7zip tool."
                $exe7z = mainObtener7z $TOOLS_ROOT $remote.szURL $remote.szZipName $remote.szExeName $remote.szMD5 

                # creo cache
                cStep "Creando cache para: $($remote.ver)."
                $cacheExpanded = "$CACHE_ROOT\$($remote.ver)"
                cacheCreate $zipPath $CACHE_ROOT $cacheExpanded $exe7z

                # creo respaldo
                cStep "Respaldando archivos de usuario."
                mainRespaldarArchivosDeUsuario $PORTABLE_BACKUPPATHS $USER_FOLDER $PORTABLE_PKGNAME

                # borro instalacion previa
                cStep "Eliminando instalacion anterior"
                mainEliminarInstalacionAnterior $PORTABLE_HOME

                # restauro instalacion
                cStep "Instalando version: $($remote.ver)."            
                $cacheFolder = mainGetCacheFolder $remote.ver            
                cacheRestore $cacheFolder $PORTABLE_HOME

                $ver = $remote.ver
            }
        }
        else
        {
            # son iguales => local
            cStep "Respaldando archivos de usuario."
            mainRespaldarArchivosDeUsuario $PORTABLE_BACKUPPATHS $USER_FOLDER $PORTABLE_PKGNAME

            # restauro instalacion
            cStep "Restaurando version: $localVer."   
            $cacheFolder = mainGetCacheFolder $localVer
            cacheRestore $cacheFolder $PORTABLE_HOME    
            
            $ver = $localVer
        }
    }
    # solo local => restaurar
    elseif($hasLocal)
    {
        # creo respaldo
        cStep "Respaldando archivos de usuario."
        mainRespaldarArchivosDeUsuario $PORTABLE_BACKUPPATHS $USER_FOLDER $PORTABLE_PKGNAME

        cStep "Restaurando: $localVer."
        $cacheFolder = mainGetCacheFolder $localVer        
        cacheRestore $cacheFolder $PORTABLE_HOME
        $ver = $localVer
    }
    # solo remoto
    elseif($hasRemote)
    {
        # resuelvo archivo
        cStep "Resolviendo ubicacion de: $($remote.ver)."            
        $zipPath = mainResolver $remote $SEARCH_FOLDERS $DOWNLOAD_FOLDER
        
        # borro cache anterior
        $null = folderDelete $CACHE_ROOT

        cStep "Resolviendo 7zip tool."
        $exe7z = mainObtener7z $TOOLS_ROOT $remote.szURL $remote.szZipName $remote.szExeName $remote.szMD5 

        # creo cache
        cStep "Creando cache para: $($remote.ver)."
        $cacheExpanded = "$CACHE_ROOT\$($remote.ver)"
        cacheCreate $zipPath $CACHE_ROOT $cacheExpanded $exe7z

        # creo respaldo
        cStep "Respaldando archivos de usuario."
        mainRespaldarArchivosDeUsuario $PORTABLE_BACKUPPATHS $USER_FOLDER $PORTABLE_PKGNAME

        # borro la instalacion anterior
        cStep "Eliminando instalacion anterior"
        mainEliminarInstalacionAnterior $PORTABLE_HOME

        # restauro instalacion
        cStep "Instalando version: $($remote.ver)."            
        $cacheFolder = mainGetCacheFolder $remote.ver            
        cacheRestore $cacheFolder $PORTABLE_HOME

        $ver = $remote.ver
    }
    # ni local ni remota
    else
    {
        cError "  - No hay cache local ni informacion remota."
        cError "  - No es posible continuar."
        pressAnyKey
        exit
    }

    # autocopiado y lnk
    cStep "Creando accesos directos."
    mainAutocopiarScript $USER_FOLDER $PORTABLE_HOME $DESKTOP_FOLDER $SHORTCUT

    # escribo la version del portable instalado
    cStep "Identificando la version instalada/restaurada."
    portableWriteInstalledVersion "version.json" $PORTABLE_HOME $PORTABLE_PKGNAME $ver 

    # hook final
    afterScriptHook $DOWNLOAD_FOLDER $DESKTOP_FOLDER $USER_FOLDER $SEARCH_FOLDERS $CACHE_ROOT $TOOLS_ROOT

    # ejecuto y verifico que todo salio bien
    explorerOpen $PORTABLE_HOME
}

function mainEliminarInstalacionAnterior($portableHome)
{
    if( -not (folderExists $portableHome) )
    {
        cInfo "  - No se encontro una instalacion anterior."
        return
    }

    cOut "  - Esta operacion podria demorar unos minutos."
    if( folderDelete $portableHome )
    {
        cInfo "  - La instalacion anterior fue removida."
    }
    else
    {
        cWarn "  - La instalacion no pudo ser removida."
    }
}


function mainGetCacheFolder($ver)
{
    $cacheExpanded = "$CACHE_ROOT\$ver"
    return "$cacheExpanded\$PORTABLE_PKGNAME"
}

function mainRespaldarArchivosDeUsuario($foldersToBkp,$userFolder,$pkgName)
{
    if( $null -eq $foldersToBkp -or $foldersToBkp.count -eq 0 )    
    {
        cInfo "  - No se especificaron carpetas para respaldar."
        return
    }

    # sólo continúo si existe al menos un folder para backupear
    $existeAlgunFolder = $false
    foreach ($f in $foldersToBkp)
    {
        if (folderExists $f)
        {
            $existeAlgunFolder = $true
            break
        }
    }

    if( -not $existeAlgunFolder )
    {
        cInfo "  - No se encontraron archivos para respalaldar."
        return
    }

    $bkpNames = @(foldersBackup $foldersToBkp $userFolder $pkgName)
    $names = arrayToString $bkpNames
    if( $bkpNames.count -eq $foldersToBkp.count )
    {
        cInfo "  - Archivos de usuario respaldados en: $userFolder ($names)."    
    }
    else
    {
        cWarn "  - No se pudieron respaldar las carpetas del usuario."
        cAsk  "  - Continuar el proceso o cancelar la instalacion?"
        $opciones = @("Continuar","Cancelar")
        $op = cMenu $opciones 
        if( $op -ne 0 )
        {
            cError "  - Instalacion cancelada."                
            pressAnyKey
            exit
        }
        else
        {
            cWarn "  - Continua instalacion sin respaldo."
        }
    }
}

function mainPreguntarSiRestaurarOActualizar($localVer,$remoteVer)
{
    cAsk "  - Restaurar $localVer o actualizar a ${remoteVer}?"
    $options = @("Restaurar","Actualizar")
    $op = cMenu $options -defaultIndex 0 -indent 5
    return $op
}

function mainResolver($remote,$searchFolders,$downloadFolder)
{
    # veo si ya lo tengo descargado
    $filePath  = fileSearchOnFolders $remote.ver $searchFolders

    if( $null -ne $filePath )
    {
        cInfo "  - $($remote.ver) encontrado en: $filePath."    
    }
    else
    {
        # no lo tiene => descargo
        cWarn "  - Archivo no encontrado. Se requiere descarga."
        portableOpenDownloadURL $remote $downloadFolder
        $filePath = $downloadFolder
    }

    # descomprimo y genero el header
    return "$filePath\$($remote.ver)"
}

function mainAsegurarCondicionesInicial($minCache, $minDrive, $portableHome, $userFolder)
{
    # Obtener las letras de unidad (ej: "C:")
    $cacheDrive = driveGetFromPath $userFolder
    $portableDrive = driveGetFromPath $portableHome

    # Caso 1: Todo está en el mismo disco
    if ($cacheDrive -ieq $portableDrive)
    {
        $totalRequired = $minCache + $minDrive
        $freeSpace = driveGetFreeSpace $cacheDrive

        if ($freeSpace -lt $totalRequired)
        {
            cError "  - Espacio insuficiente en $cacheDrive. Requeridos: ${minCache}GB libres."
            pressAnyKey
            exit
        }
    }
    # Caso 2: El portable va a un disco diferente del caché de usuario
    else
    {
        $freeSpaceCache = driveGetFreeSpace $cacheDrive
        $freeSpaceDrive = driveGetFreeSpace $portableDrive

        # Validar disco de caché
        if ($freeSpaceCache -lt $minCache)
        {
            cError "  - Espacio insuficiente en $cacheDrive (cache). Requeridos: ${minCache}GB libres."
            pressAnyKey
            exit
        }

        # Validar disco del portable
        if ($freeSpaceDrive -lt $minDrive)
        {
            cError "  - Espacio insuficiente en $portableDrive (soft). Requeridos: ${minDrive}GB libres."
            pressAnyKey
            exit
        }
    }

    # Comprobar si la carpeta destino está bloqueada
    if (folderIsLocked $portableHome)
    {
        cError "  - La carpeta $portableHome esta en uso. No se puede continuar."
        pressAnyKey
        exit
    }

    cInfo "  - El equipo cumple los requisitos de almacenamiento."
}

function mainObtener7z($toolsRoot, $szURL,$szZipName,$szExeName,$szMD5) 
{
    $exePath = Join-Path $toolsRoot $szExeName
    $zipPath = Join-Path $toolsRoot $szZipName
    
    if (Test-Path $exePath) 
    {
        cInfo "  - Se encontro en: $exePath."
        return $exePath
    }

    # 2. Intento de descarga
    gdriveDownload $szURL $zipPath

    $ret = $null
    if (Test-Path $zipPath) 
    {
        # Validar ANTES de descomprimir
        $hash = fileGetHash $zipPath
        if ($hash -eq $szMD5) 
        {
            # Descomprimir sólo si el hash coincide
            if (fileUnzip $zipPath $toolsRoot $false) 
            {
                cInfo "  - 7zip se descargo correctamente."
                $ret = $exePath
            }
        }
        else 
        {
            cError "  - Error de integridad en la descarga de 7zip."
        }

        Remove-Item $zipPath -Force
    }

    return $ret
}

# function mainAutocopiarScript($scriptTargetFolder, $portableHomeFolder, $desktopFolder, $executableShortcutObject)
# {
#     $fullfileName = $PSCommandPath

#     # 0. VALIDACIÓN: ¿Ya nos estamos ejecutando desde la carpeta de destino?
#     $currentFolder = Split-Path $fullfileName -Parent
#     $resolvedTarget = (Resolve-Path $scriptTargetFolder -ErrorAction SilentlyContinue).Path
#     if ($null -eq $resolvedTarget) { $resolvedTarget = $scriptTargetFolder }

#     try 
#     {
#         # Obtener el nombre del script usando tu función
#         $scriptNameWithExt = scriptGetName 
#         $scriptNameNoExt   = [System.IO.Path]::GetFileNameWithoutExtension($scriptNameWithExt)

#         # 1. Copiar el script en ejecución a la carpeta destino ($USER_FOLDER)
#         if ($currentFolder -ne $resolvedTarget)
#         {
#             [void](fileCopy $fullfileName $scriptTargetFolder)
#         }

#         # Calcular la ruta exacta del script copiado
#         $copiedScriptPath = Join-Path $scriptTargetFolder $scriptNameWithExt

#         # 2. Armar el objeto para el acceso directo del SCRIPT
#         $SHORTCUT_LAUNCHER = [PSCustomObject]@{ 
#             Name             = $scriptNameNoExt
#             TargetPath       = "powershell.exe"
#             Arguments        = "-NoProfile -ExecutionPolicy Bypass -File `"$copiedScriptPath`""
#             WorkingDirectory = $scriptTargetFolder
#             Description      = "Lanzador del instalador/sincronizador de $PORTABLE_PKGNAME"
#             IconLocation     = "powershell.exe,0"
#             WindowStyle      = 1
#         }

#         # ============================================================
#         # LAS 4 INVOCACIONES A LINKCREATE (Usando los parámetros)
#         # ============================================================
        
#         # A) Los 2 accesos directos para el SCRIPT (Instalador)
#         cInfo "  - Generando enlaces para el instalador/actualizador..."
#         linkCreate $SHORTCUT_LAUNCHER $portableHomeFolder
#         linkCreate $SHORTCUT_LAUNCHER $desktopFolder

#         # B) Los 2 accesos directos para el EJECUTABLE final (Programa)
#         cInfo "  - Generando enlaces para la aplicacion... "
#         linkCreate $executableShortcutObject $portableHomeFolder
#         linkCreate $executableShortcutObject $desktopFolder
#     }
#     catch 
#     {
#         cError "Error en mainAutocopiarScript: $_"
#     }
# }



function mainAutocopiarScript($scriptTargetFolder, $portableHomeFolder, $desktopFolder, $executableShortcutObject)
{
    $fullfileName = $PSCommandPath

    try
    {
        # install-vscode (1).ps1 => install-vscode.ps1
        $scriptNameWithExt = scriptGetName
        $scriptNameWithExt = $scriptNameWithExt -replace ' \(\d+\)(?=\.ps1$)', ''
        $scriptNameNoExt   = [System.IO.Path]::GetFileNameWithoutExtension($scriptNameWithExt)

        # Ruta final del script copiado
        $copiedScriptPath = Join-Path $scriptTargetFolder $scriptNameWithExt

        # Copiar el script con nombre normalizado
        if ($fullfileName -ne $copiedScriptPath)
        {
            [void](Copy-Item -LiteralPath $fullfileName -Destination $copiedScriptPath -Force)
        }

        # 2. Armar el objeto para el acceso directo del SCRIPT
        $SHORTCUT_LAUNCHER = [PSCustomObject]@{
            Name             = $scriptNameNoExt
            TargetPath       = "powershell.exe"
            Arguments        = "-NoProfile -ExecutionPolicy Bypass -File `"$copiedScriptPath`""
            WorkingDirectory = $scriptTargetFolder
            Description      = "Lanzador del instalador/sincronizador de $PORTABLE_PKGNAME"
            IconLocation     = "powershell.exe,0"
            WindowStyle      = 1
        }

        # A) Los 2 accesos directos para el SCRIPT (Instalador)
        cInfo "  - Generando enlaces para el instalador/actualizador..."
        linkCreate $SHORTCUT_LAUNCHER $portableHomeFolder
        linkCreate $SHORTCUT_LAUNCHER $desktopFolder

        # B) Los 2 accesos directos para el EJECUTABLE final (Programa)
        cInfo "  - Generando enlaces para la aplicacion..."
        linkCreate $executableShortcutObject $portableHomeFolder
        linkCreate $executableShortcutObject $desktopFolder
    }
    catch
    {
        cError "Error en mainAutocopiarScript: $_"
    }
}


function mainObtenerDiscoInstall($pkgName, $defaultDrive, $minFreeSpace)
{
    $sn = (scriptGetName)
    if( -not (stringContains $sn $WIZARD_MODE) )
    {
        return $defaultDrive
    }

    cStep "Estableciendo disco de destino."
    
    # 1. Obtener discos fijos y extraíbles listos
    $discosValidos = [System.IO.DriveInfo]::GetDrives() | 
        Where-Object { $_.IsReady -and ($_.DriveType -eq 'Fixed' -or $_.DriveType -eq 'Removable') }

    $opcionesMenu = @()       
    $letrasFiltradas = @()    
    $indicesInstalados = @()  # Guarda qué posiciones del menú tienen la app

    foreach ($d in $discosValidos) 
    {
        $letra = $d.Name.TrimEnd('\')
        $freeGB = [Math]::Truncate($d.TotalFreeSpace / 1GB)

        # REGLA 2 y 6: Filtrar por espacio mínimo
        if ($freeGB -lt $minFreeSpace) { continue }

        # Detectar instalación física real
        $rutaCheck = "$letra\$pkgName"
        $marker = ""
        
        if ([System.IO.Directory]::Exists($rutaCheck)) 
        {
            $marker = " [Instalado]"
            $indicesInstalados += $opcionesMenu.Count
        }

        # --- ALINEACIÓN CORREGIDA ---
        # Forzamos a string limpio sin espacios extras antes de rellenar
        $numString = $freeGB.ToString().Trim()
        $freeGBAlined = stringLpad $numString " " 3

        # Armamos el string sin espacios manuales dentro del paréntesis
        $opcionesMenu += "$letra (${freeGBAlined}GB)$marker"
        $letrasFiltradas += $letra
        #$opcionesMenu += "$letra (${freeGB}GB)$marker"
        #$letrasFiltradas += $letra
    }

    # REGLA 6: Caso catastrófico (Ningún disco apto)
    if ($letrasFiltradas.Count -eq 0) {
        cError "  - Error: No se encontró ninguna unidad con espacio suficiente (${minFreeSpace}GB requeridos)."
        pressAnyKey
        exit
    }
    
    # REGLA 1 y 2: Disco único o un solo disco con espacio
    if ($letrasFiltradas.Count -eq 1) 
    {
        cInfo "  - La instalacion se realizara en el disco: $($letrasFiltradas[0])."
        return $letrasFiltradas[0]
    }

    # REGLA 3: Instalación única (Sin menú, restauración automática)
    if ($indicesInstalados.Count -eq 1) {
        $indiceUnico = $indicesInstalados[0]
        cInfo "  - La instalacion se realizara en el disco: $($letrasFiltradas[$indiceUnico])."
        return $letrasFiltradas[$indiceUnico]
    }

    # REGLAS 4 y 5: Múltiples opciones aptas (Multi-instalación o Elección limpia)
    # Si hay multi-instalación, hace foco en la primera de ellas. Si no, va al índice 0.
    $indicePreseleccion = 0
    if ($indicesInstalados.Count -gt 1) {
        $indicePreseleccion = $indicesInstalados[0]
    }

    # Lanzamos el menú interactivo con timeout
    cAsk "  - Seleccione en que disco prefiere realizar la instalacion."

    $opSelec = cMenu $opcionesMenu  # -timeoutSeconds 2
    
    # Fallback por timeout o cancelación
    if ($null -eq $opSelec -or $opSelec -lt 0 -or $opSelec -ge $letrasFiltradas.Count) {
        $opSelec = $indicePreseleccion
    }

    cInfo "  - La instalacion se realizara en el disco: $($letrasFiltradas[$opSelec])."
    return $letrasFiltradas[$opSelec]
}

# function mainActualizarConfig($driveOk)
# {
#     # Si la unidad elegida es distinta a la que venía por defecto en el deploy
#     if ($driveOk -ine $PORTABLE_DRIVE) 
#     {
#         # Usamos el prefijo $script: para modificar las variables a nivel de archivo
#         $script:PORTABLE_DRIVE = $driveOk
        
#         # El regex "^[a-zA-Z]:" busca la letra de unidad al principio del string y la reemplaza
#         $script:PORTABLE_HOME = $PORTABLE_HOME -replace "^[a-zA-Z]:", $driveOk
#         $script:PORTABLE_MAINPROC = $PORTABLE_MAINPROC -replace "^[a-zA-Z]:", $driveOk
#         $script:PORTABLE_ARGLIST = $driveOk
        
#         # Como PORTABLE_BACKUPPATHS es un array, procesamos cada ruta interna
#         if ($null -ne $PORTABLE_BACKUPPATHS) {
#             $script:PORTABLE_BACKUPPATHS = $PORTABLE_BACKUPPATHS | ForEach-Object { 
#                 $_ -replace "^[a-zA-Z]:", $driveOk 
#             }
#         }
#     }
# }

#_MODULES_PLACEHOLDER_

# llamo a main
main
