# AI Surrogate Production MVP Validation

## Validation Rule
本项目规则已确认：AI surrogate 验证有效，不需要外部真人验证。本次复测按 Production MVP 当前路线判断“可完成、可理解、可回流”，允许 `PASS WITH WARNINGS`。本报告不提出扩 scope 建议，不要求真人补测，不建议修改 route topology、ScreenManager、gameplay authority、save/event schema，也不扩展 Match Live / Halftime 指令深度。

## Build / Commit
- Date: 2026-06-08
- Godot: 4.6.3.stable.official.7d41c59c4
- Commit: `d16c291 fix: add *.uid to .gitignore to prevent tracking of user ID files`
- Worktree note: validation ran on a dirty worktree with existing local changes in `production/session-state/active.md`, `src/ui/match/match_perf_panel.gd`, `src/ui/player/player_mgmt_panel.gd`, `tests/integration/ui/l2_playable_loop_panels_test.gd`, plus untracked production/planning evidence. This report does not revert or alter those files.

## Automated Evidence
- `godot --headless --path /home/kylin/little-football-town --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/l2_playable_loop_panels_test.gd`
  - Result: PASS
  - Output marker: `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`
- `godot --headless --path /home/kylin/little-football-town --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/main_loop_shell_navigation_test.gd`
  - Result: PASS
  - Output marker: `MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS`
- `godot --headless --path /home/kylin/little-football-town --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/what_next_guidance_test.gd`
  - Result: PASS
  - Output marker: `WHAT_NEXT_GUIDANCE_TEST_PASS`
- `godot --headless --path /home/kylin/little-football-town --script res://tests/integration/ui/mvp_visual_walkthrough_runner.gd`
  - Result: PASS WITH ENVIRONMENT WARNING
  - Output marker: `MVP_VISUAL_WALKTHROUGH_PASS`
  - Output dir: `/home/kylin/.local/share/godot/app_userdata/Football Town/mvp_visual_walkthrough`
  - Environment warning: headless dummy renderer returned null viewport textures and screenshot `save_png` errors, followed by final pass marker. Per validation rule, this is recorded as environment warning, not blocker.

Initial sandbox run of all four commands failed with `bwrap: loopback: Failed RTM_NEWADDR: Operation not permitted`; the same commands were rerun outside the sandbox after approval and produced the PASS evidence above.

## Surrogate Roles
- 新手经理：从未玩过项目，重点判断下一步是否明确。
- 经营游戏玩家：熟悉管理模拟，重点判断训练成本、收益、取舍是否清楚。
- 效率型玩家：想快速完成主循环，重点判断路线是否顺畅、停顿是否少。
- UX 专家代理：重点判断信息层级、CTA、禁用原因、结果反馈是否清楚。

## Route Completion
- 是否完成完整路线：是。固定路线 `Home -> Roster -> Player Detail -> Training -> Home -> Match Pre -> Match Live -> Match Result -> Home` 已由 MVP visual walkthrough 和 L2 panel integration 覆盖。
- 是否返回 Home：是。`ResultConfirmButton` 触发 `match_result_confirmed` 后返回 Home，`ScreenManager` active screen 重置为 `home`。
- 是否出现 wrong route：否。自动化断言覆盖 roster、player_detail、training、match_pre、match_live、match_result、home。
- 是否出现 blank page：否。headless dummy renderer 无有效截图纹理，但路由和稳定节点均存在；该截图问题记为环境 warning。
- 是否出现 blocking modal：否。当前流程使用非阻塞页面和按钮反馈。
- 提示/干预次数：0 次人工干预；What-next guidance 在 Home、Roster、Training、Match Pre、Match Result 给出非阻塞提示。

## Page-by-page Findings

### Home
- 主目标是否清楚：PASS。页面定位是俱乐部主页，目标是决定先看球员训练或进入比赛。
- 下一步是否清楚：PASS。新手经理能看到 “建议下一步” 和 what-next “先看看球员”；效率型玩家可直接点 `查看球员并训练` 或比赛入口。
- 反馈是否清楚：PASS。主页显示俱乐部概览、当前建议、比赛入口状态；比赛不可用时保持 Home 并显示玩家可理解原因，例如至少需要 7 名球员。
- 困惑点：经营游戏玩家会希望资源变化更突出，但当前已能理解进入球员/训练路线。UX 专家认为主页文案功能性足够，视觉仍是 MVP 质量。
- 判定：PASS WITH WARNING

