# GDD Cross-Review Rerun — 2026-05-16

**Verdict: FAIL**

旧 8 个 BLOCKING 中多数已修复，但复审仍发现 2 类残余 BLOCKING，以及若干 WARNING / CONCERN。当前不建议进入 `/create-architecture`，应先修复以下阻断。

## Scope

Reviewed the current system GDD set under `design/gdd/`, using `design/registry/entities.yaml` as the formula/entity baseline. Previous review reports and review logs were excluded from the system-GDD evidence set.

## BLOCKING Issues

### BLOCKING 1 — 主循环 UI 与经济系统的 MVP 资源显示规则冲突

`economy-management-system.md` 已明确经济系统在 MVP 阶段成立，并要求主界面显示经费与运动点数：

- `design/gdd/economy-management-system.md:68` — MVP 目标要求经费和运动点数在界面可见并参与结算变化。
- `design/gdd/economy-management-system.md:98` — 主循环 UI 是 Hard 下游，消费经费、运动点数、预警状态与结算摘要。
- `design/gdd/economy-management-system.md:323` — 主循环 UI 必须正确展示经费和运动点数。
- `design/gdd/economy-management-system.md:354` — 验收标准要求新档进入主界面时经费和运动点数当前值均可见。

但 `main-loop-ui-framework.md` 仍保留经济系统未完成/资源占位的旧口径：

- `design/gdd/main-loop-ui-framework.md:65` — 仍称经济管理系统在 MVP 设计阶段尚未完成，资源展示使用临时占位数据。
- `design/gdd/main-loop-ui-framework.md:191` — 仍定义经济系统未实现时资源摘要区使用 `---` 等临时占位。
- `design/gdd/main-loop-ui-framework.md:254` — 仍保留 `resource_placeholder_format` 作为经济系统未完成前的占位样式。
- `design/gdd/main-loop-ui-framework.md:271` — 验收标准仍要求经济系统尚未实现时资源区使用临时占位格式。

这两套验收标准不能同时通过：一个要求 MVP 显示真实经费/AP，另一个允许 MVP 使用占位资源。

**Required fix:** 统一 `main-loop-ui-framework.md`：删除“经济系统未完成”的旧口径，把资源占位规则限定为“数据加载中/错误态”而不是“系统未实现”。

### BLOCKING 2 — 比赛系统依赖反向声明仍不完整

#### 2A. Economy → Match 缺少反向声明

`economy-management-system.md` 明确依赖比赛结果与奖励口径：

- `design/gdd/economy-management-system.md:95` — 比赛竞技系统是 Hard 上游，提供比赛结果 → 奖励口径。
- `design/gdd/economy-management-system.md:132` — `post_match_funds` 公式依赖比赛结果倍率。
- `design/gdd/economy-management-system.md:301` — 依赖表中要求比赛系统提供胜负/评分到奖励基数的口径。

但 `match-competition-system.md` 的 Dependencies 没有把 economy-management-system 列为下游消费方。

**Required fix:** 在 `match-competition-system.md` Downstream Dependencies 中增加 `design/gdd/economy-management-system.md`，声明其消费比赛结果包、胜负结果、评分/奖励口径、`post_match_growth_tag` 以外的赛后结算数据。

#### 2B. Player Management UI → Match 缺少反向声明

`player-management-ui.md` 消费比赛回传数据，而 `match-competition-system.md` 已定义这些输出：

- `design/gdd/match-competition-system.md:153` — 定义 `post_match_growth_tag`。
- `design/gdd/match-competition-system.md:162` — 定义 `player_performance_score`。
- `design/gdd/match-competition-system.md:269` — 验收要求每名出场球员获得成长标签与出场时间记录。

但 `match-competition-system.md` Downstream Dependencies 未声明 `player-management-ui.md`。

**Required fix:** 在 `match-competition-system.md` Downstream Dependencies 中增加 `design/gdd/player-management-ui.md`，声明其消费球员赛后标签、表现评分、出场时间与详情页补充展示数据。

## Previously Blocking Issues — Verification

### 已修复：win-prob clamp `[0.02]` vs `[0.05]`

`balance-system.md` 与 `match-competition-system.md` 现在均使用 `[0.05, 0.95]`。旧的概率钳制冲突已解决。

### 已修复：RP zero MVP sinks

