@echo off
setlocal enabledelayedexpansion

REM If script is being run by a scheduled task, go to background task
if "%1"=="task" goto :SWITCHER

REM Detect language
call :findLang es-
if "!errorlevel!"=="0" (
    call :setLangEs
    goto :langSelected
)

REM Default to English
call :setLangEn
:langSelected

call :clearDualEcho
echo !strInit!

call :findVars
if "!errorlevel!"=="1" (
    call :clearDualEcho
    echo !strEnvVarError!
    echo.
    echo !strExit!
    pause > nul
    exit /b
)


REM Check Windows version
wmic os get Caption /value | find "Windows 10" >nul 2>&1
if !errorlevel! neq 0 (
    call :clearDualEcho
    echo !strNotTen1!
    echo !strNotTen2!
    echo.
	echo !strExit!
	pause > nul
	exit /b 1
)

REM Check for admin privileges
mkdir %windir%\checkYourPrivileges >nul 2>&1
if "!errorlevel!"=="0" (
	rmdir /s /q %windir%\checkYourPrivileges
) else (
    call :clearDualEcho
    echo !strUAC1!
	echo !strUAC2!
	echo !strUAC3!
	echo.
	echo !strExit!
	pause > nul
	exit /b 2
)

call :cmdColor
REM Check install status
REM If not installed, go to installer
if not exist "!_localappdata!\LDSwitcher\" goto :install

REM If installed, ask if user wants to modify, uninstall or cancel
call :clearDualEcho
echo !strAlreadyInstalled!
choice /c !strWhatToDoOptions! /n /m !strWhatToDo!
if "!errorlevel!"=="1" goto :install
if "!errorlevel!"=="2" goto :uninstall
if "!errorlevel!"=="3" exit /b
exit /b

:install
REM Define light mode start time (24hs format)
call :timeInput !strLightStart!
set lightStart=!timeAcu!

REM Define dark mode start time (24hs format)
call :timeInput !strDarkStart!
set darkStart=!timeAcu!

REM Define task bar behaviour
call :clearDualEcho
echo !strTaskBarModeMsg!
echo !strTaskBarOptLight!
echo !strTaskBarOptDark!
echo !strTaskBarOptByTime!
echo.
choice /c !strTaskBarOptions! /n
set /a barMode=!errorlevel!-1


call :clearDualEcho
echo !strInstalling!

REM Split both times to separate variables
if "!lightStart:~0,1!"=="0" (
    set /a light_HH=!lightStart:~1,1!
) else (
    set /a light_HH=!lightStart:~0,2!
)
if "!lightStart:~3,1!"=="0" (
    set /a light_mm=!lightStart:~4,1!
) else (
    set /a light_mm=!lightStart:~3,2!
)

if "!darkStart:~0,1!"=="0" (
    set /a dark_HH=!darkStart:~1,1!
) else (
    set /a dark_HH=!darkStart:~0,2!
)
if "!darkStart:~3,1!"=="0" (
    set /a dark_mm=!darkStart:~4,1!
) else (
    set /a dark_mm=!darkStart:~3,2!
)

REM Check if light mode starts before dark mode
set /a lightStartMin=!light_HH! * 60 + !light_mm!
set /a darkStartMin=!dark_HH! * 60 + !dark_mm!
if !darkStartMin! leq !lightStartMin! (
    call :clearDualEcho
    echo !strLDWrongOrder!
    echo.
    pause
    goto :install
)

REM Copy required files to separate folder
mkdir "!_localappdata!\LDSwitcher" >nul 2>&1
mkdir "%systemdrive%\LDSwitcher" >nul 2>&1
attrib +s +h "%systemdrive%\LDSwitcher" >nul 2>&1
copy /y %0 "%systemdrive%\LDSwitcher\LDSwitcher.bat" >nul 2>&1

REM Create startup script
echo Set WshShell = WScript.CreateObject("WScript.Shell") > "!_appdata!\Microsoft\Windows\Start Menu\Programs\Startup\LDSwitcher.vbs"
echo WshShell.Run "schtasks /run /tn ""\LDSwitcherElevation !_username!"" /i", 0, False >> "!_appdata!\Microsoft\Windows\Start Menu\Programs\Startup\LDSwitcher.vbs"

