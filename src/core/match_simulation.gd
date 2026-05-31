class_name MatchSimulation
extends Node
## Deterministic match state machine for formal match entry and restore boundaries.


enum State {
	IDLE,
	ENTRY,
	PRE_MATCH_PREPARATION,
	CONFIRMATION,
	FIRST_HALF,
	HALFTIME_ADJUSTMENT,
	SECOND_HALF,
	RESULT_REVIEW,
	SETTLEMENT_HANDOFF,
}

const FORMAL_STATE_NAMES: Array[String] = [
	"Entry",
	"Pre-Match",
	"Confirmation",
	"First Half",
	"Halftime",
	"Second Half",
	"Result Review",
	"Settlement",
]

var _state: State = State.IDLE
var _formal_state_history: Array[String] = []
var _pending_match_context: Dictionary[String, Variant] = {}
var _result_packet: Dictionary[String, Variant] = {}
var _first_half_snapshot: Dictionary[String, Variant] = {}
var _second_half_plan: Dictionary[String, Variant] = {}
var _time_manager: Node = null
var _event_bus_override: Node = null
var _balance_config_override: BalanceConfig = null
var _match_config_override: MatchConfig = null
var _match_seed_override: int = 0
var _has_match_seed_override: bool = false
var _match_rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _match_event_category_offset: int = 0
var _first_half_events: Array[Dictionary] = []
var _second_half_events: Array[Dictionary] = []
var _planned_total_event_count: int = 0
var _planned_first_half_event_count: int = 0
var _confirmed_results_by_match_id: Dictionary[String, Variant] = {}
var _event_emit_debug: Dictionary[String, Variant] = {}


## Binds the time authority used to validate formal match entry.
func bind_time_manager(time_manager: Node) -> void:
	_time_manager = time_manager


## Starts a formal match only when the provided time authority allows entry.
func start_formal_match(match_context: Dictionary[String, Variant], time_manager: Node = null) -> bool:
	if time_manager != null:
		bind_time_manager(time_manager)
	var requested_match_context: Dictionary[String, Variant] = _to_string_variant_dictionary(match_context)
	var match_id: String = String(requested_match_context.get("match_id", ""))
	if not match_id.is_empty() and _confirmed_results_by_match_id.has(match_id):
		_pending_match_context = requested_match_context
		_first_half_snapshot = {}
		_second_half_plan = {
			"tactics": {},
			"substitutions": [],
		}
		_first_half_events.clear()
		_second_half_events.clear()
		_planned_total_event_count = 0
		_planned_first_half_event_count = 0
		_formal_state_history.clear()
		_result_packet = _to_string_variant_dictionary(_confirmed_results_by_match_id.get(match_id, {}))
		_state = State.IDLE
		_set_match_in_progress(false)
		_transition_to(State.SETTLEMENT_HANDOFF)
		return true
	if _state != State.IDLE:
		return false
	if not _can_enter_formal_match():
		return false
	_pending_match_context = requested_match_context
	_first_half_snapshot = {}
	_second_half_plan = {
		"tactics": {},
		"substitutions": [],
	}
	_first_half_events.clear()
	_second_half_events.clear()
	_planned_total_event_count = 0
	_planned_first_half_event_count = 0
	_formal_state_history.clear()
	_result_packet = {}
	if _has_match_seed_override:
		_pending_match_context["match_seed"] = _match_seed_override
	elif not _pending_match_context.has("match_seed"):
		_pending_match_context["match_seed"] = int(_pending_match_context.get("event_seed", 0))
	var match_seed: int = int(_pending_match_context.get("match_seed", 0))
	_match_rng.seed = match_seed
	_match_event_category_offset = _match_rng.randi_range(0, KEY_EVENT_CATEGORIES.size() - 1)
	_transition_to(State.ENTRY)
	return true


## Advances the formal match flow by exactly one state transition.
func advance() -> void:
	match _state:
		State.ENTRY:
			if _formal_state_history.is_empty():
				_formal_state_history.append(_get_state_name(State.ENTRY))
			_transition_to(State.PRE_MATCH_PREPARATION)
		State.PRE_MATCH_PREPARATION:
			_transition_to(State.CONFIRMATION)
		State.CONFIRMATION:
			_set_match_in_progress(true)
			_transition_to(State.FIRST_HALF)
		State.FIRST_HALF:
			_capture_first_half_snapshot()
			_transition_to(State.HALFTIME_ADJUSTMENT)
		State.HALFTIME_ADJUSTMENT:
			_transition_to(State.SECOND_HALF)
		State.SECOND_HALF:
			_finalize_result_packet()
			_set_match_in_progress(false)
			_transition_to(State.RESULT_REVIEW)
		State.RESULT_REVIEW:
			_transition_to(State.SETTLEMENT_HANDOFF)
		State.SETTLEMENT_HANDOFF:
			_transition_to(State.IDLE)
		State.IDLE:
			return


## Returns the current state name.
func get_state_name() -> String:
	return _get_state_name(_state)


## Returns the ordered history of formal states visited in the active match.
func get_formal_state_history() -> Array[String]:
	return _formal_state_history.duplicate()


## Returns the recoverable pending context for the current or next match entry.
func get_pending_match_context() -> Dictionary[String, Variant]:
	return _pending_match_context.duplicate(true)


