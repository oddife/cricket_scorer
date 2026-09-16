# Cricket Scorer

A serious Flutter cricket scoring application built from the ground up. This README is the **project handover / continuity document** for the application. It records the important product decisions, cricket rules, architecture, workflows, implementation status, and known limitations so development can continue without reconstructing previous discussions.

> **Important:** Update this README whenever a major product, rules, architecture, workflow, database, sync, backend, or implementation decision changes. Do not silently change a locked cricket rule or product requirement.

---

## Current Development Status

The core offline-first live scoring workflow is functional. A real 4-innings match workflow has been manually tested successfully. The latest verified automated test run is **97/97 tests passing**, and the latest verified `flutter analyze` run reports **no issues**.

The current branch is:

```text
feature/live-wicket-delivery-dialog-v2
```

Recently implemented/updated:

- Ball-by-ball UI derived directly from persisted `BallEvent` history.
- Optional wicket workflow for Normal, Wide, No-ball, Bye, and Leg-bye deliveries.
- Delivery-only confirmation when no wicket is selected.
- Explicit **End Innings** workflow.
- Non-final innings transitions to Opening Innings Setup.
- Final innings can transition into Match Completed.
- Match result logic recognizes a chase reaching the target before the scheduled innings limit.
- Manually ended final innings is treated as final for result evaluation.
- Ball-event provider refreshes after scoring and undo.
- Tournament/team persistence is implemented.
- Tournament standings are derived from tournament match results.
- **Tournament points are customizable per tournament.** Defaults are Win 2, Tie 1, No Result 1, Loss 0.
- Tournament points rules are persisted locally in Drift/SQLite.
- Recent Matches identifies tournament matches with a tournament tag and displays the tournament name where available; normal matches remain distinguishable from tournament matches.
- Match completion persistence is implemented.
- Compact Short Match PDF and detailed Full Match PDF export are implemented.
- One **Export Match PDF** action lets the scorer choose Short or Full.
- Full PDF ball-by-ball is grouped by over.
- Self-hosted Supabase/PostgreSQL/Realtime is the approved backend direction.
- Local Drift/SQLite remains authoritative for offline scoring.
- Local sync foundation is implemented: persistent installation identity, durable sync queues, idempotent queue insertion, upload status/retry metadata, ordering fields, and recovery of interrupted in-progress work.
- Stable sync identities now exist for matches, innings, ball events, teams, players, team-player relationships, and tournaments.
- Supabase sync schema covers matches, innings, ball events, teams, players, team-player relationships, match teams, match players, tournaments, tournament teams, and tournament points rules.
- Tournament synchronization is implemented and integrated into the sync worker.
- Match synchronization carries the stable tournament relationship through `tournament_sync_id`.
- Recovery/import restores tournament metadata and is scoped to the teams participating in the recovered match.
- Recovery preserves existing local tournament points rules and rejects divergent remote rules transactionally instead of silently overwriting local configuration.
- Settings provides Supabase connection status, a connection/sync log, and a **Sync Now** action.

### Current verification status

Latest verified local run:

```text
flutter analyze
No issues found!

flutter test
+97: All tests passed!
```

Do not change this verification count unless a newer run is actually performed.

---

## 1. Project Goal

Build a serious, offline-first cricket scoring application with one Flutter codebase for:

- Android
- iPhone / iPad
- Windows desktop (`.exe`)
- Web / browser

The application must provide fast live scoring, persistent ball-by-ball history, scorecards, statistics, tournaments, records, management tools, public live score sharing, and future broadcast integrations.

The app is being built separately from the previous React/TypeScript scorer. Do not copy old architecture assumptions into this project.

---

## 2. Core Product Principles

