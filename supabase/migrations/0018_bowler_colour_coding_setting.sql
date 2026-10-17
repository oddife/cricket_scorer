-- Synchronize the match-level preference that enables two-bowler colour outlines.
-- Older rows default to disabled until the source client syncs its saved setting.
alter table public.matches
  add column if not exists bowler_colour_coding_enabled boolean not null default false;

-- Refresh PostgREST's schema cache for the new match setting.
NOTIFY pgrst, 'reload schema';
