@echo off

REM If script is being run from vbs script, go to background task
if "%1"=="task" goto :SWITCHER
title LDSwitcher

REM Detect language
call :findLang es- && call :setLangEs & goto :langSelected

REM Default to English
call :setLangEn
:langSelected

call :clearDualEcho
echo %strInit%

REM Check Windows version
wmic os get Caption /value find "Windows 10" >nul 2>&1 || (
    call :clearDualEcho
    echo %strNotTen1%
    echo %strNotTen2%
    echo.
	echo %strExit%
	pause > nul
	exit /b 1
)

REM Check for admin privileges
mkdir %windir%\checkYourPrivileges >nul 2>&1 && (
	rmdir /s /q %windir%\checkYourPrivileges
    call :clearDualEcho
    echo %strUAC1%
	echo %strUAC2%
	echo.
	echo %strExit%
	pause > nul
	exit /b 2
)

REM Check if more than 1 instance of the installer is running
for /f "delims=" %%i in ('tasklist /fi "WINDOWTITLE eq LDSwitcher" /fo csv /nh ^| find /c /i "cmd.exe"') do (
    if "%%i" neq "1" (
        call :clearDualEcho
        echo %strMultiInstances%
        echo.
        echo %strExit%
        pause > nul
        exit /b 3
    )
)

call :cmdColor
REM Check install status
REM If not installed, go to installer
if not exist "%localappdata%\LDSwitcher\LDSwitcher.bat" goto :install

REM If installed, ask if user wants to modify, uninstall or cancel
call :clearDualEcho
echo %strAlreadyInstalled%
choice /c %strWhatToDoOptions% /n /m %strWhatToDo%
if "%errorlevel%"=="1" goto :install
if "%errorlevel%"=="2" goto :uninstall
if "%errorlevel%"=="3" exit /b
exit /b

:install
REM Define light mode start time (24hs format)
call :timeInput %strLightStart% lightStartMin lightStartStr

REM Define dark mode start time (24hs format)
call :timeInput %strDarkStart% darkStartMin darkStartStr

REM Check if light mode starts before dark mode
if %darkStartMin% leq %lightStartMin% (
    call :clearDualEcho
    echo %strLDWrongOrder%
    echo.
    pause
    goto :install
)

REM Define task bar behaviour
call :clearDualEcho
echo %strTaskBarModeMsg%
echo %strTaskBarOptLight%
echo %strTaskBarOptDark%
echo %strTaskBarOptByTime%
echo.
choice /c %strTaskBarOptions% /n
set /a barMode=%errorlevel%-1

REM Define light and dark wallpapers
call :clearDualEcho
echo %strWpMode%
echo.
choice /c %strYesNo% /n
if "%errorlevel%"=="2" goto :noWallpapers

call :WallpaperInput %strLightWp%
set LightWp=%OutputWallpaper%

call :WallpaperInput %strDarkWp%
set DarkWp=%OutputWallpaper%

:noWallpapers

call :clearDualEcho
echo %strInstalling%

REM Stop previous background process instance
taskkill /fi "WINDOWTITLE eq LDSwitcher Background Process" /f >nul 2>&1

REM Copy required files to separate folder
mkdir "%localappdata%\LDSwitcher\Wallpapers" >nul 2>&1
copy /y %0 "%localappdata%\LDSwitcher\LDSwitcher.bat" >nul 2>&1
del /q "%localappdata%\LDSwitcher\Set-Wallpaper.ps1" >nul 2>&1
dir /b /s /a:a "%localappdata%\LDSwitcher\Wallpapers\*" >nul 2>&1 && (
    for /f "delims=" %%i in ('dir /b /s /a:a "%localappdata%\LDSwitcher\Wallpapers\*"') do (
        del /q %%i >nul 2>&1
    )
)

if not defined LightWp goto :undefinedWpVars
if not defined DarkWp goto :undefinedWpVars
    call :deployWallpaperScript "%localappdata%\LDSwitcher\Set-Wallpaper.ps1"
    for /f "delims=" %%l in ('dir /b %LightWp%') do (
        copy %LightWp% "%localappdata%\LDSwitcher\Wallpapers\1"%%~xl /y >nul 2>&1
    )
    for /f "delims=" %%d in ('dir /b %DarkWp%') do (
        copy %DarkWp% "%localappdata%\LDSwitcher\Wallpapers\0"%%~xd /y >nul 2>&1
    )
