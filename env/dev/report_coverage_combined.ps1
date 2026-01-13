$ErrorActionPreference = "Stop"
$checkVenvScript = Join-Path $PSScriptRoot "check_venv.ps1"

Write-Host "Starting coverage report generation..." -ForegroundColor Cyan

# Check if .coverage files exist in __cov__ directories
if (-not (Test-Path -Path "__cov__/internal/.coverage")) {
    Write-Host "Error: .coverage file not found in __cov__/internal/. Please run internal tests first." -ForegroundColor Red
    exit 1
}
if (-not (Test-Path -Path "__cov__/e2e/.coverage")) {
    Write-Host "Error: .coverage file not found in __cov__/e2e/. Please run e2e tests first." -ForegroundColor Red
    exit 1
}

# Run common validation and activate venv
Write-Host "`nValidating Python environment..." -ForegroundColor Yellow
& $checkVenvScript -ActivateVenv
if ($LASTEXITCODE -ne 0) {
    Write-Host "Error: Failed to activate virtual environment." -ForegroundColor Red
    exit 1
}

# Remove existing .coverage file if present
if (Test-Path -Path ".coverage") {
    Remove-Item ".coverage" -Force
    Write-Host "Removed existing .coverage file" -ForegroundColor Yellow
}

# Combine .coverage files directly to __cov__/.coverage
Write-Host "`n===== COMBINING COVERAGE DATA =====" -ForegroundColor Cyan
try {
    & python -m coverage combine --keep --data-file=__cov__/.coverage __cov__/internal/.coverage __cov__/e2e/.coverage
    if (Test-Path "__cov__/.coverage") {
        Write-Host "Created combined .coverage in __cov__ directory" -ForegroundColor Yellow
    } else {
        Write-Host "Error: Failed to create combined .coverage file." -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "Error: An error occurred while combining coverage data." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Create __cov__/combined directory if it doesn't exist
if (-not (Test-Path -Path "__cov__/combined")) {
    New-Item -Path "__cov__/combined" -ItemType Directory -Force | Out-Null
}

# Move __cov__/.coverage to __cov__/combined/ before generating reports
Move-Item -Path "__cov__/.coverage" -Destination (Join-Path -Path (Get-Location) -ChildPath "__cov__\combined\.coverage") -Force
Write-Host "Moved __cov__/.coverage to __cov__/combined/" -ForegroundColor Yellow

# Display coverage summary
Write-Host "`n===== COVERAGE SUMMARY =====" -ForegroundColor Cyan
try {
    & python -m coverage report --data-file=__cov__/combined/.coverage
} catch {
    Write-Host "Error: An error occurred while generating the coverage report." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Display detailed coverage report (including missing lines)
Write-Host "`n===== DETAILED COVERAGE REPORT =====" -ForegroundColor Cyan
try {
    & python -m coverage report -m --data-file=__cov__/combined/.coverage
} catch {
    Write-Host "Error: An error occurred while generating the detailed coverage report." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
}

# Generate coverage report
Write-Host "`n===== GENERATING COVERAGE REPORT =====" -ForegroundColor Cyan
try {
    & python -m coverage html -d __cov__/combined --title "Total Test Coverage Report" --data-file=__cov__/combined/.coverage
} catch {
    Write-Host "Error: An error occurred while generating the coverage report." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    exit 1
}

# Display coverage report location
$covReportPath = Join-Path -Path (Get-Location) -ChildPath "__cov__/combined/index.html"
if (Test-Path -Path $covReportPath) {
    Write-Host "`nCoverage report successfully generated:" -ForegroundColor Green

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
exit 0
