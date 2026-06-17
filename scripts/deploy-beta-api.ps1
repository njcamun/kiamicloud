# Deploy API beta (Worker CORS + R2 CORS para Flutter Web).
$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent

Write-Host "== KiamiCloud API beta ==" -ForegroundColor Cyan

Push-Location (Join-Path $Root 'workers')
try {
    Write-Host ">> wrangler deploy --env beta" -ForegroundColor Cyan
    npx wrangler deploy --env beta
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}
finally {
    Pop-Location
}

& (Join-Path $PSScriptRoot 'apply-r2-cors-beta.ps1')
if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }

Write-Host ""
Write-Host "API beta actualizada. Teste:" -ForegroundColor Green
Write-Host "  .\scripts\smoke-test-api.ps1 -BaseUrl https://kiamicloud-api-beta.kiamicloud.workers.dev" -ForegroundColor White
