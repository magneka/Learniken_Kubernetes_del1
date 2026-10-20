$ErrorActionPreference = "Stop"

# Navigate to go/go_rest/source directory (scripts are in go/go_rest/scripts/)
cd (Resolve-Path "$PSScriptRoot/../../source")

Write-Host "Removing from Kubernetes..."
kubectl delete -f kubernetes.yaml --ignore-not-found

Write-Host ""
Write-Host "Remaining resources for app=go-app:"
kubectl get deployment,svc,pods -l app=go-app

Write-Host ""
Write-Host "Teardown complete!"
