@echo off
setlocal EnableDelayedExpansion
cd /d "%~dp0"

set "API_BETA_URL=https://kiamicloud-api-beta.kiamicloud.workers.dev"
set "GITHUB_ACTIONS_URL=https://github.com/njcamun/kiamicloud/actions"
set "GITHUB_REPO_SUGERIDO=https://github.com/njcamun/kiamicloud.git"

:MAIN
cls
call :DETECT_STATE
call :SHOW_HEADER
call :SHOW_DIAGNOSTICO
call :SHOW_MENU
set /p OPCAO=Escolha: 

if /i "%OPCAO%"=="A" goto ASSISTENTE_INICIAL
if /i "%OPCAO%"=="W" goto DEPLOY_WEB_FIREBASE
if /i "%OPCAO%"=="B" goto MENU_GIT
if /i "%OPCAO%"=="C" goto DEPLOY_API_BETA
if /i "%OPCAO%"=="D" goto MIGRAR_D1
if /i "%OPCAO%"=="E" goto SMOKE_TEST
if /i "%OPCAO%"=="F" goto PREPARAR_DEPS
if /i "%OPCAO%"=="G" goto BUILD_MOBILE
if /i "%OPCAO%"=="H" goto BUILD_WEB_LOCAL
if /i "%OPCAO%"=="I" goto PUBLICACAO_COMPLETA
if /i "%OPCAO%"=="J" goto CHECKLIST
if /i "%OPCAO%"=="0" goto SAIR

echo [ERRO] Opcao invalida.
timeout /t 2 >nul
goto MAIN

:SHOW_HEADER
echo.
echo ============================================================
echo   KiamiCloud — Publicacao completa
echo ============================================================
echo   GitHub ^(master^) -^> deploy web automatico ^(Firebase^)
echo   [W] Publicar site — build + Firebase directo ^(recomendado^)
echo   API beta -^> Cloudflare Workers + D1 + R2
echo ============================================================
echo.
exit /b 0

:SHOW_DIAGNOSTICO
echo [Diagnostico]
if "%HAS_GIT%"=="0" (
  echo   Git .............. NAO INSTALADO
) else if "%IS_REPO%"=="0" (
  echo   Git .............. instalado, repositorio NAO inicializado
) else if "%HAS_REMOTE%"=="0" (
  echo   Git .............. repo local OK, sem remote GitHub
) else if "%HAS_COMMITS%"=="0" (
  echo   Git .............. remote OK, sem commits ainda
) else (
  echo   Git .............. OK ^(%BRANCH% -^> %REMOTE_URL%^)
  if defined HAS_CHANGES echo                    alteracoes locais por commitar
  if not "%AHEAD%"=="0" echo                    %AHEAD% commit^(s^) por enviar
)
if "%HAS_NODE%"=="0" (echo   Node.js .......... NAO ENCONTRADO) else (echo   Node.js .......... OK)
if "%HAS_FLUTTER%"=="0" (echo   Flutter .......... NAO ENCONTRADO) else (echo   Flutter .......... OK)
if "%HAS_WORKERS_NM%"=="0" (echo   Workers deps ..... falta npm install) else (echo   Workers deps ..... OK)
echo   API beta URL ..... %API_BETA_URL%
echo.
if "%NEEDS_SETUP%"=="1" (
  echo   ^>^> Primeira configuracao detectada — use opcao [A]
  echo.
)
exit /b 0

:SHOW_MENU
echo O que pretende fazer?
echo.
echo   [A] Assistente inicial ^(primeira vez: Git + orientacao^)
echo   [W] Publicar site web ^(Firebase — build + deploy real^)
echo   [B] GitHub — commit / push ^(opcional, para CI^)
echo   [C] API — deploy beta ^(Workers + CORS R2^)
echo   [D] API — aplicar migracoes D1 ^(remoto^)
echo   [E] API — smoke test
echo   [F] App — preparar dependencias ^(flutter pub get^)
echo   [G] App — build APK mobile beta
echo   [H] App — build web local ^(sem deploy^)
echo   [I] Publicacao completa ^(site + API + Git opcional^)
echo   [J] Checklist e documentacao
echo   [0] Sair
echo.
exit /b 0

