# Windows Broadcast Output — Design Document

The authoritative and up-to-date broadcast specification, current implementation status, accepted product decisions, and acceptance checklist now live in:

**[docs/windows-broadcast/README.md](windows-broadcast/README.md)**

Please update that README whenever a broadcast requirement changes or an implementation milestone is verified. This file is intentionally a pointer so older design notes do not conflict with the agreed behavior.

The feature remains isolated on **feature/windows-broadcast-output**. Do not modify main or the tested scoring/sync branch as part of broadcast development. The current Build 25 code is a scaffold with the first UI corrections: the combined output, loopback server, state coordinator, and initial geometry editor exist, while many features documented in the authoritative README remain unimplemented and need local Windows verification. Build 25 also moves the compact scorebar to the bottom above the ticker, adds a remembered collapsible editor/layer selector, and requires explicit server start.