REM Create elevation scheduled task
schtasks /create /ru "!_username!" /sc ONCE /sd 01/01/1970 /st 00:00 /tn "\LDSwitcherElevation !_username!" /tr "%systemdrive%\LDSwitcher\SilentLDSwitcher.vbs" /rl highest /f >nul 2>&1

REM Create silent start script
echo Set WshShell = WScript.CreateObject("WScript.Shell") > "%systemdrive%\LDSwitcher\SilentLDSwitcher.vbs"
echo WshShell.Run "%systemdrive%\LDSwitcher\LDSwitcher.bat task", 0, False >> "%systemdrive%\LDSwitcher\SilentLDSwitcher.vbs"



REM Create config.txt
echo lightTime_HH=!light_HH! > "!_localappdata!\LDSwitcher\config.txt"
echo lightTime_mm=!light_mm! >> "!_localappdata!\LDSwitcher\config.txt"
echo darkTime_HH=!dark_HH! >> "!_localappdata!\LDSwitcher\config.txt"
echo darkTime_mm=!dark_mm! >> "!_localappdata!\LDSwitcher\config.txt"
echo taskBarMode=!barMode! >> "!_localappdata!\LDSwitcher\config.txt"

REM Run theme changer from startup vbs script
schtasks /run /tn "\LDSwitcherElevation !_username!" /i >nul 2>&1

timeout /t 5 /nobreak > nul
call :cmdColor

REM Success message and exit
call :clearDualEcho
echo !strInstallSuccess!
echo.
echo !strLightStartAt! !lightStart!
echo !strDarkStartAt! !darkStart!
if !barMode!==0 ( echo !strBarIsDark! )
if !barMode!==1 ( echo !strBarIsLight! )
if !barMode!==2 ( echo !strBarIsAuto! )
echo.
echo.
pause
exit /b







:SWITCHER
call :findVars
if "%errorlevel%" neq "0" exit

REM Check configuration file existence
if not exist "!_localappdata!\LDSwitcher\config.txt" exit /b 2
REM Load parameters from config file
for /f "tokens=1,2 delims==" %%a in ('more "!_localappdata!\LDSwitcher\config.txt"') do (
    set /a %%a=%%b
)

REM Check if needed variables are defined
if not defined lightTime_HH exit /b 3
if not defined lightTime_mm exit /b 4
if not defined darkTime_HH exit /b 5
if not defined darkTime_mm exit /b 6
if not defined taskBarMode exit /b 7

if !errorlevel! neq 0 exit /b !errorlevel!

rem Set light and dark mode start times in minutes
set /a lightTime=!lightTime_HH! * 60 + !lightTime_mm!
set /a darkTime=!darkTime_HH! * 60 + !darkTime_mm!

set lastModeSet=-1
:loop
    if not exist "!_localappdata!\LDSwitcher\config.txt" exit
    if "!lastModeSet!" neq "-1" choice /t 5 /c ab /d a > nul

    REM Set current hours and minutes on separate numeric variables
    REM Ignores regional format, uses 24hr format
    for /f "tokens=1,2 delims=:" %%a in ('echo %time%') do (
        set /a now_HH=%%a
        set now_mm=%%b
    )
    if "!now_mm:~0,1!"=="0" (
        set /a now_mm=!now_mm:~1,1!
    ) else (
        set /a now_mm=!now_mm!
    )

    REM Set light mode if current time is between light and dark mode start times
    REM If not, set dark mode
    set /a now=!now_HH! * 60 + !now_mm!

    set mode=0
    if !now! geq !lightTime! (
        if !now! leq !darkTime! (
            set mode=1
        )
    )

    rem Avoid changing windows registry if there is no need
    if "!mode!"=="!lastModeSet!" goto :loop

    rem Change system colors
    reg add "!_HKCU!\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme /t REG_DWORD /d !mode! /f >nul 2>&1
    if !taskBarMode!==2 (
        reg add "!_HKCU!\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d !mode! /f >nul 2>&1
    ) else (
        reg add "!_HKCU!\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v SystemUsesLightTheme /t REG_DWORD /d !taskBarMode! /f >nul 2>&1
    )
    set lastModeSet=!mode!

