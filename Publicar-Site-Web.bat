@echo off
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\deploy-web-firebase.ps1" %*
if errorlevel 1 (
  echo.
  echo [ERRO] Deploy falhou. Verifique Flutter, firebase login e mensagens acima.
  pause
  exit /b 1
)
pause
