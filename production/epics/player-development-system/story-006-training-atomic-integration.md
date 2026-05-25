# Story 006: 实现训练原子性与 Economy/Time 集成

> **Epic**: 运动员培养系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/player-development-system.md`
**Requirement**: `TR-playerdev-005`, `TR-playerdev-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-playerdev-005`: Training must be atomic: validate→deduct→grow→apply→emit
- `TR-playerdev-006`: Training costs via EconomyManager.accredit_training_cost() only

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0005: Player Data Model
**ADR Decision Summary**: `PlayerDevelopment.train()` is the authoritative training operation and must validate cost, deduct through accredited economy paths, compute and apply gains, advance time, record history, and emit events atomically.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `RefCounted`, `Resource`, and `Dictionary` serialization are stable Godot 4.x APIs; no post-cutoff API verification required.

**Control Manifest Rules (this layer)**:
- Required: Training operations must be atomic: validate cost, deduct through accredited economy path, compute gains, apply gains, advance time, record history, emit events.
- Forbidden: Never mutate Funds/AP/RP directly outside `execute_transaction()` / accredited paths.
- Guardrail: `execute_transaction()` <0.01ms; no Core system may exceed global frame budget assumptions when queried from UI.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/player-development-system.md`, scoped to this story:*

- [ ] Training flow executes in order: validate → deduct → grow → apply → emit.
- [ ] Training costs are deducted only through `EconomyManager.accredit_training_cost()`.
- [ ] Funds, AP, and time-window costs are committed before training settlement; failures do not partially apply growth, history, events, or resource changes.

---

## Implementation Notes

*Derived from ADR-0005 Implementation Guidelines:*

Implement `PlayerDevelopment.train(player_id, training_item_id)` as the single training operation boundary. Validate player and item first, call EconomyManager's accredited training cost path, compute gains, apply gains, advance TimeManager by the training item's time cost, record history, check milestones, and emit `player_training_completed` only after successful application.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 007: Milestone content and history summary behavior beyond the training operation hook.
- Economy system internals for transaction validation and resource floors.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 训练流程严格按 validate→deduct→grow→apply→emit 执行。
  - Given: 一次合法训练请求，且可观察各阶段执行顺序。
  - When: 执行训练流程。
  - Then: 五个阶段按 validate→deduct→grow→apply→emit 顺序各执行一次；任一阶段不得提前或跳序。
  - Edge cases: validate 失败时后续阶段全部不执行；emit 只能在 apply 成功后发生。

- **AC-2**: 训练成本仅通过 EconomyManager.accredit_training_cost() 扣除。
  - Given: 一次需要扣费的合法训练，且可观察所有经济写入入口。
  - When: 执行训练成本扣除。
  - Then: 仅调用 EconomyManager.accredit_training_cost() 完成训练成本扣除，不存在其他直接资金写入路径。
  - Edge cases: 失败重试不得双重扣费；零成本训练也不得绕过官方入口直接改余额。

- **AC-3**: 经费/AP/时间窗口三项扣除在训练结算前完成；失败时不得部分落地。
  - Given: 分别构造“经费不足”“AP 不足”“时间窗口非法”三类训练请求，以及一类全部满足条件的请求。
  - When: 执行训练流程。
  - Then: 合法请求在 grow/apply 前已完成经费、AP、时间窗口的前置扣除；任一前置条件失败时，不产生属性成长、历史记录、事件发射或部分资源落地。
  - Edge cases: 若失败发生在部分扣除之后，已发生的扣除必须回滚；失败后再次尝试不应继承脏状态。

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/player-dev/training_atomic_integration_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/player-development-system/story-003-training-gain-cap.md` — must be DONE
  - `production/epics/economy-management-system/story-007-accredited-entry-points.md` — must be DONE
- Unlocks:
  - `production/epics/player-development-system/story-007-player-milestone-history.md`
  - `production/epics/player-development-system/story-009-player-development-regression.md`
