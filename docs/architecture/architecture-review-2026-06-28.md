# Architecture Review Report

Date: 2026-06-28  
Engine: Godot 4.6  
Mode: `/architecture-review full`  
GDDs Reviewed: 20, including `design/gdd/systems-index.md`  
ADRs Reviewed: 12 — 11 Accepted + 1 Proposed (`ADR-0012`)  
Stories scanned for RTM: 68  
Automated test files scanned: 76

---

## Traceability Summary

| Metric | Count |
|---|---:|
| Total requirements | 201 |
| ✅ Covered | 130 |
| ⚠️ Partial | 65 |
| ❌ Gaps | 6 |

`ADR-0012` exists for Random Event settlement contracts, but remains `Proposed` and has a blocking stable-key conflict, so Random Event requirements are counted as Partial, not Covered.

## Coverage Gaps — No Accepted ADR Exists

| TR-ID | GDD | Requirement | Suggested ADR | Domain | Engine Risk |
|---|---|---|---|---|---|
| `TR-audio-001` | `audio-system.md` | Audio consumes stable events only and must never mutate gameplay or navigation state. | `/architecture-decision Audio Settings & Event Consumption` | Audio / Event Consumer | MEDIUM |
| `TR-audio-002` | `audio-system.md` | Playback eligibility and missing assets must degrade silently. | `/architecture-decision Audio Settings & Event Consumption` | Audio / Asset Fallback | MEDIUM |
| `TR-audio-003` | `audio-system.md` | Audio mixing formula. | `/architecture-decision Audio Settings & Event Consumption` | Audio / Mixing | MEDIUM |
| `TR-audio-004` | `audio-system.md` | Audio preference fields are durable settings only. | `/architecture-decision Audio Settings & Persistence` | Audio / Save Settings | HIGH |
| `TR-audio-005` | `audio-system.md` | Audio events in the same stable window must be prioritized, merged, delayed, or suppressed. | `/architecture-decision Audio Event Priority & Playback Queue` | Audio / Priority Queue | MEDIUM |
| `TR-audio-006` | `audio-system.md` | Low-pressure feedback constraints for loss, shortage, maintenance, and weak outcomes. | `/architecture-decision Audio Feedback Tone & UX Boundaries` | Audio / UX Tone | LOW |

## Partial Coverage Sources

| Source | Count | Notes |
|---|---:|---|
| Random Event | 8 | `docs/architecture/adr-0012-random-event-settlement-contracts.md` exists but is `Proposed` and has a blocking stable-key conflict. |
| Presentation / UI / Onboarding / Tutorial | 56 | ADR-0001, ADR-0010, and ADR-0011 provide base coverage, but feature-specific UI API boundaries remain incomplete. |
| Balance Diagnostics | 1 | `TR-balance-009` has configuration support, but no dedicated diagnostics / telemetry architecture. |

---

## RTM Story and Test Linkage

Current story/test scan:

| Test Status | Count |
|---|---:|
| COVERED | 97 |
| MISSING | 0 |
| NONE | 28 |
| NO STORY | 76 |
| Total TR | 201 |

Key findings:

1. All automated test files declared by stories exist: `MISSING = 0`.
2. `production/epics/balance-system/story-009-balance-statistical-validation.md` is a verification-only story with no dedicated TR-ID, so its test cannot be counted under a TR row.
3. 28 TRs have a story but no automated test path in the story `## Test Evidence` section; these are mostly UI, onboarding, or config/manual-evidence stories.
4. The previous `docs/architecture/requirements-traceability.md` was stale relative to current stories/tests and has been refreshed alongside this report.

---

## Cross-ADR Conflicts

### 🔴 Conflict 1 — ADR-0012 vs ADR-0010 / ADR-0011: stable settlement key conflict

**Type:** State management / Integration contract / Idempotency  
**Severity:** Blocking for ADR-0012 acceptance and Random Event implementation

`ADR-0012` defines `event_settlement_key` with `rule_version` in the key source. `ADR-0010` and `ADR-0011` both establish the opposite rule: `rule_version` is metadata and must not enter durable cross-system settlement identity.

**Impact:** A rule-version change could produce a new durable key for the same event fact. If that key is consumed downstream by Reputation/Achievement settlement, the same fact could bypass idempotency and grant duplicate reputation, achievements, or rewards.

**Resolution:** Revise ADR-0012 to remove `rule_version` from durable settlement identity. If version-sensitive evaluation is required, split it into an evaluation key and a separate durable `event_settlement_id` that excludes `rule_version`.

### 🔴 Conflict 2 — `match_completed` payload contract is inconsistent

**Type:** Integration contract conflict  
**Severity:** Blocking before Match → League / Economy / Skill integration tests

Current ADR examples diverge:

