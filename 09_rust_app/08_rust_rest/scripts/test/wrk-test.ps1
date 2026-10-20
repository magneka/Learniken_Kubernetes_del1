# Run wrk load test
$ErrorActionPreference = "Stop"

if (-not (Get-Command wrk -ErrorAction SilentlyContinue)) {
    Write-Host "wrk is not installed. Please install wrk first."
    exit 1
}

Write-Host ""
Write-Host "Running wrk load test ..."
wrk -t5 -c5 -d20s http://localhost:8088

Write-Host "Done."
