# Reinstala apenas a app CasaOS "KiamiCloud Consola" no ZimaBlade (:8790).
# Uso:
#   $env:BLADE_SSH_PASSWORD='casaos'; .\scripts\install-blade-console.ps1

param(
  [string]$BladeHost = '192.168.100.170',
  [string]$BladeUser = 'casaos',
  [string]$SshPassword = $env:BLADE_SSH_PASSWORD
)

$ErrorActionPreference = 'Stop'

if (-not $SshPassword) {
  Write-Host "Defina BLADE_SSH_PASSWORD ou passe -SshPassword" -ForegroundColor Red
  Write-Host ""
  Write-Host "No Blade (SSH), manualmente:" -ForegroundColor Yellow
  Write-Host "  bash /home/casaos/kiamicloud/tools/casaos-kiamicloud-console/install-casaos-app.sh"
  exit 1
}

if (-not (Get-Module -ListAvailable -Name Posh-SSH)) {
  Install-Module -Name Posh-SSH -Scope CurrentUser -Force -AllowClobber
}
Import-Module Posh-SSH -ErrorAction Stop

$sec = ConvertTo-SecureString $SshPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($BladeUser, $sec)
$session = New-SSHSession -ComputerName $BladeHost -Credential $cred -AcceptKey -ErrorAction Stop

$installPath = '/home/casaos/kiamicloud/tools/casaos-kiamicloud-console/install-casaos-app.sh'
$cmd = "sed -i 's/\r$//' '$installPath' 2>/dev/null; bash '$installPath'"

try {
  Write-Host "== Reinstalar KiamiCloud Consola no Blade ($BladeHost) ==" -ForegroundColor Cyan
  $result = Invoke-SSHCommand -SessionId $session.SessionId -Command $cmd -TimeOut 120
  $result.Output | ForEach-Object { Write-Host $_ }
  if ($result.ExitStatus -ne 0) {
    Write-Host $result.Error -ForegroundColor Red
    throw "Install falhou (exit $($result.ExitStatus))"
  }
  Write-Host ""
  Write-Host "Consola: http://${BladeHost}:8790/blade-console/" -ForegroundColor Green
  Write-Host "Login: admin / admin" -ForegroundColor Green
}
finally {
  Remove-SSHSession -SessionId $session.SessionId | Out-Null
}
