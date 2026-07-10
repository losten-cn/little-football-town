extends Node
## Integration test for Town Overview grid stub (Story 001 / S7-03).
##
## Tests AC-1 through AC-5 using direct instantiation (component test pattern).
## TownOverviewScreen is tested standalone — production wiring deferred.
##
## Run: godot --headless --path <project> --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/town_mgmt_grid_stub_test.gd

const ScreenScript = preload("res://src/ui/town/town_overview_screen.gd")
const TownBuildingType = preload("res://src/core/town_building.gd")
const FacilityType = preload("res://src/core/facility.gd")
const TownConfigType = preload("res://src/config/town_config.gd")

var _failures: Array[String] = []
var _screen: Control = null


func _ready() -> void:
	_setup()
	await get_tree().process_frame

	# AC-1: Screen navigation (push -> verify screen_id)
	test_screen_navigation_push_sets_active_screen_id()

	# AC-2: 25 grid cells exist
	test_grid_has_25_cells()

	# AC-3: Mock TownBuilding data renders correctly
	test_mock_town_building_data_renders()

	# AC-4: Economic summary displays
	test_economic_summary_displays()

	# AC-5: Back button returns to home
	test_back_button_returns_to_home()

	_teardown()
	await get_tree().process_frame

	if _failures.is_empty():
		print("TOWN_MGMT_GRID_STUB_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("TOWN_MGMT_GRID_STUB_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


## AC-1: push_screen("town_overview") -> get_active_screen_id() == "town_overview".
## Also verifies pop_screen returns to "home".
func test_screen_navigation_push_sets_active_screen_id() -> void:
	ScreenManager.push_screen("town_overview")
	_expect(ScreenManager.get_active_screen_id() == "town_overview",
		"ScreenManager.get_active_screen_id() should return 'town_overview' after push")
	_expect(ScreenManager.get_screen_stack_depth() >= 2,
		"ScreenManager stack depth should be >= 2 after push (home + town_overview)")

	ScreenManager.pop_screen()
	_expect(ScreenManager.get_active_screen_id() == "home",
		"ScreenManager.get_active_screen_id() should return 'home' after pop")
	_expect(ScreenManager.get_screen_stack_depth() == 1,
		"ScreenManager stack depth should be 1 after popping town_overview")


## AC-2: The grid container must have exactly 25 cells.
func test_grid_has_25_cells() -> void:
	_ensure_screen_instantiated()

	var grid: GridContainer = _find_node_by_name(_screen, "TownOverviewGrid") as GridContainer
	_expect(grid != null, "TownOverviewGrid GridContainer should exist")
	if grid == null:
		return
	var cell_count: int = grid.get_child_count()
	_expect(cell_count == 25,
		"TownOverviewGrid should have 25 cells, got %d" % cell_count)

	# Verify each cell exists and is clickable (has gui_input connected)
	for i: int in range(cell_count):
		var cell: PanelContainer = grid.get_child(i) as PanelContainer
		_expect(cell != null, "Cell %d should be a PanelContainer" % i)
		if cell != null:
			_expect(cell.mouse_filter == Control.MOUSE_FILTER_STOP,
				"Cell %d should have MOUSE_FILTER_STOP (clickable)" % i)


## AC-3: Mock TownBuilding data renders facility name, level, and status in grid cells.
func test_mock_town_building_data_renders() -> void:
	_ensure_screen_instantiated()

	# Build a TownBuilding with known facilities at specific grid positions.
	# Pass a TownConfig override to avoid requiring the ConfigLoader autoload
	# in headless component tests.
	var town_config: TownConfigType = TownConfigType.new()
	var town_building: TownBuildingType = TownBuildingType.new(town_config, null)
	town_building.initialize_grid(5, 5)

	# Training Ground at (0,0) — Lv.3 ACTIVE
	var facility1 := FacilityType.new(1, FacilityType.FacilityType.TRAINING_GROUND, 3, FacilityType.FacilityState.ACTIVE, 0, 0, 0)
	town_building.register_facility(facility1)

	# Stadium at (2,2) — CONSTRUCTING
	var facility2 := FacilityType.new(2, FacilityType.FacilityType.STADIUM, 0, FacilityType.FacilityState.CONSTRUCTING, 2, 2, 5)
	town_building.register_facility(facility2)

	# Medical Room at (4,4) — Lv.1 UPGRADING
	var facility3 := FacilityType.new(3, FacilityType.FacilityType.MEDICAL_ROOM, 1, FacilityType.FacilityState.UPGRADING, 4, 4, 3)
	town_building.register_facility(facility3)

	_screen.call("set_town_building_for_testing", town_building)
	await get_tree().process_frame
	await get_tree().process_frame

	# Verify empty placeholder is hidden (grid has facilities)
	var empty_label: Label = _find_node_by_name(_screen, "TownOverviewEmpty") as Label
	_expect(empty_label == null or not empty_label.visible,
		"TownOverviewEmpty should be hidden when facilities exist")

	# Check cell (0,0) — training ground Lv.3 ACTIVE
	var cell_00_box: VBoxContainer = _get_cell_content_box_at(0, 0)
	if cell_00_box != null:
		var name_label: Label = _find_child_of_type(cell_00_box, "CellName", Label)
		_expect(name_label != null, "Occupied cell (0,0) should have CellName label")
		if name_label != null:
			_expect(name_label.text.contains("训练") or name_label.text.contains("TRAINING"),
				"Cell (0,0) name should contain training ground text, got: %s" % name_label.text)

		var level_label: Label = _find_child_of_type(cell_00_box, "CellLevel", Label)
		_expect(level_label != null, "Occupied cell (0,0) should have CellLevel label")
		if level_label != null:
			_expect(level_label.text.contains("3"),
				"Cell (0,0) level should show 3, got: %s" % level_label.text)

		var status_label: Label = _find_child_of_type(cell_00_box, "CellStatus", Label)
		_expect(status_label != null, "Occupied cell (0,0) should have CellStatus label")
		if status_label != null:
			_expect(status_label.text.contains("运行") or status_label.text.contains("ACTIVE"),
				"Cell (0,0) status should show ACTIVE, got: %s" % status_label.text)

	# Check cell (2,2) — stadium CONSTRUCTING
	var cell_22_box: VBoxContainer = _get_cell_content_box_at(2, 2)
	if cell_22_box != null:
		var status_label: Label = _find_child_of_type(cell_22_box, "CellStatus", Label)
		if status_label != null:
			_expect(status_label.text.contains("施工") or status_label.text.contains("CONSTRUCTING"),
				"Cell (2,2) status should show CONSTRUCTING, got: %s" % status_label.text)

	# Check cell (4,4) — medical room UPGRADING
	var cell_44_box: VBoxContainer = _get_cell_content_box_at(4, 4)
	if cell_44_box != null:
		var status_label: Label = _find_child_of_type(cell_44_box, "CellStatus", Label)
		if status_label != null:
			_expect(status_label.text.contains("升级") or status_label.text.contains("UPGRADING"),
				"Cell (4,4) status should show UPGRADING, got: %s" % status_label.text)

	# Check that each occupied cell has a WarmPalette color placeholder (ColorRect)
	for pos in [[0, 0], [2, 2], [4, 4]]:
		var box: VBoxContainer = _get_cell_content_box_at(pos[0] as int, pos[1] as int)
		if box != null:
			var color_rect: ColorRect = _find_child_of_type(box, "CellColorPlaceholder", ColorRect)
			_expect(color_rect != null,
				"Occupied cell (%d,%d) should have CellColorPlaceholder ColorRect" % [pos[0], pos[1]])

	# Verify empty cells show the neutral "."
	for pos in [[1, 0], [3, 3]]:
		var box: VBoxContainer = _get_cell_content_box_at(pos[0] as int, pos[1] as int)
		if box != null:
			var icon: Label = _find_child_of_type(box, "CellIcon", Label)
			_expect(icon != null and icon.text == ".",
				"Empty cell (%d,%d) should show '.' placeholder" % [pos[0], pos[1]])


## AC-4: Economic summary displays funds and daily maintenance.
func test_economic_summary_displays() -> void:
	_ensure_screen_instantiated()

	# Verify the economic summary label exists and is visible
	var summary_label: Label = _find_node_by_name(_screen, "TownOverviewEconomicSummary") as Label
	_expect(summary_label != null, "TownOverviewEconomicSummary label should exist")
	_expect(summary_label != null and summary_label.visible, "TownOverviewEconomicSummary label should be visible")

	# With no TownBuilding injected, it should show "--" placeholders
	if summary_label != null:
		_expect(summary_label.text.contains("经费") or summary_label.text.contains("funds"),
			"Economic summary should mention funds, got: %s" % summary_label.text)
		_expect(summary_label.text.contains("维护") or summary_label.text.contains("maintenance"),
			"Economic summary should mention maintenance, got: %s" % summary_label.text)

	# Inject TownBuilding with facilities to get real maintenance numbers
	var town_config: TownConfigType = TownConfigType.new()
	var town_building: TownBuildingType = TownBuildingType.new(town_config, null)
	town_building.initialize_grid(5, 5)

	# Create a Lv.2 ACTIVE training ground to generate non-zero maintenance
	var facility := FacilityType.new(10, FacilityType.FacilityType.TRAINING_GROUND, 2, FacilityType.FacilityState.ACTIVE, 0, 0, 0)
	town_building.register_facility(facility)

	_screen.call("set_town_building_for_testing", town_building)
	await get_tree().process_frame
	await get_tree().process_frame

	var updated_label: Label = _find_node_by_name(_screen, "TownOverviewEconomicSummary") as Label
	if updated_label != null:
		_expect(not updated_label.text.contains("--"),
			"Economic summary should not show '--' after TownBuilding injection, got: %s" % updated_label.text)


## AC-5: Back button presses -> ScreenManager.pop_screen() -> returns to home.
func test_back_button_returns_to_home() -> void:
	_ensure_screen_instantiated()

	# Set up ScreenManager state: push town_overview
	ScreenManager.reset_to_screen("home")
	ScreenManager.push_screen("town_overview")
	_expect(ScreenManager.get_active_screen_id() == "town_overview",
		"Active screen should be 'town_overview' before back button test")

	var back_button: Button = _find_node_by_name(_screen, "TownOverviewBackButton") as Button
	_expect(back_button != null, "TownOverviewBackButton should exist")

	if back_button != null:
		_expect(back_button.visible, "Back button should be visible")
		_expect(not back_button.disabled, "Back button should not be disabled")
		back_button.pressed.emit()
		_expect(ScreenManager.get_active_screen_id() == "home",
			"After back button press, active screen should be 'home', got: %s" % ScreenManager.get_active_screen_id())


# --- Helpers ---

func _setup() -> void:
	EventBus.clear_all()
	ScreenManager.reset_to_screen("home")


func _teardown() -> void:
	if _screen != null:
		_screen.queue_free()
		_screen = null
	EventBus.clear_all()
	ScreenManager.reset_to_screen("home")


func _ensure_screen_instantiated() -> void:
	if _screen != null:
		return
	_screen = ScreenScript.new() as Control
	add_child(_screen)
	await get_tree().process_frame
	await get_tree().process_frame


func _get_cell_content_box_at(grid_x: int, grid_y: int) -> VBoxContainer:
	if _screen == null:
		return null
	var grid: GridContainer = _find_node_by_name(_screen, "TownOverviewGrid") as GridContainer
	if grid == null:
		return null
	var cell_index: int = grid_y * 5 + grid_x
	if cell_index < 0 or cell_index >= grid.get_child_count():
		return null
	var cell: PanelContainer = grid.get_child(cell_index) as PanelContainer
	if cell == null:
		return null
	var margin: MarginContainer = cell.get_child(0) as MarginContainer
	if margin == null:
		return null
	return margin.get_child(0) as VBoxContainer


func _find_child_of_type(parent: Node, child_name: String, child_type) -> Variant:
	if parent == null:
		return null
	for child: Node in parent.get_children():
		if child.name == child_name and is_instance_of(child, child_type):
			return child
	return null


func _find_node_by_name(root: Node, node_name: String) -> Node:
	if root == null:
		return null
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