1. **Ball-by-ball data is the source of truth.**
2. Every delivery is stored as one atomic `BallEvent`.
3. Save after every scoring action.
4. Scores, batter statistics, bowler statistics, strike, overs, and rotation are derived from ball history rather than maintained as competing authoritative state.
5. Scoring/rules logic must be pure Dart and independently testable.
6. UI must not contain cricket-rule calculations.
7. Keep modules/services/models/repositories/screens separated; avoid monolithic screens.
8. Offline operation is required.
9. Backup/import/export is required.
10. **Live/cloud sync must never be required for scoring.** Local Drift/SQLite is the offline source of persisted match facts; the synchronized backend is a shared live distribution layer.
11. Global Teams and Players are reusable entities. A match does not create duplicate copies merely because they are used by that match.
12. Do not invent cricket rules. Use normal cricket Laws except for explicitly agreed custom features.
13. The scorer should make as few taps as practical during live scoring.
14. **One match → one source of truth → multiple live clients.** Scorer, public scorecard, broadcast graphics, and future displays must derive from the same synchronized match history.

---

## 3. Architecture

```text
Flutter UI
    ↓
Riverpod / ViewModels
    ↓
Application Services
    ↓
Domain
 ├── Cricket Rules Engine
 ├── Scoring Engine
 ├── Strike Engine
 ├── Bowler Rotation Engine
 ├── Innings Engine
 ├── Match Result Engine
 ├── Statistics Engine
 └── Recalculation Engine
    ↓
Repositories
    ↓
Drift / SQLite
    ↓
Sync Queue
    ↓
Supabase
 ├── PostgreSQL
 ├── Auth
 ├── Realtime
 ├── API
 └── Studio
    ↓
Live Clients
 ├── Public Web Scorecard
 ├── Windows Broadcast Client
 ├── vMix / OBS Browser Overlays
 └── Future External Displays
```

### Technology

- Flutter / Dart
- Riverpod 3.x
- Drift / SQLite
- go_router
- Shared Preferences where appropriate for app preferences
- Self-hosted Supabase
- PostgreSQL
- Supabase Auth
- Supabase Realtime
- Supabase API
- Supabase Studio
- Docker
- Traefik/HTTPS where appropriate for external access

The backend is a **live synchronization/distribution layer**, not a replacement for offline local scoring.

---

## 4. Main Navigation

```text
🏠 Home
🏆 Tournaments
🏏 Matches
👥 Teams
🧑 Players
📊 Records
⚙️ Management
```

Home order:

```text
CRICKET SCORER

🏆 TOURNAMENT
🏏 NORMAL MATCH

LIVE MATCHES
RECENT MATCHES
```

Responsive layout:

- Phone → bottom NavigationBar
- iPad / tablet → NavigationRail
- Windows → NavigationRail
- Web → NavigationRail
- Do not simply stretch the phone UI to desktop.

---

# 5. Tournament

Tournament setup happens before tournament match setup.

Supported tournament types:

- League
- Knockout
- League + Knockout

Optional tournament logo/photo.

Teams and Players are global entities.

Tournament setup can:

- Add New Team
- Select Existing Team
- Add New Player
- Select Existing Player

Do not create duplicate global Team/Player entities just because they are used by a tournament.

Inside a tournament:

```text
Matches
Teams
Players
Standings
Results
Records
+ New Match
```

Tournament type DB mapping is stable:

```text
league = 0
knockout = 1
leagueAndKnockout = 2
```

### Tournament points

Each tournament has persisted points rules.

Default rules:

```text
Win       = 2
Tie       = 1
No Result = 1
Loss      = 0
```

The values are customizable per tournament and are stored in the local Drift/SQLite database.

The standings are derived from match results and the tournament's current points rules; standings are not maintained as an independent authoritative table.

---

# 6. Normal Match

A standalone match can use global Teams/Players or create new ones during setup. Newly created Team/Player records are persisted globally and then used by the match.

No duplicate copies are created merely for a match.

## Match Setup

Fields / options:

- Match name
- Date
- Venue
- Number of innings: 2 or 4
- Overs per innings: custom
- Players per team: custom
- 2-Bowler Mode: on/off
- Teams
- Player selection
- Toss

### Match type

Match type is **Custom**. Do not reintroduce predefined T10/T20/ODI format choices unless explicitly requested.

