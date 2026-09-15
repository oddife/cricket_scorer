# Cricket Scorer

A serious Flutter cricket scoring application built from the ground up. This README is the **project handover / continuity document** for the application. It records the decisions, rules, architecture, workflows, implementation status, and known limitations agreed during development so a future development session can continue without reconstructing the previous discussion.

> **Important:** Update this README whenever a major product, rules, architecture, workflow, database, sync, backend, or implementation decision changes. Do not silently change a locked cricket rule or product requirement.

---

## Current Development Status

The core offline-first live scoring workflow is now functional. The user has completed a real 4-innings match workflow and reported **69/69 tests passing** with `flutter analyze` reporting no issues.

Recently implemented/updated:

- Ball-by-ball UI derived directly from persisted `BallEvent` history.
- Optional wicket workflow for Normal, Wide, No-ball, Bye, and Leg-bye deliveries.
- Delivery-only confirmation when no wicket is selected.
- Explicit **End Innings** workflow.
- Non-final innings transitions to Opening Innings Setup.
- Final innings can transition into the Match Completed view.
- Match result logic can recognize a chase reaching the target before the scheduled innings limit.
- Manually ended final innings is treated as final for result evaluation.
- Ball-event provider refreshes after scoring and undo so ball-by-ball UI stays current.
- Tournament/team persistence is implemented.
- Match completion persistence is implemented.
- Compact Short Match PDF and detailed Full Match PDF export are implemented.
- The PDF export UI uses one **Export Match PDF** action and then lets the scorer choose Short or Full.
- Full PDF ball-by-ball is grouped by over.
- Approved backend direction: self-hosted Supabase/PostgreSQL/Realtime in Docker, while keeping local Drift/SQLite authoritative during offline scoring.
- Local sync foundation is now implemented: persistent installation identity, durable sync queue, idempotent queue insertion, upload status/retry metadata, ordering fields, and recovery of interrupted in-progress work.
- Planned live public scorecard and Windows broadcast/ticker clients consume the same synchronized match history.

The next development work should build on this state rather than replacing the existing scoring architecture.

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
10. **Live/cloud sync is planned and approved, but scoring must never require cloud connectivity.** Local Drift/SQLite remains the offline source of persisted match facts; synchronized backend data is a shared live distribution layer.
11. Global Teams and Players are reusable entities. A match does not create duplicate copies of them.
12. Do not invent cricket rules. Use normal cricket Laws except for the explicitly agreed custom features:
   - **2-Bowler Mode**
   - **Over Fence** wicket
13. The scorer should make as few taps as practical during live scoring.
14. **One match → one source of truth → multiple live clients.** Scorer, public scorecard, broadcast graphics, and future displays must derive from the same ball-by-ball history rather than creating separate scoring models.

---

## 3. Architecture

Current intended architecture:

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

Current application technology:

- Flutter / Dart
- Riverpod
- Drift
- SQLite
- go_router
- Shared Preferences where appropriate for app preferences

Approved backend direction:

- Self-hosted Supabase
- PostgreSQL
- Supabase Auth
- Supabase Realtime
- Supabase API
- Supabase Studio
- Docker deployment
- Traefik/HTTPS for external access where appropriate

The backend is a **live synchronization/distribution layer**, not a replacement for offline local scoring.

### Data philosophy

Persist facts and events. Derive mutable scoring state.

Do **not** make current striker, current score, current bowler, or current over permanent authoritative fields when they can be reconstructed from ball history.

Opening innings metadata is persisted because it defines the starting state:

- opening striker
- opening non-striker
- opening bowler
- innings configuration

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

Home order is intentionally:

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

Tournament setup happens before match setup.

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

Tournament contains/creates its matches.

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

Tournament persistence/repository is implemented. Current tournament provider still has some in-memory state that should eventually be moved fully to the repository-backed model.

Tournament type DB mapping is stable:

```text
league = 0
knockout = 1
leagueAndKnockout = 2
```

---

# 6. Normal Match

A standalone match can use global Teams/Players or create new ones during setup. A newly created Team/Player is persisted globally and then used by the match.

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

### Balls per over

**NOT a user setting.**

Standard cricket uses 6 legal balls per over. The app must not expose a configurable balls-per-over option.

Internal models may retain `ballsPerOver` where required by the scoring engine, but the normal value is fixed to **6**.

