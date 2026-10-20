#!/bin/bash
set -euo pipefail

# Navigate to koa_ts directory (scripts are in koa_ts/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../.."

# Build the Docker image
docker build -t koa-ts-app -f Dockerfile .

# Run the container
docker run -d -p 8083:80 --name koa-ts-app-container koa-ts-app

echo "Container started. Access the app at http://localhost:8083"
