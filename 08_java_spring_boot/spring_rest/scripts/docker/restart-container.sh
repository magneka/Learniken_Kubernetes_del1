#!/bin/bash
set -euo pipefail

# Navigate to java_spring_boot/spring_rest/source directory (scripts are in java_spring_boot/spring_rest/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../../source"

# Stop and remove the container if it exists
if docker ps -q --filter "name=spring-app-container" | grep -q .; then
  docker stop spring-app-container
  docker rm spring-app-container
  echo "Old container stopped and removed."
fi

# Build the Docker image
docker build -t spring-app -f Dockerfile .

# Run the container
docker run -d -p 8087:80 --name spring-app-container spring-app

echo "Container restarted. Access the app at http://localhost:8087"
