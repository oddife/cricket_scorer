# Supabase Three-ID Verification

**Status:** Schema and existing-data integrity verification passed.

## Verification date

2026-09-20

## Purpose

Verify that the self-hosted Supabase database is aligned with the locked three-ID identity architecture before creating new test tournament/match data.

## Identity model

```text
local_id   -> local Drift/SQLite database identity only
app_id     -> permanent client-created UUID
             -> stable across devices
             -> never replaced by global_id

global_id  -> permanent server-generated UUID
             -> canonical shared identity
             -> never changes

sync_id    -> synchronization bookkeeping/version identity
             -> not a domain entity identity
```

## Supabase integrity result

The following query was run against the self-hosted Supabase SQL Editor and returned the results below.

| Table | Total | Missing app_id | Missing global_id | Unique app_id | Unique global_id |
|---|---:|---:|---:|---:|---:|
| ball_events | 68 | 0 | 0 | 68 | 68 |
| innings | 4 | 0 | 0 | 4 | 4 |
| match_players | 28 | 0 | 0 | 28 | 28 |
| match_teams | 4 | 0 | 0 | 4 | 4 |
| matches | 3 | 0 | 0 | 3 | 3 |
| players | 42 | 0 | 0 | 42 | 42 |
| team_players | 28 | 0 | 0 | 28 | 28 |
| teams | 4 | 0 | 0 | 4 | 4 |
| tournament_teams | 2 | 0 | 0 | 2 | 2 |
| tournaments | 2 | 0 | 0 | 2 | 2 |

## Result

All existing rows have both `app_id` and `global_id` populated.

For every table:

- `missing_app_id = 0`
- `missing_global_id = 0`
- `total = unique_app_ids`
- `total = unique_global_ids`

This verifies that the currently populated Supabase catalog has complete and unique client/server identities for the tested tables.

## Migration state

The repository contains the three-ID migration sequence:

```text
0012_three_id_identity.sql
0013_relationship_three_id_identity.sql
0014_three_id_uuid_alignment.sql
0015_global_identity_relationships.sql
```

The migration work has already been applied to the self-hosted Supabase database. The verified schema includes canonical relationship columns such as:

```text
tournament_global_id
match_global_id
innings_global_id
team_global_id
player_global_id
```

with foreign keys referencing the corresponding `global_id` columns.

**Do not re-run these migrations against the already migrated database.**

## Application verification baseline

The current feature branch has also been verified locally:

```text
flutter analyze
No issues found!

flutter test
97 tests passed
```

## Next verification phase

The schema check is complete. The next test is an end-to-end identity test using a newly created small test record:

1. Create the record on one client.
2. Record its `local_id`, `app_id`, `global_id`, and `sync_id`.
3. Test an offline-created record where `global_id` is initially absent locally.
4. Synchronize it.
5. Verify that `app_id` remains unchanged and `global_id` is assigned/preserved.
6. Open/synchronize the same entity from another client.
7. Verify that the cross-device entity resolves to the same canonical `global_id` and retains the same `app_id`.
8. Confirm that different devices may have different local integer IDs without creating duplicate domain identities.

No new tournament/test match data has been created as part of this schema verification.

## Important invariant

> Never replace `app_id` with `global_id`, never replace `global_id`, and never use `local_id` as a cross-device identity.
