/**

 * Consola local KiamiCloud — gere wrangler dev, testes e rede.

 * Uso: npm start → http://127.0.0.1:3847

 */

const express = require('express');

const path = require('path');

const fs = require('fs');

const { exec, spawn } = require('child_process');

const os = require('os');

const http = require('http');



const ROOT = path.resolve(__dirname, '../..');

const WORKERS_DIR = path.join(ROOT, 'workers');

const SCRIPTS_DIR = path.join(ROOT, 'scripts');

const API_PORT = 8787;

const GUI_PORT = 3847;

const DEFAULT_API_HOST = '127.0.0.1';

const DEV_LOG = path.join(os.tmpdir(), 'kiamicloud-wrangler-dev.log');



const app = express();

app.use(express.json());

app.use(express.static(path.join(__dirname, 'public')));



let devProcess = null;

let devLogStream = null;

let startingDev = false;



function runPs(command, opts = {}) {

  return new Promise((resolve) => {

    exec(

      `powershell -NoProfile -ExecutionPolicy Bypass -Command "${command.replace(/"/g, '\\"')}"`,

      { cwd: opts.cwd || ROOT, timeout: opts.timeout || 60000, ...opts },

      (err, stdout, stderr) => {

        resolve({

          ok: !err,

          stdout: (stdout || '').trim(),

          stderr: (stderr || '').trim(),

          error: err?.message,

        });

      },

    );

  });

}



function runScript(scriptName, quiet = false) {

  const scriptPath = path.join(SCRIPTS_DIR, scriptName);

  const quietFlag = quiet ? ' -Quiet' : '';

  return runPs(`& '${scriptPath.replace(/'/g, "''")}'${quietFlag}`);

}



function fetchApi(pathname, host, timeoutMs = 4000) {

  return new Promise((resolve) => {

    const url = `http://${host}:${API_PORT}${pathname}`;

    const start = Date.now();

    const req = http.get(url, { timeout: timeoutMs }, (res) => {

      let body = '';

      res.on('data', (c) => (body += c));

      res.on('end', () => {

        try {

          resolve({

            ok: res.statusCode === 200,

            status: res.statusCode,

            data: JSON.parse(body),

            ms: Date.now() - start,

          });

        } catch {

          resolve({ ok: false, status: res.statusCode, raw: body, ms: Date.now() - start });

        }

      });

    });

    req.setTimeout(timeoutMs, () => {

      req.destroy();

      resolve({ ok: false, error: 'timeout', ms: timeoutMs });

    });

    req.on('error', (e) =>

      resolve({ ok: false, error: e.message, ms: Date.now() - start }),

    );

  });

}



async function timedFetch(pathname, host, timeoutMs = 4000) {

  return fetchApi(pathname, host, timeoutMs);

}



async function waitForPing(host, maxMs = 90000) {

  const started = Date.now();

  while (Date.now() - started < maxMs) {

    const ping = await timedFetch('/health/ping', host, 3000);

    if (ping.ok) return ping;

    await new Promise((r) => setTimeout(r, 2000));

  }

  return { ok: false, error: 'timeout', ms: maxMs };

}



function getLocalIps() {

  const ips = [];

  for (const ifaces of Object.values(os.networkInterfaces())) {

    for (const iface of ifaces || []) {

      if (iface.family === 'IPv4' && !iface.internal) {

        ips.push(iface.address);

      }

    }

  }

  return [...new Set(ips)];

}



async function portStatus() {

  const r = await runPs(

    `(Get-NetTCPConnection -LocalPort ${API_PORT} -State Listen -ErrorAction SilentlyContinue | Measure-Object).Count`,

  );

  const listeners = parseInt(r.stdout, 10) || 0;

  const workerd = await runPs(

    `(Get-Process -Name workerd -ErrorAction SilentlyContinue | Measure-Object).Count`,

  );

  return {

    listeners,

    workerdCount: parseInt(workerd.stdout, 10) || 0,

    devProcessRunning: devProcess != null && !devProcess.killed,

    startingDev,

    devLog: DEV_LOG,

  };

}



function getPreferredLanIp() {

  const ips = getLocalIps();

  const bladeLike =
    ips.find((ip) => ip === '192.168.100.170') ||
    ips.find((ip) => ip.startsWith('192.168.100.'));

  return bladeLike || ips[0] || '127.0.0.1';

}



function closeDevLog() {

  if (devLogStream) {

    try {

      devLogStream.end();

    } catch {

      /* ignore */

    }

    devLogStream = null;

  }

}



function stopDevProcess() {

  if (devProcess && !devProcess.killed) {

    try {

      if (process.platform === 'win32') {

        spawn('taskkill', ['/pid', String(devProcess.pid), '/T', '/F'], {

          shell: true,

          stdio: 'ignore',

        });

      } else {

        devProcess.kill('SIGTERM');

      }

    } catch {

      /* ignore */

    }

  }

  devProcess = null;

  closeDevLog();

}



