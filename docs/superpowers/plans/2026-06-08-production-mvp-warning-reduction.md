# Production MVP Warning Reduction Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reduce accepted Production MVP UI warnings without changing route topology, gameplay authority, stable payloads, or save/event schema.

**Architecture:** Keep `MainLoopShell` as the L1 route owner and leave `ScreenManager` route IDs unchanged. Keep `PlayerMgmtPanel` and `MatchPerfPanel` as display/request panels only; all state changes continue through existing `EventBus` requests and authoritative gameplay systems.

**Tech Stack:** Godot 4.6, GDScript, custom headless integration runner via `tests/test_script_runner.gd`.

---

## File Structure

- Modify: `tests/integration/ui/l2_playable_loop_panels_test.gd`
  - Adds RED coverage for Home CTA non-duplication, Match Pre return Home affordance, player/training conclusion-first copy, unified disabled training reasons, and Match Live halftime placeholder downgrade.
- Modify: `src/ui/hud/main_loop_shell.gd`
  - Reduces Home CTA duplication while preserving `PrimaryAction`, `SecondaryAction`, route IDs, and `ScreenManager` behavior.
- Modify: `src/ui/player/player_mgmt_panel.gd`
  - Reorders dense detail/training summaries so the player sees the conclusion first, and appends a consistent disabled reason to unavailable training options.
- Modify: `src/ui/match/match_perf_panel.gd`
  - Adds an explicit pre-match return Home affordance and downgrades halftime from an apparent action to explanatory non-focusable placeholder while preserving the stable `HalftimeAdjustButton` node.

---

### Task 1: Add RED UI Warning Coverage

**Files:**
- Modify: `tests/integration/ui/l2_playable_loop_panels_test.gd`

- [ ] **Step 1: Add failing Home CTA test**

Add a new test call before existing route tests in `_ready()`:

```gdscript
func _ready() -> void:
	_setup_hud()
	await get_tree().process_frame
	test_l2_home_ctas_do_not_duplicate_roster_path()
	test_l2_player_panel_mounts_roster_detail_training_and_requests_training()
	test_l2_match_panel_mounts_prematch_live_result_and_returns_home()
	_teardown_hud()
	await get_tree().process_frame
```

Add the test:

```gdscript
func test_l2_home_ctas_do_not_duplicate_roster_path() -> void:
	TimeManager.apply_snapshot({
		"state": "Planning",
		"timeline_position": 0,
		"scheduled_match_position": 5,
		"schedule_available": true,
		"match_trigger_reached": false,
		"match_center_available": false,
		"match_in_progress": false,
	})
	EventBus.emit("time_advanced", {
		"date_display": "Week 1",
		"phase": "PLANNING",
		"available_action_windows": 1,
		"schedule_available": true,
		"match_trigger_reached": false,
		"match_center_available": false,
	})
	EventBus.emit("system_state_changed", {"system_state_allows_match": true, "navigation_context_allows_match": true})
	EventBus.emit("screen_requested", {"screen_id": "home"})
	_expect(_shell.call("get_current_route") == "home", "home route should mount through shell")
	var primary_button: Button = _find_button("PrimaryAction")
	var secondary_button: Button = _find_button("SecondaryAction")
	_expect(primary_button != null, "PrimaryAction stable node should exist")
	_expect(secondary_button != null, "SecondaryAction stable node should exist")
	var primary_text: String = primary_button.text if primary_button != null else ""
	var secondary_text: String = secondary_button.text if secondary_button != null else ""
	_expect(primary_text != secondary_text, "home primary and secondary actions should not duplicate the same roster path")
	_assert_contains(primary_text, "训练", "home primary should keep the planning training recommendation")
	_assert_contains(secondary_text, "比赛", "home secondary should point to match readiness instead of another roster wording")
	_press_button("SecondaryAction")
	_expect(_shell.call("get_current_route") == "match_pre", "home secondary should open match preparation context")
```

