# Cricket Scorer

A serious Flutter cricket scoring application built from the ground up. This README is the **project handover / continuity document** for the application. It records the important product decisions, cricket rules, architecture, workflows, implementation status, and known limitations so development can continue without reconstructing previous discussions.

> **Important:** Update this README whenever a major product, rules, architecture, workflow, database, sync, backend, or implementation decision changes. Do not silently change a locked cricket rule or product requirement.

---

## Current Development Status

The core offline-first live scoring workflow is implemented. The current feature branch includes recent changes for live player additions, opening-batter corrections, four-innings chase-target handling, and a suggested Man of the Match at the end of the final innings.

The current branch is:

```text
fix/two-bowler-pair-selection-lock
```

**Verification caution:** The previously documented baseline was 97/97 tests passing with no `flutter analyze` issues. Those checks have not been rerun after the latest feature-branch changes, so the baseline must not be treated as verification of the current branch. A normal GitHub Actions workflow now runs `flutter analyze`, `flutter test`, and a release Web build for this branch; the latest run is in progress and is not yet a verified pass.

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
- Live scoring allows adding an existing global player or creating a new player for either match team, including late-arriving bowlers and batters. Added players are made available immediately, duplicate assignments are prevented, and the configured team-size maximum is enforced.
- Before the first delivery, the scorer can correct the opening striker and non-striker from the live scoring screen; the corrected opening pair is persisted so it survives a reload. After scoring begins, manual batter selection is restricted to players already participating in the innings; new batters enter through wicket replacement.
- The final-innings completion panel shows a **Suggested Man of the Match** based on aggregate recorded contributions across the match. The suggestion is not automatically awarded.
- The current-over delivery strip keeps balls on a single horizontal line; a short horizontal scroll is available for overs with enough extras to exceed the screen width.
- In two-bowler mode with an odd innings length, the final single-bowler over disables the pair used in the previous two-over block. The selected final-over bowler is persisted across a restart.
- Cross-device sync hardening now preserves original source/local IDs, avoids overwriting catalog records with pending local edits, merges match participant/tournament-team relationships instead of deleting the whole server set each sync, and exposes automatic sync errors in Settings.
- Compact Short Match PDF and detailed Full Match PDF export are implemented.
- One **Export Match PDF** action lets the scorer choose Short or Full.
- Full PDF ball-by-ball is grouped by over.
- Self-hosted Supabase/PostgreSQL/Realtime is the approved backend direction.
- Local Drift/SQLite remains authoritative for offline scoring.
- Local sync foundation is implemented: persistent installation identity, durable sync queues, idempotent queue insertion, upload status/retry metadata, ordering fields, and recovery of interrupted in-progress work.
- Stable sync identities now exist for matches, innings, ball events, teams, players, team-player relationships, and tournaments.
- New ball events carry canonical `bowler_global_id`, `striker_global_id`, `non_striker_global_id`, and wicket-related player global IDs. Recovery resolves these before the legacy device-local integer fields, avoiding player-ID collisions between Android and Web installations.
- Match toss winners and innings setup now sync using canonical `global_id` references for the selected team, opening batters, opening bowler, and active two-bowler pair. Recovery resolves those before the legacy device-local IDs.
- Supabase sync schema covers matches, innings, ball events, teams, players, team-player relationships, match teams, match players, tournaments, tournament teams, and tournament points rules.
- Tournament synchronization is implemented and integrated into the sync worker.
- Match synchronization carries the stable tournament relationship through `tournament_sync_id`.
- Recovery/import restores tournament metadata and is scoped to the teams participating in the recovered match.
- Recovery preserves existing local tournament points rules and rejects divergent remote rules transactionally instead of silently overwriting local configuration.
- Global catalog pull is implemented: a fresh web/desktop client can download shared Teams, Players, Team Players, Tournaments, Tournament Teams, and Tournament Points Rules from Supabase into local Drift/SQLite.
- Global catalog pull uses stable `sync_id` identities and does not re-enqueue downloaded records for upload.
- Catalog download is paginated so larger global catalogs are supported.
- The SyncWorker uploads local catalog changes before pulling the shared catalog, then continues with match/scoring synchronization.
- Dockerized Flutter Web deployment is implemented on port `3112`, including the Drift WebAssembly assets and nginx WASM MIME handling.
- Direct Docker deployment on `:3112` has been manually verified with the global catalog pull.
- Cross-device catalog synchronization has been manually verified in both directions: PC → device and device → PC.
- A successful deployment test reported `Catalog sync: 33`, confirming the fresh web instance imported the existing shared catalog.
- Settings provides Supabase connection status, an **Automatic sync** status summary, a connection/sync log, and a **Sync Now** action. Ball-event upload failures, catalog failures, match-pull errors, and recovery errors are now surfaced instead of being silently swallowed.

