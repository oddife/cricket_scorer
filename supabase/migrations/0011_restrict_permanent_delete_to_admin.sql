-- Permanent management deletion is an admin-only operation.
-- This replaces the authenticated-only guard from migration 0010 so that
-- anonymous/scorer sessions cannot invoke the irreversible delete RPC.

create or replace function public.permanently_delete_catalog_entity(
  p_entity_type text,
  p_sync_id text
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if auth.uid() is null then
    raise exception 'Authentication is required for permanent deletion';
  end if;

  if not public.is_admin() then
    raise exception 'Administrator privileges are required for permanent deletion';
  end if;

  case p_entity_type
    when 'match' then
      delete from public.matches where sync_id = p_sync_id;

    when 'player' then
      if exists (
        select 1 from public.match_players
        where player_sync_id = p_sync_id
      ) then
        raise exception 'Player is referenced by match history and cannot be deleted';
      end if;
      delete from public.players where sync_id = p_sync_id;

    when 'team' then
      if exists (
        select 1 from public.match_teams
        where team_sync_id = p_sync_id
      ) or exists (
        select 1 from public.match_players
        where team_sync_id = p_sync_id
      ) then
        raise exception 'Team is referenced by match history and cannot be deleted';
      end if;
      delete from public.teams where sync_id = p_sync_id;

    when 'tournament' then
      delete from public.tournaments where sync_id = p_sync_id;

    else
      raise exception 'Unsupported permanent delete entity type: %', p_entity_type;
  end case;
end;
$$;

grant execute on function public.permanently_delete_catalog_entity(text, text)
to authenticated;
