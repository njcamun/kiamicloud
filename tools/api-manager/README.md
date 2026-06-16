# KiamiCloud — Consola API (GUI)

Interface web local para gerir `wrangler dev`, testes de rede e problemas comuns (workerd duplicado, firewall, D1).

## Iniciar

```powershell
cd "D:\Projectos Flutter\Novo\tools\api-manager"
npm install
npm start
```

Abre no browser: **http://127.0.0.1:3847**

Ou duplo-clique na raiz do projecto:

- **`Iniciar-API-GUI.bat`** (recomendado)
- `scripts/start-api-gui.bat`
- `scripts/launch-api-manager.cmd` (legado)

## Funcionalidades

| Botão | Acção |
|--------|--------|
| **Reinício limpo + iniciar** | Mata `workerd`, liberta porta 8787, inicia `npm run dev` |
| **Parar API** | Para processos na porta 8787 |
| **Testar /health/ping** | Teste rápido (sem D1) |
| **Firewall (Admin)** | Abre regra porta 8787 |
| **adb reverse** | USB → API no PC |
| **Reset D1 local** | Apaga `.wrangler/state` e migra de novo |

## Fluxo recomendado

1. Abrir consola → **Reinício limpo + iniciar**
2. Estado verde em **/health/ping**
3. No telemóvel (Wi‑Fi): testar URL com o IP do Blade (`192.168.100.170`)
4. Se não abrir → **Firewall** → testar de novo

**Não** correr `npm run dev` manualmente ao mesmo tempo que a consola inicia a API.

## Notas

- A consola corre na porta **3847** (só localhost). **Mantenha a janela do terminal aberta** — se fechar, o browser mostra `Failed to fetch`.
- A API continua na porta **8787**.
- Log do wrangler (arranque via consola): `%TEMP%\kiamicloud-wrangler-dev.log`
- Para API no **PC**, teste com host **127.0.0.1**. Use IP LAN só para telemóvel na mesma Wi‑Fi.
- Ver também `docs/REDE_API_LOCAL.md`.