## Returns the frozen first-half snapshot captured at halftime.
func get_first_half_snapshot() -> Dictionary[String, Variant]:
	return _first_half_snapshot.duplicate(true)


## Returns the second-half tactics and substitution plan.
func get_second_half_plan() -> Dictionary[String, Variant]:
	return _second_half_plan.duplicate(true)


## Returns the most recently finalized result packet.
func get_result_packet() -> Dictionary[String, Variant]:
	return _result_packet.duplicate(true)


## Returns the latest event emission diagnostic snapshot for tests.
func get_event_emit_debug() -> Dictionary[String, Variant]:
	return _event_emit_debug.duplicate(true)


## Overrides the runtime event bus for deterministic tests and isolated callers.
func set_event_bus_for_testing(event_bus: Node) -> void:
	_event_bus_override = event_bus


## Overrides the runtime balance config for deterministic tests and isolated callers.
func set_balance_config_for_testing(balance_config: BalanceConfig) -> void:
	_balance_config_override = balance_config


## Overrides the runtime match config for deterministic tests and isolated callers.
func set_match_config_for_testing(match_config: MatchConfig) -> void:
	_match_config_override = match_config


## Overrides the stored match seed for deterministic tests and isolated callers.
func set_match_seed_for_testing(match_seed: int) -> void:
	_has_match_seed_override = true
	_match_seed_override = match_seed


## Computes the actual win probability from the base probability plus match-level modifiers.
func compute_actual_win_probability(base_win_probability: float, home_advantage_mod: float, tactical_match_mod: float, condition_mod: float, event_mod: float) -> float:
	var balance_config: BalanceConfig = _get_balance_config()
	if balance_config == null:
		return clampf(base_win_probability + home_advantage_mod + tactical_match_mod + condition_mod + event_mod, 0.05, 0.95)
	return clampf(
		base_win_probability + home_advantage_mod + tactical_match_mod + condition_mod + event_mod,
		balance_config.win_probability_floor,
		balance_config.win_probability_ceiling
	)


## Computes actual win probability from team strengths and match-level modifiers.
func compute_strength_adjusted_win_probability(home_strength: float, away_strength: float, home_advantage_mod: float, tactical_match_mod: float, condition_mod: float, event_mod: float) -> float:
	var balance_config: BalanceConfig = _get_balance_config()
	var base_win_probability: float = 0.5
	if balance_config != null:
		base_win_probability = balance_config.compute_base_win_probability(home_strength, away_strength)
	return compute_actual_win_probability(base_win_probability, home_advantage_mod, tactical_match_mod, condition_mod, event_mod)


## Builds a legal MVP pre-match setup from the provided players without manual adjustment.
func build_recommended_pre_match_setup(players: Array[Player]) -> Dictionary[String, Variant]:
	var match_config: MatchConfig = _get_match_config()
	var lineup_slots: Array[Dictionary] = []
	var used_player_ids: Dictionary[int, bool] = {}
	lineup_slots.append_array(_build_slots_for_position(players, "GK", _resolve_recommended_position_count("GK", match_config), used_player_ids))
	lineup_slots.append_array(_build_slots_for_position(players, "DF", _resolve_recommended_position_count("DF", match_config), used_player_ids))
	lineup_slots.append_array(_build_slots_for_position(players, "MF", _resolve_recommended_position_count("MF", match_config), used_player_ids))
	lineup_slots.append_array(_build_slots_for_position(players, "FW", _resolve_recommended_position_count("FW", match_config), used_player_ids))
	if lineup_slots.size() < 11:
		for player: Player in players:
			if lineup_slots.size() >= 11:
				break
			if used_player_ids.has(player.id):
				continue
			lineup_slots.append(_build_lineup_slot(player, player.position))
			used_player_ids[player.id] = true
	return {
		"lineup_slots": lineup_slots,
		"tactics": {
			"label": _resolve_recommended_tactic_label(match_config),
			"tactical_match_mod": _resolve_recommended_tactical_match_mod(match_config),
		},
		"chemistry_factor": _resolve_default_chemistry_factor(match_config),
	}


## Returns whether the provided lineup satisfies the MVP legality contract.
func is_lineup_legal(lineup_slots: Array[Dictionary]) -> bool:
	if lineup_slots.size() != 11:
		return false
	var goalkeeper_count: int = 0
	for lineup_slot_variant: Variant in lineup_slots:
		var lineup_slot: Dictionary = lineup_slot_variant as Dictionary
		if not lineup_slot.has("player"):
			return false
		var player_variant: Variant = lineup_slot.get("player", null)
		if not (player_variant is Player):
			return false
		var assigned_position: String = String(lineup_slot.get("assigned_position", ""))
		if assigned_position.is_empty():
			return false
		if assigned_position == "GK":
			goalkeeper_count += 1
	return goalkeeper_count >= 1


