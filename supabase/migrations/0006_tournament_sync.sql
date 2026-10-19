-- Tournament metadata and per-tournament points configuration are shared
-- catalog data. Local Drift/SQLite remains authoritative during scoring.

create table if not exists public.tournaments (
  sync_id text primary key,
  source_installation_id text not null,
  local_id bigint not null,
  name text not null,
  tournament_type integer not null,
  logo_path text,
  start_date timestamptz,
  end_date timestamptz,
  is_active boolean not null default true,
  updated_at timestamptz not null default now(),
  unique (source_installation_id, local_id)
);

create table if not exists public.tournament_teams (
  tournament_sync_id text not null references public.tournaments(sync_id) on delete cascade,
  team_sync_id text not null references public.teams(sync_id) on delete restrict,
  created_at timestamptz not null default now(),
  primary key (tournament_sync_id, team_sync_id)
);

create table if not exists public.tournament_points_rules (
  tournament_sync_id text primary key references public.tournaments(sync_id) on delete cascade,
  win_points integer not null default 2 check (win_points >= 0 and win_points <= 99),
  tie_points integer not null default 1 check (tie_points >= 0 and tie_points <= 99),
  no_result_points integer not null default 1 check (no_result_points >= 0 and no_result_points <= 99),
  loss_points integer not null default 0 check (loss_points >= 0 and loss_points <= 99),
  updated_at timestamptz not null default now()
);

alter table public.matches
  add column if not exists tournament_sync_id text references public.tournaments(sync_id) on delete set null;

create index if not exists tournaments_local_id_idx
  on public.tournaments(source_installation_id, local_id);
create index if not exists tournament_teams_team_idx
  on public.tournament_teams(team_sync_id);
create index if not exists matches_tournament_idx
  on public.matches(tournament_sync_id, updated_at desc);

alter table public.tournaments enable row level security;
alter table public.tournament_teams enable row level security;
alter table public.tournament_points_rules enable row level security;

create policy "authenticated can read tournaments"
  on public.tournaments for select to authenticated using (true);
create policy "authenticated can insert tournaments"
  on public.tournaments for insert to authenticated with check (true);
create policy "authenticated can update tournaments"
  on public.tournaments for update to authenticated using (true) with check (true);

create policy "authenticated can read tournament teams"
  on public.tournament_teams for select to authenticated using (true);
create policy "authenticated can insert tournament teams"
  on public.tournament_teams for insert to authenticated with check (true);
create policy "authenticated can update tournament teams"
  on public.tournament_teams for update to authenticated using (true) with check (true);

create policy "authenticated can read tournament points rules"
  on public.tournament_points_rules for select to authenticated using (true);
create policy "authenticated can insert tournament points rules"
  on public.tournament_points_rules for insert to authenticated with check (true);
create policy "authenticated can update tournament points rules"
  on public.tournament_points_rules for update to authenticated using (true) with check (true);

alter publication supabase_realtime add table public.tournaments;
alter publication supabase_realtime add table public.tournament_teams;
alter publication supabase_realtime add table public.tournament_points_rules;
