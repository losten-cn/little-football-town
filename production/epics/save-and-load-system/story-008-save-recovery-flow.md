# Story 008: 实现存档恢复失败与玩家风险操作语义

> **Epic**: 存档与读档系统
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-28

## Context

**GDD**: `design/gdd/save-and-load-system.md`
**Requirement**: `TR-save-001`, `TR-save-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-save-001`: SaveManager is the sole disk writer
- `TR-save-008`: Save integrity verified via hash checksum

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0003: Save/Load Persistence
**ADR Decision Summary**: Corrupted, missing, unsupported, or failed-migration saves must not silently load; `SaveManager` exposes clear failure semantics for UI recovery and deletion flows.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: Recovery should be testable without UI by returning structured outcomes that UI can display.

**Control Manifest Rules (this layer)**:
- Required: `SaveManager` is the sole disk writer and uses integrity mismatch recovery/deletion flows.
- Forbidden: Never allow damaged or partial snapshots to become playable authority state.
- Guardrail: Save/load total time: load <500ms for a full save.

**Performance Note**: This story must respect the applicable Foundation guardrails from the control manifest. No per-frame gameplay work is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/save-and-load-system.md`, scoped to this story:*

- [x] Missing fields, hash mismatch, unsupported version, or failed migration routes to Recovery instead of State Restore.
- [x] Load failure leaves the current valid runtime state unchanged.
- [x] Covering, deleting, or loading over unsaved long-term progress exposes explicit structured risk semantics.
- [x] Cancelled risk operations do not modify disk state or runtime state.
- [x] Recovery uses only valid snapshots; corrupted saves are not silently repaired into authority state.

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

Implement structured failure results such as missing, corrupted, unsupported, migration_failed, overwrite_requires_confirmation, and delete_requires_confirmation. UI owns wording, but `SaveManager` owns the operation semantics.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- UI stories: visual confirmation dialogs and player-facing copy.
- Cloud sync or long backup chains beyond MVP local recovery baseline.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 读档失败时必须保持当前运行状态不变
  - Given: 当前已有一局正在运行的有效会话，目标槽位为损坏或不完整存档
  - When: 玩家尝试读取该槽位
  - Then: 读档失败被明确报告，当前运行状态保持不变，不进入半恢复状态
  - Edge cases: 哈希损坏、缺字段、资源类型错误

- **AC-2**: 对玩家风险操作必须给出明确风险语义与确认步骤
  - Given: 目标槽位已损坏、恢复失败或存在未完成 autosave
  - When: 玩家尝试覆盖该槽位、删除该槽位、或继续执行会丢失当前机会的高风险操作
  - Then: 系统必须提示风险并要求显式确认，不能静默继续
  - Edge cases: 覆盖损坏槽位、删除唯一手动存档、失败后立即退出

- **AC-3**: 玩家取消风险操作时，不得发生任何磁盘或运行时变更
  - Given: 风险确认弹窗已出现
  - When: 玩家选择取消/返回
  - Then: 槽位文件、当前会话状态、待保存队列均保持原样
  - Edge cases: 已进入覆盖流程前一步、重复取消、多次打开同一确认流程

- **AC-4**: 玩家确认后的恢复路径必须只使用有效快照，不得静默“修复”损坏存档
  - Given: 一个损坏槽位与一个可用替代槽位/安全路径
  - When: 玩家确认执行恢复相关操作
  - Then: 系统只加载或保留有效快照，损坏文件仅作为失败对象处理，不被静默当作成功恢复
  - Edge cases: 替代槽位存在、无替代槽位、确认后再次校验失败

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/save/save_recovery_flow_test.gd` OR playtest doc

**Status**: [x] Created and verified — SAVE_RECOVERY_FLOW_TEST_PASS

---

## Dependencies

- Depends on:
  - `production/epics/save-and-load-system/story-005-save-integrity-atomic-commit.md` — must be DONE
  - `production/epics/save-and-load-system/story-006-save-migration.md` — must be DONE
  - `production/epics/save-and-load-system/story-007-load-restore-order.md` — must be DONE
- Unlocks:
  - Downstream work: Save/Load UI confirmation and recovery stories

## Completion Notes
**Completed**: 2026-05-28
**Criteria**: 5/5 passing
**Deviations**: Advisory only — headless verification uses `tests/integration/save/save_recovery_flow_runner.gd` to host the Node-based integration test, while the evidence file remains `tests/integration/save/save_recovery_flow_test.gd`.
**Test Evidence**: Integration test at `tests/integration/save/save_recovery_flow_test.gd` — PASS via `tests/integration/save/save_recovery_flow_runner.gd` (`SAVE_RECOVERY_FLOW_TEST_PASS`)
**Code Review**: Complete — no blocking issues
