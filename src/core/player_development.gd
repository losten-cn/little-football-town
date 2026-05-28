class_name PlayerDevelopment
extends Node

class BufferedEventBus:
	extends Node

	var recorded_events: Array = []

	func emit(event_name: String, payload: Dictionary = {}) -> void:
		recorded_events.append({
			"event_name": event_name,
			"payload": payload.duplicate(true),
		})


const PlayerRosterScript: Script = preload("res://src/core/player_roster.gd")
const BalanceConfigScript: Script = preload("res://src/config/balance_config.gd")
const CONDITION_MULTIPLIER_RANGE: Vector2 = Vector2(0.45, 1.0)
const MORALE_MULTIPLIER_RANGE: Vector2 = Vector2(0.0, 1.0)
const ATTRIBUTE_MILESTONE_STEPS: Array[String] = ["SPD", "PWR", "TEC", "INT", "STA"]

var _roster: PlayerRoster = PlayerRosterScript.new()
var save_manager: Variant = null
var _balance_config_override: BalanceConfig = null
var _event_bus_override: Node = null
var _training_failure_stage_for_testing: String = ""


func _ready() -> void:
	var active_save_manager: Variant = save_manager
	if active_save_manager:
		active_save_manager.register_system("player", _serialize, _deserialize)
	_subscribe_to_time_events()


## Overrides the runtime balance config for deterministic tests and isolated callers.
func set_balance_config_for_testing(balance_config: BalanceConfig) -> void:
	_balance_config_override = balance_config


## Overrides the runtime EventBus for deterministic tests.
func set_event_bus_for_testing(event_bus: Node) -> void:
	_event_bus_override = event_bus


## Overrides the authoritative roster for deterministic tests.
func set_roster_for_testing(roster: PlayerRoster) -> void:
	_roster = roster if roster != null else PlayerRosterScript.new()


## Injects a post-deduct failure stage for deterministic rollback tests.
func set_training_failure_stage_for_testing(stage_name: String) -> void:
	_training_failure_stage_for_testing = stage_name.strip_edges()


