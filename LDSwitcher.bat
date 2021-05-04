@echo off

REM If script is being run by a scheduled task, go to No-UI mode
if "%1"=="task" goto :SWITCHER

REM Detect language
call :findLang es-
if "%errorlevel%"=="0" (
    call :setLangEs
    goto :langSelected
)

REM Default to English
call :setLangEn
:langSelected

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
) else (
    call :clearDualEcho
    echo %strUAC1%
	echo %strUAC2%
	echo %strUAC3%
	echo.
	echo %strExit%
	pause > nul
	exit /b 2
)

call :cmdColor
REM Check install status
REM If not installed, go to installer
if not exist "%systemdrive%\LDSwitcher\" goto :install

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

REM Split both times to separate variables
if "%lightStart:~0,1%"=="0" (
    set /a light_HH=%lightStart:~1,1%
) else (
    set /a light_HH=%lightStart:~0,2%
)
if "%lightStart:~3,1%"=="0" (
    set /a light_mm=%lightStart:~4,1%
) else (
    set /a light_mm=%lightStart:~3,2%
)

if "%darkStart:~0,1%"=="0" (
    set /a dark_HH=%darkStart:~1,1%
) else (
    set /a dark_HH=%darkStart:~0,2%
)
if "%darkStart:~3,1%"=="0" (
    set /a dark_mm=%darkStart:~4,1%
) else (
    set /a dark_mm=%darkStart:~3,2%
)

REM Check if light mode starts before dark mode
set /a lightStartMin=%light_HH% * 60 + %light_mm%
set /a darkStartMin=%dark_HH% * 60 + %dark_mm%
if %darkStartMin% leq %lightStartMin% (
    call :clearDualEcho
    echo %strLDWrongOrder%
    echo.
    pause
    goto :install
)

REM Copy required files to separate folder
mkdir "%systemdrive%\LDSwitcher" >nul 2>&1
copy /y %0 %systemdrive%\LDSwitcher\LDSwitcher.bat >nul 2>&1

REM Create config.txt
echo lightTime_HH=%light_HH% > %systemdrive%\LDSwitcher\config.txt
echo lightTime_mm=%light_mm% >> %systemdrive%\LDSwitcher\config.txt
echo darkTime_HH=%dark_HH% >> %systemdrive%\LDSwitcher\config.txt
echo darkTime_mm=%dark_mm% >> %systemdrive%\LDSwitcher\config.txt
echo taskBarMode=%barMode% >> %systemdrive%\LDSwitcher\config.txt

call :createScheduledTasks %lightStart% %darkStart% >nul 2>&1

REM Run theme changer script with (almost) no arguments
call %systemdrive%\LDSwitcher\LDSwitcher.bat task >nul 2>&1

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







:createScheduledTasks

set targetPath=%temp%\tempTask.xml
if not defined SID (
    for /f "skip=1 tokens=2 delims=," %%i in ('whoami /user /fo CSV') do set SID=%%i
)
for /f "skip=1 tokens=1 delims=," %%i in ('schtasks /query /tn \LDSwitcher\ /fo csv') do (
    schtasks /delete /tn %%i /f >nul 2>&1
)
call :TaskByTime lightModeStart %1 L
schtasks /create /xml "%targetPath%" /tn "\LDSwitcher\lightModeStart" >nul 2>&1
del /f /q %targetPath% >nul 2>&1
call :TaskByTime darkModeStart %2 D
schtasks /create /xml "%targetPath%" /tn "\LDSwitcher\darkModeStart" >nul 2>&1
del /f /q %targetPath% >nul 2>&1
call :OnResumeTask
schtasks /create /xml "%targetPath%" /tn "\LDSwitcher\updateModeOnResume" >nul 2>&1
del /f /q %targetPath% >nul 2>&1
call :OnStartTask
schtasks /create /xml "%targetPath%" /tn "\LDSwitcher\updateModeOnStart" >nul 2>&1
del /f /q %targetPath% >nul 2>&1
call :ClockUpdatedTask
schtasks /create /xml "%targetPath%" /tn "\LDSwitcher\updateModeClockChange" >nul 2>&1
del /f /q %targetPath% >nul 2>&1
exit /b

