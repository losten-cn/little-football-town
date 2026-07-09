extends PanelContainer
## Read-only Town Grid stub consuming authoritative TownBuilding grid state.
##
## This is a minimum Alpha presentation stub. It does not implement
## build/upgrade/demolish flows, construction cost preview, budget
## validation, or adjacency visualization. It renders a 5x5 facility
## grid as read-only placeholders, and degrades to a neutral empty
## placeholder when TownBuilding is absent or the grid is empty.

const TownBuildingType = preload("res://src/core/town_building.gd")
const FacilityType = preload("res://src/core/facility.gd")

const UI_COLOR_TEXT := Color("3A2A1A")
const UI_COLOR_MUTED := Color("6D5A3A")
const UI_COLOR_ACCENT := Color("C76A00")
const UI_COLOR_SURFACE := Color("F5DDA8")
const UI_COLOR_BORDER := Color("C58A3A")
const UI_COLOR_EMPTY_CELL := Color("F0E8D8")
const UI_COLOR_EMPTY_BORDER := Color("D0C0A0")
const UI_COLOR_OCCUPIED_CELL := Color("FFF8E8")
const UI_COLOR_OCCUPIED_BORDER := Color("D8A85A")
const UI_COLOR_CONSTRUCTING := Color("E8D8A0")
const UI_COLOR_UPGRADING := Color("D8C8E0")

const GRID_COLUMNS: int = 5
const GRID_ROWS: int = 5
const CELL_TOTAL: int = GRID_COLUMNS * GRID_ROWS

var _town_building: TownBuildingType = null
var _town_building_for_testing: TownBuildingType = null
var _root_box: VBoxContainer = null
var _title_label: Label = null
var _grid_container: GridContainer = null
var _cell_panels: Array[PanelContainer] = []
var _empty_placeholder: Label = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_PASS
	_setup_ui()
	_subscribe_events()
	_refresh()


func _exit_tree() -> void:
	EventBus.unsubscribe("town_grid_changed", _on_town_grid_changed)


## Sets the authoritative TownBuilding reference for grid queries.
func set_town_building(town_building: TownBuildingType) -> void:
	_town_building = town_building
	_refresh()


## Injects a test TownBuilding without relying on scene tree.
func set_town_building_for_testing(town_building: TownBuildingType) -> void:
	_town_building_for_testing = town_building
	_refresh()


func _resolve_town_building() -> TownBuildingType:
	if _town_building_for_testing != null:
		return _town_building_for_testing
	return _town_building


func _setup_ui() -> void:
	size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = Color("FFF8E8")
	panel_style.border_color = Color("D8A85A")
	panel_style.set_border_width_all(1)
	panel_style.set_corner_radius_all(6)
	panel_style.set_content_margin_all(8.0)
	add_theme_stylebox_override("panel", panel_style)

	_root_box = VBoxContainer.new()
	_root_box.name = "TownGridRoot"
	_root_box.add_theme_constant_override("separation", 8)
	add_child(_root_box)

	_title_label = Label.new()
	_title_label.name = "TownGridTitle"
	_title_label.text = _localized_text("TOWN_GRID_TITLE", "小镇设施布局")
	_title_label.add_theme_color_override("font_color", UI_COLOR_ACCENT)
	_title_label.add_theme_font_size_override("font_size", 14)
	_root_box.add_child(_title_label)

	_grid_container = GridContainer.new()
	_grid_container.name = "TownGridContainer"
	_grid_container.columns = GRID_COLUMNS
	_grid_container.add_theme_constant_override("h_separation", 4)
	_grid_container.add_theme_constant_override("v_separation", 4)
	_root_box.add_child(_grid_container)

	for i: int in range(CELL_TOTAL):
		var cell: PanelContainer = _create_cell_panel(i)
		_grid_container.add_child(cell)
		_cell_panels.append(cell)

	_empty_placeholder = Label.new()
	_empty_placeholder.name = "TownGridEmpty"
	_empty_placeholder.text = _localized_text("TOWN_GRID_EMPTY", "暂无设施")
	_empty_placeholder.add_theme_color_override("font_color", UI_COLOR_MUTED)
	_empty_placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty_placeholder.visible = false
	_root_box.add_child(_empty_placeholder)


func _subscribe_events() -> void:
	EventBus.subscribe("town_grid_changed", _on_town_grid_changed)


func _on_town_grid_changed(_event_name: String, _payload: Dictionary) -> void:
	_refresh()


func _refresh() -> void:
	var town_building: TownBuildingType = _resolve_town_building()
	if town_building == null:
		_render_all_empty()
		return

	var any_occupied: bool = false
	var grid_width: int = town_building.get_grid_width()
	var grid_height: int = town_building.get_grid_height()

	for y: int in range(GRID_ROWS):
		for x: int in range(GRID_COLUMNS):
			var cell_index: int = y * GRID_COLUMNS + x
			if cell_index >= _cell_panels.size():
				continue
			var facility: FacilityType = null
			if x < grid_width and y < grid_height:
				facility = town_building.get_facility_at(x, y)
			if facility != null and facility.get_state() != FacilityType.FacilityState.EMPTY:
				_render_occupied_cell(cell_index, facility)
				any_occupied = true
			else:
				_render_empty_cell(cell_index)

	if any_occupied:
		_grid_container.visible = true
		_empty_placeholder.visible = false
	else:
		_grid_container.visible = true
		_empty_placeholder.visible = true


