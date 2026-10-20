#!/bin/bash
set -euo pipefail

# Run wrk load test 
echo ""
echo "Running wrk load test ..."
wrk -t5 -c5 -d20s http://localhost:8082

echo "Done."