## Executes the authoritative training operation through validate → deduct → grow → apply → emit.
func train(player_id: int, training_project: Dictionary[String, Variant], economy_manager: EconomyManager, time_manager: Node) -> Dictionary[String, Variant]:
	var stage_sequence: Array[String] = ["validate"]
	var player: Player = _roster.get_player(player_id)
	if player == null:
		return {"success": false, "error": "player_not_found", "stage": "validate", "stage_sequence": stage_sequence}
	if training_project.is_empty():
		return {"success": false, "error": "training_project_missing", "stage": "validate", "stage_sequence": stage_sequence}
	if economy_manager == null:
		return {"success": false, "error": "economy_manager_missing", "stage": "validate", "stage_sequence": stage_sequence}
	if time_manager == null:
		return {"success": false, "error": "time_manager_missing", "stage": "validate", "stage_sequence": stage_sequence}

	var primary_attribute: String = String(training_project.get("primary_attribute", "")).strip_edges()
	var raw_growth_input: float = float(training_project.get("raw_growth_input", 0.0))
	var funds_cost: int = int(training_project.get("funds_cost", 0))
	var action_points_cost: int = int(training_project.get("action_points_cost", 0))
	var time_cost: float = float(training_project.get("time_cost", 0.0))
	var facility_training_multiplier: float = float(training_project.get("facility_training_multiplier", 1.0))
	var focus_match_multiplier: float = resolve_training_focus_match_multiplier(training_project)
	if primary_attribute.is_empty() or _get_attribute_triplet(player, primary_attribute) == null:
		return {"success": false, "error": "invalid_primary_attribute", "stage": "validate", "stage_sequence": stage_sequence}
	if raw_growth_input <= 0.0:
		return {"success": false, "error": "invalid_raw_growth_input", "stage": "validate", "stage_sequence": stage_sequence}
	if funds_cost < 0 or action_points_cost < 0 or time_cost <= 0.0:
		return {"success": false, "error": "invalid_training_cost", "stage": "validate", "stage_sequence": stage_sequence}

	var calculated_time_cost: Dictionary[String, Variant] = time_manager.call("calculate_action_time_cost", time_cost, 1.0) as Dictionary[String, Variant]
	if not (calculated_time_cost.get("success", false) as bool):
		return {"success": false, "error": String(calculated_time_cost.get("reason", "invalid_time_cost")), "stage": "validate", "stage_sequence": stage_sequence}
	var resolved_time_cost: float = float(calculated_time_cost.get("action_time_cost", 0.0))
	var committed_time_units: int = int(ceil(resolved_time_cost))
	var time_validation: Dictionary[String, Variant] = time_manager.call("can_consume_action_time", float(committed_time_units)) as Dictionary[String, Variant]
	if not (time_validation.get("success", false) as bool):
		return {"success": false, "error": String(time_validation.get("reason", "insufficient_time")), "stage": "validate", "stage_sequence": stage_sequence}

	var transaction_context: Dictionary[String, Variant] = _begin_training_transaction(player, primary_attribute, economy_manager, time_manager)
	var active_event_bus: Node = _get_event_bus()
	var original_economy_event_bus: Node = economy_manager.get("_event_bus_override") as Node
	var original_time_event_bus: Node = time_manager.get("_event_bus_override") as Node
	var buffered_event_bus: BufferedEventBus = BufferedEventBus.new()
	economy_manager.set_event_bus_for_testing(buffered_event_bus)
	time_manager.call("set_event_bus_for_testing", buffered_event_bus)

	stage_sequence.append("deduct")
	var economy_result: Dictionary[String, Variant] = economy_manager.accredit_training_cost(funds_cost, action_points_cost, player_id)
	if not (economy_result.get("success", false) as bool):
		economy_manager.set_event_bus_for_testing(original_economy_event_bus)
		time_manager.call("set_event_bus_for_testing", original_time_event_bus)
		return {"success": false, "error": String(economy_result.get("error", "training_cost_failed")), "stage": "deduct", "stage_sequence": stage_sequence}
	if _should_fail_training_stage("grow"):
		economy_manager.set_event_bus_for_testing(original_economy_event_bus)
		time_manager.call("set_event_bus_for_testing", original_time_event_bus)
		_rollback_training_transaction(player, economy_manager, time_manager, transaction_context)
		return {"success": false, "error": "forced_training_failure", "stage": "grow", "stage_sequence": stage_sequence + ["grow"]}

	time_manager.call("consume_time", committed_time_units)
	stage_sequence.append("grow")
	var attribute_triplet: Player.AttributeTriplet = _get_attribute_triplet(player, primary_attribute)
	var gain_before_apply: float = resolve_training_actual_gain(
		player,
		attribute_triplet.current,
		attribute_triplet.potential,
		raw_growth_input,
		focus_match_multiplier,
		facility_training_multiplier,
		_get_growth_decay_factor(),
	)
	if _should_fail_training_stage("apply"):
		economy_manager.set_event_bus_for_testing(original_economy_event_bus)
		time_manager.call("set_event_bus_for_testing", original_time_event_bus)
		_rollback_training_transaction(player, economy_manager, time_manager, transaction_context)
		return {"success": false, "error": "forced_training_failure", "stage": "apply", "stage_sequence": stage_sequence + ["apply"]}

	stage_sequence.append("apply")
	var attribute_before_apply: int = attribute_triplet.current
	var applied_gain: float = apply_training_gain_to_attribute(
		player,
		primary_attribute,
		raw_growth_input,
		focus_match_multiplier,
		facility_training_multiplier,
		_get_growth_decay_factor(),
	)
	player.total_training_sessions += 1
	var training_history_entry: Dictionary[String, Variant] = {
		"project_id": String(training_project.get("project_id", "")),
		"primary_attribute": primary_attribute,
		"applied_gain": applied_gain,
		"funds_cost": funds_cost,
		"action_points_cost": action_points_cost,
		"time_cost": resolved_time_cost,
		"attribute_before": attribute_before_apply,
		"attribute_after": attribute_triplet.current,
		"training_session": player.total_training_sessions,
	}
	player.training_history.append(training_history_entry)
	var milestone_events: Array[Dictionary] = _collect_player_milestones(player, primary_attribute, attribute_before_apply, attribute_triplet.current)
	if _should_fail_training_stage("emit"):
		economy_manager.set_event_bus_for_testing(original_economy_event_bus)
		time_manager.call("set_event_bus_for_testing", original_time_event_bus)
		_rollback_training_transaction(player, economy_manager, time_manager, transaction_context)
		return {"success": false, "error": "forced_training_failure", "stage": "emit", "stage_sequence": stage_sequence + ["emit"]}

	economy_manager.set_event_bus_for_testing(original_economy_event_bus)
	time_manager.call("set_event_bus_for_testing", original_time_event_bus)
	_replay_buffered_events(buffered_event_bus.recorded_events, active_event_bus)
	stage_sequence.append("emit")
	_emit_player_training_completed(player, training_project, funds_cost, action_points_cost, resolved_time_cost, primary_attribute, applied_gain)
	_emit_player_milestones(player, milestone_events)
	return {
		"success": true,
		"tx_id": int(economy_result.get("tx_id", 0)),
		"player_id": player_id,
		"primary_attribute": primary_attribute,
		"resolved_gain": gain_before_apply,
		"applied_gain": applied_gain,
		"stage": "emit",
		"stage_sequence": stage_sequence,
	}


