# Requirements Traceability Matrix (RTM)

> Last Updated: 2026-07-01
> Mode: `/architecture-review full`
> Coverage: 48.3% full chain complete (97/201 GDD → ADR → Story → Test)
> Review report: `docs/architecture/architecture-review-2026-07-01.md`
> Architecture index: `docs/architecture/architecture-traceability.md`

## How to read this matrix

| Column | Meaning |
|--------|---------|
| TR-ID | Stable requirement ID from `docs/architecture/tr-registry.yaml`. |
| GDD | Source design document. |
| ADR | Architectural decision governing implementation. |
| Story | Story file that implements this requirement. |
| Test File | Automated test file path stated in the story `## Test Evidence` section. |
| Status | `COVERED`, `MISSING`, `NONE`, `NO STORY`, or `NO ADR`. |

## Coverage Summary

| Status | Count | % |
|--------|------:|---:|
| COVERED — full chain complete | 97 | 48.3% |
| MISSING test — story exists, stated automated test file missing | 0 | 0.0% |
| NONE — story exists, no automated test path stated | 28 | 13.9% |
| NO STORY — ADR exists or partial architecture exists, not yet implemented | 76 | 37.8% |
| NO ADR — architectural gap | 0 | 0.0% |
| **Total requirements** | **201** | **100.0%** |

## Architecture Coverage Context

The current architecture review records the requirement-level architecture posture as:

| Architecture coverage | Count |
|---|---:|
| Covered | 131 |
| Partial | 70 |
| Gaps | 0 |
| Total requirements | 201 |

The RTM status above is stricter than architecture coverage: it tracks whether a requirement has a complete GDD → ADR → Story → Test chain. Therefore this file can show `NO STORY` or `NONE` while the architecture review still reports `NO ADR = 0`.

## Source Inventory

- Story files scanned: 69
- Automated test files scanned: 76
- Missing stated automated test paths: 0
- Story files with no dedicated TR-ID include `production/epics/balance-system/story-009-balance-statistical-validation.md`, which is a verification-only story.

## 2026-07-01 Alignment Notes

This refresh aligns the RTM with `docs/architecture/architecture-review-2026-07-01.md` and `docs/architecture/architecture-traceability.md`.

The source-of-truth architecture layer has converged enough that the old missing-ADR / cross-ADR blocker posture no longer applies:

1. EventBus and direct calls are unified under the registered hybrid authority model.
2. TownBuilding cross-system MVP consumption is canonicalized to the three-query surface:
   - `get_facility_training_multiplier(player_age: int)`
   - `get_facility_total_maintenance()`
   - `get_home_advantage_bonus()`
3. ADR-0003 and ADR-0013 now use aligned `audio_state` persistence vocabulary and restore semantics.
4. Scene-instantiated Core authority references for registered direct-call contracts must come from gameplay-root injection or a scene-owned service container/runtime registry; implicit global `class_name` pseudo-singletons, hardcoded `NodePath`, and arbitrary scene-tree search remain forbidden.
5. No current requirement is a true `NO ADR` gap.

The remaining RTM concerns are implementation-facing follow-through items: story/test chains, partial Presentation boundaries, and verification depth.

## Full Traceability Matrix

This compact RTM groups contiguous requirement ranges by system and status class. Use `docs/architecture/tr-registry.yaml` for exact requirement wording and `docs/architecture/architecture-review-2026-07-01.md` for the current review findings that produced this refresh.

