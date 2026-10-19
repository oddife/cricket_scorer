# Live Match Situation Display

The live scoring screen keeps the existing Scorecard button/navigation, but the most important match situation is also visible without leaving live scoring.

## Wide-screen placement

On screens 900px or wider, a small compact situation card is placed in the open/unused center area of the live score header.

It is intentionally small and does not replace the existing score, batter, bowler, scoring controls, result banner, or Scorecard button.

## Two-innings match

During innings 2 the compact card shows:

```text
TARGET 151   Need 133
```

The target is first-innings score + 1.

When the target is reached, the situation changes to:

```text
TARGET 151   Target reached
```

The existing final-match result banner remains unchanged and shows the winner/margin.

## Four-innings match

For innings 2 and 3, the compact card shows the current batting side's aggregate position:

```text
LEAD 10       After innings 2
```

or:

```text
DEFICIT 30    After innings 2
```

For innings 4 it switches to the final target/chase view:

```text
TARGET 131   Need 113
```

The target is calculated from the first three innings using the existing `MatchResultService`.

## Responsive behavior

The compact header situation is currently shown on wide layouts (900px+), where the live header has enough horizontal space. The existing Scorecard navigation remains available on every layout.

## Source of truth

The display is derived from the same persisted BallEvents and innings recalculation state used by the Match Result Service. It does not maintain a second score or target state.

## Locked behavior

Do not remove the existing result banner or Scorecard navigation when changing this UI. The compact situation is an additional at-a-glance display only.
