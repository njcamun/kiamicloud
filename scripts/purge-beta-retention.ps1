# Apaga dados beta apos periodo de retencao (30 dias pos-migracao).
# Data prevista: 2026-07-20 (ajuste BETA_PURGE_AFTER se necessario).
#
# Uso:
#   .\scripts\purge-beta-retention.ps1 -WhatIf          # apenas relatorio
#   .\scripts\purge-beta-retention.ps1 -Force           # executa purge
param(
    [switch]$WhatIf,
    [switch]$Force,
    [string]$BetaPurgeAfter = '2026-07-20'
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$Workers = Join-Path $Root 'workers'
$Today = Get-Date -Format 'yyyy-MM-dd'

Write-Host ''
Write-Host 'KiamiCloud — purge beta (retencao 30 dias)' -ForegroundColor Cyan
Write-Host "Hoje: $Today | Limite: $BetaPurgeAfter" -ForegroundColor Gray

if ($Today -lt $BetaPurgeAfter -and -not $Force) {
    Write-Host ''
    Write-Host "Ainda dentro do periodo de retencao. Use -Force para forcar antes de $BetaPurgeAfter." -ForegroundColor Yellow
    exit 0
}

function Invoke-D1($sql) {
    Push-Location $Workers
    try {
        if ($WhatIf) {
            Write-Host "[what-if] D1: $sql" -ForegroundColor DarkGray
            return
        }
        & npx wrangler d1 execute kiamicloud-db-beta --remote --env beta --command $sql
    }
    finally {
        Pop-Location
    }
}

$tables = @(
    'support_chat_read_state', 'support_chat_messages', 'user_account_events',
    'admin_actions', 'beta_feedback', 'file_shares', 'payment_checkouts',
    'file_actions', 'security_events', 'rate_limit_buckets',
    'files', 'folders', 'subscriptions', 'users'
)

Write-Host "`n[1/2] Limpar D1 beta..." -ForegroundColor Yellow
foreach ($t in $tables) {
    Invoke-D1 "DELETE FROM $t;"
}

Write-Host "`n[2/2] R2 beta — apagar objectos manualmente ou via Dashboard." -ForegroundColor Yellow
Write-Host '  Bucket: kiamicloud-files-beta' -ForegroundColor Gray
Write-Host '  (Wrangler nao tem bulk delete; use Cloudflare Dashboard ou rclone purge.)' -ForegroundColor Gray

if ($WhatIf) {
    Write-Host "`nWhatIf: nenhuma alteracao aplicada." -ForegroundColor DarkGray
}
else {
    Write-Host "`nPurge D1 beta concluido." -ForegroundColor Green
    Write-Host 'Opcional: desactivar worker beta apos confirmar que ninguem usa a URL beta.' -ForegroundColor Gray
}