:ASSISTENTE_INICIAL
cls
echo.
echo ============================================================
echo   Assistente — primeira publicacao
echo ============================================================
echo.

call :CHECK_PREREQ_SOFT
echo.

echo Este assistente configura:
echo   1. Repositorio Git local
echo   2. Ligacao ao GitHub ^(remote^)
echo   3. Primeiro commit ^(se necessario^)
echo   4. Primeiro push para master
echo   5. Orientacao para secrets Firebase e deploy API
echo.
set /p CONT=Continuar? [S/N]: 
if /i not "!CONT!"=="S" goto MAIN

if "%HAS_GIT%"=="0" (
  echo.
  echo [ERRO] Instale Git: https://git-scm.com/
  pause
  goto MAIN
)

if "%IS_REPO%"=="0" (
  echo.
  echo [1/5] A inicializar repositorio Git...
  git init
  if errorlevel 1 (
    echo [ERRO] git init falhou.
    pause
    goto MAIN
  )
  git branch -M master 2>nul
  set IS_REPO=1
  set BRANCH=master
  echo [OK] Repositorio inicializado.
) else (
  echo.
  echo [1/5] Repositorio Git ja existe.
)

if "%HAS_REMOTE%"=="0" (
  echo.
  echo [2/5] Configurar remote GitHub
  echo Sugestao: %GITHUB_REPO_SUGERIDO%
  set /p REPO_URL=URL do repositorio GitHub: 
  if "!REPO_URL!"=="" set "REPO_URL=%GITHUB_REPO_SUGERIDO%"
  git remote add origin "!REPO_URL!"
  if errorlevel 1 (
    echo [AVISO] remote add falhou — talvez ja exista. A tentar alterar...
    git remote set-url origin "!REPO_URL!"
  )
  set HAS_REMOTE=1
  set REMOTE_URL=!REPO_URL!
  echo [OK] Remote configurado: !REPO_URL!
) else (
  echo.
  echo [2/5] Remote ja configurado: %REMOTE_URL%
)

if /i not "%BRANCH%"=="master" (
  echo.
  set /p RENAME=Renomear branch actual para master? [S/N]: 
  if /i "!RENAME!"=="S" (
    git branch -M master
    set BRANCH=master
  )
)

call :DETECT_STATE

if "%HAS_COMMITS%"=="0" (
  echo.
  echo [3/5] Primeiro commit
  echo.
  echo IMPORTANTE: confirme que nao vai commitar segredos
  echo ^(.env, .dev.vars, chaves R2, service accounts^).
  echo.
  git status --short
  echo.
  set /p ADD1=Incluir todos os ficheiros no primeiro commit? [S/N]: 
  if /i not "!ADD1!"=="S" goto MAIN
  set /p MSG1=Mensagem do commit [Initial commit]: 
  if "!MSG1!"=="" set "MSG1=Initial commit"
  git add -A
  git commit -m "!MSG1!"
  if errorlevel 1 (
    echo [ERRO] primeiro commit falhou.
    pause
    goto MAIN
  )
  set HAS_COMMITS=1
  echo [OK] Primeiro commit criado.
) else (
  echo.
  echo [3/5] Ja existem commits no repositorio.
  if defined HAS_CHANGES (
    echo Ha alteracoes por commitar.
    set /p COMMIT_AGORA=Deseja commitar agora? [S/N]: 
    if /i "!COMMIT_AGORA!"=="S" (
      call :EXEC_COMMIT
    )
  )
)

