# Build Flutter Web e publica em Firebase Hosting (kiamicloud.web.app).
#
# Uso:
#   .\scripts\deploy-web-firebase.ps1
#
# Deploy automatico (GitHub Actions):
#   - Push para master dispara .github/workflows/deploy-web.yml
#   - Requer secret FIREBASE_SERVICE_ACCOUNT_KIAMICLOUD no repositorio
#     (JSON da service account Firebase com role Firebase Hosting Admin)
#
param(
    [switch]$SkipBuild
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$WebDir = Join-Path $Root 'apps\cloud\web'
$CoreDir = Join-Path $Root 'packages\kiamicloud_core'
$BuildDir = Join-Path $WebDir 'build\web'
$ProjectId = 'kiamicloud'

function Require-Command($name, $installHint) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        Write-Host "ERRO: '$name' nao encontrado." -ForegroundColor Red
        Write-Host $installHint -ForegroundColor Yellow
        exit 1
    }
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Cyan
Write-Host '  KiamiCloud - Deploy Web (Firebase)' -ForegroundColor Cyan
Write-Host '========================================' -ForegroundColor Cyan
Write-Host "  Projecto: $ProjectId" -ForegroundColor Gray
Write-Host '  URL:      https://kiamicloud.web.app' -ForegroundColor Gray
Write-Host ''

Require-Command 'flutter' 'Instale Flutter: https://flutter.dev/'
Require-Command 'node' 'Instale Node.js: https://nodejs.org/ (para firebase-tools)'

if (-not (Test-Path (Join-Path $Root 'firebase.json'))) {
    Write-Host "ERRO: firebase.json nao encontrado em $Root" -ForegroundColor Red
    exit 1
}

Write-Host '[1/4] Dependencias Flutter...' -ForegroundColor Cyan
Push-Location $CoreDir
try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
    Pop-Location
}

Push-Location $WebDir
try {
    flutter pub get
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
    Pop-Location
}

$syncScript = Join-Path $Root 'tool\sync_branding.dart'
if (Test-Path $syncScript) {
    Write-Host '[2/4] Sync branding...' -ForegroundColor Cyan
    Push-Location $Root
    try {
        dart run tool/sync_branding.dart
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Host '[2/4] Sync branding ignorado (ficheiro em falta)' -ForegroundColor Yellow
}

if (-not $SkipBuild) {
    Write-Host '[3/4] Icones PWA + flutter build web --release...' -ForegroundColor Cyan
    Push-Location $WebDir
    try {
        dart run flutter_launcher_icons
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
        flutter build web --release --base-href / --no-wasm-dry-run `
          --dart-define=KIAMI_ENV=production `
          --dart-define=KIAMI_API_BASE_URL=https://kiamicloud-api.kiamicloud.workers.dev
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    finally {
        Pop-Location
    }
}
else {
    Write-Host '[3/4] Build ignorado (-SkipBuild)' -ForegroundColor Yellow
    $indexHtml = Join-Path $BuildDir 'index.html'
    if (-not (Test-Path $indexHtml)) {
        Write-Host "ERRO: Nao existe build em $BuildDir. Execute sem -SkipBuild." -ForegroundColor Red
        exit 1
    }
}

Write-Host '[4/4] firebase deploy --only hosting...' -ForegroundColor Cyan
Write-Host '      (Se pedir login: npx firebase-tools login)' -ForegroundColor Gray
Push-Location $Root
try {
    npx --yes firebase-tools@latest deploy --only hosting --project $ProjectId
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
    Pop-Location
}

Write-Host ''
Write-Host '========================================' -ForegroundColor Green
Write-Host '  Site publicado com sucesso' -ForegroundColor Green
Write-Host '========================================' -ForegroundColor Green
Write-Host '  https://kiamicloud.web.app' -ForegroundColor White
Write-Host '  https://kiamicloud.firebaseapp.com' -ForegroundColor White
Write-Host ''