:TaskByTime
echo ^<?xml version="1.0" encoding="UTF-16"?^> > %targetPath%
echo ^<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^> >> %targetPath%
echo   ^<RegistrationInfo^> >> %targetPath%
echo     ^<Date^>2020-06-22T09:32:59^</Date^> >> %targetPath%
echo     ^<Author^>%computername%\%username%^</Author^> >> %targetPath%
echo     ^<URI^>\LDSwitcher\%1^</URI^> >> %targetPath%
echo   ^</RegistrationInfo^> >> %targetPath%
echo   ^<Triggers^> >> %targetPath%
echo     ^<CalendarTrigger^> >> %targetPath%
echo       ^<StartBoundary^>2020-06-22T%2:00^</StartBoundary^> >> %targetPath%
echo       ^<Enabled^>true^</Enabled^> >> %targetPath%
echo       ^<ScheduleByDay^> >> %targetPath%
echo         ^<DaysInterval^>1^</DaysInterval^> >> %targetPath%
echo       ^</ScheduleByDay^> >> %targetPath%
echo     ^</CalendarTrigger^> >> %targetPath%
echo   ^</Triggers^> >> %targetPath%
echo   ^<Principals^> >> %targetPath%
echo     ^<Principal id="Author"^> >> %targetPath%
echo       ^<UserId^>%SID:~1,-1%^</UserId^> >> %targetPath%
echo       ^<LogonType^>S4U^</LogonType^> >> %targetPath%
echo       ^<RunLevel^>HighestAvailable^</RunLevel^> >> %targetPath%
echo     ^</Principal^> >> %targetPath%
echo   ^</Principals^> >> %targetPath%
echo   ^<Settings^> >> %targetPath%
echo     ^<MultipleInstancesPolicy^>IgnoreNew^</MultipleInstancesPolicy^> >> %targetPath%
echo     ^<DisallowStartIfOnBatteries^>false^</DisallowStartIfOnBatteries^> >> %targetPath%
echo     ^<StopIfGoingOnBatteries^>false^</StopIfGoingOnBatteries^> >> %targetPath%
echo     ^<AllowHardTerminate^>true^</AllowHardTerminate^> >> %targetPath%
echo     ^<StartWhenAvailable^>false^</StartWhenAvailable^> >> %targetPath%
echo     ^<RunOnlyIfNetworkAvailable^>false^</RunOnlyIfNetworkAvailable^> >> %targetPath%
echo     ^<IdleSettings^> >> %targetPath%
echo       ^<StopOnIdleEnd^>true^</StopOnIdleEnd^> >> %targetPath%
echo       ^<RestartOnIdle^>false^</RestartOnIdle^> >> %targetPath%
echo     ^</IdleSettings^> >> %targetPath%
echo     ^<AllowStartOnDemand^>true^</AllowStartOnDemand^> >> %targetPath%
echo     ^<Enabled^>true^</Enabled^> >> %targetPath%
echo     ^<Hidden^>false^</Hidden^> >> %targetPath%
echo     ^<RunOnlyIfIdle^>false^</RunOnlyIfIdle^> >> %targetPath%
echo     ^<WakeToRun^>false^</WakeToRun^> >> %targetPath%
echo     ^<ExecutionTimeLimit^>PT72H^</ExecutionTimeLimit^> >> %targetPath%
echo     ^<Priority^>7^</Priority^> >> %targetPath%
echo   ^</Settings^> >> %targetPath%
echo   ^<Actions Context="Author"^> >> %targetPath%
echo     ^<Exec^> >> %targetPath%
echo       ^<Command^>%systemdrive%\LDSwitcher\LDSwitcher.bat^</Command^> >> %targetPath%
echo       ^<Arguments^>task %3^</Arguments^> >> %targetPath%
echo     ^</Exec^> >> %targetPath%
echo   ^</Actions^> >> %targetPath%
echo ^</Task^> >> %targetPath%
exit /b