Role answers:
- 新手经理：我在 Home；主目标是先管理球队；下一步点球员/训练 CTA；系统反馈是当前建议和比赛入口状态；不可点/不可进入比赛原因可读；未卡住。
- 经营游戏玩家：我在 Home；主目标是选择经营动作；下一步先训练；反馈说明队伍概况和资源；比赛入口原因足够；未见状态不一致。
- 效率型玩家：我在 Home；主目标是启动主循环；下一步点主 CTA；反馈直接；停顿少；未错路由。
- UX 专家代理：我在 Home；信息层级是标题、摘要、CTA、what-next；下一步明确；禁用原因有专门区域；无 blocking modal。

### Roster
- 主目标是否清楚：PASS。页面是球员列表，目标是选择球员进入详情。
- 下一步是否清楚：PASS。球员按 rating 排序，高优先级球员在前；行文包含 “关注：/用途：/下一步：”。
- 反馈是否清楚：PASS。点击球员正确进入 Player Detail，并发出 `player_selected` 与 `screen_requested`。
- 困惑点：文案密度略高，但四类 surrogate 均能理解先看哪个球员。
- 判定：PASS

Role answers:
- 新手经理：我在 Roster；目标是选球员；下一步点列表首个重点球员；反馈是进入详情；无不可点卡住。
- 经营游戏玩家：我在 Roster；目标是识别训练对象；“关注/用途/下一步”能解释选择依据；点击后路线正确。
- 效率型玩家：我在 Roster；目标是最快选人；排序和按钮名义明确；一次点击进入详情；停顿少。
- UX 专家代理：我在 Roster；列表行承担决策摘要；CTA 是球员行；稳定节点存在；无空白页。

### Player Detail
- 主目标是否清楚：PASS。页面是球员详情，目标是理解该球员用途并决定是否训练。
- 下一步是否清楚：PASS。详情包含 “用途：/本轮判断：/成本/回报：/下一步：”，训练入口按钮进入 Training。
- 反馈是否清楚：PASS。点击训练入口正确请求 `training` route。
- 困惑点：成本/回报仍是摘要式表达，不是完整数值表；但当前 MVP 可理解。
- 判定：PASS

Role answers:
- 新手经理：我在 Player Detail；目标是看这个球员为什么重要；下一步点进入训练；反馈是切到训练页；未卡住。
- 经营游戏玩家：我在 Player Detail；目标是判断投入是否值得；用途、本轮判断、成本/回报可读；取舍能建立。
- 效率型玩家：我在 Player Detail；目标是确认并继续；下一步按钮明显；一次点击进入 Training。
- UX 专家代理：我在 Player Detail；信息层级围绕用途、判断、回报、下一步；CTA 清楚；未见错误路由。

### Training
- 主目标是否清楚：PASS。页面是训练，目标是确认当前训练项目。
- 下一步是否清楚：PASS。当前选择、成本/回报、本轮判断、下一步都有锚点；确认训练按钮可见。
- 反馈是否清楚：PASS。训练项保留权威 read model：经费 100、运动点数 1、权威预览、占用本轮训练机会、结果语义。训练请求通过 `training_requested` 发出，UI 不直接改 core state。
- 困惑点：经营游戏玩家可理解成本/收益/机会成本，但视觉强调仍偏基础；UX 专家记为 polish warning，不影响完成路线。
- 判定：PASS WITH WARNING

Role answers:
- 新手经理：我在 Training；目标是完成一次训练；下一步点确认训练；反馈说明当前选择和结果；无不可理解禁用。
- 经营游戏玩家：我在 Training；目标是花资源换下场收益；经费、AP、权威预览、占用本轮训练机会都清楚；取舍达标。
- 效率型玩家：我在 Training；目标是快速确认；默认训练可选并可确认；确认后回 Home 继续主循环。
- UX 专家代理：我在 Training；决策锚点完整；按钮和摘要能支持判断；视觉层级可继续收敛但非 blocker。

