# Epic: 时间与赛季推进系统

> **Layer**: Foundation
> **GDD**: design/gdd/time-and-season-progression-system.md
> **Architecture Module**: TimeManager
> **Status**: Ready
> **Stories**: 9 stories

## Overview

本 epic 实现《足球小镇》的全局节奏控制层，通过 `TimeManager` 管理行动窗口、阶段推进、比赛触发、赛季结算和时间状态快照。它只负责“什么时候推进、什么时候触发关键节点”，为训练、比赛、经济、建设、联赛和 UI 提供统一时间语义，但不拥有这些下游系统的具体结算内容。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0002: Event/Signal Architecture + TimeManager | 定义 EventBus 契约、时间事件优先级、TimeManager Autoload、时间状态查询和关键节点信号。 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-time-001 | 7 game states: Planning through SeasonStart | ADR-0002 ✅ |
| TR-time-002 | action_time_cost defines action window consumption | ADR-0002 ✅ |
| TR-time-003 | available_action_windows: remaining actions before forced time advance | ADR-0002 ✅ |
| TR-time-004 | match_trigger_reached = accumulated ≥ match_interval AND no match in progress | ADR-0002 ✅ |
| TR-time-005 | stage_settlement_trigger_reached = matches_played ≥ matches_per_stage | ADR-0002 ✅ |
| TR-time-006 | season_progress_ratio = matches_played / total_matches | ADR-0002 ✅ |
| TR-time-007 | TimeManager is Autoload #5 — loaded after ScreenManager, before Core systems | ADR-0002 ✅ |
| TR-time-008 | TimeManager exposes get_state() for save snapshots | ADR-0002 ✅ |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [实现 TimeManager 状态模型与 Autoload 契约](story-001-time-manager-state-contract.md) | Integration | Ready | ADR-0002 |
| 002 | [实现行动时间消耗与可用窗口公式](story-002-action-window-formula.md) | Logic | Ready | ADR-0002 |
| 003 | [实现比赛节点触发与 Match Trigger 状态转换](story-003-match-trigger.md) | Logic | Ready | ADR-0002 |
| 004 | [实现阶段结算与赛后连续触发](story-004-stage-settlement-trigger.md) | Logic | Ready | ADR-0002 |
| 005 | [实现赛季进度、赛季结算与休赛期流转](story-005-season-progress-flow.md) | Logic | Ready | ADR-0002 |
| 006 | [实现关键节点优先级与同位置确定性结算](story-006-key-node-priority.md) | Integration | Ready | ADR-0002 |
| 007 | [实现时间事件发布与 EventBus 优先级集成](story-007-time-eventbus-integration.md) | Integration | Ready | ADR-0002 |
| 008 | [实现读档恢复节点与下游推进边界](story-008-time-restore-boundary.md) | Integration | Ready | ADR-0002 |
| 009 | [实现时间状态展示字段与节奏回归样本](story-009-time-status-regression.md) | Integration | Ready | ADR-0002 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/time-and-season-progression-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories time-and-season-progression-system` to break this epic into implementable stories.
