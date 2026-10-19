-- Add the match fields needed by the first sync worker and allow an
-- authenticated scorer to bootstrap a match and claim it for scoring.

alter table public.matches
  add column if not exists venue text,
  add column if not exists innings_count integer,
  add column if not exists overs_per_innings integer,
  add column if not exists balls_per_over integer not null default 6,
  add column if not exists players_per_team integer,
  add column if not exists two_bowler_mode boolean not null default false,
  add column if not exists toss_winner_team_id bigint,
  add column if not exists toss_decision integer,
  add column if not exists status integer not null default 0;

create policy matches_scorer_insert
on public.matches for insert
to authenticated
with check (true);

create policy matches_scorer_update
on public.matches for update
to authenticated
using (public.can_score_match(sync_id))
with check (public.can_score_match(sync_id));

create policy match_scorers_self_insert
on public.match_scorers for insert
to authenticated
with check (user_id = auth.uid());

create policy match_scorers_self_delete
on public.match_scorers for delete
to authenticated
using (user_id = auth.uid() or public.is_admin());

-- The creator claims the match immediately after inserting it. This policy
-- is intentionally limited to the authenticated user's own membership row.
