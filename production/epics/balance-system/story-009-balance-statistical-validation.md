# Story 009: 验证数值公式可复核性与随机统计边界

> **Epic**: 数值系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/balance-system.md`
**Requirement**: GDD random/statistical/manual verification acceptance criteria
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- GDD scoped acceptance criterion 1: A fixed deterministic input where object A is stronger than object B can be repeated 1000 times with only random terms varying.
- GDD scoped acceptance criterion 2: Random terms stay inside the GDD-defined range.
- GDD scoped acceptance criterion 3: A wins at least `0.95` of trials when deterministic strength advantage requires that outcome.
- GDD scoped acceptance criterion 4: Manual verification samples for effective attributes, growth, resource settlement, position rating, and win probability match system output.

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0004: Data-Driven Configuration
**ADR Decision Summary**: Balance formulas and parameters are data-driven and centrally loaded, allowing deterministic test fixtures and repeatable statistical validation.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: Statistical validation must use deterministic seeds and headless-friendly tests where automation is possible.

**Control Manifest Rules (this layer)**:
- Required: All gameplay tuning must load through `ConfigLoader` from typed Custom Resources under `res://config/`; invalid config must block startup.
- Forbidden: Never define gameplay tuning as inline constants in `src/`.
- Guardrail: Config load for all config resources combined must stay under 50ms.

**Performance Note**: This story must respect the applicable Foundation guardrails from the control manifest. No per-frame gameplay work is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/balance-system.md`, scoped to this story:*

- [ ] A fixed deterministic input where object A is stronger than object B can be repeated 1000 times with only random terms varying.
- [ ] Random terms stay inside the GDD-defined range.
- [ ] A wins at least `0.95` of trials when deterministic strength advantage requires that outcome.
- [ ] Manual verification samples for effective attributes, growth, resource settlement, position rating, and win probability match system output.
- [ ] Illegal inputs are normalized before formula use and repeated calculations are stable.
- [ ] Same initial state, total duration, and total resources produce identical aggregate results regardless of atomic operation order.

---

## Implementation Notes

*Derived from ADR-0004 Implementation Guidelines:*

Use config-backed formulas and deterministic test seeds. This story validates formula reproducibility and balance-review evidence; it does not implement full MatchCompetition simulation or downstream game loops.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Match Competition stories: full seeded match simulation and key events.
- Full MVP playtest evidence for reputation Lv.3/Lv.10 targets, which belongs after those systems exist.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 1000 次模拟的统计均值必须落在理论值容差内
  - Given: 固定一组输入，理论 `base_win_probability` 已知
  - When: 运行 1000 次模拟并统计实际胜率均值
  - Then: 实际均值与理论值偏差不超过 `±0.05`，且强者胜出比例满足 GDD 统计要求
  - Edge cases: 理论值接近 `0.05/0.95` 时仍应满足容差；随机种子变化不应导致系统性偏移

- **AC-2**: 公式输出必须支持人工复核，且中间步骤与最终结果一致
  - Given: 提供一组可手算样本，覆盖 effective、growth、resource settlement、win probability
  - When: 用文档/表格按公式逐步复核
  - Then: 人工计算结果与程序输出一致，且能看出“先 flat 后 percent”“最后 clamp”等关键步骤
  - Edge cases: 浮点保留位数需一致；中间步骤缺失、顺序不透明或结果不可追溯应判失败

- **AC-3**: 非法输入在归一化后必须稳定、可重复、不中断
  - Given: 输入包含负属性、超上限属性、NaN modifier、非法资源范围、缺失权重等异常值
  - When: 对同一组归一化后的输入重复执行 100 次
  - Then: 输出稳定一致，不崩溃，不出现 NaN/Inf
  - Edge cases: 多种非法值同时出现时仍应稳定；同一非法输入不得在不同运行中产生不同结果

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/balance/balance_statistical_validation_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/balance-system/story-006-win-probability.md` — must be DONE
  - `production/epics/balance-system/story-007-kpi-formulas.md` — must be DONE
- Unlocks:
  - Downstream work: Balance playtest evidence and downstream simulation validation
