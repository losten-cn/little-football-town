# Architecture Traceability Index

Last Updated: 2026-07-01  
Engine: Godot 4.6  
Mode: `/architecture-review full`  
Review Report: `docs/architecture/architecture-review-2026-07-01.md`

## Coverage Summary

- Total requirements: 201
- Covered: 131 (65.2%)
- Partial: 70
- Gaps: 0

## Source of Truth

- Review report: `docs/architecture/architecture-review-2026-07-01.md`
- Full RTM: `docs/architecture/requirements-traceability.md`
- Architecture overview: `docs/architecture/architecture.md`
- TR registry: `docs/architecture/tr-registry.yaml`

## Current Verdict

- Status: CONCERNS
- Interpretation: true `NO ADR` gaps remain closed, and the prior source-of-truth blockers have been resolved through accepted ADR and first-layer architecture convergence. Remaining concerns now center on partial Presentation API boundaries, sparse story/test linkage for several accepted systems, and implementation follow-through for authority-reference wiring and runtime restore behavior.

## Full Matrix

This index tracks row-level architecture coverage by system. Requirement-level story/test chains live in `docs/architecture/requirements-traceability.md`.

| System / TR range | GDD | ADR Coverage | Status | Notes |
|---|---|---|---|---|
| `TR-gameconcept-001`–`TR-gameconcept-007` | `design/gdd/game-concept.md` | ADR-0002, ADR-0005, ADR-0006, ADR-0007, ADR-0011 | Covered | Concept requirements are distributed across core loop, time, player, match, economy, and recognition architecture. |
| `TR-balance-001`–`TR-balance-014` | `design/gdd/balance-system.md` | ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0008 | Covered | Formula/config support exists; a diagnostics/telemetry ADR is optional future work, not a blocker. |
| `TR-save-001`–`TR-save-014` | `design/gdd/save-and-load-system.md` | ADR-0003, ADR-0010 | Covered | Skill/Trait-specific durable-state restore requirements still need story coverage in RTM. |
| `TR-time-001`–`TR-time-008` | `design/gdd/time-and-season-progression-system.md` | ADR-0002, ADR-0003 | Covered | Covered by TimeManager/EventBus and Save/Load persistence. |
| `TR-playerdev-001`–`TR-playerdev-011` | `design/gdd/player-development-system.md` | ADR-0005, ADR-0007, ADR-0008, ADR-0003 | Covered | Facility multiplier contract is now canonicalized; implementation must still follow injected/stable authority-reference wiring. |
| `TR-match-001`–`TR-match-017` | `design/gdd/match-competition-system.md` | ADR-0006, ADR-0005, ADR-0008, ADR-0007, ADR-0009, ADR-0010 | Covered | `match_completed` canonical envelope remains unified; `TR-match-016`–`017` still need story coverage. |
| `TR-economy-001`–`TR-economy-013` | `design/gdd/economy-management-system.md` | ADR-0007, ADR-0004, ADR-0003 | Covered | Covered by EconomyManager transaction framework and persistence; post-match reward implementation should continue consuming `settlement_id` for idempotency. |
| `TR-town-001`–`TR-town-019` | `design/gdd/town-building-system.md` | ADR-0008, ADR-0007, ADR-0004, ADR-0003 | Covered | Covered by town grid/facility architecture and economy/config dependencies; public cross-system surface is now the canonical MVP three-query interface. |
| `TR-skill-001`–`TR-skill-008` | `design/gdd/skill-and-trait-system.md` | ADR-0010, ADR-0003, ADR-0006 | Covered | Story/test linkage not yet scheduled. |
| `TR-league-001`–`TR-league-014` | `design/gdd/league-competition-structure-system.md` | ADR-0009, ADR-0006, ADR-0007, ADR-0002 | Covered | Story/test linkage remains sparse for league-specific rows. |
| `TR-mainui-001`–`TR-mainui-010` | `design/gdd/main-loop-ui-framework.md` | ADR-0001, ADR-0002, ADR-0010 | Partial | Needs feature-specific UI API boundary depth. |
| `TR-playerui-001`–`TR-playerui-011` | `design/gdd/player-management-ui.md` | ADR-0001, ADR-0005, ADR-0010 | Partial | Needs read-model, feedback ack, and detail-boundary decisions. |
| `TR-matchui-001`–`TR-matchui-011` | `design/gdd/match-performance-ui.md` | ADR-0001, ADR-0006, ADR-0009, ADR-0010 | Partial | Needs live/result queue, snapshot, and no-recompute UI boundary decisions. |
| `TR-reputation-001`–`TR-reputation-006` | `design/gdd/reputation-and-achievement-system.md` | ADR-0011, ADR-0003 | Covered | Story/test linkage not yet scheduled. |
| `TR-onboard-001`–`TR-onboard-010` | `design/gdd/onboarding-system.md` | ADR-0001, ADR-0002, ADR-0003 | Partial | Needs persistence fields, anchor fallback, and first-match guidance detail. |
| `TR-random-001`–`TR-random-008` | `design/gdd/random-event-system.md` | ADR-0012 Accepted | Partial | ADR exists and stable-key wording aligns with GDD/TR registry; remaining gap is story/test coverage and implementation follow-through. |
| `TR-audio-001`–`TR-audio-006` | `design/gdd/audio-system.md` | ADR-0013 Accepted | Partial | ADR exists; remaining gap is story/test coverage plus implementation/runtime verification. |
| `TR-townui-001`–`TR-townui-007` | `design/gdd/town-management-ui.md` | ADR-0001, ADR-0008, ADR-0007, ADR-0010 | Partial | Needs construction confirmation sequencing and UI-only pressure-state boundary. |
| `TR-tutorial-001`–`TR-tutorial-007` | `design/gdd/tutorial-and-hint-system.md` | ADR-0001, ADR-0002, ADR-0003, ADR-0010 | Partial | Needs hint durable state, cooldown, preferences, help index, and SaveManager boundary. |

## Known Gaps

None — no current requirement is completely without ADR coverage.

## Partial / Follow-up

1. Presentation API Boundaries should be extended before deeper UI, onboarding, town UI, and tutorial/hint implementation.
2. Accepted-but-unscheduled systems still need implementation stories/tests: SkillTrait, ReputationAchievement, Random Event, Audio, Town UI, and Tutorial / Hint.
3. Registered direct-call authority contracts now have a stable access rule; implementation must verify gameplay-root injection or scene-owned service container wiring.
4. Audio runtime restore, bus validation, and semantic UI-event consumption remain implementation follow-through items.
5. Random Event stable-window, idempotency, and restore-path rules remain implementation follow-through items.

## Superseded Requirements

None identified. No TR IDs were renumbered or deleted.

## Maintenance Rule

This file is a compact architecture coverage index. Use `docs/architecture/requirements-traceability.md` for story/test-level tracing.
