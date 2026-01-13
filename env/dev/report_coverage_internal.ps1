$ErrorActionPreference = "Stop"
$venvpath = ".\venv"
$checkVenvScript = Join-Path $PSScriptRoot "check_venv.ps1"

Write-Host "Starting coverage report generation..." -ForegroundColor Cyan

# Check if .coverage file exists
if (-not (Test-Path -Path ".coverage")) {
    Write-Host "Error: .coverage file not found. Please run tests to generate coverage data." -ForegroundColor Red
    exit 1
}

Write-Host "`n.coverage file found. Generating coverage report." -ForegroundColor Green

# Run common validation and activate venv
Write-Host "`nValidating Python environment..." -ForegroundColor Yellow
& $checkVenvScript -ActivateVenv
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to activate virtual environment." -ForegroundColor Red
    exit 1
}
# Display coverage summary
Write-Host "`n===== COVERAGE SUMMARY =====" -ForegroundColor Cyan
try {
    & python -m coverage report
} catch {
    Write-Host "Error: An error occurred while generating the coverage report." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
# Display detailed coverage report (including missing lines)
Write-Host "`n===== DETAILED COVERAGE REPORT =====" -ForegroundColor Cyan
try {
    & python -m coverage report -m
} catch {
    Write-Host "Error: An error occurred while generating the detailed coverage report." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}
# Generate coverage report
Write-Host "`n===== GENERATING coverage REPORT =====" -ForegroundColor Cyan
try {
    & python -m coverage html -d __cov__/internal --title "Internal Test Coverage Report"
} catch {
    Write-Host "Error: An error occurred while generating the coverage report." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
# Display coverage report location
$covReportPath = Join-Path -Path (Get-Location) -ChildPath "__cov__\internal\index.html"
if (Test-Path -Path $covReportPath) {
    Write-Host "`ncoverage report successfully generated:" -ForegroundColor Green
    # move .coverage in to __cov__/internal
    Move-Item -Path ".coverage" -Destination (Join-Path -Path (Get-Location) -ChildPath "__cov__\internal\.coverage") -Force
    Write-Host $covReportPath -ForegroundColor Yellow

    Start-Process $covReportPath
} else {
    Write-Host "`nWarning: coverage report file not found." -ForegroundColor Yellow
}

# Deactivate virtual environment
if (Get-Command "deactivate" -ErrorAction SilentlyContinue) {
    Write-Host "`nDeactivating virtual environment..." -ForegroundColor Yellow
    deactivate
}

Write-Host "`nCoverage report generation completed." -ForegroundColor Green
