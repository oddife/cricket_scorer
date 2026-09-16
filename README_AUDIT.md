# Cricket Scorer — Project Audit & Continuity Notes

> **Purpose:** This document records the latest architecture/workflow audit, confirmed behavior, known risks, and the manual verification plan. It is intended to prevent future development from losing decisions made during the audit.
>
> This is an audit/continuity document. It does **not** replace `README.md`; it supplements it.

---

## Audit date

**17 September 2026**

Branch audited:

```text
feature/live-wicket-delivery-dialog-v2
```

---

# 1. Overall Audit Result

The application has a functioning offline-first scoring architecture with the major match-management, tournament, player/team, scoring, recovery, and Supabase synchronization pieces implemented.

### Current assessment

| Area | Status | Audit finding |
|---|---|---|
| Match setup | 🟢 | Teams, players, toss, innings count, overs and 2-Bowler Mode are wired into match creation. |
| Playing XI | 🟢 | Global players are selected for the match and fewer than configured team size can be available initially. |
| Opening innings setup | 🟢 | Striker, non-striker and opening bowler selection are separated from player availability. |
| 2-Bowler Mode | 🟡 | Core legal-delivery rotation exists, but edge cases require focused real-device/manual testing. |
| Normal scoring | 🟢 | BallEvent history is the source used to rebuild scoring state. |
| Extras | 🟢 | Wide, no-ball, bye and leg-bye workflows are implemented. |
| Wickets | 🟢 | Delivery-aware wicket workflow and batter replacement are implemented. |
| Undo | 🟢 | Undo operates through persisted ball-event history. |
| Innings transition | 🟢 | Non-final completed innings returns to Opening Innings Setup. |
| Match result | 🟢 | Two- and four-innings result calculation is implemented. |
| Scorecard/PDF | 🟢 | Scorecard and PDF workflows are implemented. |
| Tournament management | 🟢 | Tournament teams and points rules are persisted and managed. |
| Global players/teams | 🟢 | Global entities are separate from team/tournament membership. |
| Supabase sync | 🟢 | Catalog and ball-event synchronization has been verified previously. |
| Recovery | 🟢 | Recovery/import and tournament consistency checks are implemented. |
| App restart during live match | 🟡 | Architecture supports recovery, but a deliberate manual restart test remains required. |
| Scorer UX | 🟡 | Functional; real-world scorer usability still needs manual testing. |
| Desktop/mobile polish | 🟡 | Responsive screens exist, but further device-specific testing remains. |
| Live match navigation | 🟡 → fixed in latest commits | Back navigation exposed a missing `/matches/:matchId` route; this has now been addressed. |

---

# 2. Important Audit Finding — Live Match Navigation

During manual testing, starting a new match and pressing Back from the live scoring screen produced:

```text
Page Not Found
GoException: no routes for location: /matches/29
```

The cause was confirmed in the router.

The live scoring screen had a fallback to:

```dart
context.go('/matches/$matchId');
```

but the router previously defined only:

```text
/matches/:matchId/opening
/matches/:matchId/live
/matches/:matchId/scorecard
```

There was no `/matches/:matchId` route.

### Fix

A `/matches/:matchId` route was added as a navigation fallback to the Live Matches page.

The live match screen therefore no longer points at a nonexistent route when there is no previous route in the navigation stack.

---

# 3. Important Audit Finding — Live Matches Was Only a Placeholder

The Home screen previously contained a static section:

```text
Live Matches
No live matches
```

It did not query the match repository.

This meant a match could correctly be created with:

```text
MatchStatus.live
```

while the Home page still displayed:

```text
No live matches
```

### Fix

A real Live Matches workflow was added.

The new screen:

- Reads `matchProvider`.
- Filters matches where `status == MatchStatus.live`.
- Sorts live matches by match date.
- Opens the selected match using `/matches/{id}/live`.
- Provides a manual Refresh action.
- Shows `No live matches` only when no live records exist.

The Home screen now also displays a live-match preview using the same repository/provider data.

