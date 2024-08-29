# App Launch Tracker

AHK v2 script to secretly monitor and report app launches via email.  
Useful for parents or employers.

## Installation (for Gmail users)

1. **Download:** [`app-tracker.exe`](app-tracker.exe) (compiled version), [`config.json`](config.json) and [`install.cmd`](install.cmd)
2. **Get email sending credentials:** [enable 2-Step Verification](https://support.google.com/accounts/answer/185839) + [generate an App Password](https://security.google.com/settings/security/apppasswords)
3. **Configure:** Update `smtp.username` and `smtp.password` in `config.json` with your Gmail credentials and App Password, update `email.to` with the recipients you want to notify
4. **Install:** Run `install.cmd` on the tracked PC to create shortcut at startup folder

## Configuration Options

-   refer to the comments in [`app-tracker.ahk`](app-tracker.ahk#L16-L36) for detailed property descriptions
-   **`apps`:** list of apps to detect, such as those containing the substring 'roblox' in their window title or the full process name 'photoshop.exe'
-   **`remoteConfig`:** remote configuration to avoid accessing tracked PC; must be `googleDocId` or `url` pointed to **your own copy** of [this spreadsheet](https://docs.google.com/spreadsheets/d/13uh9TW2axb28s9i2lOH9ShnHjEdAqKyGZayvVwDs1CA)
-   **`trayIcon`:** couple of embedded tray icons available (bell, eye, shield)

Enjoy :)
