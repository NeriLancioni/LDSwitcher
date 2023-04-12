::OnThemeChange
rem This script changes Foxit Reader 9+ theme.
rem Copy it in "%localappdata%\LDSwitcher\Addons\OnThemeChange\".
rem Theme will be changed when you re-launch Foxit Reader.
rem If you know how to programatically reflect theme change on the fly, let me know!

reg query "HKCU\SOFTWARE\Foxit Software\Foxit Reader 9.0\Preferences\Skins" /v SkinName | find "Black"
if "%errorlevel%"=="%1" exit /b

if "%1"=="0" (
    reg add "HKCU\SOFTWARE\Foxit Software\Foxit Reader 9.0\Preferences\Skins" /v SkinName /t REG_SZ /d Black /f
) else (
    reg add "HKCU\SOFTWARE\Foxit Software\Foxit Reader 9.0\Preferences\Skins" /v SkinName /t REG_SZ /d Classic /f
)
