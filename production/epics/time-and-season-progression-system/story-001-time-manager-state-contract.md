# Story 001: 实现 TimeManager 状态模型与 Autoload 契约

> **Epic**: 时间与赛季推进系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/time-and-season-progression-system.md`
**Requirement**: `TR-time-001`, `TR-time-007`, `TR-time-008`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-time-001`: 7 game states: Planning through SeasonStart
- `TR-time-007`: TimeManager is Autoload #5 — loaded after ScreenManager, before Core systems
- `TR-time-008`: TimeManager exposes get_state() for save snapshots

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0002: Event/Signal Architecture + TimeManager
**ADR Decision Summary**: TimeManager is the authoritative timeline Autoload, exposes synchronous `get_state()` for save/UI queries, and emits runtime time events through EventBus.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Uses stable Godot `Node`, `Signal`, `Callable`, and Autoload patterns; no post-cutoff API verification required.

**Control Manifest Rules (this layer)**:
- Required: Autoload order must be `ConfigLoader → EventBus → TimeManager → SaveManager → ScreenManager`.
- Required: `TimeManager` must provide both synchronous pull access (`get_state`) and runtime push updates (time events).
- Forbidden: Never couple producer and consumer systems through direct node-held signal wiring as the main architecture.
- Guardrail: TimeManager startup work must stay under 1ms in `_ready()`.

**Performance Note**: This story must respect the applicable Foundation guardrails from the control manifest. No per-frame gameplay work is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/time-and-season-progression-system.md`, scoped to this story:*

- [ ] TimeManager is loaded after EventBus and before SaveManager according to the control manifest.
- [ ] The state model supports the GDD-defined states: `Planning`, `Action Resolution`, `Match Trigger`, `Match In Progress`, `Post-Match Settlement`, `Stage Settlement`, `Season Settlement`, `Offseason`, `SeasonStart`.
- [ ] `get_state()` returns a serializable Dictionary with timeline position, current phase/state, season number, current stage, season progress, available action windows, and next key node data.
- [ ] State changes are reflected consistently through both `get_state()` and EventBus time events.

---

## Implementation Notes

*Derived from ADR-0002 Implementation Guidelines:*

Implement TimeManager as the timeline authority, with pull state for save/load and UI, and push events through EventBus. Do not rely on downstream systems to infer or mutate time state.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: Action window formulas.
- Story 007: Full EventBus priority integration for time events.
- Story 008: Save/load restore boundaries.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: TimeManager 作为 Autoload 按 ADR/manifest 的实际顺序加载
  - Given: Autoload 顺序配置为 `ConfigLoader → EventBus → TimeManager → SaveManager → ScreenManager`
  - When: 启动最小运行环境并检查单例注册与可访问顺序
  - Then: TimeManager 必须在 EventBus 之后、SaveManager 之前可用，且验证依据为 manifest 实际顺序而不是 TR 中的编号标签
  - Edge cases: 若 story/TR 文本写成 “Autoload #5”，应记录为文档标签不一致，不应据此放宽实现校验

- **AC-2**: `get_state()` 返回完整且稳定的时间状态快照
  - Given: TimeManager 已初始化并进入任一合法状态
  - When: 调用 `TimeManager.get_state()`
  - Then: 返回值应包含当前状态、timeline 位置、阶段/赛季进度、关键节点相关字段，且可被 SaveManager/下游系统直接消费
  - Edge cases: 未初始化、空状态、缺字段、字段类型错误均应判定失败

- **AC-3**: 状态模型覆盖 GDD 定义的 9 个状态
  - Given: 系统已具备状态枚举/状态机定义
  - When: 遍历状态模型并执行状态合法性校验
  - Then: 必须支持 `Planning / Action Resolution / Match Trigger / Match In Progress / Post-Match Settlement / Stage Settlement / Season Settlement / Offseason / SeasonStart` 共 9 个状态
  - Edge cases: 若实现仅支持 7 个状态、缺少赛后或休赛期状态，测试应失败并标注为 GDD 不一致

- **AC-4**: 状态切换同时满足 pull 与 push 契约
  - Given: TimeManager 发生一次合法状态切换
  - When: 订阅 EventBus 的 `time_*` 事件并同步调用 `get_state()`
  - Then: 事件必须被发布，且事件触发时 `get_state()` 读到的是切换后的稳定状态；达到比赛触发条件时还必须发出 `time_match_triggered`
  - Edge cases: 重复发事件、事件先于状态落地、push/pull 内容不一致均判定失败

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/time/time_manager_state_contract_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on: None
- Unlocks:
  - `production/epics/time-and-season-progression-system/story-002-action-window-formula.md`
  - `production/epics/time-and-season-progression-system/story-003-match-trigger.md`
  - `production/epics/time-and-season-progression-system/story-007-time-eventbus-integration.md`
  - `production/epics/time-and-season-progression-system/story-008-time-restore-boundary.md`
  - `production/epics/time-and-season-progression-system/story-009-time-status-regression.md`
