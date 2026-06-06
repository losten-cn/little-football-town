extends CanvasLayer
## Root HUD script for the strict MVP layout.
##
## The HUD only owns two persistent zones plus overlays:
## - Zone A: top status bar
## - Zone C: bottom navigation
## - OverlayLayer: pause menu, toasts, tooltip, confirmation
##
## Non-MVP legacy areas such as the sidebar and ticker remain hidden.

const THEME_PATH := "res://assets/themes/hud_theme.tres"
const ZONE_A_HEIGHT := 48
const ZONE_C_HEIGHT := 56
const LEGACY_ZONE_HEIGHT := 24

const FOCUS_PATHS: Array[NodePath] = [
	^"ZoneA/DateButton",
	^"ZoneA/NextMatchButton",
	^"ZoneA/MenuButton",
	^"ZoneC1/RosterButton",
	^"ZoneC1/MatchButton",
]

@onready var _zone_a: Control = get_node_or_null("ZoneA")
@onready var _zone_b: Control = get_node_or_null("ZoneB")
@onready var _zone_c1: Control = get_node_or_null("ZoneC1")
@onready var _zone_c2: Control = get_node_or_null("ZoneC2")
@onready var _overlay_layer: CanvasLayer = get_node_or_null("OverlayLayer")
@onready var _pause_menu: Control = get_node_or_null("OverlayLayer/PauseMenu")
@onready var _toast_container: Control = get_node_or_null("OverlayLayer/ToastContainer")
@onready var _tooltip_node: Control = get_node_or_null("OverlayLayer/TooltipNode")
@onready var _confirm_dialog: Control = get_node_or_null("OverlayLayer/ConfirmationDialog")

var _match_flow_visible := false


func _ready() -> void:
	_apply_theme_resource()
	_setup_zone_anchors()
	_subscribe_events()
	set_process_unhandled_key_input(true)
	_refresh_visibility()
	_focus_first_available()


func _exit_tree() -> void:
	EventBus.unsubscribe("screen_pushed", _on_screen_changed)
	EventBus.unsubscribe("screen_popped", _on_screen_changed)
	EventBus.unsubscribe("screen_stack_reset", _on_screen_changed)
	EventBus.unsubscribe("pause_requested", _on_pause_requested)
	EventBus.unsubscribe("pause_closed", _on_pause_closed)
	EventBus.unsubscribe("focus_requested", _on_external_focus_request)


func _apply_theme_resource() -> void:
	if not ResourceLoader.exists(THEME_PATH):
		return
	var theme_resource := load(THEME_PATH)
	if not theme_resource is Theme:
		return
	for control in [_zone_a, _zone_b, _zone_c1, _zone_c2, _pause_menu, _toast_container, _tooltip_node, _confirm_dialog]:
		if control is Control:
			control.theme = theme_resource


func _setup_zone_anchors() -> void:
	if _zone_a:
		_zone_a.anchor_left = 0.0
		_zone_a.anchor_right = 1.0
		_zone_a.anchor_top = 0.0
		_zone_a.anchor_bottom = 0.0
		_zone_a.offset_top = 0
		_zone_a.offset_bottom = ZONE_A_HEIGHT

	if _zone_c1:
		_zone_c1.anchor_left = 0.0
		_zone_c1.anchor_right = 1.0
		_zone_c1.anchor_top = 1.0
		_zone_c1.anchor_bottom = 1.0
		_zone_c1.offset_top = -ZONE_C_HEIGHT
		_zone_c1.offset_bottom = 0

	if _zone_b:
		_zone_b.visible = false
		_zone_b.anchor_left = 0.0
		_zone_b.anchor_right = 0.0
		_zone_b.anchor_top = 0.0
		_zone_b.anchor_bottom = 1.0
		_zone_b.offset_left = 0
		_zone_b.offset_right = 0
		_zone_b.offset_top = ZONE_A_HEIGHT
		_zone_b.offset_bottom = -ZONE_C_HEIGHT

	if _zone_c2:
		_zone_c2.visible = false
		_zone_c2.anchor_left = 0.0
		_zone_c2.anchor_right = 1.0
		_zone_c2.anchor_top = 1.0
		_zone_c2.anchor_bottom = 1.0
		_zone_c2.offset_top = -LEGACY_ZONE_HEIGHT
		_zone_c2.offset_bottom = 0


func _subscribe_events() -> void:
	EventBus.subscribe("screen_pushed", _on_screen_changed)
	EventBus.subscribe("screen_popped", _on_screen_changed)
	EventBus.subscribe("screen_stack_reset", _on_screen_changed)
	EventBus.subscribe("pause_requested", _on_pause_requested)
	EventBus.subscribe("pause_closed", _on_pause_closed)
	EventBus.subscribe("focus_requested", _on_external_focus_request)


func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return

	if _match_flow_visible:
		return

	if _pause_menu and _pause_menu.visible:
		if event.keycode == KEY_ESCAPE:
			_handle_esc()
			get_viewport().set_input_as_handled()
		return

	if _confirm_dialog and _confirm_dialog.visible:
		if event.keycode == KEY_ESCAPE:
			_handle_esc()
			get_viewport().set_input_as_handled()
		return

	match event.keycode:
		KEY_TAB:
			if event.shift_pressed:
				_focus_previous()
			else:
				_focus_next()
			get_viewport().set_input_as_handled()
		KEY_ESCAPE:
			_handle_esc()
			get_viewport().set_input_as_handled()
		KEY_R:
			if not _is_text_input_active():
				_request_screen("roster")
				get_viewport().set_input_as_handled()
		KEY_M:
			if not _is_text_input_active():
				_request_match_shortcut()
				get_viewport().set_input_as_handled()
		KEY_F1:
			if not _is_text_input_active():
				EventBus.emit("help_requested", {})
				get_viewport().set_input_as_handled()
		KEY_F5:
			if not _is_text_input_active():
				EventBus.emit("save_requested", {"slot": 0})
				get_viewport().set_input_as_handled()
		KEY_F9:
			if not _is_text_input_active():
				EventBus.emit("load_requested", {"slot": 0})
				get_viewport().set_input_as_handled()


