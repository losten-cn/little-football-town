# Architecture Review Report

Date: 2026-06-29  
Engine: Godot 4.6  
Mode: `/architecture-review full`  
Review posture: Strict follow-up review after ADR-0012 / ADR-0013 acceptance  
GDDs Reviewed: 20, including `design/gdd/systems-index.md`  
ADRs Reviewed: 13 — 13 Accepted  
Stories scanned for RTM: 68  
Automated test files scanned: 76

---

## Traceability Summary

| Metric | Count |
|---|---:|
| Total requirements | 201 |
| ✅ Covered | 131 |
| ⚠️ Partial | 70 |
| ❌ Gaps | 0 |

本轮相对 2026-06-28 的主要变化：

1. `TR-audio-001`–`TR-audio-006` 已由 `docs/architecture/adr-0013-audio-settings-event-consumption.md` 覆盖到 **Partial**；不再是 `NO ADR`。
2. `ADR-0012` / Random Event GDD 已把 `rule_version` 排除出 durable `event_settlement_key`。
3. `match_completed` envelope 已在 ADR-0002 / ADR-0006 / ADR-0009 / ADR-0010 统一为：

```gdscript
{
	"match_id": String,
	"settlement_id": String,
	"result_packet": Dictionary[String, Variant],
}
```

本轮已消除 `ADR-0012` / `ADR-0013` 的 Proposed 状态阻塞与 `NO ADR` 问题；剩余问题不是“缺 ADR”，而是 **Accepted ADR 集合内部仍有合同同步与边界澄清问题**。按严格复核口径，本报告保留 `FAIL`，直到以下阻塞项被修正：

- ADR-0002 / control manifest 的 EventBus-only 规则与 registry / Core ADR 中的 direct authority calls 冲突。
- ADR-0005 / ADR-0008 / architecture registry 对 facility multiplier 暴露面仍有 `get_effects()`、`compute_*()`、MVP 三输出三种口径。
- ADR-0013 已要求 `audio_state` 式注册持久化，但 ADR-0003 的 `SaveSnapshot` 与 load order 尚未同步。

---

## Traceability Matrix