---

# 7. Player Selection Before Match

`playersPerTeam` is the configured/normal maximum team size. It is **not a requirement that the scorer must have all players available before starting**.

Example:

```text
Players per Team = 9

Available now = 5
```

The scorer must be allowed to continue with 5 available players. The remaining players can be added after the match starts.

Rules:

- Initial selection may contain fewer players than `playersPerTeam`.
- It may not exceed `playersPerTeam`.
- At least 2 available players per team are required so an opening batting pair can be selected.
- Player selection does **not** determine batting order.
- Batting order is handled separately after player selection.
- A player can be added later during the match.

Current setup UI explicitly explains that missing players can be added after the match starts.

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

UI explanation:

> The two opening bowlers alternate on every legal delivery.

The setup creates the innings and persists the opening striker/non-striker/bowler metadata.

The second opening bowler in 2-Bowler Mode is currently held in live Riverpod scoring state rather than persisted as innings DB metadata. If persistence across app restart becomes necessary, implement it properly with a schema migration or dedicated persisted structure; do not encode IDs into unrelated fields.

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

Opening setup calculates the next innings number and the correct batting/bowling teams from toss + innings parity.

Current opening setup behavior:

- no previous innings → innings 1
- otherwise → highest existing innings number + 1
- reject setup if that would exceed the configured innings count

---

# 10. Match Formats and Results

## Two innings

```text
A → B
```

Result logic:

- B reaches A's target → B wins by wickets immediately; the chase does not need to consume the remaining scheduled overs.
- B remains below target → A wins by runs when the final innings is complete or manually ended.
- Equal score → tie when the final innings is complete.

## Four innings

Locked format:

```text
A → B → A → B
```

This is aggregate / Test-style scoring with custom innings limits.

Rules:

- Each innings has its configured overs/custom limit.
- No follow-on.
- No declarations.
- No draw logic.
- No unlimited innings.
- Result is based on aggregate scores and the final target/lead.

Example:

```text
A = 150
B = 120
A = 100

A aggregate = 250
B needs 131 in innings 4
```

Final B target = A aggregate + 1.

- B reaches target → B wins by wickets immediately.
- B finishes below target → A wins by runs when the final innings is complete or manually ended.
- Equal aggregate → tie when the final innings is complete.

The dedicated `MatchResultService` now evaluates the result using aggregate/current innings state and recognizes target completion before the scheduled innings limit.

---

# 11. Two-Bowler Mode — LOCKED RULE

This is the main custom bowling rule.

Two selected bowlers alternate on **every legal delivery**.

Example for 6 legal balls:

```text
1 → Bowler A
2 → Bowler B
3 → Bowler A
4 → Bowler B
5 → Bowler A
6 → Bowler B
```

Next over:

```text
7  → A
8  → B
9  → A
10 → B
11 → A
12 → B
```

After 12 legal balls, each has delivered 6 legal balls and therefore completed one normal legal over.

Then a new pair is selected.

### Important

- Pairs are not permanent.
- A pair is selected for a two-over block.
- A bowler cannot bowl consecutive overs.
- Eligible bowlers are determined by bowling eligibility and the normal consecutive-over restriction.
- Rotation is based on **legal balls**, not scoring button presses.
- Wides and no-balls do not advance the legal-ball count.
- No-ball/wide therefore does not switch the active bowler.
- The Bowler Rotation Engine owns this behavior.

### Odd number of overs

The final odd over is bowled by one selected bowler.

Examples:

```text
3 overs → first 2 overs are a two-bowler block; final 3rd over is single bowler.
5 overs → first 4 overs are blocks; final 5th is single bowler.
7 overs → first 6 overs are blocks; final 7th is single bowler.
```

The app auto-detects this from the configured overs.

### Normal cricket restriction

A bowler cannot bowl two overs consecutively, including parts of consecutive overs.

This restriction must remain enforced even if a scorer attempts to select the same bowler again.

The correct UI behavior for an invalid selection is to show the validation error while keeping the live scoring screen usable.

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

Current Drift `BallEvents` fields also include:

- `creditedToBowler`
- nullable wicket fields

Unique key:

```text
(inningsId, sequenceNumber)
```

No separate over table is currently required. Overs are derived from ball events.

Permanent batter/bowler stats are not the initial source of truth. They are derived from the events.

