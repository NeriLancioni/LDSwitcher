# LDSwitcher
Automatically switches Windows 10 light/dark mode according to time.  
  
  
  
## How to use
Run this script, select light and dark mode start time, select task bar behaviour, done!  
If you want to uninstall LDSwitcher, just run the same script!  
If you want to modify your settings, run the same script again!  
  
  
  
## What does this script do exactly?
-When Windows starts, it runs a non-admin .vbs script that starts a scheduled task. (You can find this file in the "Startup" tab on task manager)
-The scheduled task is pre-elevated and it runs a second .vbs script, but this time with admin privileges.
-The second .vbs script silently starts an exact copy of this .bat file as a background process.
-The background process loads all settings from a file in %localappdata% and periodically checks the time and theme of your system.
-The following registry values will be changed ONLY when needed, the OS will handle everything needed to apply the theme:
<code>Key: HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize - Value: AppsUseLightTheme</code>  
<code>Key: HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize - Value: SystemUsesLightTheme</code>  


## Other features
-Supports English and Spanish languages. Translators are welcome! :)  
-When running it, it will actually have the same color scheme as your current Windows theme.  
-When setup/modify finishes, your new Windows theme will also reflect on the script theme.  
-Everything it needs to run is inside a single script. No need to have EXE files, add exceptions to your AV software, install a runtime, etc.  
