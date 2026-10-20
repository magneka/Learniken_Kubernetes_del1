#!/bin/bash
set -euo pipefail

# Navigate to java_spring_boot/spring_rest/source directory (scripts are in java_spring_boot/spring_rest/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../../source"

# Set your Docker repository details
DOCKER_USERNAME="magneka"
DOCKER_REPO="learniken-spring-app"
IMAGE_TAG="latest"

# Full image name
FULL_IMAGE_NAME="$DOCKER_USERNAME/$DOCKER_REPO:$IMAGE_TAG"

# Build the Docker image
echo "Building Docker image..."
docker build -t $FULL_IMAGE_NAME -f Dockerfile .

# Login to Docker Hub (optional, if not already logged in)
echo "Logging in to Docker Hub..."
docker login

# Push the image to repository
echo "Pushing image to Docker Hub..."
docker push $FULL_IMAGE_NAME

echo "Image pushed successfully to $FULL_IMAGE_NAME"
