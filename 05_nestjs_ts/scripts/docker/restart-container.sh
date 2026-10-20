#!/bin/bash
set -euo pipefail

# Navigate to nestjs_ts directory (scripts are in nestjs_ts/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../.."

# Stop and remove the container if it exists
if docker ps -q --filter "name=nestjs-ts-app-container" | grep -q .; then
  docker stop nestjs-ts-app-container
  docker rm nestjs-ts-app-container
  echo "Old container stopped and removed."
fi

# Build the Docker image
docker build -t nestjs-ts-app -f Dockerfile .

# Run the container
docker run -d -p 8084:80 --name nestjs-ts-app-container nestjs-ts-app

echo "Container restarted. Access the app at http://localhost:8084"