## Computes the Story 002 team_match_strength from lineup slots, chemistry, and facility bonus.
func compute_team_match_strength(lineup_slots: Array[Dictionary], chemistry_factor: float, facility_rating_bonus: float) -> float:
	var weighted_sum: float = 0.0
	var weight_sum: float = 0.0
	for lineup_slot_variant: Variant in lineup_slots:
		var lineup_slot: Dictionary = lineup_slot_variant as Dictionary
		var player: Player = lineup_slot.get("player", null) as Player
		if player == null:
			continue
		var assigned_position: String = String(lineup_slot.get("assigned_position", ""))
		var lineup_weight: float = float(lineup_slot.get("lineup_weight", _resolve_lineup_weight(assigned_position, _get_match_config())))
		var positional_rating: float = compute_player_positional_rating(player, assigned_position)
		weighted_sum += positional_rating * lineup_weight
		weight_sum += lineup_weight
	if is_zero_approx(weight_sum):
		return maxf(1.0, facility_rating_bonus)
	var match_config: MatchConfig = _get_match_config()
	var normalized_chemistry: float = clampf(chemistry_factor, _resolve_chemistry_factor_min(match_config), _resolve_chemistry_factor_max(match_config))
	var lineup_base_strength: float = (weighted_sum / weight_sum) * normalized_chemistry
	return lineup_base_strength + maxf(0.0, facility_rating_bonus)


## Computes one player's position-adjusted match rating using shared balance weights and MVP fit penalty.
func compute_player_positional_rating(player: Player, assigned_position: String) -> float:
	if player == null:
		return 1.0
	var balance_config: BalanceConfig = _get_balance_config()
	var match_config: MatchConfig = _get_match_config()
	var attribute_weights: BalanceConfig.AttributeWeights = _resolve_attribute_weights(assigned_position, match_config)
	var positional_rating: float
	if balance_config == null:
		var fallback_average: float = _compute_effective_attribute_average(player)
		positional_rating = clampf(fallback_average, 1.0, 100.0)
	else:
		positional_rating = balance_config.compute_positional_overall_rating(
			player.attributes.spd.current * player.condition_multiplier,
			player.attributes.pwr.current * player.condition_multiplier,
			player.attributes.tec.current * player.condition_multiplier,
			player.attributes.intelligence.current * player.morale_multiplier,
			player.attributes.sta.current * player.condition_multiplier,
			attribute_weights
		)
	if player.position != assigned_position:
		positional_rating *= _resolve_out_of_position_penalty(match_config)
	return clampf(positional_rating, 1.0, 100.0)


const KEY_EVENT_CATEGORIES: Array[String] = [
	"offensive_push",
	"shot_on_goal",
	"goal_scored",
	"key_defense",
	"tactical_adaptation",
	"stamina_decline",
]

const WIN_REASON_CATEGORIES: Array[String] = [
	"阵容强度差距",
	"错位球员表现不足",
	"体能不足影响下半场",
	"战术克制生效",
	"关键事件逆转",
]

const POST_MATCH_GROWTH_TAGS: Array[String] = [
	"无",
	"轻度",
	"常规",
	"显著",
	"突破性",
]


## Generates readable key events from the current match probability context.
func generate_key_events(actual_win_probability: float, event_seed: int = 0) -> Array[Dictionary]:
	var seed: int = event_seed
	if _has_match_seed_override or _pending_match_context.has("match_seed"):
		seed = int(_pending_match_context.get("match_seed", event_seed))
	_match_rng.seed = seed
	_match_event_category_offset = _match_rng.randi_range(0, KEY_EVENT_CATEGORIES.size() - 1)
	var estimated_event_count: int = _estimate_key_event_count(actual_win_probability)
	var first_half_event_count: int = int(ceili(float(estimated_event_count) / 2.0))
	var second_half_event_count: int = maxi(0, estimated_event_count - first_half_event_count)
	var first_half_events: Array[Dictionary] = _build_half_events(actual_win_probability, estimated_event_count, 0, first_half_event_count, 1)
	var second_half_events: Array[Dictionary] = _build_half_events(actual_win_probability, estimated_event_count, first_half_event_count, second_half_event_count, 2)
	var events: Array[Dictionary] = first_half_events.duplicate(true)
	events.append_array(second_half_events)
	return events


## Applies halftime tactics and substitution changes for the second half only.
func apply_halftime_changes(new_tactics: Dictionary[String, Variant], substitutions: Array[Dictionary]) -> bool:
	if _state != State.HALFTIME_ADJUSTMENT:
		return false
	if substitutions.size() > 3:
		return false
	_second_half_plan = {
		"tactics": new_tactics.duplicate(true),
		"substitutions": substitutions.duplicate(true),
	}
	return true


## Registers this system with SaveManager using the story-scoped persistence contract.
func register_with_save_manager(save_manager: Node) -> bool:
	if save_manager == null:
		return false
	return save_manager.register_system("match", Callable(self, "serialize_state"), Callable(self, "deserialize_state"))


## Serializes current match state, degrading in-progress halves to a recoverable entry context.
func serialize_state() -> Dictionary[String, Variant]:
	var recoverable_state: State = _state
	var recoverable_history: Array[String] = _formal_state_history.duplicate()
	if _state == State.FIRST_HALF or _state == State.HALFTIME_ADJUSTMENT or _state == State.SECOND_HALF:
		recoverable_state = State.ENTRY
		recoverable_history = []
	var confirmed_results_snapshot: Dictionary[String, Variant] = {}
	for confirmed_match_id: String in _confirmed_results_by_match_id.keys():
		confirmed_results_snapshot[confirmed_match_id] = (_confirmed_results_by_match_id[confirmed_match_id] as Dictionary).duplicate(true)
	return {
		"state": int(recoverable_state),
		"state_name": _get_state_name(recoverable_state),
		"pending_match_context": _pending_match_context.duplicate(true),
		"result_packet": _result_packet.duplicate(true),
		"formal_state_history": recoverable_history,
		"confirmed_results_by_match_id": confirmed_results_snapshot,
	}


