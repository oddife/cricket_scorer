# Full Handover — Cricket Scorer Windows Broadcast Output

**Last updated:** 2026-10-24  
**Repository:** https://github.com/oddife/cricket_scorer  
**Working branch:** feature/windows-broadcast-output  
**Package version on branch:** 1.0.1+55 (Build 55)  
**Local Windows checkout:** C:\Projects\cricket_scorer

This handover is for continuing the isolated Windows broadcast-output work in a new chat. Read it together with the root README and the authoritative broadcast specification.

## 1. Start here

- Root project README: https://github.com/oddife/cricket_scorer/blob/feature/windows-broadcast-output/README.md
- Broadcast specification and acceptance checklist: https://github.com/oddife/cricket_scorer/blob/feature/windows-broadcast-output/docs/windows-broadcast/README.md
- This handover: https://github.com/oddife/cricket_scorer/blob/feature/windows-broadcast-output/docs/windows-broadcast/HANDOVER.md
- Feature branch: https://github.com/oddife/cricket_scorer/tree/feature/windows-broadcast-output
- GitHub Actions: https://github.com/oddife/cricket_scorer/actions

### Current truth / don't overstate it

1. The branch package version is **1.0.1+55**.
2. The user confirmed **GIF upload/playback works**.
3. **MP4/WebM playback has not been tested** because the user had no sample video.
4. The last fully documented green CI result is Build 53. The first Build 55 CI attempt failed in flutter analyze because three new full-screen model tests used relative imports from test/ into lib/. Those imports were changed to package imports in test-only commits. Follow-up CI runs were in progress when this handover was written; check the Actions page for the latest result before claiming Build 55 is green.
5. Windows release compilation and final OBS/vMix visual checks have not been confirmed in this session. CI's Web and Android successes do not prove the Windows runner or browser-source playback.
6. Builds 54–55 added standalone full-screen geometry/settings models and tests, but the new model has **not yet been integrated end-to-end**. The live coordinator and UI still use the older map-based full-screen setting fields. Do not describe per-view geometry and opacity as complete until model, persistence, controls, and output rendering are wired and tested.

## 2. Branch and safe local workflow

Use PowerShell on Windows. First inspect your current state:

    cd C:\Projects\cricket_scorer
    git status --short
    git branch --show-current

If there are local modifications, preserve and inspect them before switching branches or pulling. In particular, do not discard local changes to pubspec.lock, generated Drift files, or other files just to make a pull succeed.

If the working tree is clean and the branch is already the broadcast branch:

    git fetch origin
    git switch feature/windows-broadcast-output
    git pull --ff-only origin feature/windows-broadcast-output

Then run the validation steps individually, so each failure is easy to diagnose:

    flutter pub get
    flutter analyze
    flutter test
    flutter build windows --release

Windows executable expected after a successful release build:

    .\build\windows\x64\runner\Release\cricket_scorer.exe

The latest test-only import fixes do not change application code, so Build 55 remains +55. For future app-affecting changes under lib/, dependencies, assets, or platform build files, advance the +buildNumber in pubspec.yaml in the same commit. Documentation-only/test-only edits do not normally require a build-number increment.

## 3. Non-negotiable architecture constraints

- Keep all broadcast work on feature/windows-broadcast-output. Do not work on or merge into main as part of this task.
- Keep tested scoring and sync logic authoritative. Broadcast features are presentation-only: consume the existing snapshot, innings data, match/player records, and event identities.
- Do not add a second scoring engine, write ball events from broadcast UI, or introduce a second SyncWorker.
- Do not clear app data, reset SQLite, or wipe local databases while testing this feature.
- The broadcast HTTP server is local/loopback-only and should start only when the operator explicitly presses Start Broadcasting. It normally tries port 3113 and can fall back through 3118; always use the actual URL shown by the app.
- A running broadcast server is required before changing/saving full-screen scorecard settings. The UI added a guard because changes made while the server was stopped could otherwise be overwritten when the saved state was restored.
- Distinguish an implemented-and-tested feature from a model/test scaffold and from requirements that are still only specified in docs.

## 4. Current implemented feature inventory

### Compact combined browser output and layout

