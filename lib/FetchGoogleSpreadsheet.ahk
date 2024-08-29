#Requires AutoHotkey v2.0

; request google spreadsheet as an csv, parse first two columns, return object
FetchGoogleSpreadsheet(resource, attempts := 3, period := 5000, debug := false) {
	prefix := "https://docs.google.com/spreadsheets/d/"
	suffix := "/export?format=csv"
	e := false

	if (InStr(resource, "http")) {
		csvUrl := resource
	} else {
		csvUrl := prefix . resource . suffix
	}

	try {
		_attempts := attempts - 1
		whr := ComObject("WinHttp.WinHttpRequest.5.1")
		whr.Open("GET", csvUrl)
		whr.Send()
		response := whr.ResponseText
	} catch Error as e {
		response := e.Message
	}

	if (debug)
		A_Clipboard := "FetchGoogleSpreadsheet(" . resource . ")→" . response

	if (e) {
		if (_attempts > 0) {
			Sleep period
			return FetchGoogleSpreadsheet(resource, _attempts, period)
		} else {
			return {}
		}
	} else {
		return ParseCsv(response)
	}
}

ParseCsv(text) {
	result := {}
	linesArray := StrSplit(text, "`n", " `t`r")
	for line in linesArray {
		if !IsGood(line)
			continue
		ParseCsvLine(&result, line)
	}
	return result
}

ParseCsvLine(&obj, line) {
	_line := Enquote(Trim(line, " ,"))
	kvpair := StrSplit(_line, ',',, 3)

	if (kvpair.Length > 1 and InStr(kvpair[2], '"')) {
		; case abc,"def",...
		kvpair := StrSplit(_line, [',"', '",'],, 3)
		if (kvpair.Length < 2) {
			kvpair := StrSplit(_line, ',',, 3)
		}
	}

	if (kvpair.Length < 2)
		return

	k := kvpair[1]
	v := Dequote(kvpair[2])
	; MsgBox k " ---:--- " v

	if !(IsGood(k) and IsGood(v))
		return

	parts := StrSplit(k, ".") ; parse keys like "email.subj" 
	val := ParseValue(v) ; try parse array "[...]"

	; append props to object
	if (parts.Length == 1) {
		obj.%k% := val
	} else if (parts.Length == 2) {
		prefix := parts[1]
		nested := parts[2]
		if (obj.HasOwnProp(prefix)) {
			o2 := obj.%prefix%
			o2.%nested% := val
		} else {
			obj.%prefix% := { %nested%: val }
		}
	}
}

ParseValue(str) {
	if (str == "TRUE" or str == "true")
		return 1
	if (str == "FALSE" or str == "false")
		return 0

	parts := StrSplit(str, ["[", "]"], " ")
	if (parts.Length == 3) {
		items := StrSplit(parts[2], ",", ' "')
		return items
	}
	return Trim(str, '"')
}

IsGood(str) {
	if StrLen(Trim(Trim(str, ","))) > 0
		return true
	return false
}

Enquote(str) {
	return StrReplace(str, '""', '%22')
}

Dequote(str) {
	return StrReplace(str, '%22', '"')
}
