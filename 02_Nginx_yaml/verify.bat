@echo off
setlocal

set "URL=%~1"
if not defined URL set "URL=http://localhost:8081"

curl --fail --silent --show-error --max-time 10 "%URL%" > "%TEMP%\nginx-example-yaml-response.txt"
if errorlevel 1 exit /b 1

findstr /c:"Hello from Nginx on Kubernetes!" "%TEMP%\nginx-example-yaml-response.txt" >nul
if errorlevel 1 (
    echo Verification failed: expected Nginx page content was not found.
    del "%TEMP%\nginx-example-yaml-response.txt" >nul 2>&1
    exit /b 1
)

del "%TEMP%\nginx-example-yaml-response.txt" >nul 2>&1
echo Verification passed: %URL% returned the expected Nginx page.