## Applies authoritative post-match player-state changes through the match-result boundary.
func apply_match_result_player_state(match_result_packet: Dictionary[String, Variant], source_tag: String = "match_result") -> Dictionary[String, Variant]:
	if match_result_packet.is_empty():
		return {
			"success": false,
			"error": "match_result_packet_missing",
			"review_required": false,
			"applied_player_ids": [],
			"flagged_player_ids": [],
		}

	var root_unexpected_keys: Array[String] = _find_unexpected_keys(match_result_packet, ["match_id", "condition_changes", "morale_changes"])
	var condition_updates: Dictionary = {}
	var morale_updates: Dictionary = {}
	var flagged_player_ids: Array[int] = []
	var review_entries: Array[Dictionary] = []
	var applied_player_ids: Array[int] = []
	var match_id: String = String(match_result_packet.get("match_id", "")).strip_edges()
	if not root_unexpected_keys.is_empty():
		_append_state_update_review(review_entries, flagged_player_ids, 0, "match_result_packet_rejected", {"unexpected_keys": root_unexpected_keys})
		_emit_match_player_state_events(match_id, source_tag, applied_player_ids, flagged_player_ids, review_entries)
		return {
			"success": false,
			"match_id": match_id,
			"review_required": true,
			"applied_player_ids": applied_player_ids,
			"flagged_player_ids": flagged_player_ids,
			"review_entries": review_entries,
		}
	for change_variant: Variant in match_result_packet.get("condition_changes", []):
		if not (change_variant is Dictionary):
			_append_state_update_review(review_entries, flagged_player_ids, 0, "condition_change_invalid")
			continue
		var change: Dictionary = change_variant
		var player_id: int = int(change.get("player_id", 0))
		var player: Player = _roster.get_player(player_id)
		if player == null:
			_append_state_update_review(review_entries, flagged_player_ids, player_id, "player_not_found")
			continue
		var unexpected_keys: Array[String] = _find_unexpected_keys(change, ["player_id", "old_condition", "new_condition"])
		if not unexpected_keys.is_empty():
			_append_state_update_review(review_entries, flagged_player_ids, player_id, "condition_change_rejected", {"unexpected_keys": unexpected_keys})
			continue
		if not change.has("new_condition"):
			_append_state_update_review(review_entries, flagged_player_ids, player_id, "condition_change_missing_new_value")
			continue
		if change.has("old_condition") and not is_equal_approx(float(change.get("old_condition", player.condition_multiplier)), player.condition_multiplier):
			_append_state_update_review(review_entries, flagged_player_ids, player_id, "condition_change_stale")
			continue
		var resolved_condition: float = float(change.get("new_condition", player.condition_multiplier))
		if not _is_within_multiplier_range(resolved_condition, CONDITION_MULTIPLIER_RANGE):
			_append_state_update_review(review_entries, flagged_player_ids, player_id, "condition_change_out_of_range")
			continue
		if condition_updates.has(player_id):
			if is_equal_approx(float(condition_updates[player_id]), resolved_condition):
				continue
			_append_state_update_review(review_entries, flagged_player_ids, player_id, "condition_change_conflict")
			continue
		condition_updates[player_id] = resolved_condition
	for change_variant: Variant in match_result_packet.get("morale_changes", []):
		if not (change_variant is Dictionary):
			_append_state_update_review(review_entries, flagged_player_ids, 0, "morale_change_invalid")
			continue
		var change: Dictionary = change_variant
		var player_id: int = int(change.get("player_id", 0))
		var player: Player = _roster.get_player(player_id)
		if player == null:
			_append_state_update_review(review_entries, flagged_player_ids, player_id, "player_not_found")
			continue
		var unexpected_keys: Array[String] = _find_unexpected_keys(change, ["player_id", "old_morale", "new_morale"])
		if not unexpected_keys.is_empty():
			_append_state_update_review(review_entries, flagged_player_ids, player_id, "morale_change_rejected", {"unexpected_keys": unexpected_keys})
			continue
		if not change.has("new_morale"):
			_append_state_update_review(review_entries, flagged_player_ids, player_id, "morale_change_missing_new_value")
			continue
		if change.has("old_morale") and not is_equal_approx(float(change.get("old_morale", player.morale_multiplier)), player.morale_multiplier):
			_append_state_update_review(review_entries, flagged_player_ids, player_id, "morale_change_stale")
			continue
		var resolved_morale: float = float(change.get("new_morale", player.morale_multiplier))
		if not _is_within_multiplier_range(resolved_morale, MORALE_MULTIPLIER_RANGE):
			_append_state_update_review(review_entries, flagged_player_ids, player_id, "morale_change_out_of_range")
			continue
		if morale_updates.has(player_id):
			if is_equal_approx(float(morale_updates[player_id]), resolved_morale):
				continue
			_append_state_update_review(review_entries, flagged_player_ids, player_id, "morale_change_conflict")
			continue
		morale_updates[player_id] = resolved_morale

	for player_id_variant: Variant in condition_updates.keys():
		var player_id: int = int(player_id_variant)
		if flagged_player_ids.has(player_id):
			continue
		var player: Player = _roster.get_player(player_id)
		if player == null:
			continue
		player.condition_multiplier = float(condition_updates[player_id])
		if morale_updates.has(player_id):
			player.morale_multiplier = float(morale_updates[player_id])
		applied_player_ids.append(player_id)
	for player_id_variant: Variant in morale_updates.keys():
		var player_id: int = int(player_id_variant)
		if flagged_player_ids.has(player_id) or condition_updates.has(player_id):
			continue
		var player: Player = _roster.get_player(player_id)
		if player == null:
			continue
		player.morale_multiplier = float(morale_updates[player_id])
		applied_player_ids.append(player_id)

	_emit_match_player_state_events(match_id, source_tag, applied_player_ids, flagged_player_ids, review_entries)
	return {
		"success": review_entries.is_empty(),
		"match_id": match_id,
		"review_required": not review_entries.is_empty(),
		"applied_player_ids": applied_player_ids,
		"flagged_player_ids": flagged_player_ids,
		"review_entries": review_entries,
	}


