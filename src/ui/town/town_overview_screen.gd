class_name TownOverviewScreen
extends Control
## Town Overview screen with 5x5 facility grid and build/upgrade confirm flow.
##
## Renders the authoritative TownBuilding read model as a 25-cell facility grid.
## Grid cell clicks open a budget preview panel for empty cells (build) or
## active cells (upgrade). Confirm delegates to TownBuilding.build_facility()
## / upgrade_facility(), which internally uses the accredited EconomyManager
## entry point. No direct fund deduction from UI code.
##
## See: production/epics/town-management-ui/story-001-grid-stub.md
## See: production/epics/town-management-ui/story-002-build-confirm-flow.md
## See: ADR-0008 (presentation-only rule)

const Palette := preload("res://src/ui/hud/warm_palette.gd")
const TownBuildingType = preload("res://src/core/town_building.gd")
const FacilityType = preload("res://src/core/facility.gd")
const EconomyManagerType = preload("res://src/core/economy_manager.gd")
const TownConfigType = preload("res://src/config/town_config.gd")

const GRID_COLUMNS: int = 5
const GRID_ROWS: int = 5
const CELL_TOTAL: int = GRID_COLUMNS * GRID_ROWS

## Default facility type for build on empty cells (out-of-scope: type selector).
const DEFAULT_BUILD_TYPE: int = FacilityType.FacilityType.TRAINING_GROUND

## WarmPalette 7-color cycle used for placeholder cell backgrounds.
## Rotates through colors so facility types are visually distinct.
const CELL_PALETTE_COLORS: Array[Color] = [
	Palette.FIELD_GREEN,
	Palette.CALM_BLUE,
	Palette.CLUB_RED,
	Palette.TOWN_GOLD,
	Palette.EARTH_BROWN,
	Palette.SLATE_GRAY,
	Palette.CREAM,
]

var _town_building: TownBuildingType = null
var _town_building_for_testing: TownBuildingType = null
var _economy_manager_for_testing = null

var _root_box: VBoxContainer = null
var _title_label: Label = null
var _back_button: Button = null
var _economic_summary_label: Label = null
var _grid_container: GridContainer = null
var _cell_panels: Array[PanelContainer] = []
var _empty_placeholder: Label = null

# --- Budget preview panel members ---
var _preview_panel: PanelContainer = null
var _preview_title: Label = null
var _preview_funds_label: Label = null
var _preview_maintenance_label: Label = null
var _preview_time_label: Label = null
var _preview_insufficient_label: Label = null
var _preview_confirm_button: Button = null
var _preview_cancel_button: Button = null

# State for the currently selected build/upgrade target
var _preview_grid_x: int = -1
var _preview_grid_y: int = -1
var _preview_facility = null  # null means new build; non-null means upgrade
var _preview_is_build: bool = false
var _preview_build_cost: int = 0
var _preview_build_time: int = 0
var _preview_maintenance_delta: int = 0


func _ready() -> void:
	name = "TownOverviewScreen"
	mouse_filter = Control.MOUSE_FILTER_PASS
	_setup_ui()
	_setup_preview_panel()
	_subscribe_events()
	_refresh()


func _exit_tree() -> void:
	EventBus.unsubscribe("town_grid_changed", _on_town_grid_changed)
	EventBus.unsubscribe("screen_popped", _on_screen_popped)


## Injects a test TownBuilding without relying on scene tree.
func set_town_building_for_testing(town_building: TownBuildingType) -> void:
	_town_building_for_testing = town_building
	_refresh()


## Injects a test EconomyManager for verifying accredited paths.
func set_economy_manager_for_testing(economy_manager) -> void:
	_economy_manager_for_testing = economy_manager


## Returns the current TownBuilding reference for this screen.
func _resolve_town_building() -> TownBuildingType:
	if _town_building_for_testing != null:
		return _town_building_for_testing
	return _town_building


## Returns the current EconomyManager reference for this screen.
func _resolve_economy_manager():
	if _economy_manager_for_testing != null:
		return _economy_manager_for_testing
	return get_node_or_null("/root/EconomyManager")


