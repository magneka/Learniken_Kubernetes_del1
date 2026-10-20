$ErrorActionPreference = "Stop"

# Navigate to java_spring_boot/spring_rest/source directory (scripts are in java_spring_boot/spring_rest/scripts/)
cd (Resolve-Path "$PSScriptRoot/../../source")

# Deploy to Kubernetes
Write-Host "Deploying to Kubernetes..."
kubectl apply -f kubernetes.yaml

# Wait for deployment to be ready
Write-Host "Waiting for deployment to be ready..."
kubectl rollout status deployment/learniken-spring-app

# List pods
Write-Host ""
Write-Host "Listing pods..."
kubectl get pods

# Get the service info
Write-Host ""
Write-Host "Getting service info..."
kubectl get svc learniken-spring-app-service

# Port forward to access the service
Write-Host ""
Write-Host "Setting up port forwarding..."
$portForwardJob = Start-Job -ScriptBlock {
    kubectl port-forward svc/learniken-spring-app-service 8087:8087
}

# Wait for port forwarding to start
Start-Sleep -Seconds 2

# Curl to test the service
Write-Host ""
Write-Host "Testing the service with curl..."
try {
    Invoke-WebRequest -Uri "http://localhost:8087" -UseBasicParsing | Select-Object -ExpandProperty Content
}
catch {
    Write-Host $_.Exception.Message
}

# Clean up port forward
Stop-Job $portForwardJob -ErrorAction SilentlyContinue | Out-Null
Remove-Job $portForwardJob -ErrorAction SilentlyContinue | Out-Null

Write-Host ""
Write-Host "Deployment complete!"
