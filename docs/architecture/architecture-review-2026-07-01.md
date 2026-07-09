# Architecture Review Report

Date: 2026-07-01  
Engine: Godot 4.6  
Mode: `/architecture-review full`  
Review posture: post-convergence follow-up review after authority-contract and interface-canonicalization cleanup  
GDDs Reviewed: 20, including `design/gdd/systems-index.md`  
ADRs Reviewed: 13 — 13 Accepted  
Stories scanned for RTM: 69  
Automated test files scanned: 76

---

## Traceability Summary

| Metric | Count |
|---|---:|
| Total requirements | 201 |
| ✅ Covered | 131 |
| ⚠️ Partial | 70 |
| ❌ Gaps | 0 |

本轮相对 2026-06-29 的主要变化：

1. EventBus / direct-call 规则已统一为 **registered hybrid authority model**。
2. TownBuilding 对跨系统 MVP consumption 的 facility interface 已收敛为 **canonical three-query surface**。
3. ADR-0003 / ADR-0013 的 `audio_state` persistence vocabulary 与 two-phase restore 维持一致。
4. scene-instantiated Core authority node 的 direct-call access rule 已补齐：
   - authority reference 必须来自 gameplay-root injection 或 scene-owned service container/runtime registry；
   - 禁止 implicit global `class_name` pseudo-singleton、hardcoded `NodePath`、arbitrary scene-tree search。

因此，本轮未发现新的 true `NO ADR` gap，也未保留上一轮的 blocking cross-ADR contract conflict。当前问题已主要转化为 partial coverage、story/test linkage、以及 implementation follow-through concerns。

---

## Traceability Matrix

| TR range | GDD | ADR Coverage | Status | RTM status | Notes |
|---|---|---|---|---|---|
| `TR-gameconcept-001`–`007` | `game-concept.md` | ADR-0002, ADR-0005, ADR-0006, ADR-0007, ADR-0011 | Covered | NO STORY | Concept-level requirements are architecture-covered but not implemented as direct stories. |
| `TR-balance-001`–`014` | `balance-system.md` | ADR-0004, ADR-0005, ADR-0006, ADR-0007, ADR-0008 | Covered | COVERED / NONE | Formula/config coverage exists; some evidence remains non-automated by story type. |
| `TR-save-001`–`014` | `save-and-load-system.md` | ADR-0003, ADR-0010 | Covered | COVERED / NO STORY | Skill/Trait-specific save/load rows still need future story coverage. |
| `TR-time-001`–`008` | `time-and-season-progression-system.md` | ADR-0002, ADR-0003 | Covered | COVERED | TimeManager story/test chain exists. |
| `TR-playerdev-001`–`011` | `player-development-system.md` | ADR-0005, ADR-0007, ADR-0008, ADR-0003 | Covered | COVERED | Facility multiplier contract is now canonicalized; implementation must still follow injected authority-reference rules. |
| `TR-match-001`–`017` | `match-competition-system.md` | ADR-0006, ADR-0005, ADR-0008, ADR-0007, ADR-0009, ADR-0010 | Covered | COVERED / NO STORY | `match_completed` envelope remains canonical; deeper late-slice rows still need stories. |
| `TR-economy-001`–`013` | `economy-management-system.md` | ADR-0007, ADR-0004, ADR-0003 | Covered | COVERED | Accredited transaction path exists; authority reference rule now needs implementation follow-through only. |
| `TR-town-001`–`019` | `town-building-system.md` | ADR-0008, ADR-0007, ADR-0004, ADR-0003 | Covered | COVERED | TownBuilding public cross-system surface is now narrowed to canonical MVP outputs. |
| `TR-skill-001`–`008` | `skill-and-trait-system.md` | ADR-0010, ADR-0003, ADR-0006 | Covered | NO STORY | Architecture exists; implementation stories remain absent. |
| `TR-league-001`–`014` | `league-competition-structure-system.md` | ADR-0009, ADR-0006, ADR-0007, ADR-0002 | Covered | COVERED / NO STORY mix | Minimum league loop exists; broader league story coverage remains sparse. |
| `TR-mainui-001`–`010` | `main-loop-ui-framework.md` | ADR-0001, ADR-0002, ADR-0010 | Partial | NONE / NO STORY | Presentation API boundary still needs deepening. |
| `TR-playerui-001`–`011` | `player-management-ui.md` | ADR-0001, ADR-0005, ADR-0010 | Partial | NONE / NO STORY | Read-model and UI boundary depth remain partial. |
| `TR-matchui-001`–`011` | `match-performance-ui.md` | ADR-0001, ADR-0006, ADR-0009, ADR-0010 | Partial | NONE / NO STORY | Live/result presentation rules still need deeper formalization. |
| `TR-reputation-001`–`006` | `reputation-and-achievement-system.md` | ADR-0011, ADR-0003 | Covered | NO STORY | Durable truth and reward model exist; implementation stories not yet scheduled. |
| `TR-onboard-001`–`010` | `onboarding-system.md` | ADR-0001, ADR-0002, ADR-0003 | Partial | NONE / NO STORY | Minimum guidance exists; persistence/anchor details remain partial. |
| `TR-random-001`–`008` | `random-event-system.md` | ADR-0012 Accepted | Partial | NO STORY | Accepted architecture exists; story/test coverage and implementation evidence remain future work. |
| `TR-audio-001`–`006` | `audio-system.md` | ADR-0013 Accepted | Partial | NO STORY | Accepted architecture exists; story/test coverage and runtime verification remain future work. |
| `TR-townui-001`–`007` | `town-management-ui.md` | ADR-0001, ADR-0008, ADR-0007, ADR-0010 | Partial | NO STORY | Town UI implementation boundary remains partial. |
| `TR-tutorial-001`–`007` | `tutorial-and-hint-system.md` | ADR-0001, ADR-0002, ADR-0003, ADR-0010 | Partial | NO STORY | Hint durability, cooldown, and help-index rows remain partial. |

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

