'use strict';

const fs = require('node:fs');

const url = process.env.SUPABASE_URL;
const anonKey = process.env.SUPABASE_ANON_KEY || process.env.SUPABASE_PUBLISHABLE_KEY;
const coupleId = process.env.SUPABASE_COUPLE_ID;

if (!url || !anonKey || !coupleId) {
  throw new Error('Set SUPABASE_URL, SUPABASE_ANON_KEY (or SUPABASE_PUBLISHABLE_KEY), and SUPABASE_COUPLE_ID in the hosting build environment.');
}
if (!/^https:\/\/[a-z0-9-]+\.supabase\.co\/?$/i.test(url)) {
  throw new Error('SUPABASE_URL must be the HTTPS URL of your Supabase project.');
}
if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-8][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(coupleId)) {
  throw new Error('SUPABASE_COUPLE_ID must be a valid UUID.');
}

const config = { url: url.replace(/\/$/, ''), anonKey, coupleId };
fs.writeFileSync('config.js', 'window.SECRET_TERRITORY_CONFIG = ' + JSON.stringify(config) + ';\n', { encoding: 'utf8', mode: 0o644 });
console.log('Generated config.js for the static site build. The publishable/anon key is intended for browser use; RLS must remain enabled.');
