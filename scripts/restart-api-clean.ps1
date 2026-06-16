# Para todos os workerd/wrangler na porta 8787 e reinicia a API limpa.
# Uso: .\restart-api-clean.ps1
# Depois noutro terminal: cd workers && npm run dev

param(
  [switch]$Quiet
)

$root = Split-Path -Parent $PSScriptRoot
$workers = Join-Path $root "workers"

function Write-Info($msg, $color = 'Cyan') {
  if (-not $Quiet) { Write-Host $msg -ForegroundColor $color }
}

Write-Info "A parar processos workerd (porta 8787)..."

Get-Process -Name "workerd" -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 1

# Node a correr wrangler dev (nao mata outros node.exe do sistema)
Get-CimInstance Win32_Process -Filter "Name='node.exe'" -ErrorAction SilentlyContinue |
  Where-Object { $_.CommandLine -match 'wrangler' } |
  ForEach-Object {
    Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue
  }
Start-Sleep -Seconds 1

$conns = Get-NetTCPConnection -LocalPort 8787 -ErrorAction SilentlyContinue
foreach ($c in $conns) {
  if ($c.OwningProcess -gt 0) {
    Stop-Process -Id $c.OwningProcess -Force -ErrorAction SilentlyContinue
  }
}
Start-Sleep -Seconds 1

$still = Get-NetTCPConnection -LocalPort 8787 -State Listen -ErrorAction SilentlyContinue
if ($still) {
  Write-Info "AVISO: porta 8787 ainda em uso." 'Yellow'
} else {
  Write-Info "Porta 8787 livre." 'Green'
}

if (-not $Quiet) {
  Write-Host ""
  Write-Host "Opcional - reset D1 local se /health continuar lento:" -ForegroundColor Cyan
  Write-Host ('  Remove-Item -Recurse -Force "' + $workers + '\.wrangler\state"')
  Write-Host ""
  Write-Host "Inicie a API pela consola (Reinicio limpo) ou:" -ForegroundColor Green
  Write-Host ('  cd "' + $workers + '"')
  Write-Host "  npm run dev"
  Write-Host ""
  Write-Host "Teste (deve ser instantaneo):" -ForegroundColor Cyan
  Write-Host "  curl.exe http://127.0.0.1:8787/health/ping"
  Write-Host "  curl.exe http://127.0.0.1:8787/health"
}
