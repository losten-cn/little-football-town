# Story 002: 实现系统注册契约与快照组装

> **Epic**: 存档与读档系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/save-and-load-system.md`
**Requirement**: `TR-save-003`, `TR-save-011`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-save-003`: Save completeness: all 12 dependency systems captured atomically
- `TR-save-011`: Registration contract: each Core system registers serialize/deserialize callables with SaveManager

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0003: Save/Load Persistence
**ADR Decision Summary**: Core systems register `serialize()` / `deserialize()` callables with `SaveManager`; `SaveManager` collects all registered authority state into one atomic `SaveSnapshot`.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: Use typed callables and serializable primitive/Dictionary state blobs; no node references should be stored.

**Control Manifest Rules (this layer)**:
- Required: `SaveManager` is the sole disk writer; Core systems only register `serialize()` / `deserialize()` contracts.
- Forbidden: Never allow Core systems to write save files directly.
- Guardrail: Save/load total time: load <500ms for a full save.

**Performance Note**: This story must respect the applicable Foundation guardrails from the control manifest. No per-frame gameplay work is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/save-and-load-system.md`, scoped to this story:*

- [ ] Each required long-term system registers paired serialize/deserialize callables with `SaveManager`.
- [ ] A valid snapshot captures all required system state at one time point.
- [ ] Missing required system state causes snapshot assembly to fail.
- [ ] `save_snapshot_completeness` must equal `1` before commit.
- [ ] `cross_system_consistency_ratio` must equal `1` before commit.

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

Implement `register_system(system_id, serialize_fn, deserialize_fn)` in `SaveManager`, store callables by system id, and assemble `SaveSnapshot` by invoking every required serializer. The registration contract enforces explicit persistence ownership; it must not serialize arbitrary node trees.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 007: Load-time deserialization order and state restoration.
- Core system stories: deciding each system's detailed serializable fields.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 核心系统必须向 `SaveManager` 注册成对的 `serialize/deserialize` callable
  - Given: Core systems 依次向 `SaveManager` 注册保存契约
  - When: `SaveManager` 校验注册表
  - Then: 只有同时提供 `serialize` 与 `deserialize` callable 的系统被视为已注册，缺任一 callable 的系统被判定为未完成注册
  - Edge cases: 重复注册、空 callable、注册顺序不同

- **AC-2**: 已注册核心系统的数据必须被组装进同一份快照
  - Given: Time、Town、Player、League、Economy、Match 均已成功注册
  - When: 执行一次完整保存
  - Then: 生成的 `SaveSnapshot` 含有所有核心系统的序列化分段，且由 `SaveManager` 统一写盘
  - Edge cases: 某系统返回空但合法的默认数据、某系统序列化耗时较长、重复保存

- **AC-3**: 任一必需系统未注册时，快照组装必须失败
  - Given: 缺少至少一个核心系统注册
  - When: 执行保存
  - Then: 保存被阻止，快照不写盘，并返回缺失系统列表或等价错误信息
  - Edge cases: 仅缺失 Match、缺失多个系统、运行时注销后再次保存

- **AC-4**: `cross_system_consistency_ratio` 必须为 1 才允许提交快照
  - Given: 所有系统均已注册，但跨系统检查中存在一项不一致
  - When: `SaveManager` 执行一致性校验
  - Then: `cross_system_consistency_ratio = passed_consistency_checks / total_consistency_checks` 小于 1，保存失败且不写入槽位
  - Edge cases: 赛程与时间不一致、球员归属与城镇数据不一致、仅 1 项检查失败

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/save/save_registration_snapshot_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/save-and-load-system/story-001-save-snapshot-slots.md` — must be DONE
- Unlocks:
  - `production/epics/save-and-load-system/story-005-save-integrity-atomic-commit.md`
  - `production/epics/save-and-load-system/story-007-load-restore-order.md`
