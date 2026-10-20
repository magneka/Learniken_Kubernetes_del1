$ErrorActionPreference = "Stop"

# Navigate to rust_app/08_rust_rest/source directory (scripts are in rust_app/08_rust_rest/scripts/)
cd (Resolve-Path "$PSScriptRoot/../../source")

# Build the Docker image
docker build -t rust-app -f Dockerfile .

# Run the container
docker run -d -p 8088:80 --name rust-app-container rust-app

Write-Host "Container started. Access the app at http://localhost:8088"
