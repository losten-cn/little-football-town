# Epic: 球员管理 UI

> **Layer**: Presentation
> **GDD**: design/gdd/player-management-ui.md
> **Status**: Planned
> **Topology**: L2 — parallel UI page package
> **Stories**: 1 current-wave story

## Overview

本 epic 交付 vertical slice 所需的最小球员浏览与训练入口页面，让玩家能快速回答：我有哪些球员、谁最强、谁值得练、我从哪里开始训练。本波只覆盖 Roster、Player Detail 和 Training Entry，不做完整球员管理系统。

## Goal

- 在 MainLoop Shell 内提供可扫读的 roster 和最小 player detail。
- 让玩家能从球员详情稳定进入训练流程。
- 保证 UI 只消费 PlayerDevelopment / Balance / Economy 的权威数据，不重算评分、属性、成长或训练成本。

## Scope

### In Scope

- Roster 列表：姓名、主位置、权威评分摘要、培养层级、状态标签、近期成长指示。
- 默认按评分降序，允许姓名/位置排序。
- 位置筛选与空结果提示。
- Player Detail 固定顺序：基础身份、属性、成长、状态、操作入口。
- 属性条 1–100 视觉标尺与触顶标记。
- 训练入口带当前 `player_id` 上下文。
- 训练不可执行时显示禁用原因。
- 稳定交互 ID，供 onboarding / QA 使用。

### Out of Scope

- Complete sorting/filtering suite。
- Player compare、招募、出售、合同。
- 完整技能/特性/身份历史页。
- 深度成长历史图表。
- Full onboarding/tutorial、audio polish。
- UI 本地重算评分、成长或训练收益。

## Traceability

| TR-ID | Requirement Focus | Story |
|---|---|---|
| `TR-playerui-001` | roster row fields | Story 001 |
| `TR-playerui-002` | default/re-sort behavior | Story 001 |
| `TR-playerui-003` | detail section order | Story 001 |
| `TR-playerui-004` | attribute bars and caps | Story 001 |
| `TR-playerui-007` | empty filter result | Story 001 |
| `TR-playerui-008` | training button disabled reason | Story 001 |
| `TR-playerui-009` | stable interactive IDs | Story 001 |

## Stories

| # | Story | Type | Status | Notes |
|---|---|---|---|---|
| 001 | [建立 Roster / Player Detail 最小切片与训练入口交接](story-001-roster-training-entry.md) | UI | Planned | Parallel with MatchPerfUI after MainLoop route contract freeze. |

## Status / Notes

- Depends on MainLoop Shell route/container contract.
- May run in parallel with MatchPerfUI.
- Must not edit player/save schema.
- Must not recompute `positional_overall_rating`, attributes, `training_actual_gain`, AP, funds, or affordability.
