$venvpath = ".\venv"
function Install-PlaywrightBrowsers {
    
    try {
        Write-Host "Playwright browsers not found. Installing..." -ForegroundColor Yellow
        
        # Set environment variable to bypass SSL certificate issues in corporate environments
        $env:NODE_TLS_REJECT_UNAUTHORIZED = "0"
        
        # Install Playwright browsers
        & ".\venv\Scripts\python.exe" -m playwright install
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "Playwright browsers installed successfully!" -ForegroundColor Green
        } else {
            Write-Host "Warning: Playwright browser installation may have had issues, but continuing..." -ForegroundColor Yellow
        }
        
        # Clean up environment variable
        Remove-Item env:NODE_TLS_REJECT_UNAUTHORIZED -ErrorAction SilentlyContinue
    } catch {
        Write-Host "Error checking/installing Playwright browsers: $_" -ForegroundColor Yellow
        Write-Host "Attempting to install anyway..." -ForegroundColor Yellow
        
        try {
            # Set environment variable to bypass SSL certificate issues
            $env:NODE_TLS_REJECT_UNAUTHORIZED = "0"
            
            # Install Playwright browsers
            & ".\venv\Scripts\python.exe" -m playwright install
            
            # Clean up environment variable
            Remove-Item env:NODE_TLS_REJECT_UNAUTHORIZED -ErrorAction SilentlyContinue
            
            Write-Host "Playwright browser installation completed." -ForegroundColor Green
        } catch {
            Write-Host "Failed to install Playwright browsers: $_" -ForegroundColor Red
            Write-Host "You may need to run 'python -m playwright install' manually." -ForegroundColor Yellow
        }
    }
}
# activate the virtual environment
Write-Host "Activating virtual environment ..." -ForegroundColor Yellow
. .\$venvpath\Scripts\Activate.ps1
try {
    # check if pip is installed
    if (Get-Command pip -ErrorAction SilentlyContinue) {
        Write-Host "pip is already installed." -ForegroundColor Green
    } else {
        # install pip
        Write-Host "pip is not installed. Installing pip..." -ForegroundColor Yellow
        python -m ensurepip
    }
    # upgrade pip to the latest version
    Write-Host "Upgrading pip to the latest version..." -ForegroundColor Yellow
    python -m pip install --upgrade pip | Where-Object { 
        $_ -notmatch "Requirement already satisfied:" -and
        $_ -notmatch "Using cached"
    }
    # install the required packages from requirements.txt
    Write-Host "Installing required packages for application from requirements.txt..." -ForegroundColor Yellow
    pip install -r requirements.txt | Where-Object { 
        $_ -notmatch "Requirement already satisfied:" -and
        $_ -notmatch "Using cached"
    }
    # install the required packages from ./env/dev/requirements.txt
    Write-Host "Installing required packages for tests from ./env/dev/requirements.txt..." -ForegroundColor Yellow
    pip install -r ./env/dev/requirements.txt | Where-Object { 
        $_ -notmatch "Requirement already satisfied:" -and
        $_ -notmatch "Using cached"
    }
    # Install Playwright browsers if needed
    Install-PlaywrightBrowsers
}
catch {
    Write-Host "An error occurred during setup: $_" -ForegroundColor Red
} finally {
    Write-Host "Deactivating virtual environment ..." -ForegroundColor Yellow
    deactivate
    Write-Host "Deactivated virtual environment ..." -ForegroundColor DarkGray
}
Write-Host "Virtual environment setup completed." -ForegroundColor Green
