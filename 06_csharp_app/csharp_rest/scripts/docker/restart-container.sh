#!/bin/bash
set -euo pipefail

# Navigate to csharp_app/csharp_rest/source directory (scripts are in csharp_app/csharp_rest/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../../source"

# Stop and remove the container if it exists
if docker ps -q --filter "name=csharp-app-container" | grep -q .; then
  docker stop csharp-app-container
  docker rm csharp-app-container
  echo "Old container stopped and removed."
fi

# Build the Docker image
docker build -t csharp-app -f Dockerfile .

# Run the container
docker run -d -p 8085:80 --name csharp-app-container csharp-app

echo "Container restarted. Access the app at http://localhost:8085"
