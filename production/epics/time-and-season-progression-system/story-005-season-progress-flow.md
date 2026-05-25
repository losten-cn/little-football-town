# Story 005: 实现赛季进度、赛季结算与休赛期流转

> **Epic**: 时间与赛季推进系统
> **Status**: Ready
> **Layer**: Foundation
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/time-and-season-progression-system.md`
**Requirement**: `TR-time-006`, `TR-time-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-time-006`: season_progress_ratio = matches_played / total_matches
- `TR-time-001`: 7 game states: Planning through SeasonStart

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0002: Event/Signal Architecture + TimeManager
**ADR Decision Summary**: TimeManager owns season state and publishes season boundary events through EventBus.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Season progress logic should be deterministic and safe under repeated state checks.

**Control Manifest Rules (this layer)**:
- Required: `TimeManager` must provide both synchronous pull access and runtime push updates.
- Forbidden: Never allow downstream systems to define independent season progression.
- Guardrail: TimeManager startup work must stay under 1ms in `_ready()`.

**Performance Note**: This story must respect the applicable Foundation guardrails from the control manifest. No per-frame gameplay work is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/time-and-season-progression-system.md`, scoped to this story:*

- [ ] `season_progress_ratio = completed_season_units / max(1, total_season_units)`.
- [ ] Reaching progress ratio `1` enters `Season Settlement`.
- [ ] `completed_season_units > total_season_units` clamps effective progress to complete and marks abnormal data for review.
- [ ] `Season Settlement` can transition into `Offseason` and then `SeasonStart`.
- [ ] New season start resets season-local counters without losing long-term state.

---

## Implementation Notes

*Derived from ADR-0002 Implementation Guidelines:*

TimeManager defines when a season ends and starts; LeagueStructure later defines the league schedule content generated at season start.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- League Structure stories: fixture generation, standings, promotion/relegation.
- Story 009: Long-session rhythm regression samples.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 赛季进度比按公式安全计算
  - Given: 已知 `completed_season_units` 与 `total_season_units`
  - When: 计算 `season_progress_ratio = completed_season_units / max(1, total_season_units)`
  - Then: 输出必须符合公式，且不会因总量为 0 崩溃
  - Edge cases: `total_season_units = 0` 时分母必须按 `1` 处理；比值可大于 1 但后续需进入结算流

- **AC-2**: 赛季进度达到或超过 1 时进入 Season Settlement
  - Given: `season_progress_ratio >= 1`
  - When: 执行赛季进度检查
  - Then: 状态必须切换到 `Season Settlement`
  - Edge cases: `ratio = 1` 与 `ratio > 1` 都必须通过；不得停留在普通阶段

- **AC-3**: Season Settlement 后正确流转到 Offseason 与 SeasonStart
  - Given: 已完成 `Season Settlement`
  - When: 执行赛季末流转
  - Then: 状态应依次进入 `Offseason`，再进入 `SeasonStart`，并为新赛季建立合法初始状态
  - Edge cases: 新赛季起点不得保留上一赛季已消费的关键节点/结算标记

- **AC-4**: 新赛季开始后核心计数被正确重置或继承
  - Given: 系统从 `Offseason` 进入 `SeasonStart`
  - When: 读取新赛季状态快照
  - Then: 本赛季进度计数应重置，允许继承的长期数据应保持，且时间线处于新赛季合法起点
  - Edge cases: 重复进入 `SeasonStart` 不得重复重置或损坏长期数据

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/time/season_progress_flow_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/time-and-season-progression-system/story-004-stage-settlement-trigger.md` — must be DONE
- Unlocks:
  - `production/epics/time-and-season-progression-system/story-006-key-node-priority.md`
  - `production/epics/time-and-season-progression-system/story-007-time-eventbus-integration.md`
