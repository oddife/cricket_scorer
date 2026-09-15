-- Match-level participant assignments are part of the recovery contract.
-- Team/Player catalog rows alone cannot reconstruct MatchTeams/MatchPlayers,
-- because a match may select only part of a catalog and batting order is match-specific.

create table if not exists public.match_teams (
  match_sync_id text not null references public.matches(sync_id) on delete cascade,
  slot integer not null,
  team_sync_id text not null references public.teams(sync_id) on delete restrict,
  primary key (match_sync_id, slot),
  unique (match_sync_id, team_sync_id)
);

create table if not exists public.match_players (
  match_sync_id text not null references public.matches(sync_id) on delete cascade,
  team_sync_id text not null references public.teams(sync_id) on delete restrict,
  player_sync_id text not null references public.players(sync_id) on delete restrict,
  is_playing boolean not null default false,
  batting_order integer,
  primary key (match_sync_id, player_sync_id),
  unique (match_sync_id, team_sync_id, player_sync_id)
);

create index if not exists match_teams_match_idx
  on public.match_teams(match_sync_id, slot);
create index if not exists match_players_match_idx
  on public.match_players(match_sync_id, team_sync_id, batting_order);

alter table public.match_teams enable row level security;
alter table public.match_players enable row level security;

create policy "authenticated can read match teams"
  on public.match_teams for select to authenticated using (true);
create policy "authenticated can insert match teams"
  on public.match_teams for insert to authenticated
  with check (public.can_score_match(match_sync_id));
create policy "authenticated can update match teams"
  on public.match_teams for update to authenticated
  using (public.can_score_match(match_sync_id))
  with check (public.can_score_match(match_sync_id));

create policy "authenticated can read match players"
  on public.match_players for select to authenticated using (true);
create policy "authenticated can insert match players"
  on public.match_players for insert to authenticated
  with check (public.can_score_match(match_sync_id));
create policy "authenticated can update match players"
  on public.match_players for update to authenticated
  using (public.can_score_match(match_sync_id))
  with check (public.can_score_match(match_sync_id));

alter publication supabase_realtime add table public.match_teams;
alter publication supabase_realtime add table public.match_players;
