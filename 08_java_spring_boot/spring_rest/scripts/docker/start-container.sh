#!/bin/bash
set -euo pipefail

# Navigate to java_spring_boot/spring_rest/source directory (scripts are in java_spring_boot/spring_rest/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../../source"

# Build the Docker image
docker build -t spring-app -f Dockerfile .

# Run the container
docker run -d -p 8087:80 --name spring-app-container spring-app

echo "Container started. Access the app at http://localhost:8087"
