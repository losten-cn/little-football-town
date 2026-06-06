# Playtest Report — MVP Player Experience

## Session Info

- **Date**: 2026-06-06
- **Build**: 当前工作区构建，基于 `main` 分支现有改动
- **Duration**: 约 5–8 分钟截图式体验走查
- **Tester**: Claude / 玩家体验者视角
- **Platform**: PC / Windows 11
- **Input Method**: Keyboard + Mouse，自动化点击路径辅助截图
- **Session Type**: Targeted MVP vertical-slice playtest
- **Review Mode**: `lean`
- **Director Gate**: CD-PLAYTEST skipped — Lean mode

## Test Focus

本次重点验证 MVP 主循环体验是否能在截图与真实 UI 路由中成立：

> Home → 查看球员 → 进入球员详情 → 安排一次训练 → 查看训练反馈 → 等待/进入比赛日 → 赛前 → 赛中 → 赛后结果 → 回到 Home

对照设计意图来自：

- `design/gdd/game-concept.md`
- `design/gdd/main-loop-ui-framework.md`
- `design/gdd/onboarding-system.md`

核心体验假设：玩家能否不靠开发者讲解，理解“培养 → 比赛 → 反馈 → 再培养”的轻度足球经营闭环。

## First Impressions (First 5 minutes)

- **Understood the goal?** Partially
- **Understood the controls?** Partially
- **Emotional response**: Functional / mildly guided, but visually dry
- **Notes**:
  - 主流程能跑通，且 Home 第一屏直接提示“建议下一步：先查看球员，并安排一次训练”，这对玩家理解路线很有帮助。
  - 训练后 Home 的“最近：High 完成训练，球队状态已更新”让玩家能感知一次行动产生了状态变化。
  - 但当前 UI 仍像调试/灰盒界面，缺少“足球小镇”的温暖感和场景感。
  - 引导条多次显示内部目标名，例如 `RosterList`、`TrainingConfirmButton`、`PreMatchStartButton`，玩家会明显感觉这是开发者锚点，不是面向玩家的教程文案。

## Gameplay Flow

### What worked well

- MVP 路由完整跑通，截图覆盖 12 个关键状态，并输出 `MVP_VISUAL_WALKTHROUGH_PASS`。
- Home 首屏有清楚的下一步建议，能够把玩家导向“查看球员并训练”。
- 训练结果能即时回写到 Home，玩家可以看到“最近：High 完成训练，球队状态已更新”。
- 比赛日 Home 从“阵容不合法”变为“阵容已就绪，可以进入比赛”，流程状态变化可见。
- Match Result 有终场比分、结果、原因、球员表现、关键事件、积分榜变化，并能返回 Home。
- 赛中页面提示“比赛进行中，离开不会中止权威比赛状态”，符合低压力与防误操作目标。

### Pain points

- **High — 引导文案暴露内部锚点名**  
  多个引导提示显示“目标：RosterList / TrainingConfirmButton / PreMatchStartButton / ResultConfirmButton”。这会破坏玩家沉浸，也不符合 `onboarding-system.md` 中“友好、简洁、鼓励性文案”的目标。

- **Medium — 玩家数据大量显示“待同步 / 属性 / 状态”等占位内容**  
  Player Detail 和 Training 页面里出现“属性：属性”“成长：成长待同步”“状态：状态待同步”。作为玩家，我能完成操作，但不太相信这些信息已经代表真实系统。

- **Medium — 比赛前信息换行严重，关键内容难读**  
  Match Pre 中 `Opponent 1`、排名摘要、阵容摘要被窄列拆成很多短行，阅读节奏差，尤其“排名摘要：第 3 vs 第 5”被切碎后不利于赛前判断。

- **Medium — 比赛中反馈偏静态，足球比赛情绪不足**  
  Match Live 只有比分、阶段、事件文本和一个占位的中场调整按钮。虽然能表达状态，但缺少“正在比赛”的节奏感、张力和观看乐趣。

- **Low — Home 上存在“阵容不合法”但缺少具体原因**  
  截图 07 显示“阵容不合法”，同时给出“查看球员并训练 / 查看球员”。这能引导玩家处理，但玩家不知道是缺少首发、位置问题、状态问题，还是系统尚未推荐阵容。

### Confusion points

- “菜单”顶部栏在当前 MVP 中看起来像可用导航，但实际主要流程在页面按钮与底部标签间完成；玩家可能不知道顶部“菜单”是否可点击。
- Roster 只显示两名球员，但 Home 写着“8 人阵容，1 人可重点训练”，玩家可能会疑惑为什么列表只看到 2 人。
- Match Live 初始截图中“比分：比分待同步 / 时间：时间待同步”会让玩家怀疑比赛是否已经真正开始。
- Match Result 显示“结果：home_win”，这是内部枚举格式，不够玩家友好。

### Moments of delight

- 训练结果“High 完成射门训练，近期成长 +2”是本轮最明确的成长反馈。
- 赛后结果“门将稳定，High 制造关键机会”让球员身份和比赛结果产生了关联，有一点“我培养的人影响比赛”的感觉。
- 最终 Home 显示“阵容已就绪，可以进入比赛”，说明训练/阵容处理后状态真的改变了，这对主循环信任感有帮助。

