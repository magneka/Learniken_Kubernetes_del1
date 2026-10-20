$ErrorActionPreference = "Stop"

# Navigate to nestjs_ts directory (scripts are in nestjs_ts/scripts/)
cd (Resolve-Path "$PSScriptRoot/../..")

# Set your Docker repository details
$DockerUsername = "magneka"
$DockerRepo = "learniken-nestjs-ts-app"
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
