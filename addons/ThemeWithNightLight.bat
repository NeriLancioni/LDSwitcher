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

rem Query registry value and ignore first 46 characters (23 bytes, 2 characters per byte)
for /f "tokens=3 delims= " %%i in ('reg query "HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default$windows.data.bluelightreduction.settings\windows.data.bluelightreduction.settings" /v Data') do (
    set NLQ=%%i
)
set NLQ=%NLQ:~46%

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

rem Save new start times in registry
reg add "HKCU\SOFTWARE\NeriLancioni\LDSwitcher" /v lightTime /t REG_SZ /d %lightTime% /f >nul 2>&1
reg add "HKCU\SOFTWARE\NeriLancioni\LDSwitcher" /v darkTime /t REG_SZ /d %darkTime% /f >nul 2>&1

exit /b



rem Trims NLQ variable until the desired 4 character pattern is found.
rem Assigns new value to itself. Includes the pattern.
rem If pattern is not found it does nothing.
:TrimUntilMatch
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



rem In case anyone is interested about Night Light and registry:
rem The key is HKEY_CURRENT_USER\SOFTWARE\Microsoft\Windows\CurrentVersion\CloudStore\Store\DefaultAccount\Current\default$windows.data.bluelightreduction.settings\windows.data.bluelightreduction.settings
rem The value "Data" contains all Night Light related settings in a string of bytes.
rem Useful data for this addon are marked with an asterisk.
rem My conclusions (that seems to work at least for me) about what these bytes mean are:
rem 10 bytes  -  Constant 43,42,01,00,0a,02,01,00,2a,06.
rem 5 bytes   -  Supposed to be last modified unix timestamp in seconds (only first 2 bytes seem to change).
rem 8 bytes   -  Supposed to be constant, 4th bit is not, and it seems to be an hour as it is preceeded with a "0e" byte.
rem 2 bytes*  -  Schedule status. they are always 02,01 and are present when Night Light is scheduled. If not scheduled this 2 bytes don't exist.
rem 3 bytes*  -  They are always c2,0a,00 and determine if the user has set custom times for Night Light. If these bytes aren't present, settings are determined by location.
rem 2 bytes*  -  Constant ca,14 delimiter. following bytes are manual settings for Night Light starting time.
rem 2 bytes*  -  Night light start HOURS (manual settings). 1st byte is a delimiter (0e), 2nd byte is HH in hexadecimal. If HH is 0 both bytes are absent.
rem 2 bytes*  -  Night light start MINUTES (manual settings). 1st byte is a delimiter (2e), 2nd byte is MM in hexadecimal. If MM is 0 both bytes are absent.
rem 3 bytes*  -  Constant 00,ca,1e delimiter. following bytes are manual settings for Night Light ending time.
rem 2 bytes*  -  Night light end HOURS (manual settings). 1st byte is a delimiter (0e), 2nd byte is HH in hexadecimal. If HH is 0 both bytes are absent.
rem 2 bytes*  -  Night light end MINUTES (manual settings). 1st byte is a delimiter (2e), 2nd byte is MM in hexadecimal. If MM is 0 both bytes are absent.
rem 3 bytes   -  Constant 00,cf,28. delimiter for temperature?
rem 2 bytes   -  Supposedly color temperature in Kelvin. I didn't need it, so I mostly ignored this.
rem 2 bytes*  -  Constant ca,32 delimiter. following bytes are automatic settings for Night Light starting time.
rem 2 bytes*  -  Night light start HOURS (automatic settings). 1st byte is a delimiter (0e), 2nd byte is HH in hexadecimal. If HH is 0 both bytes are absent.
rem 2 bytes*  -  Night light start MINUTES (automatic settings). 1st byte is a delimiter (2e), 2nd byte is MM in hexadecimal. If MM is 0 both bytes are absent.
rem 3 bytes*  -  Constant 00,ca,3c delimiter. following bytes are automatic settings for Night Light ending time.
rem 2 bytes*  -  Night light end HOURS (automatic settings). 1st byte is a delimiter (0e), 2nd byte is HH in hexadecimal. If HH is 0 both bytes are absent.
rem 2 bytes*  -  Night light end MINUTES (automatic settings). 1st byte is a delimiter (2e), 2nd byte is MM in hexadecimal. If MM is 0 both bytes are absent.
rem 5 bytes   -  Constant 00,00,00,00,00.