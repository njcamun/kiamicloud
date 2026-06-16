@echo off
setlocal
cd /d "%~dp0..\tools\api-manager"

where node >nul 2>&1
if errorlevel 1 (
  echo [ERRO] Node.js nao encontrado. Instale https://nodejs.org/
  pause
  exit /b 1
)

if not exist node_modules (
  echo [KiamiCloud] A instalar dependencias da consola API...
  call npm install
  if errorlevel 1 (
    echo [ERRO] npm install falhou.
    pause
    exit /b 1
  )
)

echo.
echo ========================================
echo   KiamiCloud — Consola API (GUI)
echo ========================================
echo   Abrir: http://127.0.0.1:3847
echo   API:   porta 8787 (ligar/parar na GUI)
echo ========================================
echo.

start "" "http://127.0.0.1:3847"
call npm start

echo.
pause