- [ ] **Step 2: Add failing player/training copy and disabled reason checks**

Extend `test_l2_player_panel_mounts_roster_detail_training_and_requests_training()` with an unavailable option in `training_options_updated`:

```gdscript
EventBus.emit("training_options_updated", {
	"training_available": true,
	"options": [
		{"training_id": "finishing", "name": "射门训练", "summary": "权威预览", "cost_summary": "经费 100｜运动点数 1", "risk_summary": "占用本轮训练机会", "payoff_summary": "下一场射门机会更容易转化", "available": true},
		{"training_id": "stamina", "name": "体能恢复", "summary": "恢复体能", "available": false, "disable_reason": "运动点数不足"},
	],
})
```

Add assertions after reading `detail_summary`:

```gdscript
_expect(detail_summary.begins_with("本轮判断："), "player detail should put the decision conclusion first")
_expect(detail_summary.split("\n").size() <= 8, "player detail should reduce dense line count")
```

Add assertions after reading `training_decision`:

```gdscript
_expect(training_decision.begins_with("本轮判断："), "training decision should put the tradeoff conclusion first")
_expect(training_decision.split("\n").size() <= 7, "training decision should reduce dense line count")
var disabled_option: Button = _find_button("TrainingOption_stamina")
_expect(disabled_option != null, "disabled training option should keep stable option node")
var disabled_option_text: String = disabled_option.text if disabled_option != null else ""
_assert_contains(disabled_option_text, "暂不可用", "disabled training option should use a consistent disabled marker")
_assert_contains(disabled_option_text, "运动点数不足", "disabled training option should include the authoritative disabled reason")
```

- [ ] **Step 3: Add failing Match Pre return and halftime downgrade checks**

In `test_l2_match_panel_mounts_prematch_live_result_and_returns_home()`, add after the `PreMatchStartButton` assertion:

```gdscript
_expect(_find_button("PreMatchReturnHomeButton") != null, "Match Pre should expose an explicit return Home button")
_press_button("PreMatchReturnHomeButton")
_expect(_shell.call("get_current_route") == "home", "pre-match return Home should route back to home")
EventBus.emit("screen_requested", {"screen_id": "match_pre"})
_expect(_shell.call("get_current_route") == "match_pre", "match_pre should remount after returning home")
```

Replace the halftime assertion with:

```gdscript
var halftime_button: Button = _find_button("HalftimeAdjustButton")
_expect(halftime_button != null, "HalftimeAdjustButton stable node should exist")
_expect(halftime_button.focus_mode == Control.FOCUS_NONE, "halftime placeholder should not present as an interactive action")
_assert_contains(halftime_button.text, "说明", "halftime placeholder should read as explanatory text")
```

- [ ] **Step 4: Run RED test**

Run:

```bash
godot --headless --path /home/kylin/little-football-town --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/l2_playable_loop_panels_test.gd
```

Expected: FAIL, with failures for secondary Home match readiness, conclusion-first detail/training copy, disabled option reason marker, missing `PreMatchReturnHomeButton`, and halftime placeholder still focusable/action-like.

---

### Task 2: Reduce Home CTA Duplication

**Files:**
- Modify: `src/ui/hud/main_loop_shell.gd`
- Test: `tests/integration/ui/l2_playable_loop_panels_test.gd`

- [ ] **Step 1: Implement minimal Home CTA change**

Change `_secondary_home_action_text()`:

```gdscript
func _secondary_home_action_text() -> String:
	if _can_enter_match():
		return _localized_text("HOME_SECONDARY_ROSTER_CONFIRM", "先看球员状态")
	return _localized_text("HOME_SECONDARY_MATCH_PREP", "查看比赛准备")
```

Change `_on_secondary_action_pressed()`:

```gdscript
func _on_secondary_action_pressed() -> void:
	if _current_route == ROUTE_HOME:
		if _can_enter_match():
			route_to(ROUTE_ROSTER)
			return
		route_to(ROUTE_MATCH_PRE)
```

