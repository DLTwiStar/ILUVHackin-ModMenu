@echo off
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install.ps1" -Target Plutonium
if errorlevel 1 echo Installation failed. Read the error above.
pause
