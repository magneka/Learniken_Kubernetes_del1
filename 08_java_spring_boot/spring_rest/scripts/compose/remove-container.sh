#!/bin/bash
set -euo pipefail

cd "$(cd "$(dirname "$0")" && pwd)/../../source"

docker compose down -v --rmi all

echo "Containers, networks, volumes, and images removed."
