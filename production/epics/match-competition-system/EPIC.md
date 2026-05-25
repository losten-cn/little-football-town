# Epic: 比赛竞技系统

> **Layer**: Core
> **GDD**: design/gdd/match-competition-system.md
> **Architecture Module**: MatchCompetition
> **Status**: Ready
> **Stories**: 9 stories

## Overview

本 epic 实现《足球小镇》的单场比赛权威层，通过 `MatchCompetition` 与 `MatchSimulation` 管理赛前准备、阵容与战术锁定、上下半场演算、中场调整、关键事件、终场复盘和标准化结果包。它消费球员培养系统输出的能力与状态，并把比赛结果回传给经济、联赛、培养和 UI 系统，形成“培养 → 比赛 → 反馈 → 再培养”的核心闭环。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0006: Match Simulation Architecture | 使用确定性比赛状态机、seeded RNG、关键事件生成和 `MatchResultPacket` 完成单场比赛演算与下游交接。 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-match-001 | 8-state match flow: Entry→Pre-Match→Confirmation→First Half→Halftime→Second Half→Result Review→Settlement | ADR-0006 ✅ |
| TR-match-002 | team_match_strength = weighted positional ratings × chemistry + facility_bonus | ADR-0006 ✅ |
| TR-match-003 | actual_win_probability = base + home + condition + tactical modifiers, clamped [0.05, 0.95] | ADR-0006 ✅ |
| TR-match-004 | Key event count per match: 3 ≤ count ≤ 15 | ADR-0006 ✅ |
| TR-match-005 | 6 event categories: offensive_push, shot_on_goal, goal_scored, key_defense, tactical_adaptation, stamina_decline | ADR-0006 ✅ |
| TR-match-006 | Half-time adjustment: change tactics + up to 3 substitutions, second half only | ADR-0006 ✅ |
| TR-match-007 | Match In Progress NOT a stable restore point — save abandons partial state | ADR-0006 ✅ |
| TR-match-008 | Standardized MatchResultPacket consumed by LeagueStructure, EconomyManager, TimeManager, MatchPerfUI | ADR-0006 ✅ |
| TR-match-009 | Seeded RNG per match — same seed + inputs = identical outcome | ADR-0006 ✅ |
| TR-match-010 | 5 win_reason categories for post-match analysis | ADR-0006 ✅ |
| TR-match-011 | post_match_growth_tag: 5 discrete labels | ADR-0006 ✅ |
| TR-match-012 | match_id in match_completed event for LeagueStructure correlation | ADR-0006 ✅ |
| TR-match-013 | Full match simulation < 100ms | ADR-0006 ✅ |
| TR-match-014 | Home advantage bonus consumed from TownBuilding.compute_home_advantage_bonus() | ADR-0006 ✅ |
| TR-match-015 | Stadium revenue multiplier consumed from TownBuilding | ADR-0006 ✅ |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [实现比赛状态机与正式比赛入口边界](story-001-match-state-flow.md) | Integration | Ready | ADR-0006 |
| 002 | [实现阵容合法性、位置适配与队伍强度聚合](story-002-team-strength-aggregation.md) | Logic | Ready | ADR-0006 |
| 003 | [实现实际胜率修正与战术/状态影响](story-003-actual-win-probability.md) | Logic | Ready | ADR-0006 |
| 004 | [实现关键事件产量与事件分类生成](story-004-key-event-generation.md) | Logic | Ready | ADR-0006 |
| 005 | [实现中场调整与下半场独立生效](story-005-halftime-adjustment.md) | Integration | Ready | ADR-0006 |
| 006 | [实现 MatchResultPacket、胜负原因与赛后标签](story-006-match-result-packet.md) | Integration | Ready | ADR-0006 |
| 007 | [实现 seeded RNG 决定性与重复运行一致性](story-007-match-rng-determinism.md) | Logic | Ready | ADR-0006 |
| 008 | [实现存档降级恢复与重复触发防重赛](story-008-match-restore-dedup.md) | Integration | Ready | ADR-0006 |
| 009 | [实现完整比赛闭环回归样本与性能验证](story-009-match-loop-regression.md) | Integration | Ready | ADR-0006 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/match-competition-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories match-competition-system` to break this epic into implementable stories.
