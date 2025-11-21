@echo off
setlocal
cd /d "%~dp0"
powershell -ExecutionPolicy Bypass -NoLogo -File .\env\dev\run_tests_internal.ps1
taskkill /F /IM python.exe /FI "WINDOWTITLE eq *app.py*" 2>NUL
if %ERRORLEVEL% EQU 0 (
    echo Additional cleanup completed.
)
powershell -ExecutionPolicy Bypass -NoLogo -File .\env\dev\report_coverage_internal.ps1
powershell -ExecutionPolicy Bypass -NoLogo -File .\env\dev\run_tests_e2e.ps1
taskkill /F /IM python.exe /FI "WINDOWTITLE eq *app.py*" 2>NUL
if %ERRORLEVEL% EQU 0 (
    echo Additional cleanup completed.
)
powershell -ExecutionPolicy Bypass -NoLogo -File .\env\dev\report_coverage_e2e.ps1
powershell -ExecutionPolicy Bypass -NoLogo -File .\env\dev\report_coverage_combined.ps1
endlocal
