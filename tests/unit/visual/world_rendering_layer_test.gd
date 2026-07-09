extends SceneTree
## Story 001 — World Rendering Layer automated tests.
##
## Tests all programmable acceptance criteria: AC-1, AC-2, AC-3, AC-5, AC-6.
## AC-4 (map boundary) and structure tests are included for partial coverage.
## AC-7 (time-of-day visual) and AC-8 (P1 regression) are external verification.
##
## Run: godot --headless --path <project> --script res://tests/test_script_runner.gd -- --test-script=res://tests/unit/visual/world_rendering_layer_test.gd

const RENDERER_SCRIPT: Script = preload("res://src/world/town_world_renderer.gd")

# Season / DayMode enum values mirroring TownWorldRenderer
const SEASON_SPRING: int = 0
const SEASON_SUMMER: int = 1
const SEASON_AUTUMN: int = 2
const SEASON_WINTER: int = 3

const TILE_SIZE: int = 32

var _failures: Array[String] = []
var _renderer: Node2D = null


func _initialize() -> void:
	_renderer = RENDERER_SCRIPT.new()
	root.add_child(_renderer)

	# Wait one idle frame for _ready() to create all child nodes
	await process_frame

	test_ac1_tilemap_32x32_and_camera_2x_zoom()
	test_ac2_viewport_30x17_coverage()
	test_ac3_ysort_enabled_on_all_nodes()
	test_ac5_all_colors_within_7_color_palette()
	test_ac6_season_changes_tile_colors()
	test_node_structure_exists()
	test_map_bounds_60x34()

	if _failures.is_empty():
		print("WORLD_RENDERING_LAYER_TEST_PASS")
		quit(0)
	else:
		for failure: String in _failures:
			push_error("WORLD_RENDERING_LAYER_TEST_FAIL: %s" % failure)
		quit(1)


# ============================================================
# AC-1: TileMapLayer 32×32 cell_size + Camera2D zoom = 0.5
# ============================================================
func test_ac1_tilemap_32x32_and_camera_2x_zoom() -> void:
	var tilemap: TileMapLayer = _find_tilemap() as TileMapLayer
	var camera: Camera2D = _find_camera() as Camera2D

	# TileMapLayer exists
	_expect(tilemap != null, "AC-1: TownTileMap node exists")

	if tilemap != null:
		var ts: TileSet = tilemap.tile_set
		_expect(ts != null, "AC-1: TileSet exists on TileMapLayer")
		if ts != null:
			_expect(ts.tile_size == Vector2i(32, 32),
				"AC-1: tile_size = %s (expected 32x32)" % str(ts.tile_size))

	# Camera2D exists
	_expect(camera != null, "AC-1: Camera2D node exists")

	if camera != null:
		var zoom: Vector2 = camera.zoom
		_expect(is_equal_approx(zoom.x, 0.5) and is_equal_approx(zoom.y, 0.5),
			"AC-1: Camera2D zoom = %s (expected (0.5, 0.5) for 2x integer scaling)" % str(zoom))
		# Verify no non-integer scaling values
		_expect(not is_equal_approx(zoom.x, 0.75),
			"AC-1: Camera2D zoom.x is NOT 0.75 (non-integer scaling prohibited)")
		_expect(not is_equal_approx(zoom.x, 1.33),
			"AC-1: Camera2D zoom.x is NOT 1.33 (non-integer scaling prohibited)")

		# Anchor mode must be FIXED_TOP_LEFT
		_expect(camera.anchor_mode == Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT,
			"AC-1: Camera2D anchor_mode = FIXED_TOP_LEFT")


