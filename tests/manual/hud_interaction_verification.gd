extends Node

const HUD_SCENE := preload("res://src/ui/hud/Hud.tscn")
const PASS_MARKER := "HUD_INTERACTION_VERIFICATION_PASS"
const FAIL_MARKER := "HUD_INTERACTION_VERIFICATION_FAIL"
const RESULT_HOLD_SECONDS := 60.0

var _failures: Array[String] = []
var _hud: CanvasLayer


func _ready() -> void:
	await _run_verification()
	if _failures.is_empty():
		print(PASS_MARKER)
	else:
		for failure in _failures:
			push_error("%s: %s" % [FAIL_MARKER, failure])
	await get_tree().create_timer(RESULT_HOLD_SECONDS).timeout
	get_tree().quit(0 if _failures.is_empty() else 1)


func _run_verification() -> void:
	ScreenManager.reset_to_screen("town_main")
	_hud = HUD_SCENE.instantiate()
	add_child(_hud)
	await get_tree().process_frame

	_verify_non_match_hud_contract()
	await _verify_tooltip_delay()
	await _verify_reduced_motion_toast()
	await _verify_match_flow_hides_hud()


func _verify_non_match_hud_contract() -> void:
	_verify_required_controls_exist([
		"ZoneA/DateButton",
		"ZoneA/DateButton/DateValue",
		"ZoneA/FundsGroup/FundsValue",
		"ZoneA/ActionPointsGroup/ActionPointsValue",
		"ZoneA/ActionWindowsValue",
		"ZoneA/NextMatchButton",
		"ZoneA/NextMatchButton/NextMatchValue",
		"ZoneA/MenuButton",
		"ZoneC1/RosterButton",
		"ZoneC1/MatchButton",
	])
	_verify_controls_hidden([
		"ZoneB",
		"ZoneC2",
	])
	_verify_read_only_controls_skip_tab_focus([
		"ZoneA/DateButton/DateValue",
		"ZoneA/FundsGroup/FundsValue",
		"ZoneA/ActionPointsGroup/ActionPointsValue",
		"ZoneA/ActionWindowsValue",
		"ZoneA/NextMatchButton/NextMatchValue",
	])
	_verify_buttons_are_tab_focusable([
		"ZoneA/MenuButton",
		"ZoneC1/RosterButton",
		"ZoneC1/MatchButton",
	])


func _verify_required_controls_exist(paths: Array[String]) -> void:
	for path in paths:
		var control := _node(path) as Control
		if control == null:
			_failures.append("required HUD control missing or not Control: %s" % path)


func _verify_controls_hidden(paths: Array[String]) -> void:
	for path in paths:
		var control := _node(path) as Control
		if control == null:
			_failures.append("hidden HUD control missing or not Control: %s" % path)
		elif control.visible:
			_failures.append("non-MVP HUD control is visible: %s" % path)


func _verify_read_only_controls_skip_tab_focus(paths: Array[String]) -> void:
	for path in paths:
		var control := _node(path) as Control
		if control == null:
			_failures.append("read-only HUD control missing or not Control: %s" % path)
		elif control.focus_mode == Control.FOCUS_ALL:
			_failures.append("read-only HUD control allows Tab focus: %s" % path)


func _verify_buttons_are_tab_focusable(paths: Array[String]) -> void:
	for path in paths:
		var button := _node(path) as BaseButton
		if button == null:
			_failures.append("interactive HUD button missing or not BaseButton: %s" % path)
		elif not button.disabled and button.focus_mode != Control.FOCUS_ALL:
			_failures.append("enabled HUD button is not Tab focusable: %s" % path)


func _verify_tooltip_delay() -> void:
	var tooltip := _node("OverlayLayer/TooltipNode") as Control
	var trigger := _node("ZoneA/MenuButton") as Control
	if tooltip == null or trigger == null:
		_failures.append("tooltip verification nodes missing")
		return

	EventBus.emit("tooltip_requested", {
		"text_key": "HUD_MENU_BUTTON",
		"trigger_node": String(trigger.get_path()),
	})
	await get_tree().create_timer(0.1).timeout
	if tooltip.visible:
		_failures.append("tooltip became visible before 300ms delay")

	await get_tree().create_timer(0.25).timeout
	if not tooltip.visible:
		_failures.append("tooltip did not become visible after 300ms delay")


func _verify_reduced_motion_toast() -> void:
	var toast_container := _node("OverlayLayer/ToastContainer") as Control
	if toast_container == null:
		_failures.append("toast container missing")
		return

	EventBus.emit("reduced_motion_changed", {"enabled": true})
	EventBus.emit("notification_queued", {"message": "Reduced motion toast", "level": 0})
	await get_tree().process_frame
	await get_tree().create_timer(0.06).timeout

	var vbox := toast_container.get_node_or_null("VBoxContainer")
	if vbox == null or vbox.get_child_count() == 0:
		_failures.append("reduced-motion toast was not created")
		return

	var toast := vbox.get_child(0) as Control
	if toast == null:
		_failures.append("reduced-motion toast child is not a Control")
		return
	if absf(toast.position.x) > 0.01:
		_failures.append("reduced-motion toast used horizontal slide offset")
	if toast.modulate.a < 0.99:
		_failures.append("reduced-motion toast did not complete 50ms fade-in")


func _verify_match_flow_hides_hud() -> void:
	ScreenManager.push_screen("match_pre")
	await get_tree().process_frame

	var zone_a := _node("ZoneA") as Control
	var zone_c1 := _node("ZoneC1") as Control
	var overlay_layer := _node("OverlayLayer") as CanvasLayer
	var tooltip := _node("OverlayLayer/TooltipNode") as Control
	var toast_container := _node("OverlayLayer/ToastContainer") as Control
	var toast_vbox: Node = null
	if toast_container != null:
		toast_vbox = toast_container.get_node_or_null("VBoxContainer")

	if zone_a == null or zone_a.visible:
		_failures.append("ZoneA remained visible in match flow")
	if zone_c1 == null or zone_c1.visible:
		_failures.append("ZoneC1 remained visible in match flow")
	if overlay_layer == null or overlay_layer.visible:
		_failures.append("OverlayLayer remained visible in match flow")
	if tooltip != null and tooltip.visible:
		_failures.append("tooltip remained visible in match flow")
	if toast_vbox != null and toast_vbox.get_child_count() > 0:
		_failures.append("toast remained visible in match flow")


func _node(path: String) -> Node:
	if _hud == null:
		return null
	return _hud.get_node_or_null(NodePath(path))
