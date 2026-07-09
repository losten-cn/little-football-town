extends Node2D
class_name TownWorldRenderer
## Story 001: World Rendering Layer — Production implementation.
##
## Implements STYLE_GUIDE.md §1–§3:
##   - TileMapLayer 32×32px cell + Camera2D zoom=0.5 (2x integer scaling)
##   - 60×34 tile map with grass, roads, buildings, and pitch placeholders
##   - Y-sort on root and all children (Node2D.y_sort_enabled, NOT YSort node)
##   - 7-color absolute palette only
##   - Season parameter (SPRING/SUMMER/AUTUMN/WINTER) shifts tile colors
##   - DayMode parameter (DAILY/MATCH_DUSK/CHAMPIONSHIP_NIGHT) for time-of-day hints
##
## Authority: STYLE_GUIDE.md §1, §2, §3
## ADR-0008: TileMapLayer is presentation-only — gameplay authority is TownBuilding.
##
## See: production/epics/visual-direction-alignment/story-001-world-rendering-layer.md

# ============================================================
# STYLE_GUIDE §3 绝对色板 (7色闭环)
# ============================================================
const CREAM: Color = Color("f2e8d5")       # #F2E8D5 — 基础亮色、面板、留白
const TOWN_GOLD: Color = Color("d6b35a")   # #D6B35A — 温暖、自豪、进展、强调
const CLUB_RED: Color = Color("b84a4a")    # #B84A4A — 团队精神、比赛能量、警报
const CALM_BLUE: Color = Color("5e7fa3")   # #5E7FA3 — 信息、日程、次级结构
const FIELD_GREEN: Color = Color("6f8f5b") # #6F8F5B — 成长、健康、训练、自然
const EARTH_BROWN: Color = Color("8a6b4f") # #8A6B4F — 建筑、路径、木材、日常
const SLATE_GRAY: Color = Color("4c4a4a")  # #4C4A4A — 文字、轮廓、阴影

# Allowed palette variants (verified by P1 prototype self-tests)
const PITCH_GREEN_DEEP: Color = Color("4a6a3a")  # 球场草皮深调
const BLDG_GREEN_DEEP: Color = Color("5a7a4a")    # 球场绿深调(建筑)

# ============================================================
# STYLE_GUIDE §1 核心参数
# ============================================================
const TILE_SIZE: int = 32
const SCALE_FACTOR: int = 2
const VIEWPORT_COLS: int = 30
const VIEWPORT_ROWS: int = 17
const MAP_COLS: int = 60   # §2 建议地图总尺寸
const MAP_ROWS: int = 34

# ============================================================
# Season & DayMode enums (AC-6, AC-7)
# ============================================================
enum Season {
	SPRING,
	SUMMER,
	AUTUMN,
	WINTER,
}

enum DayMode {
	DAILY,
	MATCH_DUSK,
	CHAMPIONSHIP_NIGHT,
}

# ============================================================
# Tile type indices (atlas columns)
# ============================================================
enum TileType {
	GRASS = 0,
	DIRT_PATH = 1,
	BLDG_CREAM = 2,
	BLDG_GOLD = 3,
	BLDG_BLUE = 4,
	BLDG_GREEN = 5,
	PITCH_GREEN = 6,
	PITCH_LINE = 7,
}

# ============================================================
# @export parameters — designer-tunable
# ============================================================
@export var season: Season = Season.SPRING:
	set(value):
		season = value
		if _tilemap and _tile_source_id >= 0:
			_apply_season_colors()
			_rebuild_map_tiles()

@export var day_mode: DayMode = DayMode.DAILY:
	set(value):
		day_mode = value
		if _overlay_root:
			_apply_day_mode_overlay()

# ============================================================
# Internal state
# ============================================================
var _tilemap: TileMapLayer = null
var _tile_source_id: int = -1
var _overlay_root: CanvasLayer = null
var _current_tile_colors: Array[Color] = []


func _ready() -> void:
	_setup_root()
	_setup_camera()
	_tilemap = _create_tilemap()
	_create_world(_tilemap)
	_setup_overlay_root()
	_create_test_sprites()
	# Apply current season / day_mode after all nodes exist
	_apply_season_colors()
	_rebuild_map_tiles()
	_apply_day_mode_overlay()
	_print_bootstrap_report()


# ============================================================
# Root setup — Y-sort enabled (AC-3)
# ============================================================
func _setup_root() -> void:
	# Use Node2D.y_sort_enabled, NOT the deprecated YSort node
	y_sort_enabled = true


