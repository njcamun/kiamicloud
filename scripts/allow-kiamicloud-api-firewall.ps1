# Abre a porta 8787 no Firewall Windows (rede privada) para o telemovel aceder a API.
# Executar como Administrador: clique direito PowerShell -> Executar como administrador
#   cd "D:\Projectos Flutter\Novo\scripts"
#   .\allow-kiamicloud-api-firewall.ps1

$ruleName = "KiamiCloud API Dev (TCP 8787)"

$existing = netsh advfirewall firewall show rule name="$ruleName" 2>$null
if ($LASTEXITCODE -eq 0 -and $existing -match "KiamiCloud") {
  Write-Host "Regra ja existe: $ruleName" -ForegroundColor Yellow
} else {
  netsh advfirewall firewall add rule `
    name="$ruleName" `
    dir=in action=allow protocol=TCP localport=8787 `
    profile=private `
    description="Wrangler dev - KiamiCloud API local"
  if ($LASTEXITCODE -ne 0) {
    Write-Host "ERRO: Execute este script como Administrador." -ForegroundColor Red
    exit 1
  }
  Write-Host "Regra criada: $ruleName" -ForegroundColor Green
}

Write-Host ""
Write-Host "Teste no PC:" -ForegroundColor Cyan
Write-Host "  curl.exe http://127.0.0.1:8787/health"
Write-Host "  curl.exe http://192.168.100.170:8787/health"
Write-Host ""
Write-Host "Teste no telemovel (Wi-Fi, Chrome):" -ForegroundColor Cyan
Write-Host "  http://192.168.100.170:8787/health"
