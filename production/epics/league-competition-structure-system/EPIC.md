# Epic: 联赛与赛事结构系统

> **Layer**: Core
> **GDD**: design/gdd/league-competition-structure-system.md
> **Architecture Module**: LeagueStructure
> **Status**: Complete
> **Topology**: L0 — authority layer before UI loop consumers
> **Stories**: 1 current-wave story

## Overview

本 epic 先实现 vertical slice 所需的最小联赛权威层：固定赛程、下一场比赛、积分榜、赛季状态、赛果消费与读档恢复。LeagueStructure 只消费现有 `MatchResultPacket + match_id`、TimeManager season flow、Save/Load restore order 与 EventBus，不重定义单场比赛结果、经济奖励或 UI 表现。

## Goal

- 在 UI playable loop 前冻结 minimum LeagueStructure 的 schedule / standings / next-match / season-settlement 边界。
- 让下游 MainLoopUI、MatchPerfUI、Economy、Save/Load 能读取同一个联赛真值。
- 保留 warning，但不允许破坏 stable payload、save/load、settlement/dedup 契约。

## Scope

### In Scope

- 8–12 偶数队的 MVP 双循环赛程。
- 每队 `2 × (team_count - 1)` 场比赛。
- `win=3`、`draw=1`、`loss=0` 积分结算。
- `PRE_SEASON → IN_PROGRESS → SETTLEMENT → COMPLETED` 赛季状态。
- `match_id` 关联 scheduled match 与 `match_completed`。
- 已完成比赛的重复提交防重。
- `time_season_ended` 触发赛季最终结算。
- League state 的 serialize / deserialize 契约。
- 下游只读查询：下一场比赛、积分榜、当前轮次、赛季摘要。

### Out of Scope

- 修改或重定义 `MatchResultPacket`。
- 完整 UI、赛程页、Career Review 或历史展示。
- 经济奖励金额和交易所有权。
- 多赛季深度、完整晋级/降级链、复杂并列展示。
- Random Event、Reputation/Achievement、Skill/Trait 消费。

## Traceability

| TR-ID | Requirement Focus | Story |
|---|---|---|
| `TR-league-002` | 8–12 teams, double round-robin | Story 001 |
| `TR-league-003` | win/draw/loss points | Story 001 |
| `TR-league-006` | matches per team formula | Story 001 |
| `TR-league-007` | four season states | Story 001 |
| `TR-league-010` | match_id correlation | Story 001 |
| `TR-league-011` | season settlement on time_season_ended | Story 001 |
| `TR-league-014` | duplicate match submission rejected | Story 001 |

## Stories

| # | Story | Type | Status | Notes |
|---|---|---|---|---|
| 001 | [建立 Minimum League Loop](story-001-minimum-league-loop.md) | Integration | Complete | L0 authority layer for downstream UI loop. |

## Status / Notes

Current-wave blockers before DONE:
- League save registration must be closed and verified.
- `match_context` must not be invented or frozen by this story beyond agreed scalar correlation fields.
- `MatchResultPacket` shape and semantics must remain read-only upstream truth.
- League EventBus/save payloads must remain shallow typed dictionaries with serializable values only.

Warnings carried forward:
- Full promotion/relegation depth, season history, and standings UI remain later stories.
- `TR-economy-008` and `TR-town-013` remain partial traceability warnings outside this epic.

## Definition of Done

This epic wave is complete when Story 001 has a passing integration proof for `match_completed → standings update → duplicate rejection → time_season_ended settlement → save/load restore` and downstream consumers can read league truth without recomputing it.
