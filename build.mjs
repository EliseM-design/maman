// Construit dist/index.html à partir de src/app.html.
// Ajoute l'en-tête HTML, la configuration Supabase (lue dans les variables d'environnement)
// et la bibliothèque supabase-js. Sans configuration, l'application fonctionne en local
// (données gardées dans le navigateur), ce qui permet de la tester.
import { readFileSync, writeFileSync, mkdirSync, copyFileSync, existsSync, readdirSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

// Lecture d'un éventuel fichier .env (utile en local uniquement)
const envFile = join(root, '.env');
if (existsSync(envFile)) {
  for (const line of readFileSync(envFile, 'utf8').split(/\r?\n/)) {
    const m = line.match(/^\s*([A-Z0-9_]+)\s*=\s*(.*)\s*$/);
    if (m && !process.env[m[1]]) process.env[m[1]] = m[2].replace(/^["']|["']$/g, '');
  }
}

const url = process.env.SUPABASE_URL || process.env.NEXT_PUBLIC_SUPABASE_URL || '';
const key = process.env.SUPABASE_ANON_KEY || process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY
  || process.env.SUPABASE_PUBLISHABLE_KEY || process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY || '';

if (/service_role/.test(key)) {
  console.error('ERREUR : la clé fournie est la clé "service_role". Utilisez la clé "anon" (publique).');
  process.exit(1);
}

const app = readFileSync(join(root, 'src', 'app.html'), 'utf8');
const cut = app.indexOf('<div class="app">');
if (cut < 0) throw new Error('src/app.html : bloc <div class="app"> introuvable');
const headPart = app.slice(0, cut);
const bodyPart = app.slice(cut);

const out = join(root, 'dist');
mkdirSync(out, { recursive: true });

let sbScript = '';
if (url && key) {
  const umd = join(root, 'node_modules', '@supabase', 'supabase-js', 'dist', 'umd');
  for (const f of readdirSync(umd)) if (f.endsWith('.js')) copyFileSync(join(umd, f), join(out, f));
  sbScript = `<script>window.MP_CONFIG=${JSON.stringify({ supabaseUrl: url, supabaseKey: key })};</script>\n<script src="/supabase.js"></script>`;
  console.log(`Supabase configuré : ${url}`);
} else {
  console.warn('Attention : SUPABASE_URL / SUPABASE_ANON_KEY absents. Version locale (données dans le navigateur).');
}

const html = `<!doctype html>
<html lang="fr">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1,viewport-fit=cover">
<meta name="robots" content="noindex,nofollow">
<meta name="theme-color" content="#183C32">
<link rel="icon" href="data:image/svg+xml,${encodeURIComponent('<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48"><rect width="48" height="48" rx="11" fill="#183C32"/><g fill="none" stroke="#F4F1EA" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round"><path d="M10 23 24 11l14 12"/><path d="M14 20v16h20V20"/><path d="M21 36v-8h6v8"/></g></svg>')}">
<style>:root{padding-top:env(safe-area-inset-top,0px);padding-bottom:env(safe-area-inset-bottom,0px)}body{margin:0}img{max-width:100%}[hidden]{display:none!important}</style>
${headPart.trim()}
${sbScript}
</head>
<body>
${bodyPart.trim()}
</body>
</html>
`;
writeFileSync(join(out, 'index.html'), html);
console.log('dist/index.html construit.');