## Bugs Encountered

| # | Description | Severity | Reproducible |
|---|-------------|----------|-------------|
| 1 | 引导提示暴露内部锚点名，如 `RosterList`、`TrainingConfirmButton`、`PreMatchStartButton`、`ResultConfirmButton` | Medium | Yes |
| 2 | Player Detail / Training 多处展示占位文本，如“属性待同步”“成长待同步”“状态待同步” | Medium | Yes |
| 3 | Match Pre 窄列换行导致 `Opponent 1` 和排名摘要拆行严重 | Low / Medium | Yes |
| 4 | Match Live 初始状态出现“比分待同步”“时间待同步”，可能造成比赛未加载完成的误解 | Low | Yes |
| 5 | Match Result 使用内部枚举 `home_win`，不是玩家可读结果 | Low | Yes |

## Feature-Specific Feedback

### Home / 主界面

- **Understood purpose?** Yes
- **Found engaging?** Partially
- **Suggestions**:
  - 保留“建议下一步”区域，这是当前最有效的引导。
  - “阵容不合法”需要补充具体原因，例如“首发人数不足”或“缺少门将”。
  - 增加小镇/球队氛围元素，否则 Home 更像调试面板，不像“足球小镇”。

### Roster / 球员列表

- **Understood purpose?** Yes
- **Found engaging?** Partially
- **Suggestions**:
  - 当前可以选人，但列表过短且信息密度偏原始。
  - 如果 Home 写“8 人阵容”，Roster 至少应说明“当前仅显示重点球员 / 推荐球员”，否则会让玩家误解阵容人数。

### Player Detail / 球员详情

- **Understood purpose?** Partially
- **Found engaging?** No
- **Suggestions**:
  - 需要替换“属性待同步 / 状态待同步”等占位。
  - 玩家详情页应该是培养情感建立点，建议显示更可读的球员身份、擅长位置、近期状态、训练推荐原因。

### Training / 训练

- **Understood purpose?** Yes
- **Found engaging?** Partially
- **Suggestions**:
  - “射门训练 — 提升终结效率”是清楚的。
  - 训练前可以更明确地显示消耗与预期收益，例如“消耗 1 行动窗口，预计提升终结效率”。
  - 训练结果建议从“+2”扩展为更玩家友好的句子，例如“High 的终结效率提升了，下一场更容易把握机会”。

### Match Pre / 赛前

- **Understood purpose?** Partially
- **Found engaging?** Low
- **Suggestions**:
  - 信息布局需要优化，避免窄列逐字换行。
  - 赛前应清楚告诉玩家“推荐阵容已准备好，直接开始也可以”，符合低压力目标。
  - 如果阵容自动兜底已生效，应把“临时补位也能开赛”做成友好说明，而不是只显示内部合法性状态。

### Match Live / 赛中

- **Understood purpose?** Yes
- **Found engaging?** Low / Medium
- **Suggestions**:
  - 当前功能成立，但比赛观感偏文本日志。
  - 可以加入阶段标题、比分大号展示、关键事件卡片，增强足球比赛反馈。
  - “中场调整（占位）”如果还不能操作，建议改成“中场调整将在后续版本开放”或隐藏，避免玩家期待落空。

### Match Result / 赛后

- **Understood purpose?** Yes
- **Found engaging?** Medium
- **Suggestions**:
  - 这是当前最有闭环感的一页。
  - 需要把 `home_win` 改成“主场获胜”或“球队获胜”。
  - 建议强化“训练 → 比赛表现”的因果，比如“High 的射门训练帮助他制造关键机会”。

### Onboarding / 引导

- **Understood purpose?** Partially
- **Found engaging?** Low
- **Suggestions**:
  - 引导路径是有效的，但文案需要彻底玩家化。
  - 当前“目标：PreMatchStartButton”这种文本应该只留在调试日志，不应进入玩家界面。
  - 引导应该更像：“从这里查看球员状态”“试着安排一次训练”“准备好了就开始比赛”。

## Quantitative Data (if available)

- **Deaths**: N/A
- **Time per area**:
  - Home / 初始理解：约 1 分钟
  - Roster / Player Detail：约 1–2 分钟
  - Training / Result：约 1 分钟
  - Match Pre / Live / Result：约 2–3 分钟
- **Items used**: N/A
- **Features discovered vs missed**:
  - Discovered:
    - Home 下一步建议
    - 查看球员
    - 进入球员详情
    - 进入训练
    - 确认训练
    - 查看训练结果
    - 进入比赛
    - 查看赛中事件
    - 查看赛后结果
    - 返回 Home
  - Missed / unclear:
    - 排序筛选深度
    - 小镇建设存在感
    - 经济资源用途
    - 阵容不合法具体原因
    - 中场调整是否真实可用

## Overall Assessment

