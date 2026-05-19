# 足球小镇：系统索引

> **Status**: In Design
> **Author**: 用户 + Claude
> **Last Updated**: 2026-05-16
> **Source Set**:
> - `design/gdd/game-concept.md`
> - `E:\code\game\game-design\00-足球小镇-策划总览.md`
> - `E:\code\game\game-design\02-足球小镇-数值平衡方案.md`
> - `E:\code\game\game-design\03-足球小镇-玩家留存与商业化.md`
> - `E:\code\game\game-design\04-足球小镇-音效与音乐设计.md`
> - `E:\code\game\ui-design\足球小镇-UI交互设计文档.md`

## Overview

本索引用于把《足球小镇》的玩法概念拆解为可独立设计、实现、评审和排期的系统集合。它既记录“游戏需要哪些系统”，也记录这些系统之间的依赖关系、优先级层次以及推荐的 GDD 编写顺序。当前拆分遵循“Foundation → Core → Feature → Presentation → Polish”的设计顺序，并以 MVP 验证“培养 + 比赛”核心循环是否成立为最高优先目标。

## Systems Enumeration

| System name | Category | Layer | Priority | Status | Explicit / Inferred | Brief description |
|---|---|---|---|---|---|---|
| 数值系统 | Balance / Rules | Foundation | MVP | Designed | Explicit | 定义属性、成长、资源、比赛与经济的核心公式与数值边界。 |
| 存档与读档系统 | Foundation / Infrastructure | Foundation | MVP | Designed | Inferred | 负责保存小镇、球员、资源、赛季与解锁状态，是长期经营体验的基础。 |
| 时间与赛季推进系统 | Foundation / Infrastructure | Foundation | MVP | Designed | Inferred | 负责管理日常循环、比赛节点、阶段结算和赛季推进节奏。 |
| 运动员培养系统 | Progression / Character | Core | MVP | Approved | Explicit | 负责球员招募、训练、成长、技能、状态与长期养成反馈。 |
| 比赛竞技系统 | Gameplay / Match | Core | MVP | Designed | Explicit | 负责阵型、战术、比赛演算、胜负结果与赛后反馈。 |
| 经济管理系统 | Economy | Core | MVP | Designed | Explicit | 负责经费、研究点数、运动点数的获取、消耗与经营压力；MVP 展示经费和运动点数，研究点数后台累积。 |
| 小镇建设系统 | World / Management | Core | Alpha | Designed | Explicit | 负责设施建造、升级、布局规划以及对培养和比赛的长期加成。 |
| 声望与成就系统 | Meta Progression | Feature | Alpha | Not Started | Explicit | 负责阶段性解锁、等级成长、长期收集与重玩动力。 |
| 随机事件系统 | Content / Event | Feature | Beta | Not Started | Explicit | 负责制造变化、提供剧情化决策点并增强世界活力。 |
| 技能与特性系统 | Character Depth | Feature | Alpha | Not Started | Inferred | 负责球员差异化成长路线与长期培养深度。 |
| 联赛与赛事结构系统 | Progression / Competition | Feature | MVP | Designed | Inferred | 负责赛季编排、联赛层级、晋级结构和终局赛事目标。 |
| 多周目与挑战模式系统 | Replayability | Feature | Full Vision | Not Started | Explicit | 负责通关后的继承、挑战规则和长期重玩价值。 |
| 商业化与 DLC 规划系统 | Product / Meta | Polish | Full Vision | Not Started | Explicit | 负责买断制、DLC 节奏和发售后扩展规划，主要服务产品层。 |
| 主循环 UI 框架 | UI / UX | Presentation | MVP | Designed | Explicit | 负责主界面、球员界面、比赛界面的基础导航与信息展示。 |
| 球员管理 UI | UI / UX | Presentation | MVP | Not Started | Inferred | 负责球员列表、详情、培养入口和状态可视化。 |
| 比赛表现 UI | UI / UX | Presentation | MVP | Not Started | Inferred | 负责赛前准备、比赛过程、赛后结算等比赛相关界面。 |
| 建设与经营 UI | UI / UX | Presentation | Alpha | Not Started | Inferred | 负责建设模式、资源管理、设施信息与布局交互。 |
| 新手引导系统 | UX / Onboarding | Polish | MVP | Designed | Explicit | 负责让玩家快速理解核心循环与基础操作。 |
| 音频系统 | Audio | Presentation | Beta | Not Started | Explicit | 负责 BGM、音效、动态情绪反馈与沉浸氛围。 |
| 教程与提示系统 | UX Support | Polish | Alpha | Not Started | Inferred | 负责提示、说明、反馈强化和中长期系统理解支持。 |

