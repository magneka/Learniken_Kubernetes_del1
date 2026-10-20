$ErrorActionPreference = "Stop"

# Navigate to java_spring_boot/spring_rest/source directory (scripts are in java_spring_boot/spring_rest/scripts/)
cd (Resolve-Path "$PSScriptRoot/../../source")

Write-Host "Removing from Kubernetes..."
kubectl delete -f kubernetes.yaml --ignore-not-found

Write-Host ""
Write-Host "Remaining resources for app=spring-app:"
kubectl get deployment,svc,pods -l app=spring-app

Write-Host ""
Write-Host "Teardown complete!"