func _setup_ui() -> void:
	anchor_left = 0.0
	anchor_top = 0.0
	anchor_right = 1.0
	anchor_bottom = 1.0

	# Semi-transparent backdrop so it feels like an overlay screen
	var backdrop := ColorRect.new()
	backdrop.name = "TownOverviewBackdrop"
	backdrop.color = Color(0.0, 0.0, 0.0, 0.3)
	backdrop.anchor_left = 0.0
	backdrop.anchor_top = 0.0
	backdrop.anchor_right = 1.0
	backdrop.anchor_bottom = 1.0
	backdrop.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(backdrop)

	# Main panel container — centered
	var panel := PanelContainer.new()
	panel.name = "TownOverviewPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.anchor_left = 0.5
	panel.anchor_top = 0.5
	panel.anchor_right = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -320.0
	panel.offset_top = -240.0
	panel.offset_right = 320.0
	panel.offset_bottom = 240.0
	var panel_style := _panel_style()
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	var panel_margin := MarginContainer.new()
	panel_margin.add_theme_constant_override("margin_left", 16)
	panel_margin.add_theme_constant_override("margin_top", 12)
	panel_margin.add_theme_constant_override("margin_right", 16)
	panel_margin.add_theme_constant_override("margin_bottom", 12)
	panel.add_child(panel_margin)

	_root_box = VBoxContainer.new()
	_root_box.name = "TownOverviewRoot"
	_root_box.add_theme_constant_override("separation", 10)
	panel_margin.add_child(_root_box)

	# --- Top bar: Title + Back button + Economic summary ---
	var top_bar := HBoxContainer.new()
	top_bar.name = "TownOverviewTopBar"
	_root_box.add_child(top_bar)

	_title_label = Label.new()
	_title_label.name = "TownOverviewTitle"
	_title_label.text = _localized_text("TOWN_OVERVIEW_TITLE", "小镇建设")
	_title_label.add_theme_color_override("font_color", Palette.PANEL_TITLE_BAR)
	_title_label.add_theme_font_size_override("font_size", 20)
	_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_bar.add_child(_title_label)

	_back_button = Button.new()
	_back_button.name = "TownOverviewBackButton"
	_back_button.text = _localized_text("TOWN_OVERVIEW_BACK", "返回")
	_back_button.focus_mode = Control.FOCUS_ALL
	_apply_button_style(_back_button)
	_back_button.pressed.connect(_on_back_pressed)
	top_bar.add_child(_back_button)

	_economic_summary_label = Label.new()
	_economic_summary_label.name = "TownOverviewEconomicSummary"
	_economic_summary_label.text = _localized_text("TOWN_OVERVIEW_ECONOMIC_LOADING", "经费：-- | 每日维护：--")
	_economic_summary_label.add_theme_color_override("font_color", Palette.ZONE_A_TEXT)
	_economic_summary_label.add_theme_font_size_override("font_size", 13)
	_economic_summary_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root_box.add_child(_economic_summary_label)

	# --- Grid ---
	_grid_container = GridContainer.new()
	_grid_container.name = "TownOverviewGrid"
	_grid_container.columns = GRID_COLUMNS
	_grid_container.add_theme_constant_override("h_separation", 4)
	_grid_container.add_theme_constant_override("v_separation", 4)
	_root_box.add_child(_grid_container)

	for i: int in range(CELL_TOTAL):
		var cell: PanelContainer = _create_cell_panel(i)
		_grid_container.add_child(cell)
		_cell_panels.append(cell)

	_empty_placeholder = Label.new()
	_empty_placeholder.name = "TownOverviewEmpty"
	_empty_placeholder.text = _localized_text("TOWN_OVERVIEW_EMPTY", "设施网格为空")
	_empty_placeholder.add_theme_color_override("font_color", Palette.SLATE_GRAY)
	_empty_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_placeholder.visible = false
	_root_box.add_child(_empty_placeholder)


