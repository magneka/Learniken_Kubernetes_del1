#!/bin/bash
set -euo pipefail

cd "$(cd "$(dirname "$0")" && pwd)/../../source"

docker compose down

echo "Containers stopped."