- `design/gdd/economy-management-system.md:68` 规定研究点数 MVP 后台累积、不显示。
- `design/gdd/economy-management-system.md:284` 明确 RP 无消费出口在 MVP 阶段是预期行为，Alpha 阶段接入解锁树后使用。

该问题不再是 blocker，但仍是整体经济闭环的后续设计风险。

### 已修复：promotion-final `league_tier_multiplier` undefined

`economy-management-system.md` 已定义比赛奖励使用联赛层级倍率。旧问题中“最后一轮晋级后该场奖励使用哪个 tier”已通过“赛前所在层级”口径修复。

### 未完全修复：6 个 dependency bidirectionality gaps

旧的 6 个依赖双向性问题已减少，但仍至少剩余上述 2 个 match 反向声明问题，因此该类 blocker 未完全清零。

## Warnings

### WARNING 1 — Onboarding 仍有经济系统 provisional / placeholder 陈旧引用

`onboarding-system.md` 仍把经济系统描述为 MVP 未完成：

- `design/gdd/onboarding-system.md:59` — 引导中跳过经费和运动点数详细解释，只说“这里以后会显示你的资源”。
- `design/gdd/onboarding-system.md:184` — 经济管理系统未完成时使用占位说明。
- `design/gdd/onboarding-system.md:210` — 经济管理系统仍是 Soft provisional。
- `design/gdd/onboarding-system.md:223` — 仍写“当经济管理系统 GDD 完成后”再升级为 Hard。

这与经济系统当前已设计完成、MVP 显示经费/AP 的状态不一致。

**Recommended fix:** 将 onboarding 对经济系统的依赖升级为 Hard，并把引导文案改为正式解释经费和运动点数，但继续不解释研究点数。

### WARNING 2 — League 仍有经济系统 provisional 旧口径

`league-competition-structure-system.md` 中经济系统状态混用：

- `design/gdd/league-competition-structure-system.md:35` — 称赛季奖励由经济系统拥有，但经济系统未完成前视为 provisional。
- `design/gdd/league-competition-structure-system.md:53` — 称经济管理系统在 MVP 设计阶段尚未完成。
- `design/gdd/league-competition-structure-system.md:78` — 仍有 provisional assumption。
- `design/gdd/league-competition-structure-system.md:210` — 经济管理系统仍为 Soft provisional。
- `design/gdd/league-competition-structure-system.md:219` — 同一依赖区又把经济管理系统列为 Hard 回传。

**Recommended fix:** 统一为 Hard 双向依赖：League 输出晋级/降级/排名标签，Economy 消费这些标签计算赛季奖励；删除 provisional 文本。

### WARNING 3 — Town-building 主场加成范围需要与 Match / Balance 明确对齐

`town-building-system.md` 当前允许球场主场加成与邻接加成叠加：

- `design/gdd/town-building-system.md:297` — `home_advantage_bonus(level) = home_advantage_per_level × level`
- `design/gdd/town-building-system.md:308` — 输出范围 0–10，Lv.5 为 +10。
- `design/gdd/town-building-system.md:541` — `adj_stadium_home_bonus` clamp 到 0–5。
- `design/gdd/town-building-system.md:558` — 最大情况为 10 + 5 = 15，并说明自然流入比赛系统。
- `design/gdd/town-building-system.md:809` — 验收要求 Lv.5 `home_advantage_bonus = 10.0`。
- `design/gdd/town-building-system.md:827` — 验收要求最大主场总加成 = 15.0。

这不一定错误，但必须明确 match/balance 是否接受 `team_match_strength` 超过原本 `1–100` 的评分边界。如果 balance 仍假设 `self_team_rating` 为 1–100，则 town 的 +15 可能使范围假设失效。

**Recommended fix:** 二选一：

1. 明确 `team_match_strength` 允许设施修正后超过 100，并由胜率 clamp 兜底；或
2. 将 town 输出改为进入 match 前被统一 clamp 到 balance 系统声明的评分范围。

### WARNING 4 — `systems-index.md` 状态陈旧

`systems-index.md` 仍显示若干状态与实际 GDD 进度不一致：

- `design/gdd/systems-index.md:27` — 经济管理系统仍为 Alpha / Not Started。
- `design/gdd/systems-index.md:197` — 经济管理系统又列为 Needs Revision。
- `design/gdd/systems-index.md:28` / `198` — 小镇建设状态也不完全匹配已修复/已审查记录。
- `design/gdd/systems-index.md:205-209` — 多个 UI/onboarding 文档仍 Needs Revision，与本次复审结果有关但需要统一更新。

