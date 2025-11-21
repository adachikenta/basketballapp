# Internal Testing
$venvPath = ".\venv"
$reportPath = Join-Path -Path (Get-Location) -ChildPath "__tests__/report_internal.html"
try {
    Write-Host "Activating virtual environment..." -ForegroundColor Yellow
    . $venvPath\Scripts\Activate.ps1
    # Run the tests with or without coverage based on parameters
    Write-Host "Running tests with coverage..." -ForegroundColor Yellow
    & "$venvPath\Scripts\pytest.exe" -v --html=$reportPath --cov=. --cov-config=pytest.ini --cov-report=$CoverageFormat
    $testResult = $LASTEXITCODE
} catch {
    Write-Host "Error: $_" -ForegroundColor Red
    $testResult = 1
} finally {
    if (Get-Command "deactivate" -ErrorAction SilentlyContinue) {
        Write-Host "Deactivating virtual environment..." -ForegroundColor Yellow
        deactivate
    }
    if ($testResult -eq 0) {
        Write-Host "Tests completed successfully!" -ForegroundColor Green
    } else {
        Write-Host "Tests failed or had errors. Exit code: $testResult" -ForegroundColor Red
    }
    
    Write-Host "Done!" -ForegroundColor Green
    if (Test-Path -Path $reportPath) {
        Start-Process $reportPath
    }
    # Force exit the script to ensure all child processes are terminated
    [System.Environment]::Exit(0)
}
