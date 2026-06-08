# Production 决策可读性收敛切片 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 在不改变路由拓扑、ScreenManager 语义、gameplay authority、稳定 payload 字段和 Match Live/Halftime 深度的前提下，收敛现有 MVP 路线的决策可读性。

**Architecture:** 本切片只作用于展示层与请求层，使用现有 payload、稳定节点和既有事件流转。执行顺序先冻结共享决策骨架，再并行收敛 Player/Training 与 Match 面板，最后串行收口 Home 对齐、integration 测试和 walkthrough 证据。

**Tech Stack:** Godot 4.6, GDScript, custom headless integration runner, existing UI Control scripts.

---

## Guardrails

- 不改 route topology。
- 不改 ScreenManager push/reset 语义。
- 不改 gameplay authority 或训练/比赛状态归属。
- 不新增稳定 payload 字段。
- 不改事件名、稳定节点名、按钮名。
- 不扩 Match Live/Halftime 真实指令深度。
- 允许保留当前 Production warnings：外部真人验证未声称、远端 GitHub Actions 绿灯未声称、Live/Halftime 深度延期、视觉暖感仍可继续 polish。

## Shared Decision Skeleton

所有受影响摘要必须更快回答：

1. 现状是什么。
2. 现在能不能做。
3. 为什么。
4. 成本、回报或影响是什么。
5. 下一步建议是什么。

Player/Training 线统一为：`关注 → 用途 → 本轮判断 → 成本/回报 → 下一步`。

Match 线统一为：

- Pre-match: `现状/可开赛 → 判断 → 下一步`
- Live: `现状 → 刚刚发生 → 这意味着什么`
- Result: `结果 → 原因 → 表现/联赛影响 → 下一步`

---

### Task 1: Freeze Shared Decision Skeleton

**Files:**
- Modify: `src/ui/player/player_mgmt_panel.gd`
- Modify: `src/ui/match/match_perf_panel.gd`
- Reference only if needed: `src/ui/hud/main_loop_shell.gd`

- [ ] **Step 1: Inspect existing formatter boundaries**

Read these formatter sections before editing:

```text
src/ui/player/player_mgmt_panel.gd
- roster row formatting
- player detail summary formatting
- training selection/result formatting

src/ui/match/match_perf_panel.gd
- pre-match summary formatting
- live summary formatting
- result summary formatting
```

Expected: confirm each change can be made inside formatter/display helpers without changing route IDs, events, payload keys, or authority calls.

- [ ] **Step 2: Freeze exact label anchors**

Use these label anchors in formatter output:

```text
Player/Training:
关注：
用途：
本轮判断：
成本/回报：
下一步：

Match Pre:
赛前检查：
是否适合开赛：
判断：
下一步：

Match Live:
现场状态：
刚刚重点：
影响：
下一步关注：

Match Result:
比赛结果：
原因：
表现/联赛影响：
下一步：
```

Expected: these labels are purely user-facing text assembled from existing payload values.

- [ ] **Step 3: Do not add shared abstraction yet**

Keep this task as a contract-only task. Do not create a new shared helper file, resource, autoload, or localization layer in this slice.

Expected: the implementation remains local to the existing panel scripts.

---

### Task 2A: Converge Player / Training Panel

**Files:**
- Modify: `src/ui/player/player_mgmt_panel.gd`
- Test: `tests/integration/ui/l2_playable_loop_panels_test.gd`

- [ ] **Step 1: Update roster row wording only**

In `src/ui/player/player_mgmt_panel.gd`, update roster row text so each selectable row keeps these anchors:

```text
关注：<player-facing reason>
用途：<current role or best immediate use>
下一步：<recommended next action>
```

Expected: row button node names and selection behavior stay unchanged.

- [ ] **Step 2: Update player detail summary wording only**

Update player detail summary formatting to include:

```text
用途：<how to use this player now>
本轮判断：<train/play/hold recommendation from existing data>
成本/回报：<existing training or opportunity tradeoff if available>
下一步：<single recommended next action>
```

Expected: the detail screen still consumes the selected player and existing training payload only.

- [ ] **Step 3: Update training selection/result wording only**

Update training summary/result formatting to preserve existing concepts while aligning labels:

