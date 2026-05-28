extends Node
## Time progression authority for season and phase state.
##
## Owns the authoritative time state contract for save/UI pull reads while
## continuing to publish HUD-facing snapshots through EventBus time events.


enum TimeState {
	PLANNING,
	ACTION_RESOLUTION,
	MATCH_TRIGGER,
	MATCH_IN_PROGRESS,
	POST_MATCH_SETTLEMENT,
	STAGE_SETTLEMENT,
	SEASON_SETTLEMENT,
	OFFSEASON,
	SEASON_START,
}

const STATE_NAME_BY_VALUE: Dictionary[int, String] = {
	TimeState.PLANNING: "Planning",
	TimeState.ACTION_RESOLUTION: "Action Resolution",
	TimeState.MATCH_TRIGGER: "Match Trigger",
	TimeState.MATCH_IN_PROGRESS: "Match In Progress",
	TimeState.POST_MATCH_SETTLEMENT: "Post-Match Settlement",
	TimeState.STAGE_SETTLEMENT: "Stage Settlement",
	TimeState.SEASON_SETTLEMENT: "Season Settlement",
	TimeState.OFFSEASON: "Offseason",
	TimeState.SEASON_START: "SeasonStart",
}

const STATE_VALUE_BY_ALIAS: Dictionary[String, int] = {
	"Planning": TimeState.PLANNING,
	"planning": TimeState.PLANNING,
	"Action Resolution": TimeState.ACTION_RESOLUTION,
	"action resolution": TimeState.ACTION_RESOLUTION,
	"action_resolution": TimeState.ACTION_RESOLUTION,
	"Match Trigger": TimeState.MATCH_TRIGGER,
	"match trigger": TimeState.MATCH_TRIGGER,
	"match_trigger": TimeState.MATCH_TRIGGER,
	"Match In Progress": TimeState.MATCH_IN_PROGRESS,
	"match in progress": TimeState.MATCH_IN_PROGRESS,
	"match_in_progress": TimeState.MATCH_IN_PROGRESS,
	"Post-Match Settlement": TimeState.POST_MATCH_SETTLEMENT,
	"post-match settlement": TimeState.POST_MATCH_SETTLEMENT,
	"post_match_settlement": TimeState.POST_MATCH_SETTLEMENT,
	"Stage Settlement": TimeState.STAGE_SETTLEMENT,
	"stage settlement": TimeState.STAGE_SETTLEMENT,
	"stage_settlement": TimeState.STAGE_SETTLEMENT,
	"Season Settlement": TimeState.SEASON_SETTLEMENT,
	"season settlement": TimeState.SEASON_SETTLEMENT,
	"season_settlement": TimeState.SEASON_SETTLEMENT,
	"Offseason": TimeState.OFFSEASON,
	"offseason": TimeState.OFFSEASON,
	"SeasonStart": TimeState.SEASON_START,
	"seasonstart": TimeState.SEASON_START,
	"season_start": TimeState.SEASON_START,
}

var _season_label: String = ""
var _current_stage_display: String = ""
var _current_date_display: String = ""

var _current_timeline_position: int = 0
var _current_phase_time_budget: int = 0
var _reserved_time: int = 0
var _consumed_time: int = 0
var _standard_window_size: int = 1

var _scheduled_match_position: int = 0
var _next_key_node_position: int = 0
var _next_key_node_display: String = ""
var _next_key_node_type: String = ""
var _next_key_node_state: String = ""

var _completed_season_units: int = 0
var _total_season_units: int = 1
var _season_number: int = 1
var _current_stage: int = 1
var _current_stage_progress: int = 0
var _stage_progress_target: int = 1
var _season_progress_abnormal: bool = false
var _current_state: int = TimeState.PLANNING

var _schedule_available: bool = false
var _schedule_loading: bool = true
var _schedule_missing: bool = false
var _match_center_available: bool = false
var _opponent_name: String = ""
var _next_match_display: String = ""
var _match_in_progress: bool = false
var _match_trigger_consumed: bool = false
var _resolved_key_nodes_by_stable_state: Dictionary[String, bool] = {}
var _resolved_key_node_state_signature: String = ""
var _home_team_id: int = 0
var _away_team_id: int = 0
var _season_final_standings: Array[Dictionary] = []
var _pending_time_events: Array[Dictionary] = []
var _is_resolving_key_nodes: bool = false
var _event_bus_override: Node = null


func _ready() -> void:
	call_deferred("_publish_initial_state")


## Overrides the runtime EventBus for deterministic tests.
func set_event_bus_for_testing(event_bus: Node) -> void:
	_event_bus_override = event_bus


## Applies a full or partial authoritative time snapshot.
## Accepts either Story 001 canonical fields or the legacy HUD snapshot keys.
func apply_snapshot(snapshot: Dictionary) -> void:
	var previous_state_name: String = _get_current_state_name()
	_apply_snapshot(snapshot)
	_publish_state(previous_state_name)