## Restores match state from serialized data while forbidding live-half recovery.
func deserialize_state(data: Dictionary[String, Variant]) -> void:
	_pending_match_context = _to_string_variant_dictionary(data.get("pending_match_context", {}))
	_result_packet = _to_string_variant_dictionary(data.get("result_packet", {}))
	_formal_state_history = (data.get("formal_state_history", []) as Array[String]).duplicate()
	_first_half_snapshot = {}
	_second_half_plan = {
		"tactics": {},
		"substitutions": [],
	}
	_first_half_events.clear()
	_second_half_events.clear()
	_planned_total_event_count = 0
	_planned_first_half_event_count = 0
	_match_event_category_offset = 0
	_confirmed_results_by_match_id.clear()
	var serialized_confirmed_results: Dictionary = data.get("confirmed_results_by_match_id", {}) as Dictionary
	for confirmed_match_id_variant: Variant in serialized_confirmed_results.keys():
		var confirmed_match_id: String = String(confirmed_match_id_variant)
		_confirmed_results_by_match_id[confirmed_match_id] = _to_string_variant_dictionary(serialized_confirmed_results[confirmed_match_id_variant])
	var requested_state: State = int(data.get("state", State.IDLE)) as State
	if requested_state == State.FIRST_HALF or requested_state == State.HALFTIME_ADJUSTMENT or requested_state == State.SECOND_HALF:
		requested_state = State.ENTRY
	_state = requested_state
	if _state == State.IDLE:
		_set_match_in_progress(false)
	elif _state == State.ENTRY:
		var match_seed: int = int(_pending_match_context.get("match_seed", _pending_match_context.get("event_seed", 0)))
		_match_rng.seed = match_seed
		_match_event_category_offset = _match_rng.randi_range(0, KEY_EVENT_CATEGORIES.size() - 1)
		_set_match_in_progress(false)


func _can_enter_formal_match() -> bool:
	if _time_manager == null:
		return false
	if _time_manager.has_method("can_enter_formal_match"):
		return bool(_time_manager.call("can_enter_formal_match"))
	if _time_manager.has_method("get_match_trigger_reached"):
		return bool(_time_manager.call("get_match_trigger_reached"))
	return false


func _transition_to(next_state: State) -> void:
	_state = next_state
	var state_name: String = _get_state_name(next_state)
	if not state_name.is_empty():
		_formal_state_history.append(state_name)
	if next_state != State.SETTLEMENT_HANDOFF:
		return
	var event_bus: Node = _get_event_bus()
	_event_emit_debug = {
		"event_name": "match_completed",
		"state_name": state_name,
		"event_bus_found": event_bus != null,
		"has_subscribers": event_bus != null and event_bus.call("has_subscribers", "match_completed"),
		"result_packet_match_id": String(_result_packet.get("match_id", "")),
	}
	if event_bus != null:
		event_bus.call("emit", "match_completed", _result_packet.duplicate(true))


func _to_string_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if value is Dictionary:
		var source: Dictionary = value as Dictionary
		for key: Variant in source.keys():
			typed_dictionary[String(key)] = source[key]
	return typed_dictionary


func _to_dictionary_array(value: Variant) -> Array[Dictionary]:
	var dictionaries: Array[Dictionary] = []
	if value is Array:
		for entry: Variant in value:
			if entry is Dictionary:
				dictionaries.append((entry as Dictionary).duplicate(true))
	return dictionaries


func _finalize_result_packet() -> void:
	var match_id: String = String(_pending_match_context.get("match_id", ""))
	var result: String = String(_pending_match_context.get("result", "draw"))
	var score: Dictionary[String, Variant] = _build_score_summary(result)
	var second_half_tactics: Dictionary[String, Variant] = _to_string_variant_dictionary(_second_half_plan.get("tactics", {}))
	var actual_win_probability: float = compute_strength_adjusted_win_probability(
		float(_pending_match_context.get("home_strength", 60.0)),
		float(_pending_match_context.get("away_strength", 60.0)),
		float(_pending_match_context.get("home_advantage_mod", 0.0)),
		float(second_half_tactics.get("tactical_match_mod", 0.0)),
		float(_pending_match_context.get("condition_mod", 0.0)),
		float(_pending_match_context.get("event_mod", 0.0))
	)
	var match_seed: int = int(_pending_match_context.get("match_seed", _pending_match_context.get("event_seed", 0)))
	if _first_half_events.is_empty():
		_capture_first_half_snapshot()
	var second_half_tactical_mod: float = float(second_half_tactics.get("tactical_match_mod", 0.0))
	var second_half_probability: float = _compute_match_win_probability(second_half_tactical_mod)
	if _planned_total_event_count <= 0:
		_planned_total_event_count = _estimate_key_event_count(actual_win_probability)
	if _planned_first_half_event_count <= 0:
		_planned_first_half_event_count = _count_first_half_events(_planned_total_event_count)
	var second_half_event_count: int = maxi(0, _planned_total_event_count - _planned_first_half_event_count)
	_second_half_events = _build_half_events(second_half_probability, _planned_total_event_count, _planned_first_half_event_count, second_half_event_count, 2)
	var events: Array[Dictionary] = _first_half_events.duplicate(true)
	events.append_array(_second_half_events.duplicate(true))
	for entry_variant: Variant in events:
		var event_entry: Dictionary = entry_variant as Dictionary
		_emit_match_event(event_entry)
	var player_appearances: Array[Dictionary] = _build_player_appearances()
	var win_reasons: Array[String] = _build_win_reasons(events)
	_result_packet = {
		"match_id": match_id,
		"result": result,
		"score": score,
		"key_event_summary": _build_key_event_summary(events),
		"player_appearances": player_appearances,
		"condition_changes": _build_condition_changes(player_appearances),
		"morale_changes": _build_morale_changes(player_appearances, result),
		"win_reasons": win_reasons,
		"post_match_tags": _build_post_match_tags(win_reasons, player_appearances),
		"state_history": _formal_state_history.duplicate(),
	}
	if not match_id.is_empty():
		_confirmed_results_by_match_id[match_id] = _result_packet.duplicate(true)