```text
当前选择：<training name>
成本/回报：成本：经费 <funds>｜运动点数 <ap>；回报：权威预览 <preview>
本轮判断：<risk/tradeoff from existing data>
下一步：<what to do after confirming or why to hold>
```

Expected: training confirm still emits the same request flow and does not mutate state directly.

- [ ] **Step 4: Update Player/Training L2 assertions**

In `tests/integration/ui/l2_playable_loop_panels_test.gd`, update assertions to check the new structural anchors while preserving flow checks:

```gdscript
_assert_contains(roster_row.text, "关注：")
_assert_contains(roster_row.text, "用途：")
_assert_contains(roster_row.text, "下一步：")
_assert_contains(detail_summary.text, "本轮判断：")
_assert_contains(detail_summary.text, "成本/回报：")
_assert_contains(training_summary.text, "当前选择：")
_assert_contains(training_summary.text, "成本/回报：")
_assert_contains(training_summary.text, "下一步：")
```

Expected: assertions verify readable structure, not brittle full sentences.

- [ ] **Step 5: Run Player/Training integration coverage**

Run:

```bash
godot --headless --path /home/kylin/little-football-town --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/l2_playable_loop_panels_test.gd
```

Expected: pass after Task 2A and Task 2B are both integrated. If run before Task 2B, only Player/Training-related failures should remain explainable by pending Match edits.

---

### Task 2B: Converge Match Panel

**Files:**
- Modify: `src/ui/match/match_perf_panel.gd`
- Test: `tests/integration/ui/l2_playable_loop_panels_test.gd`

- [ ] **Step 1: Update pre-match summary wording only**

In `src/ui/match/match_perf_panel.gd`, update pre-match summary formatting to include:

```text
赛前检查：<opponent/time/current readiness>
是否适合开赛：<yes/no from existing authority gating>
判断：<why the start button is enabled or disabled>
下一步：<start match or fix blocker>
```

Expected: disabled start still remains on `match_pre`; enabled start still requests the existing match-start flow.

- [ ] **Step 2: Update live summary wording only**

Update live summary formatting to include:

```text
现场状态：<score/time/current phase>
刚刚重点：<latest timeline highlight or current match state>
影响：<what the highlight means using existing timeline/result data>
下一步关注：<what player should watch next>
```

Expected: no new live command state or halftime decision depth is added.

- [ ] **Step 3: Update result summary wording only**

Update result summary formatting to include:

```text
比赛结果：<result line>
原因：<main reason from existing result/timeline data>
表现/联赛影响：<performance and league consequence from existing payload>
下一步：<confirm and return home>
```

Expected: result confirm still returns to `home`.

- [ ] **Step 4: Update Match L2 assertions**

In `tests/integration/ui/l2_playable_loop_panels_test.gd`, update Match assertions to check structural anchors:

```gdscript
_assert_contains(pre_match_summary.text, "赛前检查：")
_assert_contains(pre_match_summary.text, "是否适合开赛：")
_assert_contains(pre_match_summary.text, "判断：")
_assert_contains(pre_match_summary.text, "下一步：")
_assert_contains(live_summary.text, "现场状态：")
_assert_contains(live_summary.text, "刚刚重点：")
_assert_contains(live_summary.text, "影响：")
_assert_contains(result_summary.text, "比赛结果：")
_assert_contains(result_summary.text, "表现/联赛影响：")
_assert_contains(result_summary.text, "下一步：")
```

Expected: assertions preserve route behavior checks for disabled pre-match and result confirm.

- [ ] **Step 5: Run Match integration coverage**

Run:

```bash
godot --headless --path /home/kylin/little-football-town --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/l2_playable_loop_panels_test.gd
```

Expected: pass after Task 2A and Task 2B are both integrated.

---

### Task 3: Minimal Home Alignment

**Files:**
- Modify if needed: `src/ui/hud/main_loop_shell.gd`
- Test: `tests/integration/ui/main_loop_shell_navigation_test.gd`

- [ ] **Step 1: Decide whether Home needs wording alignment**

Inspect whether Home summary, primary CTA, secondary CTA, or disabled match reason now conflicts with Task 2A/2B labels.

Expected: if Home already explains the next action clearly, skip this task without editing.