## Returns whether the provided state is a verified stable restore node.
func is_stable_restore_state(state_name: String) -> bool:
	return state_name == "Planning" \
		or state_name == "Stage Settlement" \
		or state_name == "Season Settlement" \
		or state_name == "Offseason" \
		or state_name == "SeasonStart"


## Restores time state from a snapshot while rejecting half-complete runtime nodes.
func restore_from_snapshot(snapshot: Dictionary) -> Dictionary[String, Variant]:
	var normalized_snapshot: Dictionary[String, Variant] = _normalize_restore_snapshot(snapshot)
	var restored_state_name: String = _get_snapshot_state_name(normalized_snapshot)
	var previous_state_name: String = _get_current_state_name()
	_apply_snapshot(normalized_snapshot)
	_publish_state(previous_state_name)
	return {
		"success": true,
		"restored_state": _get_current_state_name(),
		"requested_state": _get_snapshot_state_name(snapshot),
		"normalized": restored_state_name != _get_snapshot_state_name(snapshot),
	}


## Advances the timeline position without guessing downstream system side effects.
## If the scheduled match threshold is crossed, transitions into Match Trigger.
func advance_timeline(units: int) -> void:
	if units <= 0:
		return
	_current_timeline_position += units
	_completed_season_units = mini(_completed_season_units + units, maxi(_total_season_units, 1))
	var match_trigger_result: Dictionary[String, Variant] = evaluate_match_trigger()
	if match_trigger_result.get("success", false) as bool:
		return
	_publish_time_advanced()


## Calculates one action's authoritative time cost.
## Returns structured success/failure semantics for downstream callers.
func calculate_action_time_cost(base_time_cost: float, time_cost_modifier: float) -> Dictionary[String, Variant]:
	if base_time_cost <= 0.0 or time_cost_modifier <= 0.0:
		return {
			"success": false,
			"action_time_cost": 0.0,
			"reason": "invalid_time_cost",
		}

	return {
		"success": true,
		"action_time_cost": base_time_cost * time_cost_modifier,
		"reason": "",
	}


## Returns whether the current phase can afford the requested action time cost.
## Failure semantics are reported without mutating authoritative time state.
func can_consume_action_time(action_time_cost: float) -> Dictionary[String, Variant]:
	if action_time_cost <= 0.0:
		return {
			"success": false,
			"reason": "invalid_time_cost",
			"remaining_time": float(maxi(_current_phase_time_budget - _reserved_time - _consumed_time, 0)),
		}

	var remaining_time: int = maxi(_current_phase_time_budget - _reserved_time - _consumed_time, 0)
	if float(remaining_time) < action_time_cost:
		return {
			"success": false,
			"reason": "insufficient_time",
			"remaining_time": float(remaining_time),
		}

	return {
		"success": true,
		"reason": "",
		"remaining_time": float(remaining_time),
	}


## Records time consumption against the current phase budget.
func consume_time(units: int) -> void:
	if units <= 0:
		return
	_consumed_time += units
	_publish_time_advanced()


## Sets currently reserved time units.
func set_reserved_time(units: int) -> void:
	_reserved_time = maxi(units, 0)
	_publish_time_advanced()


## Clears any reserved time units.
func clear_reserved_time() -> void:
	if _reserved_time == 0:
		return
	_reserved_time = 0
	_publish_time_advanced()


## Re-emits the current HUD snapshot for late UI subscribers.
func request_refresh() -> void:
	_publish_time_advanced()


## Returns the names of all supported GDD-defined time states.
func get_supported_state_names() -> Array[String]:
	return [
		"Planning",
		"Action Resolution",
		"Match Trigger",
		"Match In Progress",
		"Post-Match Settlement",
		"Stage Settlement",
		"Season Settlement",
		"Offseason",
		"SeasonStart",
	]


## Returns whether the provided state name is supported by the Story 001 model.
func has_state_name(state_name: String) -> bool:
	return STATE_VALUE_BY_ALIAS.has(state_name)


## Sets the authoritative state using a GDD-visible state name.
## Returns true when a transition occurred.
func set_state_by_name(state_name: String) -> bool:
	if not STATE_VALUE_BY_ALIAS.has(state_name):
		return false
	return set_state(STATE_VALUE_BY_ALIAS[state_name])


## Sets the authoritative state using the internal enum value.
## Returns true when a transition occurred.
func set_state(new_state: int) -> bool:
	if not STATE_NAME_BY_VALUE.has(new_state):
		return false
	if _current_state == new_state:
		return false

	var previous_state_name: String = _get_current_state_name()
	_current_state = new_state
	_match_in_progress = _current_state == TimeState.MATCH_IN_PROGRESS
	_publish_state(previous_state_name)
	return true


