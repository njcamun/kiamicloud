@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

echo.
echo ========================================
echo   KiamiCloud — Publicar no GitHub
echo ========================================
echo   Push para master dispara o deploy web
echo   (GitHub Actions -^> Firebase Hosting)
echo ========================================
echo.

where git >nul 2>&1
if errorlevel 1 (
  echo [ERRO] Git nao encontrado. Instale https://git-scm.com/
  pause
  exit /b 1
)

for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set BRANCH=%%b
if not "%BRANCH%"=="master" (
  echo [AVISO] Branch actual: %BRANCH% ^(esperado: master^)
  set /p CONFIRM=Continuar mesmo assim? [S/N]: 
  if /i not "!CONFIRM!"=="S" exit /b 0
)

git remote get-url origin >nul 2>&1
if errorlevel 1 (
  echo [ERRO] Remote "origin" nao configurado.
  pause
  exit /b 1
)

echo [Git] Estado actual:
git status -sb
echo.

set NEED_COMMIT=
for /f "delims=" %%i in ('git status --porcelain 2^>nul') do set NEED_COMMIT=1

if defined NEED_COMMIT (
  if "%~1"=="" (
    set /p COMMIT_MSG=Mensagem do commit: 
    if "!COMMIT_MSG!"=="" (
      echo [ERRO] Mensagem de commit obrigatoria.
      pause
      exit /b 1
    )
  ) else (
    set "COMMIT_MSG=%*"
  )

  echo.
  echo [Git] A adicionar alteracoes...
  git add -A
  if errorlevel 1 (
    echo [ERRO] git add falhou.
    pause
    exit /b 1
  )

  echo [Git] A criar commit...
  git commit -m "!COMMIT_MSG!"
  if errorlevel 1 (
    echo [ERRO] git commit falhou.
    pause
    exit /b 1
  )
) else (
  echo [Git] Sem alteracoes locais para commit.
)

for /f "delims=" %%u in ('git remote get-url origin 2^>nul') do set REMOTE_URL=%%u

echo.
echo [Git] A enviar para origin/%BRANCH%...
echo        %REMOTE_URL%
echo.
git push -u origin %BRANCH%
if errorlevel 1 (
  echo.
  echo [ERRO] git push falhou. Verifique credenciais e ligacao.
  pause
  exit /b 1
)

echo.
echo ========================================
echo   Publicado com sucesso
echo ========================================
if /i "%BRANCH%"=="master" (
  echo   Deploy web: GitHub Actions em curso
  echo   Ver: https://github.com/njcamun/kiamicloud/actions
)
echo.
pause
exit /b 0