### Balls per over

**NOT a user setting.** Standard cricket uses 6 legal balls per over. The app must not expose a configurable balls-per-over option.

Internal models may retain `ballsPerOver` where required by the scoring engine, but the normal value is fixed to **6**.

---

# 7. Player Selection Before Match

`playersPerTeam` is the configured/normal maximum team size. It is **not a requirement that the scorer must have all players available before starting**.

Rules:

- Initial selection may contain fewer players than `playersPerTeam`.
- It may not exceed `playersPerTeam`.
- At least 2 available players per team are required so an opening batting pair can be selected.
- Player selection does **not** determine batting order.
- Batting order is handled separately after player selection.
- A player can be added later during the match.

---

# 8. Opening Innings Setup

After player selection, there is a separate Opening Innings Setup screen.

It asks for:

### Batting

- Opening striker
- Opening non-striker

They must be different and currently available batting-team players.

### Bowling — normal mode

- Opening bowler

### Bowling — 2-Bowler Mode

- Opening bowler 1
- Opening bowler 2

The two opening bowlers must be different and available from the bowling team.

The setup creates the innings and persists the opening striker/non-striker/bowler metadata.

The second opening bowler in 2-Bowler Mode is currently held in live Riverpod scoring state rather than persisted as innings DB metadata. If persistence across app restart becomes necessary, implement it with a proper schema migration or dedicated persisted structure; do not encode IDs into unrelated fields.

---

# 9. Toss and Innings Order

Toss is part of Match Setup.

Fields:

- Toss winner
- Decision: Bat / Bowl

Toss determines the first batting team.

For 4 innings, the order is automatically:

```text
A → B → A → B
```

The scorer does not manually choose the batting team for later innings.

Opening setup calculates the next innings number and correct batting/bowling teams from toss + innings parity.

---

# 10. Match Formats and Results

## Two innings

```text
A → B
```

- B reaches A's target → B wins by wickets immediately.
- B remains below target → A wins by runs when the final innings is complete or manually ended.
- Equal score → tie when the final innings is complete.

## Four innings

Locked format:

```text
A → B → A → B
```

Aggregate / Test-style scoring with custom innings limits.

Rules:

- Each innings has its configured overs/custom limit.
- No follow-on.
- No declarations.
- No draw logic.
- No unlimited innings.

The final target is based on the aggregate scores of the first team's two innings. Target completion before the scheduled innings limit ends the chase.

---

# 11. Two-Bowler Mode — LOCKED RULE

Two selected bowlers alternate on **every legal delivery**.

For six legal balls:

```text
1 → A
2 → B
3 → A
4 → B
5 → A
6 → B
```

Then a new pair is selected for the next two-over block.

Rules:

- Pairs are not permanent.
- A pair is selected for a two-over block.
- A bowler cannot bowl consecutive overs.
- Rotation is based on **legal balls**, not scoring button presses.
- Wides and no-balls do not advance the legal-ball count.
- Wides and no-balls therefore do not switch the active bowler.
- The Bowler Rotation Engine owns this behavior.

For an odd number of configured overs, the final odd over is bowled by one selected bowler.

Examples:

```text
3 overs → first 2 overs are a two-bowler block; final 3rd over is single bowler.
5 overs → first 4 overs are blocks; final 5th is single bowler.
7 overs → first 6 overs are blocks; final 7th is single bowler.
```

A bowler cannot bowl two overs consecutively, including parts of consecutive overs.

Invalid bowler selection should show a validation error while keeping the live scoring screen usable.

---

# 12. BallEvent — Source of Truth

One delivery = one atomic event.

Conceptual structure:

```text
BallEvent
├── id
├── inningsId
├── sequenceNumber
├── overNumber
├── legalBallNumber
├── bowlerId
├── strikerId
├── nonStrikerId
├── deliveryType
├── isLegalBall
├── batterRuns
├── byeRuns
├── legByeRuns
├── wideRuns
├── noBallRuns
├── totalRuns
├── wicket
│   ├── type
│   ├── dismissedPlayerId
│   ├── fielderId
│   └── runOutEnd
└── timestamp
```

