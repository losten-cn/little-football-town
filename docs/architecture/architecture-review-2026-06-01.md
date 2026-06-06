# Architecture Review Report — 2026-06-01

**Engine:** Godot 4.6 / GDScript  
**Review Mode:** Full architecture review after ADR-0010 acceptance  
**GDDs Reviewed:** 16 active GDD/system docs + systems index context  
**ADRs Reviewed:** 10  
**Verdict:** FAIL

## Summary

The architecture package remains viable and has no critical Foundation/Core ADR gap. ADR-0010 successfully closes the cross-system payload and settlement-contract concerns raised by the 2026-06-01 cross-GDD review: forced-match fallback, pre-match skill/trait snapshots, UI read-only payload consumption, durable skill/trait feedback persistence, and stable settlement-key boundaries now have accepted architecture coverage.

The review does not find a Godot 4.6 compatibility blocker or an ADR dependency cycle. However, several documentation and implementation-policy concerns remain and should be cleaned up before treating the architecture package as fully clean: ADR-0010 accepted-state wording has not fully propagated, ADR-0006 still describes `_process()`-based match ticks while the master architecture forbids Core `_process()` loops, ADR-0003 has drift around mid-match save semantics and runtime `hash(Dictionary)` integrity examples, and the master architecture still mentions `TileMapLayer` for town rendering despite ADR-0008 choosing pure data + custom Control rendering.

## Loaded Scope

Reviewed:

- `docs/architecture/adr-0001-scene-management.md`
- `docs/architecture/adr-0002-event-signal-architecture.md`
- `docs/architecture/adr-0003-save-load-persistence.md`
- `docs/architecture/adr-0004-data-driven-configuration.md`
- `docs/architecture/adr-0005-player-data-model.md`
- `docs/architecture/adr-0006-match-simulation-architecture.md`
- `docs/architecture/adr-0007-economy-transaction-framework.md`
- `docs/architecture/adr-0008-town-grid-facility-system.md`
- `docs/architecture/adr-0009-league-competition-structure.md`
- `docs/architecture/adr-0010-cross-system-payload-and-settlement-contracts.md`
- `docs/architecture/architecture.md`
- `docs/architecture/tr-registry.yaml`
- `docs/architecture/requirements-traceability.md`
- `docs/consistency-failures.md`
- Godot 4.6 engine reference docs under `docs/engine-reference/godot/`
- Active GDD/system docs under `design/gdd/`

Historical GDD review reports were treated as reference only, not active system GDDs.

## Traceability Summary

### Traceability Summary
Total requirements: 163
✅ Covered: 107
⚠️ Partial: 48
❌ Gaps: 8

## Partial Coverage Items

| TR-ID | Requirement | Governing ADR | Status | Required Follow-up |
|-------|-------------|---------------|--------|--------------------|
| TR-economy-008 | AP daily recovery formula | `ADR-0007` | Partial | ADR covers settlement but not daily AP regeneration timing detail. Clarify during Economy implementation story or ADR revision. |
| TR-town-013 | Maximum adjacency bonus cap 15.0 | `ADR-0008` | Partial | ADR computes adjacency bonuses but must explicitly enforce the GDD cap before implementation. |
| TR-match-016 | Formal match fallback resolves through recommended lineup → out-of-position fill → `forfeit_result_packet` | `ADR-0010`, `ADR-0006` | Partial | Wire the fallback packet contract into match, league, economy, and UI implementation stories. |
| TR-match-017 | `pre_match_skill_trait_snapshot` is a locked read-only match input consumed by MatchPerfUI and never recomputed in UI | `ADR-0010` | Partial | Enforce snapshot-only consumption in match and UI implementation reviews. |
| TR-save-013 | Skill/trait durable state persists candidate progress, cooldowns, feedback, ack state, identity history, migration records, and processed settlement keys | `ADR-0010`, `ADR-0003` | Partial | Extend save serialization tests and migration coverage for the full durable payload set. |
| TR-save-014 | Save/load restores durable settlement outcomes only and never replays half-resolved skill/trait evaluation state | `ADR-0010`, `ADR-0003` | Partial | Add regression coverage for reload-after-feedback and duplicate-settlement delivery. |
| TR-mainui-010 | Automatic support and post-match feedback surfaces consume authoritative payloads only and never recompute unlock, trigger, or settlement truth | `ADR-0010` | Partial | Treat UI payload consumption as a review gate for main-loop implementation work. |
| TR-playerui-011 | Player Detail consumes candidate visibility stage, blocked reason, feedback ack, and identity history as read-only payload fields | `ADR-0010` | Partial | Bind Player Detail directly to authoritative payload fields instead of local derivation. |

## Coverage Gaps (no ADR exists)

❌ TR-reputation-001: `design/gdd/reputation-and-achievement-system.md` → Reputation & Achievement → Reputation gain formula authority and settlement ownership
   Suggested ADR: `/architecture-decision Reputation and Achievement Recognition Framework`
   Domain: Economy / Progression / Presentation
   Engine Risk: MEDIUM