## Returns normalized player training efficiency and marks abnormal values for review.
func normalize_training_efficiency(player: Player) -> float:
	var normalized_value: float = clampf(player.training_efficiency, 0.8, 1.5)
	if not is_equal_approx(normalized_value, player.training_efficiency):
		player.training_efficiency = normalized_value
		if not player.review_flags.has("training_efficiency_out_of_range"):
			player.review_flags.append("training_efficiency_out_of_range")
	return player.training_efficiency


## Returns fatigue-adjusted training efficiency using condition and morale modifiers.
func get_fatigue_adjusted_training_efficiency(player: Player) -> float:
	var base_efficiency: float = normalize_training_efficiency(player)
	return clampf(base_efficiency * player.condition_multiplier * player.morale_multiplier, 0.5, 1.8)


## Returns shared attribute growth before player-specific multipliers are applied.
func attribute_growth(raw_growth_input: float, current_attribute: int, potential_cap: int, decay_factor: float) -> float:
	return (BalanceConfigScript.new() as BalanceConfig).compute_attribute_growth(raw_growth_input, float(current_attribute), float(potential_cap), decay_factor)


## Returns a facility training multiplier constrained to the TownBuilding contract range.
func normalize_facility_training_multiplier(player: Player, facility_training_multiplier: float) -> float:
	var normalized_multiplier: float = clampf(facility_training_multiplier, 1.0, 1.75)
	if not is_equal_approx(normalized_multiplier, facility_training_multiplier):
		if not player.review_flags.has("facility_training_multiplier_out_of_range"):
			player.review_flags.append("facility_training_multiplier_out_of_range")
	return normalized_multiplier


## Returns the resolved training gain for one attribute before it is applied.
func resolve_training_actual_gain(
	player: Player,
	current_attribute: int,
	potential_cap: int,
	raw_growth_input: float,
	focus_match_multiplier: float,
	facility_training_multiplier: float,
	decay_factor: float,
) -> float:
	var normalized_potential_cap: int = potential_cap
	if normalized_potential_cap < current_attribute:
		normalized_potential_cap = current_attribute
		if not player.review_flags.has("attribute_potential_below_current"):
			player.review_flags.append("attribute_potential_below_current")
	var remaining_growth_room: int = normalized_potential_cap - current_attribute
	if remaining_growth_room <= 0:
		return 0.0
	var base_growth: float = attribute_growth(raw_growth_input, current_attribute, normalized_potential_cap, decay_factor)
	var fatigue_adjusted_efficiency: float = get_fatigue_adjusted_training_efficiency(player)
	var normalized_facility_multiplier: float = normalize_facility_training_multiplier(player, facility_training_multiplier)
	return minf(
		float(remaining_growth_room),
		base_growth * fatigue_adjusted_efficiency * focus_match_multiplier * normalized_facility_multiplier,
	)


## Applies one resolved training gain to the selected attribute and returns the gain.
func apply_training_gain_to_attribute(
	player: Player,
	attribute_name: String,
	raw_growth_input: float,
	focus_match_multiplier: float,
	facility_training_multiplier: float,
	decay_factor: float,
) -> float:
	var attribute_triplet: Player.AttributeTriplet = _get_attribute_triplet(player, attribute_name)
	if attribute_triplet == null:
		return 0.0
	var resolved_gain: float = resolve_training_actual_gain(
		player,
		attribute_triplet.current,
		attribute_triplet.potential,
		raw_growth_input,
		focus_match_multiplier,
		facility_training_multiplier,
		decay_factor,
	)
	if attribute_triplet.potential < attribute_triplet.current:
		attribute_triplet.potential = attribute_triplet.current
	attribute_triplet.current = mini(attribute_triplet.potential, int(round(attribute_triplet.current + resolved_gain)))
	return resolved_gain


