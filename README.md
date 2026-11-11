# Secret Territory

A mobile-first private-corner experience for Mukku & Khushi.

## What's included
- Luxury dark-romantic UI with responsive glass panels, ambient motion and touch feedback
- Existing image assets and core sections preserved
- Sweet Cravings, Our Chemistry, Video Call Dares and an expanded Private Vault
- Surprise-me dare, private note composer and local selection history
- WhatsApp click-to-chat handoff with digit-only international phone validation and URL-encoded messages

## WhatsApp setup
The two destination numbers are currently configured near the top of the inline script in `index.html`:
- `MUKKU_NUMBER`
- `KHUSHI_NUMBER`

They must be full international numbers using digits only (India country code 91, no +, spaces or leading 0). Each number must have an active WhatsApp account. The page opens a pre-filled draft; the user still presses Send in WhatsApp. If a new tab is blocked, the page falls back to navigating the current tab.

## Shared data status
History is still saved on the current browser/device by default. The UI contains a Supabase REST integration hook, but **shared sync is not enabled by default**. Do not enable it with public/anonymous read-write database policies: the repository is public and that would expose private moments. To finish secure cross-device sync, configure Supabase Auth for both people and authenticated-only Row Level Security, then wire the signed-in user's access token into the REST requests. Never put a Supabase service-role key in this repository.

## Important security note
This is a static front-end. The current passcodes are in browser JavaScript and are only a casual screen gate, not real authentication. Anyone who can inspect the public source can discover them. Do not store sensitive/private content here until real authentication and server-side authorization are added.

## Deploy
GitHub Pages can serve this static site directly from the repository root. Keep the image assets beside `index.html`.