echo.
echo [4/5] Push para GitHub
echo.
echo O push para master dispara o deploy web via GitHub Actions.
echo.
echo Secrets necessarios no GitHub ^(Settings -^> Secrets^):
echo   FIREBASE_SERVICE_ACCOUNT_KIAMICLOUD
echo.
set /p PUSH1=Enviar para origin/%BRANCH% agora? [S/N]: 
if /i "!PUSH1!"=="S" (
  git push -u origin %BRANCH%
  if errorlevel 1 (
    echo.
    echo [ERRO] Push falhou. Verifique:
    echo   - Repositorio criado no GitHub?
    echo   - Credenciais Git configuradas?
    echo   - URL do remote correcta?
    pause
  ) else (
    echo.
    echo [OK] Codigo enviado para GitHub.
    echo Deploy web: %GITHUB_ACTIONS_URL%
  )
)

echo.
echo [5/5] Proximos passos recomendados
echo.
echo   a^) Cloudflare: npm install em workers\ e wrangler login
echo   b^) Configurar D1, R2 e secrets ^(ver docs\DEPLOY.md^)
echo   c^) Neste script: opcao [D] migracoes D1
echo   d^) Neste script: opcao [C] deploy API beta
echo   e^) Neste script: opcao [E] smoke test
echo.
set /p PROX=Executar deploy API beta agora? [S/N]: 
if /i "!PROX!"=="S" goto DEPLOY_API_BETA
pause
goto MAIN

:MENU_GIT
cls
call :DETECT_STATE
echo.
echo === GitHub — commit / push ===
echo.
if "%IS_REPO%"=="0" (
  echo Repositorio Git nao inicializado. Use opcao [A] primeiro.
  pause
  goto MAIN
)
if "%HAS_REMOTE%"=="0" (
  echo Remote GitHub nao configurado. Use opcao [A] primeiro.
  pause
  goto MAIN
)

echo Branch: %BRANCH%
git status -sb
echo.
echo   1 - Ver estado e voltar
echo   2 - Commit
echo   3 - Push
echo   4 - Commit + Push
echo   0 - Voltar ao menu principal
echo.
set /p GIT_OP=Escolha: 

if "%GIT_OP%"=="1" goto MAIN
if "%GIT_OP%"=="2" goto GIT_SO_COMMIT
if "%GIT_OP%"=="3" goto GIT_SO_PUSH
if "%GIT_OP%"=="4" goto GIT_COMMIT_PUSH
if "%GIT_OP%"=="0" goto MAIN
goto MENU_GIT

:GIT_SO_COMMIT
call :EXEC_COMMIT
if not errorlevel 1 (
  set /p MAIS=Deseja fazer push agora? [S/N]: 
  if /i "!MAIS!"=="S" goto GIT_SO_PUSH
)
pause
goto MENU_GIT

:GIT_COMMIT_PUSH
if defined HAS_CHANGES (
  call :EXEC_COMMIT
  if errorlevel 1 goto MENU_GIT
) else (
  echo Sem alteracoes novas — a enviar commits existentes.
)
goto GIT_SO_PUSH

:GIT_SO_PUSH
for /f %%a in ('git rev-list --count origin/%BRANCH%..HEAD 2^>nul') do set AHEAD=%%a
if not defined AHEAD set AHEAD=0
if "%AHEAD%"=="0" (
  echo [AVISO] Nada para enviar ao GitHub.
  pause
  goto MENU_GIT
)

if defined HAS_CHANGES (
  echo [AVISO] Ha alteracoes locais ainda por commitar.
  set /p IGN=Continuar push apenas dos commits existentes? [S/N]: 
  if /i not "!IGN!"=="S" goto MENU_GIT
)

if /i not "%BRANCH%"=="master" (
  echo [AVISO] Deploy web automatico so corre em master.
  set /p CB=Continuar? [S/N]: 
  if /i not "!CB!"=="S" goto MENU_GIT
)

echo.
echo Destino: origin/%BRANCH% ^(%REMOTE_URL%^)
set /p CP=Confirma push? [S/N]: 
if /i not "!CP!"=="S" goto MENU_GIT