goto :loop
exit /b 0


:uninstall
call :clearDualEcho
choice /c !strYesNo! /n /m !strUninstallQuestion!
if "!errorlevel!" neq "1" (
    call :clearDualEcho
    echo !strUninstallCancel!
    echo.
    pause
    exit /b
)
call :clearDualEcho
echo !strUninstalling!
schtasks /delete /tn "\LDSwitcherElevation !_username!" /f >nul 2>&1
rmdir /s /q "!_localappdata!\LDSwitcher\" >nul 2>&1
schtasks /query /tn \ /fo csv /nh | find /i "\LDSwitcher" >nul 2>&1
if "!errorlevel!" neq "0" (
    rmdir /s /q "%systemdrive%\LDSwitcher\" >nul 2>&1
)
del "!_appdata!\Microsoft\Windows\Start Menu\Programs\Startup\LDSwitcher.vbs" /q

call :clearDualEcho
echo !strUninstallSuccess!
echo.
pause
exit /b

:timeInput
set timeAcu=
call :timeInput2 012 %1
if "!timeAcu!"=="2" (
    call :timeInput2 0123 %1
) else (
    call :timeInput2 0123456789 %1
)
set timeAcu=!timeAcu!:
call :timeInput2 012345 %1
call :timeInput2 0123456789 %1
exit /b
:timeInput2
set message=%2
call :clearDualEcho
echo !message:~1,-1!!timeAcu!
choice /c %1 /n
set /a indexOffset=!errorlevel!-1
set timeAcu=!timeAcu!!indexOffset!
set indexOffset=
exit /b

REM Trying to save some lines xd
:clearDualEcho
cls & echo. & echo.
exit /b

:cmdColor
for /f "delims=x tokens=2" %%i in ('reg query "!_HKCU!\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize" /v AppsUseLightTheme') do (
    if "%%i"=="1" ( color f0 ) else ( color 0f )
)
exit /b

:findLang
if "%1"=="" exit /b 1
if not defined currentLang (
    for /f delims^=^"^ tokens^=2 %%i in ('wmic os get MUILanguages /value ^| find "MUILanguages"') do set currentLang=%%i
)
echo !currentLang! | find /i "%1" > nul
exit /b !errorlevel!

:findVars
for /f "delims=\_ tokens=3" %%i in ('reg query HKU ^| findstr /e _Classes') do (
    reg query "HKU\%%i\Volatile Environment" >nul 2>&1
    if "!errorlevel!"=="0" (
        for /f "tokens=2* skip=2" %%a in ('reg query "HKU\%%i\Volatile Environment" /v APPDATA') do set _APPDATA=%%b
        for /f "tokens=2* skip=2" %%a in ('reg query "HKU\%%i\Volatile Environment" /v LOCALAPPDATA') do set _LOCALAPPDATA=%%b
        for /f "tokens=2* skip=2" %%a in ('reg query "HKU\%%i\Volatile Environment" /v USERNAME') do set _USERNAME=%%b
        set _HKCU=HKU\%%i
        exit /b 0
    )
)
exit /b 1

:setLangEs
set strInit=Inicializando . . .
set strNotTen1=Esta version de Windows no es compatible con la funcionalidad
set strNotTen2=de temas claros y oscuros a nivel de sistema operativo.
set strExit=Presione una tecla para salir . . .
set strUAC1=Se necesitan permisos administrativos para continuar. Para esto,
set strUAC2=haga click derecho sobre el icono de la herramienta, elija
set strUAC3=Ejecutar como Administrador y elija Si en la ventana emergente.
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
set strEnvVarError=Error inesperado al obtener variables de entorno
exit /b

:setLangEn
set strInit=Initializing . . .
set strNotTen1=This Windows version is not compatible with OS-level
set strNotTen2=light and dark theme.
set strExit=Press any key to exit . . .
set strUAC1=Administrative permissions are required to continue. To do
set strUAC2=this, right-click on the tool icon, choose Run as
set strUAC3=Administrator and choose Yes in the pop-up window.
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
set strEnvVarError=Unexpected error while getting environmental variables
exit /b
