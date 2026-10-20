$ErrorActionPreference = "Stop"

# Navigate to express_app directory (scripts are in express_app/scripts/)
cd (Resolve-Path "$PSScriptRoot/../..")

Write-Host "Removing from Kubernetes..."
kubectl delete -f kubernetes.yaml --ignore-not-found

Write-Host ""
Write-Host "Remaining resources for app=express-app:"
kubectl get deployment,svc,pods -l app=express-app

Write-Host ""
Write-Host "Teardown complete!"