func _setup_preview_panel() -> void:
	## Build/upgrade budget preview panel — hidden by default.
	_preview_panel = PanelContainer.new()
	_preview_panel.name = "BudgetPreviewPanel"
	_preview_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_preview_panel.visible = false
	var preview_style := StyleBoxFlat.new()
	preview_style.bg_color = Palette.CREAM
	preview_style.border_color = Palette.WOOD_BORDER
	preview_style.set_border_width_all(2)
	preview_style.set_corner_radius_all(4)
	_preview_panel.add_theme_stylebox_override("panel", preview_style)

	var preview_margin := MarginContainer.new()
	preview_margin.add_theme_constant_override("margin_left", 12)
	preview_margin.add_theme_constant_override("margin_top", 10)
	preview_margin.add_theme_constant_override("margin_right", 12)
	preview_margin.add_theme_constant_override("margin_bottom", 10)
	_preview_panel.add_child(preview_margin)

	var preview_box := VBoxContainer.new()
	preview_box.name = "BudgetPreviewContent"
	preview_box.add_theme_constant_override("separation", 6)
	preview_margin.add_child(preview_box)

	# Title
	_preview_title = Label.new()
	_preview_title.name = "BudgetPreviewTitle"
	_preview_title.text = _localized_text("TOWN_BUILD_PREVIEW_TITLE", "建造确认")
	_preview_title.add_theme_color_override("font_color", Palette.PANEL_TITLE_BAR)
	_preview_title.add_theme_font_size_override("font_size", 16)
	_preview_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_box.add_child(_preview_title)

	# Funds line
	_preview_funds_label = Label.new()
	_preview_funds_label.name = "BudgetPreviewFunds"
	_preview_funds_label.add_theme_color_override("font_color", Palette.ZONE_A_TEXT)
	_preview_funds_label.add_theme_font_size_override("font_size", 13)
	_preview_funds_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	preview_box.add_child(_preview_funds_label)

	# Maintenance line
	_preview_maintenance_label = Label.new()
	_preview_maintenance_label.name = "BudgetPreviewMaintenance"
	_preview_maintenance_label.add_theme_color_override("font_color", Palette.ZONE_A_TEXT)
	_preview_maintenance_label.add_theme_font_size_override("font_size", 13)
	_preview_maintenance_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	preview_box.add_child(_preview_maintenance_label)

	# Time line
	_preview_time_label = Label.new()
	_preview_time_label.name = "BudgetPreviewTime"
	_preview_time_label.add_theme_color_override("font_color", Palette.ZONE_A_TEXT)
	_preview_time_label.add_theme_font_size_override("font_size", 13)
	_preview_time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	preview_box.add_child(_preview_time_label)

	# Insufficient funds reason
	_preview_insufficient_label = Label.new()
	_preview_insufficient_label.name = "BudgetPreviewInsufficient"
	_preview_insufficient_label.visible = false
	_preview_insufficient_label.add_theme_color_override("font_color", Palette.CLUB_RED)
	_preview_insufficient_label.add_theme_font_size_override("font_size", 12)
	_preview_insufficient_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	preview_box.add_child(_preview_insufficient_label)

	# Button row
	var button_row := HBoxContainer.new()
	button_row.name = "BudgetPreviewButtonRow"
	button_row.add_theme_constant_override("separation", 8)
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_box.add_child(button_row)

	_preview_confirm_button = Button.new()
	_preview_confirm_button.name = "BudgetPreviewConfirm"
	_preview_confirm_button.text = _localized_text("TOWN_BUILD_CONFIRM", "确认建造")
	_preview_confirm_button.focus_mode = Control.FOCUS_ALL
	_apply_confirm_button_style(_preview_confirm_button)
	_preview_confirm_button.pressed.connect(_on_preview_confirm_pressed)
	_preview_confirm_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button_row.add_child(_preview_confirm_button)

	_preview_cancel_button = Button.new()
	_preview_cancel_button.name = "BudgetPreviewCancel"
	_preview_cancel_button.text = _localized_text("TOWN_BUILD_CANCEL", "取消")
	_preview_cancel_button.focus_mode = Control.FOCUS_ALL
	_apply_button_style(_preview_cancel_button)
	_preview_cancel_button.pressed.connect(_on_preview_cancel_pressed)
	button_row.add_child(_preview_cancel_button)

	# Insert preview panel above the grid in _root_box
	# We need to place it right after _economic_summary_label and before _grid_container
	# Find the grid position in _root_box children
	var grid_index: int = _root_box.get_children().find(_grid_container)
	if grid_index >= 0:
		_root_box.add_child(_preview_panel)
		_root_box.move_child(_preview_panel, grid_index)


