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

Match and innings synchronization identifiers follow the same installation-scoped convention when those entities are uploaded:

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
4. Upload using `sync_id` as the idempotency key.
5. A successful insert or an already-existing identical event is an ACK.
6. Only after ACK, mark the local queue entry `synced`.
7. Network/auth/server failures mark the queue entry `failed` with an error and retry time.
8. An interrupted worker resets `in_progress` entries to `pending` on recovery.

## 5. Idempotency

The backend primary key is `ball_events.sync_id`.

The backend also enforces:

```text
unique (innings_sync_id, sequence_number)
unique (source_installation_id, local_id)
```

A retry of the same event must never create a second delivery.

The client must not silently replace a different event occupying the same innings/sequence position. Such a response is a divergence/conflict requiring explicit recovery handling.

## 6. Ordering

Within an innings, `sequence_number` is the authoritative delivery order.

The sync worker should normally upload:

```text
innings 1: sequence 1, 2, 3, ...
innings 2: sequence 1, 2, 3, ...
```

The server must not use arrival time as scoring order.

Realtime consumers must order events by `sequence_number`, not websocket arrival order.

## 7. Recovery

The local queue persists:

- attempt count
- status
- next retry time
- last error
- successful sync time

A worker can therefore stop at any point without losing the local event or needing the scorer to re-enter it.

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

The Flutter app now includes `supabase_flutter` and a build-time configuration layer. Supabase is initialized only when both values are supplied:

```text
--dart-define SUPABASE_URL=...
--dart-define SUPABASE_PUBLISHABLE_KEY=...
```

If these values are absent, the app continues in local-only/offline mode. No credentials are committed to the repository.

The Supabase client provider exposes the configured client to future authenticated sync services.

## 11. Next implementation

The next code layer will provide:

1. Auth/session handling.
2. A transport interface implementation for authenticated BallEvent upload/download.
3. Exponential retry/backoff policy around the existing persisted queue.
4. Parent match/innings synchronization before BallEvent upload.
5. Pull/reconciliation for reconnecting clients.
6. Divergence reporting and recovery UI.
