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

# Create __cov__/internal directory if it doesn't exist
if (-not (Test-Path -Path "__cov__/internal")) {
    New-Item -Path "__cov__/internal" -ItemType Directory -Force | Out-Null
}

# Move .coverage to __cov__/internal/ before generating reports
Move-Item -Path ".coverage" -Destination (Join-Path -Path (Get-Location) -ChildPath "__cov__\internal\.coverage") -Force
Write-Host "Moved .coverage to __cov__/internal/" -ForegroundColor Yellow

# Display coverage summary
Write-Host "`n===== COVERAGE SUMMARY =====" -ForegroundColor Cyan
try {
    & python -m coverage report --data-file=__cov__/internal/.coverage
} catch {
    Write-Host "Error: An error occurred while generating the coverage report." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
# Display detailed coverage report (including missing lines)
Write-Host "`n===== DETAILED COVERAGE REPORT =====" -ForegroundColor Cyan
try {
    & python -m coverage report -m --data-file=__cov__/internal/.coverage
} catch {
    Write-Host "Error: An error occurred while generating the detailed coverage report." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# Generate coverage report
Write-Host "`n===== GENERATING coverage REPORT =====" -ForegroundColor Cyan
try {
    & python -m coverage html -d __cov__/internal --title "Internal Test Coverage Report" --data-file=__cov__/internal/.coverage
} catch {
    Write-Host "Error: An error occurred while generating the coverage report." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}
# Display coverage report location
$covReportPath = Join-Path -Path (Get-Location) -ChildPath "__cov__\internal\index.html"
if (Test-Path -Path $covReportPath) {
    Write-Host "`nCoverage report successfully generated:" -ForegroundColor Green

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
exit 0
