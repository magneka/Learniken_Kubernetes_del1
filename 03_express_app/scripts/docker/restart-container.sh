#!/bin/bash
set -euo pipefail

# Navigate to express_app directory (scripts are in express_app/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../.."

# Stop and remove the container if it exists
if docker ps -q --filter "name=express-app-container" | grep -q .; then
  docker stop express-app-container
  docker rm express-app-container
  echo "Old container stopped and removed."
fi

# Build the Docker image
docker build -t express-app -f Dockerfile .

# Run the container
docker run -d -p 8082:80 --name express-app-container express-app

echo "Container restarted. Access the app at http://localhost:8082"
