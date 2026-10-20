#!/bin/bash
set -euo pipefail

# Navigate to express_app directory (scripts are in express_app/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../.."

# Stop and remove the container
if docker ps -q --filter "name=express-app-container" | grep -q .; then
  docker stop express-app-container
  docker rm express-app-container
  echo "Container express-app-container stopped and removed."
else
  echo "Container express-app-container is not running."
fi