The live ball-by-ball UI also derives its display from `BallEvent` history rather than maintaining a second list of scoring results.

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

Current scoring engine:

`lib/domain/scoring/services/scoring_engine.dart`

It accepts scoring context/input and creates a `BallEvent`.

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

The delivery-aware wicket workflow supports Normal, Wide, No-ball, Bye, and Leg-bye delivery types. **Wicket selection is optional** for these delivery actions: the scorer can select `No wicket` and confirm the delivery alone.

### Caught

Requires an eligible fielder.

### Run Out

Requires:

- Fielder
- Run Out End: striker's end or non-striker's end
- Relevant completed/total runs where applicable

Run Out is an atomic delivery + wicket event.

The scorer must not manually calculate the resulting striker/non-striker positions. The Run Out Resolver does that using:

- run-out end
- completed runs parity
- crossing before wicket

Run Out does not credit the bowler.

### Stumped

Requires the appropriate fielder/keeper selection.

### Over Fence

Custom wicket. Bowler is credited.

### Retirement

Retirement is not treated as a normal dismissal.

---

# 16. Run Out Resolution

Current `RunOutResolver` returns:

```text
RunOutResolution
├── strikerId
├── nonStrikerId
├── dismissedPlayerId
└── remainingBatterId
```

It uses:

- `RunOutEnd.striker`
- `RunOutEnd.nonStriker`
- completed runs
- crossing before wicket

A side context table stores information that cannot be reconstructed solely from the basic BallEvent fields:

```text
wicket_event_contexts
├── ball_event_id
├── completed_runs
├── crossed_before_wicket
└── replacement_batter_id
```

This preserves the information needed for exact wicket/replacement workflows without polluting the main BallEvent with UI-only data.

---

# 17. Batter Replacement

Current `BatterReplacementService` handles:

- eligible replacement batters
- already-batted players
- current striker/non-striker exclusion
- replacement validation

A wicket that requires a replacement must not simply invent a new batter. The replacement must be explicitly selected from eligible players.

The live wicket workflow records the replacement explicitly where required.

---

# 18. Wide

Wide is an illegal delivery.

Rules:

- One-run minimum wide penalty.
- Additional wide runs may be recorded.
- No legal-ball advancement.
- Bowler is charged with wide runs.
- Batter runs are zero.
- Strike/end movement follows normal Laws.

UI workflow:

- WD quick action
- Quick values / Custom
- Optional wicket through the delivery-aware wicket workflow

The UI creates the event; it does not directly mutate the score.

---

# 19. Bye / Leg Bye

Bye and leg-bye are legal deliveries unless combined with an otherwise illegal delivery such as a no-ball.

UI provides quick values and Custom.

Custom total can represent the actual total runs credited to the extras category, including running/overthrow/boundary situations as appropriate.

For these deliveries:

- Batter runs = 0
- Runs go to bye or leg-bye extras
- Strike/end movement follows normal Laws
- No invented separate overthrow workflow
- Optional wicket can be selected through the delivery-aware wicket workflow

---

# 20. No-Ball

No-ball is an illegal delivery.

Popup workflow:

- NB only
- NB + BAT
- NB + BYE
- NB + LEG BYE
- Custom
- Optional wicket through the delivery-aware wicket workflow

Examples:

```text
NB only
Team +1
Bowler +1

NB + 4 bat
Team +5
Batter +4
No-ball extra +1
Bowler +5

NB + 2 bye
Team +3
Batter +0
Bye +2
No-ball extra +1
Bowler +1

NB + 3 leg bye
Team +4
Batter +0
Leg bye +3
No-ball extra +1
Bowler +1
```

No-ball does not consume a legal ball and therefore does not advance 2-Bowler Mode rotation.

Normal no-ball wicket restrictions must be enforced by the Rules Engine.

---

# 21. Cricket Rules Principle

The app uses normal cricket Laws, with only these explicit custom additions:

1. 2-Bowler Mode
2. Over Fence wicket

Do not invent additional scoring rules.

Rules already considered include:

- Run Out
- Wide Ball
- No Ball
- Scoring Runs
- Stumped
- Hit Wicket
- The Over

The MCC Laws are the authoritative source for normal cricket rule interpretation when a question arises.

Known principles include:

- Run Out: completed runs may stand depending on the situation; the run in progress when the wicket is broken is not scored; bowler receives no wicket credit.
- No-ball: no legal ball; one-run penalty; only permitted wicket types can apply.
- Wide: one-run penalty minimum; no legal ball; bowler is charged with resulting wide runs; only permitted wicket types can apply.
- A bowler cannot bowl two overs consecutively.

When an edge case is uncertain, do not guess. Isolate it in the Rules Engine and verify the relevant Law before implementing it.

---

# 22. Strike Engine

Strike changes must be derived from the delivery outcome and normal Laws.

The Strike Engine is responsible for:

- batter-run parity
- completed runs
- extras/run movement
- end-of-over change
- delivery-to-delivery striker/non-striker state

Do not implement ad-hoc strike swaps inside UI buttons.

---

# 23. Innings Recalculation Engine

Current files:

```text
lib/domain/innings/models/innings_recalculation_context.dart
lib/domain/innings/models/innings_state.dart
lib/domain/innings/services/innings_recalculation_engine.dart
```

It processes BallEvents in sequence and derives:

- score
- wickets
- legal balls
- overs
- striker
- non-striker
- bowler
- wides
- no-balls
- byes
- leg-byes
- batter statistics
- bowler statistics
- ball count
- completion state

`InningsState` also contains:

- `requiresBatterReplacement`
- `targetReached`
- `oversComplete`
- `wicketsComplete`
- `inningsComplete`

The recalculation engine is pure and should remain free of UI/database mutation.

Target completion is now used by the match-result layer to recognize a successful chase before the scheduled innings limit.

---

# 24. Live Scoring Provider

Current provider:

`lib/features/matches/providers/live_scoring_provider.dart`

Uses a Riverpod family `AsyncNotifier` keyed by innings ID.

It supports:

- select bowler
- select 2-bowler pair
- select final odd-over bowler
- score runs
- wide
- no-ball
- bye
- leg-bye
- wicket
- combined wicket delivery
- undo
- end innings

The provider loads innings + ball events, recalculates current state, and applies new events through application services.

After scoring or undo, the ball-event provider is invalidated so dependent ball-by-ball UI refreshes from persisted event history.

`endInnings()` explicitly updates the current innings to `InningsStatus.ended` and records `completedAt`.

### Important error-handling rule

A validation error during a scoring action must **not** replace the live provider with `AsyncError` and trap the scorer on an error screen.

The correct behavior is:

```text
Keep live scoring state
        ↓
Show validation error / SnackBar
        ↓
Allow scorer to correct the selection
```

This was fixed after the UI showed:

```text
Unable to load scoring state:
Bad state: A bowler cannot bowl consecutive overs.
```

The bowler rule itself remains enforced.

---

# 25. Live Scoring Screen

Current file:

`lib/features/matches/screens/match_live_screen.dart`

Displays:

- Match name
- innings number
- score/wickets
- overs
- CRR
- striker
- non-striker
- batter runs/balls
- current bowler
- bowler overs/runs/wickets
- current over / ball-by-ball history
- extras
- scoring pad
- wicket action
- undo
- bowler/pair selection
- End Innings

Scoring pad currently includes:

```text
0  1  2
3  4  6
WD NB B LB
```

Wicket is a dedicated action, while delivery-aware wicket selection is also available from the delivery workflow.

### Ball-by-ball card

The live screen includes a compact ball-by-ball card below the batter/bowler area. It reads the current innings' `BallEvent` history and presents delivery outcomes such as:

```text
1  0  1  4  WD  NB  W  2+W
```

The exact display is derived from event type, runs/extras, and wicket data; it is not a second scoring source of truth.

### End Innings

The live controls include an explicit **End Innings** action with confirmation.

When the scorer ends an innings manually:

- current innings status becomes `ended`
- scoring controls are disabled/removed
- non-final innings routes to Opening Innings Setup
- final innings returns to the live shell so the Match Completed view can render

When an innings completes naturally, the same control-hiding/transition behavior applies.

---

# 26. End of Innings Flow

Expected flow:

```text
Live Scoring
    ↓
Innings reaches completion OR scorer selects End Innings
    ↓
Disable scoring / bowler controls
    ↓
If another innings remains
    ↓
Opening Innings Setup
    ↓
Select opening striker
Select opening non-striker
Select opening bowler(s)
    ↓
Live Scoring for next innings
```

