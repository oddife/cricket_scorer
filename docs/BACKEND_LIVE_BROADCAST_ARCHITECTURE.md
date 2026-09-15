# Backend, Sync & Live Broadcast Architecture

This document records the locked backend direction for Cricket Scorer. It complements `README.md` and must be kept in sync with major backend, synchronization, live-scorecard, and broadcast decisions.

## 1. Architecture Decision

The planned backend is **self-hosted Supabase running in Docker**.

Core services:

- PostgreSQL for central match data
- Supabase Auth for authenticated users
- Supabase Realtime for live match updates
- Supabase API layer for application access
- Supabase Studio for administration

The backend will run on the project's existing Docker infrastructure and can be placed behind Traefik with HTTPS.

## 2. Offline-First Rule

The Flutter scorer must never require internet connectivity to score a match.

Local Drift/SQLite remains the immediate persistence layer for scoring.

Scoring flow:

```text
Score delivery
    ↓
Save BallEvent to Drift immediately
    ↓
Add event to sync queue
    ↓
Internet available?
    ├── No  → keep scoring and keep queue
    └── Yes → upload event
                 ↓
              Backend ACK
                 ↓
          mark event synchronized
```

When connectivity returns, queued events are uploaded without requiring the scorer to recreate or re-enter them.

## 3. BallEvent Remains the Source of Truth

The backend must not become a second scoring engine.

A completed delivery is represented by the same atomic `BallEvent` concept used locally.

Scores, wickets, overs, batter statistics, bowler statistics, strike, targets, and broadcast displays are derived from ball history.

Do not synchronize independent authoritative fields such as only `score`, `wickets`, or `overs` and assume they are sufficient to reconstruct the match.

## 4. Live Scoring

When internet connectivity is available:

```text
Flutter Scorer
      ↓
Local BallEvent
      ↓
Supabase
      ↓
Realtime event
      ↓
Live clients
```

Live clients may include:

- Public web scorecard
- Mobile viewer
- Windows broadcast client
- External scoreboard
- Future tournament displays

A live client should be able to rebuild its displayed state from synchronized match events.

## 5. Permissions

The eventual security model should separate roles.

### Scorer

- Read assigned matches
- Write scoring events
- Perform permitted match-management actions

### Admin

- Manage teams
- Manage players
- Manage matches
- Manage tournaments
- Manage users/settings as permitted

### Public viewer

- Read-only access to published/live matches
- No ability to modify match data

## 6. Live Public Scorecard

The public scorecard will consume the same match data as the scorer.

Example data:

- Current score/wickets
- Overs
- Current batters
- Batter runs/balls
- Current bowler
- Bowler figures
- Current over
- Extras
- Target/required runs
- Match result

No manual refresh should be required while realtime connectivity is available.

## 7. Windows Broadcast Client

Windows will eventually provide a dedicated broadcast/graphics client.

Planned features:

- Live match selection
- Live ticker
- Scorebug
- Lower thirds
- Wicket graphic
- Boundary graphic
- Partnership graphic
- Match-result graphic
- Manual ticker messages
- Team/player branding
- Sponsor graphics

The graphics client consumes live match data rather than maintaining its own scoring database.

## 8. vMix Integration

The preferred initial broadcast integration is browser-based transparent graphics.

```text
Supabase Realtime
       ↓
Windows Broadcast Client
       ↓
HTML/CSS transparent overlay
       ↓
vMix Browser Input
       ↓
Broadcast
```

This keeps the scoring engine independent of vMix while allowing professional live graphics.

OBS integration can be added later using the same browser-output concept.

## 9. Local Network Fallback

A future phase may support a LAN/local broadcast path when internet is unavailable.

The scorer would continue using Drift and could expose match updates over the local network to the Windows broadcast computer.

This is a future capability and must not weaken the primary offline-first architecture.

## 10. Data Synchronization Requirements

The sync layer must eventually provide:

- Stable event identifiers
- Idempotent uploads
- Duplicate-event protection
- Sync status per local event
- Retry after failures
- Ordering protection using match/innings sequence numbers
- Authentication
- Authorization
- Safe reconnect/recovery
- Ability to detect server/client divergence

Conflict handling must be designed around immutable ball events rather than silently overwriting scoring history.

## 11. Planned Backend Data

The central backend is expected to contain relational representations of:

- Users
- Teams
- Players
- Tournaments
- Matches
- Match players
- Innings
- Ball events
- Wicket/event context where required
- Published/live match state or indexes where useful

The exact schema will be designed before implementation. Do not duplicate local Drift tables blindly; define the synchronization contract explicitly.

## 12. Development Order

Backend work should proceed in this order:

1. Define synchronization identifiers and metadata.
2. Define PostgreSQL/Supabase schema.
3. Define authentication and authorization.
4. Implement local sync queue.
5. Implement BallEvent upload/download.
6. Implement idempotency and retry behavior.
7. Implement realtime subscriptions.
8. Implement public live scorecard.
9. Implement Windows broadcast client.
10. Implement vMix browser overlays.
11. Consider LAN fallback.

## 13. Locked Principle

**One match → one source of truth → multiple live clients.**

The scorer, public scorecard, Windows broadcast graphics, and future displays must all derive their match state from the same ball-by-ball event history.

## 14. README Maintenance

Whenever backend, synchronization, realtime, public scorecard, Windows broadcast, or vMix architecture changes, update both this document and the project's main `README.md` so the project handover remains current.
