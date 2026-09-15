-- Stable, device-independent sync identity.
-- New client code generates UUID-shaped text IDs locally and uses them for
-- matches, innings, and ball events across all devices.

alter table public.matches
  alter column sync_id type text using sync_id::text;

alter table public.innings
  alter column sync_id type text using sync_id::text;

alter table public.ball_events
  alter column sync_id type text using sync_id::text;

create unique index if not exists matches_sync_id_unique
  on public.matches(sync_id);

create unique index if not exists innings_sync_id_unique
  on public.innings(sync_id);

create unique index if not exists ball_events_sync_id_unique
  on public.ball_events(sync_id);

create index if not exists innings_match_sync_id_idx
  on public.innings(match_sync_id);

create index if not exists ball_events_innings_sync_id_idx
  on public.ball_events(innings_sync_id);