func _build_score_summary(result: String) -> Dictionary[String, Variant]:
	var match_config: MatchConfig = _get_match_config()
	if match_config == null:
		match result:
			"home_win":
				return {"home": 2, "away": 1}
			"away_win":
				return {"home": 1, "away": 2}
			_:
				return {"home": 1, "away": 1}
	match result:
		"home_win":
			return {"home": match_config.home_win_home_score, "away": match_config.home_win_away_score}
		"away_win":
			return {"home": match_config.away_win_home_score, "away": match_config.away_win_away_score}
		_:
			return {"home": match_config.draw_home_score, "away": match_config.draw_away_score}


func _build_key_event_summary(events: Array[Dictionary]) -> Dictionary[String, Variant]:
	var category_counts: Dictionary[String, Variant] = {}
	for category: String in KEY_EVENT_CATEGORIES:
		category_counts[category] = 0
	for entry_variant: Variant in events:
		var event_entry: Dictionary = entry_variant as Dictionary
		var category: String = String(event_entry.get("category", ""))
		if category_counts.has(category):
			category_counts[category] = int(category_counts[category]) + 1
	return {
		"events": events.duplicate(true),
		"event_count": events.size(),
		"category_counts": category_counts,
	}


func _build_player_appearances() -> Array[Dictionary]:
	var source_players: Array[Dictionary] = []
	if _pending_match_context.has("player_appearances"):
		source_players = _to_dictionary_array(_pending_match_context.get("player_appearances", []))
	else:
		source_players = [
			{"player_id": 1, "minutes": 90, "performance_score": 7.0, "team_side": "home"},
		]
	var appearances: Array[Dictionary] = []
	for entry_variant: Variant in source_players:
		var player_entry: Dictionary = entry_variant as Dictionary
		var minutes: int = maxi(0, int(player_entry.get("minutes", 0)))
		if minutes <= 0:
			continue
		var performance_score: float = clampf(float(player_entry.get("performance_score", 6.0)), 1.0, 10.0)
		var growth_tag: String = _classify_post_match_growth_tag(minutes, performance_score, float(_pending_match_context.get("away_strength", 60.0)))
		appearances.append({
			"player_id": int(player_entry.get("player_id", 0)),
			"minutes": minutes,
			"performance_score": performance_score,
			"post_match_growth_tag": growth_tag,
			"team_side": String(player_entry.get("team_side", "home")),
		})
	return appearances


func _build_condition_changes(player_appearances: Array[Dictionary]) -> Array[Dictionary]:
	var match_config: MatchConfig = _get_match_config()
	var condition_minutes_divisor: float = 180.0
	var condition_floor: float = 0.45
	if match_config != null:
		condition_minutes_divisor = match_config.condition_minutes_divisor
		condition_floor = match_config.condition_floor
	var changes: Array[Dictionary] = []
	for entry_variant: Variant in player_appearances:
		var player_entry: Dictionary = entry_variant as Dictionary
		var old_condition: float = 1.0
		var minutes: int = int(player_entry.get("minutes", 0))
		var new_condition: float = clampf(1.0 - (float(minutes) / condition_minutes_divisor), condition_floor, 1.0)
		changes.append({
			"player_id": int(player_entry.get("player_id", 0)),
			"old_condition": old_condition,
			"new_condition": new_condition,
		})
	return changes


func _build_morale_changes(player_appearances: Array[Dictionary], result: String) -> Array[Dictionary]:
	var match_config: MatchConfig = _get_match_config()
	var morale_win_delta: float = 0.12
	var morale_loss_delta: float = -0.10
	var morale_draw_delta: float = 0.02
	if match_config != null:
		morale_win_delta = match_config.morale_win_delta
		morale_loss_delta = match_config.morale_loss_delta
		morale_draw_delta = match_config.morale_draw_delta
	var changes: Array[Dictionary] = []
	for entry_variant: Variant in player_appearances:
		var player_entry: Dictionary = entry_variant as Dictionary
		var team_side: String = String(player_entry.get("team_side", "home"))
		var morale_delta: float = morale_draw_delta
		if result == "home_win":
			morale_delta = morale_win_delta if team_side == "home" else morale_loss_delta
		elif result == "away_win":
			morale_delta = morale_win_delta if team_side == "away" else morale_loss_delta
		changes.append({
			"player_id": int(player_entry.get("player_id", 0)),
			"old_morale": 0.5,
			"new_morale": clampf(0.5 + morale_delta, 0.0, 1.0),
		})
	return changes