---

# 4. Match Creation Status

`StartMatchService` creates the match initially as:

```text
MatchStatus.setup
```

and, after teams, players, availability and toss are persisted, updates the match to:

```text
MatchStatus.live
```

The service therefore provides the correct database state for the Live Matches list once match creation completes.

The Playing XI workflow now explicitly invalidates `matchProvider` after the match is successfully created so a previously cached match list is not relied upon for the new record.

---

# 5. Locked Product Rules

These rules must not be changed accidentally during future refactoring.

## Match type

Match type is always:

```text
Custom
```

Do not add T10/T20/ODI preset choices unless explicitly requested.

## Balls per over

Always:

```text
6 legal balls
```

This is not a user setting.

## Innings

Allowed match configurations:

```text
2 innings
4 innings
```

Four-innings order:

```text
A → B → A → B
```

No follow-on, declarations, or draw logic.

## Two-Bowler Mode

Two selected bowlers alternate on **legal deliveries only**.

Six legal balls:

```text
1 → A
2 → B
3 → A
4 → B
5 → A
6 → B
```

Illegal deliveries such as wides and no-balls do not advance the legal-ball count and therefore do not rotate the active bowler.

For an odd innings length, the final odd over is handled as a single-bowler over.

> **Do not confuse this locked Flutter rule with historical TypeScript experiments in the old project.** Historical material is useful for investigation only and is not automatically the current product specification.

---

# 6. Global Player and Team Model

Players are global reusable entities.

One real player should have one global `players` record.

Team membership is represented separately through `team_players`.

Tournament membership is represented separately through `tournament_teams`.

A player may belong to multiple teams.

Removing a player from a team must not delete the global player.

Ground workflow:

```text
Search global players
       ↓
Found → select existing global player
       ↓
Not found → create one global player
       ↓
Associate player with current team/match
```

The PC management workflow and ground scoring workflow must use the same global player records.

Teams follow the same reusable-entity principle.

---

# 7. Current Navigation Model

Important match routes:

```text
/matches/live
/matches/recent
/matches/recovery
/matches/normal/new
/matches/normal/playing-xi
/matches/:matchId/opening
/matches/:matchId/live
/matches/:matchId/scorecard
/matches/:matchId        ← fallback route added by audit fix
```

The fallback route exists specifically so navigation cannot land on the Page Not Found screen when the scorer backs out of a live match without a usable previous route.

---

# 8. Current Scoring Architecture

The scoring source of truth remains persisted `BallEvent` history.

Conceptually:

```text
Scoring UI
   ↓
LiveScoringNotifier
   ↓
ApplyScoringActionService
   ↓
BallEvent repository
   ↓
Persisted BallEvent history
   ↓
InningsRecalculationEngine
   ↓
Current score/state
```

The live provider rebuilds the innings state from persisted events when it initializes.

This is important for offline operation and app restart recovery.

The UI should not introduce a second competing score authority.

---

# 9. Current Live Scoring Responsibilities

`LiveScoringNotifier` currently handles:

- Bowler selection.
- Two-bowler pair selection.
- Final odd-over bowler selection.
- Batter selection/swap.
- Replacement batter selection.
- Normal runs.
- Wide.
- No-ball.
- No-ball delivery details.
- Bye.
- Bye delivery details.
- Leg-bye.
- Leg-bye delivery details.
- Wickets.
- Explicit innings ending.
- Undo.
- Final match completion persistence.

The notifier also invalidates innings and ball-event providers after mutations so the UI can refresh from persisted state.

---

# 10. Wicket and Replacement Audit

The current design uses a delivery-aware wicket workflow.

Supported delivery contexts include:

```text
Normal
Wide
No-ball
Bye
Leg-bye
```

Wicket selection is optional for these delivery workflows.

The scoring engine remains responsible for deciding bowler wicket credit rather than allowing the UI to invent the result.

Replacement batters are explicitly selected by the scorer.

The application must never invent a replacement batter.

