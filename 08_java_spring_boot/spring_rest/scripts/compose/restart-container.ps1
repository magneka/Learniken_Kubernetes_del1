$ErrorActionPreference = "Stop"

Set-Location $PSScriptRoot

& .\stop-container.ps1
& .\start-container.ps1

Write-Host "Containers restarted."