func _subscribe_events() -> void:
	EventBus.subscribe("town_grid_changed", _on_town_grid_changed)
	EventBus.subscribe("screen_popped", _on_screen_popped)


func _on_town_grid_changed(_event_name: String, _payload: Dictionary) -> void:
	_refresh()


func _on_screen_popped(_event_name: String, payload: Dictionary) -> void:
	var screen_id: String = str(payload.get("screen_id", ""))
	if screen_id == "town_overview":
		queue_free()


func _on_back_pressed() -> void:
	if _preview_panel.visible:
		_hide_preview_panel()
	else:
		ScreenManager.pop_screen()


func _refresh() -> void:
	# If preview panel is open, close it when grid changes
	if _preview_panel.visible:
		_hide_preview_panel()

	var town_building: TownBuildingType = _resolve_town_building()
	if town_building == null:
		_render_all_empty()
		_update_economic_summary(null)
		return

	var any_occupied: bool = false
	var grid_width: int = town_building.get_grid_width()
	var grid_height: int = town_building.get_grid_height()

	for y: int in range(GRID_ROWS):
		for x: int in range(GRID_COLUMNS):
			var cell_index: int = y * GRID_COLUMNS + x
			if cell_index >= _cell_panels.size():
				continue
			var facility = null
			if x < grid_width and y < grid_height:
				facility = town_building.get_facility_at(x, y)
			if facility != null and facility.get_state() != FacilityType.FacilityState.EMPTY:
				_render_occupied_cell(cell_index, facility, x, y)
				any_occupied = true
			else:
				_render_empty_cell(cell_index, x, y)

	_grid_container.visible = true
	_empty_placeholder.visible = not any_occupied
	_update_economic_summary(town_building)


func _update_economic_summary(town_building: TownBuildingType) -> void:
	if town_building == null:
		_economic_summary_label.text = _localized_text("TOWN_OVERVIEW_ECONOMIC_NO_DATA", "经费：-- | 每日维护：--")
		return

	# Maintenance: reads from TownBuilding authority.
	# Requires TownConfig to be resolvable (either via ConfigLoader autoload
	# in production, or via _town_config_override in tests).
	var maintenance: int = 0
	if town_building.has_method("get_daily_maintenance_cost"):
		maintenance = int(town_building.get_daily_maintenance_cost())

	# Funds: try to read from EconomyManager autoload if available
	var funds_text: String = _localized_text("TOWN_OVERVIEW_FUNDS_UNKNOWN", "--")
	var economy_manager = _resolve_economy_manager()
	if economy_manager != null and economy_manager.has_method("get_funds"):
		funds_text = str(int(economy_manager.get_funds()))

	_economic_summary_label.text = _localized_text("TOWN_OVERVIEW_ECONOMIC_FORMAT", "经费：%s | 每日维护：%d") % [funds_text, maintenance]


func _render_all_empty() -> void:
	for i: int in range(_cell_panels.size()):
		var y: int = i / GRID_COLUMNS
		var x: int = i % GRID_COLUMNS
		_render_empty_cell(i, x, y)
	_grid_container.visible = true
	_empty_placeholder.visible = true


func _render_empty_cell(cell_index: int, _grid_x: int, _grid_y: int) -> void:
	var cell: PanelContainer = _cell_panels[cell_index]
	var cell_style := _empty_cell_style()
	cell.add_theme_stylebox_override("panel", cell_style)

	var box: VBoxContainer = _get_cell_content_box(cell)
	_clear_box(box)

	# Status label: 未建造
	var status_label := Label.new()
	status_label.name = "CellStatus"
	status_label.text = _localized_text("FACILITY_STATE_UNBUILT", "未建造")
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Palette.SLATE_GRAY)
	status_label.add_theme_font_size_override("font_size", 9)
	box.add_child(status_label)

	var icon: Label = Label.new()
	icon.name = "CellIcon"
	icon.text = "."
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_color_override("font_color", Palette.SLATE_GRAY)
	icon.add_theme_font_size_override("font_size", 16)
	box.add_child(icon)