# ============================================================
# Camera2D setup — 2x integer zoom (AC-1, AC-2)
# ============================================================
func _setup_camera() -> void:
	var cam := Camera2D.new()
	cam.name = "Camera2D"
	# 2x integer scaling: zoom = 1/SCALE_FACTOR = 0.5
	# 32px tile → 64px screen pixels. No fractional zoom (1.5, 1.8, etc.)
	cam.zoom = Vector2(1.0 / SCALE_FACTOR, 1.0 / SCALE_FACTOR)
	# Center on the map
	cam.position = Vector2(MAP_COLS * TILE_SIZE / 2.0, MAP_ROWS * TILE_SIZE / 2.0)
	cam.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(cam)


# ============================================================
# TileMapLayer creation — programmatic TileSet (AC-1)
# ============================================================
func _create_tilemap() -> TileMapLayer:
	var tilemap := TileMapLayer.new()
	tilemap.name = "TownTileMap"
	tilemap.tile_set = _build_tileset()
	tilemap.y_sort_enabled = true
	add_child(tilemap)
	return tilemap


func _build_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	# Base colors (default SPRING palette)
	_current_tile_colors = [
		FIELD_GREEN,            # 0: GRASS
		EARTH_BROWN,            # 1: DIRT_PATH
		CREAM,                  # 2: BLDG_CREAM
		TOWN_GOLD,              # 3: BLDG_GOLD
		CALM_BLUE,              # 4: BLDG_BLUE
		BLDG_GREEN_DEEP,        # 5: BLDG_GREEN
		PITCH_GREEN_DEEP,       # 6: PITCH_GREEN
		CREAM,                  # 7: PITCH_LINE
	]

	var atlas := _build_atlas(_current_tile_colors)
	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(atlas)
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	_tile_source_id = tileset.add_source(source)
	return tileset


func _build_atlas(colors: Array[Color]) -> Image:
	var atlas := Image.create(TILE_SIZE, TILE_SIZE * colors.size(), false, Image.FORMAT_RGBA8)
	for i: int in range(colors.size()):
		var tile_img := _make_tile_image(colors[i])
		atlas.blit_rect(tile_img, Rect2i(0, 0, TILE_SIZE, TILE_SIZE), Vector2i(0, i * TILE_SIZE))
	return atlas


func _make_tile_image(color: Color) -> Image:
	var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(color)
	# 1px darker edge line for tile distinction
	var edge := color.darkened(0.15)
	for x: int in range(TILE_SIZE):
		img.set_pixel(x, 0, edge)
		img.set_pixel(x, TILE_SIZE - 1, edge)
	for y: int in range(1, TILE_SIZE - 1):
		img.set_pixel(0, y, edge)
		img.set_pixel(TILE_SIZE - 1, y, edge)
	return img


# ============================================================
# World population (AC-4)
# ============================================================
func _create_world(tilemap: TileMapLayer) -> void:
	# Grass floor — fill entire map
	for col: int in range(MAP_COLS):
		for row: int in range(MAP_ROWS):
			tilemap.set_cell(Vector2i(col, row), _tile_source_id, Vector2i(0, TileType.GRASS))

	# Main roads (cross pattern, dirt path)
	# Vertical road: columns 14–17
	for col: int in range(14, 18):
		for row: int in range(MAP_ROWS):
			tilemap.set_cell(Vector2i(col, row), _tile_source_id, Vector2i(0, TileType.DIRT_PATH))
	# Horizontal road: rows 11–14
	for row: int in range(11, 15):
		for col: int in range(MAP_COLS):
			tilemap.set_cell(Vector2i(col, row), _tile_source_id, Vector2i(0, TileType.DIRT_PATH))

	# Buildings (STYLE_GUIDE §7.2: core buildings)
	# Clubhouse 4×4 Tile at (4,3)
	_place_building(tilemap, Vector2i(4, 3), Vector2i(4, 4), TileType.BLDG_CREAM)
	# Training ground 3×3 Tile at (25,4)
	_place_building(tilemap, Vector2i(25, 4), Vector2i(3, 3), TileType.BLDG_GOLD)
	# Medical room 2×2 Tile at (48,5)
	_place_building(tilemap, Vector2i(48, 5), Vector2i(2, 2), TileType.BLDG_BLUE)
	# Youth academy 3×3 Tile at (35,20)
	_place_building(tilemap, Vector2i(35, 20), Vector2i(3, 3), TileType.BLDG_GREEN)

	# Community pitch 14 rows × 20 cols at (20,18) (STYLE_GUIDE §5)
	_place_pitch(tilemap, Vector2i(20, 18))


