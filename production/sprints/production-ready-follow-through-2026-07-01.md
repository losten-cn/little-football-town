# Production READY Follow-through Backlog — 2026-07-01

> Purpose: Convert accepted-but-unscheduled systems from open gate concerns into explicit story/test/defer chains.
> Gate context: `production/gate-checks/2026-07-01-pre-production-to-production.md`
> Architecture context: `docs/architecture/architecture-review-2026-07-01.md`
> RTM context: `docs/architecture/requirements-traceability.md`
> Current posture: Production can continue with CONCERNS; clean READY requires these chains or explicit deferrals.

## Scope Rule

This backlog does not reopen ADRs and does not authorize implementation by itself.

Each implementation story must still be created through `/create-stories` or an equivalent story-authoring pass, then checked with `/story-readiness` before `/dev-story`.

Do not edit `production/sprint-status.yaml` from this file alone. Sprint status remains owned by `/sprint-plan`, `/dev-story`, and `/story-done` workflows.

## Topology

### L0 — Governance / no-code closure

- Record explicit accepted-but-unscheduled status for Random Event, Audio, Skill/Trait, Reputation/Achievement, Town UI, Tutorial/Hint, and deeper Presentation API slices.
- Decide which are needed for clean READY as story chains vs. documented defer.
- Keep Production moving only inside already accepted, architecture-covered scope until a story/readiness pass authorizes implementation.

### L1 — Core contract story chains

These close Logic / Integration risk first.

| System | TR range | ADR | Minimum story chain | Required evidence | Clean READY action |
|---|---|---|---|---|---|
| Random Event | `TR-random-001`–`TR-random-008` | ADR-0012 | Stable window + `event_settlement_key`; idempotent processing ledger; save/load restore path | `tests/unit/random-event/...`, `tests/integration/random-event/...` | Create epic + story chain or defer with milestone |
| Skill/Trait | `TR-skill-001`–`TR-skill-008`, `TR-save-013`–`TR-save-014`, `TR-match-017` | ADR-0010, ADR-0003, ADR-0006 | durable state; pre-match snapshot; feedback lifecycle; cooldown/identity/migration | `tests/unit/skill-trait/...`, `tests/integration/skill-trait/...` | Create epic + story chain or defer with milestone |
| Reputation/Achievement | `TR-reputation-001`–`TR-reputation-006` | ADR-0011, ADR-0003 | recognition fact intake; idempotent reward settlement; save/load persistence | `tests/unit/reputation/...`, `tests/integration/reputation/...` | Create epic + story chain or defer with milestone |
| Audio | `TR-audio-001`–`TR-audio-006` | ADR-0013, ADR-0003 | audio settings payload; `audio_state` persistence; runtime restore; semantic event consumption; bus validation | `tests/unit/audio/...`, `tests/integration/audio/...`, manual playback smoke | Create epic + story chain or defer with milestone |

### L2 — Presentation boundary chains

These reduce the 70 Partial / Presentation API concern.

| System | TR range | ADR | Minimum story chain | Required evidence | Clean READY action |
|---|---|---|---|---|---|
| Main UI deeper boundary | `TR-mainui-001`–`TR-mainui-010` | ADR-0001, ADR-0002, ADR-0010 | shell read-model boundary; route guard; no gameplay recompute rule | UI interaction test or QA walkthrough | Add follow-up stories to existing epic |
| Player UI deeper boundary | `TR-playerui-001`–`TR-playerui-011` | ADR-0001, ADR-0005, ADR-0010 | roster/detail read-model contract; feedback ack; no-authority mutation rule | UI interaction test or QA walkthrough | Add follow-up stories to existing epic |
| Match UI deeper boundary | `TR-matchui-001`–`TR-matchui-011` | ADR-0001, ADR-0006, ADR-0009, ADR-0010 | live/result snapshot queue; no-recompute boundary; result explanation read model | UI interaction test or QA walkthrough | Add follow-up stories to existing epic |
| Town Management UI | `TR-townui-001`–`TR-townui-007` | ADR-0001, ADR-0008, ADR-0007, ADR-0010 | build/upgrade confirmation UI; pressure-state display-only boundary | UI interaction test or manual walkthrough | Create epic + story chain or defer with milestone |
| Tutorial/Hint | `TR-tutorial-001`–`TR-tutorial-007` | ADR-0001, ADR-0002, ADR-0003, ADR-0010 | hint durable state; cooldown; replay/preferences; help index | integration test + walkthrough | Create epic + story chain or defer with milestone |
| Onboarding deeper boundary | `TR-onboard-001`–`TR-onboard-010` | ADR-0001, ADR-0002, ADR-0003 | persistence/anchor/fallback beyond minimum what-next guidance | integration test + walkthrough | Add follow-up stories to existing epic |

### L3 — Visual readiness

Handled separately from story/test closure:

- production-representative visual exemplar
- placeholder tolerance rule
- Art Director sign-off criteria

## Minimum Gate Closure Criteria

To move from CONCERNS toward clean READY, the project must have either:

1. A concrete story chain for each listed system, with test/evidence path; or
2. An explicit deferral entry that names:
   - deferred milestone/sprint
   - reason it does not block current Production continuation
   - remaining TR status
   - required evidence before implementation

## Recommended Decisions

| System | Recommendation |
|---|---|
| Random Event | Defer implementation; create story chain before Beta/system expansion |
| Audio | Create near-term story chain if settings/audio polish is part of Production slice; otherwise defer with explicit milestone |
| Skill/Trait | Defer implementation; create story chain because it affects Save/Match contracts |
| Reputation/Achievement | Defer implementation; create story chain before recognition/reward loop starts |
| Town UI | Defer deeper implementation; create UI story chain before town-management slice |
| Tutorial/Hint | Defer deeper implementation; create story chain before onboarding polish |
| Main/Player/Match UI deeper boundary | Add follow-up stories, but do not reopen current MVP route unless a blocker appears |

## Current Gate Impact

This backlog reduces the Producer-facing risk from “accepted systems remain invisible / unscheduled” to “accepted systems have explicit follow-through / deferral governance.”

It does not by itself make the project clean READY because:

- Per-epic story files still need to be generated through `/create-epics` and `/create-stories` where missing.
- `/story-readiness` still needs to validate the first implementable stories before `/dev-story` begins.
- RTM full-chain coverage remains 97/201 = 48.3% until story/test chains exist and evidence is recorded.
- Visual production readiness still needs a production-representative exemplar and placeholder tolerance rule.

## Next Actions

1. Approve this backlog artifact.
2. For systems chosen as near-term, run `/create-epics` if an epic does not exist.
3. Then run `/create-stories [epic-slug]` one epic at a time.
4. Run `/story-readiness` before implementation.
5. Address production-representative visual exemplar / placeholder tolerance evidence before re-running or updating the Production gate.
