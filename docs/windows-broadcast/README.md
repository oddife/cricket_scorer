# Windows Broadcast Output

This is the **authoritative product specification, implementation status, and acceptance checklist** for the Windows broadcast feature in Cricket Scorer.

- Repository: https://github.com/oddife/cricket_scorer
- Feature branch: **feature/windows-broadcast-output**
- Main OBS/vMix output: http://127.0.0.1:3113/broadcast/output
- Browser Broadcast Manager: http://127.0.0.1:3113/broadcast/manage

This document records the decisions agreed for the broadcast feature. Update it whenever implementation status or a locked product decision changes. Keep broadcast work isolated from the tested scoring/sync branch and main.

## 1. Product goals and safety boundaries

Build a Windows broadcast control experience with two native application windows: Scorer and Broadcast. The Broadcast window controls a single, transparent browser-source composition for OBS or vMix. Operators should not need one browser source per graphic.

The broadcast renderer is presentation-only:

- The existing local Drift database, scoring provider/domain logic, persisted ball events, undo/recovery implementation, and existing Supabase SyncWorker remain authoritative.
- Broadcast code must not write scoring events, recalculate cricket rules independently, or start a second SyncWorker.
- Android scoring reaches the Windows broadcast through the existing sync path. Sync is eventual; show actual freshness rather than claiming a delivery has arrived before Windows has received it.
- Only one device should actively score a match at a time. Do not imply that concurrent Android and Windows scoring is safe.
- A reconnect, refresh, restart, match switch, or historical-state reload must not replay old automatic event animations.
- Undoing the event that started an animation immediately cancels that animation. Undoing an unrelated event must not cancel an unrelated graphic.
- Hiding or taking graphics off air must never delete match data, layouts, themes, media, or assignments.

## 2. Current implementation status

**Baseline at Build 51:** the feature branch includes the reusable event-media library, first-pass automatic FOUR/SIX/WICKET playback, and confirmation-gated media deletion that lists assignments and rechecks them before clearing links. It is not the complete product below. The checklist is intentionally explicit; do not label a planned behavior as implemented until it has been built and tested.

### Present on the feature branch

- Typed broadcast snapshot model, snapshot builder/provider, and a shared presentation-state coordinator.
- A loopback-only HTTP server with port fallback across 3113–3118.
- The combined transparent output route at /broadcast/output and browser manager route at /broadcast/manage.
- A JSON state endpoint at /api/v1/broadcast/state and health check at /healthz.
- Independently toggled starter layers for compact scorecard, ticker, lower third, and event/last-ball graphic.
- A starter composite page that consumes the broadcast state and applies percentage-based layer geometry.
- Build 39 adds per-layer visibility and lock state plus editable bottom-to-top draw order. The Flutter layout editor hides/shows layers, prevents drag/resize while locked, supports step-forward/backward draw order, and persists settings with the current workspace. The combined browser output applies visibility and z-index from shared state.
- Build 37 adds independent scorebar rectangles for Minimal, Detailed, and Full broadcast bar. Geometry follows the selected style, is included in shared broadcast state, and is persisted in the Flutter workspace preferences.
- Compact scorebar default is now 94% wide × 8% high and sits directly above the ticker. Its dimensions are applied directly so typography is not vertically squashed when the operator resizes it.
- Broadcast settings and controls (visibility, event graphic, manual ticker, and player lower-third) can be collapsed as one section; its expanded/collapsed state is remembered.
- The compact scorebar uses its selected width and height directly instead of non-uniformly scaling the whole DOM layer, keeping glyphs from being vertically squashed when resized. Scorebar padding uses container-relative units so vertical spacing is calculated from the bar height, not its much larger width.
- Build 30 began sizing compact-scorebar typography and delivery chips relative to bar height and added collapsible server details.
- Build 31 removes a narrow-viewport percentage-padding override that could consume most of a short bar's height. Scorebar type and delivery chips now scale directly with the bar height, batter-row spacing is reduced, and the server card remains collapsible with status and Start/Stop kept visible.
- The Local broadcast server card can be minimized while keeping the server status and Start/Stop action visible; its expanded state is remembered.
- A Flutter layout editor with drag-to-move, resize handles, numeric X/Y/width/height controls, reset, named layout presets, local workspace/preset persistence, and geometry JSON import/export.
- Build 25 makes the layout editor collapsible (collapsed on first use and remembering the last state), adds layer-selection chips outside the canvas, and uses realistic miniature preview treatments for the scorebar, ticker, lower third and event graphic.
- Build 25 defaults the compact scorebar to a wide bottom layout, directly above the thin ticker. Untouched old default layouts are migrated to the new arrangement while custom workspace geometry is preserved.
- Opening Broadcast Manager no longer auto-starts the HTTP server. The operator must explicitly press Start Broadcasting; new server sessions still begin with every overlay hidden.
- Tests covering snapshot construction, coordinator state/layout, and HTTP routes.

