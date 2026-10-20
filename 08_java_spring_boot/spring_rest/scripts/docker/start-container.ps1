$ErrorActionPreference = "Stop"

# Navigate to java_spring_boot/spring_rest/source directory (scripts are in java_spring_boot/spring_rest/scripts/)
cd (Resolve-Path "$PSScriptRoot/../../source")

# Build the Docker image
docker build -t spring-app -f Dockerfile .

# Run the container
docker run -d -p 8087:80 --name spring-app-container spring-app

Write-Host "Container started. Access the app at http://localhost:8087"
