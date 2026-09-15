# Cricket Scorer

A new Flutter cricket scoring application being built from the ground up. This README is the **project handover / continuity document** for the application. It records the decisions, rules, architecture, workflows, implementation status, and known limitations agreed during development so a future development session can continue without reconstructing the previous discussion.

> **Important:** Update this README whenever a major product, rules, architecture, workflow, database, or implementation decision changes. Do not silently change a locked cricket rule or product requirement.

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
10. Cloud/live sync can be added later; do not design the local model around a mandatory cloud dependency.
11. Global Teams and Players are reusable entities. A match does not create duplicate copies of them.
12. Do not invent cricket rules. Use normal cricket Laws except for the explicitly agreed custom features:
   - **2-Bowler Mode**
   - **Over Fence** wicket
13. The scorer should make as few taps as practical during live scoring.

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
```

### Technology

- Flutter / Dart
- Riverpod
- Drift
- SQLite
- go_router
- Shared Preferences where appropriate for app preferences

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

- B reaches A's target → B wins by wickets.
- B remains below target → A wins by runs.
- Equal score → tie.

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

- B reaches target → B wins by wickets.
- B finishes below target → A wins by runs.
- Equal aggregate → tie.

A dedicated Match Result Engine is planned/required to centralize this logic.

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
- Obstructing the Field
- Over Fence (custom)

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

---

# 20. No-Ball

No-ball is an illegal delivery.

Popup workflow:

- NB only
- NB + BAT
- NB + BYE
- NB + LEG BYE
- Custom

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

Important current limitation: target-reached completion is not yet fully wired through the live application for all match formats. It must eventually be connected to the correct match/innings target logic.

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

The provider loads innings + ball events, recalculates current state, and applies new events through application services.

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
- current over
- extras
- scoring pad
- wicket action
- undo
- bowler/pair selection

Scoring pad currently includes:

```text
0  1  2
3  4  6
WD NB B LB
```

Wicket is a dedicated action.

The screen has an explicit Back button.

When an innings completes:

- scoring controls disappear
- pair/bowler selection disappears
- undo remains available
- non-final innings provides a route to Opening Innings Setup for the next innings
- final innings reports that match innings are complete

The live screen uses the **latest innings by innings number**, not always innings 1.

---

# 26. End of Innings Flow

Expected flow:

```text
Live Scoring
    ↓
Innings reaches completion
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

# 27. Match Player Management During Match

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

This functionality is planned for the next implementation stage.

---

# 28. MatchPlayers

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

# 29. Batting Order

Player selection and batting order are separate concepts.

Initial player selection only establishes who is available.

Opening setup explicitly selects the first two batters.

Later batting order management must be available for eligible/current players where appropriate, while preserving historical ball-by-ball data.

Do not silently assign batting order from the order in which the scorer checked player-selection boxes.

---

# 30. Current Repository / Domain Components

Important implemented components include:

```text
Scoring Engine
Strike Engine
Bowler Rotation Engine
Innings Recalculation Engine
BallEvent persistence
ApplyScoringActionService
UndoScoringActionService
WicketWorkflowService
RunOutResolver
BatterReplacementService
InitializeInningsService
```

Important files include:

```text
lib/domain/scoring/services/scoring_engine.dart
lib/domain/scoring/services/bowler_rotation_engine.dart
lib/domain/scoring/services/wicket_workflow_service.dart
lib/domain/scoring/services/run_out_resolver.dart
lib/domain/scoring/services/batter_replacement_service.dart
lib/domain/innings/services/innings_recalculation_engine.dart
lib/features/matches/providers/live_scoring_provider.dart
lib/features/matches/screens/match_live_screen.dart
lib/features/matches/screens/opening_innings_setup_screen.dart
```

---

# 31. Testing

Domain logic has tests for at least:

- Bowler Rotation Engine
- Innings Recalculation Engine
- Run Out Resolver
- Batter Replacement Service
- scoring/wicket validation behavior

Tests should be expanded whenever a rule or state transition is changed.

Always run:

```powershell
flutter analyze
flutter test
```

Do not claim either passes unless the actual command output has been checked.

---

# 32. Current Git State / Continuity

Current development branch:

```text
feature/live-wicket-delivery-dialog-v2
```

Recent relevant commits:

```text
6f23a86a7985e8096a158294b0985370e47d104e
Compatibility fix: AsyncValue.valueOrNull → asData?.value

369780e89056b56ab381cf481de2e9683c9515df
Keep live scoring navigation available after invalid bowler selection

cad0e74872b9e4900c25ad1030f7c1f109aaa93b
Remove unnecessary non-null assertion in live scoring provider
```

At the time this README was updated, the user's local analyzer had reported:

```text
1 issue found
warning - unnecessary_non_null_assertion
```

That warning was then fixed in commit `cad0e74872b9e4900c25ad1030f7c1f109aaa93b`.

**Analyzer has not been independently run by the assistant. The user should run it locally and confirm the result.**

---

# 33. Known Current Limitations / Next Work

These are known and should not be forgotten:

1. **Match Player Management** during a live match still needs implementation.
2. **Match Result Engine / Result screen** still needs full implementation.
3. **Target-reached innings completion** is not fully wired through all live application flows.
4. **Four-innings aggregate target/result integration** needs completion and tests.
5. **Innings completion persistence** must be verified; do not assume `completed` is persisted just because the recalculated UI says complete.
6. **2-Bowler opening second bowler persistence** is currently live-state only; persistence across restart needs a proper DB design/migration if required.
7. Tournament provider should eventually use the persisted tournament repository consistently rather than relying on in-memory state.
8. Live action errors should remain action-level errors and not become provider/load failures.
9. Expand automated tests around illegal deliveries, wickets with runs, target completion, innings transitions, and 2-Bowler Mode.
10. Future broadcast features include Windows Live Ticker, Broadcast Mode, External Display, and eventual vMix/OBS integration.
11. Web public live scorecard/shared match links are planned.
12. Cloud/live sync is planned for a later phase.

---

# 34. Planned Live / Broadcast Features

Windows is intended to provide additional management/scoring functionality including:

- Live Ticker
- Broadcast Mode
- External Display
- Future vMix / OBS integration

The web version is intended to provide:

- public live scorecard
- shared match links
- tournament standings
- tournament results

These should consume the same ball-by-ball source of truth rather than creating a second scoring model.

---

# 35. Database Rules

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

---

# 36. Coding Rules for Future Sessions

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
15. After a significant implementation decision, update this README so another chat/session can continue from it.

---

# 37. Quick Handover Summary

If a new development session starts, the minimum context is:

```text
Project: Flutter Cricket Scorer
Repository: oddife/cricket_scorer
Branch: feature/live-wicket-delivery-dialog-v2

Architecture:
Flutter → Riverpod → Application Services → Domain Engines → Repositories → Drift/SQLite

Source of truth:
Ball-by-ball BallEvents

Formats:
2 innings: A → B
4 innings: A → B → A → B

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

Live UI:
Invalid scoring/bowler validation must show an error without replacing live state.
Live screen has a Back button.
Completed innings hides scoring/bowler controls and routes to next Opening Setup.

Next major implementation:
In-match Player Management, then complete Match Result/target handling and tests.
```

---

## README Maintenance

This document is intentionally more detailed than a normal project README. Its purpose is continuity between development sessions.

**When the chat ends, this file should be the first project document read in the next session.**
