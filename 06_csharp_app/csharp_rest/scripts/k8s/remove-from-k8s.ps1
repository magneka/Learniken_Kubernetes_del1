$ErrorActionPreference = "Stop"

# Navigate to csharp_app/csharp_rest/source directory (scripts are in csharp_app/csharp_rest/scripts/)
cd (Resolve-Path "$PSScriptRoot/../../source")

Write-Host "Removing from Kubernetes..."
kubectl delete -f kubernetes.yaml --ignore-not-found

Write-Host ""
Write-Host "Remaining resources for app=csharp-app:"
kubectl get deployment,svc,pods -l app=csharp-app

Write-Host ""
Write-Host "Teardown complete!"