## Returns the focus match multiplier from training-project data.
func resolve_training_focus_match_multiplier(training_project: Dictionary[String, Variant]) -> float:
	return float(training_project.get("focus_match_multiplier", 1.0))


## Returns resolved secondary-attribute gains and whether any secondary gain was cap-limited.
func resolve_secondary_attribute_gains(
	player: Player,
	secondary_attributes: Array[String],
	raw_growth_input: float,
	focus_match_multiplier: float,
	facility_training_multiplier: float,
	decay_factor: float,
	secondary_gain_ratio: float,
) -> Dictionary[String, Variant]:
	var gains_by_attribute: Dictionary[String, float] = {}
	var cap_limited: bool = false
	for attribute_name: String in secondary_attributes:
		var attribute_triplet: Player.AttributeTriplet = _get_attribute_triplet(player, attribute_name)
		if attribute_triplet == null:
			continue
		var resolved_gain: float = resolve_training_actual_gain(
			player,
			attribute_triplet.current,
			attribute_triplet.potential,
			raw_growth_input * secondary_gain_ratio,
			focus_match_multiplier,
			facility_training_multiplier,
			decay_factor,
		)
		var unconstrained_gain: float = attribute_growth(
			raw_growth_input * secondary_gain_ratio,
			attribute_triplet.current,
			maxi(attribute_triplet.current + 1, attribute_triplet.potential),
			decay_factor,
		) * get_fatigue_adjusted_training_efficiency(player) * focus_match_multiplier * normalize_facility_training_multiplier(player, facility_training_multiplier)
		if resolved_gain < unconstrained_gain:
			cap_limited = true
		gains_by_attribute[attribute_name] = resolved_gain
	return {
		"gains": gains_by_attribute,
		"cap_limited": cap_limited,
	}


## Returns one ROI sample using the EconomyManager AP valuation supplied by the caller.
func calculate_player_development_roi(
	primary_gain: float,
	secondary_total_gain: float,
	funds_cost: float,
	action_points_cost: float,
	time_cost_slots: float,
	ap_to_funds_weight: float,
) -> float:
	if ap_to_funds_weight <= 0.0:
		return -1.0
	var effective_growth_value: float = primary_gain + secondary_total_gain * 0.35
	var weighted_total_training_cost: float = funds_cost + action_points_cost * ap_to_funds_weight + time_cost_slots
	return effective_growth_value / maxf(1.0, weighted_total_training_cost)


## Returns whether ROI samples satisfy the ordinary-vs-star short/mid-term target bands.
func evaluate_roi_sample(
	ordinary_short_term_roi: float,
	star_short_term_roi: float,
	ordinary_mid_term_roi: float,
	star_mid_term_roi: float,
) -> Dictionary[String, Variant]:
	var short_term_passes: bool = ordinary_short_term_roi >= star_short_term_roi * 0.9
	var mid_term_passes: bool = star_mid_term_roi > ordinary_mid_term_roi
	return {
		"passes": short_term_passes and mid_term_passes,
		"short_term_passes": short_term_passes,
		"mid_term_passes": mid_term_passes,
		"tuning_failure": not (short_term_passes and mid_term_passes),
	}


func _get_attribute_triplet(player: Player, attribute_name: String) -> Player.AttributeTriplet:
	match attribute_name:
		"SPD":
			return player.attributes.spd
		"PWR":
			return player.attributes.pwr
		"TEC":
			return player.attributes.tec
		"INT":
			return player.attributes.intelligence
		"STA":
			return player.attributes.sta
	return null


func _map_tier_to_config_key(tier: String) -> String:
	match tier:
		"普通", "normal":
			return "normal"
		"优秀", "excellent":
			return "excellent"
		"明星", "star":
			return "star"
		"传奇胚子", "legend_prospect":
			return "legend_prospect"
	return ""


func _get_tier_training_efficiency_range(tier: String) -> Vector2:
	var balance_config: BalanceConfig = _get_balance_config()
	if balance_config == null:
		return Vector2(0.5, 1.8)
	var config_tier_key: String = _map_tier_to_config_key(tier)
	if config_tier_key.is_empty():
		return Vector2(0.5, 1.8)
	return balance_config.player_tier_training_efficiency.get(config_tier_key, Vector2(0.5, 1.8)) as Vector2


func _get_balance_config() -> BalanceConfig:
	if _balance_config_override != null:
		return _balance_config_override
	if not is_inside_tree():
		return BalanceConfigScript.new() as BalanceConfig
	var config_loader: Node = get_node_or_null("/root/ConfigLoader")
	if config_loader == null:
		return BalanceConfigScript.new() as BalanceConfig
	var loaded_config: BalanceConfig = config_loader.get("balance_config") as BalanceConfig
	if loaded_config == null:
		return BalanceConfigScript.new() as BalanceConfig
	return loaded_config


