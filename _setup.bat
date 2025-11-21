@echo off
setlocal
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -NoLogo -File .\env\dev\create_venv.ps1
powershell -ExecutionPolicy Bypass -NoLogo -File .\env\dev\setup_venv.ps1
endlocal
pause
