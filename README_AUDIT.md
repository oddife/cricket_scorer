# Cricket Scorer — Project Audit & Continuity Notes

> **Purpose:** Records the current architecture, locked product rules, verified checkpoints, known risks, and development direction. This supplements `README.md`; it does not replace it.

---

## Audit / continuity date

**17 September 2026**

Branch:

```text
feature/live-wicket-delivery-dialog-v2
```

---

# 1. Current verified checkpoint

The latest local verification reported by the scorer is:

```text
flutter analyze
No issues found!

flutter test
00:04 +97: All tests passed!
```

A Flutter Web production build was also completed successfully:

```text
Compiling lib\main.dart for the Web...
√ Built build\web
```

The generated web output contains the expected Flutter application files including `index.html`, `main.dart.js`, `flutter.js`, `flutter_bootstrap.js`, `manifest.json`, `assets/`, `canvaskit/`, and `icons/`.

> These automated results are verified checkpoints only. Manual scorer workflows still require real application testing.

---

# 2. Overall audit status

| Area | Status | Notes |
|---|---|---|
| Match setup | 🟢 | Teams, players, toss, innings count, overs and 2-Bowler Mode are wired into match creation. |
| Playing XI | 🟢 | Global players are selected for matches. |
| Opening innings setup | 🟢 | Striker, non-striker and opening bowler selection are separated from availability. |
| 2-Bowler Mode | 🟡 | Core legal-delivery rotation exists; focused manual testing remains. |
| Normal scoring | 🟢 | Persisted BallEvents are the scoring source of truth. |
| Extras | 🟢 | Wide, no-ball, bye and leg-bye workflows exist. |
| Wickets | 🟢 | Delivery-aware wicket and replacement workflow exists. |
| Undo | 🟢 | Uses persisted ball-event history. |
| Innings transition | 🟢 | Completed non-final innings returns to Opening Innings Setup. |
| Match result | 🟢 | Two- and four-innings result calculation exists. |
| Scorecard/PDF | 🟢 | Implemented. |
| Tournament management | 🟢 | Teams and points rules are persisted and managed. |
| Global players/teams | 🟢 | Reusable global entities are separate from memberships. |
| Supabase sync | 🟢 | Catalog and ball-event sync was successfully verified previously. |
| Recovery | 🟢 | Recovery/import and tournament consistency checks exist. |
| Live match navigation | 🟢 | Missing `/matches/:matchId` fallback was fixed. |
| Live Matches | 🟢 | Real repository-backed Live Matches screen and Home preview exist. |
| PC management dashboard | 🟢 | Responsive management dashboard exists. |
| PC player management | 🟢 | Responsive global-player management UI implemented. |
| PC team management | 🟢 | Responsive global-team management UI implemented. |
| PC tournament list | 🟢 | Responsive tournament list/table management UI implemented. |
| Tournament management UI | 🟡 | Existing participating-team/squad/points workflow is functional; further PC polish remains. |
| Web/PWA build | 🟢 | Flutter Web build verified successfully. |
| Production web deployment | 🟡 | Docker/Nginx/Traefik deployment is the next infrastructure step. |
| App restart during live match | 🟡 | Architecture supports recovery; deliberate manual test remains. |
| Real scorer UX | 🟡 | Needs field-style manual testing. |

---

# 3. Locked product rules

## Match type

Match type is always:

```text
Custom
```

Do not add T10/T20/ODI presets unless explicitly requested.

## Balls per over

Always:

```text
6 legal balls
```

This is not a user setting.

## Innings

Allowed configurations:

```text
2 innings
4 innings
```

Four-innings order:

```text
A → B → A → B
```

No follow-on, declarations or draw logic.

## Two-Bowler Mode

Two selected bowlers alternate on **legal deliveries only**:

```text
1 → A
2 → B
3 → A
4 → B
5 → A
6 → B
```

Wides and no-balls do not consume legal balls and therefore do not advance bowler rotation.

For an odd innings length, the final odd over is handled as a single-bowler over.

> Historical TypeScript double-bowler experiments are not the current product specification.

---

# 4. Global player and team model

Players are global reusable entities.

One real player should have one global `players` record. Team membership is separate through `team_players`, and tournament membership is separate through `tournament_teams`.

A player may belong to multiple teams. Removing a player from a team must not delete the global player.

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

PC management and ground scoring must use the same global player records.

Teams follow the same reusable-entity principle.

---

# 5. PC management / PWA direction

