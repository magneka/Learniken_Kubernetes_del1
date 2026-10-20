#!/bin/bash
set -euo pipefail

# Navigate to java_spring_boot/spring_rest/source directory (scripts are in java_spring_boot/spring_rest/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../../source"

# Stop and remove the container
if docker ps -q --filter "name=spring-app-container" | grep -q .; then
  docker stop spring-app-container
  docker rm spring-app-container
  echo "Container spring-app-container stopped and removed."
else
  echo "Container spring-app-container is not running."
fi