git push -u origin %BRANCH%
if errorlevel 1 (
  echo [ERRO] git push falhou.
) else (
  echo [OK] Push concluido.
  if /i "%BRANCH%"=="master" (
    echo Nota: push so actualiza o site se GitHub Actions estiver configurado.
    echo Para publicar ja: opcao [W] ou Publicar-Site-Web.bat
    echo CI: %GITHUB_ACTIONS_URL%
  )
)
pause
goto MENU_GIT

:DEPLOY_WEB_FIREBASE
cls
echo.
echo === Publicar site web (Firebase Hosting) ===
echo.
echo Isto faz:
echo   1. flutter pub get
echo   2. flutter build web --release
echo   3. firebase deploy --only hosting
echo.
echo URL: https://kiamicloud.web.app
echo.
if "%HAS_FLUTTER%"=="0" (
  echo [ERRO] Flutter necessario.
  pause
  goto MAIN
)
if "%HAS_NODE%"=="0" (
  echo [ERRO] Node.js necessario para firebase-tools.
  pause
  goto MAIN
)
set /p DW=Confirma publicacao do site? [S/N]: 
if /i not "!DW!"=="S" goto MAIN

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\deploy-web-firebase.ps1"
if errorlevel 1 (
  echo.
  echo [ERRO] Deploy web falhou.
  echo Dica: npx firebase-tools login
  pause
  goto MAIN
)
echo.
echo [OK] Site actualizado em https://kiamicloud.web.app
pause
goto MAIN

:DEPLOY_API_BETA
cls
echo.
echo === Deploy API beta ===
echo URL: %API_BETA_URL%
echo.

if "%HAS_NODE%"=="0" (
  echo [ERRO] Node.js necessario. Instale https://nodejs.org/
  pause
  goto MAIN
)

if "%HAS_WORKERS_NM%"=="0" (
  echo Dependencias em workers\ nao instaladas.
  set /p NPM1=Executar npm install agora? [S/N]: 
  if /i not "!NPM1!"=="S" goto MAIN
  call :INSTALL_WORKERS
  if errorlevel 1 goto MAIN
)

echo Vai executar:
echo   wrangler deploy --env beta
echo   aplicar CORS R2 beta
echo.
set /p CD=Confirma deploy API beta? [S/N]: 
if /i not "!CD!"=="S" goto MAIN

pushd "%~dp0workers"
echo.
echo [API] Deploy Workers beta...
call npx wrangler deploy --env beta
if errorlevel 1 (
  echo [ERRO] wrangler deploy falhou. Verifique wrangler login e wrangler.toml
  popd
  pause
  goto MAIN
)
popd

echo.
echo [API] CORS R2 beta...
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\apply-r2-cors-beta.ps1"
if errorlevel 1 (
  echo [AVISO] CORS R2 falhou — verifique manualmente.
) else (
  echo [OK] CORS R2 aplicado.
)

echo.
echo [OK] API beta publicada: %API_BETA_URL%
set /p ST=Fazer smoke test agora? [S/N]: 
if /i "!ST!"=="S" goto SMOKE_TEST
pause
goto MAIN

:MIGRAR_D1
cls
echo.
echo === Migracoes D1 remotas ===
echo.
if "%HAS_NODE%"=="0" (
  echo [ERRO] Node.js necessario.
  pause
  goto MAIN
)
if "%HAS_WORKERS_NM%"=="0" call :INSTALL_WORKERS

echo Ambiente:
echo   1 - beta
echo   2 - production
echo   0 - cancelar
echo.
set /p D1_ENV=Escolha: 
if "%D1_ENV%"=="0" goto MAIN
if "%D1_ENV%"=="1" set "D1_FLAG=--env beta"
if "%D1_ENV%"=="2" set "D1_FLAG=--env production"
if not defined D1_FLAG (
  echo Opcao invalida.
  pause
  goto MAIN
)

echo.
echo Comando: wrangler d1 migrations apply kiamicloud-db --remote %D1_FLAG%
set /p D1C=Confirma? [S/N]: 
if /i not "!D1C!"=="S" goto MAIN