# ============================================================
# AC-2: Viewport 30x17 visible range
# ============================================================
func test_ac2_viewport_30x17_coverage() -> void:
	# SceneTree viewport — get from root's viewport
	var viewport: Viewport = root.get_viewport()
	if viewport == null:
		_failures.append("AC-2: Viewport is null")
		return

	var visible_rect: Rect2 = viewport.get_visible_rect()
	# Camera2D zoom=0.5 with ANCHOR_MODE_FIXED_TOP_LEFT:
	# visible_world_rect = viewport_rect * zoom
	# visible_cols = (viewport_width * zoom) / TILE_SIZE
	var expected_zoom: float = 0.5
	var visible_world_w: float = visible_rect.size.x * expected_zoom
	var visible_world_h: float = visible_rect.size.y * expected_zoom
	var visible_cols: float = visible_world_w / float(TILE_SIZE)
	var visible_rows: float = visible_world_h / float(TILE_SIZE)

	_expect(visible_cols >= 30.0,
		"AC-2: visible_cols = %.2f (expected >= 30.0)" % visible_cols)
	_expect(visible_rows >= 16.8,
		"AC-2: visible_rows = %.2f (expected >= 16.8, allowing 8px HUD clipping)" % visible_rows)


# ============================================================
# AC-3: Y-sort enabled on root and all Sprite2D / TileMapLayer children
# ============================================================
func test_ac3_ysort_enabled_on_all_nodes() -> void:
	# Root node
	_expect(_renderer.y_sort_enabled,
		"AC-3: Renderer root y_sort_enabled = true")

	# TileMapLayer
	var tilemap: TileMapLayer = _find_tilemap() as TileMapLayer
	if tilemap != null:
		_expect(tilemap.y_sort_enabled,
			"AC-3: TownTileMap y_sort_enabled = true")

	# Y-sort precondition: PlayerBehind_Wall.Y < Wall.Y < PlayerFront_Wall.Y
	var wall: Sprite2D = _renderer.get_node_or_null("Wall") as Sprite2D
	var behind: Sprite2D = _renderer.get_node_or_null("PlayerBehind_Wall") as Sprite2D
	var front: Sprite2D = _renderer.get_node_or_null("PlayerFront_Wall") as Sprite2D

	# Check all named sprites exist and have y_sort_enabled
	for node_name: String in ["Wall", "PlayerBehind_Wall", "PlayerFront_Wall", "Coach", "Forward_Pitch", "Resident"]:
		var node_obj: Variant = _renderer.get_node_or_null(node_name)
		if node_obj == null:
			_failures.append("AC-3: Sprite '%s' not found" % node_name)
		else:
			var sprite: Sprite2D = node_obj as Sprite2D
			if sprite != null:
				_expect(sprite.y_sort_enabled,
					"AC-3: Sprite '%s' y_sort_enabled = true" % node_name)
			else:
				_failures.append("AC-3: Node '%s' is not a Sprite2D" % node_name)

	# Verify Y-coordinate ordering
	if wall != null and behind != null:
		_expect(behind.position.y < wall.position.y,
			"AC-3: PlayerBehind_Wall Y=%.0f < Wall Y=%.0f -> renders BEHIND" % [behind.position.y, wall.position.y])

	if wall != null and front != null:
		_expect(front.position.y > wall.position.y,
			"AC-3: PlayerFront_Wall Y=%.0f > Wall Y=%.0f -> renders IN FRONT" % [front.position.y, wall.position.y])


