#!/bin/bash
set -euo pipefail

# Navigate to koa_ts directory (scripts are in koa_ts/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../.."

echo "Removing from Kubernetes..."
kubectl delete -f kubernetes.yaml --ignore-not-found

echo ""
echo "Remaining resources for app=koa-ts-app:"
kubectl get deployment,svc,pods -l app=koa-ts-app

echo ""
echo "Teardown complete!"
