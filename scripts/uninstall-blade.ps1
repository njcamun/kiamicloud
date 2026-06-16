# Remove KiamiCloud do ZimaBlade (SSH).
# Uso:
#   .\scripts\uninstall-blade.ps1
#   $env:BLADE_SSH_PASSWORD='sua_password'; .\scripts\uninstall-blade.ps1

param(
  [string]$BladeHost = '192.168.100.170',
  [string]$BladeUser = 'casaos',
  [string]$SshPassword = $env:BLADE_SSH_PASSWORD
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$ScriptPath = Join-Path $PSScriptRoot 'uninstall-blade.sh'

if (-not $SshPassword) { $SshPassword = 'casaos' }

function Write-UnixTextFile {
  param([string]$Path, [string]$Content)
  $normalized = ($Content -replace "`r`n", "`n") -replace "`r", "`n"
  [System.IO.File]::WriteAllText($Path, $normalized, [System.Text.UTF8Encoding]::new($false))
}

if (-not (Get-Module -ListAvailable -Name Posh-SSH)) {
  Install-Module -Name Posh-SSH -Scope CurrentUser -Force -AllowClobber
}
Import-Module Posh-SSH -ErrorAction Stop

$remoteScript = Get-Content $ScriptPath -Raw
$remoteScript = ($remoteScript -replace "`r`n", "`n") -replace "`r", "`n"
$b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($remoteScript))
$remoteCmd = "echo '$b64' | base64 -d > /tmp/uninstall-kiamicloud.sh && chmod +x /tmp/uninstall-kiamicloud.sh && bash /tmp/uninstall-kiamicloud.sh; rm -f /tmp/uninstall-kiamicloud.sh"

Write-Host "== KiamiCloud uninstall -> Blade ($BladeHost) ==" -ForegroundColor Cyan

$sec = ConvertTo-SecureString $SshPassword -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential($BladeUser, $sec)
$session = New-SSHSession -ComputerName $BladeHost -Credential $cred -AcceptKey -ErrorAction Stop

try {
  $result = Invoke-SSHCommand -SessionId $session.SessionId -Command $remoteCmd -TimeOut 300
  $result.Output | ForEach-Object { Write-Host $_ }
  if ($result.ExitStatus -ne 0) {
    throw "Uninstall falhou (exit $($result.ExitStatus)): $($result.Error)"
  }
  Write-Host ""
  Write-Host "Rollback concluido no ZimaBlade." -ForegroundColor Green
}
finally {
  Remove-SSHSession -SessionId $session.SessionId | Out-Null
}
