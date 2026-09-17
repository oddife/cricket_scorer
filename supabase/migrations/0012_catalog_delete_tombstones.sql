-- Durable catalog deletion markers.
-- A catalog row may be physically removed, so other devices need a durable
-- record telling them to remove their local copy during a later sync.

create table if not exists public.catalog_delete_tombstones (
  entity_type text not null,
  sync_id text not null,
  deleted_at timestamptz not null default now(),
  primary key (entity_type, sync_id)
);

alter table public.catalog_delete_tombstones enable row level security;

create policy "authenticated can read catalog delete tombstones"
  on public.catalog_delete_tombstones
  for select to authenticated
  using (true);

create index if not exists catalog_delete_tombstones_deleted_at_idx
  on public.catalog_delete_tombstones(deleted_at desc);
