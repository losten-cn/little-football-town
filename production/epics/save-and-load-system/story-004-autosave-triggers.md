# Story 004: 接入自动保存触发与延后保存队列

> **Epic**: 存档与读档系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/save-and-load-system.md`
**Requirement**: `TR-save-010`, `TR-save-005`, `TR-save-006`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-save-010`: Auto-save triggers: match_completed, time_season_ended, town_facility_completed, WM_CLOSE_REQUEST
- `TR-save-005`: Stable save nodes: Planning, Match Trigger, Post-Match Settlement, Stage Settlement, Season Settlement, Offseason
- `TR-save-006`: Match In Progress is NOT a stable save node

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0003: Save/Load Persistence
**ADR Decision Summary**: Autosave writes to a dedicated autosave slot on key long-term events, while preserving the same stable-node and consistency rules as manual save.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: Autosave trigger subscriptions should use EventBus-style decoupled events and remain headless-testable.

**Control Manifest Rules (this layer)**:
- Required: Event dispatch order follows the fixed priority chain and `SaveManager` is the sole disk writer.
- Forbidden: Never lower save consistency requirements for background/automatic saves.
- Guardrail: Save/load total time: load <500ms for a full save.

**Performance Note**: This story must respect the applicable Foundation guardrails from the control manifest. No per-frame gameplay work is expected unless explicitly listed in the acceptance criteria.

**Asset / Resource References**:
- `user://saves/autosave.tres` is a runtime save/output path, not a repository asset that must exist before implementation.

---

## Acceptance Criteria

*From GDD `design/gdd/save-and-load-system.md`, scoped to this story:*

- [ ] Autosave triggers on `match_completed`, `time_season_ended`, `town_facility_completed`, and `WM_CLOSE_REQUEST`.
- [ ] Autosave targets `user://saves/autosave.tres`.
- [ ] Autosave obeys the same stable-node gate as manual save.
- [ ] If triggered at an unstable node, save is delayed to the next stable node or rejected with clear semantics.
- [ ] Repeated deferred autosave requests coalesce into one latest-state autosave.

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

Wire autosave to declared events only. Autosave may be triggered by EventBus or Godot close notification, but must still pass stable-node, completeness, consistency, and commit validation before writing.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: Atomic commit and corruption detection.
- UI stories: player-facing save indicators or toast messages.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 指定事件必须触发自动保存流程
  - Given: 当前处于稳定节点
  - When: 依次触发 `match_completed`、`time_season_ended`、`town_facility_completed`、`WM_CLOSE_REQUEST`
  - Then: 每个事件都会发起一次 autosave，请求目标为 `user://saves/autosave.tres`
  - Edge cases: 同一帧多个事件、连续两次相同事件、无脏数据时的空保存请求

- **AC-2**: 非稳定节点触发自动保存时必须进入延后队列
  - Given: 当前运行节点为 `Match In Progress`
  - When: 触发任一 autosave 事件
  - Then: 不立即写盘，而是将 autosave 请求加入延后队列，直到进入下一个稳定节点再执行
  - Edge cases: 比赛中多次触发、长时间停留在非稳定节点、切回稳定节点前退出流程

- **AC-3**: 延后队列中的重复 autosave 请求应合并，最终只提交一次权威状态
  - Given: 队列中已存在待执行 autosave
  - When: 在到达稳定节点前再次触发多个 autosave 事件
  - Then: 队列不会无限增长，最终仅写入一次最新权威状态快照
  - Edge cases: 2 次触发、10 次触发、不同来源事件混合触发

- **AC-4**: `WM_CLOSE_REQUEST` 不得绕过稳定节点规则
  - Given: 收到关闭窗口事件
  - When: 当前分别处于稳定节点与 `Match In Progress`
  - Then: 稳定节点下立即 autosave；非稳定节点下不得写出无效快照，而是保持延后/失败语义
  - Edge cases: 关闭请求与结算切换同帧、已有待保存队列、关闭请求重复发送

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/save/autosave_triggers_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/save-and-load-system/story-003-stable-node-save-gate.md` — must be DONE
- Unlocks:
  - `production/epics/save-and-load-system/story-005-save-integrity-atomic-commit.md`
  - `production/epics/save-and-load-system/story-009-save-summary-performance.md`