---

# 11. Tournament Audit

Tournament management is implemented with:

- Global reusable teams.
- Global reusable players.
- Tournament team membership.
- Tournament points rules.
- Tournament standings derived from match results.
- Tournament synchronization.
- Recovery/import of tournament metadata.

Default points:

```text
Win       = 2
Tie       = 1
No Result = 1
Loss      = 0
```

Points are customizable per tournament.

Recovery behavior is deliberately conservative:

- Existing local tournament points remain authoritative.
- If remote tournament points diverge from an existing local configuration, recovery rejects the divergence rather than silently overwriting local settings.
- If local tournament points do not exist, compatible remote rules can be imported.

---

# 12. Supabase / Sync Audit

The approved backend remains self-hosted Supabase.

Architecture:

```text
Flutter
  ↓
Local Drift / SQLite
  ↓
Durable Sync Queue
  ↓
Supabase
  ├── PostgreSQL
  ├── Auth
  ├── Realtime
  └── API
```

Local SQLite remains authoritative for offline scoring.

The synchronized backend is the distribution layer.

Catalog synchronization covers global/shared entities and dependencies before match ball events are uploaded.

Catalog ordering is dependency-aware:

```text
team
player
team_player
 tournament
then match-dependent records
```

Stable sync identities are used for:

- Teams.
- Players.
- Team-player relationships.
- Tournaments.
- Matches.
- Innings.
- Ball events.

The previously verified synchronization checkpoint showed:

```text
Connected
Sync successful: 50 ball events
catalog synced 33
failed 0
blocked 0
```

The catalog count of 33 corresponded to the then-current synchronized records:

```text
teams          2
players       27
team_players   2
tournaments    2
------------------
               33
```

That checkpoint is historical verification and must not be treated as a claim about the current live database count unless rechecked.

---

# 13. Supabase Authentication Note

The application uses automatic anonymous authentication for the scorer session.

The publishable/anon API key identifies the Supabase API access level but does not itself identify a user session.

Anonymous authentication provides an authenticated Supabase session without requiring the scorer to enter an email/password.

Email/password remains available as a backup account path where implemented.

Do not place service-role or secret keys in the Flutter client.

Previously exposed credentials/tokens from troubleshooting should be considered compromised and rotated if they are still valid. Never put actual secrets in this document.

---

# 14. Supabase / Envoy Diagnostic Finding

A previous anonymous-auth failure returned HTTP 503 with:

```text
upstream connect error or disconnect/reset before headers
reset reason: remote connection failure
```

The investigation found that Envoy's DNS resolution for the `auth` service could select an IPv6 address even though the Envoy container had no usable IPv6 interface/route.

The Docker network's normal service resolution from another container returned the IPv4 Auth address correctly.

The selected fix was to set the Auth cluster's Envoy DNS lookup family to:

```yaml
dns_lookup_family: V4_ONLY
```

The application subsequently reached the point where Supabase sync was successfully verified.

> Do not claim the Envoy active health-check flag itself was independently resolved unless it is rechecked. The important verified result was successful application synchronization.

---

# 15. Audit: Areas Requiring Focused Testing

The following areas were not declared broken. They were identified as areas where code inspection alone is not enough.

## A. Two-Bowler Mode

Test legal and illegal deliveries together.

Example:

```text
Legal ball 1 → A
Wide         → A again
Legal ball 2 → B
No-ball      → B again
Legal ball 3 → A
```

Expected principle:

```text
Rotation follows legal-ball count.
```

Do not rotate the bowler merely because a scoring action occurred.

## B. Odd number of overs

For 3 overs:

```text
Overs 1–2 → selected two-bowler block
Over 3    → one selected final-over bowler
```

Repeat conceptually for 5 and 7 overs.

## C. App restart during live innings

Start scoring, record several deliveries, terminate/restart the application, reopen the match and verify:

- Score.
- Wickets.
- Striker.
- Non-striker.
- Bowler.
- Legal-ball count.
- Over number.
- Ball-by-ball history.
- Two-bowler state where applicable.

