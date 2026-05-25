# Story 006: 实现版本兼容判定与 additive-forward 迁移

> **Epic**: 存档与读档系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/save-and-load-system.md`
**Requirement**: `TR-save-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-save-007`: Version migration: additive-forward only, no field deletion

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0003: Save/Load Persistence
**ADR Decision Summary**: Saves carry `save_version`; migration is additive-forward only, with no deletion or rename of persisted fields.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: Migration tests should use fixed sample snapshots and verify migrated snapshots pass the same integrity and consistency checks as current saves.

**Control Manifest Rules (this layer)**:
- Required: Save migrations must be additive-forward; increment `save_version` only when schema changes.
- Forbidden: Never silently load unsupported or structurally incompatible saves.
- Guardrail: Save/load total time: load <500ms for a full save.

**Performance Note**: This story must respect the applicable Foundation guardrails from the control manifest. No per-frame gameplay work is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/save-and-load-system.md`, scoped to this story:*

- [ ] Same-version saves load without migration.
- [ ] Older supported saves migrate forward by adding fields and safe defaults only.
- [ ] Migrated saves pass field completeness and consistency validation before restore.
- [ ] Future or unsupported version gaps are rejected with clear failure semantics.
- [ ] Migration never deletes or renames existing persisted fields.

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

Use `ConfigLoader.get_save_version()` as the current save schema version. Implement migration as a stepwise loop from stored version to current version. Add fields only; preserve old fields even if deprecated.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: User-facing recovery/deletion choices when migration fails.
- Future content migrations not yet represented by a schema change.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 同版本快照应直接通过兼容检查并完成加载
  - Given: 快照版本与当前运行版本一致
  - When: 执行加载
  - Then: 不触发迁移流程，快照按原结构完成恢复
  - Edge cases: 补丁版本一致、元数据顺序不同、存在可忽略附加字段

- **AC-2**: 旧版本快照可通过 additive-forward 迁移补齐新增字段
  - Given: 一个缺少“新版本新增字段”但未删除旧字段的历史快照
  - When: 执行迁移并加载
  - Then: 迁移仅新增缺失字段并填入默认值/迁移值，原有字段数据保持不变
  - Edge cases: 新增 1 个字段、新增多个嵌套字段、默认值来自配置

- **AC-3**: 含未来新增字段的快照在不缺 required fields 时应保持可读
  - Given: 快照包含当前版本未知的附加字段，但当前 required fields 完整
  - When: 执行兼容检查与加载
  - Then: 未知附加字段不会导致加载失败，当前系统能恢复自身所需的权威状态
  - Edge cases: 多个未知字段、未知嵌套块、字段顺序变化

- **AC-4**: 非 additive-forward 的破坏性变更必须被拒绝
  - Given: 快照缺失当前 required field，或迁移需要删除/改写已有字段语义
  - When: 执行兼容检查
  - Then: 系统返回“不兼容/不可迁移”，不得继续反序列化
  - Edge cases: 必需字段被删除、字段类型不兼容、版本号伪装但结构已破坏

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/save/save_migration_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/save-and-load-system/story-005-save-integrity-atomic-commit.md` — must be DONE
- Unlocks:
  - `production/epics/save-and-load-system/story-007-load-restore-order.md`
  - `production/epics/save-and-load-system/story-008-save-recovery-flow.md`
