# Story 005: 实现训练项目匹配、副属性成长与 ROI 计算样本

> **Epic**: 运动员培养系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-26

## Context

**GDD**: `design/gdd/player-development-system.md`
**Requirement**: `TR-playerdev-003`, `TR-playerdev-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-playerdev-003`: training_actual_gain = attribute_growth × fatigue × focus_match × facility_multiplier
- `TR-playerdev-007`: ap_to_funds_weight = 50 (from EconomyManager, not overridden locally)

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0005: Player Data Model
**ADR Decision Summary**: PlayerDevelopment applies training project modifiers on top of shared growth formulas while keeping resource valuation owned by EconomyManager.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `RefCounted`, `Resource`, and `Dictionary` serialization are stable Godot 4.x APIs; no post-cutoff API verification required.

**Control Manifest Rules (this layer)**:
- Required: Core systems must access config through typed `ConfigLoader` properties, not string-keyed lookups.
- Forbidden: Never mutate Funds/AP/RP directly outside `execute_transaction()` / accredited paths.
- Guardrail: No Core system may exceed the global frame budget assumptions when queried from UI.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/player-development-system.md`, scoped to this story:*

- [x] Matched training projects have `training_focus_match_multiplier >= 1.0`; mismatched projects have `<= 1.0`.
- [x] Primary attribute gain is at least secondary attribute total gain, and secondary gain total stays within 10%–35% of primary gain.
- [x] `player_development_roi` uses `ap_to_funds_weight` from EconomyManager, not a local override.
- [x] Short-term and mid-term ROI samples verify ordinary vs star-player tradeoffs or mark tuning failure.

---

## Implementation Notes

*Derived from ADR-0005 Implementation Guidelines:*

Use training item config to define target attributes, secondary attributes, raw growth input, focus multiplier, and declared costs. ROI may read EconomyManager's AP valuation but must not define or override it locally. Treat statistical ROI sample failures as tuning evidence, not formula rewrites inside this story.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006: Actual EconomyManager deduction and TimeManager advancement.
- Balance tuning changes if ROI samples fall outside target bands.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 匹配训练项目的 training_focus_match_multiplier ≥ 1.0；不匹配 ≤ 1.0。
  - Given: 同一球员分别选择“匹配训练项目”和“不匹配训练项目”两种训练。
  - When: 计算 training_focus_match_multiplier。
  - Then: 匹配项倍率 ≥ 1.0，不匹配项倍率 ≤ 1.0，且两者均取自训练项目配置。
  - Edge cases: 中性/通用项目可恰为 1.0；配置缺失时不得默认当作匹配项加成。

- **AC-2**: 主属性收益 ≥ 副属性合计收益，副属性合计占主属性 10%–35%。
  - Given: 一个定义了主属性与副属性的训练项目，且相关属性均有足够成长空间。
  - When: 执行一次训练成长结算并拆分主/副属性收益。
  - Then: 主属性收益不低于副属性总和，且副属性总和占主属性收益比例位于 10%–35%。
  - Edge cases: 若副属性因 cap 裁剪而下降，结果至少需标记为“cap-limited”，不得静默越界；无副属性配置时不得伪造副属性收益。

- **AC-3**: player_development_roi 使用 EconomyManager 提供的 ap_to_funds_weight，且本地不覆盖；普通与明星球员前/中期 ROI 样本可验证短期与长期差异目标，越界时标记调优失败。
  - Given: EconomyManager 提供固定 ap_to_funds_weight，且有“普通球员”“明星球员”两组 ROI 样本与目标区间。
  - When: 计算各样本在前期/中期的 player_development_roi。
  - Then: ROI 计算严格使用 EconomyManager 提供的权重；本地不存在覆盖权重；样本结果满足预期的短期/长期差异目标，超出目标区间时标记调优失败。
  - Edge cases: 缺少 ap_to_funds_weight 时应失败或复核；样本结果落在边界值上视为通过。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/player-dev/training_roi_test.gd` — must exist and pass

**Status**: [x] Test file created at `tests/unit/player-dev/training_roi_test.gd`; runtime verification passed locally via `tests/unit/player-dev/training_roi_runner.gd` with Godot 4.6.2 headless result `TRAINING_ROI_TEST_PASS` (non-blocking exit warnings remain)

**Review Note (2026-05-28)**: Runtime evidence is green. AC-3 coverage was strengthened to route `ap_to_funds_weight` through the EconomyManager authority seam and to assert ordinary-vs-star ROI sample tradeoffs directly from automated test samples, in addition to the existing ROI helper and tuning-failure coverage.

---

## Dependencies

- Depends on:
  - `production/epics/player-development-system/story-003-training-gain-cap.md` — must be DONE
  - `production/epics/player-development-system/story-004-player-tier-band.md` — must be DONE
- Unlocks:
  - `production/epics/player-development-system/story-009-player-development-regression.md`
