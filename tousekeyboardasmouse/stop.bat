@echo off
title Stop A Lazy Mouse

echo Searching for A Lazy Mouse...

powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
"$procs = Get-CimInstance Win32_Process -Filter \"Name = 'powershell.exe'\" | Where-Object { $_.CommandLine -and $_.CommandLine -match 'Mousectrl.ps1' }; ^
if ($procs) { ^
    foreach ($p in $procs) { ^
        Write-Host ('Stopping A Lazy Mouse PID ' + $p.ProcessId); ^
        Stop-Process -Id $p.ProcessId -Force ^
    } ^
    Write-Host 'A Lazy Mouse stopped.' ^
} else { ^
    Write-Host 'A Lazy Mouse is not running.' ^
}"

echo.
pause
