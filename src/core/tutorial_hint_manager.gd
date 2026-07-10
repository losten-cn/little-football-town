## class_name TutorialHintManager
extends Node
## Story 001 (S8-04) — TutorialHintManager Authority Stub for design/gdd/tutorial-and-hint-system.md.
##
## Owns the four hint-system durable-truth fields:
##   seen_hints: Array[String], disabled_hints: Array[String],
##   hint_cooldowns: Dictionary[String, float], help_index_visible: bool.
##
## This node is scene-instantiated (class_name), NOT an Autoload.
## It exports serialize/deserialize for SaveManager registration and
## provides the hint eligibility check / view-payload contract for the
## presentation layer.
##
## Design Document: design/gdd/tutorial-and-hint-system.md
## Requirements: TR-tutorial-001, TR-tutorial-002, TR-tutorial-003, TR-tutorial-006, TR-tutorial-007

## Set of hint ids that have been seen at least once.
var seen_hints: Array[String] = []

## Set of hint ids that have been permanently suppressed by the player.
var disabled_hints: Array[String] = []

## Cooldown expiry timestamps keyed by hint_id.
## When a hint is marked seen, its cooldown timestamp is set to
## current_time + DEFAULT_COOLDOWN_SECONDS.
var hint_cooldowns: Dictionary[String, float] = {}

## Whether the help index panel is currently toggled open.
var help_index_visible: bool = false

## Default cooldown duration in seconds (5 minutes).
const DEFAULT_COOLDOWN_SECONDS: float = 300.0

## Override callable for onboarding guided-state queries.
## Signature: func() -> bool
## When null, the manager falls back to the Autoload path
## /root/OnboardingSystem if available; otherwise returns false
## (treating the user as a return visitor).
var _onboarding_check_callable: Callable = Callable()


# ─────────────────────────────────────────────
# Public API — Hint Eligibility & View Payload
# ─────────────────────────────────────────────

## Checks eligibility and, if the hint passes all suppression gates,
## marks it as seen, sets its cooldown, and returns the hint payload.
##
## Suppression gates (any one suppresses):
##  - hint_id is in [member disabled_hints]
##  - hint_id cooldown has not yet expired
##
## [param hint_id] Stable hint identifier (e.g. "first_training").
## [param current_time] Current timestamp for cooldown expiry check.
##   Uses [method Time.get_unix_time_from_system] when 0.0.
## [returns] A hint payload [Dictionary[String, Variant]] when eligible,
##   or an empty [Dictionary] when suppressed.
func request_hint(hint_id: String, current_time: float = 0.0) -> Dictionary[String, Variant]:
	if hint_id.is_empty():
		return {}

	# Gate 1 — permanently disabled
	if hint_id in disabled_hints:
		return {}

	# Gate 2 — cooldown not yet expired
	var resolved_time: float = current_time if current_time > 0.0 else Time.get_unix_time_from_system()
	if hint_cooldowns.has(hint_id):
		var cooldown_expiry: float = hint_cooldowns[hint_id] as float
		if resolved_time < cooldown_expiry:
			return {}

	# Eligible — mark seen, set cooldown, return payload
	mark_seen(hint_id)
	hint_cooldowns[hint_id] = resolved_time + DEFAULT_COOLDOWN_SECONDS
	return _build_hint_payload(hint_id)


## Returns a read-only hint payload without side effects.
##
## Does NOT mark the hint as seen or modify cooldowns.
## The presentation layer uses this to query hint content for
## already-eligible hints or help-index entries.
##
## [param hint_id] Stable hint identifier.
## [returns] A hint payload [Dictionary[String, Variant]] with display fields,
##   or an empty [Dictionary] when the hint_id is unrecognised or disabled.
func get_hint_view_payload(hint_id: String) -> Dictionary[String, Variant]:
	if hint_id.is_empty() or hint_id in disabled_hints:
		return {}
	if not _hint_registry().has(hint_id):
		return {}
	return _build_hint_payload(hint_id)


## Permanently suppresses a hint so it will never appear again.
##
## Does NOT affect gameplay state, resource values, or any
## authority system. Only the hint's own display is suppressed.
func disable_hint(hint_id: String) -> void:
	if hint_id.is_empty():
		return
	if hint_id not in disabled_hints:
		disabled_hints.append(hint_id)


## Records a hint as seen and sets its cooldown to the supplied time.
##
## [param hint_id] Hint to record.
## [param current_time] Timestamp for cooldown start; defaults to system time.
func mark_seen(hint_id: String, current_time: float = 0.0) -> void:
	if hint_id.is_empty():
		return
	if hint_id not in seen_hints:
		seen_hints.append(hint_id)
	var resolved_time: float = current_time if current_time > 0.0 else Time.get_unix_time_from_system()
	hint_cooldowns[hint_id] = resolved_time + DEFAULT_COOLDOWN_SECONDS


# ─────────────────────────────────────────────
# SaveManager Contract — serialize / deserialize
# ─────────────────────────────────────────────

## Serializes all durable hint state for save persistence.
func serialize() -> Dictionary[String, Variant]:
	return {
		"seen_hints": seen_hints.duplicate(true),
		"disabled_hints": disabled_hints.duplicate(true),
		"hint_cooldowns": hint_cooldowns.duplicate(true),
		"help_index_visible": help_index_visible,
	}


## Restores durable hint state from serialized save data.
func deserialize(data: Dictionary[String, Variant]) -> void:
	seen_hints.clear()
	for entry: Variant in data.get("seen_hints", []) as Array:
		seen_hints.append(String(entry))

	disabled_hints.clear()
	for entry: Variant in data.get("disabled_hints", []) as Array:
		disabled_hints.append(String(entry))

	hint_cooldowns = _normalize_string_float_dictionary(data.get("hint_cooldowns", {}))
	help_index_visible = bool(data.get("help_index_visible", false))


