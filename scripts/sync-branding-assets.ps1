# Sync branding/assets -> packages/kiamicloud_core/assets
# Run from project root: .\scripts\sync-branding-assets.ps1
#
# branding/assets/  — logos, icones, SVG
# categorias PNG    — na mesma pasta (img.png, video.png, ...) -> assets/categories/

$ErrorActionPreference = "Stop"

$scriptsDir = $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($scriptsDir)) {
    $scriptsDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
}
$root = (Resolve-Path (Join-Path $scriptsDir "..")).Path

$source = Join-Path $root "branding\assets"
$destBranding = Join-Path $root "packages\kiamicloud_core\assets\branding"
$destCategories = Join-Path $root "packages\kiamicloud_core\assets\categories"

$categoryFiles = @(
    "img.png", "img_dark.png",
    "video.png", "video_dark.png",
    "audio.png", "audio_dark.png",
    "doc.png", "doc_dark.png",
    "outro.png", "outro_dark.png",
    "unknow.png", "unknow_dark.png"
)

# Nao copiar para assets/branding/ (legado ou duplicados).
$brandingSkip = [System.Collections.Generic.HashSet[string]]::new(
    [string[]]@(
        "logo.png",
        "Logo_barra.png",
        "icon.png",
        "audio.png", "doc.png", "img.png", "outro.png", "unknow.png", "video.png"
    ),
    [StringComparer]::OrdinalIgnoreCase
)

Write-Host "[KiamiCloud] Sync branding" -ForegroundColor Cyan
Write-Host "  Root:   $root"
Write-Host "  From:   $source"
Write-Host ""

if (-not (Test-Path $source)) {
    Write-Host "ERROR: Missing folder branding\assets" -ForegroundColor Red
    exit 1
}

$copied = 0

New-Item -ItemType Directory -Force -Path $destBranding | Out-Null
$files = @(Get-ChildItem -Path $source -File -ErrorAction SilentlyContinue)
if ($files.Count -eq 0) {
    Write-Host "WARN: branding\assets is empty." -ForegroundColor Yellow
} else {
    Write-Host "Branding -> assets/branding" -ForegroundColor Cyan
    foreach ($file in $files) {
        if ($categoryFiles -contains $file.Name) { continue }
        if ($brandingSkip.Contains($file.Name)) {
            Write-Host ("  SKIP " + $file.Name + " (nao usado em branding/)") -ForegroundColor DarkYellow
            continue
        }
        $target = Join-Path $destBranding $file.Name
        Copy-Item -LiteralPath $file.FullName -Destination $target -Force
        $copied++
        Write-Host ("  OK  " + $file.Name) -ForegroundColor Green
    }
}

New-Item -ItemType Directory -Force -Path $destCategories | Out-Null
Write-Host ""
Write-Host "Categories -> assets/categories" -ForegroundColor Cyan
foreach ($name in $categoryFiles) {
    $srcFile = Join-Path $source $name
    if (-not (Test-Path $srcFile)) { continue }
    $target = Join-Path $destCategories $name
    Copy-Item -LiteralPath $srcFile -Destination $target -Force
    $copied++
    Write-Host ("  OK  " + $name) -ForegroundColor Green
}

# Remover legados do destino (limpeza apos sync).
foreach ($legacy in $brandingSkip) {
    $stale = Join-Path $destBranding $legacy
    if (Test-Path $stale) {
        Remove-Item -LiteralPath $stale -Force
        Write-Host ("  DEL " + $legacy + " (removido de assets/branding)") -ForegroundColor DarkGray
    }
}

Write-Host ""
Write-Host ("Done: " + $copied + " file(s) copied.") -ForegroundColor Green
exit 0
