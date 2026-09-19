-- Three-ID identity model.
-- app_id is the durable client-side identity.
-- global_id is the server-side canonical identity.
-- sync_id remains the legacy synchronization/compatibility identifier.

create extension if not exists pgcrypto;

alter table public.players add column if not exists app_id uuid, add column if not exists global_id uuid default gen_random_uuid();
alter table public.teams add column if not exists app_id uuid, add column if not exists global_id uuid default gen_random_uuid();
alter table public.tournaments add column if not exists app_id uuid, add column if not exists global_id uuid default gen_random_uuid();
alter table public.matches add column if not exists app_id uuid, add column if not exists global_id uuid default gen_random_uuid();
alter table public.innings add column if not exists app_id uuid, add column if not exists global_id uuid default gen_random_uuid();
alter table public.ball_events add column if not exists app_id uuid, add column if not exists global_id uuid default gen_random_uuid();

update public.players set app_id = sync_id::uuid where app_id is null;
update public.teams set app_id = sync_id::uuid where app_id is null;
update public.tournaments set app_id = sync_id::uuid where app_id is null;
update public.matches set app_id = sync_id::uuid where app_id is null;
update public.innings set app_id = sync_id::uuid where app_id is null;
update public.ball_events set app_id = sync_id::uuid where app_id is null;

update public.players set global_id = gen_random_uuid() where global_id is null;
update public.teams set global_id = gen_random_uuid() where global_id is null;
update public.tournaments set global_id = gen_random_uuid() where global_id is null;
update public.matches set global_id = gen_random_uuid() where global_id is null;
update public.innings set global_id = gen_random_uuid() where global_id is null;
update public.ball_events set global_id = gen_random_uuid() where global_id is null;

alter table public.players alter column app_id set not null;
alter table public.players alter column global_id set not null;
alter table public.teams alter column app_id set not null;
alter table public.teams alter column global_id set not null;
alter table public.tournaments alter column app_id set not null;
alter table public.tournaments alter column global_id set not null;
alter table public.matches alter column app_id set not null;
alter table public.matches alter column global_id set not null;
alter table public.innings alter column app_id set not null;
alter table public.innings alter column global_id set not null;
alter table public.ball_events alter column app_id set not null;
alter table public.ball_events alter column global_id set not null;

alter table public.players alter column app_id set default gen_random_uuid();
alter table public.teams alter column app_id set default gen_random_uuid();
alter table public.tournaments alter column app_id set default gen_random_uuid();
alter table public.matches alter column app_id set default gen_random_uuid();
alter table public.innings alter column app_id set default gen_random_uuid();
alter table public.ball_events alter column app_id set default gen_random_uuid();

create unique index if not exists players_app_id_uidx on public.players(app_id);
create unique index if not exists players_global_id_uidx on public.players(global_id);
create unique index if not exists teams_app_id_uidx on public.teams(app_id);
create unique index if not exists teams_global_id_uidx on public.teams(global_id);
create unique index if not exists tournaments_app_id_uidx on public.tournaments(app_id);
create unique index if not exists tournaments_global_id_uidx on public.tournaments(global_id);
create unique index if not exists matches_app_id_uidx on public.matches(app_id);
create unique index if not exists matches_global_id_uidx on public.matches(global_id);
create unique index if not exists innings_app_id_uidx on public.innings(app_id);
create unique index if not exists innings_global_id_uidx on public.innings(global_id);
create unique index if not exists ball_events_app_id_uidx on public.ball_events(app_id);
create unique index if not exists ball_events_global_id_uidx on public.ball_events(global_id);
