# LDSwitcher
Automatically switches Windows 10 light/dark mode and wallpaper (optional) according to time.  
  
  
  
## How to use
Run this script as a regular user (no elevation needed), select light and dark mode start time, select task bar behaviour, select wallpapers (optional) done!  
If you want to uninstall LDSwitcher, just run the same script!  
If you want to modify your settings, run the same script again!  
Additionaly you can drag and drop any .bat or .cmd file to this script to use it as an add-on.  
  
  
  
## What does this script do exactly?
-When Windows starts, it runs a VBS script. (You can find this file in the "Startup" tab on task manager)  
-The VBS script silently starts an exact copy of this .bat file as a background process.  
-The background process loads all settings from current user's registry and periodically checks the time and theme of your system.  
-If you set custom wallpapers for each mode, a PowerShell script will set your wallpaper alongside your system theme.  
-If you use Add-On's, "on change" ones will run when changing Windows theme and "periodical" ones will run every 5 seconds.  
-The following registry values will be changed ONLY when needed, the OS will handle everything needed to apply the theme:  
<code>Key: HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize - Value: AppsUseLightTheme</code>  
<code>Key: HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Themes\Personalize - Value: SystemUsesLightTheme</code>  
  


## Suggested wallpapers
Here are some light/dark wallpaper combinations to apply with this script. Feel free to suggest more!  
  
From wallpaperhub.app:  
[Windows 11](https://wallpaperhub.app/wallpapers/9256)  
[Radiant - Quadchrome](https://wallpaperhub.app/wallpapers/8144)  
[Background - Ignite](https://wallpaperhub.app/wallpapers/7866)  
[Microsoft Lines](https://wallpaperhub.app/wallpapers/8653)  
[Microsoft Lines - Filled](https://wallpaperhub.app/wallpapers/8664)  
[Fluent Blocks - Build 2020](https://wallpaperhub.app/wallpapers/6598)  
[Windows 10 & Edge & Fluent](https://wallpaperhub.app/wallpapers/6562)  
[Build 2019](https://wallpaperhub.app/wallpapers/4072)  
  
From 512pixels.net:  
MacOS 10.14 Mojave [Day](https://512pixels.net/downloads/macos-wallpapers/10-14-Day.jpg)/[Night](https://512pixels.net/downloads/macos-wallpapers/10-14-Night.jpg)  
MacOS 10.15 Catalina [Day](https://512pixels.net/downloads/macos-wallpapers/10-15-Day.jpg)/[Night](https://512pixels.net/downloads/macos-wallpapers/10-15-Night.jpg)  
MacOS Big Sur Colorful [Day](https://512pixels.net/downloads/macos-wallpapers/11-0-Color-Day.jpg)/[Night](https://512pixels.net/downloads/macos-wallpapers/11-0-Big-Sur-Color-Night.jpg)  
MacOS Big Sur [Day](https://512pixels.net/downloads/macos-wallpapers/11-0-Day.jpg)/[Night](https://512pixels.net/downloads/macos-wallpapers/11-0-Night.jpg)  
MacOS Monterey [Light](https://512pixels.net/downloads/macos-wallpapers-6k/12-Light.jpg)/[Dark](https://512pixels.net/downloads/macos-wallpapers-6k/12-Dark.jpg)  
MacOS Ventura [Light](https://512pixels.net/downloads/macos-wallpapers-6k/13-Ventura-Light.jpg)/[Dark](https://512pixels.net/downloads/macos-wallpapers-6k/13-Ventura-Dark.jpg)  
  
  
  
## Other features
-Supports English and Spanish languages. Translators are welcome! :)  
-When running it, it will actually have the same color scheme as your current Windows theme.  
-When setup/modify finishes, your new Windows theme will also reflect on the script theme.  
-Everything it needs to run is inside a single script. No need to have EXE files, add exceptions to your AV software, install a runtime, etc.  