The scorer must never be asked to select another 2-bowler pair after the innings is already complete.

Previously this caused a confusing state where selecting a new pair succeeded visually but the next scoring action reported `innings complete`. The live UI now hides those controls on completion and moves to the next innings setup.

---

# 27. Match Completion / Result UI

The live match shell recalculates the current match state from innings ball events and passes it through `MatchResultService`.

When the match is complete, the shell presents a dedicated **Match Completed** view rather than leaving the scorer on a normal scoring screen.

The result view is intended to show:

- Match Completed heading
- Match name
- Winner / Tie
- Margin, such as wickets or runs
- View Scorecard
- Back to Match

A successful chase can complete the match immediately when the target is reached; the remaining scheduled balls do not need to be scored.

---

# 28. Match Player Management During Match

This is required and must not introduce a separate squad concept.

Required functionality:

```text
Match Controls
└── Players
    ├── Add Player
    ├── Move unused player to Team A
    ├── Move unused player to Team B
    └── Batting Order
```

Rules:

1. Add a global player to an existing match.
2. Newly added player can be assigned to Team A or Team B.
3. A player who has not participated in any ball/event can be moved between teams.
4. Once a player has actually participated, they cannot be moved to another team.
5. A player cannot be removed/moved in a way that corrupts historical ball-by-ball data.
6. Participation is determined from ball events/match history, not merely `isPlaying`.
7. A player unavailable during setup can be added after match start.
8. A player originally associated with the other match team can be moved if they have not participated.
9. `match.playersPerTeam` remains the configured/initial team-size limit; it is not a reason to invent a separate squad entity.
10. Existing `MatchPlayers` uses unique `(matchId, playerId)`, so an unused player's `teamId` can be updated when moving them rather than creating duplicates.

This functionality is still planned for implementation.

---

# 29. MatchPlayers

Current conceptual table:

```text
MatchPlayers
├── id
├── matchId
├── teamId
├── playerId
├── isPlaying
└── battingOrder
```

Unique key:

```text
(matchId, playerId)
```

`isPlaying` means the player is currently available/selected for match use. It must not be interpreted as proof that the player has participated in a delivery.

`battingOrder` is not assigned merely because a player was selected during setup.

---

# 30. Batting Order

Player selection and batting order are separate concepts.

Initial player selection only establishes who is available.

Opening setup explicitly selects the first two batters.

Later batting order management must be available for eligible/current players where appropriate, while preserving historical ball-by-ball data.

Do not silently assign batting order from the order in which the scorer checked player-selection boxes.

---

# 31. Current Repository / Domain Components

Important implemented components include:

```text
Scoring Engine
Strike Engine
Bowler Rotation Engine
Innings Recalculation Engine
BallEvent persistence
BallEvent innings provider
ApplyScoringActionService
UndoScoringActionService
WicketWorkflowService
RunOutResolver
BatterReplacementService
InitializeInningsService
MatchResultService
SyncQueueRepository
DriftSyncQueueRepository
```

Important files include:

```text
lib/domain/scoring/services/scoring_engine.dart
lib/domain/scoring/services/bowler_rotation_engine.dart
lib/domain/scoring/services/wicket_workflow_service.dart
lib/domain/scoring/services/run_out_resolver.dart
lib/domain/scoring/services/batter_replacement_service.dart
lib/domain/innings/services/innings_recalculation_engine.dart
lib/domain/matches/services/match_result_service.dart
lib/features/matches/providers/innings_provider.dart
lib/features/matches/providers/live_scoring_provider.dart
lib/features/matches/screens/match_live_screen.dart
lib/features/matches/screens/match_live_shell_screen.dart
lib/features/matches/screens/opening_innings_setup_screen.dart
lib/features/matches/widgets/ball_by_ball_card.dart
lib/features/matches/widgets/delivery_aware_wicket_dialog.dart
lib/data/repositories/sync_queue_repository.dart
lib/data/repositories/drift_sync_queue_repository.dart
```

---

# 32. Testing

The current local automated test result reported by the user is:

```text
flutter analyze
No issues found!

flutter test
00:04 +69: All tests passed!
```

Domain/application coverage includes tests for:

- Bowler Rotation Engine
- Innings Recalculation Engine
- Run Out Resolver
- Batter Replacement Service
- scoring/wicket validation behavior
- combined wicket + delivery workflows
- application scoring actions
- undo scoring actions
- four-innings MatchResultService target/result behavior

