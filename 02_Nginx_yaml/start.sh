#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")"
PORT="${NGINX_PORT:-8081}"

# Build the HTML ConfigMap from index.html so each start uses the latest page.
kubectl -n default create configmap nginx-example-yaml-html --from-file=index.html --dry-run=client -o yaml | kubectl -n default apply -f -
kubectl -n default apply -f nginx.yaml
kubectl -n default rollout restart deployment/nginx-example-yaml
kubectl -n default rollout status deployment/nginx-example-yaml --timeout=120s

echo "Open http://localhost:${PORT}. Keep this terminal open."
echo "Use stop.sh in another terminal to stop Nginx."
kubectl -n default port-forward deployment/nginx-example-yaml "${PORT}:80"
