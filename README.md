# Secret Territory — Just Us

A mobile-first private world for Mukku & Khushi, built on a dark romantic palette with restrained personal accents: sea green for Khushi and deep ocean blue for Mukku.

## Experience included
- Cinematic dark-romance UI, burgundy ambient lighting, glass panels, responsive touch-friendly cards and reduced-motion support
- Mukku's deep-ocean-blue profile accent and Khushi's sea-green profile accent, used selectively for active states and details
- Preserved Sweet Cravings, Our Chemistry, Video Call Dares, Private Vault and WhatsApp click-to-chat flow
- Love Quiz with per-person answers and a playful match score
- This or That, Mood Match, Daily Mission and Date Night Wheel
- Secret-code Surprise Box
- Memory Lane, sealed letters with optional unlock dates, and a relationship countdown
- Secret Chat with shared realtime messages and optional browser notifications while the site is open
- Open When letters with future unlock dates
- Our Scrapbook with compressed photos; private Supabase Storage in cloud mode and local-device fallback in preview mode
- Our Wrapped relationship activity recap and live two-person presence indicator
- Local JSON backup and restore for saved entries
- Mukku / Khushi profile switch and recent activity history

## WhatsApp
The destination numbers are configured in the inline script in `index.html`:
- `targetNumber()` maps Mukku to Khushi and Khushi to Mukku.
- Numbers must be full international digits (India country code 91; no +, spaces or leading 0).
- The site opens a pre-filled draft; the user still presses Send in WhatsApp.
- Android may show an account/app chooser when both WhatsApp and an App Clone are installed. The user can select the clone and choose Always if Android offers it. A website cannot reliably force Vivo's cloned-app package.

## Local preview
If `config.js` is absent or incomplete, the site runs in local preview mode with the existing convenience passcode. Local preview is not secure authentication; a front-end passcode can be discovered from the public source. Do not treat this mode as private cloud access.

## Secure shared cloud setup (Supabase)

Shared cloud sync requires Supabase Auth and the membership-based RLS policies below. It is intentionally not active until you configure a Supabase project.

1. Create a Supabase project.
2. In Authentication, enable Email + Password. Create the Mukku and Khushi accounts from the site's login screen. Confirm their emails if email confirmation is enabled.
3. Run [`supabase/schema.sql`](supabase/schema.sql) in the Supabase SQL Editor.
4. In Supabase Authentication → Users, copy both users' UUIDs. Generate one random UUID for the couple.
5. In the SQL Editor, insert the two membership rows using the same couple UUID:
   ```sql
   insert into public.couple_members (couple_id, user_id, display_name) values
   ('YOUR_SHARED_COUPLE_UUID', 'MUKKU_AUTH_USER_UUID', 'Mukku'),
   ('YOUR_SHARED_COUPLE_UUID', 'KHUSHI_AUTH_USER_UUID', 'Khushi');
   ```
6. Copy `config.example.js` to `config.js` and fill in the project URL, publishable/anon key, and that same couple UUID. Deploy `config.js` alongside `index.html` on your static host. The publishable/anon key is designed for browser use; RLS is the security boundary.
7. Sign in on both devices. The app reads/writes shared entries only through the authenticated Supabase client. Realtime updates refresh the shared view. The same SQL also creates a private scrapbook bucket with couple-membership storage policies.

**Never put a Supabase service-role key or secret key in `config.js`, GitHub, or browser code.** Keep the two membership rows restricted to the intended accounts. The RLS policies allow a member to read entries for their couple and create/delete only their own entries.

### What is shared
Once configured, moments, quiz picks, This or That picks, mood selections, missions, date ideas, surprises, memories, letters, Open When notes and chat messages are written to `shared_entries`. Scrapbook images are stored in the private `secret-territory-memories` bucket and referenced by shared entries. Backup files are exported/imported on the current device; keep a separate copy somewhere safe. Browser notifications are foreground/background-tab notifications while the site is open, not guaranteed push notifications after the browser is fully closed. The live presence indicator requires both members to be signed in at the same time.

## Deployment and safety notes
- GitHub Pages can serve the static site from the repository root. Keep the original PNG assets beside `index.html`.
- `config.js` is git-ignored. Do not commit it unless you intentionally choose to publish the public Supabase URL, publishable key and couple UUID; never publish service credentials.
- Secret Vault and Surprise Box codes in a static client are playful unlocks, not security controls.
- Open When dates control the in-app reveal UI; because the shared-entry database serves both approved members, treat future-dated letter text as visible to either authenticated member through the underlying data. It is a thoughtful reveal, not cryptographic time-locking.
- Test login, both accounts, RLS, storage policies, live updates, WhatsApp chooser, scrapbook uploads, memory backup/restore and mobile layout before treating the site as production-ready.
