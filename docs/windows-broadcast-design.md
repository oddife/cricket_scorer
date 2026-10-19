# Windows Broadcast Output — Initial Design

## Goal

Add a Windows-hosted broadcast output for cricket score graphics that OBS and vMix can load as browser sources. Broadcast output must consume the existing Cricket Scorer match/scoring data. It must not introduce a second scoring engine or alter scoring, Undo, match recovery, or Supabase synchronization.

## One base URL for management and every overlay

The existing Windows Cricket Scorer app will be the broadcast management surface. Add a Broadcast panel to the app's existing UI; do not create a separate management webpage or management URL.

A small local HTTP server will serve the OBS/vMix browser-source graphics. All overlay URLs share the same scheme, host, and port; only the path changes.

Proposed default base URL:

```text
http://127.0.0.1:3113
```

Routes:

| Purpose | URL |
|---|---|
| Main scorecard browser source | `/broadcast/scorecard` |
| Bottom ticker browser source | `/broadcast/ticker` |
| Player lower-third browser source | `/broadcast/lower-third` |
| Last-ball / event graphic browser source | `/broadcast/last-ball` |
| Machine-readable live state | `/api/v1/broadcast/state` |

The Windows app's Broadcast panel will display and copy the full browser-source URLs, such as `http://127.0.0.1:3113/broadcast/scorecard`. The port should be configurable and the app must show the actual URLs after startup rather than assuming the default always succeeded.

Port 3113 is a proposed default because the existing Docker Flutter Web deployment uses host port 3112. If the broadcast port is unavailable, report the issue clearly; do not silently invent a different URL that the user cannot discover.

## Hosting and access

- The first version is for the Windows desktop scorer and OBS/vMix running on the same Windows machine.
- Bind to loopback (127.0.0.1) by default. Do not expose manual broadcast controls to the LAN by default.
- The Flutter desktop Broadcast panel controls the in-process broadcast state directly. It is not hosted as a browser page and is not exposed as an HTTP management route.
- Keep browser-source views read-only. They should not need a separate server, port, CORS configuration, or another app.
- LAN access for browser sources can be added later as an explicit setting with a visible warning. Keep remote control of broadcast graphics out of scope by default.
- Use an embedded Dart HTTP server with platform-conditional imports so Windows server code is excluded from Flutter Web builds and other unsupported targets.

## Live-state requirements

- The selected match and innings must come from existing local persisted match, innings, participant, and ball-event records.
- Reuse the existing domain scoring/recalculation logic wherever possible. Do not calculate an independent score solely for broadcast.
- Refresh graphics after scoring, Undo, wicket Undo, innings transitions, match completion, and remote recovery/sync refresh. An undone delivery must disappear from every relevant graphic.
- If no match is selected or data is not ready, show a safe, intentional empty state rather than stale data from a previous match.
- The state endpoint should provide a documented JSON snapshot with match/innings identity, team names, score, overs, batter/bowler lines, target/chase context when applicable, recent deliveries, current-over deliveries, and match result/status.
- Browser-source pages must use transparent backgrounds outside the graphic, work at 1920x1080 and scale cleanly for 4K, and avoid controls/scrollbars in output mode.

## Management-panel capabilities

Add a Broadcast panel inside the existing Windows Cricket Scorer app. It should allow the operator to select the match/innings, copy all source URLs, show/hide each overlay, send a manual ticker, and trigger/cancel a temporary event graphic (Four, Six, Wicket, or custom message). Temporary events must expire or be clearable and must never modify the score.

The Flutter desktop panel is the control surface. Browser-source URLs are clean output surfaces backed by the same in-process broadcast state; there is no separate management URL.

## Delivery plan

1. Add a Windows-only local broadcast server and a shared broadcast-state contract, with tests for URL routing and state serialization.
2. Add transparent starter pages for the scorecard, ticker, lower-third, and last-ball graphic, with no controls in output views.
3. Connect the output server and in-app Broadcast panel to the existing app/database and verify scoring and both types of Undo update the overlays.
4. Add in-app controls, temporary event messaging, and copyable browser-source URLs.
5. Test in OBS and vMix as browser sources; document startup, port conflicts, LAN-access limits, and recommended browser-source settings.

## Safety boundary

Broadcast work must stay on its own feature branch until deliberately reviewed and merged. Do not modify `main` or the tested scoring/sync branch as part of broadcast development. Do not clear or reset any local database to test the broadcaster.