func _render_all_empty() -> void:
	for i: int in range(_cell_panels.size()):
		_render_empty_cell(i)
	_grid_container.visible = true
	_empty_placeholder.visible = true


func _render_empty_cell(cell_index: int) -> void:
	var cell: PanelContainer = _cell_panels[cell_index]
	var cell_style := _empty_cell_style()
	_update_cell_style(cell, cell_style)

	var box: VBoxContainer = _get_cell_content_box(cell)
	var icon: Label = _get_or_create_cell_icon(box)
	icon.text = "."
	icon.add_theme_color_override("font_color", UI_COLOR_MUTED)

	var level_label: Label = _get_or_create_cell_level(box)
	level_label.visible = false

	var progress: ColorRect = _get_or_create_progress_indicator(box)
	progress.visible = false


func _render_occupied_cell(cell_index: int, facility: FacilityType) -> void:
	var cell: PanelContainer = _cell_panels[cell_index]
	var cell_style := _occupied_cell_style(facility.get_state())
	_update_cell_style(cell, cell_style)

	var box: VBoxContainer = _get_cell_content_box(cell)
	var icon: Label = _get_or_create_cell_icon(box)
	icon.text = _facility_type_icon(facility.get_facility_type())
	icon.add_theme_color_override("font_color", _facility_type_color(facility.get_facility_type()))

	var level_label: Label = _get_or_create_cell_level(box)
	level_label.text = "Lv.%d" % facility.get_level()
	level_label.add_theme_color_override("font_color", UI_COLOR_TEXT)
	level_label.visible = true

	var progress: ColorRect = _get_or_create_progress_indicator(box)
	var state: int = facility.get_state()
	if state == FacilityType.FacilityState.CONSTRUCTING or state == FacilityType.FacilityState.UPGRADING:
		progress.visible = true
		progress.color = UI_COLOR_MUTED
		# TODO(S5-followup): Replace ColorRect with ProgressBar when total
		# construction units become available from TownBuilding authority.
	else:
		progress.visible = false


func _create_cell_panel(_index: int) -> PanelContainer:
	var cell := PanelContainer.new()
	cell.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cell.custom_minimum_size = Vector2(56, 56)
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

	return cell


func _get_cell_content_box(cell: PanelContainer) -> VBoxContainer:
	var margin: MarginContainer = cell.get_child(0) as MarginContainer
	return margin.get_child(0) as VBoxContainer


func _get_or_create_cell_icon(box: VBoxContainer) -> Label:
	if box.get_child_count() > 0 and box.get_child(0) is Label:
		return box.get_child(0) as Label
	var icon := Label.new()
	icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon.add_theme_font_size_override("font_size", 16)
	box.add_child(icon)
	if box.get_child_count() > 1:
		box.move_child(icon, 0)
	return icon


func _get_or_create_cell_level(box: VBoxContainer) -> Label:
	for child: Node in box.get_children():
		if child is Label and child.name == "CellLevel":
			return child as Label
	var level_label := Label.new()
	level_label.name = "CellLevel"
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 9)
	box.add_child(level_label)
	return level_label


func _get_or_create_progress_indicator(box: VBoxContainer) -> ColorRect:
	for child: Node in box.get_children():
		if child is ColorRect and child.name == "ProgressIndicator":
			return child as ColorRect
	var progress := ColorRect.new()
	progress.name = "ProgressIndicator"
	progress.custom_minimum_size = Vector2(0, 4)
	progress.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(progress)
	return progress


func _update_cell_style(cell: PanelContainer, style: StyleBoxFlat) -> void:
	cell.add_theme_stylebox_override("panel", style)


func _empty_cell_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = UI_COLOR_EMPTY_CELL
	style.border_color = UI_COLOR_EMPTY_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style


func _occupied_cell_style(state: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	match state:
		FacilityType.FacilityState.CONSTRUCTING:
			style.bg_color = UI_COLOR_CONSTRUCTING
		FacilityType.FacilityState.UPGRADING:
			style.bg_color = UI_COLOR_UPGRADING
		_:
			style.bg_color = UI_COLOR_OCCUPIED_CELL
	style.border_color = UI_COLOR_OCCUPIED_BORDER
	style.set_border_width_all(1)
	style.set_corner_radius_all(4)
	return style


func _facility_type_icon(facility_type: int) -> String:
	match facility_type:
		FacilityType.FacilityType.TRAINING_GROUND:
			return "⚔"  # crossed swords
		FacilityType.FacilityType.MEDICAL_ROOM:
			return "✚"  # heavy greek cross / medical
		FacilityType.FacilityType.YOUTH_ACADEMY:
			return "☆"  # white star / youth
		FacilityType.FacilityType.STADIUM:
			return "♟"  # stadium / arena icon
	return "?"


func _facility_type_color(facility_type: int) -> Color:
	match facility_type:
		FacilityType.FacilityType.TRAINING_GROUND:
			return Color("B85A30")
		FacilityType.FacilityType.MEDICAL_ROOM:
			return Color("3A7A5A")
		FacilityType.FacilityType.YOUTH_ACADEMY:
			return Color("4A5AB8")
		FacilityType.FacilityType.STADIUM:
			return Color("B84A6A")
	return UI_COLOR_ACCENT


func _localized_text(key: String, fallback: String) -> String:
	var localized := tr(key)
	return fallback if localized == key else localized
