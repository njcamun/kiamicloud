# API local — telemovel nao abre a URL

## Sintoma

`http://192.168.100.170:8787/health` no browser do telemovel nao carrega (timeout ou pagina em branco).

---

## Passo 1 — Matar processos duplicados (causa comum no Windows)

Varios `workerd.exe` na porta **8787** = paginas em branco / timeout.

PowerShell:

```powershell
cd "D:\Projectos Flutter\Novo\scripts"
.\restart-api-clean.ps1
```

Depois **um unico** terminal — ou use a GUI:

```powershell
# Opcao A — duplo-clique na raiz do projecto
Iniciar-API-GUI.bat

# Opcao B — API directa (consola wrangler)
Iniciar-API-Local.bat
```

Ou manualmente:

```powershell
cd "D:\Projectos Flutter\Novo\workers"
npm run dev
```

**Teste rapido (sem D1):**

```powershell
curl.exe http://127.0.0.1:8787/health/ping
```

Deve devolver JSON de imediato. Depois:

```powershell
curl.exe http://127.0.0.1:8787/health
```

Se `/health/ping` funciona mas `/health` trava, apague o D1 local:

```powershell
Remove-Item -Recurse -Force "D:\Projectos Flutter\Novo\workers\.wrangler\state"
cd workers
npm run db:migrate:local
npm run dev
```

---

## Passo 2 — Firewall Windows

PowerShell **como Administrador**:

```powershell
cd "D:\Projectos Flutter\Novo\scripts"
.\allow-kiamicloud-api-firewall.ps1
```

Volte a testar no telemovel: `http://192.168.100.170:8787/health`

---

## Passo 3 — Wi-Fi

- Telemovel em **Wi-Fi** (nao dados moveis)
- Mesma rede que o PC
- Desligar VPN no PC e no telemovel
- Alguns routers tem **isolamento de clientes** — impede telemovel ver o PC (testar noutra rede ou USB abaixo)

Confirme o IP do servidor (ZimaBlade): painel ZimaOS ou router → IPv4 (ex. `192.168.100.170`).

---

## Passo 4 — Solucao USB (recomendada se Wi-Fi falhar)

Com telemovel ligado por **USB** e depuracao activa:

```powershell
cd "D:\Projectos Flutter\Novo\scripts"
.\setup-android-api-usb.ps1
```

Altere `KIAMI_LOCAL_API_URL` para `http://127.0.0.1:8787` ou edite `bladeStaticHost` em:

`packages/kiamicloud_core/lib/src/constants/kiami_constants.dart`

Reinstale a app:

```powershell
cd apps\local\mobile
flutter build apk --release
flutter install --release
```

O `adb reverse` faz o `127.0.0.1` do telemovel apontar para o PC — **nao precisa de Wi-Fi**.

---

## Resumo

| Teste | Onde | Se falhar |
|-------|------|-----------|
| curl 127.0.0.1:8787/health | PC | Reiniciar `npm run dev` |
| curl 192.168.100.170:8787/health | PC | Firewall / IP errado |
| browser 192.168.100.170:8787/health | Telemovel | Firewall / Wi-Fi / isolamento AP |
| adb reverse + 127.0.0.1 | Telemovel USB | Ver script USB |
