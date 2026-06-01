param(
    [int]$case
)


Import-Module "$PSScriptRoot\..\lib\core\assert.psm1" -Force
Import-Module "$PSScriptRoot\..\lib\core\environment.psm1" -Force
Import-Module "$PSScriptRoot\..\lib\core\string.psm1" -Force
Import-Module "$PSScriptRoot\..\lib\core\net.psm1" -Force
Import-Module "$PSScriptRoot\..\lib\core\date.psm1" -Force
Import-Module "$PSScriptRoot\..\lib\core\console.psm1" -Force
Import-Module "$PSScriptRoot\..\lib\core\filesystem.psm1" -Force
Import-Module "$PSScriptRoot\..\lib\core\web.psm1" -Force



# =========================================================
# CONFIG
# =========================================================

# Variables de entorno simuladas
$FILE_LATEST = "TestInstaller_1.0.1.zip"
$FILE_OLD = "TestInstaller_1.0.0.zip"
$CACHESTAT_LATEST = "$($FILE_LATEST)_stats.json"
$CACHESTAT_OLD = "$($FILE_OLD)_stats.json"
$PORTABLE_PKGNAME = "testInstaller"
$PORTABLE_HOME    = "C:\$PORTABLE_PKGNAME"
$CACHE_ROOT       = "$env:USERPROFILE\temp\.cache\$PORTABLE_PKGNAME"
$CACHE_EXPANDED   = "$CACHE_ROOT\$FILE_LATEST"
$DOWNLOAD_FOLDER  = "$env:USERPROFILE\Downloads"

# =========================================================
# HELPERS
# =========================================================

function environmentReset()
{
    cStep "Reseteando el entorno de pruebas."

    # remuevo el cache
    cInfo "  - Borrando: $CACHE_ROOT."
    $null = folderDelete "$CACHE_ROOT\"
    $borrado = folderExists "$CACHE_ROOT\"
    assertFalse $borrado "No se pudo remover: $CACHE_ROOT\."

    # remuevo la instalacion
    cInfo "  - Borrando: $PORTABLE_HOME."
    $null = folderDelete $PORTABLE_HOME
    $borrado = folderExists "$PORTABLE_HOME"
    assertFalse $borrado "No se pudo remover: $PORTABLE_HOME\."

    # remuevo los zip
    $f = "$DOWNLOAD_FOLDER\$FILE_LATEST"
    cInfo "  - Borrando: $f."
    $null = fileDelete $f
    $borrado = fileExists $f
    assertFalse $borrado "No se pudo remover: $f."

    $f = "$DOWNLOAD_FOLDER\$FILE_OLD"
    cInfo "  - Borrando: $f."
    $null = fileDelete $f
    $borrado = fileExists $f
    assertFalse $borrado "No se pudo remover: $f."
}

function cacheCreate()
{
    cStep "Creando cache"

    # descomprimo
    cInfo "  - Expandiendo $FILE_LATEST en $CACHE_EXPANDED."
    $fullFilePath = "resources\$FILE_LATEST" 
    $null = fileUnzip $fullFilePath $CACHE_EXPANDED
    $f = "$CACHE_EXPANDED\$PORTABLE_PKGNAME"
    assertTrue (folderExists $f) "No se pudo expandir: $FILE_LATEST en: $CACHE_EXPANDED" 

    # creo las estadisticas
    $null = folderCreateStats $CACHE_EXPANDED
    $f = "$CACHE_EXPANDED\$CACHESTAT_LATEST"
    assertTrue (fileExists $f) "No se pudo crear: $f" 
}

function cacheDowngrade()
{
    cInfo "  - Renombrando $CACHESTAT_LATEST como $CACHESTAT_OLD."
    $null = fileRename "$CACHE_EXPANDED\$CACHESTAT_LATEST" $CACHESTAT_OLD
    $f = "$CACHE_EXPANDED\$CACHESTAT_OLD"
    assertTrue (fileExists $f) "No se pudo renombrar $CACHESTAT_LATEST como: $f."

    cInfo "  - Renombrando $CACHE_EXPANDED\$FILE_LATEST a: $CACHE_EXPANDED\$FILE_OLD."
    $null = folderRename $CACHE_EXPANDED $FILE_OLD
    $f = "$CACHE_EXPANDED\$FILE_OLD"
    assertFalse (folderExists $f) "No se pudo renombrar $CACHE_EXPANDED\$FILE_LATEST como: $f."
}