❌ TR-reputation-002: `design/gdd/reputation-and-achievement-system.md` → Reputation & Achievement → Reputation level progression and progress-ratio contract
   Suggested ADR: `/architecture-decision Reputation and Achievement Recognition Framework`
   Domain: Progression / UI Contract
   Engine Risk: LOW

❌ TR-reputation-003: `design/gdd/reputation-and-achievement-system.md` → Reputation & Achievement → Achievement unlock authority and duplicate-prevention contract
   Suggested ADR: `/architecture-decision Reputation and Achievement Recognition Framework`
   Domain: Progression / Save-Load
   Engine Risk: LOW

❌ TR-reputation-004: `design/gdd/reputation-and-achievement-system.md` → Reputation & Achievement → Reward settlement ordering and de-duplication across systems
   Suggested ADR: `/architecture-decision Reputation and Achievement Recognition Framework`
   Domain: Cross-System Settlement
   Engine Risk: MEDIUM

❌ TR-reputation-005: `design/gdd/reputation-and-achievement-system.md` → Reputation & Achievement → Durable save/load state for reputation, unlocked achievements, and pending rewards
   Suggested ADR: `/architecture-decision Reputation and Achievement Recognition Framework`
   Domain: Save / Load Persistence
   Engine Risk: LOW

❌ TR-reputation-006: `design/gdd/reputation-and-achievement-system.md` → Reputation & Achievement → Authoritative presentation payloads for reputation and achievements
   Suggested ADR: `/architecture-decision Reputation and Achievement Recognition Framework`
   Domain: Presentation / UI Contract
   Engine Risk: LOW

## Cross-ADR Conflicts

## Conflict: ADR-0010 vs project typed collection standard
Type: Integration / State Contract
ADR-0010 claims: Stable cross-system payloads can be modeled with illustrative bare `Dictionary` contracts in authoritative interfaces.
Project standard claims: Stable production payloads, save payloads, and event payloads must use `Dictionary[String, Variant]` at API boundaries.
Impact: If ADR examples are implemented literally, payload authority becomes inconsistent with the pinned Godot 4.6 GDScript typing policy and reintroduces typed-boundary regressions during serialization, event dispatch, and UI binding.
Resolution options:
  1. Revise ADR-0010 examples and contract signatures to use `Dictionary[String, Variant]` at stable boundaries.
  2. Add an explicit normalization rule in ADR-0010 for all inbound untyped runtime containers before they cross a durable or public API boundary.

## Cross-ADR Conflicts and Concerns

### Concern 1 — Core `_process()` policy conflicts with ADR-0006

**Files involved:**

- `docs/architecture/architecture.md`
- `docs/architecture/adr-0006-match-simulation-architecture.md`

**Issue:**
The master architecture states that Core systems do not run `_process()` and that core logic is EventBus callback-driven. ADR-0006 still says `MatchSimulation` uses `_process()`-based tick advancement.

**Impact:**
Implementation could split between event-driven management-sim logic and per-frame Core processing, undermining the current architecture principle.

**Recommendation:**
Revise ADR-0006 wording to use explicit `advance()` / event-triggered simulation ticks instead of `_process()`-based advancement.

### Concern 2 — Mid-match save/load semantics drift

**Files involved:**

- `docs/architecture/adr-0003-save-load-persistence.md`
- `docs/architecture/adr-0006-match-simulation-architecture.md`
- `docs/architecture/adr-0010-cross-system-payload-and-settlement-contracts.md`

**Issue:**
ADR-0006 says Match In Progress is not a stable restore point and restores to Entry / pre-match state. ADR-0003 still contains a GDD mapping row saying match resumes from the “last stable event.”

**Impact:**
Save/load implementation may accidentally support an undefined mid-match resume model.

**Recommendation:**
Update ADR-0003 to match the accepted rule: durable stable-node restore only; no mid-match replay or resume.

### Concern 3 — Save integrity uses runtime `hash(Dictionary)`

**Files involved:**

- `docs/architecture/adr-0003-save-load-persistence.md`
- `docs/architecture/adr-0010-cross-system-payload-and-settlement-contracts.md`

**Issue:**
ADR-0003’s checksum example hashes runtime dictionaries directly. ADR-0010 forbids direct runtime Dictionary/Variant hashing for stable settlement identity, and the same principle should apply to durable integrity digests.

**Impact:**
Field ordering or serialization differences could create unstable save integrity behavior.

**Recommendation:**
Replace the runtime `hash(Dictionary)` example with a stable canonical serialization digest.

### Concern 4 — ADR-0010 accepted-state wording has not fully propagated

**Files involved:**

- `docs/architecture/architecture.md`
- `docs/architecture/requirements-traceability.md`

**Issue:**
`architecture.md` still says ADR-0010 has “proposed-partial” follow-through and calls ADR-0010 “proposed.” `requirements-traceability.md` still has several follow-up rows beginning with “Accept ADR-0010...”.

**Impact:**
This does not block implementation by itself, but it makes the accepted state ambiguous in gate-facing docs.

**Recommendation:**
Clean all residual “proposed” / “Accept ADR-0010” wording now that ADR-0010 is accepted.