| TR range | GDD | ADR Coverage | Status | RTM status | Notes |
|---|---|---|---|---|---|
| `TR-gameconcept-001`–`007` | `game-concept.md` | ADR-0002, ADR-0005, ADR-0006, ADR-0007, ADR-0011 | Covered | NO STORY | Concept-level requirements covered, not direct implementation stories. |
| `TR-balance-001`–`014` | `balance-system.md` | ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0008 | Covered | COVERED / NONE | Balance implementation evidence exists; diagnostics remain optional future concern. |
| `TR-save-001`–`014` | `save-and-load-system.md` | ADR-0003, ADR-0010 | Covered | COVERED / NO STORY | `TR-save-013`–`014` still need future Skill/Trait story coverage; ADR-0003 also needs synchronization if `audio_state` is accepted as durable save state. |
| `TR-time-001`–`008` | `time-and-season-progression-system.md` | ADR-0002, ADR-0003 | Covered | COVERED | TimeManager story/test chain exists. |
| `TR-playerdev-001`–`011` | `player-development-system.md` | ADR-0005, ADR-0007, ADR-0008, ADR-0003 | Covered | COVERED | Facility multiplier contract still needs canonical interface alignment. |
| `TR-match-001`–`017` | `match-competition-system.md` | ADR-0006, ADR-0005, ADR-0008, ADR-0007, ADR-0009, ADR-0010 | Covered | COVERED / NO STORY | `match_completed` envelope fixed; `TR-match-016`–`017` need stories. |
| `TR-economy-001`–`013` | `economy-management-system.md` | ADR-0007, ADR-0004, ADR-0003 | Covered | COVERED | Economy stories/tests exist; post-match idempotency should consume `settlement_id`. |
| `TR-town-001`–`019` | `town-building-system.md` | ADR-0008, ADR-0007, ADR-0004, ADR-0003 | Covered | COVERED | Town stories/tests exist; facility read-model surface must match ADR-0005 and registry. |
| `TR-skill-001`–`008` | `skill-and-trait-system.md` | ADR-0010, ADR-0003, ADR-0006 | Covered | NO STORY | Architecture exists; implementation stories absent. |
| `TR-league-001`–`014` | `league-competition-structure-system.md` | ADR-0009, ADR-0006, ADR-0007, ADR-0002 | Covered | COVERED / NO STORY | Minimum loop exists; league-specific stories remain sparse. |
| `TR-mainui-001`–`010` | `main-loop-ui-framework.md` | ADR-0001, ADR-0002, ADR-0010 | Partial | NONE / NO STORY | Deeper UI API/read-model boundary remains partial. |
| `TR-playerui-001`–`011` | `player-management-ui.md` | ADR-0001, ADR-0005, ADR-0010 | Partial | NONE / NO STORY | Read-model, feedback ack, and detail-boundary rows remain partial. |
| `TR-matchui-001`–`011` | `match-performance-ui.md` | ADR-0001, ADR-0006, ADR-0009, ADR-0010 | Partial | NONE / NO STORY | Live/result queue and no-recompute UI boundary remain partial. |
| `TR-reputation-001`–`006` | `reputation-and-achievement-system.md` | ADR-0011, ADR-0003 | Covered | NO STORY | Architecture exists; implementation stories absent. |
| `TR-onboard-001`–`010` | `onboarding-system.md` | ADR-0001, ADR-0002, ADR-0003 | Partial | NONE / NO STORY | Minimum guidance exists; persistence/full onboarding rows remain partial. |
| `TR-random-001`–`008` | `random-event-system.md` | ADR-0012 Accepted | Partial | NO STORY | ADR/GDD fixed key rule is now accepted; remaining gap is implementation story/test coverage. |
| `TR-audio-001`–`006` | `audio-system.md` | ADR-0013 Accepted | Partial | NO STORY | Audio no longer has an ADR gap; remaining gap is story/test coverage plus ADR-0003 persistence synchronization. |
| `TR-townui-001`–`007` | `town-management-ui.md` | ADR-0001, ADR-0008, ADR-0007, ADR-0010 | Partial | NO STORY | Needs town UI boundary/stories before deeper implementation. |
| `TR-tutorial-001`–`007` | `tutorial-and-hint-system.md` | ADR-0001, ADR-0002, ADR-0003, ADR-0010 | Partial | NO STORY | Needs hint durable state/cooldown/preferences/help-index boundary. |

---

## RTM Story and Test Linkage

| Test Status | Count | % |
|---|---:|---:|
| COVERED | 97 | 48.3% |
| MISSING | 0 | 0.0% |
| NONE | 28 | 13.9% |
| NO STORY | 76 | 37.8% |
| NO ADR | 0 | 0.0% |
| Total | 201 | 100.0% |

Interpretation:

- `MISSING = 0`：已声明的自动化测试文件均存在。
- `NO ADR = 0`：Audio ADR 已补上，Random Event / Audio 不再因 ADR 缺失而阻塞。
- Full-chain complete 仍为 `97/201 = 48.3%`，因为新增 ADR 尚未产生新增 story/test 链，且 UI / onboarding / tutorial 等 Presentation 边界仍为 Partial。

---

## Coverage Gaps

本轮没有 true `NO ADR` gap。

上一轮 6 条 Audio gap 现在改为 Partial：

- `TR-audio-001` — stable event consumption / no gameplay mutation
- `TR-audio-002` — playback eligibility and missing-asset degradation
- `TR-audio-003` — audio mixing formula
- `TR-audio-004` — durable audio settings
- `TR-audio-005` — same-window event priority/merge/delay/suppression
- `TR-audio-006` — low-pressure feedback constraints

Remaining issue: these rows are now architecturally governed, but they still cannot be counted as fully Covered until ADR-0003 persistence synchronization, story/test chains, and implementation evidence exist.

---

## Cross-ADR Conflicts