func _render_occupied_cell(cell_index: int, facility, grid_x: int, grid_y: int) -> void:
	var cell: PanelContainer = _cell_panels[cell_index]
	var cell_style := _occupied_cell_style(facility.get_state())
	cell.add_theme_stylebox_override("panel", cell_style)

	var box: VBoxContainer = _get_cell_content_box(cell)
	_clear_box(box)

	# Facility name label
	var name_label := Label.new()
	name_label.name = "CellName"
	name_label.text = _facility_type_display_name(facility.get_facility_type())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", Palette.ZONE_A_TEXT)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(name_label)

	# Level label (only for facilities with level > 0)
	if facility.get_level() > 0:
		var level_label := Label.new()
		level_label.name = "CellLevel"
		level_label.text = "Lv.%d" % facility.get_level()
		level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		level_label.add_theme_color_override("font_color", Palette.ZONE_A_TEXT)
		level_label.add_theme_font_size_override("font_size", 10)
		box.add_child(level_label)

	# Status label with remaining days for in-progress states
	var status_label := Label.new()
	status_label.name = "CellStatus"
	var state: int = facility.get_state()
	var status_text: String = _facility_state_display_name(state)
	if state == FacilityType.FacilityState.CONSTRUCTING or state == FacilityType.FacilityState.UPGRADING:
		var remaining: int = facility.get_remaining_construction_units()
		if remaining > 0:
			status_text = "%s - %s%d%s" % [
				status_text,
				_localized_text("FACILITY_STATE_REMAINING_PREFIX", "剩余"),
				remaining,
				_localized_text("FACILITY_STATE_REMAINING_UNIT", "天"),
			]
	status_label.text = status_text
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", _state_color(state))
	status_label.add_theme_font_size_override("font_size", 9)
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(status_label)

	# Colored placeholder icon using WarmPalette rotation
	var color_index: int = (grid_x + grid_y * GRID_COLUMNS) % CELL_PALETTE_COLORS.size()
	var icon_color: Color = CELL_PALETTE_COLORS[color_index]
	var icon := ColorRect.new()
	icon.name = "CellColorPlaceholder"
	icon.color = icon_color
	icon.custom_minimum_size = Vector2(0, 6)
	icon.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(icon)


# --- Grid cell click → budget preview flow ---

func _on_cell_gui_input(event: InputEvent, cell_index: int) -> void:
	if not (event is InputEventMouseButton):
		return
	if not event.pressed or event.button_index != MOUSE_BUTTON_LEFT:
		return

	var town_building: TownBuildingType = _resolve_town_building()
	if town_building == null:
		return

	var grid_x: int = cell_index % GRID_COLUMNS
	var grid_y: int = cell_index / GRID_COLUMNS

	var facility = null
	if grid_x < town_building.get_grid_width() and grid_y < town_building.get_grid_height():
		facility = town_building.get_facility_at(grid_x, grid_y)

	if facility == null or facility.get_state() == FacilityType.FacilityState.EMPTY:
		# Empty cell → show build preview
		_show_build_preview(grid_x, grid_y)
	elif facility.get_state() == FacilityType.FacilityState.ACTIVE:
		# Active facility → show upgrade preview
		if facility.get_level() < FacilityType.MAX_LEVEL:
			_show_upgrade_preview(facility, grid_x, grid_y)
		else:
			# Max level — no action available; silently ignore
			print("[TownOverview] Facility at (%d, %d) already at max level" % [grid_x, grid_y])
	else:
		# Constructing / upgrading — show status only, no action
		print("[TownOverview] Facility at (%d, %d) is %s — no action available" % [grid_x, grid_y, _facility_state_display_name(facility.get_state())])


