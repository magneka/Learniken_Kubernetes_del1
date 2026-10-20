#!/bin/bash
set -euo pipefail

# Navigate to koa_ts directory (scripts are in koa_ts/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../.."

# Stop and remove the container
if docker ps -q --filter "name=koa-ts-app-container" | grep -q .; then
  docker stop koa-ts-app-container
  docker rm koa-ts-app-container
  echo "Container koa-ts-app-container stopped and removed."
else
  echo "Container koa-ts-app-container is not running."
fi
