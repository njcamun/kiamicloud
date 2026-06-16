const $ = (id) => document.getElementById(id);
const API_PORT = 8787;
let lastFetchErrorAt = 0;

function log(msg) {
  const el = $('actionLog');
  const line = `[${new Date().toLocaleTimeString('pt-PT')}] ${msg}\n`;
  el.textContent = line + el.textContent;
}

async function api(path, opts = {}) {
  const timeoutMs = opts.timeoutMs ?? (opts.method === 'POST' ? 120000 : 15000);
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    const res = await fetch(path, {
      headers: { 'Content-Type': 'application/json' },
      signal: controller.signal,
      ...opts,
    });
    clearTimeout(timer);
    if (!res.ok) {
      throw new Error(`HTTP ${res.status}`);
    }
    return res.json();
  } catch (e) {
    clearTimeout(timer);
    if (e.name === 'AbortError') {
      throw new Error('Tempo esgotado — a operacao demorou demasiado.');
    }
    throw e;
  }
}

function host() {
  const manual = $('apiHost').value.trim();
  const selected = $('apiHostSelect').value;
  return manual || selected || '127.0.0.1';
}

function syncHostFromSelect() {
  const sel = $('apiHostSelect');
  if (sel.value) $('apiHost').value = sel.value;
}

function fillHostSelect(ips, preferred) {
  const sel = $('apiHostSelect');
  const options = [
    { value: '127.0.0.1', label: '127.0.0.1 (este PC)' },
    ...ips.map((ip) => ({ value: ip, label: `${ip} (LAN)` })),
  ];
  sel.innerHTML = options
    .map((o) => `<option value="${o.value}">${o.label}</option>`)
    .join('');
  const pick = preferred && options.some((o) => o.value === preferred) ? preferred : ips[0] || '127.0.0.1';
  sel.value = pick;
  $('apiHost').value = pick;
}

function setBusy(busy) {
  document.querySelectorAll('button').forEach((b) => {
    b.disabled = busy;
  });
}

function renderMetrics(data) {
  const p = data.processes || {};
  const ping = data.ping || {};
  const health = data.health || {};

  $('metrics').innerHTML = `
    <div class="metric">
      <div class="label">workerd activos</div>
      <div class="value ${p.workerdCount > 1 ? 'bad' : 'ok'}">${p.workerdCount ?? '—'}</div>
    </div>
    <div class="metric">
      <div class="label">Porta ${API_PORT} (listen)</div>
      <div class="value ${p.listeners > 1 ? 'bad' : p.listeners === 1 ? 'ok' : 'bad'}">${p.listeners ?? 0}</div>
    </div>
    <div class="metric">
      <div class="label">/health/ping (${data.host})</div>
      <div class="value ${ping.ok ? 'ok' : 'bad'}">${ping.ok ? `${ping.ms} ms` : ping.error || 'falhou'}</div>
    </div>
    <div class="metric">
      <div class="label">/health</div>
      <div class="value ${health.ok ? 'ok' : health.skipped ? '' : 'bad'}">${
        health.skipped ? '—' : health.ok ? `${health.ms} ms` : health.error || 'falhou'
      }</div>
    </div>
  `;

  const pill = $('globalStatus');
  if (ping.ok) {
    pill.textContent = 'API online';
    pill.className = 'status-pill ok';
  } else if (p.listeners > 0) {
    pill.textContent = 'Porta ocupada — sem resposta';
    pill.className = 'status-pill warn';
  } else {
    pill.textContent = 'API offline';
    pill.className = 'status-pill bad';
  }

  if (p.workerdCount > 1) {
    log('AVISO: varios workerd — use Reinicio limpo.');
  }

  $('statusLog').textContent = JSON.stringify(data, null, 2);
}

async function refreshStatus() {
  setBusy(true);
  try {
    const data = await api(`/api/status?host=${encodeURIComponent(host())}`);
    renderMetrics(data);
    lastFetchErrorAt = 0;
  } catch (e) {
    const now = Date.now();
    if (now - lastFetchErrorAt > 30000) {
      lastFetchErrorAt = now;
      log(
        `Erro estado: ${e.message} — a consola parou? Mantenha aberta a janela do Iniciar-API-GUI.bat (porta 3847).`,
      );
    }
    const pill = $('globalStatus');
    pill.textContent = 'Consola offline';
    pill.className = 'status-pill bad';
  } finally {
    setBusy(false);
  }
}

