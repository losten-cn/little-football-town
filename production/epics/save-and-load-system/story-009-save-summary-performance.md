# Story 009: 实现存档摘要、性能预算与回归样本

> **Epic**: 存档与读档系统
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-28

## Context

**GDD**: `design/gdd/save-and-load-system.md`
**Requirement**: `TR-save-009`, `TR-save-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-save-009`: Load time < 500ms for full save
- `TR-save-002`: 3 manual save slots + 1 autosave slot

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0003: Save/Load Persistence
**ADR Decision Summary**: Slot metadata supports save/load UI summaries; full save load must remain under the 500ms budget.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: Use `Time.get_ticks_msec()` for performance measurement, not deprecated timing APIs.

**Control Manifest Rules (this layer)**:
- Required: Use `SaveSnapshot` Resource-based saves (`.tres`) with 3 manual slots plus 1 autosave slot.
- Forbidden: Never treat readable metadata alone as proof that the save body is valid.
- Guardrail: Save/load total time: load <500ms for a full save.

**Performance Note**: This story must respect the applicable Foundation guardrails from the control manifest. No per-frame gameplay work is expected unless explicitly listed in the acceptance criteria.

**Asset / Resource References**:
- `.tres` is referenced for implementation context; if it is an output path, it does not need to exist before implementation.

---

## Acceptance Criteria

*From GDD `design/gdd/save-and-load-system.md`, scoped to this story:*

- [x] Save summary fields include save name or town name, last save time, playtime, season/phase, key resources, and recent stable node type.
- [x] `save_summary_progress_ratio = completed_progress_units / max(1, total_progress_units)` is correct for displayed progress.
- [x] Empty, corrupted, and incomplete slots are clearly distinguishable from valid slots.
- [x] Full save load completes in <500ms for a representative full-save regression sample.
- [x] MVP local recovery baseline verifies last valid manual save plus recent valid autosave behavior.

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

`SaveManager.get_save_metadata(slot)` should expose structured metadata for UI without granting write access. Performance evidence belongs in automated integration tests or a repeatable playtest doc.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Save/Load UI screen layout and interaction design.
- Cloud sync, platform storage quota UI, or long-term backup management.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 有效槽位必须生成稳定且可展示的存档摘要
  - Given: `slot_1`、`slot_2`、`slot_3`、`autosave` 均含有效快照
  - When: 读取槽位列表并生成摘要
  - Then: 每个槽位都能返回与其快照一致的摘要信息，并可用于存档列表展示
  - Edge cases: 空槽、刚保存后立即读取、手动槽与 autosave 混合存在

- **AC-2**: 无效槽位摘要不得伪装成有效存档
  - Given: 槽位分别为完整快照、损坏快照、`save_snapshot_completeness < 1` 的不完整快照
  - When: 生成摘要列表
  - Then: 仅有效槽位显示为可用摘要；损坏/不完整槽位必须被标记为无效、损坏或不可用
  - Edge cases: 缺少摘要字段、哈希失败、旧版本未迁移

- **AC-3**: 完整读档性能必须满足 `<500ms` 预算
  - Given: 一份代表 full save 的最大回归样本
  - When: 执行完整读档并测量耗时
  - Then: 单次完整读档耗时严格小于 500ms
  - Edge cases: 499ms 通过、500ms/501ms 失败、冷启动与热加载差异

- **AC-4**: 回归样本必须稳定通过摘要与兼容性检查
  - Given: 一组固定回归样本（当前版与迁移样本）
  - When: 逐个执行加载、摘要生成、完整性/一致性校验
  - Then: 每个样本都返回预期的有效/无效结论与摘要结果，避免后续改动引入回归
  - Edge cases: 当前版样本、旧版迁移样本、损坏样本混合运行

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/save/save_summary_performance_test.gd` OR playtest doc

**Status**: [x] Created and verified — SAVE_SUMMARY_PERFORMANCE_TEST_PASS

---

## Dependencies

- Depends on:
  - `production/epics/save-and-load-system/story-001-save-snapshot-slots.md` — must be DONE
  - `production/epics/save-and-load-system/story-004-autosave-triggers.md` — must be DONE
  - `production/epics/save-and-load-system/story-007-load-restore-order.md` — must be DONE
- Unlocks:
  - Downstream work: Save/Load UI story readiness

## Completion Notes
**Completed**: 2026-05-28
**Criteria**: 5/5 passing
**Deviations**: Advisory only — headless verification uses `tests/integration/save/save_summary_performance_runner.gd` to host the Node-based integration test, while the evidence file remains `tests/integration/save/save_summary_performance_test.gd`.
**Test Evidence**: Integration test at `tests/integration/save/save_summary_performance_test.gd` — PASS via `tests/integration/save/save_summary_performance_runner.gd` (`SAVE_SUMMARY_PERFORMANCE_TEST_PASS`)
**Code Review**: Complete — no blocking issues