The application now has a responsive management area intended to make administration easier from a desktop browser while retaining the mobile scorer workflow.

Management dashboard route:

```text
/admin
```

The dashboard provides access to:

```text
Players
Teams
Tournaments
Live Matches
Recent Matches
Recovery
Settings
```

## Players

The PC player page provides:

- Global player list.
- Search by name, display name or jersey number.
- Active/inactive filtering.
- Player summary counts.
- Add player.
- Edit player.
- Deactivate player.
- Open player profile.

The same screen remains responsive for mobile/ground use.

## Teams

The PC team page provides:

- Global team list.
- Search by team name or short name.
- Active/inactive filtering.
- Team summary counts.
- Add/edit/deactivate team.
- Manage Squad.
- Existing global-player selection for squad membership.
- Creation of a new global player when required.

Removing a player from a squad changes membership only; it must not delete the global player.

## Tournaments

The PC tournament list provides:

- Tournament search.
- Active/inactive filtering.
- Tournament summary counts.
- Desktop table view.
- New tournament.
- Tournament profile.
- Tournament management.
- Edit/deactivate actions.

The tournament management page currently supports:

- Participating global teams.
- Team removal.
- Manage Squad navigation.
- Tournament points rules.
- Custom per-tournament points.

Further PC layout polish is still planned for the tournament management page.

---

# 6. Live match navigation and Live Matches

A previous manual test produced:

```text
Page Not Found
GoException: no routes for location: /matches/29
```

The cause was a missing `/matches/:matchId` route while live scoring could fall back to that path.

The fallback route has been added.

Current important match routes include:

```text
/matches/live
/matches/recent
/matches/recovery
/matches/normal/new
/matches/normal/playing-xi
/matches/:matchId/opening
/matches/:matchId/live
/matches/:matchId/scorecard
/matches/:matchId
```

The Live Matches screen reads `matchProvider`, filters `MatchStatus.live`, and opens matches using `/matches/{id}/live`.

The Home screen also displays a repository-backed Live Matches preview.

The Playing XI workflow invalidates `matchProvider` after successful match creation so the newly created live match is not hidden behind stale provider state.

Manual verification of Back navigation and the live-match list is still required.

---

# 7. Scoring architecture

Persisted `BallEvent` history remains the source of truth.

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

The live provider rebuilds state from persisted events when initialized. Do not introduce a competing UI-only score authority.

`LiveScoringNotifier` covers bowler selection, two-bowler selection, batter selection/swap, replacement batters, runs, extras, wickets, innings ending, undo and final match completion persistence.

---

# 8. Wickets and replacements

Supported delivery contexts include:

```text
Normal
Wide
No-ball
Bye
Leg-bye
```

Wicket selection is optional in the relevant delivery workflows.

The scoring engine decides bowler wicket credit. The UI must not invent that result.

Replacement batters are explicitly selected by the scorer. The application must never invent a replacement batter.

---

# 9. Tournament rules

Default tournament points:

```text
Win       = 2
Tie       = 1
No Result = 1
Loss      = 0
```

Points are customizable per tournament.

Tournament standings are derived from match results.

Recovery is conservative:

- Existing local tournament points remain authoritative.
- Remote divergence from an existing local configuration is rejected rather than silently overwriting local settings.
- If local tournament points do not exist, compatible remote rules may be imported.

---

# 10. Supabase and synchronization

The approved backend is self-hosted Supabase.

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

Local SQLite remains authoritative for offline scoring. Supabase is the distribution/synchronization layer.

Catalog synchronization is dependency-aware:

```text
team
player
team_player
tournament
then match-dependent records
```

Stable sync identities are used for teams, players, memberships, tournaments, matches, innings and ball events.

A previously verified checkpoint showed:

```text
Connected
Sync successful: 50 ball events
catalog synced 33
failed 0
blocked 0
```

That count is historical verification and must not be treated as the current database count unless rechecked.

---

# 11. Supabase authentication

The scorer uses automatic anonymous authentication for its session.

The publishable/anon API key controls API access but does not itself identify a user session. Anonymous authentication creates an authenticated Supabase session without requiring an email/password.

Email/password remains a backup account path where implemented.

Never place service-role or secret keys in the Flutter client.

Previously exposed troubleshooting credentials/tokens should be rotated if still valid. Actual secrets must never be written into this document.

---

# 12. Envoy diagnostic

A previous anonymous-auth failure returned HTTP 503:

```text
upstream connect error or disconnect/reset before headers
reset reason: remote connection failure
```

The investigation found Envoy could resolve the Auth service to IPv6 even though the Envoy container had no usable IPv6 interface/route.

The selected fix was:

```yaml
dns_lookup_family: V4_ONLY
```

The application subsequently reached successful Supabase synchronization.

> Do not claim Envoy active health-check flags are independently fixed unless rechecked. Successful application synchronization is the verified outcome.

---

# 13. Web/PWA deployment plan

Flutter Web has been successfully built locally with:

```text
flutter build web
```

The generated `build/web` directory is suitable for deployment.

The intended production architecture is:

```text
GitHub
   ↓
git pull
   ↓
/docker/cricket-scorer
   ↓
Docker multi-stage build
   ├── Flutter build stage
   └── Nginx runtime stage
             ↓
       cricket-scorer-web
             :80
             ↓
          Traefik
             ↓
       cricket.odhome.in
```

The production container should contain only the compiled Flutter web application and Nginx. Flutter does not need to be installed in the runtime container.

The first deployment will use **manual Traefik configuration**, without Traefik labels in the Cricket Scorer Compose file. Labels can be introduced later after the manual routing is proven.

The repository source should eventually be deployed from `main` after changes are merged and verified. During development, the feature branch may be used for controlled testing.

---

# 14. Focused manual tests still required

## A. Two-Bowler Mode

Test legal and illegal deliveries together:

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

## B. Odd overs

For 3 overs:

```text
Overs 1–2 → selected two-bowler block
Over 3    → one selected final-over bowler
```

Repeat conceptually for other odd lengths.

## C. App restart

During an unfinished innings, restart the app and verify score, wickets, striker, non-striker, bowler, legal-ball count, over number, ball history and two-bowler state.

## D. Full scorer workflow

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

Test Windows desktop, tablet/iPad width and phone width. Pay attention to button wrapping, trailing controls, dialogs, dropdowns and scorer-pad usability.

---

# 15. Regression matrix

### Test 1 — Basic match

Use a short match and verify:

```text
0 / 1 / 2 / 3 / 4 / 6
wide
no-ball
bye
leg-bye
wicket
undo
end innings
```

### Test 2 — Two-Bowler Mode

Use 3 overs and verify legal-delivery alternation plus final odd-over behavior.

### Test 3 — Illegal deliveries

Verify wides/no-balls do not consume legal balls or advance legal-delivery bowler rotation.

### Test 4 — Four innings

Verify:

```text
Innings 1 → A
Innings 2 → B
Innings 3 → A
Innings 4 → B
```

### Test 5 — Restart

Restart during an unfinished innings and verify state reconstruction.

### Test 6 — Back navigation

Start a match, enter Live Scoring and press Back. Expected destination is Live Matches, not Page Not Found.

### Test 7 — Live Matches

Start a new match and verify it appears as Live and opens correctly.

### Test 8 — Home preview

Return Home during a live match and verify the active match appears in the Live Matches section.

---

# 16. Verification discipline

After code changes use this order:

```powershell
git pull
flutter analyze
flutter test
```

Do not claim tests passed unless they were actually run or verified by CI.

Do not claim manual scoring tests passed unless the scorer actually performed them.

For a web deployment checkpoint, also run:

```powershell
flutter build web
```

and record the result only after it succeeds.

---

# 17. Development discipline

1. Read this audit and `README.md` before substantial changes.
2. Preserve locked product rules.
3. Keep cricket calculations in domain/application services rather than UI widgets.
4. Keep files modular.
5. Prefer persisted facts over duplicated state.
6. Add tests for rule changes.
7. Run analyze/test before declaring an automated checkpoint.
8. Manually test changes affecting navigation, live scoring, recovery or scorer UX.
9. Update this audit when an important defect is fixed or a new verified checkpoint is reached.

---

# 18. Current next development checkpoint

The immediate development direction is:

```text
1. Finish Tournament Management PC polish.
2. Verify the management dashboard/Players/Teams/Tournaments in the browser.
3. Set up Docker multi-stage Flutter Web deployment at /docker/cricket-scorer.
4. Configure manual Traefik routing.
5. Verify the PWA against self-hosted Supabase.
6. Then perform focused live-match regression testing.
7. Resolve remaining manual UX findings.
8. Bring main into the feature branch, resolve conflicts carefully, verify again, then merge.
```

The existing scoring architecture and locked cricket rules take priority over UI polish.