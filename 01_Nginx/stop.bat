@echo off
REM Keep environment changes local to this script.
setlocal

REM Stop the pod but keep the Deployment and HTML ConfigMap.
kubectl -n default scale deployment/nginx-example --replicas=0
if errorlevel 1 exit /b 1
echo Nginx is scaled to zero. Run start.bat to start it again.