func _place_building(tilemap: TileMapLayer, origin: Vector2i, size: Vector2i, tile_type: TileType) -> void:
	for dx: int in range(size.x):
		for dy: int in range(size.y):
			tilemap.set_cell(Vector2i(origin.x + dx, origin.y + dy), _tile_source_id, Vector2i(0, tile_type))


func _place_pitch(tilemap: TileMapLayer, origin: Vector2i) -> void:
	const PITCH_COLS: int = 20
	const PITCH_ROWS: int = 14
	for col: int in range(PITCH_COLS):
		for row: int in range(PITCH_ROWS):
			var pos := Vector2i(origin.x + col, origin.y + row)
			var is_edge: bool = (col == 0 or col == PITCH_COLS - 1 or row == 0 or row == PITCH_ROWS - 1)
			if is_edge:
				tilemap.set_cell(pos, _tile_source_id, Vector2i(0, TileType.PITCH_LINE))
			else:
				tilemap.set_cell(pos, _tile_source_id, Vector2i(0, TileType.PITCH_GREEN))


# ============================================================
# Season color shifts (AC-6)
# ============================================================
func _apply_season_colors() -> void:
	match season:
		Season.SPRING:
			# Ground tone brightened +10% yellow, vegetation adds #8FBC6A accent
			_current_tile_colors = [
				FIELD_GREEN.lightened(0.10),    # 0: GRASS — brightened
				EARTH_BROWN,                     # 1: DIRT_PATH
				CREAM,                           # 2: BLDG_CREAM
				TOWN_GOLD,                       # 3: BLDG_GOLD
				CALM_BLUE,                       # 4: BLDG_BLUE
				Color("8fbc6a"),                 # 5: BLDG_GREEN → spring accent
				Color("8fbc6a").darkened(0.15),  # 6: PITCH_GREEN → spring variant
				CREAM,                           # 7: PITCH_LINE
			]
		Season.SUMMER:
			# Saturation +5%, grass richer deep green #5A7A4A
			_current_tile_colors = [
				Color("5a7a4a"),                 # 0: GRASS — rich deep green
				EARTH_BROWN.lightened(0.05),     # 1: DIRT_PATH — slightly drier
				CREAM,                           # 2: BLDG_CREAM
				TOWN_GOLD,                       # 3: BLDG_GOLD
				CALM_BLUE,                       # 4: BLDG_BLUE
				BLDG_GREEN_DEEP,                 # 5: BLDG_GREEN
				Color("5a7a4a"),                 # 6: PITCH_GREEN — summer grass
				CREAM,                           # 7: PITCH_LINE
			]
		Season.AUTUMN:
			# Warm color temperature, grass mixed with #C58A3A and #BFA26A
			_current_tile_colors = [
				Color("bfa26a"),                 # 0: GRASS — withered yellow
				Color("c58a3a"),                 # 1: DIRT_PATH — warm brown
				CREAM,                           # 2: BLDG_CREAM
				TOWN_GOLD,                       # 3: BLDG_GOLD
				CALM_BLUE,                       # 4: BLDG_BLUE
				Color("c58a3a"),                 # 5: BLDG_GREEN → autumn earth
				Color("6f8f5b"),                 # 6: PITCH_GREEN — maintained pitch
				CREAM,                           # 7: PITCH_LINE
			]
		Season.WINTER:
			# Overall brightness raised, 30% transparent snow layer
			_current_tile_colors = [
				FIELD_GREEN.lerp(Color.WHITE, 0.30),  # 0: GRASS — snow-dusted
				EARTH_BROWN.lightened(0.15),            # 1: DIRT_PATH — frozen
				CREAM,                                  # 2: BLDG_CREAM
				TOWN_GOLD,                              # 3: BLDG_GOLD
				CALM_BLUE,                              # 4: BLDG_BLUE
				BLDG_GREEN_DEEP.lightened(0.10),        # 5: BLDG_GREEN
				Color("6f8f5b"),                        # 6: PITCH_GREEN — maintained
				CREAM,                                  # 7: PITCH_LINE
			]


func _rebuild_map_tiles() -> void:
	if _tilemap == null or _tile_source_id < 0:
		return
	# Rebuild atlas with new colors
	var atlas := _build_atlas(_current_tile_colors)
	var ts: TileSet = _tilemap.tile_set
	if ts == null:
		return
	var source := ts.get_source(_tile_source_id) as TileSetAtlasSource
	if source == null:
		return
	source.texture = ImageTexture.create_from_image(atlas)
	# Re-apply same tile placements (grass, roads, buildings, pitch) with new colors
	# The cell data is unchanged; only the texture changed.
	# However, to ensure correct atlas coordinate mapping after source replacement,
	# we need to recreate the world tiles.
	_tilemap.clear()
	_create_world(_tilemap)