- [ ] **Step 2: Run targeted test**

Run:

```bash
godot --headless --path /home/kylin/little-football-town --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/l2_playable_loop_panels_test.gd
```

Expected: Home CTA assertions now pass; remaining RED failures are in player/training and match panel scope.

---

### Task 3: Reduce Player Detail/Training Copy Density and Normalize Disabled Reasons

**Files:**
- Modify: `src/ui/player/player_mgmt_panel.gd`
- Test: `tests/integration/ui/l2_playable_loop_panels_test.gd`

- [ ] **Step 1: Reorder player detail conclusion first**

Change `_format_player_detail()` to:

```gdscript
func _format_player_detail(player: Dictionary[String, Variant]) -> String:
	if player.is_empty():
		return _localized_text("PLAYER_DETAIL_NONE", "未选择球员")
	var reference_option: Dictionary[String, Variant] = _resolve_reference_training_option()
	return _localized_text("PLAYER_DETAIL_FORMAT", "本轮判断：%s\n用途：%s\n成本/回报：成本：%s；回报：%s；时机：%s\n下一步：%s\n身份：%s｜%s｜%s\n技术特点：%s\n近期成长：%s\n当前状态：%s") % [
		_resolve_training_why_summary(player),
		_resolve_player_role_summary(player),
		_resolve_training_cost_summary(reference_option),
		_resolve_training_impact_summary(reference_option),
		_resolve_training_payoff_summary(player, reference_option),
		_training_entry_text(),
		str(player.get("name", _localized_text("PLAYER_UNKNOWN", "未知球员"))),
		str(player.get("position", player.get("primary_position", "?"))),
		str(player.get("development_tier", player.get("tier", "-"))),
		_resolve_attribute_summary(player),
		_resolve_growth_summary(player),
		_resolve_status_summary(player),
	]
```

- [ ] **Step 2: Normalize disabled training option copy**

Change `_format_training_option()`:

```gdscript
func _format_training_option(option: Dictionary) -> String:
	var marker: String = "* " if str(option.get("training_id", option.get("id", ""))) == _selected_training_id else ""
	var option_text: String = _localized_text("PLAYER_TRAINING_OPTION_FORMAT", "%s%s — %s") % [
		marker,
		str(option.get("name", option.get("training_name", _localized_text("PLAYER_TRAINING_OPTION", "训练项目")))),
		str(option.get("summary", option.get("expected_gain_summary", _localized_text("PLAYER_TRAINING_EXPECTED_GAIN", "预计提升本次重点能力")))),
	]
	if bool(option.get("available", true)):
		return option_text
	return _localized_text("PLAYER_TRAINING_OPTION_DISABLED_FORMAT", "%s｜暂不可用：%s") % [option_text, _resolve_training_disabled_reason(_to_string_variant_dictionary(option))]
```

Add helper:

```gdscript
func _resolve_training_disabled_reason(option: Dictionary[String, Variant]) -> String:
	var reason: String = str(option.get("disable_reason", option.get("disabled_reason", option.get("training_disable_reason", ""))))
	if reason.is_empty():
		return _localized_text("PLAYER_TRAINING_DISABLED", "训练暂不可用")
	return reason
```

- [ ] **Step 3: Reorder training decision conclusion first**

Change `_format_training_result()`:

