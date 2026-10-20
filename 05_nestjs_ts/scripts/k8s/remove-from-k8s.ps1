$ErrorActionPreference = "Stop"

# Navigate to nestjs_ts directory (scripts are in nestjs_ts/scripts/)
cd (Resolve-Path "$PSScriptRoot/../..")

Write-Host "Removing from Kubernetes..."
kubectl delete -f kubernetes.yaml --ignore-not-found

Write-Host ""
Write-Host "Remaining resources for app=nestjs-ts-app:"
kubectl get deployment,svc,pods -l app=nestjs-ts-app

Write-Host ""
Write-Host "Teardown complete!"