## Dependency Map

### Foundation

- 数值系统
- 存档与读档系统
- 时间与赛季推进系统

### Core

- 运动员培养系统
  - depends on: 数值系统、时间与赛季推进系统、存档与读档系统
- 比赛竞技系统
  - depends on: 数值系统、时间与赛季推进系统、存档与读档系统、运动员培养系统、经济管理系统、球员管理 UI
- 经济管理系统
  - depends on: 数值系统、时间与赛季推进系统、存档与读档系统、比赛竞技系统、联赛与赛事结构系统、小镇建设系统、主循环 UI 框架
- 小镇建设系统
  - depends on: 数值系统、经济管理系统、时间与赛季推进系统、存档与读档系统

### Feature

- 声望与成就系统
  - depends on: 比赛竞技系统、运动员培养系统、小镇建设系统、经济管理系统
- 随机事件系统
  - depends on: 时间与赛季推进系统、运动员培养系统、经济管理系统、小镇建设系统
- 技能与特性系统
  - depends on: 运动员培养系统、数值系统
- 联赛与赛事结构系统
  - depends on: 比赛竞技系统、时间与赛季推进系统、经济管理系统
- 多周目与挑战模式系统
  - depends on: 声望与成就系统、联赛与赛事结构系统、存档与读档系统

### Presentation

- 主循环 UI 框架
  - depends on: 运动员培养系统、比赛竞技系统、经济管理系统、时间与赛季推进系统
- 球员管理 UI
  - depends on: 运动员培养系统
- 比赛表现 UI
  - depends on: 比赛竞技系统、联赛与赛事结构系统
- 建设与经营 UI
  - depends on: 小镇建设系统、经济管理系统
- 音频系统
  - depends on: 比赛竞技系统、小镇建设系统、随机事件系统、主循环 UI 框架

### Polish

- 新手引导系统
  - depends on: 主循环 UI 框架、运动员培养系统、比赛竞技系统、经济管理系统、球员管理 UI、比赛表现 UI
- 教程与提示系统
  - depends on: 主循环 UI 框架、球员管理 UI、建设与经营 UI、比赛表现 UI
- 商业化与 DLC 规划系统
  - depends on: 核心系统集完成后形成的完整内容结构

## Bottleneck Systems

以下系统是高风险瓶颈系统，因为多个后续系统都依赖它们：

1. **数值系统**
   - 是培养、比赛、经济、建设等系统的共同规则底座。
   - 如果边界不清，后续多个 GDD 都会反复返工。

2. **时间与赛季推进系统**
   - 决定日常循环、比赛频率、阶段目标和赛季节奏。
   - 如果时序规则模糊，会直接影响培养、赛事和事件设计。

3. **运动员培养系统**
   - 是核心幻想之一，也是比赛、技能、球员 UI 和长期成长的依附基础。

4. **比赛竞技系统**
   - 是另一条核心循环主轴，联赛结构、音频反馈、赛后结算和长期成就都依赖它。

## Recommended Design Order

1. 数值系统
2. 时间与赛季推进系统
3. 存档与读档系统
4. 运动员培养系统
5. 比赛竞技系统
6. 主循环 UI 框架
7. 联赛与赛事结构系统
8. 经济管理系统
9. 小镇建设系统
10. 球员管理 UI
11. 比赛表现 UI
12. 声望与成就系统
13. 技能与特性系统
14. 建设与经营 UI
15. 新手引导系统
16. 教程与提示系统
17. 随机事件系统
18. 音频系统
19. 多周目与挑战模式系统
20. 商业化与 DLC 规划系统

## Priority Rationale

### MVP

- 数值系统
- 存档与读档系统
- 时间与赛季推进系统
- 运动员培养系统
- 比赛竞技系统
- 联赛与赛事结构系统
- 主循环 UI 框架
- 球员管理 UI
- 比赛表现 UI
- 新手引导系统

