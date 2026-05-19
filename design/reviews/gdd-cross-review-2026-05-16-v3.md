# GDD Cross-Review v3 — 2026-05-16

**Verdict: CONCERNS**

本轮为验证审查（v3），确认 v2 rerun 中 2 个残余 BLOCKING 和主场加成 WARNING 已修复。未发现新 BLOCKING。6 处 WARNING 为依赖双向性登记精度问题，不阻断架构启动。

## Scope

审查范围：`design/gdd/` 下全部 12 个系统 GDD + `game-concept.md` + `systems-index.md` + `design/registry/entities.yaml`。旧审查报告不作为证据来源。

## Previously BLOCKING — Verification

### BLOCKING 1 (MVP 经济资源显示冲突): FIXED ✅

- `main-loop-ui-framework.md:65` — 改为"经济管理系统已完成 MVP 设计；主界面资源摘要区必须显示经费和运动点数的真实当前值"
- `main-loop-ui-framework.md:191` — 占位仅限加载/错误态，不再是"系统未完成"
- `main-loop-ui-framework.md:254` — `resource_loading_placeholder_format` 语义改为加载/错误态
- `main-loop-ui-framework.md:271` — AC 要求经济数据加载完成后显示真实值
- `onboarding-system.md:59` — 引导正式解释经费和运动点数，研究点数不展示
- `onboarding-system.md:210` — 经济管理系统升级为 Hard
- `onboarding-system.md:223` — 要求正式文案，不保留"以后会显示"
- `league-competition-structure-system.md:35,53,78` — 删除 "该系统未完成前视为 provisional"
- `league-competition-structure-system.md:210,219` — 经济系统统一为 Hard 双向依赖

### BLOCKING 2 (比赛系统缺少反向依赖): FIXED ✅

- `match-competition-system.md:221` — 新增 `economy-management-system.md` Hard 下游依赖
- `match-competition-system.md:222` — 新增 `player-management-ui.md` Hard 下游依赖
- `match-competition-system.md:234` — Dependency Rule 4 更新为列出全部 Hard 消费方

### Previous WARNING (主场加成评分范围): FIXED ✅

- `town-building-system.md:299` — 明确 `facility_rating_bonus` 注入队伍评分，允许超过 100
- `town-building-system.md:558` — 边界验证添加"进入 base_win_probability 前不按属性上限钳制"
- `match-competition-system.md:97-112` — `team_match_strength` 分解为 `lineup_base_strength + facility_rating_bonus`，范围 ~1–130
- `balance-system.md:165-166` — `self_team_rating`/`opponent_team_rating` 范围扩展为 1–130
- `balance-system.md:173` — 设计注确认设施/化学修正后的队伍评分可超过 100，clamp 兜底
- `balance-system.md:258` — 新增 Edge Case 明确超过 100 的赛前有效评分为合法输入
- `design/registry/entities.yaml:168-183` — 同步 referenced_by 与范围说明

## WARNING Issues — ALL FIXED ✅ (2026-05-16)

### WARNING 1 — match 规则 19 残留旧语言 ✅ FIXED

`match-competition-system.md:60` 已移除"在该系统尚未完成前，这部分接口视为 provisional"。League 已完成设计，不再需要 provisional 限定词。

### WARNING 2 — match ↔ player-management-ui 依赖类型不匹配 ✅ FIXED

- `match-competition-system.md:226` 改为 **Soft** 下游，对齐 `player-management-ui.md:206` 的 Soft 上游声明
- `match-competition-system.md:238` 依赖规则 4 同步更新

### WARNING 3 — player-management-ui ↔ save-and-load 依赖类型不匹配 ✅ FIXED

- `save-and-load-system.md:247` 改为 **Hard** 下游 + 正式 GDD 文件名引用，对齐 `player-management-ui.md:201` 的 Hard 上游声明

### WARNING 4 — economy 未反向声明 onboarding 为下游 ✅ FIXED

- `economy-management-system.md` Downstream 新增 `design/gdd/onboarding-system.md` 为 Soft 下游

### WARNING 5 — save-and-load 对 onboarding 使用通用名称 ✅ FIXED

- `save-and-load-system.md:250` 改为 `design/gdd/onboarding-system.md` 正式引用

### WARNING 6 — league 未反向声明 onboarding 为下游 ✅ FIXED

- `league-competition-structure-system.md` Downstream 新增 `design/gdd/onboarding-system.md` 为 Soft 下游

## Design Theory Issues

### Previous CONCERNS — All RESOLVED ✅

| Concern | Status |
|---------|--------|
| CONCERN 1 — 主进度归属分散 | **RESOLVED** — 培养/比赛为 Core 双核主循环，联赛为 Feature 长期目标，小镇为支撑手段，层次清晰 |
| CONCERN 2 — RP MVP 可见性 | **RESOLVED** — 全部 GDD 一致规定 MVP 隐藏 RP，后台累积，Alpha 接入 sink |
| CONCERN 3 — 训练+青训+邻接强势路线 | **RESOLVED** — 指数成本 (1.8x)、5x5 网格约束、维护费可持续性分析均提供了制衡 |
| CONCERN 4 — 维护费+连败结构性赤字 | **RESOLVED** — town-building Formula 9 已建模分析，负场保底+赛季奖金+预警状态构成安全网 |

