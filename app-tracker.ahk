; App tracker AHK script, to detect window/process running and secretly send email alert

#SingleInstance Force
#Requires AutoHotkey v2.0

#include lib/SendEmail.ahk
#include lib/MergeObjects.ahk
#include lib/FetchGoogleSpreadsheet.ahk
#include lib/UseBase64TrayIcon.ahk
#include lib/RemoveTrayTooltip.ahk
#include lib/Jsons.ahk

SetTitleMatchMode "RegEx"

; remoteConfig > localConfig > config
global config := {
	localConfig: "./config.json",
	remoteConfig: "", ; google doc id or url, see example https://docs.google.com/spreadsheets/d/13uh9TW2axb28s9i2lOH9ShnHjEdAqKyGZayvVwDs1CA
	apps: ["test"], ; array of apps to detect, e.g. substring of window title ("roblox") or full process name ("photoshop.exe") (string with comma as separator)
	checkPeriodSeconds: 5, ; period between scans for apps running
	alertLimitSeconds: 60 * 60 * 2, ; minimum time period between alerts to avoid spamming
	alertOnUserExit: false, ; if true, send special email on user to close app tracker
	trayIcon: "transparent", ; one of "bell", "eye", "shield", "transparent"
	smtp: { ; smtp account to send email alert
		username: "test@test.com",
		password: "" ; create app password https://security.google.com/settings/security/apppasswords
	},
	email: { ; alert' email settings
		from: "App Spy <test@test.com>", ; must be same as smtp.username
		to: "Tester <test1@test.com>, test2@test.com",
		subj: "email.subj",
		bodyPrefix: "email.body.prefix<br/>", ; html acceptable
		bodySuffix: "email.body.suffix<br/>"
	},
	debug: false ; don't override it in remoteConfig' spreadsheet
}

config := MergeObjects(config, ReadJson(config.localConfig)) ; append local config

if (config.HasOwnProp("remoteConfig")) {
	config := MergeObjects(config, FetchGoogleSpreadsheet(config.remoteConfig,,,config.debug)) ; append remote config
}

global s := {} ; global storage of script' state
s.appsFound := ""
s.secondsSinceAlert := config.alertLimitSeconds * 2 ; init as more than limit

RunAppTracker() ; main routine
RunAppTracker() {
	if (config.debug)
		MsgBox "config + localConfig + remoteConfig: `r`n" Jsons.Dump(config, 4)

	SetTimer CheckAppsRunning, 1000 * config.checkPeriodSeconds ; main routine
	UseBase64TrayIcon(config.trayIcon)
	RemoveTrayTooltip()
	OnExit HandleExit
}

CheckAppsRunning() {
	s.secondsSinceAlert += config.checkPeriodSeconds

	apps := config.apps
	if !(apps is Array)
		apps := StringToArray(config.apps)

	if apps.Length < 1
		return

	; lookup for running apps
	for appSubstring in apps {
		rexp := "i).*" appSubstring ".*"
		count := WinGetCount(rexp)
		if (count == 0 and ProcessExist(appSubstring)) {
			count := 1
		}
		if (count != 0) {
			if (s.appsFound == "") {
				s.appsFound := appSubstring " (" count ")"
			} else {
				s.appsFound .= ", " appSubstring " (" count ")"
			}
		}
	}
	if (s.appsFound != "") {
		if (s.secondsSinceAlert > config.alertLimitSeconds)
			AlertEmail()
		s.appsFound := "" ; cleanup
	}
}

AlertEmail() {
	_email := config.email.Clone()
	_email.subj := config.email.subj . " " . FormatTime(, "(HH:mm, dddd)")
	_email.body := config.email.bodyPrefix . s.appsFound . "<br/>" . config.email.bodySuffix
	SendEmail(config.smtp, _email, config.debug)
	s.secondsSinceAlert := 0 ; cleanup
}

ReadJson(path, fileReadOptions := "UTF-8") {
	if !FileExist(path) {
		if (config.debug)
			MsgBox('json file not found: ' path)
		return {}
	}

	text := FileRead(path, fileReadOptions)
	obj := Jsons.Load(&text)
	return MergeObjects({}, obj)
}

HandleExit(ExitReason, ExitCode) {
	if !(ExitReason ~= "^(?i:Logoff|Shutdown)$") {
		if (config.alertOnUserExit) {
			_email := config.email.Clone()
			_email.subj := "App tracker closed! (" . A_ComputerName . ", " . FormatTime(, "HH:mm, dddd)")
			_email.body := "User explicitly closed app tracker.<br/><br/>" . config.email.bodySuffix
			SendEmail(config.smtp, _email, config.debug)
		}
	}
}

StringToArray(v) {
	if !(v is String) {
		return []
	}
	return StrSplit(v, ",")
}
