$ErrorActionPreference = "Stop"

# Navigate to koa_ts directory (scripts are in koa_ts/scripts/)
cd (Resolve-Path "$PSScriptRoot/../..")

Write-Host "Removing from Kubernetes..."
kubectl delete -f kubernetes.yaml --ignore-not-found

Write-Host ""
Write-Host "Remaining resources for app=koa-ts-app:"
kubectl get deployment,svc,pods -l app=koa-ts-app

Write-Host ""
Write-Host "Teardown complete!"
