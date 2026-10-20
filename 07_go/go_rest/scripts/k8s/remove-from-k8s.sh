#!/bin/bash
set -euo pipefail

# Navigate to go/go_rest/source directory (scripts are in go/go_rest/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../../source"

echo "Removing from Kubernetes..."
kubectl delete -f kubernetes.yaml --ignore-not-found

echo ""
echo "Remaining resources for app=go-app:"
kubectl get deployment,svc,pods -l app=go-app

echo ""
echo "Teardown complete!"