## Registers this system with SaveManager using the tutorial-hint persistence contract.
func register_with_save_manager(save_manager: Node) -> bool:
	if save_manager == null:
		return false
	return save_manager.register_system("tutorial_hint", Callable(self, "serialize"), Callable(self, "deserialize"))


# ─────────────────────────────────────────────
# Dependency Injection — Onboarding guided-state check
# ─────────────────────────────────────────────

## Overrides the onboarding guided-state query for tests.
##
## [param check_callable] A [Callable] with signature func() -> bool.
##   Pass an empty [Callable] to restore the default autoload fallback.
func set_onboarding_check(check_callable: Callable) -> void:
	_onboarding_check_callable = check_callable


# ─────────────────────────────────────────────
# Internal helpers
# ─────────────────────────────────────────────

## Queries whether the current user is a first-time guided user.
##
## Resolution order:
##  1. Injected callable (test override)
##  2. Autoload /root/OnboardingSystem.is_guided()
##  3. Default false (return visitor — context help only)
func _is_guided_user() -> bool:
	if _onboarding_check_callable.is_valid():
		var result: Variant = _onboarding_check_callable.call()
		if result is bool:
			return result as bool
		return false

	if is_inside_tree():
		var onboarding_path: String = "/root/OnboardingSystem"
		if has_node(onboarding_path):
			var onboarding: Node = get_node(onboarding_path)
			if onboarding.has_method("is_guided"):
				var result: Variant = onboarding.call("is_guided")
				if result is bool:
					return result as bool

	return false


## Builds the canonical hint payload for a recognised hint_id.
func _build_hint_payload(hint_id: String) -> Dictionary[String, Variant]:
	var is_guided: bool = _is_guided_user()
	var registry: Dictionary = _hint_registry()
	var entry: Dictionary = _normalize_string_variant_dict(registry.get(hint_id, {}))
	var user_type: String = "guided" if is_guided else "returning"

	var core_text: String
	var detail_text: String
	if is_guided:
		core_text = String(entry.get("guided_core_text", entry.get("core_text", "")))
		detail_text = String(entry.get("guided_detail_text", entry.get("detail_text", "")))
	else:
		core_text = String(entry.get("returning_core_text", entry.get("core_text", "")))
		detail_text = String(entry.get("returning_detail_text", entry.get("detail_text", "")))

	return {
		"hint_id": hint_id,
		"core_text": core_text,
		"detail_text": detail_text,
		"user_type": user_type,
		"anchor_id": String(entry.get("anchor_id", "")),
		"category": String(entry.get("category", "context")),
	}


## Hint registry — maps hint_ids to their display content.
##
## All text uses low-pressure language per the GDD's Display Principles.
## Guided users see more detailed first-time explanations; returning
## users see shorter context help.
##
## This is the data-driven hint content catalog. Tuning values (cooldown
## duration, priority weights) live in config; text content lives here
## for the stub phase and can migrate to a Custom Resource later.
func _hint_registry() -> Dictionary:
	return {
		"first_training": {
			"guided_core_text": "可以在这里选择训练项目。",
			"guided_detail_text": "训练会消耗AP并提升球员属性。选择适合球员特点的项目可以获得更好效果。",
			"returning_core_text": "训练项目说明",
			"returning_detail_text": "查看当前可用的训练项目。",
			"anchor_id": "training_project_select",
			"category": "context",
		},
		"first_match_pre": {
			"guided_core_text": "比赛前可以查看对手信息。",
			"guided_detail_text": "确认阵容后就可以开始比赛。系统会为你推荐合适的首发安排。",
			"returning_core_text": "对手信息与阵容确认",
			"returning_detail_text": "查看对手概况并确认首发阵容。",
			"anchor_id": "match_pre_opponent_summary",
			"category": "context",
		},
		"first_match_result": {
			"guided_core_text": "比赛结果出来了。",
			"guided_detail_text": "可以在这里查看比分、关键事件和球员表现。",
			"returning_core_text": "比赛结果",
			"returning_detail_text": "查看本场比赛的详细数据和复盘原因。",
			"anchor_id": "match_result_scoreboard",
			"category": "context",
		},
		"home_roster_entry": {
			"guided_core_text": "点击球员可以查看详细信息。",
			"guided_detail_text": "在这里管理你的球队阵容，了解每位球员的状态和成长方向。",
			"returning_core_text": "球员列表",
			"returning_detail_text": "浏览和管理你的球员。",
			"anchor_id": "home_roster_button",
			"category": "context",
		},
		"resource_summary": {
			"guided_core_text": "这里显示你的经费和运动点数。",
			"guided_detail_text": "经费用于建设和日常开销，运动点数用于训练和比赛。",
			"returning_core_text": "资源摘要",
			"returning_detail_text": "当前经费和运动点数余额。",
			"anchor_id": "home_resource_bar",
			"category": "context",
		},
	}


## Normalizes an untyped container into a typed Dictionary[String, Variant].
func _normalize_string_variant_dict(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if value is Dictionary:
		var source: Dictionary = value as Dictionary
		for key: Variant in source.keys():
			typed_dictionary[String(key)] = source[key]
	return typed_dictionary


## Normalizes an untyped container into a typed Dictionary[String, float].
func _normalize_string_float_dictionary(value: Variant) -> Dictionary[String, float]:
	var typed_dictionary: Dictionary[String, float] = {}
	if value is Dictionary:
		var source: Dictionary = value as Dictionary
		for key: Variant in source.keys():
			typed_dictionary[String(key)] = float(source.get(key, 0.0))
	return typed_dictionary
