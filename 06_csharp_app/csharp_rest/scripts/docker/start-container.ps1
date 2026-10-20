$ErrorActionPreference = "Stop"

# Navigate to csharp_app/csharp_rest/source directory (scripts are in csharp_app/csharp_rest/scripts/)
cd (Resolve-Path "$PSScriptRoot/../../source")

# Build the Docker image
docker build -t csharp-app -f Dockerfile .

# Run the container
docker run -d -p 8085:80 --name csharp-app-container csharp-app

Write-Host "Container started. Access the app at http://localhost:8085"