## Returns the Story 001 save/UI snapshot contract.
## Payload contains only serializable primitives and nested Dictionaries.
func get_state() -> Dictionary[String, Variant]:
	var state_name: String = _get_current_state_name()
	var remaining_time_to_next_key_node: int = get_remaining_time_to_next_key_node()
	var current_date_or_position: String = _current_date_display
	if current_date_or_position.is_empty():
		current_date_or_position = _current_stage_display
		if current_date_or_position.is_empty():
			current_date_or_position = str(_current_timeline_position)
	var season_progress: Dictionary[String, Variant] = {
		"completed_units": _completed_season_units,
		"total_units": _total_season_units,
		"progress_ratio": get_season_progress_ratio(),
		"abnormal_for_review": _season_progress_abnormal,
	}
	var season_position: Dictionary[String, Variant] = {
		"season_number": _season_number,
		"current_stage": _current_stage,
		"current_stage_progress": _current_stage_progress,
		"stage_progress_target": _stage_progress_target,
		"timeline_position": _current_timeline_position,
	}
	var available_action_windows: Dictionary[String, Variant] = {
		"count": get_available_action_windows(),
		"current_phase_time_budget": _current_phase_time_budget,
		"reserved_time": _reserved_time,
		"consumed_time": _consumed_time,
		"standard_window_size": _standard_window_size,
	}
	var next_key_node: Dictionary[String, Variant] = {
		"type": _next_key_node_type,
		"state": _next_key_node_state,
		"position": _next_key_node_position,
		"remaining_time": remaining_time_to_next_key_node,
		"display_name": _next_key_node_display,
	}
	var match_data: Dictionary[String, Variant] = {
		"scheduled_position": _scheduled_match_position,
		"trigger_reached": get_match_trigger_reached(),
		"center_available": _match_center_available,
		"in_progress": _match_in_progress,
		"opponent_name": _opponent_name,
		"next_match_display": _next_match_display,
		"home_team_id": _home_team_id,
		"away_team_id": _away_team_id,
	}
	return {
		"timeline_position": _current_timeline_position,
		"current_phase": state_name,
		"current_state": state_name,
		"phase": state_name,
		"state": state_name,
		"season_number": _season_number,
		"season_label": _season_label,
		"current_stage": _current_stage,
		"current_stage_progress": _current_stage_progress,
		"stage_progress_target": _stage_progress_target,
		"season_progress_abnormal": _season_progress_abnormal,
		"current_stage_display": _current_stage_display,
		"current_date_display": _current_date_display,
		"current_date_or_position": current_date_or_position,
		"remaining_time_to_next_key_node": remaining_time_to_next_key_node,
		"next_key_node_position": _next_key_node_position,
		"next_key_node_display": _next_key_node_display,
		"season_position": season_position,
		"season_progress": season_progress,
		"available_action_windows": available_action_windows,
		"next_key_node": next_key_node,
		"match": match_data,
	}


## Returns available action windows from the current state snapshot.
func get_available_action_windows() -> int:
	if _current_state == TimeState.MATCH_TRIGGER or _current_state == TimeState.MATCH_IN_PROGRESS:
		return 0
	var remaining_time: int = maxi(_current_phase_time_budget - _reserved_time - _consumed_time, 0)
	return int(floor(float(remaining_time) / float(maxi(_standard_window_size, 1))))


## Records whether a formal match is currently in progress.
## This compatibility API maps into the authoritative time state model.
func set_match_in_progress(is_in_progress: bool) -> void:
	if is_in_progress:
		_match_trigger_consumed = true
		set_state(TimeState.MATCH_IN_PROGRESS)
		return

	if _current_state == TimeState.MATCH_IN_PROGRESS:
		set_state(TimeState.POST_MATCH_SETTLEMENT)
		return

	if _match_in_progress:
		_match_in_progress = false
		_publish_time_advanced()


## Returns whether a formal match is currently in progress.
func is_match_in_progress() -> bool:
	return _match_in_progress


## Returns whether the scheduled match is now reachable.
func get_match_trigger_reached() -> bool:
	return _schedule_available and _current_timeline_position >= _scheduled_match_position and not _match_in_progress


## Returns whether the current stage progress has reached its settlement threshold.
func get_stage_settlement_trigger_reached() -> bool:
	return _current_stage_progress >= _stage_progress_target


## Returns whether the season has reached its settlement threshold.
func get_season_settlement_trigger_reached() -> bool:
	return get_season_progress_ratio() >= 1.0


## Evaluates the scheduled match node and performs the one-time Match Trigger transition.
## Returns structured trigger semantics so repeated polling remains idempotent.
func evaluate_match_trigger() -> Dictionary[String, Variant]:
	if not get_match_trigger_reached():
		return {
			"success": false,
			"triggered": false,
			"reason": "not_reached",
		}

	if _match_trigger_consumed:
		return {
			"success": false,
			"triggered": false,
			"reason": "already_triggered",
		}

	_match_trigger_consumed = true
	set_state(TimeState.MATCH_TRIGGER)
	return {
		"success": true,
		"triggered": true,
		"reason": "",
	}


