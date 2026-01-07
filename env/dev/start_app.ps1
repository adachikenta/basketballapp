$ErrorActionPreference = "Stop"

$checkVenvScript = Join-Path $PSScriptRoot "check_venv.ps1"

# Run common validation and activate venv
Write-Host "Validating Python environment..." -ForegroundColor Yellow
& $checkVenvScript -ActivateVenv
if ($LASTEXITCODE -ne 0) {
    exit 1
}

# Run the application
try {
    Write-Host "Starting Flask application..." -ForegroundColor Green
    python app.py
    $appResult = $LASTEXITCODE
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    $appResult = 1
} finally {
    if (Get-Command "deactivate" -ErrorAction SilentlyContinue) {
        Write-Host "Deactivating virtual environment..." -ForegroundColor Yellow
        deactivate
    }

    if ($appResult -eq 0) {
        Write-Host "Application completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "Application exited with errors. Exit code: $appResult" -ForegroundColor Red
    }
}