func _focus_next() -> void:
	var focusables := _focusable_nodes()
	if focusables.is_empty():
		return
	var current_index := _find_focus_index(focusables)
	var next_index := (current_index + 1) % focusables.size() if current_index >= 0 else 0
	focusables[next_index].grab_focus()


func _focus_previous() -> void:
	var focusables := _focusable_nodes()
	if focusables.is_empty():
		return
	var current_index := _find_focus_index(focusables)
	var next_index := (current_index - 1 + focusables.size()) % focusables.size() if current_index >= 0 else focusables.size() - 1
	focusables[next_index].grab_focus()


func _focus_first_available() -> void:
	var focusables := _focusable_nodes()
	if not focusables.is_empty():
		focusables[0].grab_focus()


func _focusable_nodes() -> Array[Control]:
	var focusables: Array[Control] = []
	for node_path in FOCUS_PATHS:
		var control := get_node_or_null(node_path)
		if control is Control and _is_focusable(control):
			focusables.push_back(control)
	return focusables


func _find_focus_index(focusables: Array[Control]) -> int:
	var focused := get_viewport().gui_get_focus_owner()
	for index in range(focusables.size()):
		if focusables[index] == focused:
			return index
	return -1


func _is_focusable(control: Control) -> bool:
	if not control.is_visible_in_tree():
		return false
	if control.focus_mode == Control.FOCUS_NONE:
		return false
	if control is BaseButton and control.disabled:
		return false
	return true


func _handle_esc() -> void:
	if _pause_menu and _pause_menu.visible:
		if _pause_menu.has_method("close_menu"):
			_pause_menu.call("close_menu")
		else:
			_pause_menu.hide()
			EventBus.emit("pause_closed", {})
		return

	if _confirm_dialog and _confirm_dialog.visible:
		_confirm_dialog.hide()
		EventBus.emit("confirm_cancelled", {})
		return

	if ScreenManager.get_screen_stack_depth() <= 1 or ScreenManager.get_active_screen_id() == "town_main":
		EventBus.emit("pause_requested", {})
		return

	ScreenManager.pop_screen()


func _request_match_shortcut() -> void:
	if _zone_c1 and _zone_c1.has_method("request_match"):
		_zone_c1.call("request_match")
		return
	if _is_match_available():
		EventBus.emit("screen_requested", {"screen_id": "match_pre"})


func _is_match_available() -> bool:
	if _zone_c1 and _zone_c1.has_method("is_match_available"):
		return _zone_c1.call("is_match_available")
	return false


func _is_text_input_active() -> bool:
	var focused := get_viewport().gui_get_focus_owner()
	return focused is LineEdit or focused is TextEdit


func _request_screen(screen_id: String) -> void:
	if screen_id.is_empty():
		return
	if ScreenManager.get_active_screen_id() == screen_id:
		return
	EventBus.emit("screen_requested", {"screen_id": screen_id})


func _on_screen_changed(_name: String, _payload: Dictionary) -> void:
	_refresh_visibility()


func _refresh_visibility() -> void:
	var in_match_flow := ScreenManager.is_match_flow_active()
	if in_match_flow and not _match_flow_visible:
		_clear_overlays_for_match_flow()
	_match_flow_visible = in_match_flow

	if _zone_a:
		_zone_a.visible = true
	if _zone_c1:
		_zone_c1.visible = true
	if _overlay_layer:
		_overlay_layer.visible = true
	if _zone_b:
		_zone_b.visible = false
	if _zone_c2:
		_zone_c2.visible = false


func _clear_overlays_for_match_flow() -> void:
	if _pause_menu and _pause_menu.visible:
		if _pause_menu.has_method("close_menu"):
			_pause_menu.call("close_menu")
		else:
			_pause_menu.hide()

	if _tooltip_node and _tooltip_node.visible:
		EventBus.emit("tooltip_dismissed", {})

	if _confirm_dialog and _confirm_dialog.visible:
		_confirm_dialog.hide()
		EventBus.emit("confirm_cancelled", {})

	if _toast_container and _toast_container.has_method("clear_toasts"):
		_toast_container.call("clear_toasts")


func _on_pause_requested(_name: String, _payload: Dictionary) -> void:
	if _pause_menu == null:
		return
	if _pause_menu.has_method("open_menu"):
		_pause_menu.call("open_menu")
	else:
		_pause_menu.show()


func _on_pause_closed(_name: String, _payload: Dictionary) -> void:
	if _pause_menu and _pause_menu.visible:
		_pause_menu.hide()
	_focus_node(^"ZoneA/MenuButton")


func _on_external_focus_request(_name: String, payload: Dictionary) -> void:
	var node_path: String = payload.get("node_path", "")
	if node_path.is_empty():
		return
	_focus_node(NodePath(node_path))


func _focus_node(node_path: NodePath) -> void:
	var control := get_node_or_null(node_path)
	if control is Control and _is_focusable(control):
		control.grab_focus()
