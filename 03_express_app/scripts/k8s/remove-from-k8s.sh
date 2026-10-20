#!/bin/bash
set -euo pipefail

# Navigate to express_app directory (scripts are in express_app/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../.."

echo "Removing from Kubernetes..."
kubectl delete -f kubernetes.yaml --ignore-not-found

echo ""
echo "Remaining resources for app=express-app:"
kubectl get deployment,svc,pods -l app=express-app

echo ""
echo "Teardown complete!"