func _get_growth_decay_factor() -> float:
	var balance_config: BalanceConfig = _get_balance_config()
	if balance_config == null:
		return 1.2
	return balance_config.decay_factor


func _get_event_bus() -> Node:
	if _event_bus_override != null:
		return _event_bus_override
	if not is_inside_tree():
		return null
	return get_node_or_null("/root/EventBus")


func _should_fail_training_stage(stage_name: String) -> bool:
	return _training_failure_stage_for_testing == stage_name


func _begin_training_transaction(player: Player, primary_attribute: String, economy_manager: EconomyManager, time_manager: Node) -> Dictionary[String, Variant]:
	var state_snapshot: Dictionary[String, Variant] = time_manager.get_state()
	var windows: Dictionary = state_snapshot.get("available_action_windows", {}) as Dictionary
	var attribute_triplet: Player.AttributeTriplet = _get_attribute_triplet(player, primary_attribute)
	var economy_snapshot: Dictionary[String, Variant] = economy_manager.serialize()
	return {
		"funds": economy_manager.get_funds(),
		"action_points": economy_manager.get_action_points(),
		"research_points": economy_manager.get_research_points(),
		"next_tx_id": int(economy_snapshot.get("next_tx_id", 1)),
		"transactions": economy_snapshot.get("transactions", []),
		"warning_cooldowns": (economy_manager.get("_warning_cooldown_by_type") as Dictionary).duplicate(true),
		"time_state": state_snapshot.duplicate(true),
		"schedule_available": bool(time_manager.get("_schedule_available")),
		"schedule_loading": bool(time_manager.get("_schedule_loading")),
		"schedule_missing": bool(time_manager.get("_schedule_missing")),
		"match_center_available": bool(time_manager.get("_match_center_available")),
		"consumed_time": int(windows.get("consumed_time", 0)),
		"primary_attribute": primary_attribute,
		"attribute_current": attribute_triplet.current if attribute_triplet != null else 0,
		"attribute_potential": attribute_triplet.potential if attribute_triplet != null else 0,
		"training_history_size": player.training_history.size(),
		"milestones_size": player.milestones.size(),
		"total_training_sessions": player.total_training_sessions,
	}


func _rollback_training_transaction(player: Player, economy_manager: EconomyManager, time_manager: Node, transaction_context: Dictionary[String, Variant]) -> void:
	economy_manager.deserialize({
		"funds": transaction_context.get("funds", 0.0),
		"action_points": transaction_context.get("action_points", 0.0),
		"research_points": transaction_context.get("research_points", 0.0),
		"next_tx_id": transaction_context.get("next_tx_id", 1),
		"transactions": transaction_context.get("transactions", []),
	})
	economy_manager.set("_warning_cooldown_by_type", (transaction_context.get("warning_cooldowns", {}) as Dictionary).duplicate(true))
	var state_snapshot: Dictionary = (transaction_context.get("time_state", {}) as Dictionary).duplicate(true)
	state_snapshot["schedule_available"] = bool(transaction_context.get("schedule_available", false))
	state_snapshot["schedule_loading"] = bool(transaction_context.get("schedule_loading", false))
	state_snapshot["schedule_missing"] = bool(transaction_context.get("schedule_missing", false))
	state_snapshot["match_center_available"] = bool(transaction_context.get("match_center_available", false))
	var available_action_windows: Dictionary = state_snapshot.get("available_action_windows", {}) as Dictionary
	available_action_windows["consumed_time"] = int(transaction_context.get("consumed_time", 0))
	state_snapshot["available_action_windows"] = available_action_windows
	time_manager.apply_snapshot(state_snapshot)
	player.training_history.resize(int(transaction_context.get("training_history_size", 0)))
	player.milestones.resize(int(transaction_context.get("milestones_size", 0)))
	player.total_training_sessions = int(transaction_context.get("total_training_sessions", 0))
	var primary_attribute: String = String(transaction_context.get("primary_attribute", ""))
	var attribute_triplet: Player.AttributeTriplet = _get_attribute_triplet(player, primary_attribute)
	if attribute_triplet != null:
		attribute_triplet.current = int(transaction_context.get("attribute_current", attribute_triplet.current))
		attribute_triplet.potential = int(transaction_context.get("attribute_potential", attribute_triplet.potential))


func _replay_buffered_events(recorded_events: Array, event_bus: Node) -> void:
	if event_bus == null:
		return
	for recorded_event: Dictionary in recorded_events:
		event_bus.call("emit", String(recorded_event.get("event_name", "")), recorded_event.get("payload", {}) as Dictionary)