Current persisted ball events also include `creditedToBowler` and nullable wicket fields.

Unique key:

```text
(inningsId, sequenceNumber)
```

Overs are derived from ball events. Permanent batter/bowler stats are not the initial source of truth; they are derived from events.

---

# 13. Innings Model

Current persisted innings metadata includes:

```text
id
matchId
inningsNumber
battingTeamId
bowlingTeamId
openingStrikerId
openingNonStrikerId
openingBowlerId
oversPerInnings
ballsPerOver
2BowlerMode
status
startedAt
completedAt
```

Unique key:

```text
(matchId, inningsNumber)
```

Statuses:

```text
setup
live
completed
ended
```

`ballsPerOver` remains internally available but is fixed to 6 for normal cricket and is not a setup option.

`ended` represents an explicit scorer action to end an innings. Result evaluation treats an ended final innings as complete for match-result purposes.

---

# 14. Scoring Engine

The scoring engine is pure Dart and creates persisted `BallEvent` records from scoring input.

Responsibilities include:

- Delivery legality
- Legal-ball numbering
- Total runs
- Extras
- Wicket bowler credit
- Wicket legality combinations

Normal/bye/leg-bye deliveries are legal.

Wide/no-ball deliveries are illegal.

`legalBallNumber` advances only for legal deliveries.

### Wicket credit

Bowler credited:

- Bowled
- Caught
- LBW
- Stumped
- Hit Wicket
- Over Fence

Bowler not credited:

- Run Out
- Retired
- Obstructing the Field

The engine determines this from wicket type; the UI must not decide it independently.

---

# 15. Wicket Rules

Supported wicket types:

- Bowled
- Caught
- LBW
- Run Out
- Stumped
- Hit Wicket
- Retired
- Obstructing Field
- Over Fence (custom)

The delivery-aware wicket workflow supports Normal, Wide, No-ball, Bye, and Leg-bye delivery types. Wicket selection is optional for these delivery actions.

Run Out uses the run-out end, completed runs, and crossing before the wicket where applicable. Validation must not be weakened merely to make the UI accept ambiguous input.

Batter replacement is explicit. The application must never invent a replacement batter.

---

# 16. Live Scoring UI

Live scoring is driven by persisted match state and ball history.

Important behavior:

- Save after every scoring action.
- Undo removes/reverses the latest event through the application workflow rather than maintaining a separate score-only state.
- Ball-by-ball history refreshes after scoring and undo.
- Invalid scoring/bowler validation is shown as a user-facing action error/snackbar; scorer providers must not turn normal validation failures into unusable `AsyncError` states.
- When an innings is complete, scoring controls disappear.
- Non-final innings moves to Opening Innings Setup.
- Final innings can complete the match.
- Live target/need and 4-innings lead/deficit are recalculated from persisted events.

---

# 17. Tournament Management and Recent Matches

Tournament Management currently supports participating teams and editable points rules.

The points card exposes:

```text
Win
Tie
No Result
Loss
```

Each value is validated as an integer from 0 to 99 and persisted locally.

Recent Matches distinguishes:

```text
NORMAL
<tournament name>
```

Tournament matches are identified from the persisted `match.tournamentId` relationship. The tournament name is used for the tournament tag when available.

---

# 18. PDF Export

Dependencies:

- `pdf`
- `printing`

One **Export Match PDF** action offers:

```text
Short
Full
```

### Short PDF

- Compact traditional scorecard
- No ball-by-ball
- Normally 1–2 pages

### Full PDF

- Full scorecard information
- Ball-by-ball grouped by overs

Recent Matches provides PDF export for completed matches.

---

# 19. Local Database

Drift/SQLite is the authoritative local database.

The database currently contains the core entities for:

- Players
- Teams
- TeamPlayers
- Tournaments
- TournamentTeams
- Tournament points rules
- Matches
- MatchTeams
- MatchPlayers
- Innings
- BallEvents
- Sync identities
- Sync queues

