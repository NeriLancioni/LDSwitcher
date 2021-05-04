# LDSwitcher
Automatically switches Windows 10 light/dark mode according to time.  
  
  
  
## How to use
Run this script, select light and dark mode start time, select task bar behaviour, done!  
If you want to uninstall LDSwitcher, just run the same script!  
If you want to modify your settings, you guessed it, run the same script again!  
  
  
  
## What does this script do exactly?
-Creates a folder named "LDSwitcher" on the root of your main drive.  
-Copies itself to LDSwitcher folder and generates a TXT file with the options you chose.  
-Creates 5 scheduled tasks to handle light mode start, dark mode start, Windows clock manual/NTP changes, resume from suspended state and Windows startup.  
-When run by the user, it displays a menu according to the installation state of LDSwitcher.  
-When run by any of the scheduled tasks, it changes the following registry keys according to current time:  
<code>Key: HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize - Value: AppsUseLightTheme</code>  
<code>Key: HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize - Value: SystemUsesLightTheme</code>  
...then Windows handles the registry changes and reflects it to the rest of the OS.  
  
  
  
## Other features
-Supports English and Spanish languages. Translators are welcome! :)  
-When running it, it will actually have the same color scheme as your current Windows theme.  
-When setup/modify finishes, your new Windows theme will also reflect on the script theme.  
-Everything it needs to run is inside a single script. No need to have EXE files, add exceptions to your AV software, install a runtime, etc.  
