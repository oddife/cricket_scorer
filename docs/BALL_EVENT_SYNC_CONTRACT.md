# BallEvent Synchronization Contract

This document defines the first transport contract between the offline Flutter scorer and the self-hosted Supabase backend.

## 1. Authority

- Drift/SQLite is authoritative while scoring locally.
- A BallEvent is immutable once written locally.
- Supabase is the shared synchronization/distribution layer.
- Scores, wickets, overs, statistics, strike, targets, and broadcast state are derived from BallEvents.

## 2. Stable identifiers

Every installation has one persistent `installation_id` stored in local `sync_metadata`.

A local BallEvent receives a stable synchronization identifier:

```text
<installation_id>:ball:<local_ball_event_id>
```

The same `sync_id` is sent on every retry. SQLite auto-increment IDs are never treated as globally unique by the backend.

Match and innings synchronization identifiers follow the same installation-scoped convention:

```text
<installation_id>:match:<local_match_id>
<installation_id>:innings:<local_innings_id>
```

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

No derived score, current striker, current bowler, or current over is required in the BallEvent upload.

## 4. Upload rules

1. Read pending queue entries in `innings_id` + `sequence_number` order.
2. Mark the queue entry `in_progress` before network upload.
3. Load the referenced local BallEvent.
4. Ensure the authenticated session is available.
5. Upload using `sync_id` as the idempotency key.
6. A successful insert is an ACK.
7. A duplicate `sync_id` is accepted only when the existing server payload exactly matches the local event.
8. Network/auth/server failures mark the queue entry `failed` with an error and retry time.
9. An interrupted worker resets `in_progress` entries to `pending`.

## 5. Idempotency

The backend primary key is `ball_events.sync_id`.

The backend also enforces:

```text
unique (innings_sync_id, sequence_number)
unique (source_installation_id, local_id)
```

A retry of the same event must never create a second delivery.

The client must not silently replace a different event occupying the same innings/sequence position. A duplicate sync ID with different payload is a divergence/conflict.

## 6. Ordering

Within an innings, `sequence_number` is the authoritative delivery order.

The sync worker normally processes pending work in:

```text
innings 1: sequence 1, 2, 3, ...
innings 2: sequence 1, 2, 3, ...
```

The server must not use arrival time as scoring order.

Realtime consumers must order events by `sequence_number`, not websocket arrival order.

## 7. Recovery and retry

The local queue persists:

- attempt count
- status
- next retry time
- last error
- successful sync time

The sync worker resets interrupted `in_progress` work and applies exponential retry backoff capped at the configured maximum delay.

A worker can therefore stop at any point without losing the local event or requiring the scorer to re-enter it.

## 8. Conflicts

BallEvents are immutable facts. There is no normal server-side UPDATE/DELETE path for synchronized BallEvents.

Examples of divergence include:

- same `sync_id` with different event payload
- same innings/sequence containing different `sync_id`
- missing parent match/innings record
- invalid authenticated scorer assignment

These must be surfaced as synchronization errors rather than silently overwriting scoring history.

## 9. Realtime

After an event is accepted by Supabase, Realtime distributes the inserted BallEvent to subscribed live clients.

Live clients rebuild their displayed innings state from the ordered event history. They do not maintain a separate authoritative score.

## 10. Current implementation

The Flutter app now includes:

- `supabase_flutter` initialization behind build-time configuration.
- `SupabaseAuthService` for email/password sign-in, sign-up, sign-out, session access, and auth-state changes.
- `SupabaseBallEventTransport` for authenticated BallEvent insertion.
- Duplicate-event verification: an existing `sync_id` is only treated as successfully synchronized when its payload matches the local event.
- `SyncRetryPolicy` for deterministic exponential backoff.
- `SyncWorker` for durable queue processing, local BallEvent lookup, ACK handling, failure recording, and interrupted-work recovery.
- Riverpod provider wiring for the sync worker.
- Supabase migration `0002_match_sync_access.sql` for the first authenticated match-sync bootstrap access rules.

No Supabase URL, key, password, or service-role secret is committed. When build-time Supabase configuration is absent, the app remains local-only/offline.

## 11. Important current limitation

The first worker is intentionally focused on the BallEvent transport. Parent match/innings records must exist on the backend before the BallEvent foreign keys can accept an event. Parent synchronization and richer Team/Player data synchronization are the next backend layer; the worker currently reports the server failure through the durable retry queue rather than bypassing the foreign-key contract.

## 12. Next implementation

1. Parent match/innings synchronization before BallEvent upload.
2. Team/Player synchronization so public scorecards can resolve names rather than only IDs.
3. Pull/reconciliation for reconnecting clients.
4. Divergence reporting and recovery UI.
5. Background/foreground sync scheduling and connectivity-triggered retries.
6. Realtime subscriptions for public live scorecard and broadcast clients.
