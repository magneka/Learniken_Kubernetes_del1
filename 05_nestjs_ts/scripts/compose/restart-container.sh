#!/bin/bash
set -euo pipefail

cd "$(cd "$(dirname "$0")" && pwd)"

./stop-container.sh
./start-container.sh

echo "Containers restarted."
