@echo off

rem LAUNCHMODE: 0 != Command-line
echo %CMDCMDLINE% | findstr /C:"/c" >nul
set LAUNCHMODE=%errorlevel%

setlocal
cd /d "%~dp0"

powershell -ExecutionPolicy Bypass -NoLogo -File .\env\dev\po2mo.ps1
REM po2mo.ps1 failure is not critical, continue anyway

powershell -ExecutionPolicy Bypass -NoLogo -File .\env\dev\run_tests_internal.ps1
if %ERRORLEVEL% NEQ 0 (goto :catch)

powershell -ExecutionPolicy Bypass -NoLogo -File .\env\dev\run_tests_e2e.ps1
if %ERRORLEVEL% NEQ 0 (goto :catch)

powershell -ExecutionPolicy Bypass -NoLogo -File .\env\dev\report_coverage_combined.ps1
if %ERRORLEVEL% NEQ 0 (goto :catch)

:catch
:finally
set EXIT_CODE=%ERRORLEVEL%
endlocal & set EXIT_CODE=%EXIT_CODE%
if %LAUNCHMODE% NEQ 0 (exit /b %EXIT_CODE%)
cmd /k
