-- Team and Player sync tables use stable UUID identities.
-- Local integer IDs are retained only as source-device audit fields.

create table if not exists public.teams (
  sync_id text primary key,
  source_installation_id text not null,
  local_id bigint not null,
  name text not null,
  short_name text not null,
  logo_path text,
  is_active boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists public.players (
  sync_id text primary key,
  source_installation_id text not null,
  local_id bigint not null,
  name text not null,
  display_name text not null,
  photo_path text,
  jersey_number integer,
  batting_style integer not null default 0,
  bowling_style integer not null default 0,
  is_active boolean not null default true,
  updated_at timestamptz not null default now()
);

create table if not exists public.team_players (
  sync_id text primary key,
  source_installation_id text not null,
  local_id bigint not null,
  team_sync_id text not null references public.teams(sync_id) on delete cascade,
  player_sync_id text not null references public.players(sync_id) on delete cascade,
  jersey_number integer,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  unique(team_sync_id, player_sync_id)
);

create index if not exists teams_local_id_idx
  on public.teams(source_installation_id, local_id);
create index if not exists players_local_id_idx
  on public.players(source_installation_id, local_id);
create index if not exists team_players_team_idx
  on public.team_players(team_sync_id);
create index if not exists team_players_player_idx
  on public.team_players(player_sync_id);

alter table public.teams enable row level security;
alter table public.players enable row level security;
alter table public.team_players enable row level security;

create policy "authenticated can read teams"
  on public.teams for select to authenticated using (true);
create policy "authenticated can insert teams"
  on public.teams for insert to authenticated with check (true);
create policy "authenticated can update teams"
  on public.teams for update to authenticated using (true) with check (true);

create policy "authenticated can read players"
  on public.players for select to authenticated using (true);
create policy "authenticated can insert players"
  on public.players for insert to authenticated with check (true);
create policy "authenticated can update players"
  on public.players for update to authenticated using (true) with check (true);

create policy "authenticated can read team players"
  on public.team_players for select to authenticated using (true);
create policy "authenticated can insert team players"
  on public.team_players for insert to authenticated with check (true);
create policy "authenticated can update team players"
  on public.team_players for update to authenticated using (true) with check (true);

alter publication supabase_realtime add table public.teams;
alter publication supabase_realtime add table public.players;
alter publication supabase_realtime add table public.team_players;
