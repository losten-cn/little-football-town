extends Node

const HudScene: PackedScene = preload("res://src/ui/hud/Hud.tscn")

var _failures: Array[String] = []
var _hud: CanvasLayer = null
var _shell: Control = null


func _ready() -> void:
	_setup_hud()
	await get_tree().process_frame
	test_audio_manager_exists_with_default_values()
	test_setter_getter_roundtrip()
	test_settings_panel_mounts_and_toggles()
	_teardown_hud()
	await get_tree().process_frame
	if _failures.is_empty():
		print("AUDIO_SETTINGS_AUTHORITATIVE_PAYLOAD_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("AUDIO_SETTINGS_AUTHORITATIVE_PAYLOAD_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_audio_manager_exists_with_default_values() -> void:
	var audio_manager: Node = get_node_or_null("/root/AudioManager")
	_expect(audio_manager != null, "AudioManager should exist as autoload")
	if audio_manager == null:
		return
	_expect(audio_manager.has_method("build_audio_settings_payload"), "AudioManager should have build_audio_settings_payload()")
	_expect(audio_manager.has_method("set_master_volume"), "AudioManager should have set_master_volume()")
	_expect(audio_manager.has_method("set_bgm_volume"), "AudioManager should have set_bgm_volume()")
	_expect(audio_manager.has_method("set_sfx_volume"), "AudioManager should have set_sfx_volume()")

	var payload_variant: Variant = audio_manager.call("build_audio_settings_payload")
	_expect(payload_variant is Dictionary, "build_audio_settings_payload() should return a Dictionary")
	if payload_variant is Dictionary:
		var payload: Dictionary = payload_variant as Dictionary
		_expect(payload.has("audio_master_volume"), "Payload should contain audio_master_volume key")
		_expect(payload.has("audio_bgm_volume"), "Payload should contain audio_bgm_volume key")
		_expect(payload.has("audio_sfx_volume"), "Payload should contain audio_sfx_volume key")
		_expect(float(payload.get("audio_master_volume", -1.0)) == 1.0, "Default master volume should be 1.0")


func test_setter_getter_roundtrip() -> void:
	var audio_manager: Node = get_node_or_null("/root/AudioManager")
	if audio_manager == null:
		_expect(false, "AudioManager should exist")
		return
	audio_manager.call("set_master_volume", 0.5)
	audio_manager.call("set_bgm_volume", 0.3)
	audio_manager.call("set_sfx_volume", 0.7)

	var payload_variant: Variant = audio_manager.call("build_audio_settings_payload")
	if not (payload_variant is Dictionary):
		_expect(false, "build_audio_settings_payload should return Dictionary")
		return
	var payload: Dictionary = payload_variant as Dictionary
	_expect(abs(float(payload.get("audio_master_volume", -1.0)) - 0.5) < 0.001, "master volume roundtrip: 0.5")
	_expect(abs(float(payload.get("audio_bgm_volume", -1.0)) - 0.3) < 0.001, "bgm volume roundtrip: 0.3")
	_expect(abs(float(payload.get("audio_sfx_volume", -1.0)) - 0.7) < 0.001, "sfx volume roundtrip: 0.7")

	# Clamping
	audio_manager.call("set_master_volume", 2.5)
	var clamped_variant: Variant = audio_manager.call("build_audio_settings_payload")
	var clamped_payload: Dictionary = clamped_variant as Dictionary if clamped_variant is Dictionary else {}
	_expect(abs(float(clamped_payload.get("audio_master_volume", -1.0)) - 1.0) < 0.001, "Volume clamped to 1.0 max")

	audio_manager.call("set_master_volume", -0.5)
	var min_clamped_variant: Variant = audio_manager.call("build_audio_settings_payload")
	var min_clamped_payload: Dictionary = min_clamped_variant as Dictionary if min_clamped_variant is Dictionary else {}
	_expect(abs(float(min_clamped_payload.get("audio_master_volume", -1.0)) - 0.0) < 0.001, "Volume clamped to 0.0 min")

	# Reset
	audio_manager.call("set_master_volume", 1.0)
	audio_manager.call("set_bgm_volume", 1.0)
	audio_manager.call("set_sfx_volume", 1.0)


func test_settings_panel_mounts_and_toggles() -> void:
	EventBus.emit("screen_requested", {"screen_id": "home"})
	_expect(_shell.call("get_current_route") == "home", "Home route should mount")

	var settings_button: Button = _find_control("SettingsToggleButton") as Button
	_expect(settings_button != null, "Settings toggle button should exist")
	_expect(settings_button.visible, "Settings toggle button should be visible")

	var panel: Control = _find_control("AudioSettingsPanel") as Control
	_expect(panel != null, "AudioSettingsPanel should be mounted")
	if panel == null:
		return
	_expect(not panel.visible, "AudioSettingsPanel hidden by default")

	# Show
	settings_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(panel.visible, "AudioSettingsPanel visible after toggle")

	# Hide
	settings_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame
	_expect(not panel.visible, "AudioSettingsPanel hidden after second toggle")


func _setup_hud() -> void:
	EventBus.clear_all()
	ScreenManager.reset_to_screen("home")
	_hud = HudScene.instantiate() as CanvasLayer
	add_child(_hud)
	_shell = _hud.get_node("MainLoopShell") as Control


func _teardown_hud() -> void:
	if _hud != null:
		_hud.queue_free()
	EventBus.clear_all()
	ScreenManager.reset_to_screen("home")


func _find_control(control_name: String) -> Control:
	if _hud == null:
		return null
	return _find_node_by_name(_hud, control_name) as Control


func _find_node_by_name(root: Node, node_name: String) -> Node:
	if root.name == node_name:
		return root
	for child: Node in root.get_children():
		var found: Node = _find_node_by_name(child, node_name)
		if found != null:
			return found
	return null


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
