#!/bin/bash
set -euo pipefail

# Navigate to rust_app/08_rust_rest/source directory (scripts are in rust_app/08_rust_rest/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../../source"

# Stop and remove the container
if docker ps -q --filter "name=rust-app-container" | grep -q .; then
  docker stop rust-app-container
  docker rm rust-app-container
  echo "Container rust-app-container stopped and removed."
else
  echo "Container rust-app-container is not running."
fi
