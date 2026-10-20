#!/bin/bash
set -euo pipefail

# Navigate to java_spring_boot/spring_rest/source directory (scripts are in java_spring_boot/spring_rest/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../../source"

echo "Removing from Kubernetes..."
kubectl delete -f kubernetes.yaml --ignore-not-found

echo ""
echo "Remaining resources for app=spring-app:"
kubectl get deployment,svc,pods -l app=spring-app

echo ""
echo "Teardown complete!"