**Recommended fix:** 在修复 blocker 后统一更新 systems index，避免下一轮审查继续从陈旧系统状态出发。

## Design Theory Concerns

### CONCERN 1 — 主进度归属略分散

球员养成、联赛晋级、小镇扩张都具备长期成长目标。当前最合理的主轴应是：球员培养与比赛表现是主循环；联赛晋级是长期目标；小镇建设是支撑与强化手段。

如果三者在文案和系统深度上都被描述成“主进度”，玩家可能不清楚自己应该优先优化什么。

### CONCERN 2 — MVP 经济闭环仍需观察 RP

RP 在 MVP 阶段后台累积但不可消费是可接受的设计决定，但需要避免玩家看到或感知到“我获得了一个没用的资源”。当前 economy 已规定 MVP 不显示 RP，这是正确方向；UI/onboarding 必须保持一致。

### CONCERN 3 — 训练场 + 青训营 + 邻接可能形成强势路线

Town-building 的训练效率、青训成长、邻接倍率都服务球员成长。如果该路线回报明显高于球场/医疗室，可能使其他建设路线变弱。当前不一定是 blocker，但需要在后续平衡测试中重点验证。

### CONCERN 4 — 维护费 + 连败可能形成结构性赤字

经济系统已通过负场保底奖励缓解贫困螺旋，但 town-building 高等级维护费仍可能使连续失败玩家进入不可持续状态。需要在数值测试中验证“全高维护 + 连败”是否仍能恢复。

## Cross-System Scenario Walkthrough

### Scenario 1 — 首 30 分钟新手闭环

**Flow:** Home → Roster → Train → First Match → Post-match → Home

**Expected systems:**

- main-loop-ui 展示经费/AP。
- onboarding 解释主界面、球员列表、首次训练、首场比赛。
- economy 执行训练消耗与比赛奖励。
- match 输出比赛结果与成长标签。
- player-management-ui 展示赛后成长反馈。

**Issue:** 当前 onboarding 与 main-loop UI 的经济占位旧口径会导致玩家看到“以后会显示资源”或 `---`，但 economy 要求 MVP 已显示真实经费/AP。新手首 30 分钟路径会直接撞上 BLOCKING 1。

### Scenario 2 — 赛后结算链

**Flow:** 比赛结束 → match 输出结果包 → league 更新积分榜 → economy 结算奖励 → time/season 触发阶段或赛季结算 → save 进入稳定节点。

**Expected order:**

1. Match result finalized
2. League consumes result
3. Economy consumes match/league tags
4. Time/season settlement checks
5. Save/load persists stable state

**Issue:** Economy 依赖 match 奖励口径，但 match 未反向声明 economy；如果架构直接按 GDD 依赖建接口，会漏掉赛后经济结算消费方。

### Scenario 3 — 建设完工日遇主场比赛

**Flow:** 同一天设施升级完成 + 主场比赛触发。

**Risk:** Town-building 输出 `home_advantage_bonus` / `adj_stadium_home_bonus`；match 在赛前读取 `team_match_strength`。需要明确比赛快照取值时机：是比赛节点前先处理建设完工，还是比赛使用前一日设施状态。

**Current status:** 不是 blocker，但建议后续在 time/town/match 的接口设计中明确“赛前快照”顺序。

### Scenario 4 — 高维护费 + 连败赛季

**Flow:** 高等级设施维护费每日扣除 → 连败只拿低比赛奖励 → AP/经费限制训练 → 战力增长变慢 → 继续连败。

**Risk:** 可能形成负反馈螺旋。Economy 已有负场保底奖励，但 town-building 的高等级维护费仍需数值验证。

## Recommended Fix Order

1. 修复 `main-loop-ui-framework.md` 的经济系统旧口径，确保 MVP 真实显示经费/AP。
2. 修复 `onboarding-system.md` 的资源摘要引导文案和经济依赖状态。
3. 修复 `league-competition-structure-system.md` 的 economy provisional 文本与 Soft/Hard 混用。
4. 补齐 `match-competition-system.md` 对 economy 与 player-management-ui 的反向依赖声明。
5. 明确 town → match → balance 的主场加成评分范围。
6. 最后更新 `systems-index.md` 状态。
