# Epic: 声望与成就系统

> **Layer**: Feature
> **GDD**: `design/gdd/reputation-and-achievement-system.md`
> **Architecture Module**: `ReputationAchievementSystem` (Feature Contract Layer)
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories reputation-and-achievement-system`

## Overview

声望与成就系统是《足球小镇》中负责把"持续经营"转化为"被认可的成长轨迹"的长期反馈层。它承接比赛成绩、赛季推进、球员培养和小镇建设等关键里程碑，沉淀为可累积的声望进度、阶段性解锁和可追踪的成就记录。MVP 阶段仅定义最小长期反馈契约、结算口径与持久化语义；Alpha 阶段接入完整可见闭环。权威实现 `ReputationAchievementManager` 独占 `reputation_total`、`reputation_level`、`reputation_progress_ratio`、`unlocked_achievement_ids`、`pending_reputation_rewards` 和 `processed_reputation_settlement_keys` 的耐久真值。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0011: Reputation and Achievement Recognition Framework | 声望增长通过加权结算公式累积，成就判定基于去重键和已解锁集合的幂等检查；展示层只消费权威 payload | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-reputation-001 | 声望增长公式：`reputation_gain = floor((base + bonus) × source_weight × stage_multiplier)` | ADR-0011 ✅ |
| TR-reputation-002 | 声望等级进度比率由权威系统产出，UI 直接消费 | ADR-0011 ✅ |
| TR-reputation-003 | 成就完成判定需满足条件 AND 未解锁，同一成就不可重复解锁 | ADR-0011 ✅ |
| TR-reputation-004 | 奖励结算需定义明确的归属、去重键与消费顺序 | ADR-0011 ✅ |
| TR-reputation-005 | 声望等级、进度、已解锁成就与待展示奖励作为可存档耐久状态恢复 | ADR-0011 ✅ |
| TR-reputation-006 | 展示层必须消费权威声望/成就 payload，不得自行推导 | ADR-0011 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/reputation-and-achievement-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories reputation-and-achievement-system` to break this epic into implementable stories.
