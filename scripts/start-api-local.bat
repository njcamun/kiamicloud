@echo off
setlocal
cd /d "%~dp0..\workers"

where node >nul 2>&1
if errorlevel 1 (
  echo [ERRO] Node.js nao encontrado. Instale https://nodejs.org/
  pause
  exit /b 1
)

if not exist node_modules (
  echo [KiamiCloud] A instalar dependencias em workers\...
  call npm install
  if errorlevel 1 (
    echo [ERRO] npm install falhou.
    pause
    exit /b 1
  )
)

echo.

echo [KiamiCloud] A aplicar migracoes D1 locais...
call npm run db:migrate:local
if errorlevel 1 (
  echo [AVISO] Migracoes falharam — verifique a consola.
)

echo.
echo ========================================
echo   KiamiCloud — API local (wrangler dev)
echo ========================================
echo   PC:        http://127.0.0.1:8787
echo   Telemovel: http://SEU_IP_LAN:8787
echo   Teste:     http://127.0.0.1:8787/health/ping
echo.
echo   Para GUI (ligar/parar/reiniciar): Iniciar-API-GUI.bat
echo   Ctrl+C para parar
echo ========================================
echo.

call npm run dev

echo.
pause