### Not yet complete — do not imply otherwise

- A separate native Broadcast top-level Windows window, automatic two-window launch, close prompts, and robust reopen/focus behavior.
- A shared native window lifecycle proven to retain exactly one database and SyncWorker across windows.
- The Minimal/Detailed style selector, full batting/bowling tables, and Playing XI layouts. Build 27 adds the first designed horizontal Full broadcast Bar prototype using the live snapshot.
- Basic layer visibility, locking/unlocking, step forward/backward draw order, and selection chips are implemented for the current workspace. A complete layer panel with multi-select/reordering, bring-to-front/send-to-back, and the final editing workflow beneath overlapping full-screen layers is still planned.
- Persisted layout-specific styling and opacity beyond the per-style scorebar geometry added in Build 37, plus the remaining compact-scorecard rules.
- Full ticker playlists and summary configuration; lower-third event triggers/templates; and the event playback controls described below.
- Media asset storage, previews, upload/drop handling, team-logo management, reusable assignments, duplicate detection, replacement, and deletion safeguards.
- Portable export/import of selected layouts, themes, logos, and media files. Current layout JSON import/export is geometry-focused and must not be described as a complete asset bundle.
- The complete team-colour/custom-theme system, 1080p/4K runtime polish, and end-to-end validation against Windows, OBS/vMix, Android sync, and Undo.
- The full match-switch confirmation and state-preservation flow.

## 3. Windows launch and window lifecycle

### Startup

On Windows application launch:

1. Open the normal Scorer window.
2. Open a separate native Broadcast window.
3. Leave the broadcast HTTP server **stopped**. The operator explicitly presses **Start Broadcasting**.
4. Keep exactly one shared server, broadcast coordinator and SyncWorker for the application. Do not create a competing service when the other window is opened or refocused.
5. The Broadcast window must show stopped/running status and the actual chosen URLs after start.

The implementation must prove that its selected multi-window approach works with the pinned Flutter SDK/plugins. Separate Flutter engines may create separate provider scopes; do not assume in-memory Riverpod state is shared across engines. Design a deliberate shared-service/host/IPC arrangement before changing the Windows runner.

### Closing the Broadcast window

When the operator closes Broadcast, offer:

- **Keep broadcasting:** close the Manager UI but leave the server and output available to OBS/vMix.
- **Stop broadcasting:** stop the server/output and close the Manager.
- **Cancel:** leave the Manager open and make no changes.

If the server continues, Scorer must provide a way to reopen/focus the existing Broadcast window without making another server or sync worker.

### Closing Scorer

When closing Scorer while Broadcast is open or broadcasting, offer:

- **Keep broadcasting:** close Scorer but leave Broadcast, the server, and output running.
- **Stop and close everything:** stop the server/output and close both windows.
- **Cancel:** return to Scorer without changing anything.

The normal process exit must clean up owned services. Closing an individual UI window must not silently stop output that the operator chose to keep running.

## 4. URLs, server and output format

Expose exactly two operator-facing URLs in the normal workflow:

| Purpose | Default URL |
|---|---|
| Combined transparent output for OBS/vMix | http://127.0.0.1:3113/broadcast/output |
| Browser-based Broadcast Manager | http://127.0.0.1:3113/broadcast/manage |

Internal routes:

- JSON state: /api/v1/broadcast/state
- Health: /healthz

Requirements:

- Bind to IPv4 loopback 127.0.0.1 by default; do not expose management controls to the LAN by default.
- Prefer port 3113, then try 3114 through 3118. Display and copy the actual selected port; never display a URL for a port the server did not bind.
- OBS/vMix should need only one Browser Source for the combined composition.
- Render all broadcast layers inside that page; no browser controls or scrollbars in output mode.
- Use a transparent canvas so the live video remains visible outside graphics.
- Support 16:9 layouts at Full HD 1920×1080 and 4K 3840×2160.
- Keep manager/control views separate from the clean output view.
- Keep platform-conditional server imports so unsupported Flutter Web/non-IO targets do not load the Windows server implementation.

