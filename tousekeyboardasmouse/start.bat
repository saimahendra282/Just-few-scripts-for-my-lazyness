@echo off
setlocal

:MENU

cls

echo ==============================
echo          A LAZY MOUSE
echo ==============================
echo.
echo Choose the key used to toggle
echo Mouse Mode ON / OFF:
echo.
echo   1. Caps Lock
echo   2. Print Screen / SysRq
echo   3. Scroll Lock
echo   4. Pause / Break
echo.

set /p "choice=Enter choice (1-4): "

if "%choice%"=="1" set "TOGGLE=CapsLock" & goto START
if "%choice%"=="2" set "TOGGLE=PrintScreen" & goto START
if "%choice%"=="3" set "TOGGLE=ScrollLock" & goto START
if "%choice%"=="4" set "TOGGLE=PauseBreak" & goto START

echo.
echo Invalid choice.
timeout /t 2 >nul
goto MENU

:START

echo.
echo Selected toggle: %TOGGLE%
echo Starting A Lazy Mouse...
echo.

wscript.exe "%~dp0RunMouse.vbs" "%TOGGLE%"

exit /b
