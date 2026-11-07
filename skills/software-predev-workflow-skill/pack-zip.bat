@echo off
setlocal EnableExtensions
cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0pack-zip.ps1"
if errorlevel 1 (
  echo [ERROR] pack failed
  exit /b 1
)

echo Done: software-predev-workflow-skill.zip
exit /b 0