## Returns whether a formal match may legally be entered now.
func can_enter_formal_match() -> bool:
	return get_match_trigger_reached() and _match_center_available


## Evaluates the current stage threshold and performs the Stage Settlement transition when reached.
func evaluate_stage_settlement_trigger() -> Dictionary[String, Variant]:
	if not get_stage_settlement_trigger_reached():
		return {
			"success": false,
			"triggered": false,
			"reason": "not_reached",
		}

	if _current_state == TimeState.STAGE_SETTLEMENT:
		return {
			"success": false,
			"triggered": false,
			"reason": "already_triggered",
		}

	set_state(TimeState.STAGE_SETTLEMENT)
	return {
		"success": true,
		"triggered": true,
		"reason": "",
	}


## Resolves the authoritative post-match chain into either stage settlement or the normal planning flow.
func resolve_post_match_settlement() -> Dictionary[String, Variant]:
	if _current_state != TimeState.POST_MATCH_SETTLEMENT:
		return {
			"success": false,
			"triggered": false,
			"reason": "invalid_state",
		}

	var stage_trigger_result: Dictionary[String, Variant] = evaluate_stage_settlement_trigger()
	if stage_trigger_result["success"] as bool:
		return {
			"success": true,
			"triggered": true,
			"reason": "",
			"next_state": _get_current_state_name(),
		}

	set_state(TimeState.PLANNING)
	return {
		"success": true,
		"triggered": false,
		"reason": "stage_not_reached",
		"next_state": _get_current_state_name(),
	}


## Enters the explicit post-match settlement state from Match Trigger.
func enter_post_match_settlement() -> Dictionary[String, Variant]:
	if _current_state != TimeState.MATCH_TRIGGER:
		return {
			"success": false,
			"reason": "invalid_state",
			"next_state": _get_current_state_name(),
		}

	set_state(TimeState.POST_MATCH_SETTLEMENT)
	return {
		"success": true,
		"reason": "",
		"next_state": _get_current_state_name(),
	}


## Evaluates the current season progress and performs the Season Settlement transition when complete.
func evaluate_season_settlement_trigger() -> Dictionary[String, Variant]:
	if not get_season_settlement_trigger_reached():
		return {
			"success": false,
			"triggered": false,
			"reason": "not_reached",
		}

	if _current_state == TimeState.SEASON_SETTLEMENT:
		return {
			"success": false,
			"triggered": false,
			"reason": "already_triggered",
		}

	set_state(TimeState.SEASON_SETTLEMENT)
	return {
		"success": true,
		"triggered": true,
		"reason": "",
	}


## Resolves the season-end flow from Season Settlement into Offseason.
func resolve_season_settlement() -> Dictionary[String, Variant]:
	if _current_state != TimeState.SEASON_SETTLEMENT:
		return {
			"success": false,
			"reason": "invalid_state",
			"next_state": _get_current_state_name(),
		}

	set_state(TimeState.OFFSEASON)
	return {
		"success": true,
		"reason": "",
		"next_state": _get_current_state_name(),
	}


## Starts a new season by resetting season-local counters and entering SeasonStart.
func start_new_season() -> Dictionary[String, Variant]:
	if _current_state != TimeState.OFFSEASON:
		return {
			"success": false,
			"reason": "invalid_state",
			"next_state": _get_current_state_name(),
		}

	_season_number += 1
	_current_timeline_position = 0
	_completed_season_units = 0
	_total_season_units = maxi(_total_season_units, 1)
	_current_stage = 1
	_current_stage_progress = 0
	_match_trigger_consumed = false
	_match_in_progress = false
	_season_progress_abnormal = false
	_season_final_standings.clear()
	set_state(TimeState.SEASON_START)
	return {
		"success": true,
		"reason": "",
		"next_state": _get_current_state_name(),
	}


