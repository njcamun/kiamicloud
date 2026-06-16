import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const root = path.join(path.dirname(fileURLToPath(import.meta.url)), '..');
const html = fs.readFileSync(path.join(root, 'blade-console', 'index.html'), 'utf8');
const out = `/** Gerado por npm run blade-console:embed — não editar manualmente. */\nexport const BLADE_CONSOLE_HTML = ${JSON.stringify(html)};\n`;
fs.writeFileSync(path.join(root, 'src', 'blade-console', 'html.ts'), out);
console.log('blade-console/html.ts updated');
