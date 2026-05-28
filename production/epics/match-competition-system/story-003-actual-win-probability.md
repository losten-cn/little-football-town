# Story 003: 实现实际胜率修正与战术/状态影响

> **Epic**: 比赛竞技系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-25

## Context

**GDD**: `design/gdd/match-competition-system.md`
**Requirement**: `TR-match-003`, `TR-match-014`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-match-003`: actual_win_probability = base + home + condition + tactical modifiers, clamped [0.05, 0.95]
- `TR-match-014`: Home advantage bonus consumed from TownBuilding.compute_home_advantage_bonus()

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0006: Match Simulation Architecture
**ADR Decision Summary**: MatchSimulation computes match-level win probability by applying home, tactical, condition, and event modifiers on top of the shared base win probability.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript state machine and Dictionary math; no post-cutoff APIs used.

**Control Manifest Rules (this layer)**:
- Required: Core systems must access config through typed `ConfigLoader` properties, not string-keyed lookups.
- Forbidden: Never implement match simulation as a one-shot black-box formula with no event flow.
- Guardrail: Full match simulation <20ms compute time target from ADR.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/match-competition-system.md`, scoped to this story:*

- [ ] `actual_win_probability = clamp(base_win_probability + home_advantage_mod + tactical_match_mod + condition_mod + event_mod, 0.05, 0.95)`.
- [ ] Home, tactical, and condition modifiers affect match probability in the expected direction and cannot exceed clamp boundaries.
- [ ] When team strength differs significantly, the stronger team has meaningfully higher win probability while the weaker team keeps non-zero upset chance.

---

## Implementation Notes

*Derived from ADR-0006 Implementation Guidelines:*

Use BalanceConfig's base win probability floor/ceiling and rating slope rather than redefining those shared values. Apply match-owned modifiers as additive probability terms, including non-facility home modifier, tactical matchup, condition aggregate, and event modifier. Facility home advantage is consumed through team strength where applicable.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: Event generation and event modifier production.
- Town Building stories: Computing home advantage bonus itself.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: `actual_win_probability = clamp(base + home + tactical + condition + event, 0.05, 0.95)`
  - Given: 一组可精确求和的固定输入，分别覆盖和小于 0.05、位于区间内、和大于 0.95 三种情况。
  - When: 计算 `actual_win_probability`。
  - Then: 输出分别被钳制为 0.05、原始和、0.95。
  - Edge cases: 修正项为负值；event 修正为 0；边界值恰好等于 0.05 或 0.95。

- **AC-2**: 主场/战术/状态修正按比赛层语义叠加，且不突破边界
  - Given: 两队基础胜率相同，并分别注入主场、战术优势、状态劣势等独立修正。
  - When: 单独启用与组合启用这些修正后比较结果。
  - Then: 每项修正都按预期方向影响最终胜率，组合后结果等于语义叠加并仍受 0.05..0.95 边界约束。
  - Edge cases: 正负修正相互抵消；客场且状态极差；强战术优势叠加后仍不能越界。

- **AC-3**: 明显强弱差距下强队胜率显著更高，但弱队仍有非零爆冷空间
  - Given: 一组强队与弱队存在明显实力差距的固定输入。
  - When: 计算双方实际胜率。
  - Then: 强队胜率显著高于弱队，且弱队胜率仍大于 0、不低于下界 0.05。
  - Edge cases: 极端实力差距；弱队拥有主场或战术克制时仍不可反转到不合理范围；双方接近时差距应缩小。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/match/actual_win_probability_test.gd` — must exist and pass

**Status**: [x] Created — tests/unit/match/actual_win_probability_test.gd

---

## Dependencies

- Depends on:
  - `production/epics/match-competition-system/story-002-team-strength-aggregation.md` — must be DONE
  - `production/epics/balance-system/story-006-win-probability.md` — must be DONE
- Unlocks:
  - `production/epics/match-competition-system/story-004-key-event-generation.md`
  - `production/epics/match-competition-system/story-007-match-rng-determinism.md`

## Completion Notes
**Completed**: 2026-05-25
**Criteria**: 3/3 passing
**Deviations**: None
**Test Evidence**: Logic: `tests/unit/match/actual_win_probability_test.gd`
**Code Review**: Approved
