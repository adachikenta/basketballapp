$ErrorActionPreference = "Stop"
$venvpath = ".\venv"
$checkVenvScript = Join-Path $PSScriptRoot "check_venv.ps1"

Write-Host "Starting coverage report generation..." -ForegroundColor Cyan

# Check if .coverage file exists
if (-not (Test-Path -Path "./__cov__/internal/.coverage")) {
    Write-Host "Error: .coverage file not found in __cov__/internal directory. Please run tests to generate coverage data." -ForegroundColor Red
    exit 1
} else {
    Copy-Item "__cov__/internal/.coverage" ".coverage.internal"
}
if (-not (Test-Path -Path "./__cov__/e2e/.coverage")) {
    Write-Host "Error: .coverage file not found in __cov__/e2e directory. Please run tests to generate coverage data." -ForegroundColor Red
    exit 1
} else {
    Copy-Item "__cov__/e2e/.coverage" ".coverage.e2e"
}

# Run common validation and activate venv
Write-Host "`nValidating Python environment..." -ForegroundColor Yellow
& $checkVenvScript -ActivateVenv
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to activate virtual environment." -ForegroundColor Red
    exit 1
}

# Combine .coverage files
Write-Host "`n===== COMBINING COVERAGE DATA =====" -ForegroundColor Cyan
try {
    & python -m coverage combine .coverage.internal .coverage.e2e
} catch {
    Write-Host "Error: An error occurred while combining coverage data." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
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
Write-Host "`n===== GENERATING COVERAGE REPORT =====" -ForegroundColor Cyan
try {
    & python -m coverage html -d __cov__/combined --title "Total Test Coverage Report"
} catch {
    Write-Host "Error: An error occurred while generating the coverage report." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Display coverage report location
$covReportPath = Join-Path -Path (Get-Location) -ChildPath "__cov__/combined/index.html"
if (Test-Path -Path $covReportPath) {
    Write-Host "`nCoverage report successfully generated:" -ForegroundColor Green

    # move .coverage in to __cov__/combined
    Move-Item -Path ".coverage" -Destination (Join-Path -Path (Get-Location) -ChildPath "__cov__/combined/.coverage") -Force

    Write-Host $covReportPath -ForegroundColor Yellow

    # Open the report
    Start-Process $covReportPath
} else {
    Write-Host "`nWarning: Coverage report file not found." -ForegroundColor Yellow
}

# Deactivate virtual environment
if (Get-Command "deactivate" -ErrorAction SilentlyContinue) {
    Write-Host "`nDeactivating virtual environment..." -ForegroundColor Yellow
    deactivate
}

Write-Host "`nCoverage report generation completed." -ForegroundColor Green
