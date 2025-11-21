$translations = ".\translations"
Get-ChildItem $translations -Recurse -Filter *.po | ForEach-Object {
    $po = $_.FullName
    $mo = $po -replace '\.po$', '.mo'
    if (!(Test-Path $mo) -or ((Get-Item $po).LastWriteTime -gt (Get-Item $mo).LastWriteTime)) {
        Write-Host "Converting $po -> $mo"
        & msgfmt -o $mo $po
    } else {
        Write-Host "Skipping $po (up-to-date)"
    }
}
