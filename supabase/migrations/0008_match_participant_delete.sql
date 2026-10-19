-- Match participant assignments are synchronized from the local authoritative
-- participant sets. Authenticated scorers therefore need delete access so
-- local removals can be reflected in Supabase.

create policy "authenticated can delete match teams"
  on public.match_teams for delete to authenticated
  using (public.can_score_match(match_sync_id));

create policy "authenticated can delete match players"
  on public.match_players for delete to authenticated
  using (public.can_score_match(match_sync_id));
