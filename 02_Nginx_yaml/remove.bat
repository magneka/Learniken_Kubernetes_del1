@echo off
setlocal

kubectl -n default delete -f "%~dp0nginx.yaml" --ignore-not-found
if errorlevel 1 exit /b 1
kubectl -n default delete configmap/nginx-example-yaml-html --ignore-not-found
if errorlevel 1 exit /b 1
echo Nginx example resources removed.