func _show_build_preview(grid_x: int, grid_y: int) -> void:
	_preview_grid_x = grid_x
	_preview_grid_y = grid_y
	_preview_facility = null
	_preview_is_build = true

	var town_building: TownBuildingType = _resolve_town_building()
	var economy_manager = _resolve_economy_manager()
	if town_building == null or economy_manager == null:
		return

	var facility_type: int = DEFAULT_BUILD_TYPE
	var cost_result: Dictionary = town_building.compute_construction_funds_cost(facility_type, 1)
	var time_result: Dictionary = town_building.compute_construction_time_cost(facility_type, 1)
	_preview_build_cost = int(cost_result.get("value", 0))
	_preview_build_time = int(time_result.get("value", 0))

	# Maintenance delta: level-1 maintenance base for this facility type
	# Active facilities only contribute maintenance; a new facility at level 0
	# (CONSTRUCTING) contributes 0. After construction completes to level 1,
	# it will contribute. We show the eventual maintenance addition.
	var town_config: TownConfigType = _resolve_town_config(town_building)
	_preview_maintenance_delta = 0
	if town_config != null:
		_preview_maintenance_delta = town_config.get_facility_maintenance_base(facility_type)

	var current_funds: int = int(economy_manager.get_funds())
	var after_funds: int = current_funds - _preview_build_cost
	var current_maintenance: int = int(town_building.get_daily_maintenance_cost())
	var after_maintenance: int = current_maintenance + _preview_maintenance_delta
	var affordable: bool = current_funds >= _preview_build_cost

	# Title
	_preview_title.text = _localized_text("TOWN_BUILD_PREVIEW_TITLE", "建造确认")
	var type_name: String = _facility_type_display_name(facility_type)
	_preview_funds_label.text = _localized_text("TOWN_BUILD_FUNDS_LINE", "设施：%s\n当前经费：%d → 确认后：%d") % [type_name, current_funds, after_funds]
	_preview_maintenance_label.text = _localized_text("TOWN_BUILD_MAINTENANCE_LINE", "当前维护费：%d/天 → 完成后：%d/天") % [current_maintenance, after_maintenance]
	_preview_time_label.text = _localized_text("TOWN_BUILD_TIME_LINE", "建造时间：%d天") % _preview_build_time

	_preview_confirm_button.text = _localized_text("TOWN_BUILD_CONFIRM", "确认建造")
	_preview_confirm_button.disabled = not affordable
	_preview_insufficient_label.visible = not affordable
	if not affordable:
		var shortfall: int = _preview_build_cost - current_funds
		_preview_insufficient_label.text = _localized_text("TOWN_BUILD_INSUFFICIENT_FUNDS", "经费不足：还差 %d") % shortfall

	_show_preview_panel()


func _show_upgrade_preview(facility, grid_x: int, grid_y: int) -> void:
	_preview_grid_x = grid_x
	_preview_grid_y = grid_y
	_preview_facility = facility
	_preview_is_build = false

	var town_building: TownBuildingType = _resolve_town_building()
	var economy_manager = _resolve_economy_manager()
	if town_building == null or economy_manager == null:
		return

	var facility_type: int = facility.get_facility_type()
	var current_level: int = facility.get_level()
	var target_level: int = current_level + 1

	var cost_result: Dictionary = town_building.compute_upgrade_funds_cost(facility_type, target_level)
	var time_result: Dictionary = town_building.compute_upgrade_time_cost(facility_type, target_level)
	_preview_build_cost = int(cost_result.get("value", 0))
	_preview_build_time = int(time_result.get("value", 0))

	# Maintenance delta for upgrade: delta * (target_level - 1) - delta * (current_level - 1)
	# = delta * 1 = delta (since target = current + 1)
	var town_config: TownConfigType = _resolve_town_config(town_building)
	_preview_maintenance_delta = 0
	if town_config != null:
		_preview_maintenance_delta = town_config.get_facility_maintenance_delta(facility_type)

	var current_funds: int = int(economy_manager.get_funds())
	var after_funds: int = current_funds - _preview_build_cost
	var current_maintenance: int = int(town_building.get_daily_maintenance_cost())
	var after_maintenance: int = current_maintenance + _preview_maintenance_delta
	var affordable: bool = current_funds >= _preview_build_cost

	# Title
	_preview_title.text = _localized_text("TOWN_UPGRADE_PREVIEW_TITLE", "升级确认")
	var type_name: String = _facility_type_display_name(facility_type)
	_preview_funds_label.text = _localized_text("TOWN_UPGRADE_FUNDS_LINE", "设施：%s (Lv.%d → Lv.%d)\n当前经费：%d → 确认后：%d") % [type_name, current_level, target_level, current_funds, after_funds]
	_preview_maintenance_label.text = _localized_text("TOWN_BUILD_MAINTENANCE_LINE", "当前维护费：%d/天 → 完成后：%d/天") % [current_maintenance, after_maintenance]
	_preview_time_label.text = _localized_text("TOWN_UPGRADE_TIME_LINE", "升级时间：%d天") % _preview_build_time

	_preview_confirm_button.text = _localized_text("TOWN_UPGRADE_CONFIRM", "确认升级")
	_preview_confirm_button.disabled = not affordable
	_preview_insufficient_label.visible = not affordable
	if not affordable:
		var shortfall: int = _preview_build_cost - current_funds
		_preview_insufficient_label.text = _localized_text("TOWN_BUILD_INSUFFICIENT_FUNDS", "经费不足：还差 %d") % shortfall

	_show_preview_panel()