# ============================================================
# Day mode overlay (AC-7)
# ============================================================
func _setup_overlay_root() -> void:
	_overlay_root = CanvasLayer.new()
	_overlay_root.name = "DayModeOverlay"
	_overlay_root.layer = 5  # above TileMapLayer, below HUD
	add_child(_overlay_root)


func _apply_day_mode_overlay() -> void:
	if _overlay_root == null:
		return
	# Clear previous overlay children
	for child in _overlay_root.get_children():
		child.queue_free()

	match day_mode:
		DayMode.DAILY:
			# Warm white ambient light + minimal 2px shadow
			# (minimal — just a subtle warm tint, no heavy overlay)
			_add_warm_overlay()
		DayMode.MATCH_DUSK:
			# Orange highlight overlay + 4px floodlight drop shadows
			_add_dusk_overlay()
		DayMode.CHAMPIONSHIP_NIGHT:
			# Star particles + cool blue backlight + fireworks
			_add_night_overlay()


func _add_warm_overlay() -> void:
	# Subtle warm white overlay (very light)
	var tint := ColorRect.new()
	tint.name = "WarmTint"
	tint.color = Color(1.0, 1.0, 0.95, 0.04)
	tint.size = Vector2(MAP_COLS * TILE_SIZE, MAP_ROWS * TILE_SIZE)
	_overlay_root.add_child(tint)


func _add_dusk_overlay() -> void:
	# Orange highlight layer + contrast boost
	var tint := ColorRect.new()
	tint.name = "DuskTint"
	tint.color = Color(0.95, 0.55, 0.1, 0.10)
	tint.size = Vector2(MAP_COLS * TILE_SIZE, MAP_ROWS * TILE_SIZE)
	_overlay_root.add_child(tint)

	# Floodlight cones — simple vertical 4px wide strips (placeholder)
	for i: int in range(4):
		var light := ColorRect.new()
		light.name = "Floodlight_%d" % i
		light.color = Color(1.0, 0.85, 0.6, 0.08)
		# Place floodlights around the pitch area
		var base_x: float = 20.0 * TILE_SIZE + (i * 6.0 + 2.0) * TILE_SIZE
		light.position = Vector2(base_x, 18.0 * TILE_SIZE)
		light.size = Vector2(4, 14.0 * TILE_SIZE)
		_overlay_root.add_child(light)


func _add_night_overlay() -> void:
	# Cool blue backlight
	var tint := ColorRect.new()
	tint.name = "NightBacklight"
	tint.color = Color(0.15, 0.2, 0.4, 0.25)
	tint.size = Vector2(MAP_COLS * TILE_SIZE, MAP_ROWS * TILE_SIZE)
	_overlay_root.add_child(tint)

	# Star particles — sparse white dots on a dark background
	var stars := _make_star_particles()
	stars.name = "StarParticles"
	_overlay_root.add_child(stars)

	# Fireworks placeholder — red + gold burst indicators near pitch
	_add_firework_placeholder()


func _make_star_particles() -> Node2D:
	# Placeholder: create a small set of star-like dots distributed across the sky
	# (upper portion of the map — rows 0–10)
	var stars_node := Node2D.new()
	var star_img := Image.create(2, 2, false, Image.FORMAT_RGBA8)
	star_img.fill(Color.WHITE)
	star_img.set_pixel(0, 0, Color.TRANSPARENT)
	star_img.set_pixel(1, 1, Color.TRANSPARENT)
	var star_tex := ImageTexture.create_from_image(star_img)

	for _i: int in range(30):
		var star := Sprite2D.new()
		star.texture = star_tex
		star.position = Vector2(randi() % (MAP_COLS * TILE_SIZE), randi() % (10 * TILE_SIZE))
		star.modulate = Color(1.0, 1.0, 1.0, 0.4 + randf() * 0.6)
		star.scale = Vector2(0.5 + randf() * 1.0, 0.5 + randf() * 1.0)
		stars_node.add_child(star)
	return stars_node