## 5. Layout editor and layer model

The editor must be usable during an actual broadcast setup session, not just show generic rectangles.

### Editor behavior

- The layout editor is collapsible and remembers whether it was expanded or minimized across restarts.
- Show a realistic miniature preview of actual graphic designs in the canvas rather than large generic boxes labelled only with layer names.
- Use a 16:9 canvas with drag-to-move, resize handles and precise numeric X/Y/width/height controls.
- Every layer appears in a layer list, even when hidden behind a full-screen layer. Selecting a layer in the list must make it editable regardless of overlap.
- Provide independent Select, Show/Hide, Lock/Unlock, Bring Forward/Send Backward controls. Hidden layers remain editable from the layer list.
- Each layer can be moved and resized independently. Support saved z-order and independent visibility.
- Layout changes auto-save to a current workspace and survive restarts.
- Named presets change only when the operator explicitly chooses **Save as New Preset** or **Update Preset**. Build 40 presets also capture the selected scorecard style, all three style-specific scorebar rectangles, layer visibility, lock state, and stacking order. Older geometry-only saved presets and version-1 JSON exports remain importable.
- Switching away from a changed workspace prompts to update the current preset and switch, keep editing the workspace, or discard changes and switch. The selected preset identity is remembered with the current workspace.
- When switching presets, ask whether to update the current preset, keep current edits only in the workspace, or discard them before switching.
- Provide a standard TV starter preset plus additional named presets (for example, Compact Scoreboard and Custom Match Day). Do not overwrite saved presets while experimenting.
- Geometry, ordering, layer visibility and per-layout behavior need their own persisted data. Import/export should validate input and recover gracefully from invalid JSON.

### Default composition

- **Compact Scorecard:** at the bottom by default, directly above the ticker. Freely movable and resizable.
- **Ticker:** a thin strip at the bottom edge by default, directly below the compact scorecard. Freely movable and resizable.
- **Lower Third:** independently movable/resizable; use its own position and size.
- **Event / Media:** independently movable/resizable; its shared default geometry can be overridden per event.
- Full-screen layouts may occupy the entire canvas. This must never block layer selection/editing in the editor.
- Layer order is custom. The operator decides whether ticker, lower third, event media, compact scorecard or full-screen scorecard appear above/below other visible layers.

### Save/portable preset behavior

Export/import must let the operator choose which categories to include each time: layouts, themes, team logos, and media assets. The finished portable bundle must include selected media bytes or a well-documented asset-copy mechanism; it must not depend on source-PC absolute file paths. Import should validate bundles, handle name conflicts safely, and let the operator decide how to apply matching assets. Do not export credentials, the private database or match data.

## 6. Compact scorecard styles

The Compact Scorecard has three selectable styles:

1. **Minimal**
2. **Detailed**
3. **Full broadcast bar** — the default, inspired by the third user-provided cricket broadcast reference.

Each style remembers its own position and size independently. Switching style restores that style's geometry, without changing the other styles.

### Full broadcast bar content and visual intent

Use a real TV-style horizontal composition, not a generic central box. Prefer team branding at the edge and visual sections for:

- Batting team identity, runs/wickets and overs.
- Current batters with individual runs and balls faced, using available source data.
- Extras and relevant innings/chase context.
- Current bowler figures.
- Recent deliveries/current over where space allows.

Use the current authoritative scoring state and recalculation, including extras and Undo. Never invent missing statistics. Team logo lookup should first use a usable logo available from the Cricket Scorer app. If unavailable, let the operator upload/manage a logo in Broadcast Settings; provide an abbreviation fallback when no logo has been supplied.

### Colours and transparency

- Automatically use team colours by default when available, with a readable broadcast fallback.
- Allow operators to create, save, and select custom colour themes.
- Keep graphic elements transparent outside the actual scoreboard design.
- Layout/style geometry and theme choices persist independently.

## 7. Full-screen scorecards

Provide manually selectable full-screen views:

- Combined Batting & Bowling
- Batting
- Bowling
- Playing XI

Provide both quick-switch buttons and a dropdown. There is **no automatic rotation**. Full-screen graphics remain visible until the operator changes the view or turns them off.