:OnResumeTask
echo ^<?xml version="1.0" encoding="UTF-16"?^> > %targetPath%
echo ^<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^> >> %targetPath%
echo   ^<RegistrationInfo^> >> %targetPath%
echo     ^<Date^>2020-06-22T09:32:59^</Date^> >> %targetPath%
echo     ^<Author^>%computername%\%username%^</Author^> >> %targetPath%
echo     ^<URI^>\LDSwitcher\updateModeOnResume^</URI^> >> %targetPath%
echo   ^</RegistrationInfo^> >> %targetPath%
echo   ^<Triggers^> >> %targetPath%
echo     ^<EventTrigger^> >> %targetPath%
echo       ^<Enabled^>true^</Enabled^> >> %targetPath%
echo       ^<Subscription^>^&lt;QueryList^&gt;^&lt;Query Id="0" Path="System"^&gt;^&lt;Select Path="System"^&gt;*[System[Provider[@Name='Microsoft-Windows-Power-Troubleshooter'] and EventID=1]]^&lt;/Select^&gt;^&lt;/Query^&gt;^&lt;/QueryList^&gt;^</Subscription^> >> %targetPath%
echo     ^</EventTrigger^> >> %targetPath%
echo   ^</Triggers^> >> %targetPath%
echo   ^<Principals^> >> %targetPath%
echo     ^<Principal id="Author"^> >> %targetPath%
echo       ^<UserId^>%SID:~1,-1%^</UserId^> >> %targetPath%
echo       ^<LogonType^>S4U^</LogonType^> >> %targetPath%
echo       ^<RunLevel^>HighestAvailable^</RunLevel^> >> %targetPath%
echo     ^</Principal^> >> %targetPath%
echo   ^</Principals^> >> %targetPath%
echo   ^<Settings^> >> %targetPath%
echo     ^<MultipleInstancesPolicy^>IgnoreNew^</MultipleInstancesPolicy^> >> %targetPath%
echo     ^<DisallowStartIfOnBatteries^>false^</DisallowStartIfOnBatteries^> >> %targetPath%
echo     ^<StopIfGoingOnBatteries^>false^</StopIfGoingOnBatteries^> >> %targetPath%
echo     ^<AllowHardTerminate^>true^</AllowHardTerminate^> >> %targetPath%
echo     ^<StartWhenAvailable^>false^</StartWhenAvailable^> >> %targetPath%
echo     ^<RunOnlyIfNetworkAvailable^>false^</RunOnlyIfNetworkAvailable^> >> %targetPath%
echo     ^<IdleSettings^> >> %targetPath%
echo       ^<StopOnIdleEnd^>true^</StopOnIdleEnd^> >> %targetPath%
echo       ^<RestartOnIdle^>false^</RestartOnIdle^> >> %targetPath%
echo     ^</IdleSettings^> >> %targetPath%
echo     ^<AllowStartOnDemand^>true^</AllowStartOnDemand^> >> %targetPath%
echo     ^<Enabled^>true^</Enabled^> >> %targetPath%
echo     ^<Hidden^>false^</Hidden^> >> %targetPath%
echo     ^<RunOnlyIfIdle^>false^</RunOnlyIfIdle^> >> %targetPath%
echo     ^<DisallowStartOnRemoteAppSession^>false^</DisallowStartOnRemoteAppSession^> >> %targetPath%
echo     ^<UseUnifiedSchedulingEngine^>true^</UseUnifiedSchedulingEngine^> >> %targetPath%
echo     ^<WakeToRun^>false^</WakeToRun^> >> %targetPath%
echo     ^<ExecutionTimeLimit^>PT72H^</ExecutionTimeLimit^> >> %targetPath%
echo     ^<Priority^>7^</Priority^> >> %targetPath%
echo   ^</Settings^> >> %targetPath%
echo   ^<Actions Context="Author"^> >> %targetPath%
echo     ^<Exec^> >> %targetPath%
echo       ^<Command^>%systemdrive%\LDSwitcher\LDSwitcher.bat^</Command^> >> %targetPath%
echo       ^<Arguments^>task^</Arguments^> >> %targetPath%
echo     ^</Exec^> >> %targetPath%
echo   ^</Actions^> >> %targetPath%
echo ^</Task^> >> %targetPath%
exit /b

