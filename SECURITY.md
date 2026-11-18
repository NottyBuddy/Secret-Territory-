# Security notes

## Current public source

The current application source contains no local unlock passcodes and no WhatsApp recipient phone numbers. The site fails closed when Supabase configuration is missing. A browser-visible Supabase publishable/anon key is expected; it is not an administrative secret. Never use a service-role key or Supabase secret key in this static site.

## Previously published phone numbers

Earlier repository revisions and stale branch history may still contain phone numbers that were removed from the current page. A normal follow-up commit cannot erase those values from Git history. Deleting an old branch reference is not sufficient if the commits remain reachable from the default branch, a pull request, a fork, or a clone.

If the numbers are sensitive, consider them exposed and decide whether to change them. A full historical scrub requires a coordinated Git history rewrite (for example, git-filter-repo with a replacement file), force-updating every affected branch and tag, then asking collaborators to re-clone. GitHub cached views, forks, and existing clones may retain old objects. Do not attempt this casually: it changes commit IDs and can disrupt open work. Take a backup and coordinate the rewrite with repository collaborators first.

## Supabase deployment

Use only the browser-safe publishable/anon key with the membership-based RLS policies enabled. Store deployment values as hosting environment variables and generate the ignored config.js during the build. Keep service-role/secret keys exclusively in a trusted server-side environment.

## Verification before private use

1. Sign in as Mukku and confirm only the intended couple data is visible.
2. Sign in as Khushi and confirm the same couple data is visible.
3. Create a third test Auth user without a couple_members row. It must remain at the lock screen; direct reads should return no couple rows and inserts should be rejected by RLS.
4. Attempt to read a different couple_id and upload/download a storage object under another couple's folder. Both must be denied.
5. Verify the browser status reaches “Shared · Live sync” before relying on a saved item. Pending writes are retried only while the current tab remains open; they are not a durable offline queue.
