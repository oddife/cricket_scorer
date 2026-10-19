-- Durable undo contract for immutable synchronized ball events.
-- Old deliveries remain in ball_events, but their sync IDs are hidden from
-- the recovered score once a tombstone exists. Keeping the original event
-- enables an audit trail and avoids requiring DELETE permission on ball_events.

-- A rescored delivery can reuse the same innings sequence after Undo. The old
-- immutable row is retained as a tombstoned event, so sequence alone can no
-- longer be unique; sync_id remains the row identity.
alter table public.ball_events
  drop constraint if exists ball_events_innings_sync_id_sequence_number_key;

create table if not exists public.ball_event_deletions (
  sync_id text primary key,
  match_sync_id text not null
    references public.matches(sync_id) on delete cascade,
  innings_sync_id text not null
    references public.innings(sync_id) on delete cascade,
  sequence_number integer not null check (sequence_number > 0),
  deleted_by_installation_id text not null,
  deleted_by uuid not null default auth.uid(),
  deleted_at timestamptz not null default now()
);

create index if not exists idx_ball_event_deletions_match
  on public.ball_event_deletions(match_sync_id, deleted_at);

create index if not exists idx_ball_event_deletions_innings_sequence
  on public.ball_event_deletions(innings_sync_id, sequence_number);

alter table public.ball_event_deletions enable row level security;

create policy ball_event_deletions_read
on public.ball_event_deletions for select
to authenticated
using (
  exists (
    select 1 from public.matches m
    where m.sync_id = match_sync_id
      and (m.is_published or public.can_score_match(m.sync_id))
  )
);

create policy ball_event_deletions_scorer_insert
on public.ball_event_deletions for insert
to authenticated
with check (
  public.can_score_match(match_sync_id)
  and deleted_by = auth.uid()
);

-- This table is insert-only by design. Repeated sync checks for an existing
-- tombstone instead of updating it, mirroring the immutable ball-event policy.

NOTIFY pgrst, 'reload schema';
