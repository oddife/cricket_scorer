-- Align client-created app_id with the three-ID identity decision.
-- Existing rows keep their current values; this migration only converts
-- textual UUIDs and enforces UUID-v4 semantics for future writes.

create extension if not exists pgcrypto;

alter table public.teams
  alter column app_id type uuid using app_id::uuid;
alter table public.players
  alter column app_id type uuid using app_id::uuid;
alter table public.tournaments
  alter column app_id type uuid using app_id::uuid;
alter table public.matches
  alter column app_id type uuid using app_id::uuid;
alter table public.innings
  alter column app_id type uuid using app_id::uuid;
alter table public.ball_events
  alter column app_id type uuid using app_id::uuid;

alter table public.teams alter column app_id set default gen_random_uuid();
alter table public.players alter column app_id set default gen_random_uuid();
alter table public.tournaments alter column app_id set default gen_random_uuid();
alter table public.matches alter column app_id set default gen_random_uuid();
alter table public.innings alter column app_id set default gen_random_uuid();
alter table public.ball_events alter column app_id set default gen_random_uuid();

alter table public.teams add constraint teams_app_id_v4_chk
  check ((app_id::text ~* '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'));
alter table public.players add constraint players_app_id_v4_chk
  check ((app_id::text ~* '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'));
alter table public.tournaments add constraint tournaments_app_id_v4_chk
  check ((app_id::text ~* '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'));
alter table public.matches add constraint matches_app_id_v4_chk
  check ((app_id::text ~* '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'));
alter table public.innings add constraint innings_app_id_v4_chk
  check ((app_id::text ~* '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'));
alter table public.ball_events add constraint ball_events_app_id_v4_chk
  check ((app_id::text ~* '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'));

alter table public.team_players alter column app_id type uuid using app_id::uuid;
alter table public.tournament_teams alter column app_id type uuid using app_id::uuid;
alter table public.match_teams alter column app_id type uuid using app_id::uuid;
alter table public.match_players alter column app_id type uuid using app_id::uuid;

alter table public.team_players alter column app_id set default gen_random_uuid();
alter table public.tournament_teams alter column app_id set default gen_random_uuid();
alter table public.match_teams alter column app_id set default gen_random_uuid();
alter table public.match_players alter column app_id set default gen_random_uuid();