Tests should be expanded whenever a rule or state transition is changed.

Always run:

```powershell
flutter analyze
flutter test
```

Do not claim either passes unless the actual command output has been checked.

The 69/69 result is recorded from the user's reported local test run; it is not an assertion that the assistant independently executed Flutter in this environment.

---

# 33. Backend / Live Sync Architecture

Approved direction: **self-hosted Supabase in Docker**.

The backend will provide:

- PostgreSQL persistent shared match data
- Supabase Auth for authenticated scorer/admin access
- Supabase Realtime for live score distribution
- Supabase API for application access
- Supabase Studio for administration/development

### Offline-first synchronization

The scorer remains usable without internet:

```text
Flutter Scorer
     ↓
Drift / SQLite
     ↓
BallEvent saved immediately
     ↓
Sync Queue
     ↓ internet available
Supabase / PostgreSQL
     ↓
Realtime
     ├── Public Live Scorecard
     ├── Windows Broadcast Client
     ├── vMix / OBS overlays
     └── Future displays
```

### Implemented local sync foundation

Database schema version 9 now creates:

```text
sync_metadata
├── id (singleton)
└── installation_id (stable per local database)

sync_queue
├── id
├── sync_id
├── entity_type
├── entity_id
├── innings_id
├── sequence_number
├── status
├── attempts
├── created_at
├── next_attempt_at
├── last_error
└── synced_at
```

BallEvent persistence now writes the BallEvent and its sync queue entry inside the same Drift transaction. Queue insertion is idempotent using a stable `sync_id` scoped by the persistent installation identifier and local BallEvent ID.

The queue supports:

```text
pending → in_progress → synced
                 ↘ failed → pending
```

Pending work is ordered by innings/sequence. `resetInProgress()` supports recovery after an interrupted worker/app shutdown. Retry timestamps and error information are persisted locally so a future sync worker does not need to reconstruct failed work.

The local queue is intentionally transport-neutral. Supabase network upload, authentication, server schema, download/reconciliation, retry backoff policy, and Realtime subscriptions are the next layers.

Required synchronization properties remain:

- stable event IDs
- idempotent uploads
- duplicate-event protection
- sync status per local event
- retry after failures
- ordering protection using match/innings sequence numbers
- authentication
- authorization
- safe reconnect/recovery
- ability to detect server/client divergence

Conflict handling must be designed around immutable ball events rather than silently overwriting scoring history.

See also:

`docs/BACKEND_LIVE_BROADCAST_ARCHITECTURE.md`

---

# 34. Planned Live / Broadcast Features

Windows is intended to provide additional management/scoring functionality including:

- Live Ticker
- Broadcast Mode
- External Display
- Live scorebug
- Bottom ticker
- Lower thirds
- Wicket graphic
- Boundary graphic
- Partnership graphic
- Match result graphic
- Manual ticker messages
- Future vMix / OBS integration

The preferred broadcast integration is a transparent browser-based overlay that consumes the live synchronized match state and can be loaded by vMix/OBS.

The web version is intended to provide:

- public live scorecard
- shared match links
- tournament standings
- tournament results

These clients must consume the same ball-by-ball source of truth rather than creating a second scoring model.

A future LAN/local-network fallback is planned so broadcast/display clients can continue to receive live match data when internet access is unavailable but the scorer and clients share a local network.

---

# 35. PDF Export

Completed matches provide one **Export Match PDF** action. The scorer then chooses:

- **Short** — compact traditional scorecard, intended for approximately 1–2 pages, with match/date/result, toss, teams and players, innings totals/overs, batting, extras, and bowling. No ball-by-ball section.
- **Full** — complete match scorecard including the same scorecard data plus detailed ball-by-ball delivery history grouped by over.

PDF scorecards are reconstructed from persisted BallEvent history through the same innings recalculation and match-result services used by the live application. This prevents the exporter from becoming a second scoring source of truth.

The current PDF implementation keeps standard-font output ASCII-safe for delivery labels. Future Unicode branding/name requirements may require embedding a TrueType font.

---

# 36. Database Rules

Use Drift/SQLite as the local source of persisted match data.

Important rules:

