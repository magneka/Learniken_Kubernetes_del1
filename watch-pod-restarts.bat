@echo off
REM Keep environment changes local to this script.
setlocal

REM Watch this namespace; pass a different namespace as the first argument.
set "NAMESPACE=%~1"
if not defined NAMESPACE set "NAMESPACE=default"

REM Pass "watch" as the second argument to refresh every 5 seconds until Ctrl+C.
set "MODE=%~2"
if not defined MODE set "MODE=once"

:show
if /i "%MODE%"=="watch" cls

set "CONTEXT=unknown"
for /f "delims=" %%C in ('kubectl config current-context') do set "CONTEXT=%%C"
echo Cluster context: %CONTEXT%
echo Namespace:       %NAMESPACE%
echo Checked at:      %TIME:~0,8%
echo.

REM RESTARTS counts how many times the container was restarted.
REM The LAST-* columns describe the most recent restart, and stay empty
REM until a restart has actually happened.
kubectl -n %NAMESPACE% get pods -o custom-columns="NAME:.metadata.name,READY:.status.containerStatuses[*].ready,RESTARTS:.status.containerStatuses[*].restartCount,LAST-REASON:.status.containerStatuses[*].lastState.terminated.reason,LAST-EXIT:.status.containerStatuses[*].lastState.terminated.exitCode,LAST-RESTART:.status.containerStatuses[*].lastState.terminated.finishedAt,POD-AGE:.metadata.creationTimestamp"
if errorlevel 1 exit /b 1

echo.
echo Recent liveness and restart events:

REM Field selectors cannot match message text, so filter the output instead.
set "FOUND="
for /f "delims=" %%E in ('kubectl -n %NAMESPACE% get events --field-selector involvedObject.kind^=Pod --sort-by^=.lastTimestamp 2^>nul ^| findstr /i "liveness readiness restart BackOff"') do (
    echo   %%E
    set "FOUND=1"
)
if not defined FOUND echo   (none yet - no probe failures or restarts recorded)

echo.
echo Exit code 137 means Kubernetes killed the container after the
echo liveness probe failed. LAST-RESTART is when the old container died.

if /i "%MODE%"=="watch" (
    timeout /t 5 /nobreak >nul
    goto :show
)