- ADR-0002 shows `result_packet`.
- ADR-0009 requires `match_id + result_packet`.
- ADR-0010 shows `settlement_id + result_packet`.
- ADR-0006 does not clearly separate EventBus envelope fields from `MatchResultPacket` fields.

**Impact:** League requires `match_id`; settlement/idempotency consumers require `settlement_id`; Economy requires `result_packet`. Implementing any one ADR example literally can break another consumer.

**Resolution:** Adopt this canonical envelope:

```gdscript
{
	"match_id": String,
	"settlement_id": String,
	"result_packet": Dictionary[String, Variant],
}
```

`match_id` and `settlement_id` should be EventBus envelope fields. `result_packet` should remain the match result payload.

### ⚠️ Conflict 3 — `architecture.md` topological order conflicts with ADR dependencies

**Type:** Dependency / implementation-order conflict  
**Severity:** Blocking for implementation sequencing clarity

`architecture.md` still implies an order where TownBuilding precedes PlayerDevelopment / MatchCompetition / EconomyManager. The accepted ADR dependency graph requires:

```text
PlayerDevelopment → MatchCompetition → EconomyManager → TownBuilding / LeagueStructure
```

**Resolution:** Update `architecture.md` to distinguish runtime data flow from implementation order, and align the implementation order with the ADR dependency graph.

### ⚠️ Conflict 4 — ADR-0003 uses `ConfigLoader.get_save_version()` but does not depend on ADR-0004

**Type:** Dependency contract gap  
**Severity:** Medium

`ADR-0003` Save/Load references `ConfigLoader.get_save_version()`, which is defined by `ADR-0004`, but `ADR-0003` only lists ADR-0001 and ADR-0002 as dependencies.

**Resolution:** Add ADR-0004 to ADR-0003 dependencies or explicitly enforce ADR-0004 before ADR-0003 in implementation sequencing.

### ⚠️ Conflict 5 — ADR-0005 PlayerDevelopment has an implicit TownBuilding facility dependency

**Type:** Dependency / integration contract gap  
**Severity:** Medium

PlayerDevelopment formulas consume TownBuilding facility multipliers, but ADR-0005 does not depend on ADR-0008.

**Resolution:** Document that early PlayerDevelopment uses neutral `1.0` facility multipliers until ADR-0008 is integrated, or split facility-integrated growth into a later story.

### ⚠️ Conflict 6 — `architecture.md` ADR audit status is stale

**Type:** Documentation consistency  
**Severity:** Medium

`architecture.md` still reports `11/11 Accepted` and treats Random Event as an ADR gap. Current inventory is `11 Accepted + 1 Proposed`.

**Resolution:** Update `architecture.md` after ADR-0012 is revised or explicitly mark `ADR-0012` as Proposed and blocked.

---

## ADR Dependency Order

### Foundation

1. ADR-0001 — Scene Management & Autoload Architecture
2. ADR-0004 — Data-Driven Configuration
3. ADR-0002 — Event/Signal Architecture + TimeManager
4. ADR-0003 — Save/Load Persistence  
   Recommended practical dependencies: ADR-0001, ADR-0002, ADR-0004.

### Core baseline

5. ADR-0005 — Player Data Model
6. ADR-0006 — Match Simulation Architecture
7. ADR-0007 — Economy Transaction Framework

### Core / Feature contract layer

8. ADR-0008 — Town Grid & Facility System
9. ADR-0009 — League Competition Structure
10. ADR-0010 — Cross-System Payload and Settlement Contracts
11. ADR-0011 — Reputation and Achievement Recognition Framework

### Proposed / blocked

12. ADR-0012 — Random Event Settlement Contracts  
    Status: Proposed. Must resolve the stable-key conflict before acceptance.

No explicit dependency cycles were found. No nonexistent ADR dependencies were found.

---

## Engine Compatibility Issues

Engine: Godot 4.6  
ADRs with Engine Compatibility section: 12 / 12

### Deprecated API references

- ADR-0003 contains a stale `OS.get_unix_time()` comment/reference. It should align with `Time.get_unix_time_from_system()` semantics.

### Version consistency

- No ADR targets an older engine version. All ADRs align with Godot 4.6.

### Post-cutoff API conflicts

- No invalid or conflicting Godot 4.6 post-cutoff API use was found.
- ADR-0003 correctly notes `FileAccess.store_* -> bool` behavior.
- ADR-0004 correctly notes `@abstract` and `duplicate_deep()`.

### Engine Specialist Findings

Risk: **Medium**

1. No core ADR design appears impossible under Godot 4.6.
2. The main Godot-specific hygiene issue is stable contract typing: older ADR examples still use bare `Dictionary` for stable payload/save/event contracts, while project standards now prefer typed dictionary boundaries.
3. ADR-0002 EventBus is compatible, but “type-safe” wording should be softened. Type safety depends on payload builders and validation, not native Godot typed signal enforcement.
4. ADR-0003 and ADR-0008 mention “GUT test” wording, while the active project standard is the custom headless runner.

