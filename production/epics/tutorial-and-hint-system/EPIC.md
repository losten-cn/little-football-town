# Epic: 教程与提示系统

> **Layer**: Polish (Alpha)
> **GDD**: `design/gdd/tutorial-and-hint-system.md`
> **Architecture Module**: `TutorialHintSystem` (Polish / Presentation Support [Alpha])
> **Status**: Ready
> **Stories**: Not yet created — run `/create-stories tutorial-and-hint-system`

## Overview

教程与提示系统是承接规则说明、上下文帮助和中长期理解支持的 Alpha Polish 层系统。它只消费 OnboardingSystem 引导完成标记、主循环 UI 锚点和各系统的权威只读 payload，在合适位置提供低压力、可忽略、可回看的说明。该系统不新增任务链、奖励循环或第二套目标体系。提示必须可关闭、可禁用、可回看，关闭提示不造成任何资源损失。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| N/A | 纯 Presentation Support 层——消费已有系统权威 payload，无独立架构决策需求 | — |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-tutorial-001 | 只负责提示触发/内容/频率/帮助入口/历史语义 | N/A — Presentation Support ✅ |
| TR-tutorial-002 | 不得直接修改时间/资源/球员/训练/比赛/设施/声望/成就/技能/随机事件/存档 | N/A ✅ |
| TR-tutorial-003 | 基于 OnboardingSystem 引导完成标记区分首次用户和回访用户 | N/A ✅ |
| TR-tutorial-004 | 必须使用 UI 系统定义的界面锚点，不得自行重排界面 | N/A ✅ |
| TR-tutorial-005 | 解释规则时必须引用权威系统口径 | N/A ✅ |
| TR-tutorial-006 | 提示受冷却/频率上限/用户偏好/信息密度控制 | N/A ✅ |
| TR-tutorial-007 | 存档恢复时不得重复刷屏或丢失已显示状态 | N/A ✅ |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/tutorial-and-hint-system.md` are verified
- 提示冷却/已读/禁用状态正确持久化并通过 SaveManager 恢复
- 所有提示使用低压措辞，关闭不造成资源损失

## Next Step

Run `/create-stories tutorial-and-hint-system` to break this epic into implementable stories.
