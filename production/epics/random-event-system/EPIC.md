# Epic: 随机事件系统

> **Layer**: Feature (Beta)
> **GDD**: `design/gdd/random-event-system.md`
> **Architecture Module**: `RandomEventSystem` (Feature Contract Layer)
> **Status**: Ready
> **Stories**: 2 stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [Authority Stub](story-001-auth-stub.md) | Logic + Integration | Ready | ADR-0012 |
| 002 | [Window Skeleton](story-002-window-skeleton.md) | Logic | Ready | ADR-0012 |

## Overview

随机事件系统是负责制造小镇生活变化、赛季插曲和轻量决策点的 Beta 内容层。它在 TimeManager 声明的合法稳定窗口内生成事件，把玩家选择或自动结算结果转化为提交给对应权威系统的事件效果请求。权威实现 `RandomEventManager` 独占 `pending_random_event_instance`、`recent_random_event_history`、`event_cooldown_state` 和 `processed_event_settlement_keys` 的 durable truth，不直接修改资源/球员/设施/比赛。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0012: Random Event Settlement Contracts | 所有一次性事件结果使用稳定 `event_settlement_key` 去重；效果只能通过目标权威系统提交；展示层只消费只读 payload | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-randomevent-001 | RandomEventManager 独占 durable truth | ADR-0012 ✅ |
| TR-randomevent-002 | 只能由合法稳定窗口触发 | ADR-0012 ✅ |
| TR-randomevent-003 | 效果只能通过目标权威系统提交 | ADR-0012 ✅ |
| TR-randomevent-004 | 使用 event_settlement_key 去重 | ADR-0012 ✅ |
| TR-randomevent-005 | 稳定摘要算法构建 settlement key | ADR-0012 ✅ |
| TR-randomevent-006 | UI payload 只读，展示层不得重抽/重算 | ADR-0012 ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/random-event-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- `RandomEventManager` durable truth fields match ADR-0012 specification

## Next Step

Run `/create-stories random-event-system` to break this epic into implementable stories.