### 🔴 Blocking 1 — EventBus-only rule conflicts with registered direct authority calls

ADR-0002 and `control-manifest.md` state that EventBus is the sole communication channel for Foundation→Core, Core→Core, and Core→UI messages. However, `docs/registry/architecture.yaml` and several Core ADRs register or imply direct authority calls such as config access, roster/read-model access, economy transaction execution, and result packet consumption.

**Why this is a conflict:** the current documentation simultaneously supports two incompatible integration rules:

1. **Strict EventBus-only:** no system directly calls another system node/method.
2. **Hybrid authority model:** direct calls are allowed for accredited commands, read models, and single-writer state mutation, while EventBus carries notifications and asynchronous cross-system events.

**Impact:** implementers cannot know whether calls such as `EconomyManager.execute_transaction()`, `ConfigLoader` access, and authoritative read-model queries are valid architecture or control-manifest violations. Code review and story-done checks will be inconsistent.

**Resolution options:**

1. Prefer the hybrid authority model: revise ADR-0002 / control manifest wording so EventBus is the sole channel for broadcast notifications and event payloads, while accredited direct calls are allowed for registered command/query contracts.
2. Enforce true EventBus-only: remove or redesign registered direct-call contracts. This would require broad ADR and implementation rewrites and is not recommended for current architecture.

**Recommended fix:** adopt option 1 and update ADR-0002, `docs/architecture/control-manifest.md`, and `docs/registry/architecture.yaml` language together.

### 🔴 Blocking 2 — ADR-0005 / ADR-0008 facility multiplier interface remains non-canonical

ADR-0005 now describes PlayerDevelopment using an optional TownBuilding facility influence with neutral `1.0` fallback, but the concrete interface surface remains inconsistent across documents:

- ADR-0005 references a `TownBuilding.get_effects()`-style aggregate dictionary.
- ADR-0008 exposes `compute_*()` formula-style methods.
- `architecture.md` narrows the stable MVP outputs to `facility_training_multiplier`, `facility_total_maintenance`, and `home_advantage_bonus`.
- `docs/registry/architecture.yaml` still describes a broader `facility_bonuses` surface.

**Impact:** PlayerDevelopment, MatchCompetition, and EconomyManager do not have one canonical answer for whether they consume a dictionary read model, dedicated compute methods, or the three MVP stable outputs.

**Resolution:** keep the optional read-model + neutral fallback design, but explicitly name the canonical stable interface. Do not add a hard ADR-0005 → ADR-0008 dependency, because that risks an implicit dependency cycle.

**Recommended fix:** define a single stable read-model contract, for example:

- `TownBuilding.get_facility_effects() -> Dictionary[String, Variant]`, containing only registered stable keys; or
- explicit query methods for the three MVP outputs.

Then mirror the same choice in ADR-0005, ADR-0008, `architecture.md`, and `docs/registry/architecture.yaml`.

### 🔴 Blocking 3 — ADR-0013 audio persistence is accepted, but ADR-0003 SaveSnapshot/load order is not synchronized

ADR-0013 states that durable `audio_*` preferences are persisted through SaveManager using an `audio_state`-style registered boundary and two-phase restore. However, ADR-0003’s canonical `SaveSnapshot` fields and load order still list only the original core systems and do not include `audio_state` or a registered extension mechanism.

**Impact:** if implementers follow ADR-0003 literally, `AudioManager` will not participate in the canonical save/load restore path even though ADR-0013 says it must. This creates a conflict inside the Accepted ADR set.

**Resolution options:**

1. Add `audio_state` to the canonical ADR-0003 snapshot schema and load order.
2. Add an explicit registered durable-state extension mechanism to ADR-0003, where `audio_state` is one registered extension restored after core state.

**Recommended fix:** use option 2 if future systems may also need durable preferences; otherwise use option 1 for the narrow MVP audio scope. In either case, ADR-0003 and ADR-0013 must use the same vocabulary.

### ⚠️ Warning 1 — ADR-0013 semantic audio/UI events are not registered in ADR-0002

