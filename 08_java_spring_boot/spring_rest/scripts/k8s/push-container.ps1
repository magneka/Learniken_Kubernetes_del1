$ErrorActionPreference = "Stop"

# Navigate to java_spring_boot/spring_rest/source directory (scripts are in java_spring_boot/spring_rest/scripts/)
cd (Resolve-Path "$PSScriptRoot/../../source")

# Set your Docker repository details
$DockerUsername = "magneka"
$DockerRepo = "learniken-spring-app"
$ImageTag = "latest"

# Full image name
$FullImageName = "${DockerUsername}/${DockerRepo}:${ImageTag}"

# Build the Docker image
Write-Host "Building Docker image..."
docker build -t $FullImageName -f Dockerfile .

# Login to Docker Hub (optional, if not already logged in)
Write-Host "Logging in to Docker Hub..."
docker login

# Push the image to repository
Write-Host "Pushing image to Docker Hub..."
docker push $FullImageName

Write-Host "Image pushed successfully to $FullImageName"