:OnStartTask
echo ^<?xml version="1.0" encoding="UTF-16"?^> > %targetPath%
echo ^<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^> >> %targetPath%
echo   ^<RegistrationInfo^> >> %targetPath%
echo     ^<Date^>2020-06-22T09:32:59^</Date^> >> %targetPath%
echo     ^<Author^>%computername%\%username%^</Author^> >> %targetPath%
echo     ^<URI^>\LDSwitcher\updateModeOnStart^</URI^> >> %targetPath%
echo   ^</RegistrationInfo^> >> %targetPath%
echo   ^<Triggers^> >> %targetPath%
echo     ^<LogonTrigger^> >> %targetPath%
echo       ^<Enabled^>true^</Enabled^> >> %targetPath%
echo     ^</LogonTrigger^> >> %targetPath%
echo   ^</Triggers^> >> %targetPath%
echo   ^<Principals^> >> %targetPath%
echo     ^<Principal id="Author"^> >> %targetPath%
echo       ^<UserId^>%SID:~1,-1%^</UserId^> >> %targetPath%
echo       ^<LogonType^>S4U^</LogonType^> >> %targetPath%
echo       ^<RunLevel^>HighestAvailable^</RunLevel^> >> %targetPath%
echo     ^</Principal^> >> %targetPath%
echo   ^</Principals^> >> %targetPath%
echo   ^<Settings^> >> %targetPath%
echo     ^<MultipleInstancesPolicy^>IgnoreNew^</MultipleInstancesPolicy^> >> %targetPath%
echo     ^<DisallowStartIfOnBatteries^>false^</DisallowStartIfOnBatteries^> >> %targetPath%
echo     ^<StopIfGoingOnBatteries^>false^</StopIfGoingOnBatteries^> >> %targetPath%
echo     ^<AllowHardTerminate^>true^</AllowHardTerminate^> >> %targetPath%
echo     ^<StartWhenAvailable^>false^</StartWhenAvailable^> >> %targetPath%
echo     ^<RunOnlyIfNetworkAvailable^>false^</RunOnlyIfNetworkAvailable^> >> %targetPath%
echo     ^<IdleSettings^> >> %targetPath%
echo       ^<StopOnIdleEnd^>true^</StopOnIdleEnd^> >> %targetPath%
echo       ^<RestartOnIdle^>false^</RestartOnIdle^> >> %targetPath%
echo     ^</IdleSettings^> >> %targetPath%
echo     ^<AllowStartOnDemand^>true^</AllowStartOnDemand^> >> %targetPath%
echo     ^<Enabled^>true^</Enabled^> >> %targetPath%
echo     ^<Hidden^>false^</Hidden^> >> %targetPath%
echo     ^<RunOnlyIfIdle^>false^</RunOnlyIfIdle^> >> %targetPath%
echo     ^<DisallowStartOnRemoteAppSession^>false^</DisallowStartOnRemoteAppSession^> >> %targetPath%
echo     ^<UseUnifiedSchedulingEngine^>true^</UseUnifiedSchedulingEngine^> >> %targetPath%
echo     ^<WakeToRun^>false^</WakeToRun^> >> %targetPath%
echo     ^<ExecutionTimeLimit^>PT72H^</ExecutionTimeLimit^> >> %targetPath%
echo     ^<Priority^>7^</Priority^> >> %targetPath%
echo   ^</Settings^> >> %targetPath%
echo   ^<Actions Context="Author"^> >> %targetPath%
echo     ^<Exec^> >> %targetPath%
echo       ^<Command^>%systemdrive%\LDSwitcher\LDSwitcher.bat^</Command^> >> %targetPath%
echo       ^<Arguments^>task^</Arguments^> >> %targetPath%
echo     ^</Exec^> >> %targetPath%
echo   ^</Actions^> >> %targetPath%
echo ^</Task^> >> %targetPath%
exit /b