- Combined transparent browser output for OBS/vMix, with separate manager and output URLs.
- Compact scorecard styles: Minimal, Detailed, and Full broadcast bar.
- Full broadcast bar default geometry is approximately X 3%, Y 82.5%, width 94%, height 8%, positioned above the ticker. Ticker default is X 3%, Y 91.5%, width 94%, height 6.5%.
- Each compact scorecard style has its own geometry.
- Layers include scorecard, ticker, lower third, and event/last-ball overlay, with visibility/lock controls and z-order.
- Saved workspace presets capture layout geometry, scorecard style, all style-specific scorebar geometries, layer visibility/locks, and stacking order. Preset switching protects unsaved edits and offers update/keep/discard paths. Legacy geometry-only presets and version-1 exports remain supported.
- The manager exposes clear controls separately from taking all graphics off air. Respect existing confirmation/safety behavior.

### Media library and event playback

The local media system supports PNG, JPG/JPEG, GIF, WebP, APNG, MP4, and WebM; the server currently caps each upload at 50 MB. AVI is rejected with conversion guidance because browser-source AVI support is unreliable. Files are stored in local application data, not in the repository. Do not commit uploaded media files or credentials.

Implemented through Builds 44–50:

- Reusable asset catalog and category suggestions from filenames.
- Categories include FOUR, SIX, WICKET, Custom Events, Team Logos, and Sponsors.
- Search/filter and reusable assignments are available in native and browser manager flows.
- SHA-256 duplicate detection, category changes, stable URL replacement behavior, and assignment-preserving replacement.
- Deletion preview lists assigned slots; explicit confirmation is required. Stale confirmations are rejected; only media assignments are cleared after confirmed deletion.
- Three renameable custom event slots exist: Custom Event 1, Custom Event 2, Custom Event 3. Custom events do not change the match score.
- Each assigned event has its own media, duration and loop setting. The on-air timer wins even if video is still playing/looping.
- Automatic FOUR/SIX/WICKET playback has an enable/disable setting. The logic is designed to detect new event identities from live/scoring snapshots, handle batched sync refreshes, avoid replay on initial snapshot/history selection/reconnect, and stop an animation when Undo removes the exact delivery that triggered it. An unrelated Undo must not stop an unrelated animation.
- Manual Preview / Play On Air / Replay controls are present; preview should not put a graphic on air.

**Manual result:** the user tested a GIF and confirmed upload/playback is working. No sample MP4/WebM was available, so video playback remains unknown. Do not mark video formats fully verified until tested in the intended desktop browser-source environment.

### Full-screen scorecards

Builds 52–53 added the first functional pass:

- Views: Combined Batting & Bowling, Batting, Bowling, Playing XI.
- Styles: Traditional scorecard table and TV Broadcast design.
- Transparent or opaque background.
- Optional compact scorecard alongside the full-screen view.
- Playing XI can show one team or both teams; single-team mode chooses Team A or Team B.
- Uses existing innings and match-player data; there is no new scoring engine.
- The output currently follows the current broadcast innings. Historical-innings pinning is outstanding.
- Some desired table metadata (such as maiden overs, captain and wicketkeeper indicators) may be unavailable in the current snapshot/source records.
- A guard requires the local broadcast server to be running before settings are modified.

Builds 54–55 added these standalone model files and unit tests:

- lib/features/broadcast/models/broadcast_full_screen_geometry.dart
- lib/features/broadcast/models/broadcast_full_screen_settings.dart
- test/features/broadcast/broadcast_full_screen_geometry_test.dart
- test/features/broadcast/broadcast_full_screen_settings_test.dart

The geometry model validates finite numeric coordinates, positive width/height, and rectangles within the normalized 0–100% canvas. The settings model supports JSON serialization and defaults for enabled state, view, style, transparency, compact-scorecard visibility, Playing XI mode/team, opacity (10–100%), and per-view geometries.

**Critical remaining integration:** these newly added typed models are not yet connected to the coordinator's existing _fullScreenScorecardSettings map, the native/browser manager forms, saved workspace, state API, or output CSS. The existing UI still uses the older fields and does not yet expose fully working per-view geometry/opacity. The next implementation task should wire the typed model through all these layers and preserve backward compatibility for existing saved settings.

## 5. Recent CI / validation status

- Build 53 CI passed the build-number check, dependency resolution, Drift code generation, flutter analyze, flutter test, Flutter Web release build and Android APK release build.
- The first Build 55 attempt reached flutter analyze and failed on three lint infos for relative imports from lib/ in the new full-screen model test files. The imports have been changed to package imports.
- Follow-up GitHub Actions runs for those import fixes and README updates were still in progress at handover time. Re-check https://github.com/oddife/cricket_scorer/actions and cite the exact run/result in any continuation.
- Windows release compilation is not part of the existing CI workflow and must be run locally.
- GIF upload/playback: manually confirmed by the user.
- MP4/WebM playback, Windows output build, OBS/vMix fit/transparency, restart persistence of the latest full-screen model integration, and 1920×1080 / 3840×2160 layout quality: not yet verified.

