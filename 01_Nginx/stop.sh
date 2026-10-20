#!/usr/bin/env bash
# Exit on errors rather than reporting a successful stop.
set -euo pipefail

# Stop the pod but keep the Deployment and HTML ConfigMap.
kubectl -n default scale deployment/nginx-example --replicas=0
echo "Nginx is scaled to zero. Run start.sh to start it again."
