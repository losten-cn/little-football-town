# Story 001: 建立 SaveSnapshot 与存档槽结构

> **Epic**: 存档与读档系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/save-and-load-system.md`
**Requirement**: `TR-save-001`, `TR-save-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-save-001`: SaveManager is the sole disk writer
- `TR-save-002`: 3 manual save slots + 1 autosave slot

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0003: Save/Load Persistence
**ADR Decision Summary**: Saves use a typed Godot `.tres` `SaveSnapshot` Resource written only by `SaveManager`, with three manual slots and one autosave slot under `user://saves/`.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: Uses `ResourceSaver`, `ResourceLoader`, `FileAccess`, and `.tres` Resource snapshots. ADR notes Godot 4.4+ `FileAccess.store_*` return values must be checked if used.

**Control Manifest Rules (this layer)**:
- Required: `SaveManager` is the sole disk writer; Core systems only register `serialize()` / `deserialize()` contracts.
- Forbidden: Never allow Core systems to write save files directly; never use JSON, ConfigFile, or SQLite/GDExtension as the save architecture.
- Guardrail: Save/load total time: load <500ms for a full save.

**Performance Note**: This story must respect the applicable Foundation guardrails from the control manifest. No per-frame gameplay work is expected unless explicitly listed in the acceptance criteria.

**Asset / Resource References**:
- `.tres` is referenced for implementation context; if it is an output path, it does not need to exist before implementation.
- `user://saves/slot_1.tres` is a runtime save/output path, not a repository asset that must exist before implementation.
- `slot_2.tres` is referenced for implementation context; if it is an output path, it does not need to exist before implementation.
- `slot_3.tres` is referenced for implementation context; if it is an output path, it does not need to exist before implementation.
- `autosave.tres` is referenced for implementation context; if it is an output path, it does not need to exist before implementation.

---

## Acceptance Criteria

*From GDD `design/gdd/save-and-load-system.md`, scoped to this story:*

- [ ] `SaveSnapshot` is a typed Resource containing save metadata, UI state, and system state blobs.
- [ ] Save files are stored as `.tres` snapshots at `user://saves/slot_1.tres`, `slot_2.tres`, `slot_3.tres`, and `autosave.tres`.
- [ ] `SaveManager` is the only code path that writes save files to disk.
- [ ] A snapshot missing required fields cannot be treated as a valid save.
- [ ] Slot metadata can distinguish empty, valid, invalid, and corrupted slots.

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

Define `SaveSnapshot` as a Resource with exported fields for `save_version`, timestamp, playtime, UI state, system state dictionaries, and metadata. Implement slot path resolution in `SaveManager`; no downstream system may write directly to `user://saves/`.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: Core system registration and snapshot assembly.
- Story 005: Integrity hash and atomic commit behavior.
- Story 009: Save summary performance regression sample.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 有效 `SaveSnapshot` 只能由 `SaveManager` 写入到规范槽位路径
  - Given: `SaveManager` 已组装出包含全部 required fields 的 `SaveSnapshot`
  - When: 分别执行保存到 `slot_1`、`slot_2`、`slot_3`、`autosave`
  - Then: 仅生成 `user://saves/slot_1.tres`、`slot_2.tres`、`slot_3.tres`、`autosave.tres` 四种合法文件，且均可被重新加载为 `.tres` `SaveSnapshot`
  - Edge cases: 空槽首次写入、覆盖已有槽位、非法槽位名/路径被拒绝

- **AC-2**: `save_snapshot_completeness` 必须为 1，缺字段快照不得成为有效存档
  - Given: 一个缺少任一 required field 的快照
  - When: 请求写入任意槽位
  - Then: `save_snapshot_completeness = present_required_fields / total_required_fields` 小于 1，保存失败，原槽位文件不被替换
  - Edge cases: 字段为 `null`、空字典、空数组、零字节文件

- **AC-3**: 读取槽位时只能接受完整且可解析的 `SaveSnapshot`
  - Given: 槽位中分别存在完整快照、缺字段快照、非 `SaveSnapshot` 资源
  - When: 读取槽位列表或打开指定槽位
  - Then: 仅完整快照被标记为有效存档；缺字段或类型不符的文件被标记为无效/损坏
  - Edge cases: 文件存在但资源类型错误、旧文件残留、扩展名正确但内容不可解析

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/save/save_snapshot_slots_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks:
  - `production/epics/save-and-load-system/story-002-save-registration-snapshot.md`
  - `production/epics/save-and-load-system/story-005-save-integrity-atomic-commit.md`
  - `production/epics/save-and-load-system/story-009-save-summary-performance.md`