### Concern 5 — Town rendering wording still mentions `TileMapLayer`

**Files involved:**

- `docs/architecture/architecture.md`
- `docs/architecture/adr-0008-town-grid-facility-system.md`

**Issue:**
The master architecture still lists TownBuilding engine API as `TileMapLayer (2D grid render, if used)`, while ADR-0008 chose pure data + custom Control rendering.

**Impact:**
Implementation may reopen a rejected rendering path.

**Recommendation:**
Replace the `TileMapLayer` reference with “pure data model + custom Control rendering.”

## ADR Dependency Order

All 10 ADRs are currently Accepted. No dependency cycles were detected.

Recommended ordering remains:

1. `ADR-0001` — Scene Management & Autoload Architecture
2. `ADR-0004` — Data-Driven Configuration
3. `ADR-0002` — Event / Signal Architecture + TimeManager
4. `ADR-0003` — Save / Load Persistence
5. `ADR-0005` — Player Data Model
6. `ADR-0006` — Match Simulation Architecture
7. `ADR-0007` — Economy Transaction Framework
8. `ADR-0008` — Town Grid & Facility System
9. `ADR-0009` — League Competition Structure
10. `ADR-0010` — Cross-System Payload and Settlement Contracts

ADR-0010 depends on already accepted ADRs and does not create a dependency cycle.

## Engine Compatibility Audit

### Engine Verdict

**FAIL**

The engine itself is not the blocker, but accepted architecture contracts still conflict with the project's pinned Godot 4.6 typed-boundary standard and leave UI focus/accessibility obligations under-specified.

### Confirmed by Godot specialist

- `duplicate()` usages in ADR-0002 / ADR-0009 are shallow array copies, not nested Resource duplication; not a blocker.
- `TileMap` appears only in a rejected alternative; not a blocker.
- ADR-0003 correctly notes `FileAccess.store_*` return-value behavior.
- UI dual-focus and AccessKit remain implementation watch items, not current ADR blockers.

### Engine Compatibility Issues

- CONCERN: UI architecture does not yet elevate Godot 4.6 dual-focus behavior to an explicit navigation/input contract; keyboard focus and mouse hover authority may drift in implementation if ADR-0001 remains lifecycle-only.
- CONCERN: Accessibility expectations introduced in Godot 4.5+ AccessKit are not yet represented as architecture-level UI obligations, leaving onboarding and management screens without a documented compliance target.
- FAIL: Stable payload examples across ADR-0001, ADR-0002, ADR-0003, ADR-0006, ADR-0007, and ADR-0010 still normalize around bare `Dictionary` rather than project-standard `Dictionary[String, Variant]` boundaries.

## GDD Revision Flags

No GDD revision flags were found from engine compatibility review.

The concerns above point to architecture-document cleanup and implementation acceptance criteria, not GDD revisions.

## Architecture Document Coverage

### Covered

- All current Foundation/Core/Feature GDD systems appear in `architecture.md`.
- ADR-0010 is listed in the ADR audit.
- New TRs exist in `tr-registry.yaml`.
- `requirements-traceability.md` references ADR-0010 for the new cross-system contract items.

### Concerns

- Skill/trait is covered through ADR-0010 contract rules, but not represented as a first-class architecture module in the layer map.
- Presentation remains intentionally partial, but Main UI / Player UI / Match UI still need later UI ADRs.
- The pre-gate exact directory glob did not match `tests/unit/` and `tests/integration/`, although the repository has established test infrastructure and CI workflow evidence elsewhere. Verify exact directory paths before a formal gate.

### Verdict: FAIL

FAIL remains appropriate because the current architecture set still has newly registered requirement gaps, a missing Reputation & Achievement ADR, and an accepted-contract typing conflict against the project-standard Godot boundary rules.

### Blocking Issues (must resolve before PASS)
- Register the new Skill & Trait and Reputation & Achievement technical requirements in `docs/architecture/tr-registry.yaml` and regenerate the traceability summary against the current GDD set.
- Create and accept a dedicated ADR for Reputation & Achievement before that system enters implementation.
- Revise stable payload examples and contract signatures so accepted ADRs align with the project's typed GDScript boundary standard.
- Promote dual-focus UI behavior and accessibility expectations from implicit engine knowledge to explicit architecture guidance for management-screen implementation.

### Required ADRs
1. `ADR-0011` — Reputation and Achievement Recognition Framework
2. ADR addendum / revision — Typed payload boundary normalization across accepted contracts
3. ADR addendum / revision — UI focus and accessibility obligations for Godot 4.6 management screens

## Pre-Gate Checklist Snapshot

| Item | Status |
|------|--------|
| `.github/workflows/tests.yml` | Present |
| `design/accessibility-requirements.md` | Present |
| `design/ux/interaction-patterns.md` | Present |
| `tests/unit/` | Needs exact directory verification |
| `tests/integration/` | Needs exact directory verification |

## Recommended Next Step

Do the cleanup pass listed above, then rerun `/architecture-review`. If the cleanup resolves the wording and policy drift, the expected next verdict is PASS unless new issues are introduced.