- **Would play again?** Maybe
- **Difficulty**: Too Easy / Low friction, but current UI feedback too placeholder
- **Pacing**: Good for route validation; too dry for player-facing fun
- **Session length preference**: Good for 5-minute MVP validation, but needs stronger feedback before longer session

整体结论：MVP 主循环已经“能走通”，但作为玩家体验还处在**功能灰盒可玩**阶段。它验证了“培养 → 比赛 → 反馈 → 回 Home”的结构成立，但还没有完全达成《足球小镇》概念中“温馨、低压力、长期成长”的情绪目标。

## Top 3 Priorities from this session

1. **把所有玩家可见的内部锚点/枚举/占位文本替换为玩家文案**  
   包括 `PreMatchStartButton`、`ResultConfirmButton`、`home_win`、各种“待同步”。

2. **优化 Match Pre / Player Detail / Training 的可读性与因果反馈**  
   尤其是赛前窄列换行、球员详情占位、训练收益说明不足。

3. **增强主循环的“足球小镇”情绪表达**  
   当前能玩但不像小镇；需要更多温暖、归属感、球队成长反馈，而不是纯按钮/文本面板。

## Action Routing

### Design changes needed

- 引导系统需要玩家化文案，不应暴露内部锚点。
- Player Detail 需要承担“球员情感连接”和“培养理由解释”，不能长期停留在占位信息。
- Match Live 需要更强比赛观感，否则足球比赛刺激感不足。

建议后续对相关设计调整运行：

- `/propagate-design-change design/gdd/onboarding-system.md`
- `/propagate-design-change design/gdd/player-management-ui.md`
- `/propagate-design-change design/gdd/match-performance-ui.md`

### Balance adjustments

- 本轮未发现明确数值平衡问题。
- 训练 +2 和 2-1 胜利目前更像脚本样本，不足以判断 balance。

如后续要调训练收益或比赛难度，建议运行：

- `/balance-check player-development`
- `/balance-check match-competition`

### Bug reports

建议正式记录以下 bug：

1. 玩家界面暴露内部引导目标 ID。
2. 多处占位同步文本进入可见 UI。
3. Match Result 使用内部枚举 `home_win`。
4. Match Pre 文本布局导致对手和排名摘要严重拆行。

可用 `/bug-report` 分别追踪。

### Polish items

- Home / Roster / Match 页面的视觉氛围仍偏调试灰盒。
- 赛中事件需要卡片化或更强层级。
- 顶部“菜单”和底部标签的导航语义需要更明确。
- 小镇元素缺席，尚未支撑“像素小镇养成”支柱。

建议进入 Polish 阶段时加入 `production/` polish backlog。

## Visual Walkthrough Evidence Summary

- **Runner**: `tests/integration/ui/mvp_visual_walkthrough_runner.gd`
- **Command**: `"D:/Program Files/godot/Godot_v4.6.2-stable_win64_console.exe" --path "E:/code/little-football-town" --script res://tests/integration/ui/mvp_visual_walkthrough_runner.gd`
- **Output Dir**: `C:/Users/kylin/AppData/Roaming/Godot/app_userdata/Football Town/mvp_visual_walkthrough`
- **Console Marker**: `MVP_VISUAL_WALKTHROUGH_PASS`

| Step | Screenshot | Expected | Result | Notes |
|---|---|---|---|---|
| 01 | `01_home_initial.png` | Home initial | PASS WITH WARNINGS | 下一步建议清楚，但视觉像灰盒 |
| 02 | `02_roster.png` | Roster | PASS WITH WARNINGS | 可选球员，但人数与 Home 摘要可能不一致 |
| 03 | `03_player_detail.png` | Player Detail | PASS WITH WARNINGS | 多处待同步/占位 |
| 04 | `04_training.png` | Training | PASS WITH WARNINGS | 能确认训练，但收益解释偏弱 |
| 05 | `05_training_result.png` | Training Result | PASS | 成长 +2 反馈清楚 |
| 06 | `06_home_after_training.png` | Home after training | PASS | 最近训练反馈回写 |
| 07 | `07_home_match_disabled_reason.png` | Disabled / blocked reason | PASS WITH WARNINGS | 有“阵容不合法”，但原因不够具体 |
| 08 | `08_match_pre.png` | Match Pre | PASS WITH WARNINGS | 信息拆行严重 |
| 09 | `09_match_live_empty.png` | Match Live | PASS WITH WARNINGS | 初始同步占位会造成困惑 |
| 10 | `10_match_live_timeline.png` | Match Live timeline | PASS WITH WARNINGS | 有事件，但观感偏静态 |
| 11 | `11_match_result.png` | Match Result | PASS WITH WARNINGS | 结果完整，但内部枚举可见 |
| 12 | `12_home_final.png` | Home final | PASS | 能返回 Home |

## Playtest Verdict

**PASS WITH WARNINGS**

- 没有发现阻断路线的问题。
- 没有黑屏、空页、错误路由、无法返回 Home 等 blocker。
- 但当前体验仍偏“功能验证版”，引导文案、占位字段、比赛表现和小镇氛围需要进入下一轮修正。