### Full-screen appearance and per-layout settings

- Choose Traditional Scorecard Table or TV Broadcast Design independently per saved layout/view.
- Save the layout's style, geometry, opacity and related settings.
- Opaque background is the default for full-screen scorecards; each layout can instead be configured as transparent.
- Compact Scorecard visibility during a full-screen scorecard is configurable per layout.
- Default the innings selector to the current innings. Allow manual selection of previous innings; keep the manually selected innings on air until the operator changes it.
- Support 1920×1080 and 3840×2160 without a scrolling table in the Combined view. Fit all batting and bowling rows by carefully adjusting row heights and text sizes while preserving sensible legibility.
- Never automatically switch away from a selected historical innings when the match moves forward.

### Combined Batting & Bowling

Default the Combined layout to **stacked**: full batting scorecard above the bowling scorecard. Save this choice per layout. The table data must come from the existing records/calculation flow, not an independent scoring engine.

The batting table should display available batting order, dismissal information, runs, balls, fours, sixes and strike rate, plus total/extras. The bowling table should display available overs, maidens, runs, wickets and economy.

### Playing XI

- Let each layout choose **one team at a time** or **both teams together**.
- Single-team mode provides manual team-switch controls.
- Show selected Playing XI players only: 11 per team, not the full registered squad.
- No player photos required.
- Mark captain and wicketkeeper when metadata exists.
- Keep text readable in both supported output resolutions.

## 8. Ticker

The ticker supports both manual messages and automatically generated match information; the operator chooses which mode is active.

### Default placement and presentation

- Place it along the bottom edge by default, below the Compact Scorecard.
- Position/size are independent and editable.
- Offer **Scrolling** and **Static** modes; scrolling moves smoothly right-to-left with adjustable speed.

### Manual message playlists

- Add multiple messages and configure playlist order.
- Provide Previous/Next manual controls.
- Configure automatic rotation, display duration and end behavior per playlist.
- Each playlist can either loop to the first message or stop on the last message.
- Preserve the manual ticker playlist and sponsor messages when switching matches.

### Automatic match-information playlists

Let the operator select summary types, arrange their order and set a display duration for each. Support available information such as:

- Current score and match status.
- Batter statistics.
- Bowler figures.
- Recent over/current-over summary.
- Target, runs required, run rate or required run rate where relevant.

Do not show chase-only fields where they do not apply. Switching matches updates automatic match information to the new match while preserving the manual ticker playlist.

## 9. Lower thirds

Lower thirds support both manually entered titles/subtitles and configurable automatic events. Position and size are independent; display duration is configurable.

### Automatic trigger types

Each trigger has its own enable/disable setting in Broadcast Settings:

- New batter/player introduction.
- Wicket: dismissed batter and incoming batter.
- Batter reaches 50 or 100 runs.
- Bowling milestone (for example 3 or 5 wickets).
- Partnership milestone (for example 50 or 100 runs).
- Innings starts or ends.
- Match result, winner and result summary.

Provide built-in templates plus editable, saved custom templates. Allow placeholders to insert available player names, scores and match details. Do not fabricate missing player data.

Per template, allow Slide, Fade or Instant entrance/exit, with adjustable animation speed. Display duration controls how long the lower third remains on air.

If a new automatic lower-third event arrives while one is active, the new automatic lower third immediately replaces the current one and starts its own timer. Manual lower thirds can remain visible until the operator clears or replaces them.

## 10. Event / Media system

### Automatic event playback

Broadcast Settings contains one checkbox: **Enable automatic event playback**.

- Checked by default on first setup.
- Remember the last selection across app and server restarts.
- When enabled, new FOUR, SIX and WICKET scoring events can trigger the assigned animation automatically, including newly received synced events.
- When unchecked, scoring does not trigger automatic animations; operators may still use manual Play/Replay.
- Trigger each genuinely new event once only. Reconnect, snapshot refresh, source reload, app restart, historical match selection, or returning to the current match must not replay it.
- If Undo removes the scoring event that triggered an animation, stop that animation immediately. An unrelated Undo must not stop another event's animation.

If an event occurs while another event animation is playing, the new event replaces the current event graphic immediately; do not build an event queue.

### Event timing and controls

