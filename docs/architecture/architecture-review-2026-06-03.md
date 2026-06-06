# Architecture Review Report — 2026-06-03

**Engine:** Godot 4.6 / GDScript  
**Review Mode:** Focused full architecture re-review after 2026-06-03 GDD and registry contract convergence  
**GDDs Reviewed:** Current designed/approved GDD set plus systems index and registry context  
**ADRs Reviewed:** ADR-0001 through ADR-0011  
**Verdict:** CONCERNS

## Summary

The architecture package has no new Godot 4.6 engine blocker and no blocking dependency cycle between accepted ADRs. The previously repaired Foundation/Core architecture remains viable: match result packets, forced forfeit packets, pre-match skill/trait snapshots, skill/trait feedback, and feedback acknowledgement contracts are covered at least partially by ADR-0010 and the existing Match/Save architecture.

The package should not be treated as fully PASS yet because several gate-facing architecture artifacts still lag behind the 2026-06-03 GDD convergence work. `architecture.md` still reports the 2026-06-01 FAIL/Pending status, `control-manifest.md` is still generated only through ADR-0009, and the newest Random Event and Audio contract registry entries do not yet have accepted architecture coverage. ADR-0011 is now accepted; its remaining work is implementation/test follow-through rather than architecture acceptance.

## Loaded Scope

Reviewed directly or through focused sub-review:

- `docs/architecture/architecture.md`
- `docs/architecture/control-manifest.md`
- `docs/architecture/requirements-traceability.md`
- `docs/architecture/tr-registry.yaml`
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
- `docs/architecture/adr-0011-reputation-and-achievement-recognition-framework.md`
- `design/registry/entities.yaml`
- `design/gdd/gdd-cross-review-2026-06-03.md`
- Current GDDs for match, league, skill/trait, random event, reputation/achievement, audio, save/load, and main loop UI
- Godot 4.6 engine reference docs under `docs/engine-reference/godot/`
- `.claude/docs/technical-preferences.md`

## Traceability Summary

This review did not rewrite the full traceability matrix. It focused on the new or recently repaired high-risk contract set from the 2026-06-03 GDD/registry cleanup.

| Contract / Requirement | Source | Architecture Coverage | Status | Follow-up |
|---|---|---:|---|---|
| `match_result_packet` | Match GDD / registry | `ADR-0006`, `ADR-0010`, `architecture.md` | Covered | No architecture blocker |
| `forfeit_result_packet` | Match GDD / registry | `ADR-0010`, `ADR-0006` | Partial | Keep implementation-story wiring checks for League/Economy/UI |
| `pre_match_skill_trait_snapshot` | Match + Skill/Trait GDD | `ADR-0010` | Partial | Implementation review must enforce snapshot-only UI consumption |
| `pending_skill_trait_feedback` | Skill/Trait GDD | `ADR-0010`, `ADR-0003` | Partial | Save/migration regression coverage required |
| `feedback_ack` | Skill/Trait GDD | `ADR-0010`, `ADR-0003` | Partial | Save/restore acknowledgement de-duplication coverage required |
| `match_context` | League/Match GDD | `architecture.md`, `ADR-0002` partially | Partial | `ADR-0009` should name the canonical `league -> match_context` packet contract |
| `reputation_settlement_key` | Reputation GDD / registry | `ADR-0011` | Covered | Keep stable-key usage and duplicate-delivery regression checks in implementation review |
| `processed_reputation_settlement_keys` | Reputation GDD / registry | `ADR-0011` | Covered | Preserve dual-ledger and durable-outcome semantics during implementation and save/load review |
| `event_settlement_key` | Random Event GDD / registry | No accepted ADR | Gap | Extend ADR-0010 or create a Random Event settlement ADR before Beta implementation |
| `processed_event_settlement_keys` | Random Event GDD / registry | No accepted ADR | Gap | Same as above |
| `audio_settings_fields` | Audio GDD / registry | GDD/Save defined; architecture not covered | Gap | Cover through a lightweight audio settings persistence decision or architecture append |

## Cross-ADR Conflicts

### Accepted ADR conflicts

No blocking conflict was found between accepted ADRs that prevents continued planning. The Match ↔ League boundary is now aligned in current GDDs as a packet contract: `league -> match_context` before kickoff and `match -> match_result_packet` after final result. Existing accepted ADRs do not require concrete runtime mutual state ownership.

### Concern — stable payload typing drift

**Files involved:**

- `docs/architecture/adr-0002-event-signal-architecture.md`
- `docs/architecture/architecture.md`
- `.claude/docs/technical-preferences.md`

**Issue:** Some older architecture text and examples still use bare `Dictionary` wording for stable payloads, while the project standard now requires `Dictionary[String, Variant]` for production API, save, event, and test assertion boundaries.

**Impact:** If older examples are implemented literally, typed-boundary regressions may reappear in save, event, and UI payload paths.

**Resolution:** Treat `Dictionary[String, Variant]` plus normalization of inbound untyped containers as the authoritative implementation rule. Update stale architecture examples during the next control-manifest/architecture refresh.

### Warning — ADR-0011 follow-through remains implementation-facing

**Files involved:**

- `docs/architecture/adr-0011-reputation-and-achievement-recognition-framework.md`
- `docs/architecture/requirements-traceability.md`
- `design/gdd/reputation-and-achievement-system.md`

**Issue:** ADR-0011 is now accepted and closes the architecture-acceptance gap for Reputation/Achievement, but downstream implementation stories still need to preserve dual-ledger idempotency, durable reward queue/history semantics, and UI read-only payload consumption.

