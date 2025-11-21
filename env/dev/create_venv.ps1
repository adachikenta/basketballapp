$venvpath = ".\venv"
# check if scoop is installed
if (Get-Command scoop -ErrorAction SilentlyContinue) {
    Write-Host "scoop is already installed." -ForegroundColor Green
} else {
    # install scoop
    Write-Host "scoop is not installed. Installing scoop..." -ForegroundColor Yellow
    Invoke-Expression (new-object net.webclient).downloadstring('https://get.scoop.sh')
    Write-Host "scoop installed successfully." -ForegroundColor Green
}
# check if git is installed
if (Get-Command git -ErrorAction SilentlyContinue) {
    Write-Host "git is already installed." -ForegroundColor Green
} else {
    # install git
    Write-Host "git is not installed. Installing git..." -ForegroundColor Yellow
    scoop install git
    Write-Host "git installed successfully." -ForegroundColor Green
}
# check sslbackend of git
$gitConfig = git config --global -l
if ($gitConfig -match "http.sslbackend=schannel") {
    Write-Host "git sslbackend is already set to schannel." -ForegroundColor Green
} else {
    # set sslbackend to schannel
    Write-Host "git sslbackend is not set to schannel. Setting it to schannel..." -ForegroundColor Yellow
    git config --global http.sslbackend schannel
    Write-Host "git sslbackend set to schannel successfully." -ForegroundColor Green
}
# check versions bucket
if (scoop bucket list | Select-String -Pattern "versions") {
    Write-Host "versions bucket is already added." -ForegroundColor Green
} else {
    # add versions bucket
    Write-Host "versions bucket is not added. Adding versions bucket..." -ForegroundColor Yellow
    scoop bucket add versions
    Write-Host "versions bucket added successfully." -ForegroundColor Green
}
# check if msgfmt installed
if (Get-Command msgfmt -ErrorAction SilentlyContinue) {
    Write-Host "msgfmt is already installed." -ForegroundColor Green
} else {
    # install gettext
    Write-Host "gettext is not installed. Installing gettext..." -ForegroundColor Yellow
    scoop install gettext
}
$pythonversion = "python3"
# check if python is installed
if (Get-Command $pythonversion -ErrorAction SilentlyContinue) {
    Write-Host "$pythonversion is already installed." -ForegroundColor Green
} else {
    # install python
    Write-Host "$pythonversion is not installed. Installing $pythonversion..." -ForegroundColor Yellow
    scoop install $pythonversion
}
# create a Python virtual environment in the 'venv' directory
if (Test-Path -Path $venvpath) {
    Write-Host "Virtual environment already exists." -ForegroundColor Green
} else {
    Write-Host "Creating virtual environment ..." -ForegroundColor Yellow
    python3 -m venv $venvpath
}
Write-Host "Virtual environment is located at $venvpath" -ForegroundColor Green
