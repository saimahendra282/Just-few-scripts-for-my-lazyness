Set shell = CreateObject("WScript.Shell")

folder = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))
ps1 = folder & "Mousectrl.ps1"

If WScript.Arguments.Count > 0 Then
    toggle = WScript.Arguments(0)
Else
    toggle = "ScrollLock"
End If

command = "powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -File """ & ps1 & """ -ToggleKey """ & toggle & """"

shell.Run command, 0, False
