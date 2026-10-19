-- Stable, device-independent sync identity.
-- New client code generates UUID-shaped text IDs locally and uses them for
-- matches, innings, and ball events across all devices.
--
-- 0001 already defines these sync_id columns as text. Do not ALTER their
-- types here: PostgreSQL rejects even a no-op type alteration when an RLS
-- policy depends on the column. Keeping the migration additive also makes
-- the fresh self-hosted Supabase deployment safe with the current schema.

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