**Why:** 这些系统共同构成“培养 → 比赛 → 反馈 → 再培养”的最小可验证闭环。没有它们，玩家无法完整体验游戏最核心的成长与竞技节奏。

### Alpha

- 经济管理系统
- 小镇建设系统
- 声望与成就系统
- 技能与特性系统
- 建设与经营 UI
- 教程与提示系统

**Why:** 这些系统负责把 MVP 的可玩核心提升为具有持续经营深度、阶段解锁和更明确成长结构的完整框架。

### Beta

- 随机事件系统
- 音频系统

**Why:** 这些系统显著增强世界活力、情绪表达和沉浸感，但并不是验证核心循环趣味性的最小前提。

### Full Vision

- 多周目与挑战模式系统
- 商业化与 DLC 规划系统

**Why:** 这些系统主要服务长期留存、发售后扩展和完整商业目标，应建立在核心体验已经稳定成立的前提下。

## High-Risk Notes

- `数值系统` 与 `比赛竞技系统` 的边界必须尽早明确，否则“谁定义结果、谁控制体验”会反复冲突。
- `时间与赛季推进系统` 需要尽早确定是否统一驱动训练、建设、赛事和事件触发。
- `小镇建设系统` 在 MVP 阶段应控制范围，避免邻接效应和复杂布局过早吞噬开发资源。
- `音频系统` 当前适合后置，但概念层必须保留关键反馈点，避免后续完全脱节。
- `商业化与 DLC 规划系统` 建议作为支持文档存在，不要过早挤占核心玩法设计资源。

## Progress Tracker

| System name | Layer | Priority | Status | Design Doc |
|---|---|---|---|---|
| 数值系统 | Foundation | MVP | Designed | `design/gdd/balance-system.md` |
| 存档与读档系统 | Foundation | MVP | Designed | `design/gdd/save-and-load-system.md` |
| 时间与赛季推进系统 | Foundation | MVP | Designed | `design/gdd/time-and-season-progression-system.md` |
| 运动员培养系统 | Core | MVP | Approved | `design/gdd/player-development-system.md` |
| 比赛竞技系统 | Core | MVP | Designed | `design/gdd/match-competition-system.md` |
| 经济管理系统 | Core | MVP | Designed | `design/gdd/economy-management-system.md` |
| 小镇建设系统 | Core | Alpha | Designed | `design/gdd/town-building-system.md` |
| 声望与成就系统 | Feature | Alpha | Not Started | - |
| 随机事件系统 | Feature | Beta | Not Started | - |
| 技能与特性系统 | Feature | Alpha | Not Started | - |
| 联赛与赛事结构系统 | Feature | MVP | Designed | `design/gdd/league-competition-structure-system.md` |
| 多周目与挑战模式系统 | Feature | Full Vision | Not Started | - |
| 商业化与 DLC 规划系统 | Polish | Full Vision | Not Started | - |
| 主循环 UI 框架 | Presentation | MVP | Designed | `design/gdd/main-loop-ui-framework.md` |
| 球员管理 UI | Presentation | MVP | Designed | `design/gdd/player-management-ui.md` |
| 比赛表现 UI | Presentation | MVP | Designed | `design/gdd/match-performance-ui.md` |
| 建设与经营 UI | Presentation | Alpha | Not Started | - |
| 新手引导系统 | Polish | MVP | Designed | `design/gdd/onboarding-system.md` |
| 音频系统 | Presentation | Beta | Not Started | - |
| 教程与提示系统 | Polish | Alpha | Not Started | - |

## Progress Summary

- Total systems: 20
- MVP systems: 11
- Alpha systems: 5
- Beta systems: 2
- Full Vision systems: 2

## Recommended Next GDD

按当前推荐顺序，下一批优先开始设计的系统是：

1. 声望与成就系统
2. 技能与特性系统
3. 建设与经营 UI

其中**最推荐下一篇 GDD**是：`声望与成就系统`。
原因是 MVP 核心闭环与经济/小镇支撑系统已完成设计并完成本轮 blocker 修复。下一步应补齐长期目标、里程碑反馈和成就触发语义，为联赛晋级、小镇成长和球员培养提供更清晰的中长期目标框架。
