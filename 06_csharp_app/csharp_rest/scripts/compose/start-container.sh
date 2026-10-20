#!/bin/bash
set -euo pipefail

cd "$(cd "$(dirname "$0")" && pwd)/../../source"

docker compose up -d --build

echo "Containers started. Access the app at http://localhost:8085"