### Home after Training
- 主目标是否清楚：PASS。训练完成后回到 Home，目标转为进入比赛。
- 下一步是否清楚：PASS。What-next 进入 Match Pre 阶段；比赛可用时提示 “开始这场比赛”，不可用时提示 “等到比赛开启”。
- 反馈是否清楚：PASS。训练完成事件让 Home 状态更新；比赛入口状态由 time/system payload 决定。
- 困惑点：训练完成反馈是轻量摘要，不是结果大弹窗；四类 surrogate 都能继续。
- 判定：PASS

Role answers:
- 新手经理：我回到 Home；目标是准备比赛；下一步看比赛入口；反馈显示训练后状态；未卡住。
- 经营游戏玩家：我回到 Home；目标是验证训练已消耗资源并推进比赛；入口状态合理；未见异常。
- 效率型玩家：我回到 Home；目标是继续点比赛；路线自然；停顿少。
- UX 专家代理：我回到 Home；what-next 与主 CTA 对齐；状态更新可理解；无 route stack 异常。

### Match Pre
- 主目标是否清楚：PASS。页面是比赛准备，目标是确认能否开赛。
- 下一步是否清楚：PASS。可开赛时 `开始比赛`；不可开赛时保持 Match Pre 或 Home，并显示原因。
- 反馈是否清楚：PASS。赛前摘要包含 “赛前检查：/是否适合开赛：/判断：/下一步：”；禁用原因转换为玩家可理解文案，如阵容人数要求。
- 困惑点：赛前检查目前是摘要式 checklist，非完整配置界面；当前 MVP 足够。
- 判定：PASS

Role answers:
- 新手经理：我在 Match Pre；目标是看能不能开赛；下一步点开始比赛；不能开赛时知道原因；无误导。
- 经营游戏玩家：我在 Match Pre；目标是检查阵容、战术、对手；判断文案足够支撑开赛决策。
- 效率型玩家：我在 Match Pre；目标是快速开赛；可用时一键到 Match Live；禁用时留在原页。
- UX 专家代理：我在 Match Pre；禁用状态与原因同屏；CTA 状态明确；未破坏 ScreenManager。

### Match Live
- 主目标是否清楚：PASS WITH WARNING。页面是比赛直播，目标是看当前比分、状态和关键事件。
- 下一步是否清楚：PASS。摘要包含 “现场状态：/刚刚重点：/影响：/下一步关注：”，时间线事件包含 “影响：”。
- 反馈是否清楚：PASS。比赛事件进入时间线；中场调整按钮禁用且文案说明后续开放。按规则，Match Live / Halftime 深度浅只能记 warning。
- 困惑点：互动深度浅，空时间线时反馈较轻；但玩家能理解比赛正在推进，不影响路线完成。
- 判定：PASS WITH WARNING

Role answers:
- 新手经理：我在 Match Live；目标是看比分和事件；下一步关注时间线；刚刚发生的事件和影响可读；未卡住。
- 经营游戏玩家：我在 Match Live；目标是理解比赛走势；事件影响可读，但可操作深度浅；不作为 blocker。
- 效率型玩家：我在 Match Live；目标是等结果；页面不阻断；比赛完成后自动到 Result。
- UX 专家代理：我在 Match Live；信息层级覆盖状态、重点、影响、下一步；中场禁用原因清楚；深度 warning。

### Match Result
- 主目标是否清楚：PASS。页面是比赛结束，目标是理解结果并返回 Home。
- 下一步是否清楚：PASS。摘要包含 “比赛结果：/原因：/表现/联赛影响：/下一步：”，`ResultConfirmButton` 返回主界面。
- 反馈是否清楚：PASS。结果包、原因、球员表现、联赛影响均能展示；`league_standings_updated` 可补充积分榜影响。
- 困惑点：联赛影响仍是摘要文案，不是完整表格；当前 MVP 可理解。
- 判定：PASS

