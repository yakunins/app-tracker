@echo off

:: getting startup folder (https://stackoverflow.com/a/68019702)
setlocal EnableExtensions DisableDelayedExpansion
set "StartupFolder="
for /F "skip=1 tokens=1,2*" %%I in ('%SystemRoot%\System32\reg.exe QUERY "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /v Startup 2^>nul') do if /I "%%I" == "Startup" if not "%%~K" == "" if "%%J" == "REG_SZ" (set "StartupFolder=%%~K") else if "%%J" == "REG_EXPAND_SZ" call set "StartupFolder=%%~K"
if not defined StartupFolder for /F "skip=1 tokens=1,2*" %%I in ('%SystemRoot%\System32\reg.exe QUERY "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\Shell Folders" /v Startup 2^>nul') do if /I "%%I" == "Startup" if not "%%~K" == "" if "%%J" == "REG_SZ" (set "StartupFolder=%%~K") else if "%%J" == "REG_EXPAND_SZ" call set "StartupFolder=%%~K"
if not defined StartupFolder set "StartupFolder=\"
if "%StartupFolder:~-1%" == "\" set "StartupFolder=%StartupFolder:~0,-1%"
if not defined StartupFolder set "%APPDATA%\Microsoft\Windows\Start Menu\Programs\Startup"
::endlocal
::echo Startup folder of current user is: %StartupFolder%

set CurrentDir=%CD%
set ShortcutName=app-tracker-shortcut.lnk

:: create shortcut with Powershell
set PWS_TARGET='%CurrentDir%\app-tracker.exe'
set PWS_SHORTCUT='%CurrentDir%\%ShortcutName%'
set PWS=powershell.exe -ExecutionPolicy Bypass -NoLogo -NonInteractive -NoProfile
%PWS% -Command "$ws = New-Object -ComObject WScript.Shell; $s = $ws.CreateShortcut(%PWS_SHORTCUT%); $S.TargetPath = %PWS_TARGET%; $S.Save()"

:: move shortcut to startup
set Location="%CurrentDir%\%ShortcutName%"
set AutostartLocation="%StartupFolder%\%ShortcutName%"
move %Location% %AutostartLocation%

:PROMPT
set /P OPENFOLDER=Open startup folder? Y/[N]
if /I "%OPENFOLDER%" neq "Y" GOTO END
start shell:startup
:END

endlocal
