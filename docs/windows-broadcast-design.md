# Windows Broadcast Output — Initial Design

## Goal

Extend the Windows Cricket Scorer into two modules—**Scoring** and **Broadcast**—that can remain open in separate native desktop windows. Add a Windows-hosted broadcast output for cricket score graphics that OBS and vMix can load as browser sources.

Both modules must use the same local Drift database and existing scoring/domain logic. Broadcast output must not introduce a second scoring engine or alter scoring, Undo, match recovery, or Supabase synchronization. The normal workflow can score on Android and broadcast from Windows, but Windows must also be able to take over scoring locally when mobile-to-Supabase sync is unavailable.

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

## Windows modules and multiple windows

The desktop app should offer two clear modules from a home/switcher surface:

- **Scoring:** the full existing scoring experience, including match selection/setup, live scoring, scorecards, Undo, recovery, and Settings.
- **Broadcast:** the broadcast control panel, output server status, selected broadcast match, data-freshness/sync status, overlay visibility, ticker and event controls, and copyable source URLs.

The app must be able to open Scoring and Broadcast in separate native Windows windows and keep both open at once. It should be possible to move them between monitors, minimize one without stopping the other, and reopen/focus an already-open module rather than accidentally starting duplicate background services. Design the window-management layer so additional scoring/monitor/preview windows can be opened later.

All windows must share one authoritative local database and app-level services. There must be one coordinated SyncWorker and one broadcast-state coordinator—not one competing copy per window. Closing the Broadcast window must not stop the local broadcast server while OBS/vMix is using it; shutdown policy should stop the server only when the app is exiting or the operator explicitly stops broadcasting.

Before committing to a multi-window package or native runner changes, do a small Windows proof-of-concept with this project's current Flutter SDK and plugins. Prefer a supported approach that shares app state cleanly. Do not switch to Flutter's experimental/main-channel windowing API or change the project's Flutter channel as a shortcut without a separate compatibility review.

## Hosting and access

- The first version is for the Windows desktop scorer and OBS/vMix running on the same Windows machine.
- Bind the overlay server to loopback (127.0.0.1) by default. Do not expose manual broadcast controls to the LAN by default.
- The Flutter desktop Broadcast window controls the shared broadcast state directly. It is not hosted as a browser page and is not exposed as an HTTP management route.
- Keep browser-source views read-only. They should not need a separate server, port, CORS configuration, or another app.
- LAN access for browser sources can be added later as an explicit setting with a visible warning. Keep remote control of broadcast graphics out of scope by default.
- Use platform-conditional imports so Windows HTTP-server code is excluded from Flutter Web and unsupported targets.

## Match-day workflows and sync-failure fallback

### Normal workflow: Android scores, Windows broadcasts

1. Score on Android and allow the APK to sync deliveries to the configured Supabase project.
2. In the Windows Scoring or Broadcast window, sync/select the same match. The Broadcast window chooses a broadcast target independently of which match is open in the Scoring window.
3. OBS/vMix browser sources read the local Windows overlay URLs.
4. When Android scores a run, wicket, extra, or Undo, Windows imports that change through the existing SyncWorker and refreshes the graphics.
5. Show sync/data freshness in the Broadcast window. Do not claim that a remote score has arrived until Windows actually receives it.

### Fallback workflow: Windows scores, Windows broadcasts

If Android-to-Supabase sync fails or the Windows copy becomes stale, the operator can switch to the Windows Scoring window and continue from the last confirmed local match state. Because Scoring and Broadcast share the Windows app's local database and coordinator, local Windows scoring updates the overlays immediately; it does not need to travel through Supabase before appearing on the same PC.

The UI must clearly show the selected match, latest sync status, and most recent confirmed sync time, so the operator can identify whether Windows is current before taking over. When connectivity returns, the app should resume the existing sync/recovery flow; no new broadcast-specific sync system should be added.

**Only one device should actively score a match at a time.** When switching from Android to Windows because sync is failing, stop scoring on Android and explicitly take over from the last confirmed state first. Simultaneous scoring on Android and Windows can produce competing local event sequences/conflicts; the broadcast feature must not imply that concurrent scoring is safe.

The phone must not connect directly to the Windows broadcast server. Both devices use the same Supabase project for cross-device exchange. That path is eventual rather than a hard real-time guarantee, so actual sync latency must be measured and shown in the UI.

Selecting a broadcast target must not create a match, alter the score, or take over scoring controls.

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

1. Prove native multi-window support on the project's current Windows/Flutter setup without destabilizing Scoring or adding duplicate sync/database services.
2. Add the two module launch/focus controls and one shared app-level coordinator.
3. Add a Windows-only local broadcast server and a shared broadcast-state contract, with tests for URL routing and state serialization.
4. Add transparent starter pages for the scorecard, ticker, lower-third, and last-ball graphic, with no controls in output views.
5. Connect overlays to existing database/domain state and verify local Windows scoring, Android-synced scoring, Undo, wicket Undo, innings transitions, and match completion.
6. Add Broadcast controls, temporary event messaging, freshness/status indicators, and copyable browser-source URLs.
7. Test Android-scoring/Windows-broadcast, Windows fallback scoring during a sync outage, and OBS/vMix browser sources; document port conflicts, the single-active-scorer rule, and recommended source settings.

## Safety boundary

Broadcast work must stay on its own feature branch until deliberately reviewed and merged. Do not modify `main` or the tested scoring/sync branch as part of broadcast development. Do not clear or reset any local database to test the broadcaster.