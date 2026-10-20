@echo off
REM Keep environment changes local to this script.
setlocal

REM List this namespace; pass a different namespace as the first argument.
REM Pass "all" to list pods in every namespace.
set "NAMESPACE=%~1"
if not defined NAMESPACE set "NAMESPACE=default"

REM Show the target so you always know which cluster you are looking at.
set "CONTEXT=unknown"
for /f "delims=" %%C in ('kubectl config current-context') do set "CONTEXT=%%C"
echo Cluster context: %CONTEXT%

REM Choose between a single namespace and the whole cluster.
if /i "%NAMESPACE%"=="all" (
    echo Namespace:       all namespaces
    set "SCOPE=--all-namespaces"
) else (
    echo Namespace:       %NAMESPACE%
    set "SCOPE=-n %NAMESPACE%"
)
echo.

REM The AGE column shows how long each pod has been running.
REM Oldest pods are listed last because they sort by creation time.
kubectl get pods %SCOPE% -o wide --sort-by=.metadata.creationTimestamp
if errorlevel 1 exit /b 1

echo.
echo AGE shows how long the pod has existed. RESTARTS above 0 means the
echo container was restarted, so it may be running for less time than AGE.
