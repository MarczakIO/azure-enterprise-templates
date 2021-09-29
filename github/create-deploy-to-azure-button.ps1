param ($url)

$ErrorActionPreference = "Stop"

if ($null -eq $url) {
    Write-Host "Please provide full URL to a raw ARM template"
    $url = Read-Host
}

## This code is just testing the URL, it's not important otherwise
if ($null -ne $url) {
    Write-Host "Do you want to test if URL returns JSON (y/n)?"
    $test = Read-Host

    if ("y" -eq $test.ToLower() -or "yes" -eq $test.ToLower()) {
        Write-Host "Downloading..."
        $json = Invoke-WebRequest -Method Get -Uri $url
        Write-Host "Parsing..."
        $json = $json | ConvertFrom-Json
        Write-Host "Json is OK!"
    }

    $escapedUri = [uri]::EscapeDataString($url)
    $deployUri = "https://portal.azure.com/#create/Microsoft.Template/uri/$escapedUri"

    Write-Host "MARKDOWN use"
    Write-Host "[![Deploy to Azure](https://aka.ms/deploytoazurebutton)]($deployUri)" -ForegroundColor Green

    Write-Host "HTML use"
    Write-Host "<a href='$deployUri' target='_blank'>" -ForegroundColor Cyan
    Write-Host "  <img src='https://aka.ms/deploytoazurebutton'/>" -ForegroundColor Cyan
    Write-Host "</a>" -ForegroundColor Cyan

} else {
    Write-Host "URL is empty. Stopping..."
}