| TR-ID / Range | GDD | ADR | Story/Test Status | Notes |
|---|---|---|---|---|
| `TR-gameconcept-001`–`TR-gameconcept-007` | `design/gdd/game-concept.md` | ADR-0002, ADR-0005, ADR-0006, ADR-0007, ADR-0011 | NO STORY | Concept-level requirements are architecture-covered but not implemented as direct stories. |
| `TR-balance-001`–`TR-balance-014` | `design/gdd/balance-system.md` | ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0008 | COVERED / NONE mix | Most balance requirements have automated tests; some evidence remains non-automated or verification-only by story type. |
| `TR-save-001`–`TR-save-014` | `design/gdd/save-and-load-system.md` | ADR-0003, ADR-0010 | COVERED / NO STORY mix | Save/load MVP stories and integration tests exist; Skill/Trait-specific durable state and half-settlement restore rows still need future story coverage. |
| `TR-time-001`–`TR-time-008` | `design/gdd/time-and-season-progression-system.md` | ADR-0002, ADR-0003 | COVERED | TimeManager story/test chain exists. |
| `TR-playerdev-001`–`TR-playerdev-011` | `design/gdd/player-development-system.md` | ADR-0005, ADR-0007, ADR-0008, ADR-0003 | COVERED | Player development stories and tests exist; facility multiplier contract is now canonicalized, and implementation must continue using injected/stable authority references when consuming scene-instantiated authorities. |
| `TR-match-001`–`TR-match-017` | `design/gdd/match-competition-system.md` | ADR-0006, ADR-0005, ADR-0008, ADR-0007, ADR-0009, ADR-0010 | COVERED / NO STORY mix | Match MVP stories and tests exist; formal fallback and pre-match skill/trait snapshot rows still need stories. The `match_completed` envelope remains canonical. |
| `TR-economy-001`–`TR-economy-013` | `design/gdd/economy-management-system.md` | ADR-0007, ADR-0004, ADR-0003 | COVERED | Economy stories and tests exist; post-match reward implementation should continue consuming `settlement_id` for idempotency follow-through. |
| `TR-town-001`–`TR-town-019` | `design/gdd/town-building-system.md` | ADR-0008, ADR-0007, ADR-0004, ADR-0003 | COVERED | Town-building stories and tests exist; cross-system consumption is bounded to the canonical MVP three-query surface. |
| `TR-skill-001`–`TR-skill-008` | `design/gdd/skill-and-trait-system.md` | ADR-0010, ADR-0003, ADR-0006 | NO STORY | Skill/Trait settlement, candidate progress, cooldown, feedback, identity, and migration stories are not scheduled. |
| `TR-league-001`–`TR-league-014` | `design/gdd/league-competition-structure-system.md` | ADR-0009, ADR-0006, ADR-0007, ADR-0002 | COVERED / NO STORY mix | Minimum league loop exists; broader league-specific rows still need story/test coverage. |
| `TR-mainui-001`–`TR-mainui-010` | `design/gdd/main-loop-ui-framework.md` | ADR-0001, ADR-0002, ADR-0010 (Partial) | NONE / NO STORY mix | MVP shell and route evidence exist; deeper Presentation API boundary and full story/test chain remain partial. |
| `TR-playerui-001`–`TR-playerui-011` | `design/gdd/player-management-ui.md` | ADR-0001, ADR-0005, ADR-0010 (Partial) | NONE / NO STORY mix | Roster/training entry story exists; read-model, feedback acknowledgement, and deeper player detail boundaries remain unscheduled. |
| `TR-matchui-001`–`TR-matchui-011` | `design/gdd/match-performance-ui.md` | ADR-0001, ADR-0006, ADR-0009, ADR-0010 (Partial) | NONE / NO STORY mix | Pre-match/result-flow story exists; live/result queue, snapshot, and no-recompute UI boundary rows need future stories. |
| `TR-reputation-001`–`TR-reputation-006` | `design/gdd/reputation-and-achievement-system.md` | ADR-0011, ADR-0003 | NO STORY | Recognition and achievement stories are not scheduled. |
| `TR-onboard-001`–`TR-onboard-010` | `design/gdd/onboarding-system.md` | ADR-0001, ADR-0002, ADR-0003 (Partial) | NONE / NO STORY mix | Minimum guidance story exists; persistent hint state, anchor fallback, first-match guidance, and replay/cooldown rows remain unscheduled. |
| `TR-random-001`–`TR-random-008` | `design/gdd/random-event-system.md` | ADR-0012 Accepted (Partial) | NO STORY | ADR exists and stable-key wording aligns with GDD/TR registry; remaining work is story/test coverage and implementation follow-through against stable-window, idempotency, and restore rules. |
| `TR-audio-001`–`TR-audio-006` | `design/gdd/audio-system.md` | ADR-0013 Accepted (Partial) | NO STORY | ADR exists and `audio_state` vocabulary is aligned; remaining work is story/test coverage and runtime verification for persistence, bus validation, and semantic event consumption. |
| `TR-townui-001`–`TR-townui-007` | `design/gdd/town-management-ui.md` | ADR-0001, ADR-0008, ADR-0007, ADR-0010 (Partial) | NO STORY | Town Management UI stories are not scheduled; construction confirmation sequencing and UI-only pressure-state boundaries remain partial. |
| `TR-tutorial-001`–`TR-tutorial-007` | `design/gdd/tutorial-and-hint-system.md` | ADR-0001, ADR-0002, ADR-0003, ADR-0010 (Partial) | NO STORY | Tutorial/Hint stories are not scheduled; hint durable state, cooldown, preferences, help index, and SaveManager boundary rows remain partial. |

