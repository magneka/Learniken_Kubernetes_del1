#!/bin/bash
set -euo pipefail

# Navigate to rust_app/08_rust_rest/source directory (scripts are in rust_app/08_rust_rest/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../../source"

# Build the Docker image
docker build -t rust-app -f Dockerfile .

# Run the container
docker run -d -p 8088:80 --name rust-app-container rust-app

echo "Container started. Access the app at http://localhost:8088"