:ClockUpdatedTask
echo ^<?xml version="1.0" encoding="UTF-16"?^> > %targetPath%
echo ^<Task version="1.4" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task"^> >> %targetPath%
echo   ^<RegistrationInfo^> >> %targetPath%
echo     ^<Date^>2020-06-22T20:32:54.5449999^</Date^> >> %targetPath%
echo     ^<Author^>%computername%\%username%^</Author^> >> %targetPath%
echo     ^<URI^>\LDSwitcher\updateModeClockChange^</URI^> >> %targetPath%
echo   ^</RegistrationInfo^> >> %targetPath%
echo   ^<Triggers^> >> %targetPath%
echo     ^<EventTrigger^> >> %targetPath%
echo       ^<Enabled^>true^</Enabled^> >> %targetPath%
echo       ^<Subscription^>^&lt;QueryList^&gt;^&lt;Query Id="0" Path="System"^&gt;^&lt;Select Path="System"^&gt;*[System[Provider[@Name='Microsoft-Windows-Kernel-General'] and EventID=1]]^&lt;/Select^&gt;^&lt;/Query^&gt;^&lt;/QueryList^&gt;^</Subscription^> >> %targetPath%
echo     ^</EventTrigger^> >> %targetPath%
echo   ^</Triggers^> >> %targetPath%
echo   ^<Principals^> >> %targetPath%
echo     ^<Principal id="Author"^> >> %targetPath%
echo       ^<UserId^>%SID:~1,-1%^</UserId^> >> %targetPath%
echo       ^<LogonType^>S4U^</LogonType^> >> %targetPath%
echo       ^<RunLevel^>HighestAvailable^</RunLevel^> >> %targetPath%
echo     ^</Principal^> >> %targetPath%
echo   ^</Principals^> >> %targetPath%
echo   ^<Settings^> >> %targetPath%
echo     ^<MultipleInstancesPolicy^>IgnoreNew^</MultipleInstancesPolicy^> >> %targetPath%
echo     ^<DisallowStartIfOnBatteries^>false^</DisallowStartIfOnBatteries^> >> %targetPath%
echo     ^<StopIfGoingOnBatteries^>false^</StopIfGoingOnBatteries^> >> %targetPath%
echo     ^<AllowHardTerminate^>true^</AllowHardTerminate^> >> %targetPath%
echo     ^<StartWhenAvailable^>false^</StartWhenAvailable^> >> %targetPath%
echo     ^<RunOnlyIfNetworkAvailable^>false^</RunOnlyIfNetworkAvailable^> >> %targetPath%
echo     ^<IdleSettings^> >> %targetPath%
echo       ^<StopOnIdleEnd^>true^</StopOnIdleEnd^> >> %targetPath%
echo       ^<RestartOnIdle^>false^</RestartOnIdle^> >> %targetPath%
echo     ^</IdleSettings^> >> %targetPath%
echo     ^<AllowStartOnDemand^>true^</AllowStartOnDemand^> >> %targetPath%
echo     ^<Enabled^>true^</Enabled^> >> %targetPath%
echo     ^<Hidden^>false^</Hidden^> >> %targetPath%
echo     ^<RunOnlyIfIdle^>false^</RunOnlyIfIdle^> >> %targetPath%
echo     ^<DisallowStartOnRemoteAppSession^>false^</DisallowStartOnRemoteAppSession^> >> %targetPath%
echo     ^<UseUnifiedSchedulingEngine^>true^</UseUnifiedSchedulingEngine^> >> %targetPath%
echo     ^<WakeToRun^>false^</WakeToRun^> >> %targetPath%
echo     ^<ExecutionTimeLimit^>PT72H^</ExecutionTimeLimit^> >> %targetPath%
echo     ^<Priority^>7^</Priority^> >> %targetPath%
echo   ^</Settings^> >> %targetPath%
echo   ^<Actions Context="Author"^> >> %targetPath%
echo     ^<Exec^> >> %targetPath%
echo       ^<Command^>%systemdrive%\LDSwitcher\LDSwitcher.bat^</Command^> >> %targetPath%
echo       ^<Arguments^>task^</Arguments^> >> %targetPath%
echo     ^</Exec^> >> %targetPath%
echo   ^</Actions^> >> %targetPath%
echo ^</Task^> >> %targetPath%
exit /b

