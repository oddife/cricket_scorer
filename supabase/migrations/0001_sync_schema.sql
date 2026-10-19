-- Cricket Scorer: initial shared synchronization contract.
-- Local Drift/SQLite remains authoritative for scoring. Supabase stores
-- synchronized match facts and distributes them through Realtime.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  role text not null default 'scorer'
    check (role in ('scorer', 'admin')),
  created_at timestamptz not null default now()
);

create table if not exists public.matches (
  sync_id text primary key,
  source_installation_id text not null,
  local_id bigint not null,
  name text not null,
  date timestamptz not null,
  is_published boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (source_installation_id, local_id)
);

create table if not exists public.match_scorers (
  match_sync_id text not null references public.matches(sync_id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (match_sync_id, user_id)
);

create table if not exists public.innings (
  sync_id text primary key,
  match_sync_id text not null references public.matches(sync_id) on delete cascade,
  source_installation_id text not null,
  local_id bigint not null,
  innings_number integer not null check (innings_number > 0),
  batting_team_id bigint not null,
  bowling_team_id bigint not null,
  opening_striker_id bigint not null,
  opening_non_striker_id bigint not null,
  opening_bowler_id bigint not null,
  overs_per_innings integer not null check (overs_per_innings > 0),
  balls_per_over integer not null default 6 check (balls_per_over = 6),
  two_bowler_mode boolean not null default false,
  status text not null check (status in ('setup', 'live', 'completed', 'ended')),
  started_at timestamptz,
  completed_at timestamptz,
  unique (source_installation_id, local_id),
  unique (match_sync_id, innings_number)
);

create table if not exists public.ball_events (
  sync_id text primary key,
  source_installation_id text not null,
  local_id bigint not null,
  match_sync_id text not null references public.matches(sync_id) on delete cascade,
  innings_sync_id text not null references public.innings(sync_id) on delete cascade,
  sequence_number integer not null check (sequence_number > 0),
  over_number integer not null check (over_number > 0),
  legal_ball_number integer not null check (legal_ball_number >= 0),
  bowler_id bigint not null,
  striker_id bigint not null,
  non_striker_id bigint not null,
  delivery_type integer not null,
  is_legal_ball boolean not null,
  batter_runs integer not null default 0 check (batter_runs >= 0),
  bye_runs integer not null default 0 check (bye_runs >= 0),
  leg_bye_runs integer not null default 0 check (leg_bye_runs >= 0),
  wide_runs integer not null default 0 check (wide_runs >= 0),
  no_ball_runs integer not null default 0 check (no_ball_runs >= 0),
  total_runs integer not null check (total_runs >= 0),
  wicket_type integer,
  dismissed_player_id bigint,
  fielder_id bigint,
  run_out_end integer,
  credited_to_bowler boolean,
  wicket_completed_runs integer not null default 0 check (wicket_completed_runs >= 0),
  wicket_crossed_before_wicket boolean not null default false,
  replacement_batter_id bigint,
  event_timestamp timestamptz not null,
  created_at timestamptz not null default now(),
  unique (innings_sync_id, sequence_number),
  unique (source_installation_id, local_id)
);

create index if not exists idx_matches_published
  on public.matches (is_published, updated_at desc);

create index if not exists idx_match_scorers_user
  on public.match_scorers (user_id, match_sync_id);

create index if not exists idx_innings_match
  on public.innings (match_sync_id, innings_number);

create index if not exists idx_ball_events_match_order
  on public.ball_events (match_sync_id, innings_sync_id, sequence_number);

alter table public.profiles enable row level security;
alter table public.matches enable row level security;
alter table public.match_scorers enable row level security;
alter table public.innings enable row level security;
alter table public.ball_events enable row level security;

-- Helpers keep policy expressions readable and avoid repeating role checks.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.profiles
    where id = auth.uid() and role = 'admin'
  );
$$;

create or replace function public.can_score_match(p_match_sync_id text)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.is_admin()
      or exists (
        select 1 from public.match_scorers
        where match_sync_id = p_match_sync_id
          and user_id = auth.uid()
      );
$$;

create policy profiles_self_read
on public.profiles for select
to authenticated
using (id = auth.uid() or public.is_admin());

create policy profiles_admin_write
on public.profiles for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy matches_read
on public.matches for select
to anon, authenticated
using (is_published or public.can_score_match(sync_id));

create policy matches_admin_write
on public.matches for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy match_scorers_read
on public.match_scorers for select
to authenticated
using (user_id = auth.uid() or public.is_admin());

create policy match_scorers_admin_write
on public.match_scorers for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

create policy innings_read
on public.innings for select
to anon, authenticated
using (
  exists (
    select 1 from public.matches m
    where m.sync_id = match_sync_id
      and (m.is_published or public.can_score_match(m.sync_id))
  )
);

create policy innings_scorer_insert
on public.innings for insert
to authenticated
with check (public.can_score_match(match_sync_id));

create policy innings_scorer_update
on public.innings for update
to authenticated
using (public.can_score_match(match_sync_id))
with check (public.can_score_match(match_sync_id));

create policy ball_events_read
on public.ball_events for select
to anon, authenticated
using (
  exists (
    select 1 from public.matches m
    where m.sync_id = match_sync_id
      and (m.is_published or public.can_score_match(m.sync_id))
  )
);

-- Ball events are immutable after insertion. There is intentionally no
-- UPDATE or DELETE policy. Corrections happen by the scorer's local event
-- history/undo workflow and are synchronized using an explicit contract.
create policy ball_events_scorer_insert
on public.ball_events for insert
to authenticated
with check (public.can_score_match(match_sync_id));

-- Realtime publication. The Supabase project can enable/disable this
-- publication at deployment time without changing the Flutter contract.
alter publication supabase_realtime add table public.ball_events;
alter publication supabase_realtime add table public.innings;
alter publication supabase_realtime add table public.matches;
