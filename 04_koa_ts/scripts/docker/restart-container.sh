#!/bin/bash
set -euo pipefail

# Navigate to koa_ts directory (scripts are in koa_ts/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../.."

# Stop and remove the container if it exists
if docker ps -q --filter "name=koa-ts-app-container" | grep -q .; then
  docker stop koa-ts-app-container
  docker rm koa-ts-app-container
  echo "Old container stopped and removed."
fi

# Build the Docker image
docker build -t koa-ts-app -f Dockerfile .

# Run the container
docker run -d -p 8083:80 --name koa-ts-app-container koa-ts-app

echo "Container restarted. Access the app at http://localhost:8083"