**Impact:** This no longer blocks architecture convergence. The remaining risk is implementation drift if save/load, UI, economy handoff, or random-event follow-through ignores the accepted contract.

**Resolution:** Treat these items as implementation/test warnings. Keep regression coverage for duplicate delivery, save/load recovery, and authoritative payload consumption in the next implementation pass.

### Concern — Random Event settlement keys lack accepted architecture coverage

**Files involved:**

- `design/gdd/random-event-system.md`
- `design/registry/entities.yaml`
- `docs/architecture/adr-0010-cross-system-payload-and-settlement-contracts.md`

**Issue:** The GDD and registry now define `event_settlement_key` and `processed_event_settlement_keys`, but no accepted ADR covers RandomEventManager authority, event settlement de-duplication, or save/load durability for those keys.

**Impact:** This is not an MVP blocker, but it is a Beta implementation blocker for the random-event settlement path.

**Resolution:** Either extend ADR-0010 to include random-event settlement contracts or create a dedicated Random Event settlement ADR before implementing Beta random events.

### Concern — Audio settings persistence lacks architecture coverage

**Files involved:**

- `design/gdd/audio-system.md`
- `design/gdd/save-and-load-system.md`
- `design/gdd/main-loop-ui-framework.md`
- `design/registry/entities.yaml`

**Issue:** The GDDs and registry define `audio_master_volume`, `audio_bgm_volume`, `audio_sfx_volume`, `audio_ambience_volume`, and `audio_muted_categories`, but no accepted architecture artifact names the audio settings persistence payload.

**Impact:** This is not a gameplay blocker, but implementation could split field ownership between UI, Audio, and Save/Load if not captured before Beta/audio settings work.

**Resolution:** Cover this through a lightweight Audio settings persistence ADR or an accepted architecture append.

## ADR Dependency Order

No accepted ADR dependency cycle was found.

Recommended implementation order remains:

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
11. `ADR-0011` — Reputation and Achievement Recognition Framework

## Engine Compatibility Issues

### Engine audit result

**CONCERNS — no engine blockers.**

No direct blocker was found for Godot 4.6. The review did not find accepted architecture requiring deprecated APIs such as:

- `yield()`
- `instance()` / `PackedScene.instance()`
- string-based `connect("signal", obj, "method")`
- old authoritative `TileMap` gameplay-state patterns

### Godot 4.6 risks to carry forward

1. Stable payload examples should use `Dictionary[String, Variant]`, not bare `Dictionary`, at public/save/event boundaries.
2. Control dual-focus and AccessKit-aware UI behavior are acknowledged but not yet fully formalized as UI architecture rules.
3. Audio has no Godot 4.6 blocker, but settings persistence needs architecture coverage before Beta implementation.

## GDD Revision Flags

No GDD revision flags were found. The current issues are architecture artifact coverage and status synchronization problems, not design rules that contradict verified Godot 4.6 behavior.

## Architecture Document Coverage

### `architecture.md`

`architecture.md` has partially absorbed ADR-0010 and already mentions:

- `match_context`
- `forfeit_result_packet`
- `pre_match_skill_trait_snapshot`
- skill/trait feedback durable payload state

However, it remains stale because its document status still points to the 2026-06-01 FAIL/Pending review state and does not yet fully reflect:

- 2026-06-03 GDD convergence
- Random Event settlement contracts
- Audio settings persistence fields
- updated control manifest version

### `control-manifest.md`

`control-manifest.md` is stale:

- **Last Updated:** 2026-05-19
- **ADRs Covered:** ADR-0001 through ADR-0009 only

It should now be regenerated so story-facing programmer rules include ADR-0010 and ADR-0011 and the gate-facing package reflects the converged architecture state.

## Verdict

### CONCERNS

The architecture package may continue toward planning and targeted cleanup, but it should not be considered fully clean until the stale/partial coverage items are resolved.

This is not a FAIL because:

1. No new Foundation/Core hard gap was found.
2. Godot 4.6 compatibility has no blocker.
3. Match/League packet contract no longer conflicts at the GDD level.
4. Most remaining gaps are Alpha/Beta/Presentation follow-through or document synchronization issues.

It is not PASS because:

1. Random Event and Audio registry contracts still lack accepted architecture coverage.
2. `control-manifest.md` is stale and omits ADR-0010/0011.
3. `architecture.md` still carries the earlier FAIL/Pending status and incomplete coverage state.

## Blocking Issues

No blocking issue prevents continued targeted architecture cleanup. The following are required before a clean PASS:

1. Refresh `control-manifest.md` to include ADR-0010 and ADR-0011.
2. Update architecture status/coverage language in `architecture.md`.
3. Add accepted coverage for Random Event settlement keys before Beta random-event implementation.
4. Add accepted coverage for audio settings persistence before Beta/audio settings implementation.

## Required ADRs / Recommended Skills

Priority order:

1. `/create-control-manifest update` — regenerate story-facing programmer rules after ADR coverage changes.
2. `/architecture-review rtm` — generate the full GDD → ADR → Story → Test matrix now that the project has production stories and tests.
3. `/architecture-decision Random Event Settlement Contracts` — required before Beta Random Event implementation.
4. `/architecture-decision Audio Settings Persistence` — required before Beta Audio settings implementation.

## Handoff

Recommended immediate next step: refresh the control manifest, then rerun architecture review or RTM mode so the gate-facing package reflects the accepted ADR-0011 convergence.