pushd "%~dp0workers"
call npx wrangler d1 migrations apply kiamicloud-db --remote %D1_FLAG%
set D1_ERR=!ERRORLEVEL!
popd
if !D1_ERR! neq 0 (
  echo [ERRO] Migracoes falharam.
) else (
  echo [OK] Migracoes aplicadas.
)
pause
goto MAIN

:SMOKE_TEST
cls
echo.
echo === Smoke test API ===
echo.
set /p API_URL=URL da API [%API_BETA_URL%]: 
if "!API_URL!"=="" set "API_URL=%API_BETA_URL%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\smoke-test-api.ps1" -BaseUrl "!API_URL!"
pause
goto MAIN

:PREPARAR_DEPS
cls
echo.
echo === Preparar dependencias Flutter ===
echo.

if "%HAS_FLUTTER%"=="0" (
  echo [ERRO] Flutter necessario. Instale https://flutter.dev/
  pause
  goto MAIN
)

set /p PD=Actualizar dependencias em core, web, mobile e desktop? [S/N]: 
if /i not "!PD!"=="S" goto MAIN

call :FLUTTER_PUB_GET "%~dp0packages\kiamicloud_core"
call :FLUTTER_PUB_GET "%~dp0apps\cloud\web"
call :FLUTTER_PUB_GET "%~dp0apps\cloud\mobile"
call :FLUTTER_PUB_GET "%~dp0apps\cloud\desktop"

echo.
echo [OK] Dependencias actualizadas.
pause
goto MAIN

:BUILD_MOBILE
cls
echo.
echo === Build APK mobile beta ===
echo.

if "%HAS_FLUTTER%"=="0" (
  echo [ERRO] Flutter necessario.
  pause
  goto MAIN
)

set /p API_URL=URL API beta [%API_BETA_URL%]: 
if "!API_URL!"=="" set "API_URL=%API_BETA_URL%"

echo.
echo Comando:
echo   flutter build apk --dart-define=KIAMI_ENV=beta --dart-define=KIAMI_API_BASE_URL=!API_URL!
set /p BM=Confirma build? [S/N]: 
if /i not "!BM!"=="S" goto MAIN

pushd "%~dp0apps\cloud\mobile"
call flutter build apk --dart-define=KIAMI_ENV=beta --dart-define=KIAMI_API_BASE_URL=!API_URL!
set BUILD_ERR=!ERRORLEVEL!
popd

if !BUILD_ERR! neq 0 (
  echo [ERRO] Build falhou.
) else (
  echo [OK] APK em apps\cloud\mobile\build\app\outputs\flutter-apk\
)
pause
goto MAIN

:BUILD_WEB_LOCAL
cls
echo.
echo === Build web local ^(release^) ===
echo.
echo Nota: o deploy online e feito pelo GitHub Actions apos push.
echo Este build e util para testar localmente ou deploy manual Firebase.
echo.

if "%HAS_FLUTTER%"=="0" (
  echo [ERRO] Flutter necessario.
  pause
  goto MAIN
)

set /p BW=Executar flutter build web --release? [S/N]: 
if /i not "!BW!"=="S" goto MAIN

pushd "%~dp0apps\cloud\web"
call flutter build web --release --base-href /
set WEB_ERR=!ERRORLEVEL!
popd

if !WEB_ERR! neq 0 (
  echo [ERRO] Build web falhou.
) else (
  echo [OK] Build em apps\cloud\web\build\web\
  echo.
  set /p DEPLOY=Publicar agora no Firebase? [S/N]: 
  if /i "!DEPLOY!"=="S" (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\deploy-web-firebase.ps1" -SkipBuild
  )
)
pause
goto MAIN

:PUBLICACAO_COMPLETA
cls
echo.
echo ============================================================
echo   Publicacao completa — assistente
echo ============================================================
echo.
echo Passos recomendados para uma release:
echo   1. Preparar dependencias
echo   2. Publicar site web ^(Firebase — build + deploy^)
echo   3. Deploy API beta
echo   4. Smoke test
echo   5. Commit + push GitHub ^(opcional, backup/CI^)
echo   6. Build mobile ^(opcional^)
echo.

