extends Node
## Deterministic Story 001 match state machine.
##
## Scope: explicit state flow, legal entry gating, and safe save/restore behavior.

const MATCH_SYSTEM_NAME: String = "match"

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

var _current_state: State = State.IDLE
var _pending_context: Dictionary[String, Variant] = {}
var _transition_history: Array[String] = []


func _ready() -> void:
	if SaveManager != null and SaveManager.has_method("register_system"):
		SaveManager.register_system(
			MATCH_SYSTEM_NAME,
			Callable(self, "serialize_state"),
			Callable(self, "deserialize_state")
		)


## Starts a formal match only when the incoming context marks the node as legally reachable.
func start_formal_match(match_context: Dictionary[String, Variant]) -> bool:
	if _current_state != State.IDLE:
		return false
	if not bool(match_context.get("match_trigger_reached", false)):
		return false

	_pending_context = match_context.duplicate(true)
	_transition_history.clear()
	_set_state(State.ENTRY)
	return true


## Advances the explicit match flow by one legal step.
func advance() -> void:
	match _current_state:
		State.ENTRY:
			_set_state(State.PRE_MATCH_PREPARATION)
		State.PRE_MATCH_PREPARATION:
			_set_state(State.CONFIRMATION)
		State.CONFIRMATION:
			_set_state(State.FIRST_HALF)
		State.FIRST_HALF:
			_set_state(State.HALFTIME_ADJUSTMENT)
		State.HALFTIME_ADJUSTMENT:
			_set_state(State.SECOND_HALF)
		State.SECOND_HALF:
			_set_state(State.RESULT_REVIEW)
		State.RESULT_REVIEW:
			_set_state(State.SETTLEMENT_HANDOFF)
			_emit_match_completed()
		State.SETTLEMENT_HANDOFF:
			_reset_to_idle()
		State.IDLE:
			return


## Returns from confirmation to the editable pre-match state.
func return_to_pre_match() -> void:
	if _current_state != State.CONFIRMATION:
		return
	_set_state(State.PRE_MATCH_PREPARATION)


## Returns the current machine state enum value.
func get_state() -> int:
	return int(_current_state)


## Returns the current machine state display name.
func get_state_name() -> String:
	return _state_to_name(_current_state)


## Returns the ordered history of formal state entries.
func get_transition_history() -> Array[String]:
	return _transition_history.duplicate()


## Returns a serializable state blob safe for SaveManager.
func serialize_state() -> Dictionary[String, Variant]:
	var serialized_context: Dictionary[String, Variant] = _pending_context.duplicate(true)
	if _is_unstable_restore_state(_current_state):
		var safe_history: Array[String] = [_state_to_name(State.ENTRY)]
		return {
			"is_active": true,
			"state": int(State.ENTRY),
			"state_name": _state_to_name(State.ENTRY),
			"pending_context": serialized_context,
			"transition_history": safe_history,
			"abandoned_in_progress_state": true,
		}

	return {
		"is_active": _current_state != State.IDLE,
		"state": int(_current_state),
		"state_name": _state_to_name(_current_state),
		"pending_context": serialized_context,
		"transition_history": _transition_history.duplicate(),
		"abandoned_in_progress_state": false,
	}


## Restores a serialized state blob while forbidding restore into unstable in-progress half states.
func deserialize_state(data: Dictionary[String, Variant]) -> void:
	if not bool(data.get("is_active", false)):
		_reset_to_idle()
		return

	var pending_context_variant: Variant = data.get("pending_context", {})
	if pending_context_variant is Dictionary:
		_pending_context = (pending_context_variant as Dictionary).duplicate(true)
	else:
		_pending_context = {}

	var requested_state: State = _coerce_state(int(data.get("state", int(State.ENTRY))))
	if _is_unstable_restore_state(requested_state):
		requested_state = State.ENTRY

	_transition_history.clear()
	var transition_history_variant: Variant = data.get("transition_history", [])
	if transition_history_variant is Array:
		for state_name_variant: Variant in transition_history_variant:
			_transition_history.append(String(state_name_variant))

	var restored_state_name: String = _state_to_name(requested_state)
	if _transition_history.is_empty() or _transition_history[_transition_history.size() - 1] != restored_state_name:
		_transition_history.clear()
		_transition_history.append(restored_state_name)

	_current_state = requested_state


func _set_state(new_state: State) -> void:
	_current_state = new_state
	if new_state == State.IDLE:
		return
	_transition_history.append(_state_to_name(new_state))


func _reset_to_idle() -> void:
	_current_state = State.IDLE
	_pending_context.clear()
	_transition_history.clear()


func _emit_match_completed() -> void:
	if EventBus == null:
		return
	EventBus.emit("match_completed", {
		"state": _state_to_name(State.SETTLEMENT_HANDOFF),
		"pending_context": _pending_context.duplicate(true),
	})


func _is_unstable_restore_state(state: State) -> bool:
	return state == State.FIRST_HALF or state == State.HALFTIME_ADJUSTMENT or state == State.SECOND_HALF


func _coerce_state(value: int) -> State:
	match value:
		State.IDLE:
			return State.IDLE
		State.ENTRY:
			return State.ENTRY
		State.PRE_MATCH_PREPARATION:
			return State.PRE_MATCH_PREPARATION
		State.CONFIRMATION:
			return State.CONFIRMATION
		State.FIRST_HALF:
			return State.FIRST_HALF
		State.HALFTIME_ADJUSTMENT:
			return State.HALFTIME_ADJUSTMENT
		State.SECOND_HALF:
			return State.SECOND_HALF
		State.RESULT_REVIEW:
			return State.RESULT_REVIEW
		State.SETTLEMENT_HANDOFF:
			return State.SETTLEMENT_HANDOFF
		_:
			return State.ENTRY


func _state_to_name(state: State) -> String:
	match state:
		State.IDLE:
			return "Idle"
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
			return "Entry"