func _show_preview_panel() -> void:
	_grid_container.visible = false
	_empty_placeholder.visible = false
	_preview_panel.visible = true


func _hide_preview_panel() -> void:
	_preview_panel.visible = false
	_preview_grid_x = -1
	_preview_grid_y = -1
	_preview_facility = null
	_preview_is_build = false
	_preview_build_cost = 0
	_preview_build_time = 0
	_preview_maintenance_delta = 0
	_grid_container.visible = true
	# Recompute empty placeholder visibility
	var town_building: TownBuildingType = _resolve_town_building()
	var any_occupied: bool = false
	if town_building != null:
		for cell in _cell_panels:
			var box: VBoxContainer = _get_cell_content_box(cell)
			var name_label: Label = _find_child_by_name(box, "CellName")
			if name_label != null:
				any_occupied = true
				break
	_empty_placeholder.visible = not any_occupied


func _on_preview_confirm_pressed() -> void:
	var town_building: TownBuildingType = _resolve_town_building()
	if town_building == null:
		return

	if _preview_is_build:
		var result: Dictionary = town_building.build_facility(DEFAULT_BUILD_TYPE, _preview_grid_x, _preview_grid_y)
		if result.get("success", false):
			_hide_preview_panel()
			# emit event so grid refreshes
			EventBus.emit("town_grid_changed", {"action": "built", "grid_x": _preview_grid_x, "grid_y": _preview_grid_y})
		else:
			# Show error reason (low-pressure language)
			_preview_insufficient_label.visible = true
			_preview_insufficient_label.text = _localized_text("TOWN_BUILD_ERROR", "建造失败，请稍后重试")
			_preview_confirm_button.disabled = true
	else:
		if _preview_facility == null:
			return
		var result: Dictionary = town_building.upgrade_facility(_preview_facility.get_id())
		if result.get("success", false):
			_hide_preview_panel()
			EventBus.emit("town_grid_changed", {"action": "upgraded", "grid_x": _preview_grid_x, "grid_y": _preview_grid_y})
		else:
			_preview_insufficient_label.visible = true
			_preview_insufficient_label.text = _localized_text("TOWN_UPGRADE_ERROR", "升级失败，请稍后重试")
			_preview_confirm_button.disabled = true


func _on_preview_cancel_pressed() -> void:
	_hide_preview_panel()


func _resolve_town_config(town_building: TownBuildingType) -> TownConfigType:
	# Access town_building's internal town_config if possible (for tests)
	# In production, read from ConfigLoader. In tests, the TownBuilding
	# may have a _town_config_override we can't access directly.
	# Fall back: try ConfigLoader autoload.
	var config_loader := get_node_or_null("/root/ConfigLoader")
	if config_loader != null and config_loader.has_method("get") and config_loader.get("town_config") != null:
		return config_loader.get("town_config") as TownConfigType
	return null


# --- Cell rendering helpers ---

func _clear_box(box: VBoxContainer) -> void:
	for child: Node in box.get_children():
		box.remove_child(child)
		child.queue_free()


func _get_cell_content_box(cell: PanelContainer) -> VBoxContainer:
	var margin: MarginContainer = cell.get_child(0) as MarginContainer
	return margin.get_child(0) as VBoxContainer


