# Story 005: 实现原子提交、完整性哈希与损坏检测

> **Epic**: 存档与读档系统
> **Status**: Complete
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-28

## Context

**GDD**: `design/gdd/save-and-load-system.md`
**Requirement**: `TR-save-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-save-008`: Save integrity verified via hash checksum

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0003: Save/Load Persistence
**ADR Decision Summary**: `SaveSnapshot` includes an integrity hash for best-effort corruption detection; save commit must not expose half-written snapshots as valid progress.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: `ResourceSaver.save()` return code and any `FileAccess.store_*` bool result must be checked and routed through failure handling.

**Control Manifest Rules (this layer)**:
- Required: Use `integrity_hash` as best-effort corruption detection and surface recovery/deletion flows on mismatch.
- Forbidden: Never silently load corrupted save data.
- Guardrail: Save/load total time: load <500ms for a full save.

**Performance Note**: This story must respect the applicable Foundation guardrails from the control manifest. No per-frame gameplay work is expected unless explicitly listed in the acceptance criteria.

## Asset / Resource References

- `user://saves/slot_1.tres`, `slot_2.tres`, `slot_3.tres`, and `autosave.tres` are runtime save/output paths, not repository assets that must exist before implementation.
- Any temporary commit path used for atomic replace (for example `user://saves/slot_1.tmp` or equivalent) is also a runtime output path, not a pre-existing asset.
- Integrity hash data lives inside `SaveSnapshot` metadata/runtime save content and does not require a separate checked-in asset file.

---

## Acceptance Criteria

*From GDD `design/gdd/save-and-load-system.md`, scoped to this story:*

- [x] Valid saves include an integrity hash computed from serialized gameplay state.
- [x] Hash mismatch or corrupted file returns failure and does not enter normal restore.
- [x] Save commit is atomic from the player perspective: new snapshot complete or old snapshot intact.
- [x] Failed save does not emit success semantics or overwrite the last valid snapshot.
- [x] Disk/write API failures are checked and surfaced as save failures.

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

Compute and verify `integrity_hash` as part of metadata. If any write operation fails, return false and avoid reporting `save_completed`. Prefer temp-then-replace style commit if needed to preserve the old valid snapshot.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 008: Player-facing recovery decision semantics.
- Security/anti-tamper: hash is corruption detection, not cheat-proofing.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 成功保存后必须写出可通过校验的完整性哈希
  - Given: 一个完整且一致的 `SaveSnapshot`
  - When: 执行保存并随后执行读取校验
  - Then: 快照中的 hash checksum 校验通过，槽位被判定为可正常读取
  - Edge cases: 小型快照、大型快照、相同内容重复保存

- **AC-2**: 哈希不匹配时必须判定为损坏存档
  - Given: 已保存槽位文件被手动篡改或部分截断
  - When: 执行读档或槽位校验
  - Then: 校验失败，槽位被标记为损坏，不进入正常反序列化流程
  - Edge cases: 只改 1 个字段、尾部截断、哈希字段自身损坏

- **AC-3**: 原子提交必须满足“新快照完整可用，或旧快照原样保留”
  - Given: 目标槽位已有旧存档
  - When: 在新存档提交过程中模拟中断、异常或临时文件提交失败
  - Then: 结果只能是“新快照完整替换成功”或“旧快照仍可正常读取”，不得出现半写入状态
  - Edge cases: 写到一半崩溃、提交前校验失败、磁盘写入异常

- **AC-4**: ADR 规定的底层返回值必须被检查并纳入失败路径
  - Given: `FileAccess.store_*` 返回 `false` 或 `ResourceSaver.save` 返回非 `OK` 错误
  - When: 执行保存
  - Then: `SaveManager` 必须将其视为保存失败，不得报告成功，也不得覆盖旧槽位
  - Edge cases: 仅一个 `store_*` 失败、`ResourceSaver.save` 失败、先写成功后提交失败

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/save/save_integrity_atomic_commit_test.gd` OR playtest doc

**Status**: [x] Created and verified — `SAVE_INTEGRITY_ATOMIC_COMMIT_TEST_PASS`

---

## Dependencies

- Depends on:
  - `production/epics/save-and-load-system/story-001-save-snapshot-slots.md` — must be DONE
  - `production/epics/save-and-load-system/story-002-save-registration-snapshot.md` — must be DONE
  - `production/epics/save-and-load-system/story-003-stable-node-save-gate.md` — must be DONE
- Unlocks:
  - `production/epics/save-and-load-system/story-006-save-migration.md`
  - `production/epics/save-and-load-system/story-008-save-recovery-flow.md`

## Completion Notes
**Completed**: 2026-05-28
**Criteria**: 5/5 passing
**Deviations**: Advisory only — headless verification uses `tests/integration/save/save_integrity_atomic_commit_runner.gd` to host the Node-based integration test, while the evidence file remains `tests/integration/save/save_integrity_atomic_commit_test.gd`.
**Test Evidence**: Integration test at `tests/integration/save/save_integrity_atomic_commit_test.gd` — PASS via `tests/integration/save/save_integrity_atomic_commit_runner.gd` (`SAVE_INTEGRITY_ATOMIC_COMMIT_TEST_PASS`)
**Code Review**: Complete — no blocking issues
