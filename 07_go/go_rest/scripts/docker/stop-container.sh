#!/bin/bash
set -euo pipefail

# Navigate to go/go_rest/source directory (scripts are in go/go_rest/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../../source"

# Stop and remove the container
if docker ps -q --filter "name=go-app-container" | grep -q .; then
  docker stop go-app-container
  docker rm go-app-container
  echo "Container go-app-container stopped and removed."
else
  echo "Container go-app-container is not running."
fi
