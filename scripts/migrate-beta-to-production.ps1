# Migra dados beta -> producao (D1 + R2) antes de desactivar beta.
# Uso: .\scripts\migrate-beta-to-production.ps1 [-DryRun] [-SkipR2]
param(
    [switch]$DryRun,
    [switch]$SkipR2
)

$ErrorActionPreference = 'Stop'
$Root = Split-Path $PSScriptRoot -Parent
$Workers = Join-Path $Root 'workers'
$BackupDir = Join-Path $Root 'database\backups'
$ProdUrl = 'https://kiamicloud-api.kiamicloud.workers.dev'

function Invoke-Wrangler {
    param([string[]]$WranglerArgs)
    Push-Location $Workers
    try {
        $prev = $ErrorActionPreference
        $ErrorActionPreference = 'Continue'
        $out = & npx wrangler @WranglerArgs 2>&1 | Out-String
        $ErrorActionPreference = $prev
        if ($LASTEXITCODE -ne 0) {
            throw "wrangler falhou: $out"
        }
        return $out
    }
    finally {
        Pop-Location
    }
}

New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

function Invoke-D1Count($dbName, $envFlag) {
    $cmd = @"
SELECT 'users' t, COUNT(*) c FROM users
UNION ALL SELECT 'files', COUNT(*) FROM files
UNION ALL SELECT 'folders', COUNT(*) FROM folders
UNION ALL SELECT 'subscriptions', COUNT(*) FROM subscriptions;
"@
    Push-Location $Workers
    try {
        $args = @('d1', 'execute', $dbName, '--remote', '--command', $cmd)
        if ($envFlag) { $args += @('--env', $envFlag) }
        return Invoke-Wrangler -WranglerArgs $args
    }
    finally {
        Pop-Location
    }
}

Write-Host ''
Write-Host 'KiamiCloud — migracao beta -> producao' -ForegroundColor Cyan
Write-Host '======================================' -ForegroundColor Cyan

Write-Host "`n[1/4] Contagens D1..." -ForegroundColor Yellow
Write-Host 'Beta:' -ForegroundColor Gray
Write-Host (Invoke-D1Count 'kiamicloud-db-beta' 'beta')
Write-Host 'Producao:' -ForegroundColor Gray
Write-Host (Invoke-D1Count 'kiamicloud-db' 'production')

$tables = @(
    'users', 'folders', 'files', 'subscriptions', 'file_actions',
    'payment_checkouts', 'file_shares', 'beta_feedback',
    'admin_actions', 'user_account_events',
    'support_chat_messages', 'support_chat_read_state'
)

Write-Host "`n[2/4] Export beta (data-only, se existir)..." -ForegroundColor Yellow
$exported = @()
foreach ($t in $tables) {
    $outFile = Join-Path $BackupDir "beta-$t.sql"
    Push-Location $Workers
    try {
        if ($DryRun) {
            Write-Host "  [dry-run] export $t -> $outFile" -ForegroundColor DarkGray
            continue
        }
        Invoke-Wrangler -WranglerArgs @(
            'd1', 'export', 'kiamicloud-db-beta', '--remote', '--env', 'beta',
            "--table=$t", '--no-schema', "--output=$outFile"
        ) | Out-Null
        if ((Test-Path $outFile) -and ((Get-Item $outFile).Length -gt 32)) {
            $exported += @{ Table = $t; File = $outFile }
            Write-Host "  export OK: $t" -ForegroundColor Green
        }
        else {
            if (Test-Path $outFile) { Remove-Item $outFile -Force }
            Write-Host "  skip (vazio): $t" -ForegroundColor DarkGray
        }
    }
    finally {
        Pop-Location
    }
}

Write-Host "`n[3/4] Import para producao (merge)..." -ForegroundColor Yellow
if ($exported.Count -eq 0) {
    Write-Host '  Nada a importar — beta D1 vazio ou producao ja e a fonte de verdade.' -ForegroundColor Green
}
else {
    foreach ($item in $exported) {
        if ($DryRun) {
            Write-Host "  [dry-run] import $($item.Table)" -ForegroundColor DarkGray
            continue
        }
        Write-Host "  import $($item.Table)..." -ForegroundColor Gray
        Push-Location $Workers
        try {
            Invoke-Wrangler -WranglerArgs @(
                'd1', 'execute', 'kiamicloud-db', '--remote', '--env', 'production',
                "--file=$($item.File)"
            ) | Out-Null
        }
        catch {
            Write-Host "  AVISO: import $($item.Table) falhou (possivel conflito PK). Revise manualmente." -ForegroundColor Yellow
        }
        finally {
            Pop-Location
        }
    }
}

if (-not $SkipR2) {
    Write-Host "`n[4/4] Sync R2 beta -> prod..." -ForegroundColor Yellow
    $r2Script = Join-Path $Workers 'scripts\sync-r2-beta-to-prod-api.mjs'
    if (-not (Test-Path $r2Script)) {
        Write-Host "  Script R2 em falta: $r2Script" -ForegroundColor Yellow
    }
    elseif ($DryRun) {
        Write-Host '  [dry-run] node scripts/sync-r2-beta-to-prod.mjs --dry-run' -ForegroundColor DarkGray
    }
    else {
        Push-Location $Workers
        try {
            node scripts/sync-r2-beta-to-prod-api.mjs
        }
        finally {
            Pop-Location
        }
    }
}
else {
    Write-Host "`n[4/4] R2 sync ignorado (-SkipR2)" -ForegroundColor DarkGray
}

Write-Host "`nSmoke test producao..." -ForegroundColor Yellow
& (Join-Path $Root 'scripts\smoke-test-api.ps1') -BaseUrl $ProdUrl

Write-Host "`nMigracao concluida." -ForegroundColor Green
Write-Host "Producao: $ProdUrl" -ForegroundColor White
Write-Host 'Beta: manter 30 dias; depois .\scripts\purge-beta-retention.ps1' -ForegroundColor Gray
