#!/bin/bash
set -euo pipefail

# Navigate to rust_app/08_rust_rest/source directory (scripts are in rust_app/08_rust_rest/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../../source"

# Stop and remove the container if it exists
if docker ps -q --filter "name=rust-app-container" | grep -q .; then
  docker stop rust-app-container
  docker rm rust-app-container
  echo "Old container stopped and removed."
fi

# Build the Docker image
docker build -t rust-app -f Dockerfile .

# Run the container
docker run -d -p 8088:80 --name rust-app-container rust-app

echo "Container restarted. Access the app at http://localhost:8088"