func _collect_player_milestones(player: Player, attribute_name: String, attribute_before: int, attribute_after: int) -> Array[Dictionary]:
	var milestone_events: Array[Dictionary] = []
	if attribute_after > attribute_before:
		var starting_band: int = int(floor(float(attribute_before) / 10.0))
		var ending_band: int = int(floor(float(attribute_after) / 10.0))
		for crossed_band: int in range(starting_band + 1, ending_band + 1):
			var milestone_value: int = crossed_band * 10
			if milestone_value <= 0:
				continue
			var milestone_key: String = "%s_%d" % [attribute_name, milestone_value]
			if player.milestones.has(milestone_key):
				continue
			player.milestones.append(milestone_key)
			milestone_events.append({
				"player_id": player.id,
				"player_name": player.name,
				"milestone_key": milestone_key,
				"milestone_type": "attribute",
				"attribute": attribute_name,
				"milestone_value": milestone_value,
				"training_sessions": player.total_training_sessions,
			})
	for training_threshold: int in _get_training_session_milestones():
		if player.total_training_sessions != training_threshold:
			continue
		var session_milestone_key: String = "TRAINING_%d" % training_threshold
		if player.milestones.has(session_milestone_key):
			continue
		player.milestones.append(session_milestone_key)
		milestone_events.append({
			"player_id": player.id,
			"player_name": player.name,
			"milestone_key": session_milestone_key,
			"milestone_type": "training_sessions",
			"attribute": attribute_name,
			"milestone_value": training_threshold,
			"training_sessions": player.total_training_sessions,
		})
	return milestone_events


func _emit_player_training_completed(
	player: Player,
	training_project: Dictionary[String, Variant],
	funds_cost: int,
	action_points_cost: int,
	resolved_time_cost: float,
	primary_attribute: String,
	applied_gain: float,
) -> void:
	var event_bus: Node = _get_event_bus()
	if event_bus == null:
		return
	event_bus.call("emit", "player_training_completed", {
		"player_id": player.id,
		"player_name": player.name,
		"project_id": String(training_project.get("project_id", "")),
		"primary_attribute": primary_attribute,
		"applied_gain": applied_gain,
		"funds_cost": funds_cost,
		"action_points_cost": action_points_cost,
		"time_cost": resolved_time_cost,
	})


## Returns the recent growth summary using serialized training history entries only.
func get_recent_growth_summary(player_id: int, limit: int = -1) -> Dictionary[String, Variant]:
	var player: Player = _roster.get_player(player_id)
	if player == null:
		return {
			"success": false,
			"error": "player_not_found",
			"entries": [],
			"total_applied_gain": 0.0,
		}
	var resolved_limit: int = limit
	if resolved_limit <= 0:
		resolved_limit = _get_recent_growth_summary_limit()
	var history_size: int = player.training_history.size()
	var start_index: int = maxi(0, history_size - resolved_limit)
	var entries: Array[Dictionary] = []
	var total_applied_gain: float = 0.0
	for history_index: int in range(start_index, history_size):
		var entry: Dictionary[String, Variant] = _to_typed_variant_dictionary(player.training_history[history_index])
		entries.append(entry)
		total_applied_gain += float(entry.get("applied_gain", 0.0))
	return {
		"success": true,
		"player_id": player.id,
		"entries": entries,
		"total_applied_gain": total_applied_gain,
	}


func _emit_match_player_state_events(match_id: String, source_tag: String, applied_player_ids: Array[int], flagged_player_ids: Array[int], review_entries: Array[Dictionary]) -> void:
	var event_bus: Node = _get_event_bus()
	if event_bus == null:
		return
	if not applied_player_ids.is_empty():
		event_bus.call("emit", "player_match_state_applied", {
			"match_id": match_id,
			"source_tag": source_tag,
			"player_ids": applied_player_ids.duplicate(),
		})
	if not review_entries.is_empty():
		event_bus.call("emit", "player_state_update_flagged", {
			"match_id": match_id,
			"source_tag": source_tag,
			"player_ids": flagged_player_ids.duplicate(),
			"review_entries": review_entries.duplicate(true),
		})


func _append_state_update_review(review_entries: Array[Dictionary], flagged_player_ids: Array[int], player_id: int, reason: String, metadata: Dictionary = {}) -> void:
	review_entries.append({
		"player_id": player_id,
		"reason": reason,
		"metadata": metadata.duplicate(true),
	})
	if player_id > 0 and not flagged_player_ids.has(player_id):
		flagged_player_ids.append(player_id)
		var player: Player = _roster.get_player(player_id)
		if player != null and not player.review_flags.has(reason):
			player.review_flags.append(reason)


func _emit_player_milestones(player: Player, milestone_events: Array[Dictionary]) -> void:
	var event_bus: Node = _get_event_bus()
	if event_bus == null:
		return
	for milestone_event: Dictionary in milestone_events:
		var payload: Dictionary[String, Variant] = _to_typed_variant_dictionary(milestone_event)
		payload["player_id"] = player.id
		payload["player_name"] = player.name
		event_bus.call("emit", "player_milestone_reached", payload)