## Resolves all eligible key nodes at the current stable state using the fixed time-domain priority order.
func resolve_current_key_nodes() -> Dictionary[String, Variant]:
	var processed_sequence: Array[String] = []
	var state_sequence: Array[String] = [_get_current_state_name()]
	var progressed: bool = true
	_is_resolving_key_nodes = true
	_pending_time_events.clear()

	while progressed:
		progressed = false
		_sync_resolved_key_nodes_for_current_state()

		if not _resolved_key_nodes_by_stable_state.has("match_trigger"):
			var match_trigger_result: Dictionary[String, Variant] = evaluate_match_trigger()
			if match_trigger_result["success"] as bool:
				_mark_key_node_resolved("match_trigger")
				processed_sequence.append("Match Trigger")
				state_sequence.append(_get_current_state_name())
				progressed = true
				continue

		if not _resolved_key_nodes_by_stable_state.has("post_match_settlement") and _current_state == TimeState.MATCH_TRIGGER:
			var post_match_result: Dictionary[String, Variant] = enter_post_match_settlement()
			if post_match_result["success"] as bool:
				_mark_key_node_resolved("post_match_settlement")
				processed_sequence.append("Post-Match Settlement")
				state_sequence.append(_get_current_state_name())
				progressed = true
				continue

		if not _resolved_key_nodes_by_stable_state.has("stage_settlement") and _current_state == TimeState.POST_MATCH_SETTLEMENT and get_stage_settlement_trigger_reached():
			var stage_settlement_result: Dictionary[String, Variant] = resolve_post_match_settlement()
			if stage_settlement_result["success"] as bool and stage_settlement_result["triggered"] as bool:
				_mark_key_node_resolved("stage_settlement")
				processed_sequence.append("Stage Settlement")
				state_sequence.append(_get_current_state_name())
				progressed = true
				continue

		if not _resolved_key_nodes_by_stable_state.has("season_settlement") and (_current_state == TimeState.STAGE_SETTLEMENT or _current_state == TimeState.POST_MATCH_SETTLEMENT or _current_state == TimeState.PLANNING):
			var season_settlement_result: Dictionary[String, Variant] = evaluate_season_settlement_trigger()
			if season_settlement_result["success"] as bool:
				_mark_key_node_resolved("season_settlement")
				processed_sequence.append("Season Settlement")
				state_sequence.append(_get_current_state_name())
				progressed = true
				continue

	_sync_resolved_key_nodes_for_current_state()
	_is_resolving_key_nodes = false
	_flush_pending_time_events()
	return {
		"processed_sequence": processed_sequence,
		"state_sequence": state_sequence,
		"final_state": _get_current_state_name(),
	}


## Returns normalized season progress.
func get_season_progress_ratio() -> float:
	var clamped_completed_units: int = mini(_completed_season_units, maxi(_total_season_units, 1))
	return float(clamped_completed_units) / float(maxi(_total_season_units, 1))


## Returns remaining time to the next key node.
func get_remaining_time_to_next_key_node() -> int:
	return maxi(_next_key_node_position - _current_timeline_position, 0)


## Returns the HUD-facing compatibility payload snapshot.
func get_hud_payload() -> Dictionary[String, Variant]:
	var date_display: String = _current_date_display
	if date_display.is_empty():
		date_display = _current_stage_display

	var available_action_windows: int = get_available_action_windows()
	var match_trigger_reached: bool = get_match_trigger_reached()
	var season_progress_ratio: float = get_season_progress_ratio()
	var remaining_time_to_next_key_node: int = get_remaining_time_to_next_key_node()
	var state_name: String = _get_current_state_name()

	return {
		"date_display": date_display,
		"date_text": date_display,
		"date_label": date_display,
		"current_date_display": _current_date_display,
		"current_stage": _current_stage,
		"current_stage_display": _current_stage_display,
		"phase": state_name,
		"state": state_name,
		"season_number": _season_number,
		"season_label": _season_label,
		"available_action_windows": available_action_windows,
		"action_windows_value": available_action_windows,
		"remaining_time_to_next_key_node": remaining_time_to_next_key_node,
		"next_key_node_display": _next_key_node_display,
		"next_key_node_position": _next_key_node_position,
		"season_progress_ratio": season_progress_ratio,
		"completed_season_units": _completed_season_units,
		"total_season_units": _total_season_units,
		"current_timeline_position": _current_timeline_position,
		"match_trigger_reached": match_trigger_reached,
		"schedule_available": _schedule_available,
		"schedule_loading": _schedule_loading,
		"schedule_missing": _schedule_missing,
		"match_center_available": _match_center_available,
		"match_in_progress": _match_in_progress,
		"scheduled_match_position": _scheduled_match_position,
		"opponent_name": _opponent_name,
		"next_match_display": _next_match_display,
	}


