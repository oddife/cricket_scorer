# BallEvent Synchronization Contract

This document defines the transport contract between the offline Flutter scorer and the self-hosted Supabase backend.

## 1. Authority

- Drift/SQLite is authoritative while scoring locally.
- A BallEvent is immutable once written locally.
- Supabase is the shared synchronization/distribution layer.
- Scores, wickets, overs, statistics, strike, targets, and broadcast state are derived from BallEvents.

## 2. Stable identifiers

Every installation has one persistent `installation_id` stored in local `sync_metadata`. This identifies the device installation for audit/recovery metadata; it is **not** the identity of a match.

Matches, innings, BallEvents, Teams, Players, and TeamPlayer memberships now receive persistent synchronization IDs stored locally in `sync_entity_identities`.

Conceptually:

```text
Team local ID 12
→ stable team sync ID: <UUID>

Player local ID 42
→ stable player sync ID: <UUID>

TeamPlayer local ID 8
→ stable team-player sync ID: <UUID>
```

SQLite auto-increment IDs are local only and are never treated as globally unique by the backend. The installation ID remains in `source_installation_id` for audit/source metadata.

## 3. BallEvent payload

The backend payload represents the complete persisted BallEvent plus the wicket context required to reconstruct it exactly.

Conceptually:

```text
sync_id
source_installation_id
local_id
match_sync_id
innings_sync_id
sequence_number
over_number
legal_ball_number
bowler_id
striker_id
non_striker_id
delivery_type
is_legal_ball
batter_runs
bye_runs
leg_bye_runs
wide_runs
no_ball_runs
total_runs
wicket_type
dismissed_player_id
fielder_id
run_out_end
credited_to_bowler
wicket_completed_runs
wicket_crossed_before_wicket
replacement_batter_id
event_timestamp
```

No derived score, current striker, or current over is required in the BallEvent upload.

## 4. Parent upload ordering

The sync worker uploads reference data before Match/Innings/BallEvents:

1. Upload Teams using stable Team IDs.
2. Upload Players using stable Player IDs.
3. Upload active TeamPlayer memberships using stable Team and Player IDs.
4. Resolve/create the stable Match sync ID and upload/update the Match.
5. Resolve/create the stable Innings sync ID and upload/update the Innings referencing the stable Match sync ID.
6. Resolve/create the stable BallEvent sync ID.
7. Upload the BallEvent referencing the stable Match and Innings IDs.

This establishes the reference-data layer needed for remote scorecards while keeping local SQLite authoritative.

## 5. Upload rules

1. Read pending queue entries in `innings_id` + `sequence_number` order.
2. Mark the queue entry `in_progress` before network upload.
3. Load the referenced local BallEvent.
4. Ensure the authenticated session is available.
5. Ensure Team/Player reference data and Match/Inn­ings parents exist remotely.
6. Upload using stable `sync_id` values as idempotency keys.
7. A successful insert/upsert is an ACK.
8. BallEvent duplicates are accepted only when the existing server payload exactly matches the local event.
9. Network/auth/server failures mark the queue entry `failed` with an error and retry time.
10. An interrupted worker resets `in_progress` entries to `pending`.

## 6. Idempotency

The backend identity for synchronized entities is their stable `sync_id`.

The backend also enforces sequence uniqueness within an innings so two different events cannot silently occupy the same delivery position.

A retry of the same event must never create a second delivery.

A different BallEvent occupying the same innings/sequence position is a divergence/conflict rather than an overwrite.

## 7. Ordering

Within an innings, `sequence_number` is the authoritative delivery order.

The sync worker normally processes pending work in:

```text
innings 1: sequence 1, 2, 3, ...
innings 2: sequence 1, 2, 3, ...
```

The server must not use arrival time as scoring order.

Realtime consumers must order events by `sequence_number`, not websocket arrival order.

## 8. Recovery and retry

The local queue persists attempt count, status, next retry time, last error, and successful sync time. The worker resets interrupted `in_progress` work and applies exponential retry backoff capped at the configured maximum delay.

Stable entity IDs additionally allow a later client to refer to the same synchronized entities rather than generating a second device-specific identity.

## 9. Conflicts

BallEvents are immutable facts. There is no normal server-side UPDATE/DELETE path for synchronized BallEvents.

Examples of divergence include:

- same BallEvent `sync_id` with different event payload
- same innings/sequence containing different `sync_id`
- missing parent Match/Innings/Team/Player record
- invalid authenticated scorer assignment
- two devices attempting to advance the same match without an agreed takeover/lease

These must be surfaced as synchronization errors rather than silently overwriting scoring history.

## 10. Realtime

After an event is accepted by Supabase, Realtime distributes synchronized records to subscribed live clients.

Live clients rebuild displayed innings state from ordered event history. They do not maintain a separate authoritative score.

## 11. Current implementation

The Flutter app now includes:

- `supabase_flutter` initialization behind build-time configuration.
- `SupabaseAuthService` for email/password sign-in, sign-up, sign-out, session access, and auth-state changes.
- `SupabaseBallEventTransport` for authenticated BallEvent insertion using stable entity IDs.
- `SupabaseMatchTransport` for authenticated Match and Innings parent upload using stable entity IDs.
- `SupabaseTeamPlayerTransport` for authenticated Team, Player, and active TeamPlayer membership upload.
- Persistent installation identity for audit/source metadata.
- Persistent Team, Player, TeamPlayer, Match, Innings, and BallEvent synchronization identities in local SQLite.
- `SyncWorker` reference-data upload before Match/Innings/BallEvent upload.
- Duplicate BallEvent verification and deterministic retry handling.
- Supabase migrations `0002_match_sync_access.sql`, `0003_stable_sync_ids.sql`, and `0004_team_player_sync.sql`.

No Supabase URL, key, password, or service-role secret is committed. When build-time Supabase configuration is absent, the app remains local-only/offline.

## 12. Important current limitation

Stable IDs and reference-data upload are now in place, but cross-device recovery is **not complete yet**.

The remaining recovery layer must:

- discover synchronized matches on a new device;
- pull Match, Innings, Team, Player, TeamPlayer, and BallEvent records into local SQLite;
- map remote stable IDs to new local integer IDs safely;
- reconcile events in sequence order;
- prevent duplicate imports;
- detect divergence;
- provide an explicit device takeover/lease mechanism so an old scorer cannot continue writing after another device takes control.

The current worker is still primarily an upload worker. It does not yet implement remote pull/reconciliation or takeover.

## 13. Next implementation

1. Pull/reconciliation for reconnecting clients and new devices.
2. Match discovery/recovery UI.
3. Explicit scorer ownership/takeover lease.
4. Divergence reporting and recovery UI.
5. Background/foreground sync scheduling and connectivity-triggered retries.
6. Realtime subscriptions for public live scorecard and broadcast clients.
