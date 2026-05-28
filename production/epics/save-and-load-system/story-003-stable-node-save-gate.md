# Story 003: 实现稳定节点判定与瞬时节点保存拦截

> **Epic**: 存档与读档系统
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: S
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/save-and-load-system.md`
**Requirement**: `TR-save-005`, `TR-save-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-save-005`: Stable save nodes: Planning, Match Trigger, Post-Match Settlement, Stage Settlement, Season Settlement, Offseason
- `TR-save-006`: Match In Progress is NOT a stable save node

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0003: Save/Load Persistence
**ADR Decision Summary**: Save/load only restores stable long-term progress; Match In Progress and other incomplete settlement states cannot be standard restore points.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: Stable-node gate should be deterministic and independent from UI confirmation flows.

**Control Manifest Rules (this layer)**:
- Required: `TimeManager` must provide synchronous pull access (`get_state`) for save snapshots.
- Forbidden: Never allow half-finished runtime states to be persisted as valid stable saves.
- Guardrail: Save/load total time: load <500ms for a full save.

**Performance Note**: This story must respect the applicable Foundation guardrails from the control manifest. No per-frame gameplay work is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/save-and-load-system.md`, scoped to this story:*

- [ ] `recoverable_stable_node = current_runtime_node ∈ stable_node_set`.
- [ ] Stable nodes include `Planning`, `Match Trigger`, `Post-Match Settlement`, `Stage Settlement`, `Season Settlement`, and `Offseason`.
- [ ] `Match In Progress` is not a stable save node.
- [ ] Unknown or incomplete settlement nodes are rejected by default.
- [ ] Rejected save requests do not proceed to snapshot assembly.

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

Use TimeManager state as the authority for runtime node semantics. This story only decides whether a save may proceed now; deferred save behavior is handled by Story 004.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 004: Autosave triggers and deferred save queue.
- Match Competition stories: defining internal match state machine details.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 稳定节点必须被判定为可恢复保存点
  - Given: 当前运行节点分别为 Planning、Match Trigger、Post-Match Settlement、Stage Settlement、Season Settlement、Offseason
  - When: 调用稳定节点判定
  - Then: `recoverable_stable_node = current_runtime_node ∈ stable_node_set` 为真，允许进入保存流程
  - Edge cases: 节点名称大小写、枚举值映射、边界节点切换瞬间

- **AC-2**: `Match In Progress` 必须被判定为不可保存
  - Given: 当前运行节点为 `Match In Progress`
  - When: 发起手动保存或自动保存
  - Then: 判定结果为假，保存被拦截，不生成快照
  - Edge cases: 比赛开始前 1 帧、比赛结束后结算前、暂停状态下仍处于比赛中

- **AC-3**: 未知节点或瞬时节点默认不可保存
  - Given: 当前运行节点不在稳定节点集合中
  - When: 发起保存
  - Then: 系统返回不可恢复/不可保存结果，并阻止后续快照组装
  - Edge cases: 新增节点未登记、拼写错误节点、`null`/未初始化节点

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/save/stable_node_save_gate_test.gd` — must exist and pass

**Status**: [x] Created — `tests/unit/save/stable_node_save_gate_test.gd` (runtime verified with `STABLE_NODE_SAVE_GATE_TEST_PASS`)

---

## Dependencies

- Depends on: None
- Unlocks:
  - `production/epics/save-and-load-system/story-004-autosave-triggers.md`
  - `production/epics/save-and-load-system/story-005-save-integrity-atomic-commit.md`

## Completion Notes
**Completed**: 2026-05-27
**Criteria**: 5/5 passing
**Deviations**: None
**Test Evidence**: Logic test at `tests/unit/save/stable_node_save_gate_test.gd` (runtime verified with `STABLE_NODE_SAVE_GATE_TEST_PASS`)
**Code Review**: Complete (`APPROVED WITH SUGGESTIONS`)
