# Epic: 主循环 UI 框架

> **Layer**: Presentation
> **GDD**: design/gdd/main-loop-ui-framework.md
> **Status**: Complete with Production follow-up planned
> **Topology**: L1 — shell after League contract freeze
> **Stories**: 1 complete current-wave story + 1 Production follow-up story

## Overview

本 epic 交付 vertical slice 的最小主循环外壳，让玩家能在统一 UI 框架内完成 `Home → Roster/Training → Match Pre/Live/Result → Home`。本波只解决 Home、导航、统一容器、入口可用性、返回路径和状态刷新，不扩张为 full HUD 或完整主界面系统。

## Goal

- 冻结 L2 UI 可并行接入的 route / container / return-path contract。
- 让玩家从 Home 看懂日期、AP/资金、下一场比赛、球队摘要和当前可行动作。
- 保证训练、比赛、赛后返回 Home 后，主循环状态刷新且路径稳定。

## Scope

### In Scope

- Shell 三段式结构：top bar、main content、bottom bar。
- 最小 route contract：`home`、`roster`、`player_detail`、`training`、`match_pre`、`match_live`、`match_result`。
- Home 摘要：当前日期/阶段、下一场比赛、球队概览、`available_action_windows`、funds/AP。
- Home 入口：Roster、Training、Match。
- 入口启用/禁用原因。
- `time_advanced`、`system_state_changed`、`player_action_completed` 后刷新。
- 150–400ms screen transition 预算。

### Out of Scope

- Full HUD、deep schedule、完整 Town UI、settings/audio polish。
- 完整 tutorial/help stack。
- PlayerMgmtUI 和 MatchPerfUI 内部内容。
- 任何 gameplay truth 的本地重算。

## Traceability

| TR-ID | Requirement Focus | Story |
|---|---|---|
| `TR-mainui-001` | max navigation depth from Home | Story 001 |
| `TR-mainui-004` | UI refresh triggers | Story 001 |
| `TR-mainui-005` | consistent shell structure | Story 001 |
| `TR-mainui-006` | entry availability formula | Story 001 |
| `TR-mainui-007` | transition duration range | Story 001 |

## Stories

| # | Story | Type | Status | Notes |
|---|---|---|---|---|
| 001 | [建立 Home Shell 与主循环导航骨架](story-001-home-loop-navigation.md) | UI | Complete | Freezes route/container contract for L2 UI packages. |
| 002 | [Home visual exemplar and placeholder boundary](story-002-home-visual-exemplar-placeholder-boundary.md) | UI | Ready | Production follow-through story for Home/shell visual exemplar and placeholder tolerance. |

## Status / Notes

- Depends on L0 League next-match / standings-facing contract freeze.
- Unlocks PlayerMgmtUI and MatchPerfUI parallel implementation.
- UI may format authoritative data but must not recompute `team_match_strength`, `available_action_windows`, funds/AP, training preview, match trigger, or roster truth.
