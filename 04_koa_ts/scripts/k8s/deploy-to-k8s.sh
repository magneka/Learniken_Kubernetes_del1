#!/bin/bash
set -euo pipefail

# Navigate to koa_ts directory (scripts are in koa_ts/scripts/)
cd "$(cd "$(dirname "$0")" && pwd)/../.."

# Deploy to Kubernetes
echo "Deploying to Kubernetes..."
kubectl apply -f kubernetes.yaml

# Wait for deployment to be ready
echo "Waiting for deployment to be ready..."
kubectl rollout status deployment/learniken-koa-ts-app

# List pods
echo ""
echo "Listing pods..."
kubectl get pods

# Get the service info
echo ""
echo "Getting service info..."
kubectl get svc learniken-koa-ts-app-service

# Port forward to access the service
echo ""
echo "Setting up port forwarding..."
kubectl port-forward svc/learniken-koa-ts-app-service 8083:8083 &
PORTFORWARD_PID=$!

# Wait for port forwarding to start
sleep 2

# Curl to test the service
echo ""
echo "Testing the service with curl..."
curl -v http://localhost:8083

# Clean up port forward
kill $PORTFORWARD_PID 2>/dev/null

echo ""
echo "Deployment complete!"
