@echo off

REM If script is being run from vbs script, go to background task
if "%1"=="task" goto :SWITCHER
title LDSwitcher

REM Detect language
call :findLang es-
if "%errorlevel%"=="0" (
    call :setLangEs
    goto :langSelected
)

REM Default to English
call :setLangEn
:langSelected

call :clearDualEcho
echo %strInit%

REM Check Windows version
wmic os get Caption /value | find "Windows 10" >nul 2>&1
if %errorlevel% neq 0 (
    call :clearDualEcho
    echo %strNotTen1%
    echo %strNotTen2%
    echo.
	echo %strExit%
	pause > nul
	exit /b 1
)

REM Check for admin privileges
mkdir %windir%\checkYourPrivileges >nul 2>&1
if "%errorlevel%"=="0" (
	rmdir /s /q %windir%\checkYourPrivileges
    call :clearDualEcho
    echo %strUAC1%
	echo %strUAC2%
	echo.
	echo %strExit%
	pause > nul
	exit /b 2
)

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
if not exist "%localappdata%\LDSwitcher\" goto :install

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
call :timeInput %strLightStart%
set lightStart=%timeAcu%

REM Define dark mode start time (24hs format)
call :timeInput %strDarkStart%
set darkStart=%timeAcu%

REM Check if light mode starts before dark mode
set /a lightStartMin=%lightStart:~0,2%*60+%lightStart:~3,2%
set /a darkStartMin=%darkStart:~0,2%*60+%darkStart:~3,2%
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


call :clearDualEcho
echo %strInstalling%

REM Stop previous instance
taskkill /fi "WINDOWTITLE eq LDSwitcher Background Process" /f >nul 2>&1

REM Copy required files to separate folder
mkdir "%localappdata%\LDSwitcher" >nul 2>&1
copy /y %0 "%localappdata%\LDSwitcher\LDSwitcher.bat" >nul 2>&1

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

REM Success message and exit
call :clearDualEcho
echo %strInstallSuccess%
echo.
echo %strLightStartAt% %lightStart%
echo %strDarkStartAt% %darkStart%
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

:loop
    REM Set current time as minutes
    set /a now=%time:~0,2%*60+%time:~3,2%

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

    rem Change apps colors
    call :setTheme AppsUseLightTheme %mode%

    choice /t 5 /c ab /d a > nul
goto :loop
exit /b 0

:setTheme
rem Avoid changing windows registry if there is no need
for /f "delims=x tokens=2" %%i in ('reg query "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v %1') do (
    if "%%i" neq "%2" reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v %1 /t REG_DWORD /d %2 /f >nul 2>&1
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
timeout /t 1 /nobreak > nul
rmdir /s /q "%localappdata%\LDSwitcher\" >nul 2>&1
reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Run" /v LDSwitcher /f >nul 2>&1
reg delete "HKCU\SOFTWARE\NeriLancioni\LDSwitcher" /f >nul 2>&1
reg query "HKCU\SOFTWARE\NeriLancioni" | find "\" >nul 2>&1
if "%errorlevel%" neq 0 reg delete "HKCU\SOFTWARE\NeriLancioni" /f >nul 2>&1

call :clearDualEcho
echo %strUninstallSuccess%
echo.
pause
exit /b

:timeInput
set timeAcu=
call :timeInput2 012 %1
if "%timeAcu%"=="2" (
    call :timeInput2 0123 %1
) else (
    call :timeInput2 0123456789 %1
)
set timeAcu=%timeAcu%:
call :timeInput2 012345 %1
call :timeInput2 0123456789 %1
exit /b
:timeInput2
set message=%2
call :clearDualEcho
echo %message:~1,-1%%timeAcu%
choice /c %1 /n
set /a indexOffset=%errorlevel%-1
set timeAcu=%timeAcu%%indexOffset%
set indexOffset=
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
exit /b