func _find_unexpected_keys(payload: Dictionary, allowed_keys: Array[String]) -> Array[String]:
	var unexpected_keys: Array[String] = []
	for key_variant: Variant in payload.keys():
		var key: String = String(key_variant)
		if not allowed_keys.has(key):
			unexpected_keys.append(key)
	return unexpected_keys


func _is_within_multiplier_range(value: float, valid_range: Vector2) -> bool:
	return value >= valid_range.x and value <= valid_range.y


func _subscribe_to_time_events() -> void:
	var event_bus: Node = _get_event_bus()
	if event_bus == null or not event_bus.has_method("subscribe"):
		return
	event_bus.call("unsubscribe", "time_season_ended", Callable(self, "_on_time_season_ended"))
	event_bus.call("subscribe", "time_season_ended", Callable(self, "_on_time_season_ended"))


func _on_time_season_ended(_event_name: String, payload: Dictionary) -> void:
	var season_number: int = int(payload.get("season_number", 0))
	if season_number <= 0:
		return
	for player: Player in _roster.players:
		if player.last_age_advanced_season >= season_number:
			continue
		player.age += 1
		player.last_age_advanced_season = season_number


func _get_training_session_milestones() -> Array[int]:
	var balance_config: BalanceConfig = _get_balance_config()
	if balance_config == null or balance_config.player_training_session_milestones.is_empty():
		return [10, 25, 50]
	return balance_config.player_training_session_milestones


func _get_recent_growth_summary_limit() -> int:
	var balance_config: BalanceConfig = _get_balance_config()
	if balance_config == null:
		return 5
	return maxi(1, balance_config.recent_growth_summary_limit)


func _to_typed_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if not (value is Dictionary):
		return typed_dictionary
	for key_variant: Variant in value:
		typed_dictionary[String(key_variant)] = value[key_variant]
	return typed_dictionary


## Returns the default potential-cap band for one player tier.
func get_tier_potential_band(tier: String) -> Vector2i:
	var balance_config: BalanceConfig = _get_balance_config()
	if balance_config == null:
		return Vector2i.ZERO
	var config_tier_key: String = _map_tier_to_config_key(tier)
	if config_tier_key.is_empty():
		return Vector2i.ZERO
	return balance_config.player_tier_potential_caps.get(config_tier_key, Vector2i.ZERO) as Vector2i


## Returns whether the player's potential caps fit the tier band or have an explicit special source.
func validate_player_tier_band(player: Player) -> Dictionary[String, Variant]:
	var band: Vector2i = get_tier_potential_band(player.tier)
	if band == Vector2i.ZERO:
		return {
			"valid": false,
			"reason": "tier_unknown",
		}
	var out_of_band_attributes: Array[String] = []
	for attribute_name: String in ["SPD", "PWR", "TEC", "INT", "STA"]:
		var attribute_triplet: Player.AttributeTriplet = _get_attribute_triplet(player, attribute_name)
		if attribute_triplet == null:
			continue
		if attribute_triplet.potential < band.x or attribute_triplet.potential > band.y:
			out_of_band_attributes.append(attribute_name)
	if out_of_band_attributes.is_empty():
		return {
			"valid": true,
			"special_case": false,
			"out_of_band_attributes": out_of_band_attributes,
		}
	var has_valid_source: bool = not player.special_trait_source.strip_edges().is_empty()
	if not has_valid_source and not player.review_flags.has("potential_cap_out_of_tier_band"):
		player.review_flags.append("potential_cap_out_of_tier_band")
	return {
		"valid": has_valid_source,
		"special_case": has_valid_source,
		"out_of_band_attributes": out_of_band_attributes,
		"reason": "potential_cap_out_of_tier_band" if not has_valid_source else "special_case_source_present",
	}


## Returns resolved gain samples for two players under identical training inputs.
func compare_training_efficiency_gain(
	lower_efficiency_player: Player,
	higher_efficiency_player: Player,
	attribute_name: String,
	raw_growth_input: float,
	focus_match_multiplier: float,
	facility_training_multiplier: float,
	decay_factor: float,
) -> Dictionary[String, float]:
	var lower_gain: float = apply_training_gain_to_attribute(
		lower_efficiency_player,
		attribute_name,
		raw_growth_input,
		focus_match_multiplier,
		facility_training_multiplier,
		decay_factor,
	)
	var higher_gain: float = apply_training_gain_to_attribute(
		higher_efficiency_player,
		attribute_name,
		raw_growth_input,
		focus_match_multiplier,
		facility_training_multiplier,
		decay_factor,
	)
	return {
		"lower_gain": lower_gain,
		"higher_gain": higher_gain,
	}


## Returns the authoritative player save payload.
func _serialize() -> Dictionary[String, Variant]:
	return _roster.serialize()


## Restores authoritative player save payload.
func _deserialize(data: Dictionary[String, Variant]) -> void:
	_roster.deserialize(data)