function cacheCorrupt()
{
    cInfo "  - Corrompiendo el cache."
    $null = fileRename "$CACHE_EXPANDED\$CACHESTAT_LATEST" "xx.xx"
    $f = "$CACHE_EXPANDED\$CACHESTAT_LATEST"
    assertFalse (fileExists $f) "No se pudo renombrar: $f."
}

function installationCreate()
{
    cStep "Creando instalacion."

    # descomprimo
    cInfo "  - Expandiendo $FILE_LATEST en C:\"
    $fullFilePath = "resources\$FILE_LATEST" 
    $null = fileUnzip $fullFilePath "C:\" $false
    $f = "$PORTABLE_HOME"
    assertTrue (folderExists $f) "No se pudo expandir: $FILE_LATEST en: $PORTABLE_HOME." 
}

function zipPlace($file)
{
    cStep "Copiando: $file a: $DOWNLOAD_FOLDER."

    # descomprimo
    $null = fileCopy "resources\$file" $DOWNLOAD_FOLDER 
    $f = "$DOWNLOAD_FOLDER\$file"
    assertTrue (fileExists $f) "No se pudo copiar: $file a: $DOWNLOAD_FOLDER" 
    cInfo "  - Archivo copiado."
}

function caseDetails($caseNo, $caseDesciption, $caseChecklist) 
{
    cOut ""
    cBlink "CASO $caseNo" 1000
    cInfo "  - Situacion: $caseDesciption"
    cInfo "    Checklist:"

    foreach($item in $caseChecklist)
    {
        cWarn "     - $item"
    }
}

# =========================================================
# CASES
# =========================================================

function case1()
{
    environmentReset

    $checklist = @(
      "Debe solicitar descarga."
      "Debe retomar la instalacion y finalizar correctamente."
    )

    caseDetails 1 "NO: cache, archivo, instalacion previa." $checklist
}

function case2()
{
    environmentReset
    $null = zipPlace $FILE_LATEST

    $checklist = @(
      "Debe verificar que existe el archvio y esta actualizado."
      "Debe retomar la instalacion y finalizar sin interaccion."
    )

    caseDetails 2 "Hay archivo. NO hay: cache ni instalacion previa." $checklist
}

function case3()
{
    # Cache OK latest
    # Installation exists

    environmentReset
    cacheCreate
    installationCreate

    $checklist = @(
      "Debe restaurar la instalacion."
    )

    caseDetails 3 "Hay cache y esta al dia. Hay instalacion previa." $checklist
}

function case4()
{
    # Cache old
    # Installation exists

    environmentReset
    cacheCreate
    cacheDowngrade
    installationCreate

    $descr = "Hay cache viejo, existe actualizacion. Hay instalacion previa."
    $checklist = @(
      "Debe mostrar que existe una actualizacion."
      "Debe preguntar RESTAURAR o ACTUALIZAR."
      "Si elijo RESTAURAR => restaura la instalacion actual."
      "Si elijo ACTUALIZAR => descarga el archivo e crea una nueva instalacion."
    )

    caseDetails 4 $descr $checklist
 }

function case5()
{
    environmentReset
    cacheCreate

    $descr = "Hay cache actualizado, no existe instalacion previa."
    $checklist = @(
      "Debe mostrar que la version local esta actualizada."
      "Debe instalar la aplicacion."
    )

    caseDetails 5 $descr $checklist
}


function case6()
{
    environmentReset
    cacheCreate
    cacheDowngrade

    $descr = "Hay cache desactualiado, no existe instalacion previa."
    $checklist = @(
      "Debe mostrar que la version local esta desactualizada."
      "Debe preguntar si quiero actualizar o utilizar la actual."
      "Si actualizo => descargar e instalar."
      "Si restauro => instalar la aplicacion."
    )

    caseDetails 6 $descr $checklist
}

function case7()
{
    # No ZIP
    # Cache latest
    # No installation

    environmentReset
    cacheCreate

    $descr = "Hay cache actualizado, no existe instalacion previa."
    $checklist = @(
      "Debe mostrar que la version local esta actualizada."
      "Debe instalar sin intervension del usuario."
    )

    caseDetails 7 $descr $checklist
}