func _apply_snapshot(snapshot: Dictionary) -> void:
	if snapshot.has("season_label"):
		_season_label = String(snapshot["season_label"])
	if snapshot.has("current_stage_display"):
		_current_stage_display = String(snapshot["current_stage_display"])
	if snapshot.has("current_date_display"):
		_current_date_display = String(snapshot["current_date_display"])

	if snapshot.has("timeline_position"):
		_current_timeline_position = maxi(int(snapshot["timeline_position"]), 0)
	if snapshot.has("current_timeline_position"):
		_current_timeline_position = maxi(int(snapshot["current_timeline_position"]), 0)
	if snapshot.has("season_number"):
		_season_number = maxi(int(snapshot["season_number"]), 1)
	if snapshot.has("current_stage"):
		_current_stage = maxi(int(snapshot["current_stage"]), 1)
	if snapshot.has("current_stage_progress"):
		_current_stage_progress = maxi(int(snapshot["current_stage_progress"]), 0)
	if snapshot.has("stage_progress_target"):
		_stage_progress_target = maxi(int(snapshot["stage_progress_target"]), 1)
	if snapshot.has("scheduled_match_position"):
		_scheduled_match_position = maxi(int(snapshot["scheduled_match_position"]), 0)
	if snapshot.has("next_key_node_position"):
		_next_key_node_position = maxi(int(snapshot["next_key_node_position"]), 0)
	if snapshot.has("next_key_node_display"):
		_next_key_node_display = String(snapshot["next_key_node_display"])
	if snapshot.has("schedule_available"):
		_schedule_available = bool(snapshot["schedule_available"])
	if snapshot.has("schedule_loading"):
		_schedule_loading = bool(snapshot["schedule_loading"])
	if snapshot.has("schedule_missing"):
		_schedule_missing = bool(snapshot["schedule_missing"])
	if snapshot.has("match_center_available"):
		_match_center_available = bool(snapshot["match_center_available"])
	if snapshot.has("opponent_name"):
		_opponent_name = String(snapshot["opponent_name"])
	if snapshot.has("next_match_display"):
		_next_match_display = String(snapshot["next_match_display"])
	if snapshot.has("match_in_progress"):
		_match_in_progress = bool(snapshot["match_in_progress"])

	var season_progress: Dictionary[String, Variant] = _to_string_variant_dictionary(snapshot.get("season_progress", {}))
	if season_progress.has("completed_units"):
		_completed_season_units = maxi(int(season_progress["completed_units"]), 0)
	if season_progress.has("total_units"):
		_total_season_units = maxi(int(season_progress["total_units"]), 1)

	var available_action_windows: Dictionary[String, Variant] = _to_string_variant_dictionary(snapshot.get("available_action_windows", {}))
	if available_action_windows.has("current_phase_time_budget"):
		_current_phase_time_budget = maxi(int(available_action_windows["current_phase_time_budget"]), 0)
	if available_action_windows.has("reserved_time"):
		_reserved_time = maxi(int(available_action_windows["reserved_time"]), 0)
	if available_action_windows.has("consumed_time"):
		_consumed_time = maxi(int(available_action_windows["consumed_time"]), 0)
	if available_action_windows.has("standard_window_size"):
		_standard_window_size = maxi(int(available_action_windows["standard_window_size"]), 1)

	if snapshot.has("current_phase_time_budget"):
		_current_phase_time_budget = maxi(int(snapshot["current_phase_time_budget"]), 0)
	if snapshot.has("reserved_time"):
		_reserved_time = maxi(int(snapshot["reserved_time"]), 0)
	if snapshot.has("consumed_time"):
		_consumed_time = maxi(int(snapshot["consumed_time"]), 0)
	if snapshot.has("standard_window_size"):
		_standard_window_size = maxi(int(snapshot["standard_window_size"]), 1)

	var next_key_node: Dictionary[String, Variant] = _to_string_variant_dictionary(snapshot.get("next_key_node", {}))
	if next_key_node.has("type"):
		_next_key_node_type = String(next_key_node["type"])
	if next_key_node.has("state"):
		_next_key_node_state = String(next_key_node["state"])
	if next_key_node.has("position"):
		_next_key_node_position = maxi(int(next_key_node["position"]), 0)
	if next_key_node.has("display_name"):
		_next_key_node_display = String(next_key_node["display_name"])
	elif next_key_node.has("display"):
		_next_key_node_display = String(next_key_node["display"])

	var match_data: Dictionary[String, Variant] = _to_string_variant_dictionary(snapshot.get("match", {}))
	if match_data.has("scheduled_position"):
		_scheduled_match_position = maxi(int(match_data["scheduled_position"]), 0)
	if match_data.has("center_available"):
		_match_center_available = bool(match_data["center_available"])
	if match_data.has("in_progress"):
		_match_in_progress = bool(match_data["in_progress"])
	if match_data.has("opponent_name"):
		_opponent_name = String(match_data["opponent_name"])
	if match_data.has("next_match_display"):
		_next_match_display = String(match_data["next_match_display"])
	if match_data.has("home_team_id"):
		_home_team_id = int(match_data["home_team_id"])
	if match_data.has("away_team_id"):
		_away_team_id = int(match_data["away_team_id"])

	if snapshot.has("home_team_id"):
		_home_team_id = int(snapshot["home_team_id"])
	if snapshot.has("away_team_id"):
		_away_team_id = int(snapshot["away_team_id"])

	if snapshot.has("season_final_standings") and snapshot["season_final_standings"] is Array:
		_season_final_standings = _to_typed_dictionary_array(snapshot["season_final_standings"] as Array)

	_season_progress_abnormal = _completed_season_units > _total_season_units
	if _completed_season_units > _total_season_units:
		_completed_season_units = _total_season_units

	if snapshot.has("season_progress_abnormal"):
		_season_progress_abnormal = bool(snapshot["season_progress_abnormal"])

	var season_progress_snapshot: Dictionary[String, Variant] = _to_string_variant_dictionary(snapshot.get("season_progress", {}))
	if season_progress_snapshot.has("abnormal_for_review"):
		_season_progress_abnormal = bool(season_progress_snapshot["abnormal_for_review"])

	_apply_state_from_snapshot(snapshot)
	if _match_in_progress:
		_current_state = TimeState.MATCH_IN_PROGRESS
	_reset_resolved_key_node_tracking()
	_pending_time_events.clear()
	_is_resolving_key_nodes = false


