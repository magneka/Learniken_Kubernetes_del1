$ErrorActionPreference = "Stop"

# Navigate to go/go_rest/source directory (scripts are in go/go_rest/scripts/)
cd (Resolve-Path "$PSScriptRoot/../../source")

# Build the Docker image
docker build -t go-app -f Dockerfile .

# Run the container
docker run -d -p 8086:80 --name go-app-container go-app

Write-Host "Container started. Access the app at http://localhost:8086"
