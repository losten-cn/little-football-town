# Story 008: 实现读档恢复节点与下游推进边界

> **Epic**: 时间与赛季推进系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/time-and-season-progression-system.md`
**Requirement**: `TR-time-001`, `TR-time-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-time-001`: 7 game states: Planning through SeasonStart
- `TR-time-008`: TimeManager exposes get_state() for save snapshots

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0002: Event/Signal Architecture + TimeManager
**ADR Decision Summary**: TimeManager exposes `get_state()` for SaveManager snapshots and remains the sole authority for timeline, season, and key-node state.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Save/load boundary tests should use serializable Dictionaries and avoid runtime object references.

**Control Manifest Rules (this layer)**:
- Required: `TimeManager` must provide synchronous pull access (`get_state`) for save snapshots.
- Forbidden: Never let downstream systems directly modify timeline, season progress, or key-node state.
- Guardrail: Save/load total time: load <500ms for a full save.

**Performance Note**: This story must respect the applicable Foundation guardrails from the control manifest. No per-frame gameplay work is expected unless explicitly listed in the acceptance criteria.

**Asset / Resource References**:
- `.tres` is referenced for implementation context; if it is an output path, it does not need to exist before implementation.

---

## Acceptance Criteria

*From GDD `design/gdd/time-and-season-progression-system.md`, scoped to this story:*

- [ ] Save snapshots capture TimeManager state through `get_state()`.
- [ ] Restoring at stable nodes returns to the same verifiable node state.
- [ ] Half-complete key-node states are rejected or normalized to a verified stable node.
- [ ] Restored state does not replay already-completed key nodes or skip pending key nodes.
- [ ] Downstream attempts to directly mutate timeline, season progress, or key-node state are rejected or ignored.

---

## Implementation Notes

*Derived from ADR-0002 Implementation Guidelines:*

Expose controlled TimeManager APIs for save/restore and time progression. Downstream systems should request progression or consume events, not write internal timeline fields.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- SaveManager story details for `.tres` persistence, integrity hash, and migration.
- Downstream Core recovery behavior after time restoration.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 存档恢复基于 `TimeManager.get_state()` 的稳定快照
  - Given: 在合法稳定节点生成存档状态
  - When: 通过恢复流程还原 TimeManager
  - Then: 恢复后的 timeline、赛季进度、关键节点状态应与存档快照一致，并可继续正常推进
  - Edge cases: `Planning`、`SeasonStart`、`Offseason` 等稳定节点都应覆盖

- **AC-2**: 半完成节点不得被直接恢复为运行中态
  - Given: 存档数据对应半完成状态（如结算链中间态、未稳定落地的关键节点）
  - When: 执行恢复
  - Then: 系统必须拒绝该恢复，或将其规范化到经验证的稳定节点，不能恢复到“半完成节点”
  - Edge cases: `Match Trigger` 与 `Post-Match Settlement` 中间态要重点覆盖

- **AC-3**: 恢复后下游推进边界正确，不重放也不跳过
  - Given: 从稳定节点恢复后继续推进到下一个关键节点
  - When: 执行一次正常时间推进
  - Then: 不应重复发出已完成节点的事件，也不应跳过尚未处理的下一个节点
  - Edge cases: 恢复点紧邻比赛触发/赛季结算边界时必须覆盖

- **AC-4**: 下游系统不得直接篡改时间核心状态
  - Given: 下游系统持有 TimeManager 引用或收到时间事件
  - When: 尝试直接修改 timeline/season/key-node 状态
  - Then: 修改应被禁止、忽略或通过受控接口拒绝，时间状态只能由 TimeManager 驱动
  - Edge cases: 直接写字段、事件回调内回写、恢复后立即篡改都应失败

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/time/time_restore_boundary_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/time-and-season-progression-system/story-001-time-manager-state-contract.md` — must be DONE
  - `production/epics/time-and-season-progression-system/story-007-time-eventbus-integration.md` — must be DONE
- Unlocks:
  - Downstream work: Save/Load roundtrip stories and Core time-consumer stories
