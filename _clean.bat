@echo off
setlocal
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -NoLogo -File .\env\dev\clean.ps1
endlocal
pause