- `MISSING = 0`：所有已声明的自动化测试路径都存在。
- `NO ADR = 0`：本轮没有 architecture-gap 级 requirement。
- Full-chain coverage 仍停在 `97/201 = 48.3%`，主要原因是：
  - Partial Presentation boundaries；
  - accepted-but-unscheduled systems；
  - Random Event / Audio / Reputation / SkillTrait / Tutorial 等仍未进入完整实施链。

---

## Coverage Gaps

本轮没有 true `NO ADR` gap。

当前未闭环的主要问题类型不是“缺 ADR”，而是：

1. **Partial architecture boundary**
   - Main UI
   - Player UI
   - Match UI
   - Town UI
   - Onboarding
   - Tutorial / Hint

2. **NO STORY**
   - SkillTrait
   - ReputationAchievement
   - Random Event
   - Audio
   - Town UI
   - Tutorial / Hint
   - league / match / save 的部分后续 requirement

3. **Implementation follow-through**
   - registered direct-call authority reference wiring
   - TownBuilding canonical three-query surface 的实际 wiring
   - Audio runtime restore / bus validation / UI semantic event consumption
   - Random Event stable-window + idempotency + restore path

---

## Cross-ADR Conflicts

### ✅ Resolved — EventBus-only vs direct-call authority conflict

上一轮 blocker 是：ADR-0002 / control manifest 接近 EventBus-only，而 registry 同时登记多条 `direct_call` contract。

当前状态：

- ADR-0002 已定义 registered hybrid authority model；
- control manifest 已同步；
- registry 已说明 EventBus 路由 notifications / async events，而 accepted `direct_call` contracts 仅作为 explicit authority command/query boundaries。

**Result:** resolved.

### ✅ Resolved — facility multiplier interface ambiguity

上一轮 blocker 是：ADR-0005、ADR-0008、`architecture.md`、registry 同时存在 `get_effects()`、`compute_*()`、MVP 三输出三种口径。

当前状态：

- TownBuilding 对跨系统 MVP consumption 明确只暴露：
  - `get_facility_training_multiplier(player_age: int)`
  - `get_facility_total_maintenance()`
  - `get_home_advantage_bonus()`
- ADR-0005 / ADR-0008 / `architecture.md` / registry 已同步这一 canonical surface。
- optional read-model + neutral `1.0` fallback 保留不变。

**Result:** resolved.

### ✅ Resolved — audio persistence alignment

上一轮 blocker 是：ADR-0013 需要 `audio_state` + two-phase restore，而 ADR-0003 的持久化 vocabulary / extension phase 描述不足。

当前状态：

- ADR-0003 已明确 `durable_extensions` 与 `audio_state`；
- ADR-0013 的 `audio_state` restore 与 ADR-0003 extension restore phase 一致；
- registry 使用同一 vocabulary。

**Result:** resolved.

### ✅ Resolved — Godot scene-instantiated authority reference ambiguity

上一轮 blocker 是：registered direct-call 已允许，但没有说明非 Autoload Core authority node 如何在 Godot scene-tree 中稳定获取实例。

当前状态：

- ADR-0002 明确：
  - gameplay-root injection / scene-owned service container/runtime registry
- control manifest 已禁止：
  - implicit global `class_name` pseudo-singleton
  - hardcoded `NodePath`
  - arbitrary scene-tree search
- ADR-0005 / 0006 / 0007 / 0008 已补到 ADR 正文
- registry 对关键 direct-call contracts 已加 stable authority reference rule

**Result:** resolved.

---

## ADR Dependency Order

Recommended practical order:

1. ADR-0001 — Scene Management & Autoload Architecture
2. ADR-0004 — Data-Driven Configuration
3. ADR-0002 — Event/Signal Architecture + TimeManager
4. ADR-0003 — Save/Load Persistence
5. ADR-0005 — Player Data Model
6. ADR-0006 — Match Simulation Architecture
7. ADR-0007 — Economy Transaction Framework
8. ADR-0008 — Town Grid & Facility System
9. ADR-0009 — League Competition Structure
10. ADR-0013 — Audio Settings & Event Consumption
11. ADR-0010 — Cross-System Payload and Settlement Contracts
12. ADR-0011 — Reputation and Achievement Recognition Framework
13. ADR-0012 — Random Event Settlement Contracts