- New media assignments default to a 5-second on-air display duration.
- Display duration is configurable per event and always wins: hide the graphic when the timer expires even if its media is still playing.
- Configure Play once or Loop separately for each event's assigned media.
- Event animations use shared default position/size with optional per-event overrides.
- Three custom slots exist: Custom Event 1, Custom Event 2, Custom Event 3. Each is renameable and has independent media/playback settings.
- Custom events never modify the match score.
- The Manager has separate **Preview**, **Play On Air**, and **Replay** controls. Preview is manager-only and must not change the live output; Play On Air and Replay begin immediately without a confirmation dialog.

### Supported media formats

The Build 41–45 implementation supports local uploads of PNG/JPG, animated GIF, animated WebP, APNG, MP4 and WebM, up to 50 MB per file. The library stores each asset once in application-data storage and provides categories FOUR, SIX, WICKET, Custom Events, Team Logos and Sponsors. Search by name/category/assigned slot; move assets between categories; assign one asset to multiple event slots; detect identical content by SHA-256; skip a duplicate or update the existing entry; and replace the file at an existing asset URL so assigned event slots continue using the replacement. Existing Build 41 media files are migrated into the catalog on first start. The Browser Manager and Flutter manager both expose the reusable library. AVI is rejected with conversion guidance to MP4 (H.264). The server validates the file signature, stores media in the user's application-data directory outside the project, serves it to the transparent browser output, and persists per-slot assignments. The on-air timer overrides video duration; video may optionally loop until the timer expires. AVI is rejected because browser-source AVI playback is not reliable; convert it to MP4 (H.264).

The native Broadcast Manager includes a media-settings panel, image preview, event duration, loop setting and three renameable custom slots. The browser Manager has its own upload, preview, save, clear and Play On Air/Replay controls. Upload requires the operator to start Broadcasting explicitly; opening the panel does not start the server or put graphics on air.

The reusable media library now supports search, category filters, shared assignments, SHA-256 duplicate detection, same-extension replacement, and Build 50 confirmation-gated deletion. Deletion first returns the media name and all assigned event slots without changing state; after confirmation, the server rechecks the slot list, deletes the asset, and clears only those media assignments while retaining custom names, durations, and loop settings. Cancelling has no effect, and a stale confirmation is refused. Multi-file/drag-and-drop imports, more deletion failure recovery testing, video playback verification, and end-to-end OBS/vMix checks remain outstanding. Unsupported/corrupt files are rejected with a useful message.

## 11. Media library and team logos

The local media library is reusable; upload an asset once and assign it to multiple events without duplicating file content. Initial categories:

- FOUR
- SIX
- WICKET
- Custom Events
- Team Logos
- Sponsors

Provide searchable previews. Support drag-and-drop and Browse Files, including multi-file uploads.

During import:

- Suggest categories from filenames and let the operator confirm/change them.
- Allow bulk category assignment and individual edits.
- Detect identical content, not only identical filenames, and ask whether to skip or replace an existing asset.
- Replacing an asset preserves its event assignments, per-event duration, Play once/Loop mode, and position overrides. Every assignment to that asset uses the new file.
- Before deleting an asset in use, list all affected event assignments and request confirmation. If confirmed, delete the asset and clear those assignments; cancelling changes nothing.
- Do not delete files or assignments silently.

Team logos first reuse available app/team logos where integration is possible. Broadcast Settings provides upload, replace and management controls for logos unavailable from the app.

## 12. Broadcast Manager controls and safeguards

Keep quick on-air controls separate from the detailed collapsible Layout Editor. The editor remembers its expanded/minimized state.

Main on-air controls:

- Compact Scorecard: show/hide.
- Ticker: show/hide and select playlist.
- Lower Third: show, clear or edit.
- Event / Media: Preview, Play On Air and Replay.
- Full-screen Scorecard: choose view and return to compact layout.
- Clear controls: clear selected graphic or take all graphics off air.

Use separate controls for clearing one layer and taking all graphics off air. **Take all graphics off air** must ask for confirmation. When confirmed, hide overlays without deleting configuration, layouts, media, themes, match data or the current workspace.

On starting the server, begin clean: all graphics hidden. Keep saved layouts/settings, but require the operator to enable graphics for the new session. Do not replay previous event animations.

## 13. Match switching while on air

If the operator chooses a different match while broadcasting:

