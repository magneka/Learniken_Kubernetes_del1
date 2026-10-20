@echo off
REM Keep environment changes local to this script.
setlocal

REM Allow a different URL when the port-forward uses another local port.
set "URL=%~1"
if not defined URL set "URL=http://localhost:8080"

REM Fetch the page and fail if curl cannot connect or receives a non-2xx response.
curl --fail --silent --show-error --max-time 10 "%URL%" > "%TEMP%\nginx-example-response.txt"
if errorlevel 1 exit /b 1

REM Confirm that the expected page, rather than an unrelated web server, responded.
findstr /c:"Hello from Nginx on Kubernetes!" "%TEMP%\nginx-example-response.txt" >nul
if errorlevel 1 (
    echo Verification failed: expected Nginx page content was not found.
    del "%TEMP%\nginx-example-response.txt" >nul 2>&1
    exit /b 1
)

REM Remove the temporary response file after a successful check.
del "%TEMP%\nginx-example-response.txt" >nul 2>&1
echo Verification passed: %URL% returned the expected Nginx page.