ADR-0013 expects normalized semantic UI/audio events, but ADR-0002’s EventBus registry has not been extended with those event names or registry rules.

**Resolution:** add an EventBus naming/registry extension or state that audio semantic events are local presentation events rather than global EventBus events.

### ⚠️ Warning 2 — ADR-0007 post-match economy flow must consistently consume `settlement_id`

The canonical `match_completed` envelope now includes `settlement_id`, and ADR-0007 has follow-through wording for idempotency metadata. During implementation, post-match reward settlement should consistently use `settlement_id` or derived transaction metadata as the processed key.

**Resolution:** keep ADR-0007 examples and story tests aligned with `settlement_id` idempotency.

---

## Resolved From Previous Review

### ✅ ADR-0012 stable key conflict resolved in ADR/GDD

ADR-0012 and Random Event GDD now exclude `rule_version` from durable `event_settlement_key`.

Residual fix completed in this review: `docs/architecture/tr-registry.yaml` aligns `TR-random-005` with ADR/GDD wording.

### ✅ `match_completed` canonical envelope resolved

ADR-0002 / ADR-0006 / ADR-0009 / ADR-0010 now converge on `match_id + settlement_id + result_packet`.

### ✅ ADR-0012 / ADR-0013 Proposed blockers resolved

Both ADR-0012 and ADR-0013 are now `Accepted`; stories should no longer be auto-blocked solely because these ADRs are Proposed.

### ✅ `architecture.md` no longer treats Random Event and Audio as missing ADRs

The architecture overview now references ADR-0012 and ADR-0013. Remaining architecture document issues are contract synchronization and Presentation boundary detail, not missing ADR inventory.

---

## ADR Dependency Order

Recommended practical order:

1. ADR-0001 — Scene Management & Autoload Architecture
2. ADR-0004 — Data-Driven Configuration
3. ADR-0002 — Event/Signal Architecture + TimeManager
4. ADR-0003 — Save/Load Persistence  
   - practical dependency: ADR-0004 before ADR-0003 because of `ConfigLoader.get_save_version()`
5. ADR-0005 — Player Data Model
6. ADR-0006 — Match Simulation Architecture
7. ADR-0007 — Economy Transaction Framework
8. ADR-0008 — Town Grid & Facility System
9. ADR-0009 — League Competition Structure
10. ADR-0013 — Audio Settings & Event Consumption (`Accepted`)
11. ADR-0010 — Cross-System Payload and Settlement Contracts
12. ADR-0011 — Reputation and Achievement Recognition Framework
13. ADR-0012 — Random Event Settlement Contracts (`Accepted`)

No explicit ADR dependency cycle found.

Potential implicit cycle if facility multiplier is fixed incorrectly:

```text
ADR-0005 → ADR-0008 → ADR-0007 → ADR-0006 → ADR-0005
```

Therefore facility multipliers should be modeled as optional read-model inputs with neutral fallback, not as a hard dependency from ADR-0005 to ADR-0008.

---

## Engine Compatibility Issues

Engine: Godot 4.6  
ADRs with Engine Compatibility section: 13 / 13

### Deprecated API References

- No blocking deprecated Godot API reference found in ADR decisions.
- Non-blocking stale tooling wording: ADR-0008 mentions GUT as the headless test path, while current project standard is the custom Godot headless script runner.

### Version Consistency

- No ADR targets an older engine version.
- No HIGH RISK Godot 4.6 API blocker found.

### Post-Cutoff API Findings

- `FileAccess.store_* -> bool` handling is correctly noted.
- `duplicate_deep()` references are reasonable where they avoid nested `Resource` copy pitfalls.
- UI-heavy ADRs should continue to account for Godot 4.6 dual-focus behavior; later ADRs already avoid treating transient hover/focus as authoritative semantic truth.

### Engine Specialist Findings

- ADR-0013 is feasible in Godot 4.6: `AudioServer` bus control, pooled `AudioStreamPlayer`, silent missing-asset degradation, and transient ducking/priority playback are all compatible.
- Typed `Dictionary[String, Variant]` boundaries are appropriate, but enforcement remains a project discipline issue rather than a Godot signal-level guarantee.
- No GDD revision flag is required from engine findings.

