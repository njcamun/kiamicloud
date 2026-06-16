# KiamiCloud — Verifica estrutura de pastas obrigatória
# Uso: .\scripts\verify-structure.ps1

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)

$required = @(
    "apps\cloud\mobile",
    "apps\cloud\web",
    "apps\cloud\desktop",
    "workers",
    "database",
    "storage",
    "branding",
    "branding\assets",
    "docs",
    "progress",
    "scripts"
)

$missing = @()
foreach ($path in $required) {
    $full = Join-Path $root $path
    if (-not (Test-Path $full)) {
        $missing += $path
    }
}

if ($missing.Count -gt 0) {
    Write-Host "ERRO: Pastas em falta:" -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  - $_" }
    exit 1
}

Write-Host "OK: Estrutura KiamiCloud valida." -ForegroundColor Green
exit 0
