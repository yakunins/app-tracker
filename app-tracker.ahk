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

global config := {
	localConfig: "./config.json", ; remoteConfig > localConfig > config
	remoteConfig: "", ; googleDocId or url, see https://docs.google.com/spreadsheets/d/13uh9TW2axb28s9i2lOH9ShnHjEdAqKyGZayvVwDs1CA
	apps: ["test"], ; array of apps to detect, e.g. substring of window title ("roblox") or full process name ("photoshop.exe") (string with comma as separator)
	checkPeriodSeconds: 20, ; (20 seconds) interval between scans for apps running
	alertLimitSeconds: 60 * 60 * 3, ; (3 hours) minimum interval between two alerts, to prevent spamming
	alertOnUserExit: false, ; if true, send special email on user to close app tracker
	trayIcon: "transparent", ; one of "bell", "eye", "shield", "transparent" or path to local file ("./ico/radar.ico")
	smtp: { ; smtp account to send email alert
		username: "test@test.com",
		password: "" ; create app password https://security.google.com/settings/security/apppasswords
	},
	email: { ; alert' email settings
		from: "App Spy <test@test.com>", ; address must be the same as smtp.username
		to: "Tester <test1@test.com>, test2@test.com",
		subj: "email.subj",
		bodyPrefix: "email.body.prefix<br/>", ; html is acceptable
		bodySuffix: "email.body.suffix<br/>"
	},
	debug: false
}

config := MergeObjects(config, ReadJson(config.localConfig)) ; local config to take pecedence

if (config.HasOwnProp("remoteConfig")) {
	config := MergeObjects(config, FetchGoogleSpreadsheet(config.remoteConfig,,,config.debug)) ; remote config to take pecedence
}

global s := {} ; global storage of script' state
s.appsFound := ""
s.secondsSinceAlert := config.alertLimitSeconds + 1 ; init as if limit has been passed

RunAppTracker() ; main routine
RunAppTracker() {
	if (config.debug)
		MsgBox "config + localConfig + remoteConfig: `r`n" Jsons.Dump(config, 4)

	SetTimer CheckAppsRunning, 1000 * config.checkPeriodSeconds ; main routine
	RemoveTrayTooltip()
	SetTrayIcon(config.trayIcon)
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

SetTrayIcon(nameOrPath) {
	if (InStr(nameOrPath, ".")) {
		if FileExist(nameOrPath)
			TraySetIcon(nameOrPath)
	} else {
		UseBase64TrayIcon(config.trayIcon)
	}
}

StringToArray(v) {
	if !(v is String) {
		return []
	}
	return StrSplit(v, ",")
}