async function startDevProcess({ migrate = false } = {}) {

  if (startingDev) {

    return { ok: false, message: 'API ja esta a arrancar — aguarde.' };

  }



  const status = await portStatus();

  if (status.listeners > 0 && status.workerdCount > 0 && !devProcess) {

    const ping = await timedFetch('/health/ping', '127.0.0.1', 3000);

    if (ping.ok) {

      return {

        ok: false,

        message: 'API ja esta a responder. Use Reinicio limpo se houver problemas.',

        processes: status,

        ping,

      };

    }

  }



  if (devProcess && !devProcess.killed) {

    return { ok: false, message: 'Consola ja iniciou um processo npm run dev.' };

  }



  startingDev = true;

  try {

    if (migrate) {

      const mig = await runPs(`npm run db:migrate:local`, {

        cwd: WORKERS_DIR,

        timeout: 120000,

      });

      if (!mig.ok) {

        return {

          ok: false,

          message: 'Erro ao aplicar migracoes D1.',

          detail: mig.stdout || mig.stderr || mig.error,

        };

      }

    }



    closeDevLog();

    devLogStream = fs.createWriteStream(DEV_LOG, { flags: 'a' });

    devLogStream.write(`\n--- ${new Date().toISOString()} npm run dev ---\n`);



    devProcess = spawn('npm', ['run', 'dev'], {

      cwd: WORKERS_DIR,

      shell: true,

      stdio: ['ignore', devLogStream, devLogStream],

    });



    devProcess.on('exit', () => {

      devProcess = null;

      closeDevLog();

    });



    const ping = await waitForPing('127.0.0.1', 90000);

    return {

      ok: ping.ok,

      message: ping.ok

        ? 'API iniciada. Teste /health/ping.'

        : 'Processo iniciado mas API ainda nao responde — veja o log ou aguarde.',

      ping,

      log: DEV_LOG,

    };

  } finally {

    startingDev = false;

  }

}



app.get('/api/network', (_req, res) => {

  const ips = getLocalIps();

  const preferredHost = getPreferredLanIp();

  res.json({

    ips,

    preferredHost,

    defaultHost: DEFAULT_API_HOST,

    apiPort: API_PORT,

    guiPort: GUI_PORT,

    devLog: DEV_LOG,

    urls: [

      `http://127.0.0.1:${API_PORT}/health/ping`,

      `http://${preferredHost}:${API_PORT}/health/ping`,

    ],

  });

});



app.get('/api/processes', async (_req, res) => {

  res.json(await portStatus());

});



app.get('/api/status', async (req, res) => {

  const host = req.query.host || '127.0.0.1';

  const processes = await portStatus();

  const ping = await timedFetch('/health/ping', host, 5000);

  const health = ping.ok ? await timedFetch('/health', host, 8000) : { ok: false, skipped: true };

  res.json({ host, processes, ping, health });

});



app.get('/api/dev-log', (_req, res) => {

  try {

    if (!fs.existsSync(DEV_LOG)) {

      return res.type('text/plain').send('(sem log ainda)');

    }

    const tail = fs.readFileSync(DEV_LOG, 'utf8').slice(-12000);

    res.type('text/plain').send(tail);

  } catch (e) {

    res.status(500).json({ ok: false, error: e.message });

  }

});



app.post('/api/stop', async (_req, res) => {

  stopDevProcess();

  const r = await runScript('restart-api-clean.ps1', true);

  res.json({ ok: true, message: 'Processos parados.', detail: r.stdout || r.stderr });

});



app.post('/api/start', async (_req, res) => {

  const result = await startDevProcess({ migrate: true });

  res.json(result);

});



app.post('/api/restart', async (_req, res) => {

  stopDevProcess();

  await runScript('restart-api-clean.ps1', true);

  await new Promise((r) => setTimeout(r, 1500));

  const result = await startDevProcess({ migrate: false });

  const processes = await portStatus();

  res.json({

    ...result,

    message: result.ok ? 'Reinicio concluido.' : result.message,

    processes,

  });

});



app.post('/api/firewall', async (_req, res) => {

  const scriptPath = path.join(SCRIPTS_DIR, 'allow-kiamicloud-api-firewall.ps1');

  const r = await runPs(

    `Start-Process powershell -Verb RunAs -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File "${scriptPath}"' -Wait`,

    { timeout: 120000 },

  );

  res.json({

    ok: r.ok,

    message: r.ok

      ? 'Script firewall executado (janela Admin).'

      : 'Nao foi possivel executar como Admin.',

    detail: r.stdout || r.stderr || r.error,

  });

});



app.post('/api/adb-reverse', async (_req, res) => {

  const r = await runScript('setup-android-api-usb.ps1');

  res.json({

    ok: r.ok,

    message: r.ok ? 'adb reverse configurado.' : 'Falha no adb.',

    detail: r.stdout || r.stderr,

  });

});



app.post('/api/migrate-local', async (_req, res) => {

  const mig = await runPs(`npm run db:migrate:local`, { cwd: WORKERS_DIR, timeout: 120000 });

  res.json({

    ok: mig.ok,

    message: mig.ok

      ? 'Migracoes D1 locais aplicadas.'

      : 'Erro ao aplicar migracoes.',

    detail: mig.stdout || mig.stderr || mig.error,

  });

});



app.post('/api/reset-d1', async (_req, res) => {

  const statePath = path.join(WORKERS_DIR, '.wrangler', 'state');

  const r = await runPs(

    `Remove-Item -Recurse -Force '${statePath.replace(/'/g, "''")}' -ErrorAction SilentlyContinue; Write-Output 'ok'`,

    { cwd: WORKERS_DIR },

  );

  const mig = await runPs(`npm run db:migrate:local`, { cwd: WORKERS_DIR, timeout: 120000 });

  res.json({

    ok: mig.ok,

    message: mig.ok ? 'D1 local resetada e migracoes aplicadas.' : 'Erro nas migracoes.',

    detail: mig.stdout || mig.stderr,

  });

});



app.listen(GUI_PORT, '127.0.0.1', () => {

  console.log('');

  console.log('  KiamiCloud — Consola API');

  console.log(`  http://127.0.0.1:${GUI_PORT}`);

  console.log(`  Log wrangler: ${DEV_LOG}`);

  console.log('');

});



process.on('exit', () => {

  stopDevProcess();

});


