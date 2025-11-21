$venvpath = ".\venv"
if (Test-Path $venvpath) {
    $absolutevenvpath = (Resolve-Path -Path $venvpath -ErrorAction SilentlyContinue).Path
    # check if python exe in the virtual environment is running
    $pythonExe = Join-Path -Path $absolutevenvpath -ChildPath "Scripts\python.exe"
    if (Get-Process | Where-Object { $_.Path -eq $pythonExe }) {
        Write-Host "killing python process at $pythonExe" -ForegroundColor Yellow
        Get-Process | Where-Object { $_.Path -eq $pythonExe } | ForEach-Object {
            try {
                Stop-Process -Id $_.Id -Force -ErrorAction Stop
                Write-Host "Python process with ID $($_.Id) stopped successfully." -ForegroundColor Green
            } catch {
                Write-Host "Failed to stop Python process with ID $($_.Id): $_" -ForegroundColor Red
                exit
            }
        }
    } else {
        Write-Host "Not found process $pythonExe" -ForegroundColor Green
    }
} else {
    Write-Host "Virtual environment not found at $venvpath" -ForegroundColor Green
}
$gitignorePath = ".\.gitignore"
if (Test-Path $gitignorePath) {
    try {
        Write-Host "Removing files" -ForegroundColor Yellow
        git clean -fdX
    } catch {
        Write-Host "Failed to remove directory $($dir.FullName): $_" -ForegroundColor Red
    }
} else {
    Write-Host ".gitignore file not found at $gitignorePath" -ForegroundColor Red
}
