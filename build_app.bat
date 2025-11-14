@echo off
setlocal enabledelayedexpansion

echo ========================================
echo         FLUTTER FLAVOR BUILDER
echo ========================================

:: Elegir flavor
echo.
echo Elige el flavor:
echo [1] Automotora Argentina
echo [2] Parabrisas Ejido
echo [3] Resysol
set /p FLAVOR_OPTION=Opcion:

if "%FLAVOR_OPTION%"=="1" (
    set FLAVOR_BASE=automotoraargentina
) else if "%FLAVOR_OPTION%"=="2" (
    set FLAVOR_BASE=parabrisasejido
) else if "%FLAVOR_OPTION%"=="3" (
    set FLAVOR_BASE=resysol
) else (
    echo Opcion invalida. Saliendo...
    exit /b
)

:: Elegir entorno (QA o Prod) para todos los flavors
echo.
echo Elige el entorno:
echo [1] QA
echo [2] Produccion
set /p ENV_OPTION=Opcion:

if "%ENV_OPTION%"=="1" (
    set IS_PROD=false
    set FLAVOR_SUFFIX=Qa
) else if "%ENV_OPTION%"=="2" (
    set IS_PROD=true
    set FLAVOR_SUFFIX=Prod
) else (
    echo Opcion invalida. Saliendo...
    exit /b
)

:: Construir el nombre completo del flavor
set FLAVOR_FULL=%FLAVOR_BASE%%FLAVOR_SUFFIX%

:: Mostrar advertencia si se selecciona Resysol Prod (si aún no existe)
if "%FLAVOR_BASE%"=="resysol" if "%IS_PROD%"=="true" (
    echo.
    echo ⚠ ADVERTENCIA: Resysol Produccion podria no estar configurado aun en el build.gradle
    echo Si falla la compilacion, verifica que el flavor 'resysolProd' este definido.
    echo.
    timeout /t 3 /nobreak > nul
)

:: Elegir modo de build (release o debug)
echo.
echo Elige el modo de build:
echo [1] Release
echo [2] Debug
set /p BUILD_OPTION=Opcion:

if "%BUILD_OPTION%"=="1" (
    set BUILD_MODE=release
) else if "%BUILD_OPTION%"=="2" (
    set BUILD_MODE=debug
) else (
    echo Opcion invalida. Saliendo...
    exit /b
)

:: Elegir plataformas (múltiple selección)
echo.
echo Elige las plataformas (puedes seleccionar varias separadas por comas):
echo [1] APK (Android)
echo [2] Web
echo [3] Windows
echo [4] Todas las plataformas
set /p PLATFORM_OPTIONS=Opciones (ej: 1,2,3):

:: Procesar selección de plataformas
set BUILD_APK=false
set BUILD_WEB=false
set BUILD_WINDOWS=false

if "%PLATFORM_OPTIONS%"=="4" (
    set BUILD_APK=true
    set BUILD_WEB=true
    set BUILD_WINDOWS=true
) else (
    for %%i in (%PLATFORM_OPTIONS%) do (
        if "%%i"=="1" set BUILD_APK=true
        if "%%i"=="2" set BUILD_WEB=true
        if "%%i"=="3" set BUILD_WINDOWS=true
    )
)

:: Mostrar resumen de selección
echo.
echo ========================================
echo RESUMEN DE COMPILACION:
echo Flavor: %FLAVOR_FULL%
echo Modo: %BUILD_MODE%
echo Plataformas seleccionadas:
if "%BUILD_APK%"=="true" echo   - APK (Android)
if "%BUILD_WEB%"=="true" echo   - Web
if "%BUILD_WINDOWS%"=="true" echo   - Windows
echo ========================================
echo.

:: Verificar que se seleccionó al menos una plataforma
if "%BUILD_APK%"=="false" if "%BUILD_WEB%"=="false" if "%BUILD_WINDOWS%"=="false" (
    echo Error: No se selecciono ninguna plataforma. Saliendo...
    pause
    exit /b
)

:: --- APK ---
if "%BUILD_APK%"=="true" (
    echo ========================================
    echo COMPILANDO APK...
    echo ========================================
    flutter build apk --flavor %FLAVOR_FULL% --%BUILD_MODE% --dart-define=FLAVOR=%FLAVOR_BASE% --dart-define=IS_PROD=%IS_PROD%
    if errorlevel 1 (
        echo Error al compilar APK
        echo.
        echo Si el error es porque el flavor no existe, verifica que este definido en build.gradle
        pause
        exit /b
    )
    echo ✓ APK compilado exitosamente
    echo.
)

:: --- Web ---
if "%BUILD_WEB%"=="true" (
    echo ========================================
    echo COMPILANDO WEB...
    echo ========================================
    flutter build web --%BUILD_MODE% --dart-define=FLAVOR=%FLAVOR_BASE% --dart-define=IS_PROD=%IS_PROD%
    if errorlevel 1 (
        echo Error al compilar Web
        pause
        exit /b
    )
    echo ✓ Web compilado exitosamente
    echo.
)

:: --- Windows ---
if "%BUILD_WINDOWS%"=="true" (
    echo ========================================
    echo COMPILANDO WINDOWS...
    echo ========================================
    echo Verificando icono de Windows para %FLAVOR_BASE%...
    
    :: Verificar si existe carpeta específica del flavor, sino usar carpeta genérica
    if exist "windows_assets\%FLAVOR_BASE%\app_icon.ico" (
        echo Copiando icono específico para %FLAVOR_BASE%...
        copy /Y "windows_assets\%FLAVOR_BASE%\app_icon.ico" "windows\runner\resources\app_icon.ico"
    ) else if exist "windows_assets\default\app_icon.ico" (
        echo Copiando icono por defecto...
        copy /Y "windows_assets\default\app_icon.ico" "windows\runner\resources\app_icon.ico"
    ) else (
        echo ⚠ ADVERTENCIA: No se encuentra icono específico para %FLAVOR_BASE%
        echo Se usará el icono por defecto de Flutter
    )
    
    flutter build windows --%BUILD_MODE% --dart-define=FLAVOR=%FLAVOR_BASE% --dart-define=IS_PROD=%IS_PROD%
    if errorlevel 1 (
        echo Error al compilar Windows
        pause
        exit /b
    )
    echo ✓ Windows compilado exitosamente
    echo.
)

echo ========================================
echo COMPILACION COMPLETADA EXITOSAMENTE
echo ========================================
echo.
pause