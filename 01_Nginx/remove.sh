#!/usr/bin/env bash
# Exit on errors rather than reporting a successful removal.
set -euo pipefail

# Delete this example's Deployment and HTML ConfigMap.
kubectl -n default delete deployment/nginx-example configmap/nginx-example-html --ignore-not-found

# Also clean up resources left by the earlier YAML-based version, if present.
kubectl -n default delete service/nginx-example --ignore-not-found
kubectl -n default delete configmap -l app=nginx-example --ignore-not-found
echo "Nginx example resources removed."
