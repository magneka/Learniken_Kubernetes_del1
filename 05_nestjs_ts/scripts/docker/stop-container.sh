#!/bin/bash
set -euo pipefail

# Navigate to nestjs_ts directory (scripts are in nestjs_ts/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../.."

# Stop and remove the container
if docker ps -q --filter "name=nestjs-ts-app-container" | grep -q .; then
  docker stop nestjs-ts-app-container
  docker rm nestjs-ts-app-container
  echo "Container nestjs-ts-app-container stopped and removed."
else
  echo "Container nestjs-ts-app-container is not running."
fi
