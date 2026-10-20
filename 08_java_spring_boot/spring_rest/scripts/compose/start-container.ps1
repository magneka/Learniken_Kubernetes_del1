$ErrorActionPreference = "Stop"

Set-Location (Join-Path $PSScriptRoot "..\..\source")

docker compose up -d --build

Write-Host "Containers started. Access the app at http://localhost:8087"