- [ ] **Step 2: Align Home wording only if needed**

If needed, edit only Home-facing text helpers in `src/ui/hud/main_loop_shell.gd`:

```text
建议下一步：<best current action>
俱乐部概览：<current state>
比赛准备：<can start or why blocked>
```

Expected: do not change `ROUTE_IDS`, `shell_main_content`, `route_to`, `return_home`, push/reset behavior, or mounted panel classes.

- [ ] **Step 3: Update shell assertions only if Home wording changed**

In `tests/integration/ui/main_loop_shell_navigation_test.gd`, update only text assertions affected by wording alignment.

Keep these assertions unchanged:

```gdscript
assert_eq(shell.get_route_ids(), ["home", "roster", "player_detail", "training", "match_pre", "match_live", "match_result"])
assert_eq(shell.get_current_route(), "home")
```

Expected: disabled match CTA still stays on Home and shows a player-facing reason.

- [ ] **Step 4: Run shell navigation coverage**

Run:

```bash
godot --headless --path /home/kylin/little-football-town --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/main_loop_shell_navigation_test.gd
```

Expected: pass with route topology unchanged.

---

### Task 4: Serial Regression and Walkthrough Closure

**Files:**
- Modify if needed: `tests/integration/ui/l2_playable_loop_panels_test.gd`
- Modify if needed: `tests/integration/ui/main_loop_shell_navigation_test.gd`
- Modify if needed: `tests/integration/ui/mvp_visual_walkthrough_runner.gd`

- [ ] **Step 1: Run L2 panel test**

Run:

```bash
godot --headless --path /home/kylin/little-football-town --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/l2_playable_loop_panels_test.gd
```

Expected: pass and confirm Player/Training/Match summaries expose the new decision skeleton.

- [ ] **Step 2: Run shell navigation test**

Run:

```bash
godot --headless --path /home/kylin/little-football-town --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/main_loop_shell_navigation_test.gd
```

Expected: pass and confirm topology/flow guardrails remain unchanged.

- [ ] **Step 3: Run MVP visual walkthrough**

Run the existing walkthrough runner according to its current SceneTree/direct script pattern:

```bash
godot --headless --path /home/kylin/little-football-town --script res://tests/integration/ui/mvp_visual_walkthrough_runner.gd
```

Expected: route order remains stable and these capture nodes remain present:

```text
01_home_initial
02_roster
03_player_detail
04_training
07_home_after_training
08_match_pre
10_match_live_timeline
11_match_result
12_home_final
```

- [ ] **Step 4: Record warning-limited evidence**

Record final verification in the session state or story/evidence note used for this Production slice.

Evidence standard:

```text
- l2_playable_loop_panels_test.gd passed
- main_loop_shell_navigation_test.gd passed
- mvp_visual_walkthrough_runner.gd completed route/capture chain
- Remaining warnings are limited to accepted Production warnings and display polish, not route, authority, or stability failures
```

Expected: do not claim external-human validation or remote GitHub Actions green unless separately verified.

---

## Parallelization Plan

Run after Task 1 contract is agreed:

- Subagent A: Task 2A, `src/ui/player/player_mgmt_panel.gd` and Player/Training assertions.
- Subagent B: Task 2B, `src/ui/match/match_perf_panel.gd` and Match assertions.

Run serially after A/B merge:

- Task 3: `src/ui/hud/main_loop_shell.gd` only if needed.
- Task 4: final integration and walkthrough closure.

Do not parallelize:

- Shared shell wording.
- Shared shell assertions.
- Final `l2_playable_loop_panels_test.gd` merge resolution.
- Final walkthrough verification.

## Acceptance Criteria

- Route set remains exactly `home`, `roster`, `player_detail`, `training`, `match_pre`, `match_live`, `match_result`.
- ScreenManager stack behavior remains unchanged.
- UI continues to display/request only and does not directly mutate gameplay state.
- No new stable payload fields are introduced.
- Stable node names and button names remain unchanged.
- L2 summaries answer status, possibility, reason, cost/impact, and next step.
- Required integration tests pass.
- MVP walkthrough completes its route/capture chain.
- Remaining warnings stay within already accepted Production warning boundaries.
