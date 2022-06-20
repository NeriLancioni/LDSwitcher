::Periodical
rem This script overrides light and dark start times with Night Light windows times
rem It will check your current settings once each minute and apply them to the LDSwitcher background process on the go.
rem If Night Light is not programmed, it will default to LDSwitcher manual settings.
rem Copy it in "%localappdata%\LDSwitcher\Addons\Periodical\".

rem Run once per minute
if not defined NLQCounter (
    set /a NLQCounter=60
) else (
    set /a NLQCounter+=5
)
if %NLQCounter% lss 60 exit /b
set NLQCounter=0

for /f "tokens=3 delims= " %%i in ('reg query "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default$windows.data.bluelightreduction.settings\windows.data.bluelightreduction.settings" /v Data') do (
    set NLQ=%%i
)
set NLQ=%NLQ:~46%

rem If Night Light is not programmed, load default LDSwitcher values
echo %NLQ% | findstr /b 0201 >nul 2>&1 || (
    for /f "skip=2 tokens=3 delims= " %%a in ('reg query HKCU\SOFTWARE\NeriLancioni\LDSwitcher /v lightTime') do set /a lightTime=%%a
    for /f "skip=2 tokens=3 delims= " %%a in ('reg query HKCU\SOFTWARE\NeriLancioni\LDSwitcher /v darkTime') do set /a darkTime=%%a
    exit /b
)

rem Check if Night Light settings are manual or automatic
echo %NLQ% | findstr /b 0201C20A00 >nul 2>&1 && (
    set Trim1=CA14
    set Trim2=CA1E
) || (
    set Trim1=CA32
    set Trim2=CA3C
)

rem Initialize nedded variables as 0
set /a StartHH=0
set /a StartMM=0
set /a EndHH=0
set /a EndMM=0

rem Trim first query and load nedded values
call :TrimUntilMatch %Trim1%
call :SetVarAsNeeded Start %NLQ:~4,4%
call :SetVarAsNeeded Start %NLQ:~8,4%

rem Trim first query (again) and load nedded values
call :TrimUntilMatch %Trim2%
call :SetVarAsNeeded End %NLQ:~4,4%
call :SetVarAsNeeded End %NLQ:~8,4%

rem Set new light and dark times for LDSwitcher
set /a lightTime=%EndHH%*60+%EndMM%
set /a darkTime=%StartHH%*60+%StartMM%
exit /b



rem Trims NLQ variable until the desired 4 character pattern is found.
rem Assigns new value to itself. Includes the pattern.
rem If pattern is not found it does nothing.
:TrimUntilMatch
set trimAux=
set /a index=0
:trimLoop
    call set trimAux=%%NLQ:~%index%,4%%
    if "%trimAux%"=="" exit /b 1
    if "%trimAux%"=="%1" (
        call set NLQ=%%NLQ:~%index%%%

        exit /b 0
    )
    set /a index=%index%+2
goto :trimLoop



rem Sets a variable which name starts with 1st argument and ends with HH or MM.
rem If 2nd argument starts with 0E, variable name ends with HH.
rem If 2nd argument starts with 2E, variable name ends with MM.
rem Value assigned is last 2 characters of 2nd argument converted from hex to decimal.
:SetVarAsNeeded
set input=%2
if "%input:~0,2%"=="0E" (
    set /a %1HH=0x%input:~2,2%
    set input=
    exit /b 0
)
if "%input:~0,2%"=="2E" (
    set /a %1MM=0x%input:~2,2%
    set input=
    exit /b 0
)
exit /b 1