### New WARNINGs (design theory)

**WARNING D1 — Pillar 2 (像素小镇养成) 单点承载**

`town-building-system.md` 是唯一直接实现 Pillar 2 的系统。不同于 Pillar 1（6+系统承载）和 Pillar 3（多系统承载），Pillar 2 缺乏冗余。如果小镇建设被延迟或缩减范围，Pillar 2 将失去唯一载体。

**WARNING D2 — 训练路径乘性叠加 vs 球场/医疗加性叠加**

训练路径（训练场 1.25 × 青训 1.20 × 邻接 1.15 = 年轻球员 1.725 倍）为乘性，球场路径（+15评分 → ~6.75%胜率偏移）和医疗路径（+3AP/天）为加性。在训练为主进度的游戏中，训练乘法路径可能成为明显的最优优先投资。

**WARNING D3 — RP 银行可能在 Alpha 解锁时破坏节奏**

MVP 赛季累积 12-180 RP 无消费出口。Alpha 接入解锁树时，MVP 存档持有的大量 RP 可能让玩家瞬间解锁大量内容，破坏预期节奏。建议添加 bank cap 或 Alpha 启动时折算机制。

**WARNING D4 — 训练场是唯一的 3 连接邻接枢纽**

四个设施中训练场有 3 对邻接（训练-医疗、训练-青训、球场-训练），其余设施各仅 1 对。在 5×5 网格上，训练场不可避免地成为布局核心，降低了邻接布局的策略多样性。

### CONCERNs

**CONCERN D1 — MVP 经济循环偏薄**

MVP 经济仅包含训练消耗+建设消耗+维护费 vs 比赛收入+赛季奖金。缺少 RP 消费、随机事件波动和招募定价的经济可能被测试者认为过于简单，不足以引发"有意义的取舍"。

**CONCERN D2 — 无玩家可选难度设置**

全部调参为内部 knob。低压力长期成长是刻意设计选择，但模拟经营受众常期望难度选项。

## Cross-System Scenario Walkthrough

### Scenario 1 — 首 30 分钟新手闭环 ✅
**Flow:** Home → Roster → Train → First Match → Post-match → Home

验证状态：onboarding 和 main-loop UI 的经济占位旧口径已修复。玩家将看到真实经费和运动点数，引导正式解释资源用途。不再出现 `---` 或"以后会显示"。

### Scenario 2 — 赛后结算链 ✅
**Flow:** Match → League 更新积分榜 → Economy 结算奖励 → Time/Season → Save

验证状态：match 已反向声明 economy 和 player-management-ui 为下游消费方。赛后经济结算消费方可被架构正确建模。

### Scenario 3 — 建设完工日遇主场比赛 ℹ️
**Risk:** 同一天设施升级完成 + 主场比赛触发。比赛是否使用当日完工后的设施加成？

当前状态：GDD 未明确规定"赛前快照"是取比赛节点前设施状态还是当日完工后状态。不是设计矛盾，但架构设计时需要 time/town/match 接口中明确取值时机。**建议:** 统一规则为"比赛快照取值为比赛节点触发时的设施状态，当日已完工设施纳入快照"。

### Scenario 4 — 高维护费 + 连败赛季 ✅
**Risk:** 高等级设施 → 高维护费 → 连败低奖励 → AP/经费限制训练 → 继续连败

验证状态：town-building Formula 9 (Economic Sustainability Verification) 已建模此场景。全 Lv.5 + 全败 = -68/3天周期，50%胜率 + 全 Lv.5 = +7/周期。经济系统提供负场保底、赛季奖金和预警状态作为安全网。结构性赤字是刻意的风险/回报设计。

## Summary

| 类别 | 数量 | 说明 |
|------|:----:|------|
| 已验证修复 | 3/3 | BLOCKING 1, BLOCKING 2, 主场加成范围 — 全部修复 |
| 新 BLOCKING | 0 | 无阻断架构的跨文档矛盾 |
| WARNING (一致性) | 6 → 全部修复 ✅ | 依赖类型不匹配、单向声明、残留旧语言 — 已于 2026-05-16 修复 |
| WARNING (设计理论) | 4 | Pillar 承载体、训练路径平衡、RP 银行、训练场枢纽化 |
| CONCERN | 2 | MVP 经济薄、无难度设置 |

## Recommended Actions

1. ~~修复 W1-W6（依赖登记精度）~~ ✅ 已完成（2026-05-16）
2. 记录 WARNING D1-D4 为后续平衡测试重点，当前不阻断架构
3. 架构阶段明确 Scenario 3 的"赛前快照"时序规则
4. 架构可以通过
