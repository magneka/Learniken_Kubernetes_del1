#!/bin/bash
set -euo pipefail

# Navigate to nestjs_ts directory (scripts are in nestjs_ts/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../.."

echo "Removing from Kubernetes..."
kubectl delete -f kubernetes.yaml --ignore-not-found

echo ""
echo "Remaining resources for app=nestjs-ts-app:"
kubectl get deployment,svc,pods -l app=nestjs-ts-app

echo ""
echo "Teardown complete!"
