#!/bin/bash
set -euo pipefail

# Navigate to express_app directory (scripts are in express_app/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../.."

# Build the Docker image
docker build -t express-app -f Dockerfile .

# Run the container
docker run -d -p 8082:80 --name express-app-container express-app

echo "Container started. Access the app at http://localhost:8082"
