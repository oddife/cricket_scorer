-- Enforce the locked match configuration at the synchronization boundary.
-- The Flutter app remains the local authority, but Supabase must reject
-- impossible match configurations from any client.
--
-- NOT VALID keeps deployment safe for any legacy rows that predate these
-- constraints. New inserts/updates are enforced immediately. Existing data
-- can be validated separately after it has been audited.

alter table public.matches
  add constraint matches_innings_count_valid
  check (innings_count is not null and innings_count in (2, 4)) not valid;

alter table public.matches
  add constraint matches_overs_per_innings_valid
  check (overs_per_innings is not null and overs_per_innings > 0) not valid;

alter table public.matches
  add constraint matches_players_per_team_valid
  check (players_per_team is not null and players_per_team > 0) not valid;

alter table public.matches
  add constraint matches_balls_per_over_valid
  check (balls_per_over = 6) not valid;

alter table public.matches
  add constraint matches_status_valid
  check (status between 0 and 3) not valid;

alter table public.matches
  add constraint matches_toss_decision_valid
  check (toss_decision is null or toss_decision in (0, 1)) not valid;

alter table public.innings
  add constraint innings_number_valid
  check (innings_number between 1 and 4) not valid;

alter table public.innings
  add constraint innings_overs_per_innings_valid
  check (overs_per_innings > 0) not valid;

alter table public.innings
  add constraint innings_balls_per_over_valid
  check (balls_per_over = 6) not valid;