func _create_cell_panel(_index: int) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.name = "TownOverviewCell"
	cell.mouse_filter = Control.MOUSE_FILTER_STOP
	cell.custom_minimum_size = Vector2(100, 56)
	cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cell.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 3)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_right", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	cell.add_child(margin)

	var box := VBoxContainer.new()
	box.name = "CellContent"
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 1)
	margin.add_child(box)

	# Connect click signal for interactive build/upgrade flow
	cell.gui_input.connect(_on_cell_gui_input.bind(_index))

	return cell


# --- Style helpers ---

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Palette.CREAM
	style.border_color = Palette.PANEL_OUTER_BORDER
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	return style


func _empty_cell_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("F0E8D8")
	style.border_color = Color("D0C0A0")
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style


func _occupied_cell_style(state: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	match state:
		FacilityType.FacilityState.CONSTRUCTING:
			style.bg_color = Color("E8D8A0")
		FacilityType.FacilityState.UPGRADING:
			style.bg_color = Color("D8C8E0")
		_:
			style.bg_color = Color("FFF8E8")
	style.border_color = Palette.WOOD_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style


func _apply_button_style(button: Button) -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Palette.BUTTON_SECONDARY_BG
	normal_style.border_color = Palette.WOOD_BORDER
	normal_style.set_border_width_all(1)
	button.add_theme_stylebox_override("normal", normal_style)
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Palette.BUTTON_SECONDARY_BG
	hover_style.border_color = Palette.BUTTON_FOCUS_BORDER
	hover_style.set_border_width_all(3)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_color_override("font_color", Palette.ZONE_A_TEXT)


func _apply_confirm_button_style(button: Button) -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Palette.BUTTON_PRIMARY_BG
	normal_style.border_color = Palette.WOOD_BORDER
	normal_style.set_border_width_all(1)
	button.add_theme_stylebox_override("normal", normal_style)
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Palette.CLUB_RED
	hover_style.border_color = Palette.BUTTON_FOCUS_BORDER
	hover_style.set_border_width_all(3)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("focus", hover_style)
	button.add_theme_stylebox_override("pressed", hover_style)
	button.add_theme_color_override("font_color", Color("FFFFFF"))

	# Disabled state
	var disabled_style := StyleBoxFlat.new()
	disabled_style.bg_color = Palette.SLATE_GRAY
	disabled_style.border_color = Palette.SLATE_GRAY
	disabled_style.set_border_width_all(1)
	button.add_theme_stylebox_override("disabled", disabled_style)
	button.add_theme_color_override("font_disabled_color", Color("AAAAAA"))


# --- Display name helpers ---

func _facility_type_display_name(facility_type: int) -> String:
	match facility_type:
		FacilityType.FacilityType.TRAINING_GROUND:
			return _localized_text("FACILITY_TRAINING_GROUND", "训练场")
		FacilityType.FacilityType.MEDICAL_ROOM:
			return _localized_text("FACILITY_MEDICAL_ROOM", "医务室")
		FacilityType.FacilityType.YOUTH_ACADEMY:
			return _localized_text("FACILITY_YOUTH_ACADEMY", "青训营")
		FacilityType.FacilityType.STADIUM:
			return _localized_text("FACILITY_STADIUM", "体育场")
	return "?"


func _facility_state_display_name(state: int) -> String:
	match state:
		FacilityType.FacilityState.CONSTRUCTING:
			return _localized_text("FACILITY_STATE_CONSTRUCTING", "建设中")
		FacilityType.FacilityState.ACTIVE:
			return _localized_text("FACILITY_STATE_ACTIVE", "运作中")
		FacilityType.FacilityState.UPGRADING:
			return _localized_text("FACILITY_STATE_UPGRADING", "升级中")
	return "?"


func _state_color(state: int) -> Color:
	match state:
		FacilityType.FacilityState.CONSTRUCTING:
			return Palette.TOWN_GOLD
		FacilityType.FacilityState.ACTIVE:
			return Palette.FIELD_GREEN
		FacilityType.FacilityState.UPGRADING:
			return Palette.CALM_BLUE
	return Palette.SLATE_GRAY


func _localized_text(key: String, fallback: String) -> String:
	var localized := tr(key)
	return fallback if localized == key else localized


func _find_child_by_name(parent: Node, child_name: String) -> Node:
	if parent == null:
		return null
	for child: Node in parent.get_children():
		if child.name == child_name:
			return child
	return null
