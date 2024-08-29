; AHK script to send email via powershell command.
; Based on https://www.autohotkey.com/boards/viewtopic.php?t=67283

#Requires AutoHotkey v2.0

/*
global _smtp := {}
_smtp.username := "***@gmail.com"
_smtp.password := "**** **** **** ****" ; create app password https://security.google.com/settings/security/apppasswords

global _email := {} 
_email.from := "Test Sender Name <" _smtp.username ">" ; must be formatted as "a@b.com" or "Abc <abc@d.com>"
_email.to := "Test1 <test1@gmail.com>, test2@gmail.com"
_email.subj := "Test Email" FormatTime(, " (HH:mm, dddd)")
_email.body := "Test.`r`nTesting of SendEmail AHK script...`r`nTesting done."

SendEmail(_smtp, _email, true)
*/

SendEmail(smtp, email, debug := false) {
	if (!smtp.HasOwnProp("server"))
		smtp.server := 'smtp.gmail.com'
	if (!smtp.HasOwnProp("port"))
		smtp.port := 587

	PS := 'powershell.exe'
	cmd := "`"" 
		. (debug ? "try{" : "")
		. "Send-MailMessage -From '" email.from
		. "' -To " FormatToPowershellArray(email.to)
		. " -Subject '" email.subj
		. "' -BodyAsHtml -Body '" email.body
		. "' -SmtpServer '" smtp.server
		. "' -port '" smtp.port
		. "' -UseSsl -Credential (New-Object -TypeName System.Management.Automation.PSCredential"
		. " -ArgumentList ('" smtp.username
		. "', (ConvertTo-SecureString -String '" smtp.password
		. "' -AsPlainText -Force)));"
		. (debug ? "Write-Host 'Email sent, subj: " email.subj "';" : "")
		. (debug ? "}catch{" : "")
		. (debug ? "Write-Host 'Send email error:';" : "")
		. (debug ? "Write-Host $_;" : "")
		. (debug ? "}" : "")
		. "`""

		
	if (debug) {
		A_Clipboard := cmd
		Run(PS . ' -noexit -command ' . cmd)
		return
	}

	Run(PS . ' -command ' . cmd,, 'Hide')
}

FormatToPowershellArray(tosStr) {
	prefix := "@("
	suffix := ")"
	result := ""
	
	for index, to in StrSplit(tosStr, ",")
		result .= "'" Trim(to) "',"

	return prefix Trim(result, ",") suffix
}
