-- Permanent management deletion does not require an app login.
-- The scorer application intentionally remains login-free.
-- 0012 keeps durable deletion tombstones for cross-device synchronization.

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
to anon, authenticated;
