@echo off
:: Check for Administrator privileges
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting Administrative Privileges...
    powershell -Command "Start-Process '%~f0' -Verb RunAs"
    exit /b
)

echo Disabling Internal PS/2 Keyboard...
powershell -Command "Get-PnpDevice -Class Keyboard | Where-Object {$_.FriendlyName -match 'PS/2'} | Disable-PnpDevice -Confirm:$false"
echo.
echo Command sent. If the keyboard is still typing, your laptop's BIOS may be locking it.
pause
