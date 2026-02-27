@echo off
:: Batch script to run the RastCloud setup via PowerShell as Admin

:: Check for admin rights
net session >nul 2>&1
if %errorLevel% neq 0 (
    echo Requesting administrative privileges...
    powershell -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

:: Run the installation command
powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (irm aka.rastcloud.com/setup)"

pause