## 6. Immediate next actions (recommended)

1. **Confirm CI after the test import fixes.** If flutter analyze still fails, fix all reported issues and rerun. Do not report Build 55 as green until the run actually completes.
2. **Run local Windows validation:** safely pull the branch, then flutter pub get, flutter analyze, flutter test, flutter build windows --release, and launch the executable.
3. **Integrate the new typed full-screen model.** Replace or adapt the older untyped map in the coordinator with BroadcastFullScreenSettings; migrate old map-based values safely; persist it through workspace/preset state and local server start/stop; expose per-view geometry and opacity controls; serialize it via the state API; apply it in the browser output CSS. Keep compact and full-screen layer visibility rules coherent.
4. **Add tests before visual tuning.** Cover JSON legacy/current round trips, invalid geometry, state coordinator mutations/restoration, persistence across server restart, API state serialization, and HTML/output behavior for all four views.
5. **Verify full-screen visuals.** At 1920×1080 first, then 3840×2160. Check batting/bowling row fit, selected Playing XI behavior, both background modes, opacity, layout positioning, overlay stacking, and compact-scorecard coexistence.
6. **Test a real short MP4/WebM clip** in the transparent output and OBS/vMix browser source. Confirm the clip loops only when enabled and always stops when the event timer expires. Keep the current successful GIF behavior as a regression test.
7. Continue with multi-file/drag-and-drop importing, advanced ticker playlists/static-vs-scrolling modes, automatic ticker summaries, lower-third templates/triggers/animations, and native multi-window lifecycle only after the baseline remains green.

## 7. Manual smoke-test checklist for this branch

- [ ] Start Broadcasting explicitly; confirm correct URL/port and running status.
- [ ] Confirm Combined output remains transparent and the compact bar stays at the default 94% × 8% size above the ticker.
- [ ] Switch Minimal / Detailed / Full broadcast bar and confirm each geometry is retained.
- [ ] Toggle/lock/reorder layers and save a preset; restart and confirm the workspace and selected preset restore.
- [ ] Upload a GIF, preview without going on air, assign it to FOUR or a custom slot, and Play On Air.
- [ ] Confirm event display duration hides the graphic even when the GIF/video continues or is looping.
- [ ] Upload/assign a short MP4 or WebM and confirm actual playback in OBS/vMix. Record the tested codec/container and result.
- [ ] Confirm Custom Event 1, 2 and 3 retain distinct names, media, duration and loop settings.
- [ ] Confirm same-event Undo stops only the matching automatic event animation.
- [ ] Confirm a batch of sync-received scoring events does not replay historical events more than once.
- [ ] Use media replacement and verify assignments/settings persist.
- [ ] Try deleting an assigned asset; verify preview is non-mutating, confirmation lists affected slots, cancellation changes nothing, and stale confirmation is rejected.
- [ ] Confirm full-screen view settings require the server to be running; verify current view/style and settings persist.
- [ ] Verify full-screen data reflects the current innings and Playing XI selection.
- [ ] Confirm existing scoring, undo, match deletion and sync behavior remains unchanged.
- [ ] Run the full Windows test/build commands and inspect the output manually at Full HD and 4K.

## 8. API/page endpoints worth knowing

The current local server exposes these pages on the actual base URL shown by the app:

- /broadcast/manage — browser manager.
- /broadcast/output — combined transparent OBS/vMix output.
- /broadcast/scorecard — scorecard-only output.
- /broadcast/ticker — ticker-only output.
- /broadcast/lower-third — lower-third-only output.
- /broadcast/last-ball — event/last-ball-only output.
- /api/v1/broadcast/state — shared broadcast state JSON.
- /api/v1/broadcast/media/upload — upload endpoint for supported media.
- /broadcast/media/<asset filename> — local media serving route.

The server is intentionally loopback-only. Do not expose control endpoints over the LAN or internet as part of this handover.

## 9. How to continue in the next chat

Start with this request:

Continue the Cricket Scorer Windows broadcast feature from the full handover. Repo is oddife/cricket_scorer, branch feature/windows-broadcast-output, version 1.0.1+55. First check the newest GitHub Actions result for the package-import lint fix; don't touch main or scoring/sync. Then integrate the standalone BroadcastFullScreenSettings / BroadcastFullScreenGeometry models into coordinator persistence, native/browser controls, state API, and output CSS with tests. GIF is confirmed working; MP4/WebM is untested. Preserve local changes and never reset the scoring database.
