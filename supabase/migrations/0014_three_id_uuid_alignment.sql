-- app_id is already UUID in 0012. Keep this migration as an idempotent
-- compatibility step for environments that may have applied an earlier
-- revision of 0012 where app_id was text.

create extension if not exists pgcrypto;

-- Existing sync_id values are valid UUIDs, but their UUID version is not
-- part of the legacy contract. Do not enforce UUID v4 on migrated rows.

alter table public.teams alter column app_id set default gen_random_uuid();
alter table public.players alter column app_id set default gen_random_uuid();
alter table public.tournaments alter column app_id set default gen_random_uuid();
alter table public.matches alter column app_id set default gen_random_uuid();
alter table public.innings alter column app_id set default gen_random_uuid();
alter table public.ball_events alter column app_id set default gen_random_uuid();
alter table public.team_players alter column app_id set default gen_random_uuid();
alter table public.tournament_teams alter column app_id set default gen_random_uuid();
alter table public.match_teams alter column app_id set default gen_random_uuid();
alter table public.match_players alter column app_id set default gen_random_uuid();
