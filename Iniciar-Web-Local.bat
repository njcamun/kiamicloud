@echo off
setlocal
cd /d "%~dp0"

echo [KiamiCloud] A preparar ambiente web...
call dart run tool/sync_branding.dart

echo.
echo [KiamiCloud] A iniciar Flutter Web no Chrome (producao)...
echo API: https://kiamicloud-api.kiamicloud.workers.dev
echo.

cd apps\cloud\web
call flutter pub get
if errorlevel 1 goto :fail
call flutter run -d chrome --web-port=8080 --dart-define=KIAMI_ENV=production --dart-define=KIAMI_API_BASE_URL=https://kiamicloud-api.kiamicloud.workers.dev
if errorlevel 1 goto :fail
goto :end

:fail
echo.
echo [ERRO] Falha ao iniciar a app web. Verifique mensagens acima.
pause
exit /b 1

:end

pause
