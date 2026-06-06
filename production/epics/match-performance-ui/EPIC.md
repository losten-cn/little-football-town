# Epic: 比赛表现 UI

> **Layer**: Presentation
> **GDD**: design/gdd/match-performance-ui.md
> **Status**: Planned
> **Topology**: L2 — parallel UI page package
> **Stories**: 1 current-wave story

## Overview

本 epic 交付 vertical slice 所需的最小比赛展示流，让玩家完整经历 `Match Pre → Match Live → Match Result`，并在赛后理解发生了什么、为什么会这样、以及如何返回主循环。它只呈现比赛系统和联赛系统的权威结果，不做 full HUD、深度统计、解说或音频打磨。

## Goal

- 在 MainLoop Shell 内提供赛前、赛中、赛后三个稳定容器。
- 让比赛过程可读，赛后结果可理解，并能安全回到 Home。
- 保证 UI 只消费权威 match / league payload，不重算比赛、阵容、评分、排名或资源变化。

## Scope

### In Scope

- `match_pre`：对手、主客场、轮次、排名摘要、阵容摘要、战术摘要/最小选择位、开赛确认。
- `match_live`：比分、比赛时间、半场指示、关键事件时间线、中场分隔、调整入口、退出告警。
- `match_result`：终场比分、胜负原因、关键事件回看、球员表现摘要、联赛影响、确认返回 Home。
- Stable anchors for QA/onboarding: `match_pre_confirm`, `match_live_timeline`, `match_live_exit_warning`, `match_halftime_adjust`, `match_result_confirm`.

### Out of Scope

- Full HUD、animated match scene、deep stats、完整 schedule/standings 页面。
- 技能/特性赛前快照和赛后解释页。
- Commentary、audio polish、复杂演出。
- UI 本地重算阵容合法性、比赛结果、球员评分、排名或资金/AP。

## Traceability

| TR-ID | Requirement Focus | Story |
|---|---|---|
| `TR-matchui-001` | three match UI containers | Story 001 |
| `TR-matchui-002` | pre-match required info | Story 001 |
| `TR-matchui-003` | opponent strength labels | Story 001 |
| `TR-matchui-004` | live score/time/timeline | Story 001 |
| `TR-matchui-007` | post-match section order | Story 001 |
| `TR-matchui-009` | halftime separator | Story 001 |
| `TR-matchui-010` | live exit warning | Story 001 |
| `TR-matchui-011` | 0-0 halftime summary | Story 001 |

## Stories

| # | Story | Type | Status | Notes |
|---|---|---|---|---|
| 001 | [建立赛前到赛后的最小比赛展示流](story-001-prematch-result-flow.md) | UI | Planned | Parallel with PlayerMgmtUI after MainLoop route contract freeze; final wiring depends on League contract. |

## Status / Notes

- Depends on MainLoop Shell route/container contract.
- Final pre-match/league-impact wiring depends on League next-match and standings-facing contract freeze.
- Must not modify `match_context`, `match_result_packet`, or `pre_match_skill_trait_snapshot`.
