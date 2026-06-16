# Deploy workers + database para ZimaBlade (LAN).
# Uso:
#   .\scripts\deploy-blade.ps1
#   $env:BLADE_SSH_PASSWORD='sua_password'; .\scripts\deploy-blade.ps1
# Blade por defeito: 192.168.100.170

param(
  [string]$BladeHost = '192.168.100.170',
  [string]$BladeUser = 'casaos',
  [int]$HttpPort = 8765,
  [int]$SshTimeoutSeconds = 30,
  [string]$SshPassword = $env:BLADE_SSH_PASSWORD,
  [switch]$SkipEmbed,
  [switch]$HttpOnly
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
Set-Location $Root

Write-Host "== KiamiCloud deploy -> Blade ($BladeHost) ==" -ForegroundColor Cyan

function Test-BladeReachable {
  param([string]$TargetHost)
  Write-Host ">> Testar rede: $TargetHost (porta 22)..." -ForegroundColor DarkGray
  $ping = Test-Connection -ComputerName $TargetHost -Count 1 -Quiet -ErrorAction SilentlyContinue
  $tcp = Test-NetConnection -ComputerName $TargetHost -Port 22 -WarningAction SilentlyContinue -ErrorAction SilentlyContinue
  $sshOk = $tcp.TcpTestSucceeded -eq $true
  if (-not $ping -and -not $sshOk) {
    Write-Host ""
    Write-Host "ERRO: Nao foi possivel contactar o ZimaBlade em $TargetHost" -ForegroundColor Red
    Write-Host "  - PC e Blade na mesma Wi-Fi? (rede 192.168.100.x)" -ForegroundColor Yellow
    Write-Host "  - Hostname alternativo: casaos.local (mDNS) ou IP 192.168.100.170 no CasaOS." -ForegroundColor Yellow
    Write-Host "  - SSH activo no Blade? (utilizador: $BladeUser)" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Deploy manual (sem SSH a partir deste PC):" -ForegroundColor Cyan
    Write-Host "  .\scripts\deploy-blade.ps1 -HttpOnly" -ForegroundColor White
    Write-Host "  Depois no Blade: curl -fsSL 'http://<IP-DO-SEU-PC>:8765/remote-install.sh' | bash" -ForegroundColor White
    Write-Host ""
    Write-Host "Ou outro host:" -ForegroundColor Cyan
    Write-Host "  .\scripts\deploy-blade.ps1 -BladeHost 192.168.100.170" -ForegroundColor White
    return $false
  }
  if (-not $sshOk) {
    Write-Host "AVISO: ping OK mas porta 22 fechada em $TargetHost" -ForegroundColor Yellow
    return $false
  }
  Write-Host ">> Rede OK (${TargetHost}:22)" -ForegroundColor Green
  return $true
}

if (-not $SkipEmbed) {
  Write-Host ">> blade-console:embed"
  Push-Location workers
  npm run blade-console:embed | Out-Host
  Pop-Location
}

$DeployDir = Join-Path $Root '.deploy-blade'
$Archive = Join-Path $DeployDir 'kiamicloud-blade.tar.gz'
$RemoteScript = Join-Path $DeployDir 'remote-install.sh'
New-Item -ItemType Directory -Force -Path $DeployDir | Out-Null

Write-Host ">> Criar arquivo (workers + database, sem node_modules/.wrangler)"
if (Test-Path $Archive) { Remove-Item $Archive -Force }

$CasaOsTools = Join-Path $Root 'tools\casaos-kiamicloud-console'
Get-ChildItem -Path $CasaOsTools -Filter '*.sh' -File | ForEach-Object {
  $raw = [System.IO.File]::ReadAllText($_.FullName)
  $lf = ($raw -replace "`r`n", "`n") -replace "`r", "`n"
  if ($lf -ne $raw) {
    [System.IO.File]::WriteAllText($_.FullName, $lf, [System.Text.UTF8Encoding]::new($false))
  }
}

& tar -czf $Archive --exclude=workers/node_modules --exclude=workers/.wrangler workers database tools/casaos-kiamicloud-console
if ($LASTEXITCODE -ne 0) { throw "tar falhou ($LASTEXITCODE)" }

$LanIp = '0.0.0.0'
$LanIpAdvertise = (
  Get-NetIPAddress -AddressFamily IPv4 |
  Where-Object { $_.IPAddress -like '192.168.100.*' } |
  Sort-Object -Descending IPAddress |
  Select-Object -First 1 -ExpandProperty IPAddress
)
if (-not $LanIpAdvertise) {
  $LanIpAdvertise = (
    Get-NetIPAddress -AddressFamily IPv4 |
    Where-Object { $_.IPAddress -like '192.168.*' -and $_.PrefixOrigin -ne 'WellKnown' } |
    Select-Object -First 1 -ExpandProperty IPAddress
  )
}
if (-not $LanIpAdvertise) { $LanIpAdvertise = '127.0.0.1' }

$archiveName = Split-Path $Archive -Leaf
$HttpUrl = "http://${LanIpAdvertise}:${HttpPort}/${archiveName}"
$ScriptUrl = "http://${LanIpAdvertise}:${HttpPort}/remote-install.sh"

function Write-UnixTextFile {
  param([string]$Path, [string]$Content)
  $normalized = ($Content -replace "`r`n", "`n") -replace "`r", "`n"
  [System.IO.File]::WriteAllText($Path, $normalized, [System.Text.UTF8Encoding]::new($false))
}

$template = Get-Content (Join-Path $PSScriptRoot 'remote-install-blade.sh') -Raw
Write-UnixTextFile -Path $RemoteScript -Content ($template.Replace('__ARCHIVE_URL__', $HttpUrl))

function Start-DeployHttpServer {
  param([string]$ServeDir, [int]$Port, [string]$Bind)
  $existing = Get-NetTCPConnection -LocalPort $Port -ErrorAction SilentlyContinue
  if ($existing) {
    Write-Host ">> Porta $Port ja em uso - reutilizar servidor existente" -ForegroundColor Yellow
    return $null
  }
  Write-Host ">> Servidor HTTP http://${Bind}:${Port}/"
  return Start-Process -PassThru -WindowStyle Hidden python -ArgumentList @(
    '-m', 'http.server', "$Port", '--bind', $Bind, '--directory', $ServeDir
  )
}

$httpProc = Start-DeployHttpServer -ServeDir $DeployDir -Port $HttpPort -Bind $LanIp

function Invoke-BladeRemoteInstall {
  param([string]$Password)
  if (-not (Test-BladeReachable -TargetHost $BladeHost)) {
    throw "Blade inacessivel. Corrija a rede ou use -HttpOnly."
  }
  if (-not (Get-Module -ListAvailable -Name Posh-SSH)) {
    Install-Module -Name Posh-SSH -Scope CurrentUser -Force -AllowClobber
  }
  Import-Module Posh-SSH -ErrorAction Stop
  $sec = ConvertTo-SecureString $Password -AsPlainText -Force
  $cred = New-Object System.Management.Automation.PSCredential($BladeUser, $sec)
  Write-Host ">> SSH: ligar a ${BladeUser}@${BladeHost} (timeout ${SshTimeoutSeconds}s)..." -ForegroundColor DarkGray
  $session = New-SSHSession -ComputerName $BladeHost -Credential $cred -AcceptKey -ConnectionTimeout $SshTimeoutSeconds -ErrorAction Stop
  try {
    Write-Host ">> SSH: instalar via $ScriptUrl"
    $cmd = "curl -fsSL '$ScriptUrl' | bash"
    $result = Invoke-SSHCommand -SessionId $session.SessionId -Command $cmd -TimeOut 300
    $result.Output | ForEach-Object { Write-Host $_ }
    if ($result.ExitStatus -ne 0) {
      throw "Remote install falhou (exit $($result.ExitStatus)): $($result.Error)"
    }
  }
  finally {
    Remove-SSHSession -SessionId $session.SessionId | Out-Null
  }
}

try {
  if ($SshPassword -and -not $HttpOnly) {
    Invoke-BladeRemoteInstall -Password $SshPassword
    Write-Host ""
    Write-Host "Deploy concluido via SSH." -ForegroundColor Green
    Write-Host "API:     http://${BladeHost}:8787/health"
    Write-Host "Consola: http://${BladeHost}:8787/blade-console/"
    exit 0
  }

  Write-Host ""
  Write-Host "Sem BLADE_SSH_PASSWORD - servidor HTTP activo para pull manual." -ForegroundColor Yellow
  Write-Host "No Blade (SSH), corra:" -ForegroundColor Yellow
  Write-Host ""
  Write-Host "  curl -fsSL '$ScriptUrl' | bash" -ForegroundColor White
  Write-Host ""
  $pub = Get-Content "$env:USERPROFILE\.ssh\id_ed25519_blade.pub" -ErrorAction SilentlyContinue
  if ($pub) {
    Write-Host "Chave SSH (deploy automatico futuro):" -ForegroundColor Yellow
    Write-Host "  echo '$pub' >> ~/.ssh/authorized_keys" -ForegroundColor White
  }
  Write-Host ""
  Write-Host "Servidor HTTP activo. Ctrl+C para parar." -ForegroundColor DarkGray
  if ($httpProc) { Wait-Process -Id $httpProc.Id }
}
finally {
  if ($httpProc -and -not $httpProc.HasExited) {
    Stop-Process -Id $httpProc.Id -Force -ErrorAction SilentlyContinue
  }
}
