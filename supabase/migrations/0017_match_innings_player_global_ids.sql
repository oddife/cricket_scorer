-- Canonical IDs for match toss, innings teams, opening players, and the
-- persisted two-bowler selection. The legacy bigint columns are retained for
-- compatibility but are local to the installation that created the record.

alter table public.matches
  add column if not exists toss_winner_team_global_id uuid;

alter table public.innings
  add column if not exists batting_team_global_id uuid,
  add column if not exists bowling_team_global_id uuid,
  add column if not exists opening_striker_global_id uuid,
  add column if not exists opening_non_striker_global_id uuid,
  add column if not exists opening_bowler_global_id uuid,
  add column if not exists active_two_bowler_one_global_id uuid,
  add column if not exists active_two_bowler_two_global_id uuid;

-- Best-effort backfill only where the existing source installation plus
-- local integer ID provides an unambiguous catalog reference.
update public.matches m
set toss_winner_team_global_id = t.global_id
from public.teams t
where m.toss_winner_team_global_id is null
  and m.toss_winner_team_id is not null
  and t.source_installation_id = m.source_installation_id
  and t.local_id = m.toss_winner_team_id;

update public.innings i
set batting_team_global_id = t.global_id
from public.teams t
where i.batting_team_global_id is null
  and t.source_installation_id = i.source_installation_id
  and t.local_id = i.batting_team_id;

update public.innings i
set bowling_team_global_id = t.global_id
from public.teams t
where i.bowling_team_global_id is null
  and t.source_installation_id = i.source_installation_id
  and t.local_id = i.bowling_team_id;

update public.innings i
set opening_striker_global_id = p.global_id
from public.players p
where i.opening_striker_global_id is null
  and p.source_installation_id = i.source_installation_id
  and p.local_id = i.opening_striker_id;

update public.innings i
set opening_non_striker_global_id = p.global_id
from public.players p
where i.opening_non_striker_global_id is null
  and p.source_installation_id = i.source_installation_id
  and p.local_id = i.opening_non_striker_id;

update public.innings i
set opening_bowler_global_id = p.global_id
from public.players p
where i.opening_bowler_global_id is null
  and p.source_installation_id = i.source_installation_id
  and p.local_id = i.opening_bowler_id;

do $sync_migration$
begin
  if not exists (select 1 from pg_constraint where conname = 'matches_toss_winner_team_global_id_fkey') then
    alter table public.matches add constraint matches_toss_winner_team_global_id_fkey
      foreign key (toss_winner_team_global_id) references public.teams(global_id) not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'innings_batting_team_global_id_fkey') then
    alter table public.innings add constraint innings_batting_team_global_id_fkey
      foreign key (batting_team_global_id) references public.teams(global_id) not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'innings_bowling_team_global_id_fkey') then
    alter table public.innings add constraint innings_bowling_team_global_id_fkey
      foreign key (bowling_team_global_id) references public.teams(global_id) not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'innings_opening_striker_global_id_fkey') then
    alter table public.innings add constraint innings_opening_striker_global_id_fkey
      foreign key (opening_striker_global_id) references public.players(global_id) not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'innings_opening_non_striker_global_id_fkey') then
    alter table public.innings add constraint innings_opening_non_striker_global_id_fkey
      foreign key (opening_non_striker_global_id) references public.players(global_id) not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'innings_opening_bowler_global_id_fkey') then
    alter table public.innings add constraint innings_opening_bowler_global_id_fkey
      foreign key (opening_bowler_global_id) references public.players(global_id) not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'innings_active_two_bowler_one_global_id_fkey') then
    alter table public.innings add constraint innings_active_two_bowler_one_global_id_fkey
      foreign key (active_two_bowler_one_global_id) references public.players(global_id) not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'innings_active_two_bowler_two_global_id_fkey') then
    alter table public.innings add constraint innings_active_two_bowler_two_global_id_fkey
      foreign key (active_two_bowler_two_global_id) references public.players(global_id) not valid;
  end if;
end $sync_migration$;

create index if not exists matches_toss_winner_team_global_id_idx
  on public.matches(toss_winner_team_global_id);
create index if not exists innings_batting_team_global_id_idx
  on public.innings(batting_team_global_id);
create index if not exists innings_bowling_team_global_id_idx
  on public.innings(bowling_team_global_id);
create index if not exists innings_opening_striker_global_id_idx
  on public.innings(opening_striker_global_id);
create index if not exists innings_opening_non_striker_global_id_idx
  on public.innings(opening_non_striker_global_id);
create index if not exists innings_opening_bowler_global_id_idx
  on public.innings(opening_bowler_global_id);
create index if not exists innings_active_two_bowler_one_global_id_idx
  on public.innings(active_two_bowler_one_global_id);
create index if not exists innings_active_two_bowler_two_global_id_idx
  on public.innings(active_two_bowler_two_global_id);
