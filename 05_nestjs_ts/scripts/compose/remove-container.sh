#!/bin/bash
set -euo pipefail

cd "$(cd "$(dirname "$0")" && pwd)/../.."

docker compose down -v --rmi all

echo "Containers, networks, volumes, and images removed."
