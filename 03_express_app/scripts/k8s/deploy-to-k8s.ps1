$ErrorActionPreference = "Stop"

# Navigate to express_app directory (scripts are in express_app/scripts/)
cd (Resolve-Path "$PSScriptRoot/../..")

# Deploy to Kubernetes
Write-Host "Deploying to Kubernetes..."
kubectl apply -f kubernetes.yaml

# Wait for deployment to be ready
Write-Host "Waiting for deployment to be ready..."
kubectl rollout status deployment/learniken-express-app

# List pods
Write-Host ""
Write-Host "Listing pods..."
kubectl get pods

# Get the service info
Write-Host ""
Write-Host "Getting service info..."
kubectl get svc learniken-express-app-service

# Port forward to access the service
Write-Host ""
Write-Host "Setting up port forwarding..."
$portForwardJob = Start-Job -ScriptBlock {
    kubectl port-forward svc/learniken-express-app-service 8082:8082
}

# Wait for port forwarding to start
Start-Sleep -Seconds 2

# Curl to test the service
Write-Host ""
Write-Host "Testing the service with curl..."
try {
    Invoke-WebRequest -Uri "http://localhost:8082" -UseBasicParsing | Select-Object -ExpandProperty Content
}
catch {
    Write-Host $_.Exception.Message
}

# Clean up port forward
Stop-Job $portForwardJob -ErrorAction SilentlyContinue | Out-Null
Remove-Job $portForwardJob -ErrorAction SilentlyContinue | Out-Null

Write-Host ""
Write-Host "Deployment complete!"