function case8()
{
    # No ZIP
    # Cache old
    # No installation

    environmentReset
    cacheCreate
    cacheDowngrade

    $descr = "Hay cache desactualizado, no hay archivo, no existe instalacion previa."
    $checklist = @(
      "Debe preguntar: INSTALAR o ACTUALIZAR."
      "ACTUALIZAR => descargar e instalar."
      "INSTALAR => instala version actual."
    )

    caseDetails 8 $descr $checklist
}

function case9()
{
    # ZIP latest
    # Corrupt cache
    # No installation

    environmentReset
    zipPlace $FILE_LATEST
    cacheCreate
    cacheCorrupt

    $descr = "Hay cache, esta corrupto. hay archivo, no existe instalacion previa."
    $checklist = @(
      "Debe crear cache."
      "Debe instalar."
    )

    caseDetails 9 $descr $checklist
}

function case10()
{
    # ZIP latest
    # Corrupt cache
    # Installation exists

    environmentReset
    zipPlace $FILE_LATEST
    installationCreate
    cacheCreate
    cacheCorrupt

    $descr = "Cache corrupto, hay archivo, hay instalacion previa."
    $checklist = @(
      "Debe crear el cache."
      "Debe eliminar la instalacion."
      "Debe instalar."
    )

    caseDetails 10 $descr $checklist

}

function case11()
{
    # ZIP latest
    # Installation exists

    environmentReset
    zipPlace $FILE_LATEST
    installationCreate

    $descr = "No hay cache, hay archivo, hay instalacion previa."
    $checklist = @(
      "Debe crear el cache."
      "Debe eliminar la instalacion."
      "Debe instalar."
    )

    caseDetails 11 $descr $checklist
}

function case12()
{
    # Cache OK
    # Installation exists
    # Internet OFF

    environmentReset
    cacheCreate
    installationCreate
    internetDisable
    cInfo "  - Internet fue deshabilitada."

    $descr = "Hay cache, hay instalacion previa, no hay Internet"
    $checklist = @(
      "Debe decir que no hay internet."
      "Debe restaurar la instalacion actual."
    )

    caseDetails 12 $descr $checklist

    cBlink "Presione una tecla para restaurar Internet."
    pressAnyKey

    cInfo "  - Internet fue reestablecida."
    internetEnable
}

function case13()
{
    # No cache
    # No installation
    # Internet OFF

    environmentReset
    internetDisable
    cInfo "  - Internet fue deshabilitada."
    $descr = "No hay cache ni instalacion previa, no hay Internet"
    $checklist = @(
      "Debe decir que no puede continuar."
    )

    caseDetails 13 $descr $checklist

    cBlink "Presione una tecla para restaurar Internet."
    pressAnyKey

    cInfo "  - Internet fue reestablecida."
    internetEnable
}

function case14()
{
    # Corrupt cache
    # No installation
    # Internet OFF

    environmentReset
    cacheCreate
    cacheCorrupt
    internetDisable
    cInfo "  - Internet fue deshabilitada."
    $descr = "Hay cache corrupto, sin instalacion previa ni Internet"
    $checklist = @(
      "Debe decir que el cache esta corrupto."
      "No hay Internet."
      "No puede continuar."
    )

    caseDetails 14 $descr $checklist

    cBlink "Presione una tecla para restaurar Internet."
    pressAnyKey

    cInfo "  - Internet fue reestablecida."
    internetEnable
}

function case15()
{
    # Valid cache
    # No installation
    # Internet OFF

    environmentReset
    cacheCreate
    internetDisable
    cInfo "  - Internet fue deshabilitada."
    $descr = "Hay cache. No hay instalacion previa ni Internet"
    $checklist = @(
      "Debe decir la version del cache local."
      "No hay Internet."
      "Instalar la version actual."
    )

    caseDetails 15 $descr $checklist

    cBlink "Presione una tecla para restaurar Internet."
    pressAnyKey

    cInfo "  - Internet fue reestablecida."
    internetEnable
}


# =========================================================
# MAIN
# =========================================================


switch($case)
{
    "1"  { case1 }
    "2"  { case2 }
    "3"  { case3 }
    "4"  { case4 }
    "5"  { case5 }
    "6"  { case6 }
    "7"  { case7 }
    "8"  { case8 }
    "9"  { case9 }
    "10" { case10 }
    "11" { case11 }
    "12" { case12 }
    "13" { case13 }
    "14" { case14 }
    "15" { case15 }
    default 
    { 
        Write-Host "Usage: .\testcasescase.ps1 [caseNo]" 
    }
}

