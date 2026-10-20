$ErrorActionPreference = "Stop"

# Navigate to express_app directory (scripts are in express_app/scripts/)
cd (Resolve-Path "$PSScriptRoot/../..")

# Build the Docker image
docker build -t express-app -f Dockerfile .

# Run the container
docker run -d -p 8082:80 --name express-app-container express-app

Write-Host "Container started. Access the app at http://localhost:8082"
