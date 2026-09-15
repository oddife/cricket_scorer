# Match Result and Scorecard Logic

This document records the current agreed behavior for match completion, targets, lead/deficit display, and scorecard presentation.

## Two-Innings Match

Format:

```text
Team A → Team B
```

After Team A's innings:

```text
Target for Team B = Team A score + 1
```

The scorecard must show the target while Team B is batting.

If Team B reaches the target, Team B wins by wickets.

If Team B finishes below the target, Team A wins by runs.

If both scores are equal, the match is tied.

## Four-Innings Match

Format:

```text
A → B → A → B
```

After innings 2, show the current aggregate **lead/deficit** between the teams.

After innings 3, show the current aggregate **lead/deficit** again.

For innings 4, calculate:

```text
A aggregate = A innings 1 + A innings 2
B first innings = B innings 1
B fourth-innings target = A aggregate - B first innings + 1
```

The fourth-innings target is never displayed below 1; if the calculation is below 1, the displayed target is 1.

The scorecard must show the fourth-innings target while Team B is batting.

Lead/deficit is always based on cumulative aggregate scores through the displayed innings:

- Positive → batting team leads by that number.
- Negative → batting team trails by the absolute value.
- Zero → scores level.

## Match Winner

The live match screen must show the winner when the configured final innings is complete.

The scorecard must also show the completed result.

For a two-innings chase:

- chasing team ahead → winner by wickets
- defending team ahead → winner by runs
- equal → tied

For four innings, the result compares the final aggregate totals. The final batting team can win by wickets when its aggregate is higher; otherwise the other team wins by the aggregate run difference. Equal aggregate is a tie.

## Scorecard Presentation

Each innings section should show:

- innings number
- batting team
- score/wickets
- overs
- target where applicable
- lead/deficit where applicable
- batter statistics

The scorecard is reached from the live match through the **Scorecard** action.

## Important Architecture Rule

Target/lead/deficit/result calculations belong in the domain/application result logic, not inside scoring buttons or UI widgets.

The ball-by-ball events remain the source of truth. The scorecard derives its values by recalculating innings from BallEvents.

## Current Implementation

Implemented:

- `MatchResultService`
- target calculation for second innings
- target calculation for fourth innings
- lead/deficit calculation
- match result calculation
- `MatchScorecardScreen`
- live result banner
- live Scorecard navigation

The fourth-innings target is calculated from the first three innings, not from a manually entered value.