Tournament points rules are stored separately from the tournament record so changing a tournament's scoring rules does not require storing a duplicated standings table.

The current database schema version is **12**.

The catalog sync queue is durable and includes teams, players, team-player memberships, and tournaments. Queue entries carry stable sync IDs, status, attempts, retry timing, and error metadata.

---

# 20. Supabase Synchronization

Supabase synchronization is implemented incrementally. Local SQLite remains authoritative.

The current server migration sequence is:

```text
0001_sync_schema.sql
0002_match_sync_access.sql
0003_stable_sync_ids.sql
0004_team_player_sync.sql
0005_match_participants_sync.sql
0006_tournament_sync.sql
0007_tournament_team_delete.sql
0008_match_participant_delete.sql
0009_match_constraints.sql
```

### Important migration detail

`0001_sync_schema.sql` already defines the stable sync ID columns as text. Therefore `0003_stable_sync_ids.sql` only adds the required unique/index structures; it does not attempt to alter the existing sync ID column types. This avoids PostgreSQL errors caused by RLS policies depending on those columns.

`0009_match_constraints.sql` adds `NOT VALID` constraints for future writes covering the locked match/innings rules, including 2-or-4 innings, positive overs/player counts, six balls per over, valid statuses/toss values, and six-ball innings configuration.

Current synchronized entities include:

- Matches
- Innings
- Ball events
- Teams
- Players
- Team-player memberships
- Match teams
- Match players
- Tournaments
- Tournament teams
- Tournament points rules

Stable sync identities are generated and persisted locally rather than relying on device-specific integer primary keys.

### Tournament synchronization

Tournament synchronization is implemented through the same stable identity and durable catalog queue architecture.

The server model is:

```text
public.tournaments
public.tournament_teams
public.tournament_points_rules
```

and `public.matches` carries a nullable stable `tournament_sync_id` rather than using a device-local tournament integer as the cross-device identity.

Tournament synchronization preserves:

- Tournament identity
- Tournament name/type/logo/date/active state
- Participating teams
- Custom points rules
- Match-to-tournament association

Tournament and participant removals are represented remotely by replacing the authoritative relationship set where appropriate. Team-player membership removal is represented as an inactive membership rather than deleting the catalog identity.

### Sync Worker ordering

The SyncWorker:

1. Resets interrupted in-progress queue entries.
2. Ensures the installation identity exists.
3. Seeds missing catalog queue entries.
4. Processes catalog entries in dependency order.
5. Waits for required catalog dependencies before uploading dependent match data.
6. Uploads match metadata, participants, innings, and ball events.
7. Applies retry metadata for retryable failures.

Catalog dependency order is:

```text
team
player
team_player
 tournament
```

with dependent match data gated until required catalog entities are synchronized.

Inactive team-player memberships remain available locally and are uploaded with `is_active = false` so a removal can propagate to the server.

### Settings / manual sync

Management → Settings provides:

- Supabase configuration fields
- Actual connection status check
- Connection/sync log
- **Sync Now** action

The connection status is based on a real Supabase table request rather than only checking whether configuration fields are populated.

---

# 21. Sync Identity

Stable local-to-server identities are maintained through a generic identity repository.

Current entity types include:

```text
match
innings
ball
team
player
team_player
tournament
```

Tournament identity uses the same mechanism as the other synchronized catalog entities.

Repository methods include:

```dart
ensureTournamentSyncId(int tournamentId)
getTournamentSyncId(int tournamentId)
```

No unrelated local integer IDs are encoded into sync identity fields.

---

# 22. Sync Queue and Catalog Reconciliation

There are durable queues for match ball events and catalog entities.

Catalog queue entries contain:

```text
id
syncId
entityType
entityId
status
attempts
createdAt
nextAttemptAt
lastError
syncedAt
```

Queue behavior includes:

- Idempotent enqueue-if-missing behavior.
- Explicit requeue for local mutations that need to be uploaded again.
- Retry scheduling after failures.
- Reset of interrupted `in_progress` work after restart.
- Dependency-aware processing.
- Deterministic ordering for catalog uploads.