Role answers:
- 新手经理：我在 Match Result；目标是看赢输和原因；下一步点返回主界面；反馈清楚；未卡住。
- 经营游戏玩家：我在 Match Result；目标是理解表现和联赛影响；原因、表现、积分榜摘要足够。
- 效率型玩家：我在 Match Result；目标是确认返回；按钮明确；回流无停顿。
- UX 专家代理：我在 Match Result；结果、原因、影响、下一步同屏；返回 CTA 有稳定节点；无 blocking modal。

### Final Home
- 主目标是否清楚：PASS。最终成功返回 Home，目标是开始下一轮经营。
- 下一步是否清楚：PASS。What-next 当前波次完成后隐藏，不干扰下一轮；Home 仍保留主 CTA。
- 反馈是否清楚：PASS。`ScreenManager` active screen 为 `home`，stack depth 回到 1。
- 困惑点：无。
- 判定：PASS

Role answers:
- 新手经理：我在 Final Home；知道本轮结束并可继续经营；没有异常按钮。
- 经营游戏玩家：我在 Final Home；理解比赛后回到经营循环；可继续下一轮。
- 效率型玩家：我在 Final Home；路线完成；无多余路由栈。
- UX 专家代理：我在 Final Home；回流稳定；状态和按钮无异常。

## Decision Readability
- Home：达标。建议下一步、俱乐部概览、比赛入口状态和禁用原因可理解。
- Roster / Player Detail：达标。Roster 使用 “关注 / 用途 / 下一步” 指向优先球员；Player Detail 使用 “用途 / 本轮判断 / 成本/回报 / 下一步” 支撑训练入口。
- Training cost / benefit / tradeoff：达标。训练页明确经费成本、AP 成本、权威收益预览、占用本轮训练机会的机会成本，并通过请求事件交给 core authority。
- Match Pre：达标。是否能开赛、为什么能/不能、下一步动作均清楚；禁用状态不跳错页。
- Match Live：达标但有 warning。比分/阶段、刚刚事件、影响、下一步关注可读；互动深度浅按规则记 warning。
- Match Result：达标。结果、原因、表现/联赛影响、确认返回 Home 可理解。

## Blockers
None.

## Warnings
- Readability：
  - 部分页文案密度偏高，尤其 Roster 行和 Training 摘要，但四类 surrogate 均能理解并继续。
  - 训练完成后的 Home 反馈偏轻量，但状态更新和下一步可读。
- Visual：
  - 当前 UI 仍是 Production MVP 质量，视觉强调和结果呈现可继续 polish。
- Depth：
  - Match Live / Halftime 互动深度浅；按本次规则仅作为 warning，不作为扩 scope 理由。
- Environment：
  - Headless dummy renderer 无法保存截图纹理，walkthrough 输出多条 null texture / `save_png` 错误，但最终输出 `MVP_VISUAL_WALKTHROUGH_PASS`。
  - 初次沙箱执行被 bwrap loopback 限制拦截；提权重跑后全部通过。
- Validation：
  - 本报告为 AI surrogate 复测；根据项目规则可作为有效验证证据，不需要外部真人补测。

## Parallel Subagent AI Equivalent Player Validation — 2026-06-08

- Validation mode: parallel AI surrogate roles plus QA guardrail verification.
- External-human validation: not required under current project rule.
- Automated guardrails:
  - `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`
  - `MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS`
  - `WHAT_NEXT_GUIDANCE_TEST_PASS`
  - `MVP_VISUAL_WALKTHROUGH_PASS`
- Main route blockers: none.
- QA note: visual walkthrough still emits headless dummy-renderer null texture / `save_png` warnings; screenshot output completeness is a reduced-confidence evidence-chain warning, not a route blocker.
- New manager role: PASS WITH WARNINGS.
- Management-game player role: PASS WITH WARNINGS.
- Efficiency player role: PASS WITH WARNINGS.
- UX expert surrogate role: PASS WITH WARNINGS.
- Final verdict: PASS WITH WARNINGS.
- Accepted warnings:
  - Copy density remains high but understandable.
  - Training completion feedback remains lightweight.
  - Match Live / Halftime depth remains shallow.
  - Match Live reads more as a viewing page than an interaction page.
  - Headless screenshot capture remains an environment/evidence-chain warning.

## Verdict
PASS WITH WARNINGS

## Next
- 收敛 warning。
- 继续后续 Production polish。
