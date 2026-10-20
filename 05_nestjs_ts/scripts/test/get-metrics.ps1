$ErrorActionPreference = "Continue"

# Navigate to nestjs_ts directory (scripts are in nestjs_ts/scripts/)
cd (Resolve-Path "$PSScriptRoot/../..")

$AppLabel = "app=nestjs-ts-app"
$Deployment = "learniken-nestjs-ts-app"
$Service = "learniken-nestjs-ts-app-service"

Write-Host "===== Deployment status ====="
kubectl get deployment $Deployment -o wide

Write-Host ""
Write-Host "===== Replica set ====="
kubectl get rs -l $AppLabel -o wide

Write-Host ""
Write-Host "===== Pods ====="
kubectl get pods -l $AppLabel -o wide

Write-Host ""
Write-Host "===== Service ====="
kubectl get svc $Service -o wide

Write-Host ""
Write-Host "===== Pod resource usage (requires metrics-server) ====="
kubectl top pods -l $AppLabel

Write-Host ""
Write-Host "===== Node resource usage ====="
kubectl top nodes

Write-Host ""
Write-Host "===== Pod details (requests/limits, restarts, events) ====="
kubectl describe pods -l $AppLabel

Write-Host ""
Write-Host "===== Recent events ====="
kubectl get events --field-selector involvedObject.kind=Pod --sort-by=".lastTimestamp" |
    Select-String -Pattern "nestjs-ts-app"

Write-Host ""
Write-Host "===== Recent logs ====="
kubectl logs -l $AppLabel --tail=50 --all-containers

Write-Host ""
Write-Host "Done."
