-- Tournament membership is synchronized from the local authoritative
-- membership set. Authenticated scorers therefore need delete access so
-- local removals can be reflected in Supabase.

create policy "authenticated can delete tournament teams"
  on public.tournament_teams for delete to authenticated using (true);