### Current verification status

Previously documented baseline (before the latest feature-branch changes):

```text
flutter analyze
No issues found!

flutter test
+97: All tests passed!
```

The latest live-player, opening-batter, Man of the Match, sync-hardening, and scoring-UI changes still require a passing fresh `flutter analyze`, `flutter test`, and manual smoke test on Web and Android. The previous cross-device catalog check predates these new sync changes and is not verification of this revision.

Latest documented manual web deployment verification:

```text
Docker Flutter Web app
Direct access: :3112
Catalog sync: 33
PC → device catalog sync: verified
Device → PC catalog sync: verified
```

The web client previously required a full app refresh/reload for management screens to immediately display downloaded catalog records. The current sync changes request provider refreshes, but this revision still needs a fresh Web and Android smoke test.

### Docker and Android showing different data

Each installation has its own local Drift/SQLite database. They share data through Supabase, not through the Docker container's filesystem. Both clients must resolve to the **same exact Supabase project URL and publishable key**.

- For Docker, the web URL/key are build-time values passed through `docker/docker-compose.yml`. From the repository root, verify the root `.env` exists and rebuild with `docker compose --env-file .env -f docker/docker-compose.yml build --no-cache`, then recreate with `docker compose --env-file .env -f docker/docker-compose.yml up -d --force-recreate`.
- For Android, pass the same `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY` to `flutter build apk` using `--dart-define`, or configure the same values under Settings → Supabase. Values saved in Android shared preferences take precedence over build-time values; restart after changing them.
- On both clients, open Settings and compare the Supabase URL, then press **Sync Now**. The sync status should report catalog uploads/downloads, matches pulled, ball events uploaded, and any errors.

A schema mismatch can prevent cross-device sync. The live Supabase column audit on 2026-10-17 confirmed that the audited `0015` canonical relationship columns were present. Initially all six `0016` ball-event player-reference columns and all eight `0017` match/innings reference columns were missing; after applying the repository migrations `0016_ball_event_player_global_ids.sql` and `0017_match_innings_player_global_ids.sql`, a follow-up audit returned `6` and `8` present columns respectively. The query path `supabase_migrations.schema_migrations` was not available in this project, so the applied history was not verified through that table. The repository contains duplicate numeric migration prefixes (`0012` and `0013` have multiple files); inspect actual columns and review each exact migration before applying changes to a populated database.

### Sync triage and convergence — 2026-10-17 (Android APK and Docker Web)

The initial incident had backend-schema errors and cross-device recovery failures. The following observations are confirmed from user-provided Supabase query results and Settings screenshots.

**Schema and data repair**

- The audited canonical identity prerequisites and `0015` relationship columns were present in Supabase.
- Migrations `0016_ball_event_player_global_ids.sql` and `0017_match_innings_player_global_ids.sql` were applied. A read-only follow-up audit reported all six ball-event player-reference columns and all eight match/innings reference columns present (`6`, `8`).
- The Supabase migration-history query against `supabase_migrations.schema_migrations` failed because that relation was not available; migration history was not verified through that table.
- Match `b921490f-7cdf-413b-acf0-52be41466cd4` (`2nd match`) was confirmed to have zero `match_teams`, `match_players`, `innings`, and `ball_events` rows, then deleted by a guarded statement that required those counts to remain zero.
- After cleanup, Docker and Android reported `Automatic sync: OK`, zero ball-event upload failures, and no recovery errors. Android's screenshot reported 50 ball events uploaded successfully.