Repository mutations enqueue the affected catalog entity. This includes team, player, team-player, tournament, tournament points rules, and tournament membership changes.

For authoritative relationship sets such as tournament teams and match participants, upload replaces the remote relationship set with the current local set. This allows local removals to propagate without inventing delete events in the local scoring model.

---

# 23. Recovery

Supabase recovery is read-only from the server snapshot into local SQLite.

Current recovery supports synchronized match data including:

- Match
- Match teams
- Match players
- Teams
- Players
- Team memberships
- Innings
- Ball events
- Tournament metadata
- Tournament teams relevant to the recovered match
- Tournament points rules
- Match tournament association

Recovery catalog queries are scoped to the dependencies of the recovered match rather than importing unrelated global tournament membership.

Imported rows are not re-added to the upload queue.

Existing local entities are compared against the remote snapshot. Divergent synchronized facts cause recovery to fail rather than silently overwrite local authoritative data.

Tournament points have an additional protection: if local tournament points rules already exist, remote recovery must match them exactly. Divergent remote points cause the transaction to abort. If local rules are missing, the remote rules may be imported.

The recovery importer is transactional, so a validation/divergence failure rolls back earlier changes from the same import.

---

# 24. Match Player Management — Planned

Future Match Controls → Players functionality should support:

- Add Player
- Move an unused player between teams
- Manage batting order

A player may move teams only when there is no ball/event participation that would make the change historically invalid.

Do not modify historical ball events to make a late roster change appear to have existed earlier.

---

# 25. Locked Rules / Do Not Regress

The following decisions are locked unless explicitly changed by the project owner:

- Match type is always **Custom**.
- Balls per over are fixed at **6**.
- 2 innings = `A → B`.
- 4 innings = `A → B → A → B`.
- No follow-on.
- No declarations.
- No draw logic.
- No unlimited innings.
- `playersPerTeam` is a maximum/configured team size, not a requirement to have every player before match start.
- Minimum 2 available players per team before starting.
- Player selection and batting order are separate.
- Missing players may be added after match start.
- Toss determines innings order.
- BallEvent is the scoring source of truth.
- Save after every scoring action.
- Wides and no-balls do not advance legal-ball count or 2-Bowler rotation.
- Bowler consecutive-over restrictions remain enforced.
- Batter replacement is explicit; never invent a batter.
- Local SQLite remains authoritative even when Supabase is unavailable.
- UI must not contain cricket-rule calculations.
- Tournament standings are derived from results and customizable tournament points rules.
- Recovery must not silently overwrite divergent local synchronized facts.

---

# 26. Development Workflow

For development sessions:

1. Keep the existing scoring architecture intact.
2. Make the smallest coherent change for the requested feature.
3. Add/update tests for domain and repository behavior.
4. Run `git pull` first when continuing work on the branch.
5. Run `flutter analyze`.
6. Run `flutter test`.
7. Manually test the affected workflow where practical.
8. Update this README for major product/architecture/database/sync decisions.
9. Commit the completed change to the active feature branch.

Do not claim tests or analyzer status without actually running them.

---

# 27. Current Next Step

The tournament Supabase synchronization block is now implemented and verified. The next development phase should be a **sync/recovery audit and integration hardening pass**, not a redesign.

Recommended audit order:

1. Verify catalog retry behavior and dependency ordering under failures/restarts.
2. Verify local tournament membership changes do not overwrite unrelated local/server state.
3. Verify match participant removal/re-addition behavior across sync.
4. Exercise recovery against a populated tournament with additional unrelated teams and confirm only match dependencies are imported.
5. Exercise divergent tournament points recovery and confirm the entire import rolls back.
6. Verify the self-hosted Supabase deployment against the current migrations and RLS policies.
7. Add/expand integration-style transport tests where practical.
8. Continue feature work only after the synchronization invariants remain intact.

The implementation must remain offline-first throughout this work.
