#!/usr/bin/env bash
set -euo pipefail

kubectl -n default scale deployment/nginx-example-yaml --replicas=0
echo "Nginx is scaled to zero. Run start.sh to start it again."