---

## GDD Revision Flags

No GDD revision flags — all GDD assumptions are consistent with verified engine behavior.

No `systems-index.md` update is required from engine findings.

---

## Architecture Document Coverage

`docs/architecture/architecture.md` is now substantially synchronized with ADR-0012 / ADR-0013, but the following follow-through remains relevant:

- Presentation API Boundaries remain partial for:
  - Main UI
  - Player UI
  - Match UI
  - Town Management UI
  - Onboarding
  - Tutorial/Hint
- The EventBus/direct-call architecture rule must be reconciled across ADR-0002, control manifest, and architecture registry.
- The PlayerDevelopment ↔ TownBuilding facility-multiplier interface must be made canonical across ADR-0005, ADR-0008, `architecture.md`, and registry.
- ADR-0003 must be synchronized with ADR-0013 if durable `audio_state` is an accepted SaveManager boundary.

---

## Verdict: FAIL

`NO ADR` gap 已降为 0，ADR-0012 / ADR-0013 也已进入 Accepted；但按严格架构一致性口径，本轮仍为 **FAIL**，因为 Accepted ADR 集合内部存在阻塞性合同冲突：

1. EventBus-only control rule conflicts with registered direct authority calls.
2. Facility multiplier interface remains non-canonical across ADR-0005 / ADR-0008 / registry / architecture overview.
3. ADR-0013 audio persistence boundary is accepted, but ADR-0003 SaveSnapshot/load order does not yet represent `audio_state` or registered durable-state extensions.

这些问题必须在依赖它们的 implementation stories 继续深入前收敛。Presentation API partial、NO STORY、NONE 测试链问题仍然重要，但它们是后续覆盖率与排期问题，不是本轮最核心的 FAIL 原因。

---

## Blocking Issues

1. Reconcile EventBus-only wording with registered direct-call authority contracts.
   - Update ADR-0002, `docs/architecture/control-manifest.md`, and `docs/registry/architecture.yaml` together.
2. Canonicalize the facility multiplier interface.
   - Update ADR-0005, ADR-0008, `architecture.md`, and registry so they name one stable read-model/query contract.
3. Synchronize ADR-0013 audio persistence with ADR-0003.
   - Either add `audio_state` to ADR-0003’s canonical snapshot/load order or define a registered durable-state extension mechanism that includes AudioManager.

---

## Required ADR / Documentation Fixes

1. Revise ADR-0002 and control manifest to distinguish EventBus notifications from accredited direct command/query contracts.
2. Revise ADR-0005 and ADR-0008 facility multiplier wording and registry interface contract.
3. Revise ADR-0003 / ADR-0013 persistence vocabulary and restore sequencing for durable audio settings.
4. Refresh `docs/architecture/architecture.md` after the above contract decisions.
5. Refresh `docs/architecture/architecture-traceability.md` and `docs/architecture/requirements-traceability.md` after contract changes.
6. Later, before deeper UI/tutorial implementation: create or extend UI API boundary ADRs and add story/test chains for NO STORY / NONE rows.

---

## Pre-gate Checklist

| Item | Status |
|---|---|
| `tests/unit/` and `tests/integration/` | ✅ |
| `.github/workflows/tests.yml` | ✅ |
| `design/accessibility-requirements.md` | ✅ |
| `design/ux/interaction-patterns.md` | ✅ |

Pre-gate infrastructure exists. `/gate-check pre-production` should still wait until blocking architecture contract issues are resolved.

---

## Handoff

Immediate actions:

1. Decide and document the cross-system communication rule: hybrid accredited direct calls + EventBus notifications, or true EventBus-only.
2. Canonicalize the TownBuilding facility multiplier read model consumed by PlayerDevelopment.
3. Synchronize ADR-0003 with ADR-0013 for durable audio settings persistence.

Re-run `/architecture-review` after each ADR/document correction to verify coverage improves.
