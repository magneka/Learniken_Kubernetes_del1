$ErrorActionPreference = "Stop"

# Navigate to nestjs_ts directory (scripts are in nestjs_ts/scripts/)
cd (Resolve-Path "$PSScriptRoot/../..")

# Build the Docker image
docker build -t nestjs-ts-app -f Dockerfile .

# Run the container
docker run -d -p 8084:80 --name nestjs-ts-app-container nestjs-ts-app

Write-Host "Container started. Access the app at http://localhost:8084"
