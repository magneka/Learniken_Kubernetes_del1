#!/bin/bash
set -euo pipefail

# Navigate to rust_app/08_rust_rest/source directory (scripts are in rust_app/08_rust_rest/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../../source"

echo "Removing from Kubernetes..."
kubectl delete -f kubernetes.yaml --ignore-not-found

echo ""
echo "Remaining resources for app=rust-app:"
kubectl get deployment,svc,pods -l app=rust-app

echo ""
echo "Teardown complete!"
