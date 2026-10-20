#!/bin/bash
set -euo pipefail

# Navigate to csharp_app/csharp_rest/source directory (scripts are in csharp_app/csharp_rest/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../../source"

# Stop and remove the container
if docker ps -q --filter "name=csharp-app-container" | grep -q .; then
  docker stop csharp-app-container
  docker rm csharp-app-container
  echo "Container csharp-app-container stopped and removed."
else
  echo "Container csharp-app-container is not running."
fi