```gdscript
func _format_training_result() -> String:
	var selected_option: Dictionary[String, Variant] = _resolve_selected_training_option()
	var result_summary: String = _localized_text("PLAYER_TRAINING_RESULT_PENDING", "完成训练后会在这里显示结果")
	if not _last_training_result.is_empty():
		result_summary = str(_last_training_result.get("summary", _last_training_result.get("result_summary", _localized_text("PLAYER_TRAINING_DONE", "训练已完成，近期状态已更新"))))
	return _localized_text("PLAYER_TRAINING_DECISION_FORMAT", "本轮判断：%s\n当前选择：%s\n成本/回报：成本：%s；回报：%s；时机：%s\n下一步：%s\n结果：%s") % [
		_resolve_training_risk_summary(selected_option),
		_resolve_training_option_name(selected_option),
		_resolve_training_cost_summary(selected_option),
		_resolve_training_impact_summary(selected_option),
		_resolve_training_payoff_summary(_resolve_selected_player(), selected_option),
		_resolve_training_next_step_summary(selected_option),
		result_summary,
	]
```

- [ ] **Step 4: Run targeted test**

Run:

```bash
godot --headless --path /home/kylin/little-football-town --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/l2_playable_loop_panels_test.gd
```

Expected: Player/training assertions now pass; remaining RED failures are in match panel scope.

---

### Task 4: Add Match Pre Return Home and Downgrade Halftime Placeholder

**Files:**
- Modify: `src/ui/match/match_perf_panel.gd`
- Test: `tests/integration/ui/l2_playable_loop_panels_test.gd`

- [ ] **Step 1: Add pre-match return Home button**

Add field:

```gdscript
var _pre_match_return_home_button: Button = null
```

Create it after `_pre_match_start_button` in `_setup_ui()`:

```gdscript
_pre_match_return_home_button = Button.new()
_pre_match_return_home_button.name = "PreMatchReturnHomeButton"
_pre_match_return_home_button.text = _localized_text("MATCH_PRE_RETURN_HOME", "返回主页")
_pre_match_return_home_button.focus_mode = Control.FOCUS_ALL
_apply_town_button_style(_pre_match_return_home_button, false)
_pre_match_return_home_button.pressed.connect(_on_pre_match_return_home_pressed)
_root_box.add_child(_pre_match_return_home_button)
```

Hide it in `_refresh()`:

```gdscript
_pre_match_return_home_button.visible = false
```

Show it in `_mount_pre_match()`:

```gdscript
_pre_match_return_home_button.visible = true
```

Add handler:

```gdscript
func _on_pre_match_return_home_pressed() -> void:
	EventBus.emit("screen_requested", {"screen_id": "home"})
```

- [ ] **Step 2: Downgrade halftime placeholder without changing stable node**

Change halftime setup:

```gdscript
_halftime_adjust_button.text = _localized_text("MATCH_HALFTIME_EXPLANATION", "说明：中场调整将在后续版本开放；本场先继续观看时间线。")
_halftime_adjust_button.focus_mode = Control.FOCUS_NONE
_halftime_adjust_button.disabled = true
```

Keep `_halftime_adjust_button.name = "HalftimeAdjustButton"` and keep it as `Button` to preserve existing stable node lookup.

- [ ] **Step 3: Run targeted test**

Run:

```bash
godot --headless --path /home/kylin/little-football-town --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/l2_playable_loop_panels_test.gd
```

Expected: `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`.

---

### Task 5: Run Regression Baseline

**Files:**
- No code changes expected.

- [ ] **Step 1: Run targeted UI test**

Run:

```bash
godot --headless --path /home/kylin/little-football-town --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/l2_playable_loop_panels_test.gd
```

Expected: PASS with `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`.

- [ ] **Step 2: Run local standard split-runner baseline**

Run the same local split-runner path used for the current project baseline.

Expected: no regression from the previously observed local 71/71 pass baseline. Do not claim remote GitHub Actions green unless it is actually verified.

---

## Guardrails

- Do not change route IDs: `home`, `roster`, `player_detail`, `training`, `match_pre`, `match_live`, `match_result`.
- Do not change `ScreenManager` stack semantics.
- Do not alter gameplay authority or make UI mutate game state.
- Do not change stable payload keys or save/event schema.
- Keep `HalftimeAdjustButton` as a stable node name to avoid breaking existing scene/test contracts.
- Warnings are acceptable; blockers are not.