No explicit ADR dependency cycle found.  
No currently blocking implicit cycle remains after the facility-interface and authority-reference cleanup.

---

## Engine Compatibility Issues

Engine: Godot 4.6  
ADRs with Engine Compatibility section: 13 / 13

### Deprecated API References

- No blocking deprecated Godot API reference found in the accepted ADR body.
- No architecture-level adoption of forbidden deprecated patterns such as:
  - `yield()`
  - `instance()`
  - string-based `connect("signal", ...)`
  - deprecated `TileMap`

### Version Consistency

- No ADR targets an older engine version.
- No stale engine-version divergence found.

### Post-Cutoff API Findings

- `FileAccess.store_* -> bool` risk is correctly recorded in save/load-related ADRs.
- `duplicate_deep()` / `@abstract` references remain implementation verification concerns, not architecture blockers.
- Godot 4.6 dual-focus behavior is properly reflected in UI / Random Event / Audio-related ADR boundaries.
- The authority-reference access rule is now compatible with Godot scene-tree / lifecycle expectations.

### Engine Specialist Findings

- No remaining FAIL-level engine blocker after the authority-reference rule was added to ADRs and synchronized first-layer architecture documents.
- Remaining engine follow-through should be verified in implementation stories:
  - injection / service-container wiring
  - load/ready sequencing
  - UI semantic event normalization
  - audio bus/runtime-apply timing

---

## GDD Revision Flags

No GDD revision flags — all GDD assumptions remain consistent with verified engine behavior and the accepted ADR set.

No `systems-index.md` update is required from this review.

---

## Architecture Document Coverage

`docs/architecture/architecture.md` is now materially synchronized with the accepted ADR set and the recent authority-contract convergence:

- Random Event and Audio are no longer treated as missing ADRs.
- EventBus / direct-call hybrid authority rule is reflected in Ownership Rules.
- TownBuilding canonical MVP outputs are reflected in Core API boundaries.
- direct-call authority access is now bounded by injected/stable reference rules.

Remaining document-level concerns:

- Presentation API boundaries remain partial for:
  - Main UI
  - Player UI
  - Match UI
  - Town UI
  - Onboarding
  - Tutorial / Hint
- Story/test follow-through remains sparse for:
  - Random Event
  - Audio
  - ReputationAchievement
  - SkillTrait
  - Tutorial / Hint
- Review / traceability derivatives are still stale and should be refreshed after approval.

---

## Verdict: CONCERNS

`NO ADR` gap remains 0, and the previous contract-level blockers have now been resolved in the accepted ADR set and synchronized first-layer architecture sources.

The architecture therefore no longer warrants `FAIL`.

However, it should not be marked `PASS` yet, because:

1. 70 requirements remain only **Partial** at the architecture-boundary level.
2. 76 requirements remain **NO STORY**.
3. 28 requirements remain **NONE** in automated test-chain linkage by story type.
4. Several important systems are architecture-covered but still require implementation follow-through:
   - Random Event
   - Audio
   - Skill / Trait
   - Reputation / Achievement
   - Presentation-layer APIs
5. Review / traceability derivatives have not yet been refreshed to reflect the newly converged source-of-truth documents.

Therefore the correct gate posture is now:

> **CONCERNS — architecture blockers cleared, but coverage depth and implementation traceability remain incomplete.**

---

## Blocking Issues (must resolve before PASS)

There are no remaining `FAIL`-level blocking cross-ADR conflicts.

To move from `CONCERNS` to `PASS`, the highest-priority issues are:

1. Deepen Presentation API boundary coverage.
2. Add story/test chains for currently architecture-covered but unscheduled systems.
3. Refresh formal architecture review / traceability outputs so the project’s derived evidence matches the accepted ADR body.

---

## Required ADRs

No new blocker ADR is required before continuing.

Priority follow-through work is not “write missing ADRs” but:

1. Refresh architecture review / traceability artifacts.
2. Schedule implementation stories for accepted-but-unscheduled systems.
3. Add verification coverage for authority-injection wiring and runtime restore rules.

---

## Pre-gate Checklist

| Item | Status |
|---|---|
| `tests/unit/` and `tests/integration/` | ✅ |
| `.github/workflows/tests.yml` | ✅ |
| `design/accessibility-requirements.md` | ✅ |
| `design/ux/interaction-patterns.md` | ✅ |

All pre-gate infrastructure items are present.

---

## Handoff

### Immediate actions

1. Refresh the formal review artifact to reflect the new `CONCERNS` verdict.
2. Refresh `architecture-traceability.md` and `requirements-traceability.md` so they align with the converged ADR set.
3. Prioritize implementation stories for accepted-but-unscheduled systems:
   - Random Event
   - Audio
   - Skill / Trait
   - Reputation / Achievement
   - Presentation API slices

### Rerun trigger

Re-run `/architecture-review` after:

- refreshing the formal report and traceability artifacts, or
- landing any new ADR/document changes that affect authority contracts or presentation boundaries.