## Uncovered Requirements / Priority Follow-through

There are no current `NO ADR` requirements. The remaining chain breaks are not missing architecture decisions; they are missing or incomplete implementation and verification links.

### Foundation / Core follow-up

- `TR-save-013`–`TR-save-014` — Skill/Trait durable state and half-settlement restore behavior need story coverage.
- `TR-match-016`–`TR-match-017` — Formal match fallback and pre-match skill/trait snapshot need story coverage.
- `TR-skill-001`–`TR-skill-008` — Skill/Trait settlement, candidate progress, cooldown, feedback, identity, and migration contracts need stories.
- Registered direct-call authority contracts need implementation verification for gameplay-root injection or scene-owned service container/runtime registry wiring.

### Core / Feature architecture follow-up

- `TR-random-001`–`TR-random-008` — ADR-0012 is accepted; remaining work is story/test coverage and implementation follow-through against stable-window, idempotency, and restore rules.
- `TR-audio-001`–`TR-audio-006` — ADR-0013 is accepted; remaining work is story/test coverage and runtime verification for `audio_state`, bus validation, and semantic event consumption.
- `TR-reputation-001`–`TR-reputation-006` — ADR coverage exists, but stories are not scheduled.

### Feature / Presentation layer follow-up

- UI/Presentation requirements are mostly Partial or `NONE`/`NO STORY`: Main UI, Player UI, Match UI, Town Management UI, Onboarding, and Tutorial/Hint require feature-specific API boundary and story/test coverage before deeper implementation.
- Production-representative visual exemplars and placeholder-tolerance rules remain gate-readiness evidence concerns, not architecture source-of-truth blockers.

## Production Gate Interpretation

- Verdict supported by this RTM: `CONCERNS`.
- The project does not have a current missing-ADR blocker and may continue Production inside accepted, architecture-covered scope.
- This RTM does **not** support a clean `READY` posture yet because full-chain coverage remains 97/201, accepted-but-unscheduled systems still lack story/test chains, Presentation API boundaries remain partial, and fresh automation is not yet a full current CI-equivalent baseline.

## History

| Date | Full Chain % | Notes |
|------|-------------:|-------|
| 2026-06-28 | 48.3% | Refreshed by `/architecture-review full`; ADR-0012 counted as Proposed/Partial, Audio remained NO ADR, and story/test scan used only `## Test Evidence` automated paths. |
| 2026-06-29 | 48.3% | Audio moved from NO ADR to ADR-0013 Accepted/Partial; `NO ADR` remained 0. Remaining concerns centered on ADR-0005 facility multiplier wording, supporting ADR follow-through, and unscheduled story/test coverage. |
| 2026-07-01 | 48.3% | Source-of-truth architecture converged to `CONCERNS`: EventBus/direct-call hybrid authority, TownBuilding canonical three-query surface, `audio_state` vocabulary, and scene-instantiated authority-reference rules are aligned. Remaining concerns are story/test linkage, partial Presentation boundaries, implementation follow-through, and fresh gate evidence depth. |
