#!/usr/bin/env bash
# Exit immediately if a command fails or an unset variable is used.
set -euo pipefail

# Use this script's directory so it works from any working directory.
cd "$(dirname "$0")"

# Use NGINX_PORT=18080 when local port 8080 is already in use.
PORT="${NGINX_PORT:-8080}"

# Recreate the example so each start uses the latest local HTML file.
kubectl -n default delete deployment/nginx-example configmap/nginx-example-html --ignore-not-found
kubectl -n default create configmap nginx-example-html --from-file=index.html
kubectl -n default create deployment nginx-example --image=nginx:stable-alpine

# Mount the ConfigMap as Nginx's web directory; no YAML file is needed.
kubectl -n default patch deployment nginx-example --type=strategic -p '{"spec":{"template":{"spec":{"containers":[{"name":"nginx","volumeMounts":[{"name":"html","mountPath":"/usr/share/nginx/html","readOnly":true}]}],"volumes":[{"name":"html","configMap":{"name":"nginx-example-html"}}]}}}}'
kubectl -n default rollout status deployment/nginx-example --timeout=120s

# Keep forwarding in the foreground; Ctrl+C ends forwarding, not the deployment.
echo "Open http://localhost:${PORT}. Keep this terminal open."
echo "Use stop.sh in another terminal to stop Nginx."
kubectl -n default port-forward deployment/nginx-example "${PORT}:80"
