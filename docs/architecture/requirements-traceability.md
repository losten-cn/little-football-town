# Architecture Requirements Traceability Matrix

> **Generated**: 2026-05-19
> **Source Registry**: `docs/architecture/tr-registry.yaml`
> **Architecture Review**: `docs/architecture/architecture-review-2026-05-17.md`
> **Status**: 0 Foundation gaps / 0 Core gaps / 2 partial coverage items

## Gate Summary

| Layer | Total Requirements | Covered | Partial / N/A | Gaps |
|-------|--------------------|---------|---------------|------|
| Foundation | 42 | 36 | 6 | 0 |
| Core | 56 | 54 | 2 | 0 |
| Feature | 14 | 14 | 0 | 0 |
| Presentation | 21 | 4 | 17 | 0 |
| Polish | 10 | 0 | 10 | 0 |
| Total | 143 | 108 | 35 | 0 |

## Foundation Coverage

| Domain | Source GDD | Governing ADR(s) | Coverage |
|--------|------------|------------------|----------|
| Game Concept / Core Loop | `design/gdd/game-concept.md` | `ADR-0001`, `ADR-0002`, `ADR-0005`, `ADR-0006`, `ADR-0007`, `ADR-0008`, `ADR-0009` | Covered |
| Balance / Formula Config | `design/gdd/balance-system.md` | `ADR-0004`, `ADR-0005`, `ADR-0006`, `ADR-0007`, `ADR-0008` | Covered |
| Save / Load | `design/gdd/save-and-load-system.md` | `ADR-0003` | Covered |
| Time / Season Progression | `design/gdd/time-and-season-progression-system.md` | `ADR-0002`, `ADR-0003` | Covered |
| Scene / Screen Navigation | `design/gdd/main-loop-ui-framework.md` | `ADR-0001`, `ADR-0002` | Covered |

## Core Coverage

| Domain | Source GDD | Governing ADR(s) | Coverage |
|--------|------------|------------------|----------|
| Player Development | `design/gdd/player-development-system.md` | `ADR-0005`, `ADR-0007`, `ADR-0008`, `ADR-0003` | Covered |
| Match Competition | `design/gdd/match-competition-system.md` | `ADR-0006`, `ADR-0005`, `ADR-0008`, `ADR-0007`, `ADR-0009` | Covered |
| Economy Management | `design/gdd/economy-management-system.md` | `ADR-0007`, `ADR-0004`, `ADR-0003` | Partial |
| Town Building | `design/gdd/town-building-system.md` | `ADR-0008`, `ADR-0007`, `ADR-0004`, `ADR-0003` | Partial |
| League Competition | `design/gdd/league-competition-structure-system.md` | `ADR-0009`, `ADR-0006`, `ADR-0007`, `ADR-0002` | Covered |

## Partial Coverage Items

| TR-ID | Requirement | Governing ADR | Status | Required Follow-up |
|-------|-------------|---------------|--------|--------------------|
| TR-economy-008 | AP daily recovery formula | `ADR-0007` | Partial | ADR covers settlement but not daily AP regeneration timing detail. Clarify during Economy implementation story or ADR revision. |
| TR-town-013 | Maximum adjacency bonus cap 15.0 | `ADR-0008` | Partial | ADR computes adjacency bonuses but must explicitly enforce the GDD cap before implementation. |

## ADR Implementation Order

1. `ADR-0001` — Scene Management & Autoload Architecture
2. `ADR-0004` — Data-Driven Configuration
3. `ADR-0002` — Event / Signal Architecture + TimeManager
4. `ADR-0003` — Save / Load Persistence
5. `ADR-0005` — Player Data Model
6. `ADR-0006` — Match Simulation Architecture
7. `ADR-0007` — Economy Transaction Framework
8. `ADR-0008` — Town Grid & Facility System
9. `ADR-0009` — League Competition Structure

## Gate Interpretation

- Foundation layer has **zero gaps**.
- Core layer has **zero gaps**.
- The two partial items are not gate blockers, but must become story acceptance criteria before implementation.
- `docs/architecture/tr-registry.yaml` remains the canonical per-requirement registry; this file is the gate-facing traceability summary.
