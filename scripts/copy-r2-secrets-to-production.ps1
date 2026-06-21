# Copia secrets R2 de beta para producao (valores identicos).
# Necessario se upload presign directo ao R2 for usado em producao.
#
# O wrangler NAO permite ler secrets existentes. Opcoes:
# 1) Dashboard Cloudflare > R2 > Manage API Tokens > copiar Access Key / Secret
# 2) Reutilizar o mesmo token que configurou em beta (recomendado)
#
# Uso interactivo:
#   .\scripts\copy-r2-secrets-to-production.ps1
param(
    [string]$R2AccountId = 'fd1b514b0915d0f6fe4e866ae67ccc86',
    [string]$R2AccessKeyId,
    [string]$R2SecretAccessKey
)

$ErrorActionPreference = 'Stop'
$Workers = Join-Path (Split-Path $PSScriptRoot -Parent) 'workers'

if (-not $R2AccessKeyId) {
    $R2AccessKeyId = Read-Host 'R2 Access Key ID (mesmo token usado em beta)'
}
if (-not $R2SecretAccessKey) {
    $R2SecretAccessKey = Read-Host 'R2 Secret Access Key' -AsSecureString
    $R2SecretAccessKey = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($R2SecretAccessKey)
    )
}

Push-Location $Workers
try {
    foreach ($pair in @(
            @('R2_ACCOUNT_ID', $R2AccountId),
            @('R2_ACCESS_KEY_ID', $R2AccessKeyId),
            @('R2_SECRET_ACCESS_KEY', $R2SecretAccessKey)
        )) {
        $name = $pair[0]
        $value = $pair[1]
        $value | npx wrangler secret put $name --env production
        if ($LASTEXITCODE -ne 0) { throw "Falha ao definir $name" }
        Write-Host "OK $name" -ForegroundColor Green
    }
}
finally {
    Pop-Location
}

Write-Host 'Secrets R2 configurados em producao.' -ForegroundColor Green