:undefinedWpVars

REM Create silent start script
echo Set WshShell = WScript.CreateObject("WScript.Shell") > "%localappdata%\LDSwitcher\LDSwitcher.vbs"
echo WshShell.Run """%localappdata%\LDSwitcher\LDSwitcher.bat"" task", 0, False >> "%localappdata%\LDSwitcher\LDSwitcher.vbs"

REM Create startup registry
reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v LDSwitcher /t REG_SZ /d "\"%localappdata%\LDSwitcher\LDSwitcher.vbs\"" /f >nul 2>&1

REM Save settings to registry
reg add "HKCU\SOFTWARE\NeriLancioni\LDSwitcher" /v lightTime /t REG_SZ /d %lightStartMin% /f >nul 2>&1
reg add "HKCU\SOFTWARE\NeriLancioni\LDSwitcher" /v darkTime /t REG_SZ /d %darkStartMin% /f >nul 2>&1
reg add "HKCU\SOFTWARE\NeriLancioni\LDSwitcher" /v taskBarMode /t REG_SZ /d %barMode% /f >nul 2>&1

REM Run theme changer from startup script
"%localappdata%\LDSwitcher\LDSwitcher.vbs" >nul 2>&1

REM Wait 5 seconds for background process to change current windows theme
choice /t 5 /c ab /d a > nul
call :cmdColor
for /f "delims=x tokens=2" %%i in ('reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme') do (
    call :setWallpaper %%i
)

REM Success message and exit
call :clearDualEcho
echo %strInstallSuccess%
echo.
echo %strLightStartAt% %lightStartStr%
echo %strDarkStartAt% %darkStartStr%
if %barMode%==0 ( echo %strBarIsDark% )
if %barMode%==1 ( echo %strBarIsLight% )
if %barMode%==2 ( echo %strBarIsAuto% )
echo.
echo.
pause
exit /b



:SWITCHER
title LDSwitcher Background Process

REM Load parameters from registry
for /f "skip=2 tokens=1,3 delims= " %%a in ('reg query HKCU\SOFTWARE\NeriLancioni\LDSwitcher') do set /a %%a=%%b

REM Check if needed variables are defined
if not defined lightTime exit /b 3
if not defined darkTime exit /b 4
if not defined taskBarMode exit /b 5

REM Check if wallpaper script is deployed
if exist "%localappdata%\LDSwitcher\Set-Wallpaper.ps1" (
    set wallpaperChange=1
) else (
    set wallpaperChange=0
)

:loop
    REM Set current time as minutes
    echo %time% | findstr /b /c:" " >nul 2>&1 && (
        set /a now=0
    ) || (
        set /a now=%time:~0,1%*600
    )

    set /a now=%now%+%time:~1,1%*60+%time:~3,1%*10+%time:~4,1%

    REM Set light mode if current time is between light and dark mode start times
    REM If not, set dark mode
    set mode=0
    if %now% geq %lightTime% (
        if %now% leq %darkTime% (
            set mode=1
        )
    )

    rem Change system colors
    if %taskBarMode%==2 (
        call :setTheme SystemUsesLightTheme %mode%
    ) else (
        call :setTheme SystemUsesLightTheme %taskBarMode%
    )

    rem Change apps colors and wallpaper if needed
    call :setTheme AppsUseLightTheme %mode% && call :setWallpaper %mode%

    choice /t 5 /c ab /d a > nul
goto :loop
exit /b 0

:setTheme
rem Avoid changing windows registry if there is no need
for /f "delims=x tokens=2" %%i in ('reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v %1') do (
    if "%%i" neq "%2" (
        reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v %1 /t REG_DWORD /d %2 /f >nul 2>&1
        exit /b 0
    )
)
exit /b 1

:setWallpaper
if "%wallpaperChange%"=="0" exit /b
for /f "delims=" %%i in ('dir /b /s /a:a "%localappdata%\LDSwitcher\Wallpapers\" ^| find "\Wallpapers\%1"') do (
    powershell -ExecutionPolicy Bypass -file "%localappdata%\LDSwitcher\Set-Wallpaper.ps1" "%%~fi"
)
exit /b


:uninstall
call :clearDualEcho
choice /c %strYesNo% /n /m %strUninstallQuestion%
if "%errorlevel%" neq "1" (
    call :clearDualEcho
    echo %strUninstallCancel%
    echo.
    pause
    exit /b
)
call :clearDualEcho
echo %strUninstalling%
taskkill /fi "WINDOWTITLE eq LDSwitcher Background Process" /f >nul 2>&1
timeout /t 3 /nobreak > nul
rmdir /s /q "%localappdata%\LDSwitcher\" >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v LDSwitcher /f >nul 2>&1
reg delete "HKCU\SOFTWARE\NeriLancioni\LDSwitcher" /f >nul 2>&1
reg query "HKCU\SOFTWARE\NeriLancioni" | find "\" >nul 2>&1 || reg delete "HKCU\SOFTWARE\NeriLancioni" /f >nul 2>&1

call :clearDualEcho
echo %strUninstallSuccess%
echo.
pause
exit /b

:timeInput
set /a timeAcu=0
set timeAcuStr=
call :timeInput2 012 %1
set /a timeAcu=%timeAcu%+%errorlevel%*600
if "%timeAcu%"=="2" (
    call :timeInput2 0123 %1
) else (
    call :timeInput2 0123456789 %1
)
set /a timeAcu=%timeAcu%+%errorlevel%*60
set timeAcuStr=%timeAcuStr%:
call :timeInput2 012345 %1
set /a timeAcu=%timeAcu%+%errorlevel%*10
call :timeInput2 0123456789 %1
set /a timeAcu=%timeAcu%+%errorlevel%
set %2=%timeAcu%
set %3=%timeAcuStr%
exit /b %timeAcu%

:timeInput2
set message=%2
call :clearDualEcho
echo %message:~1,-1%%timeAcuStr%
choice /c %1 /n > nul
set /a indexOffset=%errorlevel%-1
set timeAcuStr=%timeAcuStr%%indexOffset%
exit /b %indexOffset%

:WallpaperInput
call :clearDualEcho
echo %strWpPath%
set /p OutputWallpaper=%1
for /f "delims== tokens=2" %%i in ('set ^| findstr /b OutputWallpaper=') do set OutputWallpaper="%%~fi"
dir /b %OutputWallpaper% | findstr ".jpg .jpeg .bmp .png .gif" >nul 2>&1 || (
    call :clearDualEcho
    echo %strInvalidWp%
    echo.
    pause
    goto :WallpaperInput
)
exit /b

REM Trying to save some lines xd
:clearDualEcho
cls & echo. & echo.
exit /b

:cmdColor
for /f "delims=x tokens=2" %%i in ('reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme') do (
    if "%%i"=="1" ( color f0 ) else ( color 0f )
)
exit /b

:findLang
if "%1"=="" exit /b 1
if not defined currentLang (
    for /f delims^=^"^ tokens^=2 %%i in ('wmic os get MUILanguages /value ^| find "MUILanguages"') do set currentLang=%%i
)
echo %currentLang% | find /i "%1" > nul
exit /b %errorlevel%

:deployWallpaperScript
rem thanks to this guy https://c-nergy.be/blog/?p=15291
echo param ([string]$Image="") > %1
echo $code = @' >> %1
echo using System.Runtime.InteropServices;  >> %1
echo namespace Win32{  >> %1
echo      public class Wallpaper{  >> %1
echo         [DllImport("user32.dll", CharSet=CharSet.Auto)]  >> %1
echo          static extern int SystemParametersInfo (int uAction , int uParam , string lpvParam , int fuWinIni) ;  >> %1
echo          public static void SetWallpaper(string thePath){  >> %1
echo             SystemParametersInfo(20,0,thePath,3);  >> %1
echo          } >> %1
echo     } >> %1
echo  }  >> %1
echo '@ >> %1
echo add-type $code  >> %1
echo [Win32.Wallpaper]::SetWallpaper($Image) >> %1
exit /b

:setLangEs
set strInit=Inicializando . . .
set strNotTen1=Esta version de Windows no es compatible con la funcionalidad
set strNotTen2=de temas claros y oscuros a nivel de sistema operativo.
set strExit=Presione una tecla para salir . . .
set strUAC1=Este script no necesita permisos administrativos.
set strUAC2=Ejecutelo nuevamente como usuario normal.
set strWhatToDo="(M)odificar, (D)esinstalar o (S)alir:"
set strWhatToDoOptions=MDS
set strLightStart="Ingrese a que hora deberia iniciar el modo claro en formato HH:mm - "
set strDarkStart="Ingrese a que hora deberia iniciar el modo oscuro en formato HH:mm - "
set strLDWrongOrder=El modo oscuro debe iniciar luego del modo claro
set strInstallSuccess=Instalacion completada exitosamente!
set strLightStartAt=El modo claro iniciara a las
set strDarkStartAt=El modo oscuro iniciara a las
set strUninstallQuestion="Esta seguro que desea desinstalar LDSwitcher? (S/N):"
set strYesNo=SN
set strUninstallCancel=Ha cancelado la desinstalacion
set strUninstallSuccess=LDSwitcher fue desinstalado de su equipo
set strAlreadyInstalled=LDSwitcher ya esta instalado. Que desea hacer?
set strInstalling=Instalando . . .
set strUninstalling=Desinstalando . . .
set strTaskBarModeMsg=Elija el comportamiento de la barra de tareas:
set strTaskBarOptDark=(O) Siempre oscuro
set strTaskBarOptLight=(C) Siempre claro
set strTaskBarOptByTime=(H) Segun horario
set strTaskBarOptions=OCH
set strBarIsDark=La barra de tareas sera siempre oscura
set strBarIsLight=La barra de tareas sera siempre clara
set strBarIsAuto=La barra de tareas cambiara de color segun el horario
set strMultiInstances=No puede haber mas de una instancia de LDSwitcher simultaneamente.
set strWpMode=Desea definir fondos de pantalla para cada modo? (S/N)
set strLightWp="Fondo del modo claro: "
set strDarkWp="Fondo del modo oscuro: "
set strWpPath=Escriba la ruta completa de la imagen o arrastrela aqui.
set strInvalidWp=El archivo no es una imagen o no existe.
exit /b

:setLangEn
set strInit=Initializing . . .
set strNotTen1=This Windows version is not compatible with OS-level
set strNotTen2=light and dark theme.
set strExit=Press any key to exit . . .
set strUAC1=This script does not need administrative privileges.
set strUAC2=Run it again as normal user.
set strWhatToDo="(M)odify, (U)ninstall o (E)xit:"
set strWhatToDoOptions=MUE
set strLightStart="Enter when light mode should start in HH:mm format"
set strDarkStart="Enter when dark mode should start in HH:mm format"
set strLDWrongOrder=Dark mode must start after light mode.
set strInstallSuccess=Installation completed successfully!
set strLightStartAt=Light mode will start at
set strDarkStartAt=Dark mode will start at
set strUninstallQuestion="Are you sure you want to uninstall LDSwitcher? (Y/N):"
set strYesNo=YN
set strUninstallCancel=Uninstallation canceled.
set strUninstallSuccess=LDSwitcher was uninstalled from your device.
set strAlreadyInstalled=LDSwitcher is already installed. What would you like to do?
set strInstalling=Installing . . .
set strUninstalling=Uninstalling . . .
set strTaskBarModeMsg=Choose the task bar behavior:
set strTaskBarOptDark=(D) Always dark
set strTaskBarOptLight=(L) Always light
set strTaskBarOptByTime=(T) Defined by time
set strTaskBarOptions=DLT
set strBarIsDark=Task bar will always be dark
set strBarIsLight=Task bar will always be light
set strBarIsAuto=Task bar will change depending on time
set strMultiInstances=There cannot be more than one LDSwitcher instance simultaneously.
set strWpMode=Would you like to set wallpapers for each mode? (Y/N)
set strLightWp="Light mode wallpaper: "
set strDarkWp="Dark mode wallpaper: "
set strWpPath=Write the picture full path here or drag it here.
set strInvalidWp=File is not a picture or does not exist.
exit /b