1. Keep the current match on air until the operator confirms switching.
2. On confirmation, preserve current layout and overlay visibility.
3. Update scorecard and automatic match-information data to the new match.
4. Clear old event animations and lower thirds.
5. Preserve the manual ticker playlist and sponsor messages.
6. Never replay historical scoring events from the target match.
7. Keep the selected innings behavior explicit; do not unexpectedly reset a manually selected historical innings without the operator changing it.

Broadcast target selection must not create a match or change the score. Show match identity clearly so the operator knows which match is on air.

## 14. Architecture and persistence

- Use one application-level owner for the server and broadcast coordinator.
- Server construction/lifecycle must not be tied to ordinary snapshot notifications; scoring changes must not recreate the server.
- The browser Manager and native Broadcast UI are clients of the same authoritative broadcast state.
- Use existing scoring data and calculation paths for all statistics.
- Persist user preferences locally: automatic event playback checkbox, editor expanded/minimized state, current workspace, named presets, per-layout appearance/visibility/ordering, ticker playlists, lower-third templates, media assignments, per-event timing/mode/geometry and themes.
- Export only operator-selected assets/configuration. Never include credentials or the private database.
- Keep the default server loopback-only; no LAN remote control unless introduced later as an explicit setting with a clear warning.

## 15. Implementation phases

Recommended order; preserve stable scoring/sync behavior throughout:

1. **Baseline verification:** pull the feature branch, run analyzer/tests and Windows build; establish current failures before implementation.
2. **State/data contracts:** define persisted preferences and stable event identity/revision so sync and Undo never replay historical triggers.
3. **Layer model/editor:** layer selector, visibility, lock, ordering, minimized state, real previews, workspace/preset save behavior and per-layout configuration.
4. **Scorecards:** Minimal/Detailed/Full broadcast bar; complete read-only batting/bowling data; combined stacked view; Playing XI single/both modes; current/historical innings selection.
5. **Ticker/lower thirds:** playlists, configurable auto summaries, templates, trigger settings, durations and transitions.
6. **Media library:** local assets, supported-format preview, upload/drop, categories/search, duplicate/replace/delete safeguards, logo management and reusable assignments.
7. **Event playback reliability:** automatic opt-in persistence, manual Preview/Play/Replay, per-event options, Undo cancellation, sync deduplication and no historical replay.
8. **Native windows/lifecycle:** prove the supported two-window approach and implement startup, close prompts, focus/reopen and one shared service ownership.
9. **Portable setup:** selective export/import of layouts, themes, logos and media assets.
10. **Visual/runtime validation:** realistic Full broadcast bar; transparent Full HD/4K outputs; OBS/vMix integration; end-to-end Windows/Android sync/Undo/switch tests.
11. Update this README with actual implementation evidence; do not mark a phase complete solely because code was committed.

## 16. Acceptance checklist

### Build, runtime and output
- [ ] Analyzer and tests pass on the user's pinned Flutter toolchain.
- [ ] Windows release build succeeds.
- [ ] Scorer and Broadcast open as separate native windows.
- [ ] Server is stopped on app launch and starts only after Start Broadcasting.
- [ ] Exactly one shared server and SyncWorker exist.
- [ ] Closing/reopening a window follows the specified prompts and never makes duplicate services.
- [ ] Only the two intended operator-facing URLs are shown and both match the real bound port.
- [ ] Single transparent Browser Source works at 1920×1080 and 3840×2160.

### Layout and scorecards
- [ ] Collapsible editor state persists; full-screen layers do not block other layer selection.
- [ ] Visibility, lock, ordering, drag/resize and numeric geometry all work.
- [ ] Workspace autosaves; named presets update only on explicit save/update.
- [ ] Switching preset offers update/keep-workspace/discard choices.
- [ ] Compact Scorecard defaults above the bottom ticker and supports Minimal/Detailed/Full broadcast bar with per-style geometry.
- [ ] Full-screen combined scorecard is stacked Batting then Bowling and fits without scrolling.
- [ ] Batting/Bowling table vs TV style, opacity, innings selection and compact visibility persist per layout.
- [ ] Playing XI supports one or both teams, no photos, and captain/wicketkeeper indicators.

### Match data, sync and event playback
- [ ] Score, wickets, extras, batter/bowler stats, target and recent deliveries reflect the authoritative scorer.
- [ ] Android-synced runs, wickets, undo and match updates refresh output accurately.
- [ ] A new FOUR/SIX/WICKET triggers once only when automatic playback is enabled.
- [ ] Unchecking auto-play leaves manual Play/Replay available.
- [ ] Restart, sync refresh, history selection and match switching never replay old events.
- [ ] Undoing the triggering event immediately stops its animation; unrelated Undo does not.
- [ ] Event display duration always takes precedence over media length/loop.