func _build_win_reasons(events: Array[Dictionary]) -> Array[String]:
	var match_config: MatchConfig = _get_match_config()
	var strength_gap_reason_threshold: float = 10.0
	if match_config != null:
		strength_gap_reason_threshold = match_config.strength_gap_reason_threshold
	var reasons: Array[String] = []
	var strength_gap: float = absf(float(_pending_match_context.get("home_strength", 60.0)) - float(_pending_match_context.get("away_strength", 60.0)))
	if strength_gap >= strength_gap_reason_threshold:
		reasons.append("阵容强度差距")
	if bool(_pending_match_context.get("has_out_of_position_player", false)):
		reasons.append("错位球员表现不足")
	if _events_include_category(events, "stamina_decline"):
		reasons.append("体能不足影响下半场")
	var second_half_tactics: Dictionary[String, Variant] = _to_string_variant_dictionary(_second_half_plan.get("tactics", {}))
	if not second_half_tactics.is_empty() or _events_include_category(events, "tactical_adaptation"):
		reasons.append("战术克制生效")
	if bool(_pending_match_context.get("is_reversal", false)):
		reasons.append("关键事件逆转")
	if reasons.is_empty():
		if String(_pending_match_context.get("result", "draw")) == "draw":
			reasons.append("战术克制生效")
		elif _events_include_category(events, "goal_scored"):
			reasons.append("关键事件逆转")
		else:
			reasons.append("阵容强度差距")
	if reasons.size() > 3:
		reasons.resize(3)
	return reasons


func _build_post_match_tags(win_reasons: Array[String], player_appearances: Array[Dictionary]) -> Array[String]:
	var tags: Array[String] = []
	for reason: String in win_reasons:
		if not tags.has(reason):
			tags.append(reason)
	for entry_variant: Variant in player_appearances:
		var player_entry: Dictionary = entry_variant as Dictionary
		var growth_tag: String = String(player_entry.get("post_match_growth_tag", "无"))
		if not tags.has(growth_tag):
			tags.append(growth_tag)
	return tags


func _emit_match_event(event_entry: Dictionary) -> void:
	var event_bus: Node = _get_event_bus()
	_event_emit_debug = {
		"event_name": "match_event_occurred",
		"event_bus_found": event_bus != null,
		"has_subscribers": event_bus != null and event_bus.call("has_subscribers", "match_event_occurred"),
		"event_minute": int(event_entry.get("minute", 0)),
		"event_category": String(event_entry.get("category", "")),
	}
	if event_bus == null:
		return
	event_bus.call("emit", "match_event_occurred", {
		"event_category": String(event_entry.get("category", "")),
		"event_data": event_entry.duplicate(true),
		"match_minute": int(event_entry.get("minute", 0)),
	})


func _events_include_category(events: Array[Dictionary], category: String) -> bool:
	for entry_variant: Variant in events:
		var event_entry: Dictionary = entry_variant as Dictionary
		if String(event_entry.get("category", "")) == category:
			return true
	return false


func _compute_match_win_probability(tactical_match_mod: float) -> float:
	return compute_strength_adjusted_win_probability(
		float(_pending_match_context.get("home_strength", 60.0)),
		float(_pending_match_context.get("away_strength", 60.0)),
		float(_pending_match_context.get("home_advantage_mod", 0.0)),
		tactical_match_mod,
		float(_pending_match_context.get("condition_mod", 0.0)),
		float(_pending_match_context.get("event_mod", 0.0))
	)


func _estimate_key_event_count(actual_win_probability: float) -> int:
	var match_config: MatchConfig = _get_match_config()
	var balance_config: BalanceConfig = _get_balance_config()
	var probability_floor: float = 0.05
	var probability_ceiling: float = 0.95
	if balance_config != null:
		probability_floor = balance_config.win_probability_floor
		probability_ceiling = balance_config.win_probability_ceiling
	var clamped_probability: float = clampf(actual_win_probability, probability_floor, probability_ceiling)
	var min_key_events: int = 3
	var max_key_events: int = 15
	if match_config != null:
		min_key_events = match_config.min_key_events
		max_key_events = match_config.max_key_events
	var probability_span: float = maxf(0.000001, probability_ceiling - probability_floor)
	var normalized_probability: float = (clamped_probability - probability_floor) / probability_span
	return clampi(int(round(float(min_key_events) + normalized_probability * float(max_key_events - min_key_events))), min_key_events, max_key_events)


func _count_first_half_events(total_event_count: int) -> int:
	var first_half_event_count: int = 0
	for event_index: int in range(total_event_count):
		var event_minute: int = _compute_event_minute(event_index)
		if event_minute <= 45:
			first_half_event_count += 1
	return first_half_event_count


func _compute_event_minute(event_index: int) -> int:
	var match_config: MatchConfig = _get_match_config()
	var event_minute_start: int = 5
	var event_minute_step: int = 7
	if match_config != null:
		event_minute_start = match_config.event_minute_start
		event_minute_step = match_config.event_minute_step
	return mini(90, event_minute_start + event_index * event_minute_step)


