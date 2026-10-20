@echo off
REM Keep environment changes local to this script.
setlocal

REM Use the script directory even when launched from another directory or drive.
cd /d "%~dp0"
if errorlevel 1 exit /b 1

REM Use NGINX_PORT=18080 when local port 8080 is already in use.
set "PORT=%NGINX_PORT%"
if not defined PORT set "PORT=8080"

REM Recreate the example so each start uses the latest local HTML file.
kubectl -n default delete deployment/nginx-example configmap/nginx-example-html --ignore-not-found
if errorlevel 1 exit /b 1
kubectl -n default create configmap nginx-example-html --from-file=index.html
if errorlevel 1 exit /b 1
kubectl -n default create deployment nginx-example --image=nginx:stable-alpine
if errorlevel 1 exit /b 1

REM Mount the ConfigMap as Nginx's web directory; escape JSON quotes for Windows.
kubectl -n default patch deployment nginx-example --type=strategic -p "{\"spec\":{\"template\":{\"spec\":{\"containers\":[{\"name\":\"nginx\",\"volumeMounts\":[{\"name\":\"html\",\"mountPath\":\"/usr/share/nginx/html\",\"readOnly\":true}]}],\"volumes\":[{\"name\":\"html\",\"configMap\":{\"name\":\"nginx-example-html\"}}]}}}}"
if errorlevel 1 exit /b 1
kubectl -n default rollout status deployment/nginx-example --timeout=120s
if errorlevel 1 exit /b 1

REM Run in the foreground; Ctrl+C ends forwarding but leaves Nginx running.
echo Open http://localhost:%PORT%. Keep this terminal open.
echo Use stop.bat in another terminal to stop Nginx.
kubectl -n default port-forward deployment/nginx-example %PORT%:80
exit /b %errorlevel%
