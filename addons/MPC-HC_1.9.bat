::OnThemeChange
rem This script changes Media Player Classic Home Cinema 1.9+ theme.
rem Copy it in "%localappdata%\LDSwitcher\Addons\OnThemeChange\".
rem Theme will be changed when you re-launch Media Player Classic Home Cinema.
rem If you know how to programatically reflect theme change on the fly, let me know!

reg query "HKCU\SOFTWARE\MPC-HC\MPC-HC\Settings" /v MPCTheme | findstr /e 0x%1 || exit /b

if "%1"=="0" (
    reg add "HKCU\SOFTWARE\MPC-HC\MPC-HC\Settings" /v MPCTheme /t REG_DWORD /d 1 /f
    exit /b
)
if "%1"=="1" (
    reg add "HKCU\SOFTWARE\MPC-HC\MPC-HC\Settings" /v MPCTheme /t REG_DWORD /d 0 /f
)
