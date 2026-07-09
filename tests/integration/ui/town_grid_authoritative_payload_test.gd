extends Node

const HudScene: PackedScene = preload("res://src/ui/hud/Hud.tscn")

var _failures: Array[String] = []
var _hud: CanvasLayer = null
var _shell: Control = null


func _ready() -> void:
	_setup_hud()
	await get_tree().process_frame
	test_town_grid_mounts_in_home_shell()
	test_town_grid_shows_neutral_placeholder_when_grid_empty()
	test_town_grid_renders_occupied_cells_from_authoritative_town_building()
	test_town_grid_subscribes_to_town_grid_changed_and_refreshes()
	_teardown_hud()
	await get_tree().process_frame
	if _failures.is_empty():
		print("TOWN_GRID_AUTHORITATIVE_PAYLOAD_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("TOWN_GRID_AUTHORITATIVE_PAYLOAD_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


func test_town_grid_mounts_in_home_shell() -> void:
	EventBus.emit("screen_requested", {"screen_id": "home"})
	_expect(_shell.call("get_current_route") == "home", "home route should mount")
	var town_grid: Control = _find_control("TownGrid")
	_expect(town_grid != null and town_grid.visible, "TownGrid should be mounted and visible on Home")


func test_town_grid_shows_neutral_placeholder_when_grid_empty() -> void:
	EventBus.emit("screen_requested", {"screen_id": "home"})
	var empty_label: Label = _find_control("TownGridEmpty") as Label
	_expect(empty_label != null and empty_label.visible, "TownGrid should show neutral placeholder when grid is empty")
	var title_label: Label = _find_control("TownGridTitle") as Label
	_expect(title_label != null and title_label.visible, "TownGrid title should be visible")
	_expect(title_label.text.contains("小镇设施布局") if title_label != null else false, "TownGrid title should contain grid title text")


func test_town_grid_renders_occupied_cells_from_authoritative_town_building() -> void:
	var town_building: TownBuilding = TownBuilding.new()
	town_building.initialize_grid(5, 5)
	var facility := Facility.new(1, Facility.FacilityType.TRAINING_GROUND, 3, Facility.FacilityState.ACTIVE, 0, 0, 0)
	town_building.register_facility(facility)
	var facility2 := Facility.new(2, Facility.FacilityType.STADIUM, 2, Facility.FacilityState.CONSTRUCTING, 2, 2, 3)
	town_building.register_facility(facility2)

	var town_grid: Control = _find_control("TownGrid")
	_expect(town_grid != null, "TownGrid should exist")
	if town_grid != null and town_grid.has_method("set_town_building_for_testing"):
		town_grid.call("set_town_building_for_testing", town_building)
		await get_tree().process_frame
		await get_tree().process_frame

	# After injection, the empty placeholder should be hidden (grid has facilities)
	var empty_label: Label = _find_control("TownGridEmpty") as Label
	_expect(empty_label == null or not empty_label.visible, "TownGrid empty placeholder should be hidden when facilities exist")

	# Verify grid container exists
	var grid_container: Control = _find_control("TownGridContainer") as Control
	_expect(grid_container != null and grid_container.visible, "TownGridContainer should be visible when facilities exist")

	# Verify at least one cell shows a level label
	var trained_cell_level: Label = _find_control("CellLevel") as Label
	_expect(trained_cell_level != null, "CellLevel should exist for occupied cells")
	if trained_cell_level != null:
		_expect(trained_cell_level.visible, "CellLevel should be visible for occupied facility cell")


func test_town_grid_subscribes_to_town_grid_changed_and_refreshes() -> void:
	var town_building: TownBuilding = TownBuilding.new()
	town_building.initialize_grid(5, 5)
	var facility := Facility.new(10, Facility.FacilityType.TRAINING_GROUND, 1, Facility.FacilityState.ACTIVE, 1, 0, 0)
	town_building.register_facility(facility)

	var town_grid: Control = _find_control("TownGrid")
	_expect(town_grid != null, "TownGrid should exist before subscription test")
	if town_grid != null and town_grid.has_method("set_town_building_for_testing"):
		town_grid.call("set_town_building_for_testing", town_building)
		await get_tree().process_frame

		# Emit town_grid_changed — grid should refresh without crash
		EventBus.emit("town_grid_changed", {"action": "construction_started", "facility_id": 10, "facility_type": 0, "grid_x": 1, "grid_y": 0})
		await get_tree().process_frame

		var grid_container: Control = _find_control("TownGridContainer") as Control
		_expect(grid_container != null and grid_container.visible, "TownGridContainer should remain visible after town_grid_changed event")

	# Emit town_grid_changed with no TownBuilding set — should degrade gracefully
	var empty_grid: Control = _find_control("TownGrid")
	if empty_grid != null and empty_grid.has_method("set_town_building_for_testing"):
		empty_grid.call("set_town_building_for_testing", null)
		await get_tree().process_frame
		EventBus.emit("town_grid_changed", {"action": "demolish_completed", "facility_id": 10, "grid_x": 1, "grid_y": 0})
		await get_tree().process_frame
		var empty_label: Label = _find_control("TownGridEmpty") as Label
		_expect(empty_label != null and empty_label.visible, "TownGrid should show neutral placeholder when TownBuilding is absent after event")


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