function renderNetwork(net) {
  $('ipList').innerHTML = (net.ips || [])
    .map((ip) => `<li>${ip}</li>`)
    .join('');

  const h = host();
  const urls = [
    `http://127.0.0.1:${API_PORT}/health/ping`,
    `http://${h}:${API_PORT}/health/ping`,
    `http://127.0.0.1:${API_PORT}/health`,
    `http://${h}:${API_PORT}/health`,
  ];

  $('urlList').innerHTML = urls
    .map(
      (u) => `
    <div class="url-item">
      <a href="${u}" target="_blank" rel="noopener">${u}</a>
      <button type="button" class="btn secondary" data-copy="${u}">Copiar</button>
    </div>`,
    )
    .join('');

  document.querySelectorAll('[data-copy]').forEach((btn) => {
    btn.addEventListener('click', () => {
      navigator.clipboard.writeText(btn.dataset.copy);
      log(`Copiado: ${btn.dataset.copy}`);
    });
  });
}

async function loadNetwork() {
  try {
    const net = await api('/api/network');
    fillHostSelect(net.ips || [], net.preferredHost);
    renderNetwork(net);
  } catch (e) {
    log(`Erro rede: ${e.message}`);
  }
}

async function action(name, path) {
  setBusy(true);
  log(`${name}…`);
  try {
    const r = await api(path, { method: 'POST', timeoutMs: 180000 });
    log(r.message || JSON.stringify(r));
    if (r.detail) log(r.detail);
    if (r.log) log(`Log wrangler: ${r.log}`);
    for (let i = 0; i < 20; i += 1) {
      await refreshStatus();
      const pill = $('globalStatus');
      if (pill?.textContent === 'API online') break;
      await new Promise((resolve) => setTimeout(resolve, 3000));
    }
    await loadNetwork();
    return r;
  } catch (e) {
    log(`Erro: ${e.message}`);
  } finally {
    setBusy(false);
  }
}

$('btnRefresh').addEventListener('click', refreshStatus);
$('btnRestart').addEventListener('click', () => action('Reinicio limpo', '/api/restart'));
$('btnStart').addEventListener('click', () => action('Iniciar API', '/api/start'));
$('btnStop').addEventListener('click', () => action('Parar API', '/api/stop'));
$('btnFirewall').addEventListener('click', () => action('Firewall', '/api/firewall'));
$('btnAdb').addEventListener('click', () => action('adb reverse', '/api/adb-reverse'));
$('btnMigrate').addEventListener('click', () => action('Migracoes D1', '/api/migrate-local'));
$('btnResetD1').addEventListener('click', () => {
  if (confirm('Apagar D1 local (.wrangler/state) e reaplicar migracoes?')) {
    action('Reset D1', '/api/reset-d1');
  }
});

$('btnTestPing').addEventListener('click', async () => {
  setBusy(true);
  const r = await timedFetch(host(), '/health/ping');
  log(r.ok ? `ping OK (${r.ms} ms)` : `ping falhou: ${r.error}`);
  setBusy(false);
  refreshStatus();
});

$('btnTestHealth').addEventListener('click', async () => {
  setBusy(true);
  const r = await timedFetch(host(), '/health');
  log(r.ok ? `health OK (${r.ms} ms)` : `health falhou: ${r.error}`);
  setBusy(false);
  refreshStatus();
});

$('btnOpenPing').addEventListener('click', () => {
  window.open(`http://127.0.0.1:${API_PORT}/health/ping`, '_blank');
});

$('apiHostSelect').addEventListener('change', syncHostFromSelect);

async function timedFetch(h, path) {
  const start = Date.now();
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 5000);
  try {
    const res = await fetch(`http://${h}:${API_PORT}${path}`, {
      signal: controller.signal,
    });
    clearTimeout(timer);
    const data = await res.json();
    return { ok: res.ok, ms: Date.now() - start, data };
  } catch (e) {
    clearTimeout(timer);
    return { ok: false, ms: Date.now() - start, error: e.message };
  }
}

loadNetwork();
refreshStatus();
setInterval(refreshStatus, 15000);