### Ticker, lower thirds and media
- [ ] Manual and automatic ticker sources work; playlists support order, duration, Previous/Next and loop/stop behavior.
- [ ] Automatic ticker summary types are selectable and order/duration configurable.
- [ ] Lower-third triggers are individually configurable and placeholders use real match data.
- [ ] New automatic lower thirds replace the previous automatic lower third.
- [ ] Media upload, preview, format handling, categorization, duplicate detection, replacement and deletion safeguards work.
- [ ] A shared asset can be assigned to multiple events; replacement preserves settings.
- [ ] Export/import includes only selected categories and selected media are portable to another PC.
- [ ] Take all graphics off air requires confirmation and does not delete configuration.

### Match switching
- [ ] Switching matches prompts before changing the on-air match.
- [ ] Layout/visibility and manual ticker playlist survive a confirmed switch.
- [ ] Scorecard/automatic ticker update to the new match, old event/lower-third graphics clear, and no historical events replay.

## 17. Local verification commands

From the feature branch on Windows:

- git fetch origin
- git pull --ff-only origin feature/windows-broadcast-output
- flutter analyze
- flutter test
- flutter build windows --release

The current branch is Build 51. Build 51 fixes the media-delete pending-file path interpolation lint reported by the first analyzer run; full CI validation for this exact commit is pending. Build 49 added batched-sync event detection so earlier FOUR/SIX/WICKET events are not missed if a sync refresh also includes a later ordinary delivery. The reusable media library supports category filtering, search, assignments across multiple slots, SHA-256 duplicate detection, metadata/category updates and same-extension replacement while retaining asset URLs and links. Build 50 adds confirmation-gated deletion in both the native and browser managers: preview the assigned-slot list first, confirm the exact list, and refuse deletion if assignments changed. Confirmed deletion removes the catalog entry/file and clears the affected media assignments while preserving slot names, duration and loop settings. The tests now cover non-mutating preview, stale-confirmation rejection, and deletion cleanup. Automatic playback remains presentation-only; GIF playback was manually verified, while MP4/WebM playback still needs a real test. Multi-file/drag-and-drop import, animated logo/team integrations, advanced ticker/lower-third features and native multi-window lifecycle remain outstanding. CI validation, Windows release-build and OBS/vMix verification are required.

## Change log

