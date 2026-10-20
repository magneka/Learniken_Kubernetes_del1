#!/bin/bash
set -euo pipefail

# Navigate to go/go_rest/source directory (scripts are in go/go_rest/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../../source"

# Stop and remove the container if it exists
if docker ps -q --filter "name=go-app-container" | grep -q .; then
  docker stop go-app-container
  docker rm go-app-container
  echo "Old container stopped and removed."
fi

# Build the Docker image
docker build -t go-app -f Dockerfile .

# Run the container
docker run -d -p 8086:80 --name go-app-container go-app

echo "Container restarted. Access the app at http://localhost:8086"
