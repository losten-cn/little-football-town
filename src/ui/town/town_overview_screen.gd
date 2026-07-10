class_name TownOverviewScreen
extends Control
## Read-only Town Overview screen stub rendering a 5x5 facility grid.
##
## This is a minimum Alpha presentation stub consuming the authoritative
## TownBuilding read model. It renders 25 grid cells using WarmPalette
## placeholder colors, facility name/level/status per cell, and a read-only
## economic summary at top (funds + daily maintenance). Back button pops
## via ScreenManager.pop_screen(). No build/upgrade/demolish logic.
##
## See: production/epics/town-management-ui/story-001-grid-stub.md
## See: ADR-0008 (presentation-only rule)

const Palette := preload("res://src/ui/hud/warm_palette.gd")
const TownBuildingType = preload("res://src/core/town_building.gd")
const FacilityType = preload("res://src/core/facility.gd")

const GRID_COLUMNS: int = 5
const GRID_ROWS: int = 5
const CELL_TOTAL: int = GRID_COLUMNS * GRID_ROWS

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

var _root_box: VBoxContainer = null
var _title_label: Label = null
var _back_button: Button = null
var _economic_summary_label: Label = null
var _grid_container: GridContainer = null
var _cell_panels: Array[PanelContainer] = []
var _empty_placeholder: Label = null


func _ready() -> void:
	name = "TownOverviewScreen"
	mouse_filter = Control.MOUSE_FILTER_PASS
	_setup_ui()
	_subscribe_events()
	_refresh()


func _exit_tree() -> void:
	EventBus.unsubscribe("town_grid_changed", _on_town_grid_changed)
	EventBus.unsubscribe("screen_popped", _on_screen_popped)


## Injects a test TownBuilding without relying on scene tree.
func set_town_building_for_testing(town_building: TownBuildingType) -> void:
	_town_building_for_testing = town_building
	_refresh()


## Returns the current TownBuilding reference for this screen.
func _resolve_town_building() -> TownBuildingType:
	if _town_building_for_testing != null:
		return _town_building_for_testing
	return _town_building


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
	ScreenManager.pop_screen()


func _refresh() -> void:
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
	var economy_manager = get_node_or_null("/root/EconomyManager")
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

	# Level label
	var level_label := Label.new()
	level_label.name = "CellLevel"
	level_label.text = "Lv.%d" % facility.get_level()
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_color_override("font_color", Palette.ZONE_A_TEXT)
	level_label.add_theme_font_size_override("font_size", 10)
	box.add_child(level_label)

	# Status label
	var status_label := Label.new()
	status_label.name = "CellStatus"
	status_label.text = _facility_state_display_name(facility.get_state())
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", _state_color(facility.get_state()))
	status_label.add_theme_font_size_override("font_size", 9)
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

	# Connect click signal for future interactivity (AC-2: cell is clickable)
	cell.gui_input.connect(_on_cell_gui_input.bind(_index))

	return cell


func _on_cell_gui_input(event: InputEvent, cell_index: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var y: int = cell_index / GRID_COLUMNS
		var x: int = cell_index % GRID_COLUMNS
		print("[TownOverview] Cell clicked: (%d, %d) — index %d" % [x, y, cell_index])


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
			return _localized_text("FACILITY_STATE_CONSTRUCTING", "施工中")
		FacilityType.FacilityState.ACTIVE:
			return _localized_text("FACILITY_STATE_ACTIVE", "运行中")
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
