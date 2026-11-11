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
