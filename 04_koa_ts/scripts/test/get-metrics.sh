#!/bin/bash
set -euo pipefail

# Navigate to koa_ts directory (scripts are in koa_ts/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../.."

APP_LABEL="app=koa-ts-app"
DEPLOYMENT="learniken-koa-ts-app"
SERVICE="learniken-koa-ts-app-service"

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
kubectl get events --field-selector involvedObject.kind=Pod --sort-by='.lastTimestamp' | grep -i koa-ts-app || true

echo ""
echo "===== Recent logs ====="
kubectl logs -l "$APP_LABEL" --tail=50 --all-containers

echo ""
echo "Done."
