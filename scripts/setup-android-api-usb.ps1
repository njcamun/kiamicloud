# Liga o telemovel USB a API no PC sem depender do Wi-Fi (adb reverse).
# Requisitos: USB debugging activo, adb no PATH, npm run dev a correr no PC.

Write-Host "A configurar adb reverse tcp:8787 tcp:8787 ..." -ForegroundColor Cyan
adb reverse tcp:8787 tcp:8787
if ($LASTEXITCODE -ne 0) {
  Write-Host "ERRO: adb falhou. Telemovel ligado por USB com depuracao USB?" -ForegroundColor Red
  exit 1
}

Write-Host ""
Write-Host "OK. Use na app: http://127.0.0.1:8787" -ForegroundColor Green
Write-Host "Altere em packages/kiamicloud_core/lib/src/constants/kiami_constants.dart:"
Write-Host '  devApiBaseUrl = ''http://127.0.0.1:8787'''
Write-Host "Depois: flutter build apk --release && flutter install --release"
Write-Host ""
Write-Host "Teste rapido (opcional):" -ForegroundColor Cyan
adb shell "curl -s http://127.0.0.1:8787/health" 2>$null
if ($LASTEXITCODE -ne 0) {
  Write-Host "(curl no telemovel nao disponivel — teste na app Flutter)"
}
