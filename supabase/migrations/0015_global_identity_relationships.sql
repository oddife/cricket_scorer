-- Move synchronized domain relationships onto canonical global_id values.
-- Legacy sync_id columns remain during the compatibility period.

create extension if not exists pgcrypto;

-- Core entities: preserve the existing UUID sync_id as the migration seed for app_id,
-- and generate a permanent server canonical global_id.
alter table public.players add column if not exists app_id uuid;
alter table public.players add column if not exists global_id uuid;
alter table public.teams add column if not exists app_id uuid;
alter table public.teams add column if not exists global_id uuid;
alter table public.tournaments add column if not exists app_id uuid;
alter table public.tournaments add column if not exists global_id uuid;
alter table public.matches add column if not exists app_id uuid;
alter table public.matches add column if not exists global_id uuid;
alter table public.innings add column if not exists app_id uuid;
alter table public.innings add column if not exists global_id uuid;
alter table public.ball_events add column if not exists app_id uuid;
alter table public.ball_events add column if not exists global_id uuid;

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
alter table public.innings alter column app_id set not null;\alter table public.innings alter column global_id set not null;
alter table public.ball_events alter column app_id set not null;
alter table public.ball_events alter column global_id set not null;

create unique index if not exists players_app_id_key on public.players(app_id);
create unique index if not exists players_global_id_key on public.players(global_id);
create unique index if not exists teams_app_id_key on public.teams(app_id);
create unique index if not exists teams_global_id_key on public.teams(global_id);
create unique index if not exists tournaments_app_id_key on public.tournaments(app_id);
create unique index if not exists tournaments_global_id_key on public.tournaments(global_id);
create unique index if not exists matches_app_id_key on public.matches(app_id);
create unique index if not exists matches_global_id_key on public.matches(global_id);
create unique index if not exists innings_app_id_key on public.innings(app_id);
create unique index if not exists innings_global_id_key on public.innings(global_id);
create unique index if not exists ball_events_app_id_key on public.ball_events(app_id);
create unique index if not exists ball_events_global_id_key on public.ball_events(global_id);

-- Canonical relationship references.
alter table public.matches add column if not exists tournament_global_id uuid;
alter table public.innings add column if not exists match_global_id uuid;
alter table public.ball_events add column if not exists match_global_id uuid;
alter table public.ball_events add column if not exists innings_global_id uuid;
alter table public.team_players add column if not exists team_global_id uuid;
alter table public.team_players add column if not exists player_global_id uuid;
alter table public.tournament_teams add column if not exists tournament_global_id uuid;
alter table public.tournament_teams add column if not exists team_global_id uuid;
alter table public.match_teams add column if not exists match_global_id uuid;\alter table public.match_teams add column if not exists team_global_id uuid;
alter table public.match_players add column if not exists match_global_id uuid;\alter table public.match_players add column if not exists team_global_id uuid;\alter table public.match_players add column if not exists player_global_id uuid;

update public.matches m set tournament_global_id = t.global_id
from public.tournaments t where m.tournament_sync_id = t.sync_id and m.tournament_global_id is null;
update public.innings i set match_global_id = m.global_id
from public.matches m where i.match_sync_id = m.sync_id and i.match_global_id is null;
update public.ball_events b set match_global_id = m.global_id
from public.matches m where b.match_sync_id = m.sync_id and b.match_global_id is null;
update public.ball_events b set innings_global_id = i.global_id
from public.innings i where b.innings_sync_id = i.sync_id and b.innings_global_id is null;
update public.team_players r set team_global_id = t.global_id
from public.teams t where r.team_sync_id = t.sync_id and r.team_global_id is null;
update public.team_players r set player_global_id = p.global_id
from public.players p where r.player_sync_id = p.sync_id and r.player_global_id is null;
update public.tournament_teams r set tournament_global_id = t.global_id
from public.tournaments t where r.tournament_sync_id = t.sync_id and r.tournament_global_id is null;
update public.tournament_teams r set team_global_id = t.global_id
from public.teams t where r.team_sync_id = t.sync_id and r.team_global_id is null;
update public.match_teams r set match_global_id = m.global_id
from public.matches m where r.match_sync_id = m.sync_id and r.match_global_id is null;
update public.match_teams r set team_global_id = t.global_id
from public.teams t where r.team_sync_id = t.sync_id and r.team_global_id is null;
update public.match_players r set match_global_id = m.global_id
from public.matches m where r.match_sync_id = m.sync_id and r.match_global_id is null;
update public.match_players r set team_global_id = t.global_id
from public.teams t where r.team_sync_id = t.sync_id and r.team_global_id is null;
update public.match_players r set player_global_id = p.global_id
from public.players p where r.player_sync_id = p.sync_id and r.player_global_id is null;

alter table public.matches add constraint matches_tournament_global_id_fkey foreign key (tournament_global_id) references public.tournaments(global_id);
alter table public.innings add constraint innings_match_global_id_fkey foreign key (match_global_id) references public.matches(global_id);
alter table public.ball_events add constraint ball_events_match_global_id_fkey foreign key (match_global_id) references public.matches(global_id);
alter table public.ball_events add constraint ball_events_innings_global_id_fkey foreign key (innings_global_id) references public.innings(global_id);
alter table public.team_players add constraint team_players_team_global_id_fkey foreign key (team_global_id) references public.teams(global_id);
alter table public.team_players add constraint team_players_player_global_id_fkey foreign key (player_global_id) references public.players(global_id);
alter table public.tournament_teams add constraint tournament_teams_tournament_global_id_fkey foreign key (tournament_global_id) references public.tournaments(global_id);
alter table public.tournament_teams add constraint tournament_teams_team_global_id_fkey foreign key (team_global_id) references public.teams(global_id);
alter table public.match_teams add constraint match_teams_match_global_id_fkey foreign key (match_global_id) references public.matches(global_id);
alter table public.match_teams add constraint match_teams_team_global_id_fkey foreign key (team_global_id) references public.teams(global_id);
alter table public.match_players add constraint match_players_match_global_id_fkey foreign key (match_global_id) references public.matches(global_id);
alter table public.match_players add constraint match_players_team_global_id_fkey foreign key (team_global_id) references public.teams(global_id);
alter table public.match_players add constraint match_players_player_global_id_fkey foreign key (player_global_id) references public.players(global_id);
