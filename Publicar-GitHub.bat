@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

:INICIO
cls
echo.
echo ========================================
echo   KiamiCloud — Publicar no GitHub
echo ========================================
echo   Push para master dispara deploy web
echo   (GitHub Actions -^> Firebase Hosting)
echo ========================================
echo.

where git >nul 2>&1
if errorlevel 1 (
  echo [ERRO] Git nao encontrado. Instale https://git-scm.com/
  pause
  exit /b 1
)

git rev-parse --is-inside-work-tree >nul 2>&1
if errorlevel 1 (
  echo [ERRO] Esta pasta nao e um repositorio Git.
  pause
  exit /b 1
)

git remote get-url origin >nul 2>&1
if errorlevel 1 (
  echo [ERRO] Remote "origin" nao configurado.
  pause
  exit /b 1
)

for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set BRANCH=%%b
for /f "delims=" %%u in ('git remote get-url origin 2^>nul') do set REMOTE_URL=%%u

set HAS_CHANGES=
for /f "delims=" %%i in ('git status --porcelain 2^>nul') do set HAS_CHANGES=1

set AHEAD=0
for /f %%a in ('git rev-list --count origin/%BRANCH%..HEAD 2^>nul') do set AHEAD=%%a
if not defined AHEAD set AHEAD=0

echo Branch:  %BRANCH%
echo Remote:  %REMOTE_URL%
echo.
echo [Estado]
git status -sb
echo.

if defined HAS_CHANGES (
  echo Ha alteracoes locais por commitar.
) else (
  echo Sem alteracoes locais por commitar.
)

if not "!AHEAD!"=="0" (
  if not "!AHEAD!"=="" (
    echo Ha !AHEAD! commit^(s^) por enviar ao GitHub.
  )
)
echo.

echo O que pretende fazer?
echo   1 - Apenas ver estado e sair
echo   2 - Commit (gravar alteracoes localmente)
echo   3 - Push (enviar commits para GitHub)
echo   4 - Commit + Push (gravar e publicar)
echo   5 - Cancelar
echo.
set /p OPCAO=Escolha [1-5]: 

if "%OPCAO%"=="1" goto SAIR
if "%OPCAO%"=="2" goto FAZER_COMMIT
if "%OPCAO%"=="3" goto FAZER_PUSH
if "%OPCAO%"=="4" goto FAZER_COMMIT_PUSH
if "%OPCAO%"=="5" goto CANCELAR

echo [ERRO] Opcao invalida.
timeout /t 2 >nul
goto INICIO

:FAZER_COMMIT
call :EXEC_COMMIT
if errorlevel 1 goto INICIO
echo.
set /p MAIS=Deseja fazer push agora? [S/N]: 
if /i "!MAIS!"=="S" goto FAZER_PUSH
goto PERGUNTAR_VOLTAR

:FAZER_COMMIT_PUSH
if defined HAS_CHANGES (
  call :EXEC_COMMIT
  if errorlevel 1 goto INICIO
) else (
  echo.
  echo Sem alteracoes novas — a enviar commits existentes.
)
goto FAZER_PUSH

:FAZER_PUSH
for /f %%a in ('git rev-list --count origin/%BRANCH%..HEAD 2^>nul') do set AHEAD=%%a
if not defined AHEAD set AHEAD=0
if "%AHEAD%"=="0" (
  echo.
  echo [AVISO] Nao ha commits por enviar ao GitHub.
  goto PERGUNTAR_VOLTAR
)

if defined HAS_CHANGES (
  echo.
  echo [AVISO] Ha alteracoes locais ainda por commitar.
  echo O push envia apenas commits ja gravados.
  set /p IGNORAR=Continuar com push? [S/N]: 
  if /i not "!IGNORAR!"=="S" goto PERGUNTAR_VOLTAR
)

if /i not "%BRANCH%"=="master" (
  echo.
  echo [AVISO] Branch actual: %BRANCH%
  echo O deploy web automatico so corre em "master".
  set /p CONFIRM_BRANCH=Continuar com push para esta branch? [S/N]: 
  if /i not "!CONFIRM_BRANCH!"=="S" goto PERGUNTAR_VOLTAR
)

echo.
echo Vai enviar commits para:
echo   origin/%BRANCH%
echo   %REMOTE_URL%
echo.
set /p CONFIRM_PUSH=Confirma o push? [S/N]: 
if /i not "!CONFIRM_PUSH!"=="S" (
  echo Push cancelado.
  goto PERGUNTAR_VOLTAR
)

echo.
echo [Git] A enviar...
git push -u origin %BRANCH%
if errorlevel 1 (
  echo.
  echo [ERRO] git push falhou. Verifique credenciais e ligacao.
  pause
  goto PERGUNTAR_VOLTAR
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
goto PERGUNTAR_VOLTAR

:EXEC_COMMIT
if not defined HAS_CHANGES (
  echo.
  echo [AVISO] Nao ha alteracoes para commit.
  exit /b 1
)

echo.
echo Ficheiros alterados:
git status --short
echo.
set /p ADD_ALL=Incluir TODAS as alteracoes no commit? [S/N]: 
if /i not "!ADD_ALL!"=="S" (
  echo.
  echo Para escolher ficheiros manualmente:
  echo   git add ficheiro...
  echo Depois execute este script novamente e escolha Commit ou Commit+Push.
  exit /b 1
)

set /p COMMIT_MSG=Mensagem do commit: 
if "!COMMIT_MSG!"=="" (
  echo [ERRO] Mensagem de commit obrigatoria.
  exit /b 1
)

echo.
echo Resumo do commit:
echo   Branch:  %BRANCH%
echo   Mensagem: !COMMIT_MSG!
echo.
set /p CONFIRM_COMMIT=Confirma o commit? [S/N]: 
if /i not "!CONFIRM_COMMIT!"=="S" (
  echo Commit cancelado.
  exit /b 1
)

echo.
echo [Git] A adicionar alteracoes...
git add -A
if errorlevel 1 (
  echo [ERRO] git add falhou.
  exit /b 1
)

echo [Git] A criar commit...
git commit -m "!COMMIT_MSG!"
if errorlevel 1 (
  echo [ERRO] git commit falhou.
  exit /b 1
)

echo [OK] Commit criado.
set HAS_CHANGES=
for /f %%a in ('git rev-list --count origin/%BRANCH%..HEAD 2^>nul') do set AHEAD=%%a
if not defined AHEAD set AHEAD=0
exit /b 0

:PERGUNTAR_VOLTAR
echo.
set /p VOLTAR=Voltar ao menu principal? [S/N]: 
if /i "!VOLTAR!"=="S" goto INICIO
goto SAIR

:CANCELAR
echo Operacao cancelada.
goto SAIR

:SAIR
echo.
pause
exit /b 0
