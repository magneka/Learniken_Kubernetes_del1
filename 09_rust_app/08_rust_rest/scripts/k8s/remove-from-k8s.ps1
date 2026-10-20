$ErrorActionPreference = "Stop"

# Navigate to rust_app/08_rust_rest/source directory (scripts are in rust_app/08_rust_rest/scripts/)
cd (Resolve-Path "$PSScriptRoot/../../source")

Write-Host "Removing from Kubernetes..."
kubectl delete -f kubernetes.yaml --ignore-not-found

Write-Host ""
Write-Host "Remaining resources for app=rust-app:"
kubectl get deployment,svc,pods -l app=rust-app

Write-Host ""
Write-Host "Teardown complete!"
