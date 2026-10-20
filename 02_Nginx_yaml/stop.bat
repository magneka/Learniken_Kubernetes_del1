@echo off
setlocal

kubectl -n default scale deployment/nginx-example-yaml --replicas=0
if errorlevel 1 exit /b 1
echo Nginx is scaled to zero. Run start.bat to start it again.
