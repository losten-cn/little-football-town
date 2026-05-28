# Epic: 运动员培养系统

> **Layer**: Core
> **GDD**: design/gdd/player-development-system.md
> **Architecture Module**: PlayerDevelopment
> **Status**: Complete
> **Stories**: 9 stories

## Overview

本 epic 实现《足球小镇》的球员长期成长权威层，通过 `PlayerDevelopment`、`PlayerRoster` 和 `Player` 数据模型承载球员属性、潜力、训练效率、状态、训练结算、培养历史和里程碑反馈。它把数值系统的共享成长公式转化为玩家可规划、可比较、可持续投入的培养体验，并向比赛系统提供结构化球员能力与状态输出。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0005: Player Data Model | 使用 `Player` RefCounted、`PlayerRoster` 集合与 `PlayerDevelopment` Core 节点管理球员权威状态、训练原子性和序列化契约。 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-playerdev-001 | Player must have: id, name, age, position, 5 attrs, train_efficiency, condition, morale, history, milestones | ADR-0005 ✅ |
| TR-playerdev-002 | fatigue_adjusted_training_efficiency = efficiency × condition × morale, clamped [0.5, 1.8] | ADR-0005 ✅ |
| TR-playerdev-003 | training_actual_gain = attribute_growth × fatigue × focus_match × facility_multiplier | ADR-0005 ✅ |
| TR-playerdev-004 | facility_training_multiplier ∈ [1.0, 1.75] — consumed from TownBuilding | ADR-0005 ✅ |
| TR-playerdev-005 | Training must be atomic: validate→deduct→grow→apply→emit | ADR-0005 ✅ |
| TR-playerdev-006 | Training costs via EconomyManager.accredit_training_cost() only | ADR-0005 ✅ |
| TR-playerdev-007 | ap_to_funds_weight = 50 (from EconomyManager, not overridden locally) | ADR-0005 ✅ |
| TR-playerdev-008 | Training gains survive save/load without loss or double-settlement | ADR-0005 ✅ |
| TR-playerdev-009 | Tier potential bands: 普通(60-75), 优秀(72-85), 明星(82-95), 传奇胚子(90-99) | ADR-0005 ✅ |
| TR-playerdev-010 | Individual training_efficiency ∈ [0.8, 1.5] per player | ADR-0005 ✅ |
| TR-playerdev-011 | Milestone check: attribute reaching 10-multiple triggers player_milestone_reached | ADR-0005 ✅ |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [实现 Player / PlayerRoster 权威数据模型与序列化边界](story-001-player-data-serialization-boundary.md) | Integration | Complete | ADR-0005 |
| 002 | [实现训练效率与状态修正公式](story-002-training-efficiency-formula.md) | Logic | Complete | ADR-0005 |
| 003 | [实现训练成长结算与潜力上限裁剪](story-003-training-gain-cap.md) | Logic | Complete | ADR-0005 |
| 004 | [实现球员层级、潜力区间与训练效率差异](story-004-player-tier-band.md) | Logic | Complete | ADR-0005 |
| 005 | [实现训练项目匹配、副属性成长与 ROI 计算样本](story-005-training-roi.md) | Logic | Complete | ADR-0005 |
| 006 | [实现训练原子性与 Economy/Time 集成](story-006-training-atomic-integration.md) | Integration | Complete | ADR-0005 |
| 007 | [实现成长里程碑、训练历史与赛季年龄推进](story-007-player-milestone-history.md) | Integration | Complete | ADR-0005 |
| 008 | [实现赛后状态消费与下游写保护边界](story-008-player-state-boundary.md) | Integration | Complete | ADR-0005 |
| 009 | [实现培养闭环回归样本与持久化一致性验证](story-009-player-development-regression.md) | Integration | Complete | ADR-0005 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/player-development-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories player-development-system` to break this epic into implementable stories.
