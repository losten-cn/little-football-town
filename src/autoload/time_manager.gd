extends Node
## Time progression authority for season and phase state.
##
## Emits HUD-facing snapshots derived from the time and season progression GDD.

var _season_label := ""
var _current_stage_display := ""
var _current_date_display := ""

var _current_timeline_position := 0
var _current_phase_time_budget := 0
var _reserved_time := 0
var _consumed_time := 0
var _standard_window_size := 1

var _scheduled_match_position := 0
var _next_key_node_position := 0
var _next_key_node_display := ""

var _completed_season_units := 0
var _total_season_units := 1

var _schedule_available := false
var _schedule_loading := true
var _schedule_missing := false
var _match_center_available := false
var _opponent_name := ""
var _next_match_display := ""


func _ready() -> void:
	call_deferred("_publish_initial_state")


## Applies a full or partial authoritative time snapshot.
func apply_snapshot(snapshot: Dictionary) -> void:
	_apply_snapshot(snapshot)
	_publish_state()


## Advances the timeline position without guessing other system side effects.
func advance_timeline(units: int) -> void:
	if units <= 0:
		return
	_current_timeline_position += units
	_completed_season_units = mini(_completed_season_units + units, maxi(_total_season_units, 1))
	_publish_state()


## Records time consumption against the current phase budget.
func consume_time(units: int) -> void:
	if units <= 0:
		return
	_consumed_time += units
	_publish_state()


## Sets currently reserved time units.
func set_reserved_time(units: int) -> void:
	_reserved_time = maxi(units, 0)
	_publish_state()


## Clears any reserved time units.
func clear_reserved_time() -> void:
	if _reserved_time == 0:
		return
	_reserved_time = 0
	_publish_state()


## Re-emits the current snapshot for late UI subscribers.
func request_refresh() -> void:
	_publish_state()


## Returns available action windows from the GDD formula.
func get_available_action_windows() -> int:
	var remaining_time := maxi(_current_phase_time_budget - _reserved_time - _consumed_time, 0)
	return int(floor(float(remaining_time) / float(maxi(_standard_window_size, 1))))


## Returns whether the scheduled match is now reachable.
func get_match_trigger_reached() -> bool:
	return _schedule_available and _current_timeline_position >= _scheduled_match_position


## Returns normalized season progress.
func get_season_progress_ratio() -> float:
	return float(_completed_season_units) / float(maxi(_total_season_units, 1))


## Returns remaining time to the next key node.
func get_remaining_time_to_next_key_node() -> int:
	return maxi(_next_key_node_position - _current_timeline_position, 0)


## Returns the HUD-facing payload snapshot.
func get_hud_payload() -> Dictionary:
	var date_text := _current_date_display
	if date_text.is_empty():
		date_text = _current_stage_display

	var available_action_windows := get_available_action_windows()
	var match_trigger_reached := get_match_trigger_reached()
	var season_progress_ratio := get_season_progress_ratio()
	var remaining_time_to_next_key_node := get_remaining_time_to_next_key_node()

	return {
		"date_text": date_text,
		"date_label": date_text,
		"current_date_display": _current_date_display,
		"current_stage_display": _current_stage_display,
		"season_label": _season_label,
		"available_action_windows": available_action_windows,
		"action_windows_value": available_action_windows,
		"remaining_time_to_next_key_node": remaining_time_to_next_key_node,
		"next_key_node_display": _next_key_node_display,
		"season_progress_ratio": season_progress_ratio,
		"completed_season_units": _completed_season_units,
		"total_season_units": _total_season_units,
		"current_timeline_position": _current_timeline_position,
		"match_trigger_reached": match_trigger_reached,
		"schedule_available": _schedule_available,
		"schedule_loading": _schedule_loading,
		"schedule_missing": _schedule_missing,
		"match_center_available": _match_center_available,
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

	if snapshot.has("current_timeline_position"):
		_current_timeline_position = maxi(int(snapshot["current_timeline_position"]), 0)
	if snapshot.has("current_phase_time_budget"):
		_current_phase_time_budget = maxi(int(snapshot["current_phase_time_budget"]), 0)
	if snapshot.has("reserved_time"):
		_reserved_time = maxi(int(snapshot["reserved_time"]), 0)
	if snapshot.has("consumed_time"):
		_consumed_time = maxi(int(snapshot["consumed_time"]), 0)
	if snapshot.has("standard_window_size"):
		_standard_window_size = maxi(int(snapshot["standard_window_size"]), 1)

	if snapshot.has("scheduled_match_position"):
		_scheduled_match_position = maxi(int(snapshot["scheduled_match_position"]), 0)
	if snapshot.has("next_key_node_position"):
		_next_key_node_position = maxi(int(snapshot["next_key_node_position"]), 0)
	if snapshot.has("next_key_node_display"):
		_next_key_node_display = String(snapshot["next_key_node_display"])

	if snapshot.has("completed_season_units"):
		_completed_season_units = maxi(int(snapshot["completed_season_units"]), 0)
	if snapshot.has("total_season_units"):
		_total_season_units = maxi(int(snapshot["total_season_units"]), 1)
	if _completed_season_units > _total_season_units:
		_completed_season_units = _total_season_units

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


func _publish_initial_state() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	_publish_state()


func _publish_state() -> void:
	if EventBus:
		EventBus.emit("time_advanced", get_hud_payload())