- **Build 24 baseline:** combined output and initial layout editor scaffold exist; nine reported analyzer infos were addressed in that code change.
- **Build 25 first UI pass:** bottom scorebar/ticker defaults, realistic miniature layer previews, collapsed-by-default remembered editor state, explicit layer selection chips, legacy default-layout migration, and explicit server start were added.
- **Build 26 compile fix:** added the missing closing bracket for the layout editor outer children list.
- **Build 27 broadcast composition/control pass:** added a styled horizontal live scorebar and compact on-air controls with confirmation before Take All Off Air. Fresh local analyzer/test/Windows-build verification is still required.
- **Build 29 scorebar and settings usability:** defaulted the scorebar to 8% canvas height above the ticker and added one remembered collapse/expand control for broadcast settings.
- **Build 30 compact typography and server panel:** began sizing fonts/chips relative to the selected scorebar height; the Local broadcast server details can be minimized independently without hiding Start/Stop or the running status.
- **Build 31 short-bar fit:** removed the narrow-viewport padding override and made the entire scorebar typography scale with bar height, avoiding clipping at compact sizes.
- **Build 32 test correction:** removed an obsolete test expectation for the pre-fix `3cqw` padding so the assertion matches the current `.85cqw` CSS rule.
- **Build 33 typography revision:** increases score, batter, bowler and delivery typography relative to the scorebar's own height while preserving the selected 8% overall geometry. This is a visual refinement and must be confirmed in the operator's OBS preview.
- **Build 34 scorecard styles:** added a persistent Minimal / Detailed / Full broadcast bar selector to the Flutter layout editor and a live selector to the browser manager. The shared broadcast state carries the style, and the combined output renders distinct layouts; Full broadcast bar remains the default. Style changes never write scoring data.
- **Build 35 analyzer cleanup:** uses `initialValue` for the Flutter scorecard style dropdown and removes unnecessary quote escapes from the broadcast-output tests.
- **Build 36 test correction:** moves assertions for the scorecard-style selector and its route from `/broadcast/output` to `/broadcast/manage`, the page that actually owns the controls.
- **Build 37 per-style geometry:** Minimal, Detailed and Full broadcast bar each retain their own scorebar rectangle across style switches; style geometry is serialized in output state and persisted with the current layout workspace.
- **Build 39 layer controls:** workspace visibility, lock states and z-order are serialized, persisted, applied to output, and edited in the layout editor.
- **Build 40 full-workspace presets:** saved/imported/exported presets capture all layer rectangles, per-style scorebar geometry, scorecard style, per-layer visibility/locks and z-order. Preset switching prompts before replacing unsaved workspace edits, the active preset name persists, and legacy geometry-only exports remain supported.
- **Build 41 event media assignment:** added local upload/serving for PNG, JPG, GIF, WebP, APNG, MP4 and WebM (50 MB cap), simple file-signature validation, persistent per-slot media settings, per-event display duration/loop settings, image/video support in the transparent combined output, and three renameable custom event slots. Native and browser managers receive Choose & Upload, Preview, Save/Clear Assignment, Play On Air and Replay controls. AVI receives explicit conversion guidance. Upload is gated on the operator explicitly starting Broadcasting. This implementation is initial media assignment only; the full searchable/reusable asset library and automatic event/Undo playback behavior are still future work. Local Flutter analyzer, tests, Windows release build and OBS/vMix validation remain required.
- **Build 42 media plumbing follow-up:** repair event-media constructor/serving method boundaries, keep test uploads in a temporary directory, ensure Clear Assignment removes stored media fields, and preserve unsaved browser-manager slot edits while polling.
- **Build 43 analyzer cleanup:** resolve lint infos in event media UI/server and make existing mutable layer maps final. CI validation is pending.
- **Build 44 media-library core:** add the persistent reusable asset catalog, filename-based category suggestions, SHA-256 duplicate detection, existing-asset migration, category updates and replacement at a stable URL.
- **Build 45 media-library controls:** integrate searchable/filterable asset selection into the Flutter and browser managers, allow reuse across multiple event slots, expose category changes and replacement actions, prompt before merging identical assets, and test duplicate handling, category changes, replacement assignment preservation, and restart persistence.
- **Build 46 automatic event playback:** read event identities from the existing broadcast snapshot, trigger assigned FOUR/SIX/WICKET graphics only for newly observed eligible live events, persist an enable/disable setting across server restarts, suppress replay on initial snapshots/refreshes/historical selection, and stop an automatic animation when Undo removes its exact triggering ball. Added coordinator, snapshot-builder and server persistence tests. Manual GIF playback is verified; MP4/WebM and Windows release behavior still need local verification.
- **Build 47 Web compatibility follow-up:** replace most HTTP status constants in the Flutter manager media-library screen with numeric status-code comparisons, avoiding a `dart:io` dependency in the Flutter Web UI.
- **Build 48 Web compatibility cleanup:** replace the last remaining category-handler HTTP status constant and advance the build number.
- **Build 49 batched sync event detection:** carry ordered FOUR/SIX/WICKET candidates through broadcast snapshots and play newly received eligible candidates even when a sync refresh also includes later ordinary deliveries. Added coverage for a boundary earlier in a batched refresh.
- **Build 50 safe media deletion:** native and browser media-library cards offer Delete asset. The server returns a non-mutating assignment preview, requires explicit confirmation with the exact assigned-slot list, refuses stale confirmations, and clears only media assignments after confirmed deletion. Added API-level tests for preview-without-side-effects, stale confirmation rejection, file/catalog removal, and retained custom slot settings.
- **Build 51 lint follow-up:** use interpolation for the pending-delete filename and advance the app build number. Full analyzer, tests, Web/APK CI and Windows/OBS verification remain pending.
- **Build 38 geometry validation:** validates restored style rectangles with null-safe checks and refreshes the Flutter style dropdown if selection changes through the browser manager.
- **Accepted design consolidation:** recorded the agreed scorecard styles/layouts, ticker playlists, lower-third triggers/templates, event/media behavior, window lifecycle, safety prompts, match switching, and acceptance checks. Most of these are requirements, not claims that the full feature has already been implemented.
