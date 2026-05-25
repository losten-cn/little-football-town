# Story 007: 实现读档恢复顺序与权威状态重建

> **Epic**: 存档与读档系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/save-and-load-system.md`
**Requirement**: `TR-save-004`, `TR-save-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-save-004`: Cross-system consistency: save_time_state == TimeManager.get_state() instantaneously
- `TR-save-012`: Deserialize order: Time→Town→Player→League→Economy→Match

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0003: Save/Load Persistence
**ADR Decision Summary**: Loading validates snapshots, then deserializes systems in fixed dependency order: Time → Town → Player → League → Economy → Match.

**Engine**: Godot 4.6 | **Risk**: MEDIUM
**Engine Notes**: Restore code must not persist or restore runtime object references; derived caches are rebuilt from authority data.

**Control Manifest Rules (this layer)**:
- Required: Deserialize Core systems in the fixed order `time → town → player → league → economy → match`.
- Forbidden: Never serialize derived player values or runtime caches as authority state.
- Guardrail: Save/load total time: load <500ms for a full save.

**Performance Note**: This story must respect the applicable Foundation guardrails from the control manifest. No per-frame gameplay work is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/save-and-load-system.md`, scoped to this story:*

- [ ] `save_time_state` matches the instantaneous `TimeManager.get_state()` used for the snapshot.
- [ ] Load order is exactly Time→Town→Player→League→Economy→Match.
- [ ] A system restore failure aborts the load and prevents mixed old/new runtime state from becoming playable.
- [ ] Runtime caches, UI displays, and derived values are rebuilt from restored authority data.
- [ ] Match-in-progress snapshots are not restored as stable mid-match authority state.

---

## Implementation Notes

*Derived from ADR-0003 Implementation Guidelines:*

Use the ADR load order explicitly. Restore Time first so later systems can interpret phase and season state; restore Match last after its data dependencies exist.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 006: Version migration before restore.
- Match Competition stories: how abandoned in-progress match state resumes at pre-match Entry.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 反序列化顺序必须严格为 `Time→Town→Player→League→Economy→Match`
  - Given: 六个核心系统均已注册反序列化 callable，并记录调用顺序
  - When: 执行一次完整读档
  - Then: 实际调用顺序与 ADR 规定顺序完全一致
  - Edge cases: 任一系统无数据块、顺序相邻系统互换、重复加载

- **AC-2**: 下游系统必须读取到上游已恢复的权威状态
  - Given: 快照中包含跨系统依赖数据
  - When: 按规定顺序执行恢复
  - Then: `Town/Player/League/Economy/Match` 在各自恢复时都能读取到其依赖的上游最终值，而不是运行时旧值
  - Edge cases: 赛季切换后读档、球员转会后读档、结算后立刻读档

- **AC-3**: 任一系统恢复失败时不得暴露混合态运行时状态
  - Given: 某中间系统（如 Economy）反序列化失败
  - When: 执行读档
  - Then: 后续系统不再继续恢复，本次读档整体失败，运行时不会留下“部分新数据 + 部分旧数据”的混合状态
  - Edge cases: 第一个系统失败、中间系统失败、最后一个系统失败

- **AC-4**: 读档后必须重建权威状态，而不是直接复用瞬时缓存
  - Given: 快照中只保存权威数据，未保存瞬时缓存/临时节点
  - When: 读档完成
  - Then: 依赖状态与派生状态按恢复顺序被重新构建，最终 Match 状态与权威数据一致
  - Edge cases: 缓存为空、缓存过期、恢复后首次进入比赛相关流程

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/save/load_restore_order_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/save-and-load-system/story-002-save-registration-snapshot.md` — must be DONE
  - `production/epics/save-and-load-system/story-006-save-migration.md` — must be DONE
- Unlocks:
  - `production/epics/save-and-load-system/story-008-save-recovery-flow.md`