**Remaining behavior: sync converges over several cycles**

Data was appearing on the other client, but sometimes only after multiple automatic/manual sync passes. That points to ordering/concurrency around match recovery, rather than a remaining missing-column error. The following code changes have been pushed to this branch:

- Canonical player/team global IDs are used as a fallback when a legacy relationship `*_sync_id` is stale, but only if the canonical reference resolves to a catalog row. Unresolved identities still fail explicitly; recovery must not guess which player scored a delivery.
- Automatic five-second sync and Settings **Sync Now** share a single in-flight `SyncWorker.runOnce()` operation so they cannot concurrently reset or process the same durable queue.
- Newly created matches are initially written with `is_published = false`. The source client publishes them after it has uploaded the two match-team slots, at least one player assignment, and all currently stored innings. Match recovery explicitly lists only `is_published = true` rows, preventing a client from recovering a partially uploaded match.
- Existing published matches remain published during normal updates. Local Drift/SQLite remains authoritative for offline scoring; no local match database reset is part of this repair.

**Current verification status**

- At the time this note was updated, the latest CI run had passed Dart analysis, the full Flutter test suite, and the Flutter Web build. The Android APK build was still running; check [GitHub Actions](https://github.com/oddife/cricket_scorer/actions) for the final result before deploying that revision.
- The live clients previously reported zero failures, but that was before deploying the newest convergence changes. A clean **two-way** smoke test using the same revision on Docker Web and Android is still required: create/score one test match on the source client, confirm it appears with players/innings on the other client, then verify a subsequent scoring update travels back.
- Do not reset local databases or delete real matches to troubleshoot timing. Use one active scorer per match; concurrent independent scoring of the same match is not a conflict-free multi-writer workflow.

**Deployment commands from the repository root**

Docker Web:
```powershell
git fetch origin
git switch fix/two-bowler-pair-selection-lock
git pull --ff-only origin fix/two-bowler-pair-selection-lock
docker compose --env-file .env -f docker/docker-compose.yml build --no-cache
docker compose --env-file .env -f docker/docker-compose.yml up -d --force-recreate
```

Android APK:
```powershell
flutter pub get
dart run build_runner build --delete-conflicting-outputs
flutter build apk --release
```

The APK output is `build\app\outputs\flutter-apk\app-release.apk`. Install over the existing app with the same signing key; do not clear app data. Ensure both clients use the same Supabase project URL and publishable key.

Match participant, match team, and tournament team uploads now merge existing relationship rows instead of deleting the entire remote set on every periodic sync. This prevents a stale client from erasing a late-added participant, but authoritative propagation of physical roster/team-membership removals still needs a dedicated deletion/tombstone contract. Concurrent independent scoring of the same match is not a supported conflict-free multi-writer workflow; use one active scorer per match and treat the other client as a synchronized view or hand off scoring deliberately. Canonical global player references protect delivery recovery from device-local player ID collisions; they do not merge two different deliveries independently scored at the same sequence number.

Do not change the automated verification count unless a newer run is actually performed.

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
- A player can be added later during the match from Live Scoring. Select an existing global player or create a new one; they are attached to the relevant match team and marked available.
- Late-added batters are available for replacement after a wicket; they do not retroactively enter an innings already in progress.
- The configured player count applies to total players attached to a match team, including late additions.

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
- A non-final innings moves to Opening Innings Setup.
- The final innings completion panel includes a match-wide Man of the Match suggestion.
- Live target/need and 4-innings lead/deficit are recalculated from persisted events.
- The Manage Batters dialog can correct the opening pair before the first delivery; the changed opening IDs are saved to the innings record.
- Once deliveries exist, Manage Batters only allows participating, not-dismissed batters.
- Add Player / Add Bowler actions let the scorer attach an existing player or create a new player for the batting or bowling team within the configured roster maximum. The new bowling player becomes selectable as a bowler. A new batting player is available for wicket-replacement selection.

### Final-innings Man of the Match suggestion

At completion of the match's final innings, Live Scoring shows a suggested candidate aggregated across all innings. The current transparent heuristic is:

```text
impact score = batting runs + (20 × bowler-credited wickets)
                           + (10 × recorded fielder dismissals)
```

Ties in impact score are broken by wickets, then batting runs, then player ID for deterministic output. The UI shows the candidate's batting runs/balls, wickets/runs conceded, and recorded fielding dismissals where applicable. The scorer makes the final award decision; this heuristic is a suggestion, not a claim of an official cricket standard.

Only contributions available in persisted ball-event history are considered. The service does not yet store a formally awarded Man of the Match result.

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

The latest migration files are:

```text
0016_ball_event_player_global_ids.sql
0017_match_innings_player_global_ids.sql
```

**Both migrations are required before deploying this revision.** Migration 0016 adds canonical player references to ball events; migration 0017 adds canonical toss-winner and innings setup references. Apply them to the same Supabase project used by Docker and Android after verifying that their prerequisites through `0015_global_identity_relationships.sql` already exist.

The file naming currently has duplicate numeric versions (`0012_catalog_delete_tombstones.sql` and `0012_three_id_identity.sql`; several files start with `0013_`). Treat the migration directory as requiring a migration-history audit before using automated `supabase db push`; confirm which SQL has already been applied and normalize migration ordering in a controlled deployment plan rather than replaying migrations blindly. The live server's applied migration state has not been inspected from this session.

`0011` adds an administrator-only restriction to permanent catalog deletion, but it has **not been applied to the current self-hosted Supabase instance** because the application currently uses automatic anonymous authentication and does not yet expose a user-facing administrator/login mechanism. Do not apply `0011` until the administrator model is designed and implemented.

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

### Global catalog pull

Global catalog synchronization is bidirectional.

The SyncWorker now performs:

```text
1. Authenticate
2. Upload local catalog changes
3. Pull the shared global catalog from Supabase
4. Continue with match/scoring synchronization
```

The catalog pull imports:

- Teams
- Players
- Team-player memberships
- Tournaments
- Tournament-team memberships
- Tournament points rules

Remote rows are matched using stable `sync_id` identities and imported into the local Drift database without being re-added to the upload queue. Repeated pulls update existing synchronized rows rather than creating duplicate global entities.

The remote catalog transport is paginated so the implementation is not limited to the first 1,000 rows returned by a Supabase/PostgREST request.

### Cross-device verification

The bidirectional catalog workflow has been manually tested:

```text
PC → device → verified
Device → PC → verified
```

A fresh Docker web client also successfully imported the existing shared catalog and reported:

```text
Catalog sync: 33
```

This confirms that a fresh local web database can populate its global catalog from Supabase rather than depending on recovery of a particular match.

### Sync Worker ordering

The SyncWorker:

1. Resets interrupted in-progress queue entries.
2. Ensures the installation identity exists.
3. Seeds missing catalog queue entries.
4. Processes catalog entries in dependency order.
5. Waits for required catalog dependencies before uploading dependent match data.
6. Pulls the shared global catalog after local catalog uploads.
7. Uploads match metadata, participants, innings, and ball events.
8. Applies retry metadata for retryable failures.

Catalog dependency order is:

```text
team
player
team_player
 tournament
```

with dependent match data gated until required catalog entities are synchronized.

New matches are inserted with `is_published = false` and become visible to other installations only after the source client has uploaded the two team slots, at least one player assignment, and all currently stored innings. This avoids another client recovering the match between separate REST writes and seeing a temporarily incomplete snapshot. Existing published matches remain published during normal updates. Automatic five-second sync and manual **Sync Now** share one in-flight `SyncWorker.runOnce()` operation, so they cannot concurrently reset/process the same durable queues.

Inactive team-player memberships remain available locally and are uploaded with `is_active = false` so a removal can propagate to the server.

### Settings / manual sync

Management → Settings provides:

- Supabase configuration fields
- Actual connection status check
- Connection/sync log
- **Sync Now** action
- Automatic sync status with counts and surfaced errors

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

Downloaded catalog rows are deliberately not re-enqueued for upload. The local import path preserves the stable remote identity and updates the local authoritative catalog without creating an upload loop.

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

# 24. Docker / Flutter Web Deployment

Flutter Web is built in a reproducible Docker builder using Flutter **3.47.4**.

The Docker image bundles the Drift WebAssembly runtime assets:

```text
sqlite3.wasm
drift_worker.js
```

nginx serves the application on port:

```text
3112
```

The nginx configuration explicitly serves `sqlite3.wasm` with the correct WebAssembly MIME type and disables caching for `index.html` and the Flutter service worker where required.

The deployment is currently verified directly before Traefik:

```text
http://SERVER-IP:3112
```

Direct access has been manually tested successfully, including a fresh catalog pull from Supabase. Traefik/HTTPS remains the external reverse-proxy layer and is not required for the Docker application's internal operation.

### Current web UI sync behavior

The synchronization layer correctly imports new catalog records into local Drift. If a management screen is already open when the records arrive, that screen may continue displaying its previous Riverpod state until the app/screen is refreshed.

This is a UI refresh/state-notification issue, not a Docker, nginx, or Traefik synchronization failure. Automatic management-screen refresh can be implemented later as a separate improvement without changing the catalog data model.

---

# 25. Match Player Management

### Implemented in Live Scoring

- Add an existing global player to either match team.
- Create a new global player and add them to the current match team.
- Make the added player available immediately without resetting the innings or changing historical ball events.
- Enforce the configured maximum number of players for the team and prevent adding the same player to the match twice.
- Correct the opening striker/non-striker before the first ball and persist the correction.
- Use a late-added batting player as an explicit wicket replacement; a player cannot be selected as an in-progress batter simply because they were added to the roster.

### Still planned

Future Match Controls → Players functionality may support moving an unused player between teams and managing batting order.

A player may move teams only when there is no ball/event participation that would make the change historically invalid.

Do not modify historical ball events to make a late roster change appear to have existed earlier.

---

# 26. Locked Rules / Do Not Regress

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
- Global Teams and Players remain reusable entities; synchronization must not create duplicate global entities for the same stable identity.

---

# 27. Development Workflow

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

# 28. Current Next Step

The global catalog synchronization and Docker Web deployment were manually verified in an earlier revision. The latest sync-hardening changes have not yet been validated end-to-end. The next development phase should be a **sync/recovery audit and integration hardening pass**, not a redesign.

Recommended audit order:

1. Run `flutter analyze` and `flutter test` against the latest feature branch; fix any regressions before deployment.
2. Manually test late-player addition, opening-batter correction before the first delivery, and the final-innings Man of the Match suggestion on Web and Android.
3. Verify catalog retry behavior and dependency ordering under failures/restarts.
4. Verify local tournament membership changes do not overwrite unrelated local/server state.
5. Verify match participant removal/re-addition behavior across sync.
6. Exercise recovery against a populated tournament with additional unrelated teams and confirm only match dependencies are imported.
7. Exercise divergent tournament points recovery and confirm the entire import rolls back.
8. Verify the self-hosted Supabase deployment against the current migrations and RLS policies.
9. Resolve/verify the current permanent catalog deletion RPC deployment/schema-cache issue before treating permanent deletion as production-ready.
10. Add/expand integration-style transport tests where practical.
11. Verify Docker and Android use the same Supabase URL/project/key and check both clients' Settings sync diagnostics.
12. Audit the live Supabase migration history, confirm prerequisites through `0015`, apply `0016_ball_event_player_global_ids.sql` and `0017_match_innings_player_global_ids.sql`, and reconcile duplicate `0012`/`0013` filename prefixes before future automated migration deployment.
13. Run cross-device tests for catalog edits, live player additions, match/innings status, canonical ball player references, scored balls, and app restart recovery.
14. Add proper removal tombstones for match participants and tournament/match team relationships.
15. Add automatic management-screen refresh after catalog import as a separate UI improvement if desired.
16. Continue feature work only after the synchronization invariants remain intact.

The implementation must remain offline-first throughout this work.

---

# 29. Two-Bowler Mode Simulation Findings — 2026-09-24

A focused simulation was run using the exact ported scoring algorithms to reproduce the 2-Bowler Mode boundary/recovery behavior.

## Simulation scope

The simulation used:

\`\`\`text
lib/domain/scoring/** copied verbatim from cricket_scorer (pure Dart).

lib/sim/scoring_simulator.dart mirrors:
- LiveScoringNotifier (_apply / selectTwoBowlerPair / selectFinalOverBowler /
  _restoreTwoBowlerPair / undo / build-restore)
- ApplyScoringActionService (_effectiveBowlerId / _validateBowlerSelection /
  _bowlersInOver)
\`\`\`

Documented approximation:

\`\`\`text
InningsState.bowlerId = bowler of the last ball
\`\`\`

Only the \`== 0\` / \`!= 0\` behavior is used by the restore and undo paths.

The behavior was validated against an independent line-by-line port of the algorithms.

## Verified scenarios

| Scenario | Result |
|---|---|
| **A — clean 15-over 2-bowler match** | ✅ Completes: 15 overs, 90 legal balls. The pair prompt after over 6 is correct by design because a new pair is selected every 2 overs. |
| **B — after over 6, scorer selects the same pair that just bowled over 6** | 🔴 Reproduced: every scoring press throws \`An active two-bowler pair cannot include a bowler from the previous over\`. The dialog does not filter or explain the invalid choice, so the invalid pair remains selected and the scoring pad appears stuck. |
| **C — provider/app rebuild after the first ball of over 7** | 🔴 Reproduced: \`_restoreTwoBowlerPair\` cannot reconstruct the new block's pair from ball history because only one bowler has bowled in the block. The pair is silently dropped, leaving the scoring pad disabled with \`Two-Bowler Mode requires exactly two active bowlers\` until the pair is re-selected. |
| **D — undo across the over-6 boundary** | 🔴 Reproduced: undo keeps the new pair but restores \`selectedBowlerId\` from the pre-undo ball, which can be a bowler from the previous pair. Scoring then throws \`Selected bowler must be in the active pair\` until the pair is re-selected. |

### Important simulation result

The simulation disproved the hypothesis that the tap order in the pair dialog is itself the problem. \`_effectiveBowlerId\` auto-corrects the selected bowler during an over, so pair selection order is not the root cause.

The observed "sometimes stuck" behavior is explained by three separate boundary conditions:

1. Selecting a pair that overlaps the previous over.
2. Provider/app rebuild or restart during a new two-over block.
3. Undo crossing a two-over-block boundary.

In all three cases, manually reopening the pair dialog and selecting a valid pair is currently an escape path, but the UI does not adequately explain the required action.

## Findings and proposed fixes

These are **findings/proposals only**. No scoring fix is claimed as applied by this section.

1. **Persist the active two-bowler pair durably.** Store \`activeTwoBowlerIds\` in an appropriate innings column or dedicated key/value structure so provider rebuilds can restore the pair. Ball history remains a fallback.
2. **Improve pair selection UI.** Disable bowlers from the previous over in the pair dialog and explain the consecutive-over restriction inline.
3. **Harden undo restoration.** If the restored \`selectedBowlerId\` is not part of the active pair, clear it rather than restoring a stale bowler.
4. **Surface validation failures persistently.** Show the active pair/selection problem in the pair-selector area rather than relying only on a transient snackbar.

The simulation and these findings should be used as the regression baseline before changing the 2-Bowler Mode implementation.

## Simulation artifacts

The simulation work is associated with:

\`\`\`text
two_bowler_pair_repro
bin/simulate.dart
lib/sim/scoring_simulator.dart
\`\`\`

The simulator is intended to remain zero-dependency at the Dart level where practical; the package test suite uses the project's existing \`package:test\` setup.

