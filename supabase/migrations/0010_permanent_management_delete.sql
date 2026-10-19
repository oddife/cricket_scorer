-- Permanent management deletion is explicit and irreversible.
-- The function is intentionally authenticated-only. It rejects deletion of
-- players/teams that are still referenced by match participant history.
--
-- 0012 adds durable deletion tombstones so another device can learn about a
-- physical catalog deletion even though the source row no longer exists.

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

  case p_entity_type
    when 'match' then
      delete from public.matches where sync_id = p_sync_id;
      insert into public.catalog_delete_tombstones (entity_type, sync_id)
      values ('match', p_sync_id)
      on conflict (entity_type, sync_id) do update
        set deleted_at = now();

    when 'player' then
      if exists (
        select 1 from public.match_players
        where player_sync_id = p_sync_id
      ) then
        raise exception 'Player is referenced by match history and cannot be deleted';
      end if;
      delete from public.players where sync_id = p_sync_id;
      insert into public.catalog_delete_tombstones (entity_type, sync_id)
      values ('player', p_sync_id)
      on conflict (entity_type, sync_id) do update
        set deleted_at = now();

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
      insert into public.catalog_delete_tombstones (entity_type, sync_id)
      values ('team', p_sync_id)
      on conflict (entity_type, sync_id) do update
        set deleted_at = now();

    when 'tournament' then
      delete from public.tournaments where sync_id = p_sync_id;
      insert into public.catalog_delete_tombstones (entity_type, sync_id)
      values ('tournament', p_sync_id)
      on conflict (entity_type, sync_id) do update
        set deleted_at = now();

    else
      raise exception 'Unsupported permanent delete entity type: %', p_entity_type;
  end case;
end;
$$;

grant execute on function public.permanently_delete_catalog_entity(text, text)
to authenticated;
