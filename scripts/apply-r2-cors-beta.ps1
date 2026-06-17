# Aplica CORS no bucket R2 beta (upload directo do browser / Flutter Web).
$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$CorsFile = Join-Path $Root 'storage\r2-cors-beta.json'
$Bucket = 'kiamicloud-files-beta'

if (-not (Test-Path $CorsFile)) {
    Write-Host "ERRO: Falta $CorsFile" -ForegroundColor Red
    exit 1
}

Write-Host "[KiamiCloud] R2 CORS -> $Bucket" -ForegroundColor Cyan
Push-Location (Join-Path $Root 'workers')
try {
    npx wrangler r2 bucket cors set $Bucket --file $CorsFile -y
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
    Pop-Location
}

Write-Host "CORS R2 aplicado." -ForegroundColor Green