func _apply_state_from_snapshot(snapshot: Dictionary) -> void:
	var state_name: String = ""
	if snapshot.has("current_state"):
		state_name = String(snapshot["current_state"])
	elif snapshot.has("current_phase"):
		state_name = String(snapshot["current_phase"])
	elif snapshot.has("state"):
		state_name = String(snapshot["state"])
	elif snapshot.has("phase"):
		state_name = String(snapshot["phase"])

	if state_name.is_empty():
		return
	if not STATE_VALUE_BY_ALIAS.has(state_name):
		return
	_current_state = STATE_VALUE_BY_ALIAS[state_name]


func _publish_initial_state() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_publish_time_advanced()


func _sync_resolved_key_nodes_for_current_state() -> void:
	var stable_state_signature: String = _get_key_node_stable_state_signature()
	if _resolved_key_node_state_signature == stable_state_signature:
		return
	_resolved_key_node_state_signature = stable_state_signature
	_resolved_key_nodes_by_stable_state.clear()


func _mark_key_node_resolved(key_node_name: String) -> void:
	_resolved_key_nodes_by_stable_state[key_node_name] = true
	_resolved_key_node_state_signature = _get_key_node_stable_state_signature()


func _reset_resolved_key_node_tracking() -> void:
	_resolved_key_nodes_by_stable_state.clear()
	_resolved_key_node_state_signature = ""


func _get_key_node_stable_state_signature() -> String:
	return JSON.stringify({
		"current_state": _get_current_state_name(),
		"timeline_position": _current_timeline_position,
		"current_stage_progress": _current_stage_progress,
		"stage_progress_target": _stage_progress_target,
		"completed_season_units": _completed_season_units,
		"total_season_units": _total_season_units,
		"season_number": _season_number,
		"match_trigger_consumed": _match_trigger_consumed,
		"match_in_progress": _match_in_progress,
	})


func _publish_state(previous_state_name: String) -> void:
	var current_state_name: String = _get_current_state_name()
	_match_in_progress = _current_state == TimeState.MATCH_IN_PROGRESS
	if previous_state_name != current_state_name:
		_publish_phase_changed(previous_state_name, current_state_name)
		match _current_state:
			TimeState.MATCH_TRIGGER:
				_queue_time_event("time_match_triggered", _build_match_triggered_payload())
			TimeState.STAGE_SETTLEMENT:
				_queue_time_event("time_stage_settled", _build_stage_settled_payload())
			TimeState.SEASON_SETTLEMENT:
				_queue_time_event("time_season_ended", _build_season_ended_payload())
		if not _is_resolving_key_nodes:
			_flush_pending_time_events()
	_publish_time_advanced()


func _publish_phase_changed(previous_state_name: String, current_state_name: String) -> void:
	var event_bus: Node = _event_bus()
	if event_bus != null:
		event_bus.emit("time_phase_changed", {
			"old_phase": previous_state_name,
			"new_phase": current_state_name,
			"timeline_position": _current_timeline_position,
			"season_number": _season_number,
			"current_stage": _current_stage,
		})


func _queue_time_event(event_name: String, payload: Dictionary[String, Variant]) -> void:
	_pending_time_events.append({
		"event_name": event_name,
		"payload": payload,
	})


func _flush_pending_time_events() -> void:
	if _pending_time_events.is_empty():
		return
	var event_bus: Node = _event_bus()
	if event_bus == null:
		_pending_time_events.clear()
		return
	var events_to_emit: Array[Dictionary] = _pending_time_events.duplicate(true)
	_pending_time_events.clear()
	if event_bus.has_method("emit_prioritized"):
		event_bus.call("emit_prioritized", events_to_emit)
		return
	for event: Dictionary in events_to_emit:
		event_bus.emit(String(event["event_name"]), event["payload"] as Dictionary)


