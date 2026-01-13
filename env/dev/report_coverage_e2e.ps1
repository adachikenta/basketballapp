$ErrorActionPreference = "Stop"
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

# Create __cov__/e2e directory if it doesn't exist
if (-not (Test-Path -Path "__cov__/e2e")) {
    New-Item -Path "__cov__/e2e" -ItemType Directory -Force | Out-Null
}

# Move .coverage to __cov__/e2e/ before generating reports
Move-Item -Path ".coverage" -Destination (Join-Path -Path (Get-Location) -ChildPath "__cov__\e2e\.coverage") -Force
Write-Host "Moved .coverage to __cov__/e2e/" -ForegroundColor Yellow

# Display coverage summary
Write-Host "`n===== COVERAGE SUMMARY =====" -ForegroundColor Cyan
try {
    & python -m coverage report --data-file=__cov__/e2e/.coverage
} catch {
    Write-Host "Error: An error occurred while generating the coverage report." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Display detailed coverage report (including missing lines)
Write-Host "`n===== DETAILED COVERAGE REPORT =====" -ForegroundColor Cyan
try {
    & python -m coverage report -m --data-file=__cov__/e2e/.coverage
} catch {
    Write-Host "Error: An error occurred while generating the detailed coverage report." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# Generate coverage report
Write-Host "`n===== GENERATING COVERAGE REPORT =====" -ForegroundColor Cyan
try {
    & python -m coverage html -d .\__cov__\e2e --title "E2E Test Coverage Report" --data-file=__cov__/e2e/.coverage
} catch {
    Write-Host "Error: An error occurred while generating the coverage report." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Display coverage report location
$covReportPath = Join-Path -Path (Get-Location) -ChildPath "__cov__\e2e\index.html"
if (Test-Path -Path $covReportPath) {
    Write-Host "`nCoverage report successfully generated:" -ForegroundColor Green

    Write-Host $covReportPath -ForegroundColor Yellow

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
exit 0
