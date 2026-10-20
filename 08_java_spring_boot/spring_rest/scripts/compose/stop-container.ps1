$ErrorActionPreference = "Stop"

Set-Location (Join-Path $PSScriptRoot "..\..\source")

docker compose down

Write-Host "Containers stopped."
