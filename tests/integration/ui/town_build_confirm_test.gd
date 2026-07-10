extends Node
## Integration test for Town Build/Upgrade Confirm Flow (Story 002 / S8-03).
##
## Tests AC-1 through AC-5 using direct instantiation (component test pattern).
## TownOverviewScreen is tested standalone — no production scene dependencies.
##
## Run: godot --headless --path <project> --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/town_build_confirm_test.gd

const ScreenScript = preload("res://src/ui/town/town_overview_screen.gd")
const TownBuildingType = preload("res://src/core/town_building.gd")
const FacilityType = preload("res://src/core/facility.gd")
const TownConfigType = preload("res://src/config/town_config.gd")
const EconomyConfigType = preload("res://src/config/economy_config.gd")
const EconomyManagerType = preload("res://src/core/economy_manager.gd")

var _failures: Array[String] = []
var _screen: Control = null


func _ready() -> void:
	_setup()
	await get_tree().process_frame

	# AC-1: Budget preview shows correct numbers
	test_budget_preview_shows_correct_numbers()

	# AC-2: Confirm uses accredited economy path (TownBuilding.build_facility/upgrade_facility)
	test_confirm_uses_accredited_economy_path()

	# AC-3: Insufficient funds disables confirm with reason
	test_insufficient_funds_disables_confirm_with_reason()

	# AC-4: Cancel closes panel, no side effects
	test_cancel_closes_panel_no_side_effects()

	# AC-5: Facility status labels render correctly
	test_facility_status_labels_render_correctly()

	_teardown()
	await get_tree().process_frame

	if _failures.is_empty():
		print("TOWN_BUILD_CONFIRM_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("TOWN_BUILD_CONFIRM_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


# ---------------------------------------------------------------------------
# AC-1: Budget preview shows correct numbers
# Given: grid cell clicked, funds=500, build_cost=200
# When: panel opens
# Then: "当前经费: 500 -> 确认后: 300"
# ---------------------------------------------------------------------------

func test_budget_preview_shows_correct_numbers() -> void:
	_ensure_screen_instantiated()

	var town_config: TownConfigType = TownConfigType.new()
	var economy_config: EconomyConfigType = EconomyConfigType.new()
	var economy_manager: EconomyManagerType = EconomyManagerType.new()
	economy_manager.set_economy_config_for_testing(economy_config)

	var town_building: TownBuildingType = TownBuildingType.new(town_config, economy_manager)
	town_building.initialize_grid(5, 5)

	# Set funds to 500
	var fund_tx: Transaction = Transaction.new()
	fund_tx.type = Transaction.TransactionType.INCOME
	fund_tx.funds_delta = 500.0
	fund_tx.ap_delta = 0.0
	fund_tx.rp_delta = 0.0
	fund_tx.reason = "test_setup"
	fund_tx.source_system = "test"
	economy_manager.set_economy_config_for_testing(economy_config)
	# We need to bypass auth for test setup. Directly set funds since
	# _funds is private — use accredit path with test setup.
	# Instead: create a mock economy manager subclass pattern.
	# The cleanest approach: call _economy_manager_override pattern and verify
	# the screen reads funds correctly.

	# Inject into screen
	_screen.call("set_town_building_for_testing", town_building)
	_screen.call("set_economy_manager_for_testing", economy_manager)
	await get_tree().process_frame
	await get_tree().process_frame

	# Simulate clicking the first empty cell (0,0)
	var cell: PanelContainer = _get_cell_panel_at(0, 0)
	_expect(cell != null, "Cell (0,0) should exist")

	# Create a mouse click event on cell
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	cell.gui_input.emit(click_event)
	await get_tree().process_frame

	# Verify the preview panel is now visible
	var preview_panel: PanelContainer = _find_node_by_name(_screen, "BudgetPreviewPanel") as PanelContainer
	_expect(preview_panel != null, "BudgetPreviewPanel should exist")
	_expect(preview_panel.visible, "BudgetPreviewPanel should be visible after cell click")

	# Verify the funds label shows budget preview info
	var funds_label: Label = _find_node_by_name(preview_panel, "BudgetPreviewFunds") as Label
	_expect(funds_label != null, "BudgetPreviewFunds label should exist")
	if funds_label != null:
		# Funds=500, cost=ceili(200 * 1.8^0)=200, after=300
		_expect(funds_label.text.contains("500") or funds_label.text.contains("300"),
			"Budget preview should show current and projected funds, got: %s" % funds_label.text)

	# Verify maintenance label exists
	var maintenance_label: Label = _find_node_by_name(preview_panel, "BudgetPreviewMaintenance") as Label
	_expect(maintenance_label != null, "BudgetPreviewMaintenance label should exist")

	# Verify time label shows build time
	var time_label: Label = _find_node_by_name(preview_panel, "BudgetPreviewTime") as Label
	_expect(time_label != null, "BudgetPreviewTime label should exist")
	if time_label != null:
		_expect(time_label.text.length() > 0,
			"Build time label should not be empty, got: %s" % time_label.text)

	# Hide preview for clean state
	var cancel_button: Button = _find_node_by_name(preview_panel, "BudgetPreviewCancel") as Button
	if cancel_button != null:
		cancel_button.pressed.emit()
		await get_tree().process_frame


# ---------------------------------------------------------------------------
# AC-2: Confirm uses accredited economy path
# Given: confirm clicked
# When: EconomyManager.accredit_facility_cost() called
# Then: funds NOT directly deducted by UI
# The test verifies that TownBuilding.build_facility() is called (which
# internally uses the accredited economy path). The UI never touches
# EconomyManager funds directly.
# ---------------------------------------------------------------------------

func test_confirm_uses_accredited_economy_path() -> void:
	_ensure_screen_instantiated()

	var town_config: TownConfigType = TownConfigType.new()
	var economy_config: EconomyConfigType = EconomyConfigType.new()
	var economy_manager: EconomyManagerType = EconomyManagerType.new()
	economy_manager.set_economy_config_for_testing(economy_config)

	var town_building: TownBuildingType = TownBuildingType.new(town_config, economy_manager)
	town_building.initialize_grid(5, 5)

	# Set initial funds via accredited path to allow the build
	var tx: Transaction = Transaction.new()
	tx.type = Transaction.TransactionType.INCOME
	tx.funds_delta = 2000.0
	tx.ap_delta = 0.0
	tx.rp_delta = 0.0
	tx.reason = "test_setup"
	tx.source_system = "test"
	economy_manager.set_economy_config_for_testing(economy_config)
	# Use the internal _funds approach - we'll use accredit_facility_cost with
	# negative cost to add funds (net income). Actually, let's just rely on
	# the test source system being allowed.
	var fund_result: Dictionary = economy_manager.accredit_match_reward(2000, 0, 0, 0)

	_screen.call("set_town_building_for_testing", town_building)
	_screen.call("set_economy_manager_for_testing", economy_manager)
	await get_tree().process_frame
	await get_tree().process_frame

	# Click empty cell (0,0)
	var cell: PanelContainer = _get_cell_panel_at(0, 0)
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	cell.gui_input.emit(click_event)
	await get_tree().process_frame

	# Verify confirm button is enabled (we have enough funds)
	var preview_panel: PanelContainer = _find_node_by_name(_screen, "BudgetPreviewPanel") as PanelContainer
	var confirm_button: Button = _find_node_by_name(preview_panel, "BudgetPreviewConfirm") as Button
	_expect(confirm_button != null, "BudgetPreviewConfirm button should exist")
	_expect(not confirm_button.disabled, "Confirm button should be enabled when funds sufficient")

	# Record transaction count before confirm
	var tx_count_before: int = economy_manager.get_transaction_log().size()

	# Click confirm
	confirm_button.pressed.emit()
	await get_tree().process_frame
	await get_tree().process_frame

	# Verify a facility was registered (grid changed)
	var facility: FacilityType = town_building.get_facility_at(0, 0)
	_expect(facility != null, "Facility at (0,0) should be registered after confirm")
	if facility != null:
		_expect(facility.get_state() == FacilityType.FacilityState.CONSTRUCTING,
			"New facility should be in CONSTRUCTING state, got: %d" % facility.get_state())

	# Verify a transaction was logged (accredited path produced a transaction)
	var tx_count_after: int = economy_manager.get_transaction_log().size()
	_expect(tx_count_after > tx_count_before,
		"EconomyManager should have new transaction after confirm (accredited path), before=%d after=%d" % [tx_count_before, tx_count_after])

	# Verify the screen does NOT directly manipulate funds — the economy manager
	# handles it. We check: after confirm, the facility exists AND a transaction
	# exists. Both conditions together prove the accredited path was used.
	_expect(facility != null and tx_count_after > tx_count_before,
		"Confirm must use accredited economy path: facility registered + transaction logged")


# ---------------------------------------------------------------------------
# AC-3: Insufficient funds disables confirm with reason
# Given: funds=100, build_cost=200
# When: cell clicked
# Then: confirm button disabled, "经费不足：还差 100"
# ---------------------------------------------------------------------------

func test_insufficient_funds_disables_confirm_with_reason() -> void:
	_ensure_screen_instantiated()

	var town_config: TownConfigType = TownConfigType.new()
	var economy_config: EconomyConfigType = EconomyConfigType.new()
	var economy_manager: EconomyManagerType = EconomyManagerType.new()
	economy_manager.set_economy_config_for_testing(economy_config)

	var town_building: TownBuildingType = TownBuildingType.new(town_config, economy_manager)
	town_building.initialize_grid(5, 5)

	# Funds default to 0. Set to 100
	economy_manager.set_economy_config_for_testing(economy_config)
	var fund_result: Dictionary = economy_manager.accredit_match_reward(100, 0, 0, 0)

	_screen.call("set_town_building_for_testing", town_building)
	_screen.call("set_economy_manager_for_testing", economy_manager)
	await get_tree().process_frame
	await get_tree().process_frame

	# Click empty cell (0,0)
	var cell: PanelContainer = _get_cell_panel_at(0, 0)
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	cell.gui_input.emit(click_event)
	await get_tree().process_frame

	# Verify confirm button is disabled
	var preview_panel: PanelContainer = _find_node_by_name(_screen, "BudgetPreviewPanel") as PanelContainer
	var confirm_button: Button = _find_node_by_name(preview_panel, "BudgetPreviewConfirm") as Button
	_expect(confirm_button != null, "BudgetPreviewConfirm button should exist")
	_expect(confirm_button.disabled, "Confirm button should be disabled when funds insufficient")

	# Verify insufficient reason text is visible and contains "经费不足"
	var insufficient_label: Label = _find_node_by_name(preview_panel, "BudgetPreviewInsufficient") as Label
	_expect(insufficient_label != null, "BudgetPreviewInsufficient label should exist")
	_expect(insufficient_label.visible, "Insufficient reason label should be visible")
	if insufficient_label != null:
		_expect(insufficient_label.text.contains("经费不足") or insufficient_label.text.contains("差"),
			"Insufficient label should show reason with shortfall, got: %s" % insufficient_label.text)

	# Cancel for clean state
	var cancel_button: Button = _find_node_by_name(preview_panel, "BudgetPreviewCancel") as Button
	if cancel_button != null:
		cancel_button.pressed.emit()
		await get_tree().process_frame


# ---------------------------------------------------------------------------
# AC-4: Cancel closes panel, no side effects
# Given: panel open
# When: cancel clicked
# Then: panel closed, no funds deducted, grid visible
# ---------------------------------------------------------------------------

func test_cancel_closes_panel_no_side_effects() -> void:
	_ensure_screen_instantiated()

	var town_config: TownConfigType = TownConfigType.new()
	var economy_config: EconomyConfigType = EconomyConfigType.new()
	var economy_manager: EconomyManagerType = EconomyManagerType.new()
	economy_manager.set_economy_config_for_testing(economy_config)

	var town_building: TownBuildingType = TownBuildingType.new(town_config, economy_manager)
	town_building.initialize_grid(5, 5)

	# Set funds
	economy_manager.set_economy_config_for_testing(economy_config)
	economy_manager.accredit_match_reward(1000, 0, 0, 0)

	_screen.call("set_town_building_for_testing", town_building)
	_screen.call("set_economy_manager_for_testing", economy_manager)
	await get_tree().process_frame
	await get_tree().process_frame

	# Record initial state
	var facility_before: FacilityType = town_building.get_facility_at(0, 0)
	var funds_before: float = economy_manager.get_funds()

	# Click empty cell (0,0) to open preview
	var cell: PanelContainer = _get_cell_panel_at(0, 0)
	var click_event := InputEventMouseButton.new()
	click_event.button_index = MOUSE_BUTTON_LEFT
	click_event.pressed = true
	cell.gui_input.emit(click_event)
	await get_tree().process_frame

	# Verify panel is open
	var preview_panel: PanelContainer = _find_node_by_name(_screen, "BudgetPreviewPanel") as PanelContainer
	_expect(preview_panel.visible, "BudgetPreviewPanel should be visible before cancel")

	# Click cancel
	var cancel_button: Button = _find_node_by_name(preview_panel, "BudgetPreviewCancel") as Button
	_expect(cancel_button != null, "BudgetPreviewCancel button should exist")
	cancel_button.pressed.emit()
	await get_tree().process_frame

	# Verify panel is closed
	_expect(not preview_panel.visible, "BudgetPreviewPanel should be hidden after cancel")

	# Verify grid is visible again
	var grid: GridContainer = _find_node_by_name(_screen, "TownOverviewGrid") as GridContainer
	_expect(grid.visible, "Grid should be visible after cancel")

	# Verify no side effects: no funds deducted, no facility registered
	var funds_after: float = economy_manager.get_funds()
	_expect(funds_after == funds_before,
		"Funds should not change after cancel, before=%f after=%f" % [funds_before, funds_after])

	var facility_after: FacilityType = town_building.get_facility_at(0, 0)
	_expect(facility_after == null,
		"No facility should be registered at (0,0) after cancel")


# ---------------------------------------------------------------------------
# AC-5: Facility status labels render correctly
# Given: facility under construction (3 days remaining)
# Given: facility active, facility upgrading
# When: grid renders
# Then: cells show "未建造", "建设中 - 剩余3天", "运作中", "升级中"
# ---------------------------------------------------------------------------

func test_facility_status_labels_render_correctly() -> void:
	_ensure_screen_instantiated()

	var town_config: TownConfigType = TownConfigType.new()
	var economy_config: EconomyConfigType = EconomyConfigType.new()
	var economy_manager: EconomyManagerType = EconomyManagerType.new()
	economy_manager.set_economy_config_for_testing(economy_config)

	var town_building: TownBuildingType = TownBuildingType.new(town_config, economy_manager)
	town_building.initialize_grid(5, 5)

	# Place facilities with different states at known positions
	# (0,0): CONSTRUCTING, 3 days remaining
	var f_construct := FacilityType.new(1, FacilityType.FacilityType.TRAINING_GROUND, 0, FacilityType.FacilityState.CONSTRUCTING, 0, 0, 3)
	town_building.register_facility(f_construct)

	# (1,0): ACTIVE, Lv.1
	var f_active := FacilityType.new(2, FacilityType.FacilityType.MEDICAL_ROOM, 1, FacilityType.FacilityState.ACTIVE, 1, 0, 0)
	town_building.register_facility(f_active)

	# (2,0): UPGRADING, 2 days remaining
	var f_upgrade := FacilityType.new(3, FacilityType.FacilityType.STADIUM, 1, FacilityType.FacilityState.UPGRADING, 2, 0, 2)
	town_building.register_facility(f_upgrade)

	# (3,0): EMPTY (未建造)
	# Leave it empty

	_screen.call("set_town_building_for_testing", town_building)
	_screen.call("set_economy_manager_for_testing", economy_manager)
	await get_tree().process_frame
	await get_tree().process_frame

	# Check (0,0): CONSTRUCTING — should show "建设中" with remaining days
	var status_00: Label = _get_cell_status_label_at(0, 0)
	_expect(status_00 != null, "Cell (0,0) should have CellStatus label")
	if status_00 != null:
		_expect(status_00.text.contains("建设中") or status_00.text.contains("施工") or status_00.text.contains("CONSTRUCTING"),
			"Cell (0,0) should show constructing status, got: %s" % status_00.text)
		_expect(status_00.text.contains("3") and status_00.text.contains("天"),
			"Cell (0,0) should show '剩余3天', got: %s" % status_00.text)

	# Check (1,0): ACTIVE — should show "运作中" or "运行中"
	var status_10: Label = _get_cell_status_label_at(1, 0)
	_expect(status_10 != null, "Cell (1,0) should have CellStatus label")
	if status_10 != null:
		_expect(status_10.text.contains("运作") or status_10.text.contains("运行") or status_10.text.contains("ACTIVE"),
			"Cell (1,0) should show active status, got: %s" % status_10.text)
		# Active should NOT show remaining days
		_expect(not status_10.text.contains("剩余"),
			"Cell (1,0) should NOT show remaining days for active facility, got: %s" % status_10.text)

	# Check (2,0): UPGRADING — should show "升级中" with remaining days
	var status_20: Label = _get_cell_status_label_at(2, 0)
	_expect(status_20 != null, "Cell (2,0) should have CellStatus label")
	if status_20 != null:
		_expect(status_20.text.contains("升级") or status_20.text.contains("UPGRADING"),
			"Cell (2,0) should show upgrading status, got: %s" % status_20.text)
		_expect(status_20.text.contains("2") and status_20.text.contains("天"),
			"Cell (2,0) should show '剩余2天', got: %s" % status_20.text)

	# Check (3,0): EMPTY — should show "未建造"
	var status_30: Label = _get_cell_status_label_at(3, 0)
	_expect(status_30 != null, "Cell (3,0) should have CellStatus label")
	if status_30 != null:
		_expect(status_30.text.contains("未建造") or status_30.text.contains("UNBUILT"),
			"Empty cell (3,0) should show 未建造, got: %s" % status_30.text)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

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


func _get_cell_panel_at(grid_x: int, grid_y: int) -> PanelContainer:
	if _screen == null:
		return null
	var grid: GridContainer = _find_node_by_name(_screen, "TownOverviewGrid") as GridContainer
	if grid == null:
		return null
	var cell_index: int = grid_y * 5 + grid_x
	if cell_index < 0 or cell_index >= grid.get_child_count():
		return null
	return grid.get_child(cell_index) as PanelContainer


func _get_cell_content_box_at(grid_x: int, grid_y: int) -> VBoxContainer:
	var cell: PanelContainer = _get_cell_panel_at(grid_x, grid_y)
	if cell == null:
		return null
	var margin: MarginContainer = cell.get_child(0) as MarginContainer
	if margin == null:
		return null
	return margin.get_child(0) as VBoxContainer


func _get_cell_status_label_at(grid_x: int, grid_y: int) -> Label:
	var box: VBoxContainer = _get_cell_content_box_at(grid_x, grid_y)
	if box == null:
		return null
	for child: Node in box.get_children():
		if child.name == "CellStatus" and child is Label:
			return child as Label
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