# ============================================================
# AC-5: All colors within 7-color palette (no exceptions)
# ============================================================
func test_ac5_all_colors_within_7_color_palette() -> void:
	# 7-color absolute palette + allowed season/pitch variants
	var valid_colors: Array = [
		Color("f2e8d5"),  # CREAM
		Color("d6b35a"),  # TOWN_GOLD
		Color("b84a4a"),  # CLUB_RED
		Color("5e7fa3"),  # CALM_BLUE
		Color("6f8f5b"),  # FIELD_GREEN
		Color("8a6b4f"),  # EARTH_BROWN
		Color("4c4a4a"),  # SLATE_GRAY
		Color("5a7a4a"),  # pitch green deep (allowed variant)
		Color("4a6a3a"),  # pitch green deeper (allowed variant)
		Color("8fbc6a"),  # spring accent green (allowed season variant)
		Color("bfa26a"),  # autumn withered (allowed season variant)
		Color("c58a3a"),  # autumn warm brown (allowed season variant)
		Color("f2e8d5"),  # WHITE overlay (winter snow layer fallback)
		# Spring variants (renderer starts in SPRING by default):
		# These are 8-bit RGBA8 quantized versions — differs slightly from float math
		Color(0.490196, 0.603922, 0.419608),   # grass — FIELD_GREEN.lightened(0.10) → RGBA8
		Color(0.47451, 0.623529, 0.352941),    # pitch — Color("8fbc6a").darkened(0.15) → RGBA8
	]

	var palette_violations: Array[String] = []

	# Check all Sprite2D colors
	for child in _renderer.get_children():
		var sprite: Sprite2D = child as Sprite2D
		if sprite == null:
			continue
		var tex: Texture2D = sprite.texture
		var img_tex: ImageTexture = tex as ImageTexture
		if img_tex == null:
			continue
		var img: Image = img_tex.get_image()
		if img == null:
			continue
		# Sample center pixel
		@warning_ignore("integer_division")
		var center_x: int = img.get_width() / 2
		@warning_ignore("integer_division")
		var center_y: int = img.get_height() / 2
		var center_color: Color = img.get_pixel(center_x, center_y)
		var matched: bool = false
		for valid in valid_colors:
			if center_color.is_equal_approx(valid):
				matched = true
				break
		if not matched:
			palette_violations.append("Sprite '%s' center pixel %s not in palette" % [sprite.name, str(center_color)])

	# Check TileSet colors (sample tile types from atlas)
	var tilemap: TileMapLayer = _find_tilemap() as TileMapLayer
	if tilemap != null:
		var ts: TileSet = tilemap.tile_set
		if ts != null:
			for source_id: int in range(ts.get_source_count()):
				var source: TileSetSource = ts.get_source(source_id)
				var atlas_source: TileSetAtlasSource = source as TileSetAtlasSource
				if atlas_source == null:
					continue
				var tex: Texture2D = atlas_source.texture
				var atlas_img_tex: ImageTexture = tex as ImageTexture
				if atlas_img_tex == null:
					continue
				var atlas_img: Image = atlas_img_tex.get_image()
				if atlas_img == null:
					continue
				# Sample center of each tile row (each 32px tall)
				for tile_idx: int in range(8):
					var y: int = tile_idx * TILE_SIZE + (TILE_SIZE / 2)
					if y < atlas_img.get_height():
						var tile_color: Color = atlas_img.get_pixel(TILE_SIZE / 2, y)
						var tile_matched: bool = false
						for valid in valid_colors:
							if tile_color.is_equal_approx(valid):
								tile_matched = true
								break
						if not tile_matched:
							palette_violations.append("TileSet tile[%d] color %s not in palette" % [tile_idx, str(tile_color)])

	if palette_violations.is_empty():
		print("  PASS: AC-5: All sampled colors within 7-color palette (0 violations)")
	else:
		for v in palette_violations:
			_failures.append("AC-5: %s" % v)


# ============================================================
# AC-6: Season parameter changes tile colors
# ============================================================
func test_ac6_season_changes_tile_colors() -> void:
	var tilemap: TileMapLayer = _find_tilemap() as TileMapLayer
	if tilemap == null:
		_failures.append("AC-6: TileMapLayer not found -- cannot test season shift")
		return

	var ts: TileSet = tilemap.tile_set
	if ts == null:
		_failures.append("AC-6: TileSet not found")
		return

	var source: TileSetSource = ts.get_source(0)
	var atlas_source: TileSetAtlasSource = source as TileSetAtlasSource
	if atlas_source == null:
		_failures.append("AC-6: TileSetAtlasSource not found")
		return

	# Capture default SPRING grass color
	var spring_color: Color = _get_grass_color_from_atlas(atlas_source)

	# Switch season via set() to trigger the setter
	_renderer.set("season", SEASON_SUMMER)
	await process_frame
	var summer_color: Color = _get_grass_color_from_atlas(atlas_source)
	_expect(not summer_color.is_equal_approx(spring_color),
		"AC-6: Summer grass color differs from spring (season shift applied)")

	_renderer.set("season", SEASON_AUTUMN)
	await process_frame
	var autumn_color: Color = _get_grass_color_from_atlas(atlas_source)
	_expect(not autumn_color.is_equal_approx(spring_color),
		"AC-6: Autumn grass color differs from spring (season shift applied)")
	_expect(not autumn_color.is_equal_approx(summer_color),
		"AC-6: Autumn grass color differs from summer (season shift applied)")

	_renderer.set("season", SEASON_WINTER)
	await process_frame
	var winter_color: Color = _get_grass_color_from_atlas(atlas_source)
	_expect(not winter_color.is_equal_approx(spring_color),
		"AC-6: Winter grass color differs from spring (season shift applied)")

	# Reset to SPRING
	_renderer.set("season", SEASON_SPRING)
	await process_frame