func _build_half_events(actual_win_probability: float, total_event_count: int, start_index: int, half_event_count: int, half: int) -> Array[Dictionary]:
	var match_config: MatchConfig = _get_match_config()
	var balance_config: BalanceConfig = _get_balance_config()
	var low_density_event_count: int = 3
	if match_config != null:
		low_density_event_count = match_config.low_density_event_count
	var probability_floor: float = 0.05
	var probability_ceiling: float = 0.95
	if balance_config != null:
		probability_floor = balance_config.win_probability_floor
		probability_ceiling = balance_config.win_probability_ceiling
	var clamped_probability: float = clampf(actual_win_probability, probability_floor, probability_ceiling)
	var probability_span: float = maxf(0.000001, probability_ceiling - probability_floor)
	var normalized_probability: float = (clamped_probability - probability_floor) / probability_span
	var events: Array[Dictionary] = []
	for local_index: int in range(half_event_count):
		var event_index: int = start_index + local_index
		var category_roll: int = _match_rng.randi_range(0, KEY_EVENT_CATEGORIES.size() - 1)
		var category_index: int = (_match_event_category_offset + category_roll + event_index) % KEY_EVENT_CATEGORIES.size()
		var category: String = KEY_EVENT_CATEGORIES[category_index]
		var event_minute: int = _compute_event_minute(event_index)
		var home_bias: float = 0.1 + normalized_probability * 0.8
		var event_side: String = "home" if _match_rng.randf() <= clampf(home_bias, 0.1, 0.9) else "away"
		var narrative_tags: Array[String] = []
		var modifier_flags: Dictionary[String, Variant] = {
			"is_slow_pace": total_event_count == low_density_event_count,
			"is_high_impact": category == "goal_scored",
		}
		if total_event_count == low_density_event_count:
			narrative_tags.append("slow_pace")
		if category == "goal_scored":
			narrative_tags.append("high_impact")
		elif category == "shot_on_goal":
			narrative_tags.append("chance_created")
		elif category == "tactical_adaptation":
			narrative_tags.append("tactical_shift")
		elif category == "stamina_decline":
			narrative_tags.append("fatigue")
		else:
			narrative_tags.append("readable")
		events.append({
			"category": category,
			"minute": event_minute,
			"half": half,
			"side": event_side,
			"narrative_tags": narrative_tags,
			"modifier_flags": modifier_flags,
		})
	return events


func _classify_post_match_growth_tag(player_match_minutes: int, player_performance_score: float, opponent_strength_level: float) -> String:
	var match_config: MatchConfig = _get_match_config()
	var growth_tag_none_minutes: int = 5
	var growth_tag_light_minutes: int = 10
	var growth_tag_regular_minutes: int = 30
	var growth_tag_regular_score: float = 6.8
	var growth_tag_significant_minutes: int = 60
	var growth_tag_significant_score: float = 7.8
	var growth_tag_breakthrough_minutes: int = 75
	var growth_tag_breakthrough_score: float = 8.5
	var growth_tag_breakthrough_opponent_strength: float = 75.0
	if match_config != null:
		growth_tag_none_minutes = match_config.growth_tag_none_minutes
		growth_tag_light_minutes = match_config.growth_tag_light_minutes
		growth_tag_regular_minutes = match_config.growth_tag_regular_minutes
		growth_tag_regular_score = match_config.growth_tag_regular_score
		growth_tag_significant_minutes = match_config.growth_tag_significant_minutes
		growth_tag_significant_score = match_config.growth_tag_significant_score
		growth_tag_breakthrough_minutes = match_config.growth_tag_breakthrough_minutes
		growth_tag_breakthrough_score = match_config.growth_tag_breakthrough_score
		growth_tag_breakthrough_opponent_strength = match_config.growth_tag_breakthrough_opponent_strength
	if player_match_minutes < growth_tag_none_minutes:
		return "无"
	if player_match_minutes >= growth_tag_breakthrough_minutes and player_performance_score >= growth_tag_breakthrough_score and opponent_strength_level >= growth_tag_breakthrough_opponent_strength:
		return "突破性"
	if player_match_minutes >= growth_tag_significant_minutes and player_performance_score >= growth_tag_significant_score:
		return "显著"
	if player_match_minutes >= growth_tag_regular_minutes and player_performance_score >= growth_tag_regular_score:
		return "常规"
	if player_match_minutes >= growth_tag_light_minutes:
		return "轻度"
	return "无"


func _capture_first_half_snapshot() -> void:
	var first_half_probability: float = _compute_match_win_probability(0.0)
	_planned_total_event_count = _estimate_key_event_count(first_half_probability)
	_planned_first_half_event_count = _count_first_half_events(_planned_total_event_count)
	_first_half_events = _build_half_events(first_half_probability, _planned_total_event_count, 0, _planned_first_half_event_count, 1)
	_first_half_snapshot = {
		"state_name": "First Half",
		"state_history": _formal_state_history.duplicate(),
		"pending_match_context": _pending_match_context.duplicate(true),
		"event_count": _first_half_events.size(),
		"events": _first_half_events.duplicate(true),
	}


func _build_slots_for_position(players: Array[Player], assigned_position: String, required_count: int, used_player_ids: Dictionary[int, bool]) -> Array[Dictionary]:
	var matching_players: Array[Player] = []
	var fallback_players: Array[Player] = []
	for player: Player in players:
		if used_player_ids.has(player.id):
			continue
		if player.position == assigned_position:
			matching_players.append(player)
		else:
			fallback_players.append(player)
	var selected_slots: Array[Dictionary] = []
	for player: Player in matching_players:
		if selected_slots.size() >= required_count:
			break
		selected_slots.append(_build_lineup_slot(player, assigned_position))
		used_player_ids[player.id] = true
	for player: Player in fallback_players:
		if selected_slots.size() >= required_count:
			break
		selected_slots.append(_build_lineup_slot(player, assigned_position))
		used_player_ids[player.id] = true
	return selected_slots


