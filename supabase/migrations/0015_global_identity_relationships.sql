-- Move synchronized domain relationships onto canonical global_id values.
-- Legacy *_sync_id columns remain during the compatibility period.
--
-- Prerequisite: 0012, 0013 and 0014 have been applied.

-- Canonical relationship references.
alter table public.matches add column if not exists tournament_global_id uuid;
alter table public.innings add column if not exists match_global_id uuid;
alter table public.ball_events add column if not exists match_global_id uuid;
alter table public.ball_events add column if not exists innings_global_id uuid;
alter table public.team_players add column if not exists team_global_id uuid;
alter table public.team_players add column if not exists player_global_id uuid;
alter table public.tournament_teams add column if not exists tournament_global_id uuid;
alter table public.tournament_teams add column if not exists team_global_id uuid;
alter table public.match_teams add column if not exists match_global_id uuid;
alter table public.match_teams add column if not exists team_global_id uuid;
alter table public.match_players add column if not exists match_global_id uuid;
alter table public.match_players add column if not exists team_global_id uuid;
alter table public.match_players add column if not exists player_global_id uuid;

-- Resolve the existing legacy relationships to canonical server identities.
update public.matches m
set tournament_global_id = t.global_id
from public.tournaments t
where m.tournament_sync_id = t.sync_id
  and m.tournament_global_id is null;

update public.innings i
set match_global_id = m.global_id
from public.matches m
where i.match_sync_id = m.sync_id
  and i.match_global_id is null;

update public.ball_events b
set match_global_id = m.global_id
from public.matches m
where b.match_sync_id = m.sync_id
  and b.match_global_id is null;

update public.ball_events b
set innings_global_id = i.global_id
from public.innings i
where b.innings_sync_id = i.sync_id
  and b.innings_global_id is null;

update public.team_players r
set team_global_id = t.global_id
from public.teams t
where r.team_sync_id = t.sync_id
  and r.team_global_id is null;

update public.team_players r
set player_global_id = p.global_id
from public.players p
where r.player_sync_id = p.sync_id
  and r.player_global_id is null;

update public.tournament_teams r
set tournament_global_id = t.global_id
from public.tournaments t
where r.tournament_sync_id = t.sync_id
  and r.tournament_global_id is null;

update public.tournament_teams r
set team_global_id = t.global_id
from public.teams t
where r.team_sync_id = t.sync_id
  and r.team_global_id is null;

update public.match_teams r
set match_global_id = m.global_id
from public.matches m
where r.match_sync_id = m.sync_id
  and r.match_global_id is null;

update public.match_teams r
set team_global_id = t.global_id
from public.teams t
where r.team_sync_id = t.sync_id
  and r.team_global_id is null;

update public.match_players r
set match_global_id = m.global_id
from public.matches m
where r.match_sync_id = m.sync_id
  and r.match_global_id is null;

update public.match_players r
set team_global_id = t.global_id
from public.teams t
where r.team_sync_id = t.sync_id
  and r.team_global_id is null;

update public.match_players r
set player_global_id = p.global_id
from public.players p
where r.player_sync_id = p.sync_id
  and r.player_global_id is null;

-- Canonical foreign keys. Nullable during the compatibility phase so an
-- existing orphaned legacy relationship can be identified and repaired before
-- the columns become NOT NULL.
alter table public.matches
  add constraint matches_tournament_global_id_fkey
  foreign key (tournament_global_id) references public.tournaments(global_id);

alter table public.innings
  add constraint innings_match_global_id_fkey
  foreign key (match_global_id) references public.matches(global_id);

alter table public.ball_events
  add constraint ball_events_match_global_id_fkey
  foreign key (match_global_id) references public.matches(global_id);

alter table public.ball_events
  add constraint ball_events_innings_global_id_fkey
  foreign key (innings_global_id) references public.innings(global_id);

alter table public.team_players
  add constraint team_players_team_global_id_fkey
  foreign key (team_global_id) references public.teams(global_id);

alter table public.team_players
  add constraint team_players_player_global_id_fkey
  foreign key (player_global_id) references public.players(global_id);

alter table public.tournament_teams
  add constraint tournament_teams_tournament_global_id_fkey
  foreign key (tournament_global_id) references public.tournaments(global_id);

alter table public.tournament_teams
  add constraint tournament_teams_team_global_id_fkey
  foreign key (team_global_id) references public.teams(global_id);

alter table public.match_teams
  add constraint match_teams_match_global_id_fkey
  foreign key (match_global_id) references public.matches(global_id);

alter table public.match_teams
  add constraint match_teams_team_global_id_fkey
  foreign key (team_global_id) references public.teams(global_id);

alter table public.match_players
  add constraint match_players_match_global_id_fkey
  foreign key (match_global_id) references public.matches(global_id);

alter table public.match_players
  add constraint match_players_team_global_id_fkey
  foreign key (team_global_id) references public.teams(global_id);

alter table public.match_players
  add constraint match_players_player_global_id_fkey
  foreign key (player_global_id) references public.players(global_id);

create index if not exists matches_tournament_global_id_idx on public.matches(tournament_global_id);
create index if not exists innings_match_global_id_idx on public.innings(match_global_id);
create index if not exists ball_events_innings_global_id_idx on public.ball_events(innings_global_id);
create index if not exists team_players_team_global_id_idx on public.team_players(team_global_id);
create index if not exists team_players_player_global_id_idx on public.team_players(player_global_id);
create index if not exists tournament_teams_tournament_global_id_idx on public.tournament_teams(tournament_global_id);
create index if not exists tournament_teams_team_global_id_idx on public.tournament_teams(team_global_id);
create index if not exists match_teams_match_global_id_idx on public.match_teams(match_global_id);
create index if not exists match_teams_team_global_id_idx on public.match_teams(team_global_id);
create index if not exists match_players_match_global_id_idx on public.match_players(match_global_id);
create index if not exists match_players_team_global_id_idx on public.match_players(team_global_id);
create index if not exists match_players_player_global_id_idx on public.match_players(player_global_id);
