-- Secret Territory shared data schema
-- Run this in Supabase SQL Editor. Use a fresh random UUID as couple_id.
-- Create both accounts through the app first, then add both auth user IDs below.

create table if not exists public.couple_members (
  couple_id uuid not null,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text not null,
  created_at timestamptz not null default now(),
  primary key (couple_id, user_id)
);

create table if not exists public.shared_entries (
  id uuid primary key default gen_random_uuid(),
  couple_id uuid not null,
  created_by uuid not null references auth.users(id) on delete cascade,
  entry_type text not null,
  payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create index if not exists shared_entries_couple_created_idx
  on public.shared_entries (couple_id, created_at desc);

alter table public.couple_members enable row level security;
alter table public.shared_entries enable row level security;

drop policy if exists "Members can view their own membership" on public.couple_members;
create policy "Members can view their own membership"
  on public.couple_members for select to authenticated
  using (user_id = auth.uid());

drop policy if exists "Couple members can read shared entries" on public.shared_entries;
create policy "Couple members can read shared entries"
  on public.shared_entries for select to authenticated
  using (exists (
    select 1 from public.couple_members cm
    where cm.couple_id = shared_entries.couple_id
      and cm.user_id = auth.uid()
  ));

drop policy if exists "Couple members can add their own entries" on public.shared_entries;
create policy "Couple members can add their own entries"
  on public.shared_entries for insert to authenticated
  with check (
    created_by = auth.uid()
    and exists (
      select 1 from public.couple_members cm
      where cm.couple_id = shared_entries.couple_id
        and cm.user_id = auth.uid()
    )
  );

drop policy if exists "Authors can delete their own entries" on public.shared_entries;
create policy "Authors can delete their own entries"
  on public.shared_entries for delete to authenticated
  using (
    created_by = auth.uid()
    and exists (
      select 1 from public.couple_members cm
      where cm.couple_id = shared_entries.couple_id
        and cm.user_id = auth.uid()
    )
  );

-- Optional: enable Realtime for live cross-device updates.
do $$
begin
  alter publication supabase_realtime add table public.shared_entries;
exception when duplicate_object then
  null;
end $$;

-- After both users have signed up, add exactly the two auth.users IDs here.
-- Generate one random couple UUID and use the SAME UUID in config.js on both devices.
-- insert into public.couple_members (couple_id, user_id, display_name) values
-- ('YOUR_SHARED_COUPLE_UUID', 'MUKKU_AUTH_USER_UUID', 'Mukku'),
-- ('YOUR_SHARED_COUPLE_UUID', 'KHUSHI_AUTH_USER_UUID', 'Khushi');

-- Private scrapbook storage. The first folder in each object path is couple_id.
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'secret-territory-memories',
  'secret-territory-memories',
  false,
  2097152,
  array['image/jpeg','image/png','image/webp']
)
on conflict (id) do update
set public = false,
    file_size_limit = 2097152,
    allowed_mime_types = array['image/jpeg','image/png','image/webp'];

drop policy if exists "Couple members can view scrapbook photos" on storage.objects;
create policy "Couple members can view scrapbook photos"
  on storage.objects for select to authenticated
  using (
    bucket_id = 'secret-territory-memories'
    and exists (
      select 1 from public.couple_members cm
      where cm.couple_id::text = (storage.foldername(name))[1]
        and cm.user_id = auth.uid()
    )
  );

drop policy if exists "Couple members can upload scrapbook photos" on storage.objects;
create policy "Couple members can upload scrapbook photos"
  on storage.objects for insert to authenticated
  with check (
    bucket_id = 'secret-territory-memories'
    and exists (
      select 1 from public.couple_members cm
      where cm.couple_id::text = (storage.foldername(name))[1]
        and cm.user_id = auth.uid()
    )
  );

drop policy if exists "Couple members can delete scrapbook photos" on storage.objects;
create policy "Couple members can delete scrapbook photos"
  on storage.objects for delete to authenticated
  using (
    bucket_id = 'secret-territory-memories'
    and exists (
      select 1 from public.couple_members cm
      where cm.couple_id::text = (storage.foldername(name))[1]
        and cm.user_id = auth.uid()
    )
  );

-- Presence is private and limited to authenticated members of the matching couple.
drop policy if exists "Couple members can use their own presence channel" on realtime.messages;
create policy "Couple members can use their own presence channel"
  on realtime.messages for all to authenticated
  using (
    extension = 'presence'
    and exists (
      select 1 from public.couple_members cm
      where cm.user_id = auth.uid()
        and realtime.topic() = 'st-presence-' || cm.couple_id::text
    )
  )
  with check (
    extension = 'presence'
    and exists (
      select 1 from public.couple_members cm
      where cm.user_id = auth.uid()
        and realtime.topic() = 'st-presence-' || cm.couple_id::text
    )
  );