func _build_lineup_slot(player: Player, assigned_position: String) -> Dictionary[String, Variant]:
	return {
		"player": player,
		"assigned_position": assigned_position,
		"lineup_weight": _resolve_lineup_weight(assigned_position, _get_match_config()),
	}


func _resolve_recommended_position_count(assigned_position: String, match_config: MatchConfig) -> int:
	match assigned_position:
		"GK":
			return 1 if match_config == null else match_config.recommended_goalkeeper_count
		"DF":
			return 4 if match_config == null else match_config.recommended_defender_count
		"MF":
			return 3 if match_config == null else match_config.recommended_midfielder_count
		"FW":
			return 3 if match_config == null else match_config.recommended_forward_count
		_:
			return 0


func _resolve_recommended_tactic_label(match_config: MatchConfig) -> String:
	if match_config == null:
		return "balanced"
	return match_config.recommended_tactic_label


func _resolve_recommended_tactical_match_mod(match_config: MatchConfig) -> float:
	if match_config == null:
		return 0.0
	return match_config.recommended_tactical_match_mod


func _resolve_default_chemistry_factor(match_config: MatchConfig) -> float:
	if match_config == null:
		return 1.0
	return match_config.default_chemistry_factor


func _resolve_chemistry_factor_min(match_config: MatchConfig) -> float:
	if match_config == null:
		return 0.85
	return match_config.chemistry_factor_min


func _resolve_chemistry_factor_max(match_config: MatchConfig) -> float:
	if match_config == null:
		return 1.15
	return match_config.chemistry_factor_max


func _resolve_out_of_position_penalty(match_config: MatchConfig) -> float:
	if match_config == null:
		return 0.85
	return match_config.out_of_position_penalty_multiplier


func _resolve_lineup_weight(assigned_position: String, match_config: MatchConfig) -> float:
	match assigned_position:
		"GK":
			return 0.9 if match_config == null else match_config.goalkeeper_lineup_weight
		"DF":
			return 0.95 if match_config == null else match_config.defender_lineup_weight
		"MF":
			return 1.0 if match_config == null else match_config.midfielder_lineup_weight
		"FW":
			return 1.0 if match_config == null else match_config.forward_lineup_weight
		_:
			return 1.0


func _resolve_attribute_weights(assigned_position: String, match_config: MatchConfig) -> BalanceConfig.AttributeWeights:
	var weights: Array[float] = []
	match assigned_position:
		"GK":
			weights = [0.05, 0.15, 0.10, 0.35, 0.35] if match_config == null else match_config.goalkeeper_attribute_weights
		"DF":
			weights = [0.15, 0.25, 0.10, 0.20, 0.30] if match_config == null else match_config.defender_attribute_weights
		"MF":
			weights = [0.20, 0.15, 0.25, 0.25, 0.15] if match_config == null else match_config.midfielder_attribute_weights
		"FW":
			weights = [0.25, 0.20, 0.30, 0.10, 0.15] if match_config == null else match_config.forward_attribute_weights
		_:
			weights = [0.20, 0.20, 0.20, 0.20, 0.20]
	return BalanceConfig.AttributeWeights.new(weights[0], weights[1], weights[2], weights[3], weights[4])


func _compute_effective_attribute_average(player: Player) -> float:
	return (
		player.attributes.spd.current * player.condition_multiplier +
		player.attributes.pwr.current * player.condition_multiplier +
		player.attributes.tec.current * player.condition_multiplier +
		player.attributes.intelligence.current * player.morale_multiplier +
		player.attributes.sta.current * player.condition_multiplier
	) / 5.0


func _set_match_in_progress(is_in_progress: bool) -> void:
	if _time_manager != null and _time_manager.has_method("set_match_in_progress"):
		_time_manager.call("set_match_in_progress", is_in_progress)


func _get_event_bus() -> Node:
	if _event_bus_override != null:
		return _event_bus_override
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/EventBus")


func _get_balance_config() -> BalanceConfig:
	if _balance_config_override != null:
		return _balance_config_override
	if not is_inside_tree():
		return null
	var config_loader: Node = get_node_or_null("/root/ConfigLoader")
	if config_loader == null:
		return null
	return config_loader.get("balance_config") as BalanceConfig


func _get_match_config() -> MatchConfig:
	if _match_config_override != null:
		return _match_config_override
	if not is_inside_tree():
		return null
	var config_loader: Node = get_node_or_null("/root/ConfigLoader")
	if config_loader == null:
		return null
	return config_loader.get("match_config") as MatchConfig


func _get_state_name(state: State) -> String:
	match state:
		State.ENTRY:
			return "Entry"
		State.PRE_MATCH_PREPARATION:
			return "Pre-Match"
		State.CONFIRMATION:
			return "Confirmation"
		State.FIRST_HALF:
			return "First Half"
		State.HALFTIME_ADJUSTMENT:
			return "Halftime"
		State.SECOND_HALF:
			return "Second Half"
		State.RESULT_REVIEW:
			return "Result Review"
		State.SETTLEMENT_HANDOFF:
			return "Settlement"
		_:
			return ""
