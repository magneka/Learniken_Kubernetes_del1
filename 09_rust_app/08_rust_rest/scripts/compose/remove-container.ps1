$ErrorActionPreference = "Stop"

Set-Location (Join-Path $PSScriptRoot "..\..\source")

docker compose down -v --rmi all

Write-Host "Containers, networks, volumes, and images removed."
