# Secret Territory — Just Us

A mobile-first private world for Mukku & Khushi, built on a dark romantic palette with restrained personal accents: sea green for Khushi and deep ocean blue for Mukku.

## Experience included
- Cinematic dark-romance UI, burgundy ambient lighting, glass panels, responsive touch-friendly cards and reduced-motion support
- Mukku's deep-ocean-blue profile accent and Khushi's sea-green profile accent, used selectively for active states and details
- Preserved Sweet Cravings, Our Chemistry, Video Call Dares, Private Vault and WhatsApp click-to-chat flow
- Love Quiz with per-person answers and a playful match score
- This or That, Mood Match, Daily Mission and Date Night Wheel
- Random Surprise Box
- Memory Lane, sealed letters with optional unlock dates, and a relationship countdown
- Secret Chat with shared realtime messages and optional browser notifications while the site is open
- Open When letters with future unlock dates
- Our Scrapbook with compressed photos in a private Supabase Storage bucket
- Our Wrapped relationship activity recap and live two-person presence indicator
- User-triggered JSON backup and restore for saved entries
- Authenticated Mukku / Khushi identity and recent activity history

## WhatsApp
The site opens the generic WhatsApp recipient chooser with a pre-filled message. It does not embed recipient phone numbers or promise automatic Mukku/Khushi routing. The user chooses the recipient and sends the message in WhatsApp. Android decides which WhatsApp installation handles the link; a website cannot force Vivo's cloned-app package. If a browser blocks the new tab, the site stays open and asks the user to allow pop-ups before retrying.

## Authentication and privacy
There is no client-side passcode or local-preview unlock. The site remains locked until Supabase Auth is configured and an authenticated user is found in the configured couple's membership rows. The Private Vault is part of that authenticated area, not a second client-side password gate.

## Secure shared cloud setup (Supabase)

Shared cloud sync requires Supabase Auth and the membership-based RLS policies below. It is intentionally not active until you configure a Supabase project.

1. Create a Supabase project. The repository now fails closed: without valid Supabase settings, the login screen stays locked and there is no local passcode fallback.
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
7. Sign in on both devices. The app reads/writes shared entries only through the authenticated Supabase client. Realtime updates refresh the shared view. Cloud data stays in memory rather than browser localStorage. Sign-out clears the in-memory view and any legacy st2-* cache. Failed writes retry in memory while the tab remains open or when connectivity returns; a reload/close discards unsynced pending writes, so wait for the Shared · Live sync status before leaving. The same SQL also creates a private scrapbook bucket with couple-membership storage policies.

**Never put a Supabase service-role key or secret key in `config.js`, GitHub, or browser code.** Keep the two membership rows restricted to the intended accounts. The RLS policies allow a member to read entries for their couple and create/delete only their own entries.

### What is shared
Once configured, moments, quiz picks, This or That picks, mood selections, missions, date ideas, countdown dates, surprises, memories, letters, Open When notes and chat messages are written to `shared_entries`. Scrapbook images are stored in the private `secret-territory-memories` bucket and referenced by shared entries. Backup files are exported/imported on the current device; keep a separate copy somewhere safe. Browser notifications are foreground/background-tab notifications while the site is open, not guaranteed push notifications after the browser is fully closed. The live presence indicator uses a private Realtime channel restricted to the matching couple membership and requires both members to be signed in at the same time.

## Deployment and safety notes
- GitHub Pages can serve the static site from the repository root. Keep the original PNG assets beside `index.html`.
- `config.js` is git-ignored. Do not commit it unless you intentionally choose to publish the public Supabase URL, publishable key and couple UUID; never publish service credentials.
- There are no client-side passcodes. The Vault is available only after Supabase Auth succeeds; the Surprise Box reveals a random prompt rather than validating a public code.
- Open When dates control the in-app reveal UI; because the shared-entry database serves both approved members, treat future-dated letter text as visible to either authenticated member through the underlying data. It is a thoughtful reveal, not cryptographic time-locking.
- Test login, both accounts, RLS, storage policies, live updates, WhatsApp chooser, scrapbook uploads, memory backup/restore and mobile layout before treating the site as production-ready.