---

## GDD Revision Flags

No GDD revision flags — all GDD assumptions are consistent with verified engine behavior.

No `systems-index.md` updates are required from engine findings.

---

## Architecture Document Coverage

### Systems-index coverage status

`systems-index.md` lists 20 systems. `architecture.md` layer / ownership coverage includes 18 systems and misses 2 future/product systems.

| System | architecture.md Status | Note |
|---|---|---|
| Balance System | Covered | ConfigLoader / BalanceConfig / ADR-0004. |
| Save and Load System | Covered | ADR-0003 and Save/Load path. |
| Time and Season Progression | Covered | ADR-0002. |
| Player Development | Covered | ADR-0005; facility multiplier integration needs sequencing note. |
| Match Competition | Covered | ADR-0006. |
| Economy Management | Covered | ADR-0007. |
| Town Building | Covered | ADR-0008. |
| Skill and Trait | Covered | ADR-0010. |
| League Competition Structure | Covered | ADR-0009. |
| Main Loop UI Framework | Partial | ScreenManager / MainLoopUI exists; UI-specific API boundary incomplete. |
| Player Management UI | Partial | Ownership exists; formal read-model / feedback boundary insufficient. |
| Match Performance UI | Partial | Ownership exists; live/result queue and feedback boundary insufficient. |
| Reputation and Achievement | Covered | ADR-0011. |
| Onboarding System | Partial | API exists; persistence fields, anchor fallback, and first-match guidance are too broad. |
| Random Event System | Partial | ADR-0012 exists but is Proposed and conflicted. |
| Audio System | Gap / partial in `architecture.md` | Warning/ownership only; no ADR coverage. |
| Town Management UI | Partial | Missing construction confirmation sequencing and UI-only maintenance pressure boundary. |
| Tutorial and Hint System | Partial | Missing hint durable state, cooldown, preferences, help index, and SaveManager boundary. |
| 多周目与挑战模式系统 | Missing | No GDD; Full Vision, not short-term MVP blocking. |
| 商业化与 DLC 规划系统 | Missing | No GDD; product-layer concern, not runtime architecture. |

### Orphaned architecture

No clearly problematic orphaned gameplay architecture was found. Godot Platform, EventBus, ConfigLoader, ScreenManager, and Compatibility renderer references are justified as platform/foundation architecture.

### Architecture document recommendations

1. Update `architecture.md` ADR inventory and Random Event status.
2. Update implementation topological order.
3. Extend Presentation API Boundaries for Player UI, Match UI, Town UI, Onboarding, and Tutorial/Hint.
4. Add Save/Load path coverage for Audio settings and Tutorial/Hint persistent UI support states.
5. Refresh traceability after ADR-0012 is revised and accepted.

---

## Verdict: FAIL

The architecture is broadly implementable, but it should not pass the architecture gate yet because blocking architecture conflicts and ADR coverage gaps remain.

### Blocking Issues

1. ADR-0012 Random Event settlement key conflicts with ADR-0010 / ADR-0011 stable-key rules.
2. `match_completed` canonical payload is inconsistent across ADR-0002 / ADR-0006 / ADR-0009 / ADR-0010.
3. Audio has 6 uncovered technical requirements, including high-risk audio settings persistence.
4. `architecture.md` is stale relative to the current ADR inventory and dependency graph.

### Required ADRs / Fixes

1. Revise ADR-0012 Random Event Settlement Contracts.
2. Update ADR-0002 / ADR-0006 / ADR-0009 / ADR-0010 to share a canonical `match_completed` envelope.
3. Create `/architecture-decision Audio Settings & Event Consumption`.
4. Create `/architecture-decision Main and Feature UI API Boundaries` before deeper UI implementation.
5. Create `/architecture-decision Tutorial and Hint State Persistence` before Tutorial/Hint implementation.
6. Optional: Create `/architecture-decision Balance Diagnostics & Telemetry` if balance diagnostics become a production system.

---

## Pre-gate Checklist

| Item | Status |
|---|---|
| `tests/unit/` | ✅ |
| `tests/integration/` | ✅ |
| `.github/workflows/tests.yml` | ✅ |
| `design/accessibility-requirements.md` | ✅ |
| `design/ux/interaction-patterns.md` | ✅ |

Pre-gate infrastructure exists, but `/gate-check pre-production` should wait until the blocking ADR conflicts/gaps above are resolved.

## Handoff

Immediate actions:

1. Revise ADR-0012 to remove `rule_version` from durable settlement identity.
2. Normalize `match_completed` payload across ADRs.
3. Write Audio architecture coverage for `TR-audio-001`–`TR-audio-006`.

Re-run `/architecture-review` after each new or revised ADR to verify coverage improves.
