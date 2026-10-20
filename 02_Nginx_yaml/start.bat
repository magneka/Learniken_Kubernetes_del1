@echo off
setlocal

cd /d "%~dp0"
if errorlevel 1 exit /b 1

set "PORT=%NGINX_PORT%"
if not defined PORT set "PORT=8081"

REM Build the HTML ConfigMap from index.html so each start uses the latest page.
kubectl -n default create configmap nginx-example-yaml-html --from-file=index.html --dry-run=client -o yaml | kubectl -n default apply -f -
if errorlevel 1 exit /b 1
kubectl -n default apply -f nginx.yaml
if errorlevel 1 exit /b 1
kubectl -n default rollout restart deployment/nginx-example-yaml
if errorlevel 1 exit /b 1
kubectl -n default rollout status deployment/nginx-example-yaml --timeout=120s
if errorlevel 1 exit /b 1

echo Open http://localhost:%PORT%. Keep this terminal open.
echo Use stop.bat in another terminal to stop Nginx.
kubectl -n default port-forward deployment/nginx-example-yaml %PORT%:80
exit /b %errorlevel%
