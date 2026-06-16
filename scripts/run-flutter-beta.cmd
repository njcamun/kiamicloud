@echo off

REM KiamiCloud — Flutter em modo beta (Cloudflare)

set API_URL=https://kiamicloud-api-beta.kiamicloud.workers.dev

if not "%~1"=="" set API_URL=%~1



echo KiamiCloud Beta — API: %API_URL%

cd /d "%~dp0..\apps\cloud\mobile"

flutter run --dart-define=KIAMI_ENV=beta --dart-define=KIAMI_API_BASE_URL=%API_URL%

