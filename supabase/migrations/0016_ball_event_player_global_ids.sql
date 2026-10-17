-- Canonical player references for cross-installation ball-event recovery.
-- Legacy integer player IDs remain for compatibility, but are device-local and
-- must not be used as the only identity on new synchronized deliveries.

alter table public.ball_events
  add column if not exists bowler_global_id uuid,
  add column if not exists striker_global_id uuid,
  add column if not exists non_striker_global_id uuid,
  add column if not exists dismissed_player_global_id uuid,
  add column if not exists fielder_global_id uuid,
  add column if not exists replacement_batter_global_id uuid;

-- Backfill only references that can be resolved exactly against the event's
-- originating installation. Older events created on a client that used
-- downloaded players may not have a matching source-local catalog row; those
-- remain null and continue using the legacy recovery fallback.
update public.ball_events b
set bowler_global_id = p.global_id
from public.players p
where b.bowler_global_id is null
  and p.source_installation_id = b.source_installation_id
  and p.local_id = b.bowler_id;

update public.ball_events b
set striker_global_id = p.global_id
from public.players p
where b.striker_global_id is null
  and p.source_installation_id = b.source_installation_id
  and p.local_id = b.striker_id;

update public.ball_events b
set non_striker_global_id = p.global_id
from public.players p
where b.non_striker_global_id is null
  and p.source_installation_id = b.source_installation_id
  and p.local_id = b.non_striker_id;

update public.ball_events b
set dismissed_player_global_id = p.global_id
from public.players p
where b.dismissed_player_global_id is null
  and b.dismissed_player_id is not null
  and p.source_installation_id = b.source_installation_id
  and p.local_id = b.dismissed_player_id;

update public.ball_events b
set fielder_global_id = p.global_id
from public.players p
where b.fielder_global_id is null
  and b.fielder_id is not null
  and p.source_installation_id = b.source_installation_id
  and p.local_id = b.fielder_id;

update public.ball_events b
set replacement_batter_global_id = p.global_id
from public.players p
where b.replacement_batter_global_id is null
  and b.replacement_batter_id is not null
  and p.source_installation_id = b.source_installation_id
  and p.local_id = b.replacement_batter_id;

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'ball_events_bowler_global_id_fkey') then
    alter table public.ball_events add constraint ball_events_bowler_global_id_fkey
      foreign key (bowler_global_id) references public.players(global_id) not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'ball_events_striker_global_id_fkey') then
    alter table public.ball_events add constraint ball_events_striker_global_id_fkey
      foreign key (striker_global_id) references public.players(global_id) not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'ball_events_non_striker_global_id_fkey') then
    alter table public.ball_events add constraint ball_events_non_striker_global_id_fkey
      foreign key (non_striker_global_id) references public.players(global_id) not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'ball_events_dismissed_player_global_id_fkey') then
    alter table public.ball_events add constraint ball_events_dismissed_player_global_id_fkey
      foreign key (dismissed_player_global_id) references public.players(global_id) not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'ball_events_fielder_global_id_fkey') then
    alter table public.ball_events add constraint ball_events_fielder_global_id_fkey
      foreign key (fielder_global_id) references public.players(global_id) not valid;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'ball_events_replacement_batter_global_id_fkey') then
    alter table public.ball_events add constraint ball_events_replacement_batter_global_id_fkey
      foreign key (replacement_batter_global_id) references public.players(global_id) not valid;
  end if;
end $$;

create index if not exists ball_events_bowler_global_id_idx on public.ball_events(bowler_global_id);
create index if not exists ball_events_striker_global_id_idx on public.ball_events(striker_global_id);
create index if not exists ball_events_non_striker_global_id_idx on public.ball_events(non_striker_global_id);
create index if not exists ball_events_dismissed_player_global_id_idx on public.ball_events(dismissed_player_global_id);
create index if not exists ball_events_fielder_global_id_idx on public.ball_events(fielder_global_id);
create index if not exists ball_events_replacement_batter_global_id_idx on public.ball_events(replacement_batter_global_id);
