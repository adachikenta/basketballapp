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
# check if git of scoop is installed
$scoopgit = "$env:USERPROFILE\scoop\apps\git\current\bin\git.exe"
if (Test-Path $scoopgit) {
    Write-Host "git of scoop is already installed." -ForegroundColor Green
} else {
    # install git
    Write-Host "git of scoop is not installed. Installing git..." -ForegroundColor Yellow
    scoop install git
    Write-Host "git of scoop installed successfully." -ForegroundColor Green
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
# check if gettext of scoop installed
$scoopgettext = "$env:USERPROFILE\scoop\apps\gettext\current\bin\msgfmt.exe"
if (Test-Path $scoopgettext) {
    Write-Host "gettext of scoop is already installed." -ForegroundColor Green
} else {
    # install gettext
    Write-Host "gettext is not installed. Installing gettext..." -ForegroundColor Yellow
    scoop install gettext
}
# check if python of scoop is installed
$scooppython = "$env:USERPROFILE\scoop\apps\python\current\python.exe"
if (Test-Path $scooppython) {
    Write-Host "python of scoop is already installed." -ForegroundColor Green
} else {
    # install python
    Write-Host "python of scoop is not installed. Installing python..." -ForegroundColor Yellow
    scoop install python
}
# create a Python virtual environment in the 'venv' directory
if (Test-Path -Path $venvpath) {
    Write-Host "Virtual environment already exists." -ForegroundColor Green
} else {
    Write-Host "Creating virtual environment ..." -ForegroundColor Yellow
    & $scooppython -m venv $venvpath
}
Write-Host "Virtual environment is located at $venvpath" -ForegroundColor Green