set /p P1=Passo 1 — preparar dependencias? [S/N]: 
if /i "!P1!"=="S" (
  call :FLUTTER_PUB_GET "%~dp0packages\kiamicloud_core"
  call :FLUTTER_PUB_GET "%~dp0apps\cloud\web"
  call :FLUTTER_PUB_GET "%~dp0apps\cloud\mobile"
  call :FLUTTER_PUB_GET "%~dp0apps\cloud\desktop"
)

set /p P2=Passo 2 — publicar site web no Firebase? [S/N]: 
if /i "!P2!"=="S" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0scripts\deploy-web-firebase.ps1"
  if errorlevel 1 (
    echo [ERRO] Deploy web falhou.
    pause
    goto MAIN
  )
)

set /p P3=Passo 3 — deploy API beta? [S/N]: 
if /i "!P3!"=="S" goto DEPLOY_API_BETA

set /p P4=Passo 4 — smoke test? [S/N]: 
if /i "!P4!"=="S" goto SMOKE_TEST

call :DETECT_STATE
set /p P5=Passo 5 — commit + push GitHub? [S/N]: 
if /i "!P5!"=="S" (
  if "%IS_REPO%"=="0" (
    echo [AVISO] Git nao configurado — ignorado.
  ) else (
    if defined HAS_CHANGES call :EXEC_COMMIT
    call :DETECT_STATE
    for /f %%a in ('git rev-list --count origin/%BRANCH%..HEAD 2^>nul') do set AHEAD=%%a
    if not defined AHEAD set AHEAD=0
    if not "%AHEAD%"=="0" (
      echo.
      echo A enviar %AHEAD% commit^(s^) para origin/%BRANCH%...
      git push -u origin %BRANCH%
      if errorlevel 1 (
        echo [ERRO] git push falhou.
      ) else (
        echo [OK] Codigo no GitHub. CI: %GITHUB_ACTIONS_URL%
      )
    ) else (
      echo [AVISO] Nada para enviar ao GitHub.
    )
  )
)

set /p P6=Passo 6 — build APK mobile? [S/N]: 
if /i "!P6!"=="S" goto BUILD_MOBILE

echo.
echo === Publicacao concluida ===
echo   Site: https://kiamicloud.web.app
echo   API:  %API_BETA_URL%
pause
goto MAIN

:CHECKLIST
cls
echo.
echo === Checklist de publicacao ===
echo.
echo PRIMEIRA VEZ
echo   [ ] Conta GitHub com repositorio criado
echo   [ ] Git instalado e credenciais configuradas
echo   [ ] Opcao [A] — assistente inicial ^(git init, remote, push^)
echo   [ ] Secret GitHub: FIREBASE_SERVICE_ACCOUNT_KIAMICLOUD
echo   [ ] Cloudflare: wrangler login
echo   [ ] D1 + R2 criados e secrets configurados ^(docs\DEPLOY.md^)
echo   [ ] Opcao [D] — migracoes D1
echo   [ ] Opcao [C] — deploy API beta
echo   [ ] Opcao [E] — smoke test
echo.
echo CADA RELEASE
echo   [ ] Opcao [W] ou Publicar-Site-Web.bat — site no Firebase ^(OBRIGATORIO^)
echo   [ ] Opcao [C] — deploy API beta ^(se mudou backend^)
echo   [ ] Opcao [E] — validar API
echo   [ ] Opcao [B] — commit + push GitHub ^(opcional^)
echo   [ ] Opcao [G] — APK para testadores ^(opcional^)
echo.
echo DOCUMENTACAO
echo   docs\DEPLOY.md  — API Cloudflare
echo   docs\BETA.md    — programa beta
echo   %GITHUB_ACTIONS_URL%
echo.
pause
goto MAIN

