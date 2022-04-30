@echo off

REM If script is being run from vbs script, go to background task
if "%~1"=="BackgroundTask" goto :SWITCHER
title LDSwitcher

for /f "delims=: tokens=2" %%i in ('chcp') do set /a currentChcp=%%i
chcp 65001 > nul

REM Detect language
call :setLangEs && goto :langSelected

REM Default to English
call :setLangEn
:langSelected

call :banner
echo %strInit%

REM Check Windows version
wmic os get Caption /value | findstr /c:"Windows 10" /c:"Windows 11" >nul 2>&1 || (
    call :banner
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
    call :banner
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
        call :banner
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

REM Check if first argument is a bat or cmd file
echo '%~x1' | findstr /i /c:"'.bat'" /c:"'.cmd'" >nul 2>&1 && (
    if exist "%~f1" (
        goto :installAddon
    )
)

REM If installed, ask if user wants to modify, uninstall or cancel
call :banner
echo %strAlreadyInstalled%
choice /c %strWhatToDoOptions% /n /m %strWhatToDo%
if "%errorlevel%"=="1" goto :install
if "%errorlevel%"=="2" goto :uninstall
if "%errorlevel%"=="3" exit /b
exit /b

:install
REM Define light mode start time (24hs format)
call :timeInput %strLightStart% lightStartMin lightStartStr lightTime

REM Define dark mode start time (24hs format)
call :timeInput %strDarkStart% darkStartMin darkStartStr darkTime

REM Check if light mode starts before dark mode
if %darkStartMin% leq %lightStartMin% (
    call :banner
    echo %strLDWrongOrder%
    echo.
    pause
    goto :install
)

REM Define task bar behaviour
call :banner
echo %strTaskBarModeMsg%
echo %strTaskBarOptLight%
echo %strTaskBarOptDark%
echo %strTaskBarOptByTime%
echo.
choice /c %strTaskBarOptions% /n
set /a barMode=%errorlevel%-1

REM Define light and dark wallpapers
call :banner
echo %strWpMode%
echo.
choice /c %strYesNo% /n
if "%errorlevel%"=="2" goto :noWallpapers

call :WallpaperInput %strLightWp%
set LightWp=%OutputWallpaper%

call :WallpaperInput %strDarkWp%
set DarkWp=%OutputWallpaper%

:noWallpapers

call :banner
echo %strInstalling%

REM Stop previous background process instance
taskkill /fi "WINDOWTITLE eq LDSwitcher Background Process" /f >nul 2>&1

REM Copy required files to separate folder
mkdir "%localappdata%\LDSwitcher\Wallpapers" >nul 2>&1
mkdir "%localappdata%\LDSwitcher\Addons\OnThemeChange" >nul 2>&1
mkdir "%localappdata%\LDSwitcher\Addons\Periodical" >nul 2>&1
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
echo WshShell.Run """%localappdata%\LDSwitcher\LDSwitcher.bat"" BackgroundTask", 0, False >> "%localappdata%\LDSwitcher\LDSwitcher.vbs"

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
chcp %currentChcp% > nul
call :cmdColor
for /f "delims=x tokens=2" %%i in ('reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme') do (
    call :setWallpaper %%i
)
chcp 65001 > nul

REM Success message and exit
call :banner
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



:installAddon
REM Check if first line indicates the folder to copy to
type "%~f1" | findstr /n . | findstr /b /c:"1:::OnThemeChange" >nul 2>&1 && (
    set errorlevel=1
    goto :skipAddonChoice
)
type "%~f1" | findstr /n . | findstr /b /c:"1:::Periodical" >nul 2>&1 && (
    set errorlevel=2
    goto :skipAddonChoice
)

REM Ask the user when to run the addon
call :banner
echo %strAddonInstallText%
echo %~f1
echo.
echo %strOptAlongWindows%
echo %strOptPeriodical%
choice /c %strAddonOptions% /n
:skipAddonChoice
if %errorlevel%==1 (
    set folder=OnThemeChange
) else (
    set folder=Periodical
)

REM Copy addon to addons folder, kill current instance of background process, re-run LDSwitcher
call :banner
echo %strInstalling%
copy /y "%~f1" "%localappdata%\LDSwitcher\Addons\%folder%\" >nul 2>&1
taskkill /fi "WINDOWTITLE eq LDSwitcher Background Process" /f >nul 2>&1
"%localappdata%\LDSwitcher\LDSwitcher.vbs" >nul 2>&1

call :banner
echo %strAddonInstalledOK%
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
if not defined enableLogging set enableLogging=0

if "%enableLogging%"=="1" (
    mkdir "%localappdata%\LDSwitcher\Logs\" >nul 2>&1
)

REM Check if wallpaper script is deployed
if exist "%localappdata%\LDSwitcher\Set-Wallpaper.ps1" (
    set wallpaperChange=1
) else (
    set wallpaperChange=0
)

REM Check if periodical addons exist
dir /b /s "%localappdata%\LDSwitcher\Addons\Periodical\" | findstr /e /c:".cmd" /c:".bat" && (
    set execPeriodicalAddons=1
) || (
    set execPeriodicalAddons=0
)

REM Check if on-change addons exist
dir /b /s "%localappdata%\LDSwitcher\Addons\OnThemeChange\" | findstr /e /c:".cmd" /c:".bat" && (
    set execOnThemeChangeAddons=1
) || (
    set execOnThemeChangeAddons=0
)

:loop
    REM Set current time as minutes
    set /a now=%time:~0,1%*600+%time:~1,1%*60+%time:~3,1%*10+%time:~4,1%
    if "%enableLogging%"=="1" (
        echo Last loop ran at %time% > "%localappdata%\LDSwitcher\Logs\LastLoopRunTime.txt"
    )

    REM Set light mode if current time is between light and dark mode start times, else set dark mode
    set mode=0
    if %now% geq %lightTime% (
        if %now% lss %darkTime% (
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
    call :setTheme AppsUseLightTheme %mode% && (call :setWallpaper %mode% & call :callOnThemeChangeAddons %mode%)
    call :callPeriodicalAddons %mode%

    choice /t 5 /c ab /d a > nul
goto :loop

:setTheme
rem Avoid changing windows registry if there is no need
reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v %1 | findstr /e 0x%2 >nul 2>&1 || (
    reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v %1 /t REG_DWORD /d %2 /f >nul 2>&1
    exit /b 0
)
exit /b 1

:setWallpaper
if "%wallpaperChange%"=="0" exit /b
for /f "delims=" %%i in ('dir /b /s "%localappdata%\LDSwitcher\Wallpapers\" ^| find "\Wallpapers\%1"') do (
    powershell -ExecutionPolicy Bypass -file "%localappdata%\LDSwitcher\Set-Wallpaper.ps1" "%%~fi"
)
exit /b

:callOnThemeChangeAddons
if "%execOnThemeChangeAddons%"=="0" exit /b
for /f "delims=" %%i in ('dir /b /s "%localappdata%\LDSwitcher\Addons\OnThemeChange\" ^| findstr /e /c:".cmd" /c:".bat"') do (
    call "%%~fi" %1
)
exit /b

:callPeriodicalAddons
if "%execPeriodicalAddons%"=="0" exit /b
for /f "delims=" %%i in ('dir /b /s "%localappdata%\LDSwitcher\Addons\Periodical\" ^| findstr /e /c:".cmd" /c:".bat"') do (
    call "%%~fi" %1
)
exit /b


:uninstall
call :banner
choice /c %strYesNo% /n /m %strUninstallQuestion%
if "%errorlevel%" neq "1" (
    call :banner
    echo %strUninstallCancel%
    echo.
    pause
    exit /b
)
call :banner
echo %strUninstalling%
taskkill /fi "WINDOWTITLE eq LDSwitcher Background Process" /f >nul 2>&1
timeout /t 3 /nobreak > nul
rmdir /s /q "%localappdata%\LDSwitcher\" >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v LDSwitcher /f >nul 2>&1
reg delete "HKCU\SOFTWARE\NeriLancioni\LDSwitcher" /f >nul 2>&1
reg query "HKCU\SOFTWARE\NeriLancioni" | find "\" >nul 2>&1 || reg delete "HKCU\SOFTWARE\NeriLancioni" /f >nul 2>&1

call :banner
echo %strUninstallSuccess%
echo.
pause
exit /b

:timeInput
call :MinutesToHHMM %4 currentHHMM
set /a timeAcu=0
set timeAcuStr=
call :timeInput2 012 %1 %currentHHMM% __:__
set /a timeAcu=%timeAcu%+%errorlevel%*600
if "%timeAcu%"=="2" (
    call :timeInput2 0123 %1 %currentHHMM% _:__
) else (
    call :timeInput2 0123456789 %1 %currentHHMM% _:__
)
set /a timeAcu=%timeAcu%+%errorlevel%*60
set timeAcuStr=%timeAcuStr%:
call :timeInput2 012345 %1 %currentHHMM% __
set /a timeAcu=%timeAcu%+%errorlevel%*10
call :timeInput2 0123456789 %1 %currentHHMM% _ 
set /a timeAcu=%timeAcu%+%errorlevel%
set %2=%timeAcu%
set %3=%timeAcuStr%
exit /b %timeAcu%

:timeInput2
set message=%2
call :banner
echo %message:~1,-1%
if "%3" neq "none" echo %strCurrentValue% %3
echo %strNewValue% %timeAcuStr%%4
choice /c %1 /n > nul
set /a indexOffset=%errorlevel%-1
set timeAcuStr=%timeAcuStr%%indexOffset%
exit /b %indexOffset%

:MinutesToHHMM
reg query HKCU\SOFTWARE\NeriLancioni\LDSwitcher /v %1 >nul 2>&1
if "%errorlevel%" neq "0" (
    set %2=none
    exit /b
)
for /f "delims=" %%i in ('reg query HKCU\SOFTWARE\NeriLancioni\LDSwitcher /v %1') do set InputMinutes=%%i
set /a InputMinutes=%InputMinutes:~-4%
set /a AuxHH=%InputMinutes%/60
set /a AuxMM=%InputMinutes%-%AuxHH%*60
if %AuxHH% leq 9 set AuxHH=0%AuxHH%
if %AuxMM% leq 9 set AuxMM=0%AuxMM%
set %2=%AuxHH%:%AuxMM%
set InputMinutes=
set AuxHH=
set AuxMM=
exit /b

:WallpaperInput
call :banner
echo %strWpPath%
set /p OutputWallpaper=%1
for /f "delims== tokens=2" %%i in ('set ^| findstr /b OutputWallpaper=') do set OutputWallpaper="%%~fi"
dir /b %OutputWallpaper% | findstr ".jpg .jpeg .bmp .png .gif" >nul 2>&1 || (
    call :banner
    echo %strInvalidWp%
    echo.
    pause
    goto :WallpaperInput
)
exit /b

:cmdColor
for /f "delims=x tokens=2" %%i in ('reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme') do (
    if "%%i"=="1" ( color f0 ) else ( color 0f )
)
exit /b

:deployWallpaperScript
rem Thanks to this guy https://c-nergy.be/blog/?p=15291
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

:banner
cls
echo.
echo ===================================================================================
echo ^|                                                                                 ^|
echo ^|  #       #####     ######                                                       ^|
echo ^|  #       #    #   #                                                             ^|
echo ^|  #       #     #  #         #         #   #  #####  #####  #   #  #####  ####   ^|
echo ^|  #       #     #   ######   #         #   #    #    #      #   #  #      #   #  ^|
echo ^|  #       #     #         #   #   #   #    #    #    #      #####  ###    ####   ^|
echo ^|  #       #    #          #   #  # #  #    #    #    #      #   #  #      #  #   ^|
echo ^|  ######  #####     ######     ##   ##     #    #    #####  #   #  #####  #   #  ^|
echo ^|                                                                                 ^|
echo ===================================================================================
echo.
echo.
exit /b

:findLang
if not defined currentLang (
    for /f delims^=^"^ tokens^=2 %%i in ('wmic os get MUILanguages /value ^| find "MUILanguages"') do set currentLang=%%i
)
echo %currentLang% | find /i "%1" > nul
exit /b %errorlevel%

:setLangEs
call :findLang es- || exit /b 1
set strInit=Inicializando . . .
set strNotTen1=Esta version de Windows no es compatible con la funcionalidad
set strNotTen2=de temas claros y oscuros a nivel de sistema operativo.
set strExit=Presione una tecla para salir . . .
set strUAC1=Este script no necesita permisos administrativos.
set strUAC2=Ejecutelo nuevamente como usuario normal.
set strWhatToDo="(M)odificar, (D)esinstalar o (S)alir:"
set strWhatToDoOptions=MDS
set strLightStart="Ingrese a que hora deberia iniciar el modo claro en formato HH:mm"
set strDarkStart="Ingrese a que hora deberia iniciar el modo oscuro en formato HH:mm"
set strLDWrongOrder=El modo oscuro debe iniciar luego del modo claro
set strInstallSuccess=Instalacion completada exitosamente!
set strLightStartAt=El modo claro iniciara a las
set strDarkStartAt=El modo oscuro iniciara a las
set strUninstallQuestion="¿Esta seguro que desea desinstalar LDSwitcher? (S/N):"
set strYesNo=SN
set strUninstallCancel=Ha cancelado la desinstalacion
set strUninstallSuccess=LDSwitcher fue desinstalado de su equipo
set strAlreadyInstalled=LDSwitcher ya esta instalado. ¿Que desea hacer?
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
set strWpMode=¿Desea definir fondos de pantalla para cada modo? (S/N)
set strLightWp="Fondo del modo claro: "
set strDarkWp="Fondo del modo oscuro: "
set strWpPath=Escriba la ruta completa de la imagen o arrastrela aqui.
set strInvalidWp=El archivo no es una imagen o no existe.
set strCurrentValue=Valor actual:
set strNewValue=Valor nuevo:
set strAddonInstallText=¿Cuando desea que se ejecute este Add-On? (W/P)
set strOptAlongWindows=Junto al tema de (W)indows
set strOptPeriodical=(P)eriodicamente
set strAddonOptions=WP
set strAddonInstalledOK=Add-On instalado correctamente.
exit /b 0

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
set strCurrentValue=Current value:
set strNewValue=New value:
set strAddonInstallText=When would you like to run this Add-On? (W/P)
set strOptAlongWindows=Alongside (W)indows theme
set strOptPeriodical=(P)eriodically
set strAddonOptions=WP
set strAddonInstalledOK=Add-On installed successfully.
exit /b 0