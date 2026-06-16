@echo off
REM Sincroniza logos — funciona com duplo-clique ou CMD (sem ExecutionPolicy)
setlocal
cd /d "%~dp0.."
echo.
echo [KiamiCloud] A sincronizar branding/assets ...
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0sync-branding-assets.ps1"
set EXITCODE=%ERRORLEVEL%
if %EXITCODE% NEQ 0 (
  echo.
  echo Falhou com codigo %EXITCODE%.
  pause
  exit /b %EXITCODE%
)
echo.
pause
exit /b 0
