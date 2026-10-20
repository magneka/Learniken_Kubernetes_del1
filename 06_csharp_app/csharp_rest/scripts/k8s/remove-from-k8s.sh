#!/bin/bash
set -euo pipefail

# Navigate to csharp_app/csharp_rest/source directory (scripts are in csharp_app/csharp_rest/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../../source"

echo "Removing from Kubernetes..."
kubectl delete -f kubernetes.yaml --ignore-not-found

echo ""
echo "Remaining resources for app=csharp-app:"
kubectl get deployment,svc,pods -l app=csharp-app

echo ""
echo "Teardown complete!"
