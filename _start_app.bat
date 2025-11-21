@echo off
setlocal
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -NoLogo -File .\env\dev\po2mo.ps1
powershell -ExecutionPolicy Bypass -NoExit -NoLogo -File .\env\dev\start_app.ps1
endlocal
