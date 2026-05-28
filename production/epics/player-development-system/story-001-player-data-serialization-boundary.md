# Story 001: 实现 Player / PlayerRoster 权威数据模型与序列化边界

> **Epic**: 运动员培养系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-28

## Context

**GDD**: `design/gdd/player-development-system.md`
**Requirement**: `TR-playerdev-001`, `TR-playerdev-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-playerdev-001`: Player must have: id, name, age, position, 5 attrs, train_efficiency, condition, morale, history, milestones
- `TR-playerdev-008`: Training gains survive save/load without loss or double-settlement

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0005: Player Data Model
**ADR Decision Summary**: Use `Player` as a `RefCounted`, `PlayerRoster` as the roster save boundary, and `PlayerDevelopment` as the Core system node that owns authoritative player state and save/load contracts.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `RefCounted`, `Resource`, and `Dictionary` serialization are stable Godot 4.x APIs; no post-cutoff API verification required.

**Control Manifest Rules (this layer)**:
- Required: Every Core system must register its serialization contract with `SaveManager` and restore only through the centralized load pipeline.
- Forbidden: Never serialize or persist derived player values such as `effective` or positional overall ratings.
- Guardrail: Roster serialization <50ms for a full roster; player runtime memory ~25KB target for roster structures.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/player-development-system.md`, scoped to this story:*

- [x] Player authoritative state includes id, name, age, position, five attributes, training efficiency, condition, morale, history, and milestones.
- [x] Derived values such as `effective` attributes and positional ratings are not persisted as authoritative state.
- [x] Training gains survive save/load without loss, player mismatch, or double settlement.

---

## Implementation Notes

*Derived from ADR-0005 Implementation Guidelines:*

Represent `Player` as a `RefCounted` runtime data object and `PlayerRoster` as a `Resource` that owns the collection and handles `serialize()` / `deserialize()` conversion. Persist only authoritative fields: identity, age, position, tier, `attributes.current`, `attributes.potential`, `training_efficiency`, `condition_multiplier`, `morale_multiplier`, `training_history`, `milestones`, and `total_training_sessions`. Do not persist `effective` or positional overall ratings.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: Training efficiency and condition/morale formula calculation.
- Story 006: Full training transaction atomicity with Economy and Time integration.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: Player 权威状态至少包含 id、name、age、position、5 attrs、training_efficiency、condition、morale、history、milestones。
  - Given: 一个 PlayerRoster 含 1 名已完整填充的球员，以上字段均有非默认值。
  - When: 执行一次保存快照并检查保存后的球员权威数据。
  - Then: 保存结果中每名球员都包含且仅包含该 AC 要求的长期权威字段，字段值与保存前一致。
  - Edge cases: history/milestones 为空时仍保留为空集合；多球员保存时按唯一 id 关联，不因 roster 顺序变化错位。

- **AC-2**: 派生值如 effective / positional rating 不得作为持久化权威字段保存。
  - Given: 运行时已能计算 effective rating / positional rating，且球员权威字段已保存前后可对比。
  - When: 执行保存并检查快照内容，再恢复一次数据。
  - Then: 快照中不存在派生值权威字段；恢复后派生值应由当前权威字段重新计算，不覆盖权威状态。
  - Edge cases: 旧快照若带有派生字段，应被忽略或隔离，不得污染当前权威字段；派生缓存缺失不影响恢复成功。

- **AC-3**: Save snapshot 与恢复后，球员长期成长状态不得丢失、错位或重复结算。
  - Given: 球员已发生多次训练成长，history 与 milestones 均非空，并已完成一次合法结算。
  - When: 保存快照、恢复，再对比恢复前后的长期成长状态。
  - Then: attrs、training_efficiency、history、milestones、age 等长期状态与保存时一致；恢复后不会重复应用已结算成长。
  - Edge cases: 同一快照重复读档不会重复增加属性或追加历史；多球员恢复时不会把成长记录串到其他球员。

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/player-dev/player_data_serialization_boundary_test.gd` OR playtest doc

**Status**: [x] Created — `tests/integration/player-dev/player_data_serialization_boundary_test.gd` + `tests/integration/player-dev/player_data_serialization_boundary_test.tscn`; Godot 4.6.2 headless result: `PLAYER_DATA_SERIALIZATION_BOUNDARY_TEST_PASS` (non-blocking exit warnings remain). Coverage includes authoritative exact-key boundary checks, empty history/milestones persistence, multi-player restore by id under reordered snapshots, and legacy derived-field ignore semantics.

---

## Dependencies

- Depends on:
  - `production/epics/balance-system/story-001-balance-config-validation.md` — must be DONE
  - `production/epics/save-and-load-system/story-002-save-registration-snapshot.md` — must be DONE
  - `production/epics/time-and-season-progression-system/story-001-time-manager-state-contract.md` — must be DONE
- Unlocks:
  - `production/epics/player-development-system/story-002-training-efficiency-formula.md`
  - `production/epics/player-development-system/story-003-training-gain-cap.md`
  - `production/epics/player-development-system/story-006-training-atomic-integration.md`
