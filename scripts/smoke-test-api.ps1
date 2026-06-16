# Testes rapidos da API KiamiCloud (Fase 14)
param(
    [string]$BaseUrl = "http://127.0.0.1:8787"
)

$BaseUrl = $BaseUrl.TrimEnd("/")
$ok = 0
$fail = 0

function Test-Endpoint {
    param([string]$Name, [string]$Path, [int]$ExpectedStatus = 200)
    try {
        $r = Invoke-WebRequest -Uri "$BaseUrl$Path" -UseBasicParsing -TimeoutSec 15
        if ($r.StatusCode -eq $ExpectedStatus) {
            Write-Host ('OK  ' + $Name + ' (' + $r.StatusCode + ')') -ForegroundColor Green
            $script:ok++
        } else {
            Write-Host ('FAIL ' + $Name + ' - esperado ' + $ExpectedStatus + ', recebido ' + $r.StatusCode) -ForegroundColor Red
            $script:fail++
        }
    } catch {
        $code = $null
        if ($_.Exception.Response) {
            $code = [int]$_.Exception.Response.StatusCode.value__
        }
        if ($code -eq $ExpectedStatus) {
            Write-Host ('OK  ' + $Name + ' (' + $code + ')') -ForegroundColor Green
            $script:ok++
        } else {
            $msg = $_.Exception.Message
            Write-Host ('FAIL ' + $Name + ' - ' + $msg) -ForegroundColor Red
            $script:fail++
        }
    }
}

Write-Host ('KiamiCloud smoke test - ' + $BaseUrl) -ForegroundColor Cyan
Test-Endpoint "GET /" "/"
Test-Endpoint "GET /health/ping" "/health/ping"
Test-Endpoint "GET /health" "/health"
Test-Endpoint "GET /plans" "/plans"
Test-Endpoint "GET /beta/info" "/beta/info"
Test-Endpoint "GET /me sem token" "/me" -ExpectedStatus 401

Write-Host ""
$color = if ($fail -eq 0) { "Green" } else { "Yellow" }
Write-Host ('Resultado: ' + $ok + ' OK, ' + $fail + ' falhas') -ForegroundColor $color
if ($fail -gt 0) { exit 1 }