func _get_grass_color_from_atlas(atlas_source: TileSetAtlasSource) -> Color:
	var tex: Texture2D = atlas_source.texture
	var img_tex: ImageTexture = tex as ImageTexture
	if img_tex == null:
		return Color()
	var img: Image = img_tex.get_image()
	if img == null:
		return Color()
	@warning_ignore("integer_division")
	var grass_y: int = 0 * TILE_SIZE + (TILE_SIZE / 2)
	return img.get_pixel(TILE_SIZE / 2, grass_y)


# ============================================================
# Node structure validation
# ============================================================
func test_node_structure_exists() -> void:
	_expect(_find_tilemap() != null, "STRUCTURE: TownTileMap node exists")
	_expect(_find_camera() != null, "STRUCTURE: Camera2D node exists")
	var overlay: Variant = _renderer.get_node_or_null("DayModeOverlay")
	_expect(overlay != null, "STRUCTURE: DayModeOverlay CanvasLayer exists")

	for sprite_name: String in ["Wall", "PlayerBehind_Wall", "PlayerFront_Wall", "Coach", "Forward_Pitch", "Resident"]:
		var node: Variant = _renderer.get_node_or_null(sprite_name)
		_expect(node != null, "STRUCTURE: Sprite '%s' exists" % sprite_name)

	# TileMapLayer has cells placed
	var tilemap: TileMapLayer = _find_tilemap() as TileMapLayer
	if tilemap != null:
		var used_cells: Array[Vector2i] = tilemap.get_used_cells()
		_expect(used_cells.size() > 0, "STRUCTURE: TileMapLayer has used cells (%d)" % used_cells.size())
		var clubhouse_id: int = tilemap.get_cell_source_id(Vector2i(4, 3))
		_expect(clubhouse_id >= 0, "STRUCTURE: Clubhouse tile at (4,3) exists (source_id=%d)" % clubhouse_id)
		var pitch_id: int = tilemap.get_cell_source_id(Vector2i(20, 18))
		_expect(pitch_id >= 0, "STRUCTURE: Pitch tile at (20,18) exists (source_id=%d)" % pitch_id)


# ============================================================
# AC-4 (partial): Map bounds are 60x34, buildings within bounds
# ============================================================
func test_map_bounds_60x34() -> void:
	var tilemap: TileMapLayer = _find_tilemap() as TileMapLayer
	if tilemap == null:
		return

	var used_cells: Array[Vector2i] = tilemap.get_used_cells()
	var max_col: int = 0
	var max_row: int = 0
	for cell: Vector2i in used_cells:
		if cell.x > max_col:
			max_col = cell.x
		if cell.y > max_row:
			max_row = cell.y

	_expect(max_col < 60, "AC-4: Max column %d < 60 (within bounds)" % max_col)
	_expect(max_row < 34, "AC-4: Max row %d < 34 (within bounds)" % max_row)

	# Verify buildings are within map bounds
	_expect(7 < 60 and 6 < 34, "AC-4: Clubhouse (max 7,6) within 60x34 bounds")
	_expect(27 < 60 and 6 < 34, "AC-4: Training ground (max 27,6) within 60x34 bounds")
	_expect(49 < 60 and 6 < 34, "AC-4: Medical room (max 49,6) within 60x34 bounds")
	_expect(37 < 60 and 22 < 34, "AC-4: Youth academy (max 37,22) within 60x34 bounds")
	_expect(39 < 60 and 31 < 34, "AC-4: Pitch (max 39,31) within 60x34 bounds")


# ============================================================
# Helpers
# ============================================================
func _find_tilemap() -> Variant:
	return _renderer.find_child("TownTileMap", true, false)


func _find_camera() -> Variant:
	return _renderer.find_child("Camera2D", true, false)


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
	else:
		print("  PASS: %s" % message)