## D. Real scorer workflow

Test the complete sequence without artificial pauses:

```text
Start match
→ select players
→ toss
→ opening setup
→ score deliveries
→ extras
→ wicket
→ replacement
→ undo
→ end innings
→ next innings
→ final result
```

## E. Responsive UI

Test on:

- Windows desktop.
- iPad/tablet width.
- Phone width.

Pay particular attention to button wrapping, trailing controls, dropdowns, and scorer-pad usability.

---

# 16. Recommended Manual Regression Matrix

## Test 1 — Basic two-innings match

Use a short match such as 2 overs.

Verify:

```text
0
1
2
3
4
6
wide
no-ball
bye
leg-bye
wicket
undo
end innings
```

## Test 2 — Two-Bowler Mode

Use 3 overs.

Verify:

```text
Over 1 → A/B alternating legal deliveries
Over 2 → correct continuation/block behavior
Over 3 → final odd-over single bowler
```

## Test 3 — Illegal delivery rotation

Verify that wides and no-balls do not consume legal balls and do not advance legal-delivery bowler rotation.

## Test 4 — Four innings

Use 1–2 overs per innings.

Verify:

```text
Innings 1 → Team A
Innings 2 → Team B
Innings 3 → Team A
Innings 4 → Team B
```

## Test 5 — App restart

Restart during an unfinished innings and confirm state is reconstructed from the database.

## Test 6 — Back navigation

Start a match, enter Live Scoring, press Back.

Expected:

```text
Live Matches page
```

Not:

```text
Page Not Found
GoException
```

## Test 7 — New match appears in Live Matches

Start a new match and then open Live Matches.

Expected:

```text
New match appears with Live status.
```

## Test 8 — Home live preview

Start a live match and return to Home.

Expected:

```text
Live Matches section
→ active match displayed
→ Open returns to the match
```

---

# 17. Verification Rules for Future Development

The project should use this command order after code changes:

```powershell
git pull
flutter analyze
flutter test
```

Do not update the README's test count merely because code was changed.

Only update a verification count when the commands have actually been run and the result is known.

Do not say that manual tests passed unless the scorer has actually performed them.

---

# 18. Current Known State After This Audit

### Fixed

- Missing `/matches/:matchId` fallback route.
- Static Live Matches placeholder.
- Home Live Matches section now reads actual match state.
- Match provider refresh after successful match creation.

### Still to verify manually

- Two-Bowler Mode edge cases.
- Odd-over final-bowler behavior on a real scoring session.
- Restart/recovery during an active innings.
- Full scorer workflow from match creation through result.
- Desktop/mobile visual behavior.

### Important

The current codebase should not be considered fully field-validated solely from static inspection and automated tests. The remaining yellow items require actual application testing.

---

# 19. Development Discipline

When making future changes:

1. Read this audit and the main `README.md` first.
2. Preserve locked product rules.
3. Keep cricket calculations in domain/application services rather than UI widgets.
4. Keep files modular; do not turn screens into large monolithic files.
5. Prefer persisted facts over duplicated state.
6. Add tests for rule changes.
7. Run `flutter analyze` and `flutter test` before declaring an automated checkpoint.
8. Perform manual scoring tests for changes affecting navigation, live scoring, recovery, or scorer UX.
9. Update this audit when a yellow item is verified or a new important defect is discovered.

---

# 20. Next Development Checkpoint

The immediate next checkpoint is **manual live-match regression testing** after the navigation/live-match fixes.

Priority order:

```text
1. Confirm Back from Live Scoring no longer produces Page Not Found.
2. Confirm newly started match appears in Live Matches.
3. Open the match from Live Matches.
4. Verify normal scoring.
5. Verify 2-Bowler legal-delivery rotation.
6. Verify illegal-delivery behavior.
7. Verify app restart recovery.
8. Then continue with remaining UX/polish work.
```

This order keeps the core scorer workflow stable before adding more UI features.