func _add_firework_placeholder() -> void:
	# Placeholder: red + gold "burst" dots near the pitch area
	var fw_node := Node2D.new()
	fw_node.name = "FireworksPlaceholder"

	var colors: Array[Color] = [CLUB_RED, TOWN_GOLD]
	for _i: int in range(5):
		var burst := Sprite2D.new()
		var img := Image.create(6, 6, false, Image.FORMAT_RGBA8)
		var c := colors[_i % colors.size()]
		# Draw a simple cross pattern
		for p: int in range(6):
			img.set_pixel(p, 2, c)
			img.set_pixel(p, 3, c)
			img.set_pixel(2, p, c)
			img.set_pixel(3, p, c)
		burst.texture = ImageTexture.create_from_image(img)
		# Scatter around pitch area
		burst.position = Vector2(
			20.0 * TILE_SIZE + randi() % (20 * TILE_SIZE),
			18.0 * TILE_SIZE - randi() % (4 * TILE_SIZE)
		)
		burst.modulate.a = 0.6 + randf() * 0.4
		fw_node.add_child(burst)
	_overlay_root.add_child(fw_node)


# ============================================================
# Test sprites for Y-sort validation (AC-3)
# ============================================================
func _create_test_sprites() -> void:
	# Wall (earth brown, at road intersection)
	var wall := _make_sprite(Vector2(96, 80), EARTH_BROWN, Vector2(16 * TILE_SIZE + 8, 11 * TILE_SIZE))
	wall.name = "Wall"
	add_child(wall)

	# Player behind wall (smaller Y -> renders behind)
	var player_behind := _make_sprite(Vector2(20, 40), CLUB_RED, Vector2(17 * TILE_SIZE + 6, 9 * TILE_SIZE + 16))
	player_behind.name = "PlayerBehind_Wall"
	add_child(player_behind)

	# Player in front of wall (larger Y -> renders in front)
	var player_front := _make_sprite(Vector2(20, 40), TOWN_GOLD, Vector2(17 * TILE_SIZE + 6, 14 * TILE_SIZE - 8))
	player_front.name = "PlayerFront_Wall"
	add_child(player_front)

	# Coach near training ground
	var coach := _make_sprite(Vector2(20, 40), CALM_BLUE, Vector2(27 * TILE_SIZE, 8 * TILE_SIZE))
	coach.name = "Coach"
	add_child(coach)

	# Forward on pitch
	var forward := _make_sprite(Vector2(20, 40), CLUB_RED, Vector2(30 * TILE_SIZE, 26 * TILE_SIZE))
	forward.name = "Forward_Pitch"
	add_child(forward)

	# Resident on town street
	var resident := _make_sprite(Vector2(18, 36), TOWN_GOLD, Vector2(6 * TILE_SIZE, 13 * TILE_SIZE))
	resident.name = "Resident"
	add_child(resident)


func _make_sprite(size: Vector2, color: Color, pos: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	var img := Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	img.fill(color)
	# 1px dark outline
	var outline := color.darkened(0.25)
	for x: int in range(int(size.x)):
		img.set_pixel(x, 0, outline)
		img.set_pixel(x, int(size.y) - 1, outline)
	for y: int in range(int(size.y)):
		img.set_pixel(0, y, outline)
		img.set_pixel(int(size.x) - 1, y, outline)
	# Simple "face" marker — top light strip
	var face := color.lightened(0.3)
	for fx: int in range(4, int(size.x) - 4):
		img.set_pixel(fx, 4, face)
		img.set_pixel(fx, 5, face)
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.position = pos
	sprite.centered = false
	sprite.y_sort_enabled = true
	return sprite


# ============================================================
# Bootstrap report — prints key configuration for debugging
# ============================================================
func _print_bootstrap_report() -> void:
	var visible_rect := get_viewport().get_visible_rect()
	var visible_cols := visible_rect.size.x * (1.0 / SCALE_FACTOR) / TILE_SIZE
	var visible_rows := visible_rect.size.y * (1.0 / SCALE_FACTOR) / TILE_SIZE

	print("========================================")
	print("  TownWorldRenderer — Bootstrap Report")
	print("========================================")
	print("  Tile size: %d×%d px" % [TILE_SIZE, TILE_SIZE])
	print("  Camera zoom: %.3f (2x integer scaling)" % (1.0 / SCALE_FACTOR))
	print("  Viewport: %.1f cols × %.1f rows visible" % [visible_cols, visible_rows])
	print("  Map size: %d×%d tiles" % [MAP_COLS, MAP_ROWS])
	print("  Y-sort: %s" % ("enabled" if y_sort_enabled else "DISABLED"))
	print("  Season: %d  DayMode: %d" % [season, day_mode])
	print("  Renderer: %s" % _get_renderer_name())
	print("========================================")


func _get_renderer_name() -> String:
	var info := OS.get_video_adapter_driver_info()
	if info.size() > 0:
		return info[0]
	return "unknown"
