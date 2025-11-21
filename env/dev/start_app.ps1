$venvpath = ".\venv"
# activate the virtual environment
try {
Write-Host "Activating virtual environment ..." -ForegroundColor Yellow
. .\$venvpath\Scripts\Activate.ps1
# run the app
Write-Host "Starting the Flask application..." -ForegroundColor Green
try {
    python app.py
} catch {
    Write-Host "An error occurred while starting the application: $_" -ForegroundColor Red
} finally {
    deactivate
    Write-Host "if you want to run the cli script again, run the app_devenv_start_app.bat script." -ForegroundColor Yellow
}
} catch {
    Write-Host "An error occurred while starting the application: $_" -ForegroundColor Red
}
