# Epic: 新手引导系统

> **Layer**: Polish
> **GDD**: design/gdd/onboarding-system.md
> **Status**: Planned
> **Topology**: L3 — after stable UI anchors
> **Current Wave**: Minimum what-to-do-next guidance only
> **Stories**: 1 current-wave story

## Overview

本 epic 当前波次不启动完整 Tutorial/Hint 系统，只在 Home、Roster/Training、Pre-Match、Result 的稳定 anchors 上提供非模态“下一步做什么”提示，帮助首次玩家在 5 分钟内完成 `Home → Roster/Training → Match → Result → Home`。

## Goal

- 降低玩家在 MVP playable loop 中卡住的风险。
- 用轻量、非阻塞、动作导向的提示指向下一步。
- 避免把 current wave 扩张为 full onboarding/tutorial stack。

## Scope

### In Scope

- Home、Roster/Training、Pre-Match、Result 四处最小 guidance。
- 单次只显示一个当前 checkpoint 的提示。
- 核心提示文案不超过 25 字。
- 非模态高亮或 text-only fallback。
- 玩家关闭/跳过提示后不得阻断合法操作。
- 缺 anchor 时降级为 text-only，不报错、不错误高亮。

### Out of Scope

- Full Tutorial/Hint 系统。
- hint eligibility、`hint_record_key`、cooldown、anchor registry。
- seen/preferences/onboarding_done 持久化。
- Match Live / Halftime guidance。
- 帮助中心、可回看教程、埋点分析。

## Traceability

| TR-ID | Current-Wave Coverage | Story |
|---|---|---|
| `TR-onboard-001` | Partial minimum path only | Story 001 |
| `TR-onboard-002` | In scope | Story 001 |
| `TR-onboard-003` | In scope | Story 001 |
| `TR-onboard-005` | In scope | Story 001 |
| `TR-onboard-009` | In scope | Story 001 |
| `TR-onboard-010` | In scope | Story 001 |

## Stories

| # | Story | Type | Status | Notes |
|---|---|---|---|---|
| 001 | [实现 Minimum What-to-Do-Next Guidance](story-001-minimum-what-next-guidance.md) | UI | Planned | Depends on Home, Roster/Training, Pre-Match, and Result anchors being stable. |

## Status / Notes

- This is L3 support work and must not push upstream UI to invent unstable anchors.
- `TR-onboard-001` remains partially covered only; Match Live/Halftime guidance is deferred.
- No persistence is included in this wave.
