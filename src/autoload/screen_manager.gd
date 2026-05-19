extends Node
## Manages a stack of screen IDs for L1-L4 navigation hierarchy.
## Emits events through EventBus on push/pop so the HUD can toggle zone visibility.
## Zone D (main content) rendering is the responsibility of screen scenes, not this
## manager. This manager only tracks the stack and emits navigation events.
##
## See: ADR-0001 (scene management), design/ux/hud.md section 5, Pattern #1.

## Stack of active screen IDs. Index 0 is the root (L1), last index is the top.
var _screen_stack: Array[String] = []


## Push a screen onto the navigation stack.
## Emits "screen_pushed" via EventBus with {screen_id: String, stack_depth: int}.
## The HUD hides zones when match screens are pushed.
func push_screen(screen_id: String) -> void:
	_screen_stack.push_back(screen_id)
	EventBus.emit("screen_pushed", {
		"screen_id": screen_id,
		"stack_depth": _screen_stack.size(),
	})


## Pop the top screen from the navigation stack.
## Emits "screen_popped" via EventBus with {screen_id: String, stack_depth: int}.
## Does nothing if the stack only has one screen (can't pop the root L1).
func pop_screen() -> void:
	if _screen_stack.size() <= 1:
		return
	var popped_id: String = _screen_stack.pop_back()
	EventBus.emit("screen_popped", {
		"screen_id": popped_id,
		"stack_depth": _screen_stack.size(),
	})


## Pop screens until the target screen_id is at the top.
## If target is not in the stack, pops to the root (L1).
func pop_to_screen(target_id: String) -> void:
	while _screen_stack.size() > 1 and get_active_screen_id() != target_id:
		var popped_id: String = _screen_stack.pop_back()
		EventBus.emit("screen_popped", {
			"screen_id": popped_id,
			"stack_depth": _screen_stack.size(),
		})


## Returns the screen ID at the top of the stack.
## Returns empty string if the stack is empty.
func get_active_screen_id() -> String:
	if _screen_stack.is_empty():
		return ""
	return _screen_stack[_screen_stack.size() - 1]


## Returns the current stack depth (number of screens).
func get_screen_stack_depth() -> int:
	return _screen_stack.size()


## Returns true if any match-flow screen is at the top of the stack.
## Match screens are: match_pre, match_live, match_result.
func is_match_flow_active() -> bool:
	var active_id: String = get_active_screen_id()
	return active_id in ["match_pre", "match_live", "match_result"]


## Check if a screen is currently in the stack.
func is_screen_in_stack(screen_id: String) -> bool:
	return screen_id in _screen_stack


## Clear the entire stack and set a new root screen.
## Used when transitioning between major game states (e.g., main menu → game).
func reset_to_screen(screen_id: String) -> void:
	_screen_stack.clear()
	_screen_stack.push_back(screen_id)
	EventBus.emit("screen_stack_reset", {
		"screen_id": screen_id,
	})