func _build_match_triggered_payload() -> Dictionary[String, Variant]:
	return {
		"current_phase": _get_current_state_name(),
		"current_state": _get_current_state_name(),
		"timeline_position": _current_timeline_position,
		"scheduled_match_position": _scheduled_match_position,
		"opponent_name": _opponent_name,
		"next_match_display": _next_match_display,
		"home_team_id": _home_team_id,
		"away_team_id": _away_team_id,
		"match_context": {
			"scheduled_match_position": _scheduled_match_position,
			"opponent_name": _opponent_name,
			"next_match_display": _next_match_display,
			"home_team_id": _home_team_id,
			"away_team_id": _away_team_id,
		},
	}


func _build_stage_settled_payload() -> Dictionary[String, Variant]:
	return {
		"current_phase": _get_current_state_name(),
		"current_state": _get_current_state_name(),
		"timeline_position": _current_timeline_position,
		"current_stage": _current_stage,
		"stage_number": _current_stage,
		"stage_result": {},
	}


func _build_season_ended_payload() -> Dictionary[String, Variant]:
	return {
		"current_phase": _get_current_state_name(),
		"current_state": _get_current_state_name(),
		"timeline_position": _current_timeline_position,
		"season_number": _season_number,
		"final_standings": _season_final_standings.duplicate(true),
	}


func _publish_time_advanced() -> void:
	var event_bus: Node = _event_bus()
	if event_bus != null:
		event_bus.emit("time_advanced", get_hud_payload())


func _should_enter_match_trigger() -> bool:
	return get_match_trigger_reached() and _current_state != TimeState.MATCH_TRIGGER and _current_state != TimeState.MATCH_IN_PROGRESS


func _get_current_state_name() -> String:
	return String(STATE_NAME_BY_VALUE.get(_current_state, "Planning"))


func _event_bus() -> Node:
	if _event_bus_override != null:
		return _event_bus_override
	if not is_inside_tree():
		return null
	var tree: SceneTree = get_tree()
	if tree == null or tree.root == null:
		return null
	return get_node_or_null("/root/EventBus")


func _to_string_variant_dictionary(value: Variant) -> Dictionary[String, Variant]:
	var typed_dictionary: Dictionary[String, Variant] = {}
	if not (value is Dictionary):
		return typed_dictionary

	for key_variant: Variant in value:
		typed_dictionary[String(key_variant)] = value[key_variant]
	return typed_dictionary


func _to_typed_dictionary_array(values: Array) -> Array[Dictionary]:
	var typed_array: Array[Dictionary] = []
	for value: Variant in values:
		if value is Dictionary:
			typed_array.append(value)
	return typed_array


func _get_snapshot_state_name(snapshot: Dictionary) -> String:
	if snapshot.has("current_state"):
		return String(snapshot["current_state"])
	if snapshot.has("current_phase"):
		return String(snapshot["current_phase"])
	if snapshot.has("state"):
		return String(snapshot["state"])
	if snapshot.has("phase"):
		return String(snapshot["phase"])
	return ""


func _normalize_restore_snapshot(snapshot: Dictionary) -> Dictionary[String, Variant]:
	var normalized_snapshot: Dictionary[String, Variant] = _to_string_variant_dictionary(snapshot)
	var requested_state: String = _get_snapshot_state_name(snapshot)
	if requested_state.is_empty() or is_stable_restore_state(requested_state):
		return normalized_snapshot

	var normalized_state: String = "Planning"
	if requested_state == "Post-Match Settlement" and _is_snapshot_stage_settlement_ready(snapshot):
		normalized_state = "Stage Settlement"

	normalized_snapshot["current_state"] = normalized_state
	normalized_snapshot["current_phase"] = normalized_state
	normalized_snapshot["state"] = normalized_state
	normalized_snapshot["phase"] = normalized_state
	if normalized_state == "Planning":
		var normalized_match: Dictionary[String, Variant] = _to_string_variant_dictionary(normalized_snapshot.get("match", {}))
		normalized_match["in_progress"] = false
		normalized_snapshot["match"] = normalized_match
		normalized_snapshot["match_in_progress"] = false
	return normalized_snapshot


func _is_snapshot_stage_settlement_ready(snapshot: Dictionary) -> bool:
	var snapshot_stage_progress: int = 0
	var snapshot_stage_target: int = 1
	if snapshot.has("current_stage_progress"):
		snapshot_stage_progress = maxi(int(snapshot["current_stage_progress"]), 0)
	if snapshot.has("stage_progress_target"):
		snapshot_stage_target = maxi(int(snapshot["stage_progress_target"]), 1)
	var season_progress: Dictionary[String, Variant] = _to_string_variant_dictionary(snapshot.get("season_progress", {}))
	if season_progress.has("current_stage_progress"):
		snapshot_stage_progress = maxi(int(season_progress["current_stage_progress"]), 0)
	if season_progress.has("stage_progress_target"):
		snapshot_stage_target = maxi(int(season_progress["stage_progress_target"]), 1)
	return snapshot_stage_progress >= snapshot_stage_target