- Save each delivery.
- Preserve sequence order.
- Do not overwrite historical events to fake current state.
- Do not delete historical players after they have participated.
- Do not move a participating player between teams.
- Keep schema migrations explicit.
- Do not modify generated Drift files manually as a shortcut when a schema change is required.
- If a new persisted field is required, update the Drift schema and migration properly.
- Backend synchronization must preserve stable local event identity and sequence ordering.
- Do not make cloud availability a prerequisite for local scoring.
- Local sync queue insertion for a BallEvent must be part of the same transaction as the BallEvent write.

---

# 37. Coding Rules for Future Sessions

When continuing development:

1. Read this README first.
2. Inspect the current repository implementation before modifying code.
3. Treat sections marked **LOCKED** or explicit user constraints as requirements, not suggestions.
4. Do not reintroduce configurable balls-per-over.
5. Do not introduce a separate squad concept.
6. Do not assign batting order automatically from player-selection order.
7. Do not require all configured players to be available before starting a match.
8. Do not change normal cricket rules unless the user explicitly approves a custom rule.
9. Keep cricket rules in domain engines/services, not widgets.
10. Preserve ball-by-ball historical integrity.
11. Make the smallest safe change when fixing a bug.
12. Add/update tests when changing domain logic.
13. Run `flutter analyze` and `flutter test` when possible and report actual results.
14. Never claim tests/analyzer passed without actual output.
15. After a significant implementation decision, update this README in the same development step.
16. When backend/sync/realtime/public-scorecard/broadcast architecture changes, update both this README and `docs/BACKEND_LIVE_BROADCAST_ARCHITECTURE.md`.
17. GitHub is the project source of truth for development continuity; do not assume an uncommitted local change is part of the shared implementation.

---

# 38. Quick Handover Summary

If a new development session starts, the minimum context is:

```text
Project: Flutter Cricket Scorer
Repository: oddife/cricket_scorer
Branch: feature/live-wicket-delivery-dialog-v2

Architecture:
Flutter → Riverpod → Application Services → Domain Engines → Repositories → Drift/SQLite
→ Sync Queue → Supabase/PostgreSQL/Realtime → Public/Broadcast clients

Source of truth:
Ball-by-ball BallEvents

Formats:
2 innings: A → B
4 innings: A → B → A → B

Match type:
Custom

Balls per over:
Always 6; NOT configurable

Player setup:
Can start with fewer available players than configured playersPerTeam.
Missing players can be added during the match.

Opening setup:
Striker + non-striker + opening bowler(s)

Toss:
Determines first innings; later innings alternate automatically.

2-Bowler Mode:
Two bowlers alternate every LEGAL ball.
Each pair covers two normal overs.
No consecutive overs by same bowler.
Odd final over is single bowler.
Wides/no-balls do not advance rotation.

Custom rule:
Over Fence wicket, bowler credited.

Normal cricket:
Use MCC Laws; no invented rules.

Wicket workflow:
Normal/Wide/No-ball/Bye/Leg-bye can use delivery-aware wicket flow.
Wicket is optional; No wicket records delivery only.

Live UI:
Invalid scoring/bowler validation must show an error without replacing live state.
Live screen has a Back button.
Live screen includes ball-by-ball event display.
End Innings is available with confirmation.
Completed innings hides scoring/bowler controls and routes to next Opening Setup.
Final innings can show Match Completed.

PDF export:
One Export Match PDF action, then Short or Full.
Short has no ball-by-ball.
Full includes ball-by-ball grouped by over.

Current tests:
69/69 reported passing; flutter analyze reports no issues.

Backend direction:
Self-hosted Supabase + PostgreSQL + Realtime in Docker.
Local Drift/SQLite remains offline scoring persistence.
BallEvents are queued transactionally in a durable local sync queue.
Public scorecard and Windows broadcast clients consume synchronized match history.

Next major implementation:
Define the PostgreSQL/Supabase schema and synchronization contract, then implement authenticated BallEvent upload/download with idempotency and ordered recovery.
```

---

## README Maintenance

This document is intentionally more detailed than a normal project README. Its purpose is continuity between development sessions.

**When the chat ends, this file should be the first project document read in the next session.**

**Permanent rule:** significant code, product, cricket-rule, database, sync, backend, UI workflow, or architecture changes must update this document as part of the same development step. Never intentionally leave the README behind the implementation.
