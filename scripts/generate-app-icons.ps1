# Gera icones da app (Android / Web / Windows) a partir de branding/assets/icon.png
$ErrorActionPreference = "Stop"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$icon = Join-Path $root "branding\assets\icon.png"

if (-not (Test-Path $icon)) {
    Write-Host "ERRO: Falta branding\assets\icon.png" -ForegroundColor Red
    exit 1
}

Write-Host "[KiamiCloud] Sync branding + gerar icones (icon.png)" -ForegroundColor Cyan
& (Join-Path $PSScriptRoot "sync-branding-assets.ps1")
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

$apps = @(
    @{ Name = "cloud_mobile";   Dir = "apps\cloud\mobile" },
    @{ Name = "cloud_web";      Dir = "apps\cloud\web" },
    @{ Name = "cloud_desktop";  Dir = "apps\cloud\desktop" }
)

foreach ($app in $apps) {
    $dir = Join-Path $root $app.Dir
    if (-not (Test-Path $dir)) { continue }
    Write-Host ""
    Write-Host "flutter_launcher_icons - $($app.Name)" -ForegroundColor Cyan
    Push-Location $dir
    try {
        dart run flutter_launcher_icons
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    finally {
        Pop-Location
    }
}

Write-Host ""
Write-Host "Icones gerados. Reinstale a app ou faca build limpo." -ForegroundColor Green

# Native splash (Android mobile apps)
$splashApps = @("apps\cloud\mobile")
foreach ($rel in $splashApps) {
    $dir = Join-Path $root $rel
    if (-not (Test-Path $dir)) { continue }
    Write-Host ""
    Write-Host "flutter_native_splash - $rel" -ForegroundColor Cyan
    Push-Location $dir
    try {
        dart run flutter_native_splash:create
        if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    }
    finally {
        Pop-Location
    }
}

Write-Host ""
Write-Host "Splash nativo regenerado." -ForegroundColor Green
