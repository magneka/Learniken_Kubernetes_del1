#!/usr/bin/env bash
set -euo pipefail

kubectl -n default delete -f "$(dirname "$0")/nginx.yaml" --ignore-not-found
kubectl -n default delete configmap/nginx-example-yaml-html --ignore-not-found
echo "Nginx example resources removed."
