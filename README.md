# App Tracker
AHK script to track for app launch and secretly notify over email. Useful for parents or employers.

## Installation (for Gmail user)
1. download compiled version [`app-tracker.exe`](app-tracker.exe), [`config.json`](config.json) and [`install.cmd`](install.cmd)
2. [create app password](https://security.google.com/settings/security/apppasswords) for [smtp](https://en.wikipedia.org/wiki/Simple_Mail_Transfer_Protocol#Outgoing_mail_SMTP_server) account to allow sending alerts ([2-step verification is required](https://support.google.com/accounts/answer/185839))
3. provide smtp.username and smtp.password to `config.json`
4. (on tracked PC) run `install.cmd` to create `app-tracker-shortcut.lnk` at startup folder 

## Configuration via `config.json`
- see props description at the begining of [`app-tracker.ahk`](app-tracker.ahk)
- remote configuration, just point `remoteConfig: ...` to your copy of [this spreadsheet](https://docs.google.com/spreadsheets/d/13uh9TW2axb28s9i2lOH9ShnHjEdAqKyGZayvVwDs1CA)
- couple of embedded tray icons available

Cheers!