:EXEC_COMMIT
if not defined HAS_CHANGES (
  echo [AVISO] Nao ha alteracoes para commit.
  exit /b 1
)
echo.
git status --short
echo.
set /p ADD_ALL=Incluir TODAS as alteracoes? [S/N]: 
if /i not "!ADD_ALL!"=="S" exit /b 1
set /p COMMIT_MSG=Mensagem do commit: 
if "!COMMIT_MSG!"=="" (
  echo [ERRO] Mensagem obrigatoria.
  exit /b 1
)
echo.
echo Resumo: %BRANCH% — !COMMIT_MSG!
set /p CC=Confirma commit? [S/N]: 
if /i not "!CC!"=="S" exit /b 1
git add -A
git commit -m "!COMMIT_MSG!"
if errorlevel 1 exit /b 1
echo [OK] Commit criado.
set HAS_CHANGES=
exit /b 0

:DETECT_STATE
set HAS_GIT=0
set IS_REPO=0
set HAS_REMOTE=0
set HAS_COMMITS=0
set HAS_CHANGES=
set HAS_NODE=0
set HAS_FLUTTER=0
set HAS_WORKERS_NM=0
set NEEDS_SETUP=0
set BRANCH=
set REMOTE_URL=
set AHEAD=0

where git >nul 2>&1
if not errorlevel 1 set HAS_GIT=1

if "%HAS_GIT%"=="1" (
  git rev-parse --is-inside-work-tree >nul 2>&1
  if not errorlevel 1 (
    set IS_REPO=1
    for /f "delims=" %%b in ('git rev-parse --abbrev-ref HEAD 2^>nul') do set BRANCH=%%b
    git rev-parse HEAD >nul 2>&1
    if not errorlevel 1 set HAS_COMMITS=1
    git remote get-url origin >nul 2>&1
    if not errorlevel 1 (
      set HAS_REMOTE=1
      for /f "delims=" %%u in ('git remote get-url origin 2^>nul') do set REMOTE_URL=%%u
    )
    for /f "delims=" %%i in ('git status --porcelain 2^>nul') do set HAS_CHANGES=1
    if "%HAS_REMOTE%"=="1" (
      for /f %%a in ('git rev-list --count origin/%BRANCH%..HEAD 2^>nul') do set AHEAD=%%a
      if not defined AHEAD set AHEAD=0
    )
  )
)

where node >nul 2>&1
if not errorlevel 1 set HAS_NODE=1

where flutter >nul 2>&1
if not errorlevel 1 set HAS_FLUTTER=1

if exist "%~dp0workers\node_modules\" set HAS_WORKERS_NM=1

if "%IS_REPO%"=="0" set NEEDS_SETUP=1
if "%HAS_REMOTE%"=="0" if "%IS_REPO%"=="1" set NEEDS_SETUP=1
if "%HAS_COMMITS%"=="0" if "%IS_REPO%"=="1" set NEEDS_SETUP=1
exit /b 0

:CHECK_PREREQ_SOFT
echo Pre-requisitos:
if "%HAS_GIT%"=="0" echo   [ ] Git — https://git-scm.com/
if "%HAS_NODE%"=="0" echo   [ ] Node.js — https://nodejs.org/ ^(API^)
if "%HAS_FLUTTER%"=="0" echo   [ ] Flutter — https://flutter.dev/ ^(apps^)
if "%HAS_GIT%"=="1" if "%HAS_NODE%"=="1" if "%HAS_FLUTTER%"=="1" echo   [OK] Ferramentas principais detectadas
exit /b 0

:INSTALL_WORKERS
echo.
echo [Workers] npm install...
pushd "%~dp0workers"
if not exist node_modules call npm install
if errorlevel 1 (
  popd
  exit /b 1
)
popd
set HAS_WORKERS_NM=1
exit /b 0

:FLUTTER_PUB_GET
echo.
echo [Flutter] pub get em %~1
pushd "%~1"
call flutter pub get
set FP_ERR=!ERRORLEVEL!
popd
if !FP_ERR! neq 0 exit /b 1
exit /b 0

:SAIR
echo.
echo A sair.
exit /b 0
