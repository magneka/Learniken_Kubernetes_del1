@echo off
REM Keep environment changes local to this script.
setlocal

REM Clean this namespace; pass a different namespace as the first argument.
set "NAMESPACE=%~1"
if not defined NAMESPACE set "NAMESPACE=default"

REM Show the target so you never delete pods in the wrong cluster by accident.
set "CONTEXT=unknown"
for /f "delims=" %%C in ('kubectl config current-context') do set "CONTEXT=%%C"
echo Cluster context: %CONTEXT%
echo Namespace:       %NAMESPACE%
echo.

REM List the pods that are about to be removed.
kubectl -n %NAMESPACE% get pods
if errorlevel 1 exit /b 1

REM Ask before deleting, because this cannot be undone. FORCE=1 skips the question.
if "%FORCE%"=="1" goto :delete
set "ANSWER="
set /p "ANSWER=Permanently delete these pods? Type yes to continue: "
if /i not "%ANSWER%"=="yes" (
    echo Cancelled. Nothing was deleted.
    exit /b 1
)

:delete
REM Delete the controllers first; otherwise they immediately recreate their pods.
kubectl -n %NAMESPACE% delete deployments,statefulsets,daemonsets,replicasets,jobs,cronjobs --all --ignore-not-found
if errorlevel 1 exit /b 1

REM Delete any remaining pods that were created without a controller.
kubectl -n %NAMESPACE% delete pods --all --ignore-not-found
if errorlevel 1 exit /b 1

echo All pods removed from namespace %NAMESPACE%. Nothing will restart.
