@echo off
REM Keep environment changes local to this script.
setlocal

REM Delete this example's Deployment and HTML ConfigMap.
kubectl -n default delete deployment/nginx-example configmap/nginx-example-html --ignore-not-found
if errorlevel 1 exit /b 1

REM Also clean up resources left by the earlier YAML-based version, if present.
kubectl -n default delete service/nginx-example --ignore-not-found
if errorlevel 1 exit /b 1
kubectl -n default delete configmap -l app=nginx-example --ignore-not-found
if errorlevel 1 exit /b 1
echo Nginx example resources removed.
