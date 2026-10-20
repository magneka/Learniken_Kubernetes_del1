#!/bin/bash
set -euo pipefail

# Navigate to go/go_rest/source directory (scripts are in go/go_rest/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../../source"

APP_LABEL="app=go-app"
DEPLOYMENT="learniken-go-app"
SERVICE="learniken-go-app-service"

echo "===== Deployment status ====="
kubectl get deployment "$DEPLOYMENT" -o wide

echo ""
echo "===== Replica set ====="
kubectl get rs -l "$APP_LABEL" -o wide

echo ""
echo "===== Pods ====="
kubectl get pods -l "$APP_LABEL" -o wide

echo ""
echo "===== Service ====="
kubectl get svc "$SERVICE" -o wide

echo ""
echo "===== Pod resource usage (requires metrics-server) ====="
kubectl top pods -l "$APP_LABEL" 2>&1 || true

echo ""
echo "===== Node resource usage ====="
kubectl top nodes 2>&1 || true

echo ""
echo "===== Pod details (requests/limits, restarts, events) ====="
kubectl describe pods -l "$APP_LABEL"

echo ""
echo "===== Recent events ====="
kubectl get events --field-selector involvedObject.kind=Pod --sort-by='.lastTimestamp' | grep -i go-app || true

echo ""
echo "===== Recent logs ====="
kubectl logs -l "$APP_LABEL" --tail=50 --all-containers

echo ""
echo "Done."