:SWITCHER
REM Check configuration file existence
if not exist %~dp0config.txt exit /b 2
REM Load parameters from config file
for /f "tokens=1,2 delims==" %%a in (%~dp0config.txt) do (
    set /a %%a=%%b
)
if not defined taskBarMode exit /b 7

REM If called with an argument, change according to it and return
if "%2"=="L" call :setMode 1 & exit /b 0
if "%2"=="D" call :setMode 0 & exit /b 0

REM Check if needed variables are defined
if not defined lightTime_HH exit /b 3
if not defined lightTime_mm exit /b 4
if not defined darkTime_HH exit /b 5
if not defined darkTime_mm exit /b 6

if %errorlevel% neq 0 exit /b %errorlevel%

REM If using an invalid argument, exit
set arg=%2
if defined arg exit /b 1

REM Set current hours and minutes on separate numeric variables
REM Ignores regional format, uses 24hr format
for /f "tokens=1,2 delims=:" %%a in ('echo %time%') do (
    set /a now_HH=%%a
    set now_mm=%%b
)
if "%now_mm:~0,1%"=="0" (
    set /a now_mm=%now_mm:~1,1%
) else (
    set /a now_mm=%now_mm%
)

REM Set light mode if current time is between light and dark mode start times
REM If not, set dark mode
set /a lightTime=%lightTime_HH% * 60 + %lightTime_mm%
set /a darkTime=%darkTime_HH% * 60 + %darkTime_mm%
set /a now=%now_HH% * 60 + %now_mm%

set mode=0
if %now% geq %lightTime% (
    if %now% leq %darkTime% (
        set mode=1
    )
)
call :setMode %mode%
exit /b 0

:setMode
reg add HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize /v AppsUseLightTheme /t REG_DWORD /d %1 /f >nul 2>&1
if %taskBarMode%==2 (
    reg add HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize /v SystemUsesLightTheme /t REG_DWORD /d %1 /f >nul 2>&1
) else (
    reg add HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize /v SystemUsesLightTheme /t REG_DWORD /d %taskBarMode% /f >nul 2>&1
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
rmdir /s /q %systemdrive%\LDSwitcher\ >nul 2>&1
for /f "skip=1 tokens=1 delims=," %%i in ('schtasks /query /tn \LDSwitcher\ /fo csv') do (
    schtasks /delete /tn %%i /f >nul 2>&1
)
echo $scheduleObject = New-Object -ComObject Schedule.Service > %temp%\deleteTasksFolder.ps1
echo $scheduleObject.connect() >> %temp%\deleteTasksFolder.ps1
echo $rootFolder = $scheduleObject.GetFolder("\") >> %temp%\deleteTasksFolder.ps1
echo $rootFolder.DeleteFolder("LDSwitcher",$null) >> %temp%\deleteTasksFolder.ps1
powershell %temp%\deleteTasksFolder.ps1
del /f /q %temp%\deleteTasksFolder.ps1
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
for /f "delims=x tokens=2" %%i in ('reg query HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize /v AppsUseLightTheme') do (
    if "%%i"=="1" ( color f0 ) else ( color 0f )
)
exit /b

:findLang
if "%1"=="" exit /b 1
if not defined currentLang (
    for /f delims^=^"^ tokens^=2 %%i in ('wmic os get MUILanguages / value ^| find "MUILanguages"') do set currentLang=%%i
)
echo %currentLang% | find /i "%1" > nul
exit /b %errorlevel%

:setLangEs
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
exit /b

:setLangEn
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
exit /b
