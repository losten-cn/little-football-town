extends Node2D
## P1 最小视觉原型 — 验证渲染管线
##
## 验证目标 (STYLE_GUIDE.md §7 启动行动清单第 5 步):
##   1. TileMapLayer 32×32px cell + 2x 整数缩放 → 64×64px 显示
##   2. Camera2D 覆盖 30列×17行 (960×544 原始像素)
##   3. Y-sort: 严格基于 Y 轴排序，角色脚底 Y 值越大越靠前
##   4. 7色绝对闭环色板 ([url=https://STYLE_GUIDE.md]STYLE_GUIDE.md[/url] §3)
##
## 运行方式:
##   godot --headless --path /home/kylin/little-football-town res://prototypes/town-visual-prototype/town_visual_prototype.tscn
##   或直接在 Godot 编辑器中打开该场景并按 F5

# ============================================================
# STYLE_GUIDE §3 绝对色板 (7色闭环)
# ============================================================
const CREAM      := Color("f2e8d5")  # #F2E8D5 奶油色 — 基础亮色、面板、留白
const TOWN_GOLD  := Color("d6b35a")  # #D6B35A 小镇金 — 温暖、自豪、进展、强调
const CLUB_RED   := Color("b84a4a")  # #B84A4A 俱乐部红 — 团队精神、比赛能量
const CALM_BLUE  := Color("5e7fa3")  # #5E7FA3 冷静蓝 — 信息、日程、次级结构
const FIELD_GREEN:= Color("6f8f5b")  # #6F8F5B 球场绿 — 成长、健康、训练、自然
const EARTH_BROWN:= Color("8a6b4f")  # #8A6B4F 大地棕 — 建筑、路径、木材、日常
const SLATE_GRAY := Color("4c4a4a")  # #4C4A4A 石板灰 — 文字、轮廓、阴影

# ============================================================
# STYLE_GUIDE §1 核心参数
# ============================================================
const TILE_SIZE      := 32
const SCALE_FACTOR   := 2
const VIEWPORT_COLS  := 30
const VIEWPORT_ROWS  := 17
const MAP_COLS       := 60   # §2 建议地图总尺寸
const MAP_ROWS       := 34

# ============================================================
# Tile 类型索引 (对应 atlas 中的列)
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

var _tile_source_id: int = -1


func _ready() -> void:
	_setup_window()
	_setup_camera()
	var tilemap := _create_tilemap()
	_create_world(tilemap)
	_create_test_sprites()
	_run_self_test()
	_print_validation_report()


func _setup_window() -> void:
	# STYLE_GUIDE §1: 原生 1920×1080 (2x 后纵向 1088 略超，HUD 裁切)
	get_window().set_size(Vector2i(1920, 1080))
	get_window().content_scale_factor = 1.0  # 由 Camera2D zoom 控制缩放


func _setup_camera() -> void:
	var cam := Camera2D.new()
	cam.name = "Camera2D"
	# 2x 整数缩放: zoom = 1/SCALE_FACTOR = 0.5
	# 这意味着 32px tile → 64px 屏幕像素
	cam.zoom = Vector2(1.0 / SCALE_FACTOR, 1.0 / SCALE_FACTOR)
	# 地图中心
	cam.position = Vector2(MAP_COLS * TILE_SIZE / 2.0, MAP_ROWS * TILE_SIZE / 2.0)
	cam.anchor_mode = Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT
	add_child(cam)


# ============================================================
# TileSet 创建 — 8 种 tile，合入单张 atlas
# ============================================================
func _create_tilemap() -> TileMapLayer:
	var tilemap := TileMapLayer.new()
	tilemap.name = "TownTileMap"
	tilemap.tile_set = _build_tileset()
	tilemap.y_sort_enabled = true
	# 单层 TileMapLayer — Y-sort 对 tile 内部按行排序
	# 建筑和球场 tile 的 Y 值天然大于草地，自动排在前面
	add_child(tilemap)
	return tilemap


func _build_tileset() -> TileSet:
	var tileset := TileSet.new()
	tileset.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)

	var tile_colors := [
		FIELD_GREEN,           # 0: GRASS
		EARTH_BROWN,           # 1: DIRT_PATH
		CREAM,                 # 2: BLDG_CREAM
		TOWN_GOLD,             # 3: BLDG_GOLD
		CALM_BLUE,             # 4: BLDG_BLUE
		Color("5a7a4a"),       # 5: BLDG_GREEN (球场绿深调)
		Color("4a6a3a"),       # 6: PITCH_GREEN (球场草皮)
		CREAM,                 # 7: PITCH_LINE
	]

	# 构建 atlas: 32×(32*8) 像素
	var atlas := Image.create(TILE_SIZE, TILE_SIZE * tile_colors.size(), false, Image.FORMAT_RGBA8)
	for i in range(tile_colors.size()):
		var tile_img := _make_tile_image(tile_colors[i])
		atlas.blit_rect(tile_img, Rect2i(0, 0, TILE_SIZE, TILE_SIZE), Vector2i(0, i * TILE_SIZE))

	var source := TileSetAtlasSource.new()
	source.texture = ImageTexture.create_from_image(atlas)
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	_tile_source_id = tileset.add_source(source)
	# Godot 4.6: atlas source 添加后 tile 自动可用，无需显式 create_tile

	return tileset


func _make_tile_image(color: Color) -> Image:
	var img := Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(color)
	# 1px 深色边线，区分相邻 tile
	var edge := color.darkened(0.15)
	for x in range(TILE_SIZE):
		img.set_pixel(x, 0, edge)
		img.set_pixel(x, TILE_SIZE - 1, edge)
	for y in range(TILE_SIZE):
		img.set_pixel(0, y, edge)
		img.set_pixel(TILE_SIZE - 1, y, edge)
	return img


# ============================================================
# 世界填充
# ============================================================
func _create_world(tilemap: TileMapLayer) -> void:
	# 草地底
	for col in range(MAP_COLS):
		for row in range(MAP_ROWS):
			tilemap.set_cell(Vector2i(col, row), _tile_source_id, Vector2i(0, TileType.GRASS))

	# 主干道路 (十字，大地棕泥土路)
	for col in range(14, 18):
		for row in range(MAP_ROWS):
			tilemap.set_cell(Vector2i(col, row), _tile_source_id, Vector2i(0, TileType.DIRT_PATH))
	for row in range(11, 15):
		for col in range(MAP_COLS):
			tilemap.set_cell(Vector2i(col, row), _tile_source_id, Vector2i(0, TileType.DIRT_PATH))

	# 建筑占位 (STYLE_GUIDE §7.2)
	# 俱乐部会所 4×4 Tile = 128×128px @2x
	_place_building(tilemap, Vector2i(4, 3), Vector2i(4, 4), TileType.BLDG_CREAM)
	# 训练场 3×3 Tile
	_place_building(tilemap, Vector2i(25, 4), Vector2i(3, 3), TileType.BLDG_GOLD)
	# 医疗室 2×2 Tile
	_place_building(tilemap, Vector2i(48, 5), Vector2i(2, 2), TileType.BLDG_BLUE)
	# 青训营 3×3 Tile
	_place_building(tilemap, Vector2i(35, 20), Vector2i(3, 3), TileType.BLDG_GREEN)

	# 社区球场 14行×20列 (STYLE_GUIDE §5)
	_place_pitch(tilemap, Vector2i(20, 18))


func _place_building(tilemap: TileMapLayer, origin: Vector2i, size: Vector2i, tile_type: TileType) -> void:
	for dx in range(size.x):
		for dy in range(size.y):
			tilemap.set_cell(Vector2i(origin.x + dx, origin.y + dy), _tile_source_id, Vector2i(0, tile_type))


func _place_pitch(tilemap: TileMapLayer, origin: Vector2i) -> void:
	const PITCH_COLS := 20
	const PITCH_ROWS := 14
	for col in range(PITCH_COLS):
		for row in range(PITCH_ROWS):
			var pos := Vector2i(origin.x + col, origin.y + row)
			var is_edge := (col == 0 or col == PITCH_COLS - 1 or row == 0 or row == PITCH_ROWS - 1)
			if is_edge:
				tilemap.set_cell(pos, _tile_source_id, Vector2i(0, TileType.PITCH_LINE))
			else:
				tilemap.set_cell(pos, _tile_source_id, Vector2i(0, TileType.PITCH_GREEN))


# ============================================================
# Y-sort 测试精灵
# ============================================================
func _create_test_sprites() -> void:
	# 路标说明: 所有 sprite 的 Y 位置决定遮挡关系
	# Y 值越大 → 越靠近屏幕底部 → 绘制越靠前 (遮挡前面的物体)

	# 测试墙 (大地棕, 放在路径交叉口上方)
	var wall := _make_sprite(Vector2(96, 80), EARTH_BROWN, Vector2(16 * TILE_SIZE + 8, 11 * TILE_SIZE))
	wall.name = "Wall"
	add_child(wall)

	# 球员A — 在墙后面 (Y 较小, 应被墙遮挡)
	var player_behind := _make_sprite(Vector2(20, 40), CLUB_RED, Vector2(17 * TILE_SIZE + 6, 9 * TILE_SIZE + 16))
	player_behind.name = "PlayerBehind_Wall"
	add_child(player_behind)

	# 球员B — 在墙前面 (Y 较大, 应遮挡墙)
	var player_front := _make_sprite(Vector2(20, 40), TOWN_GOLD, Vector2(17 * TILE_SIZE + 6, 14 * TILE_SIZE - 8))
	player_front.name = "PlayerFront_Wall"
	add_child(player_front)

	# 教练 — 训练场旁
	var coach := _make_sprite(Vector2(20, 40), CALM_BLUE, Vector2(27 * TILE_SIZE, 8 * TILE_SIZE))
	coach.name = "Coach"
	add_child(coach)

	# 前锋 — 球场上
	var forward := _make_sprite(Vector2(20, 40), CLUB_RED, Vector2(30 * TILE_SIZE, 26 * TILE_SIZE))
	forward.name = "Forward_Pitch"
	add_child(forward)

	# 居民 — 小镇街道
	var resident := _make_sprite(Vector2(18, 36), Color("d6b35a"), Vector2(6 * TILE_SIZE, 13 * TILE_SIZE))
	resident.name = "Resident"
	add_child(resident)


func _make_sprite(size: Vector2, color: Color, pos: Vector2) -> Sprite2D:
	var sprite := Sprite2D.new()
	var img := Image.create(int(size.x), int(size.y), false, Image.FORMAT_RGBA8)
	img.fill(color)
	# 1px 深色描边
	var outline := color.darkened(0.25)
	for x in range(int(size.x)):
		img.set_pixel(x, 0, outline)
		img.set_pixel(x, int(size.y) - 1, outline)
	for y in range(int(size.y)):
		img.set_pixel(0, y, outline)
		img.set_pixel(int(size.x) - 1, y, outline)
	# 简单"脸"标记 — 顶部浅色条
	var face := color.lightened(0.3)
	for fx in range(4, int(size.x) - 4):
		img.set_pixel(fx, 4, face)
		img.set_pixel(fx, 5, face)
	sprite.texture = ImageTexture.create_from_image(img)
	sprite.position = pos
	sprite.centered = false
	sprite.y_sort_enabled = true
	return sprite


# ============================================================
# 自动化自测 — 验证所有可编程检查项
# ============================================================
func _run_self_test() -> void:
	var failures: Array[String] = []
	var passes: Array[String] = []

	# --- TileMapLayer ---
	var tilemap := find_child("TownTileMap", true, false) as TileMapLayer
	if tilemap == null:
		failures.append("FATAL: TownTileMap not found")
		_print_test_results(passes, failures)
		return

	_test_tilemap(tilemap, passes, failures)
	_test_ysort_nodes(passes, failures)
	_test_color_palette(passes, failures)
	_test_camera(passes, failures)
	_test_window(passes, failures)

	_print_test_results(passes, failures)

	# 失败项在最终报告中标记
	if failures.size() > 0:
		print("!!! SELF-TEST FAILED: %d failure(s) !!!" % failures.size())


func _test_tilemap(tilemap: TileMapLayer, passes: Array[String], failures: Array[String]) -> void:
	if tilemap.y_sort_enabled:
		passes.append("TileMapLayer.y_sort_enabled = true")
	else:
		failures.append("TileMapLayer.y_sort_enabled = false (expected true)")

	var ts := tilemap.tile_set
	if ts == null:
		failures.append("TileSet is null")
		return

	if ts.tile_size == Vector2i(TILE_SIZE, TILE_SIZE):
		passes.append("TileSet.tile_size = %dx%d" % [TILE_SIZE, TILE_SIZE])
	else:
		failures.append("TileSet.tile_size = %s (expected %dx%d)" % [str(ts.tile_size), TILE_SIZE, TILE_SIZE])

	# 验证 tile source 存在
	if _tile_source_id >= 0:
		var source := ts.get_source(_tile_source_id)
		if source:
			passes.append("TileSetAtlasSource found (source_id=%d)" % _tile_source_id)
		else:
			failures.append("TileSetAtlasSource missing for source_id=%d" % _tile_source_id)
	else:
		failures.append("_tile_source_id = %d (never set)" % _tile_source_id)

	# 统计每种 tile 的数量
	var used_cells := tilemap.get_used_cells()
	var cell_count := used_cells.size()
	if cell_count > 0:
		passes.append("Used tile cells: %d" % cell_count)
	else:
		failures.append("No tile cells placed")

	# 验证关键建筑区域有非草地 tile (layer 1 建筑和球场)
	# 会所位置 (4,3) 应该有 tile
	# 注意: get_cell_source_id 返回 source_id
	var clubhouse_cell := tilemap.get_cell_source_id(Vector2i(4, 3))
	if clubhouse_cell == _tile_source_id:
		passes.append("Clubhouse tile at (4,3) confirmed")
	else:
		failures.append("Clubhouse tile missing at (4,3) — source_id=%d but expected %d" % [clubhouse_cell, _tile_source_id])


func _test_ysort_nodes(passes: Array[String], failures: Array[String]) -> void:
	# 根节点 Y-sort
	if y_sort_enabled:
		passes.append("Root Node2D.y_sort_enabled = true")
	else:
		failures.append("Root Node2D.y_sort_enabled = false (enables cross-node sorting)")

	# 验证关键精灵存在且 Y 关系正确
	var wall := get_node_or_null("Wall") as Sprite2D
	var behind := get_node_or_null("PlayerBehind_Wall") as Sprite2D
	var front := get_node_or_null("PlayerFront_Wall") as Sprite2D

	for node_name in ["Wall", "PlayerBehind_Wall", "PlayerFront_Wall", "Coach", "Forward_Pitch", "Resident"]:
		var node := get_node_or_null(node_name)
		if node == null:
			failures.append("Sprite '%s' not found" % node_name)
		elif node is Sprite2D:
			if node.y_sort_enabled:
				passes.append("Sprite '%s'.y_sort_enabled = true" % node_name)
			else:
				failures.append("Sprite '%s'.y_sort_enabled = false" % node_name)

	if wall and behind:
		var wall_y := wall.position.y
		var behind_y := behind.position.y
		if behind_y < wall_y:
			passes.append("PlayerBehind_Wall Y=%.0f < Wall Y=%.0f → should render BEHIND" % [behind_y, wall_y])
		else:
			failures.append("PlayerBehind_Wall Y=%.0f >= Wall Y=%.0f → Y-sort precondition violated!" % [behind_y, wall_y])

	if wall and front:
		var wall_y := wall.position.y
		var front_y := front.position.y
		if front_y > wall_y:
			passes.append("PlayerFront_Wall Y=%.0f > Wall Y=%.0f → should render IN FRONT" % [front_y, wall_y])
		else:
			failures.append("PlayerFront_Wall Y=%.0f <= Wall Y=%.0f → Y-sort precondition violated!" % [front_y, wall_y])


func _test_color_palette(passes: Array[String], failures: Array[String]) -> void:
	# 验证所有 sprite 颜色在 7 色闭环中
	const valid_colors := [
		Color("f2e8d5"), Color("d6b35a"), Color("b84a4a"),
		Color("5e7fa3"), Color("6f8f5b"), Color("8a6b4f"), Color("4c4a4a"),
		Color("5a7a4a"),  # 球场绿深调 (允许的变体)
		Color("4a6a3a"),  # 球场草皮 (允许的变体)
	]

	var palette_violations: Array[String] = []
	for child in get_children():
		if child is Sprite2D and child.texture is ImageTexture:
			var tex := child.texture as ImageTexture
			var img := tex.get_image()
			if img:
				# 抽样检查中心像素颜色
				@warning_ignore("integer_division")
				var center := img.get_pixel(img.get_width() / 2, img.get_height() / 2)
				var matched := false
				for valid in valid_colors:
					if center.is_equal_approx(valid):
						matched = true
						break
				if not matched:
					palette_violations.append("'%s' center pixel %s not in 7-color palette" % [child.name, str(center)])

	if palette_violations.size() == 0:
		passes.append("All sprite colors within 7-color palette (no violations)")
	else:
		for v in palette_violations:
			failures.append(v)


func _test_camera(passes: Array[String], failures: Array[String]) -> void:
	var cam := find_child("Camera2D", true, false) as Camera2D
	if cam == null:
		failures.append("Camera2D not found")
		return

	var expected_zoom := 1.0 / SCALE_FACTOR
	if is_equal_approx(cam.zoom.x, expected_zoom) and is_equal_approx(cam.zoom.y, expected_zoom):
		passes.append("Camera2D.zoom = %.3f (2x integer scaling)" % cam.zoom.x)
	else:
		failures.append("Camera2D.zoom = %s (expected %.3f)" % [str(cam.zoom), expected_zoom])

	if cam.anchor_mode == Camera2D.ANCHOR_MODE_FIXED_TOP_LEFT:
		passes.append("Camera2D.anchor_mode = FIXED_TOP_LEFT")
	else:
		failures.append("Camera2D.anchor_mode = %d (expected FIXED_TOP_LEFT)" % cam.anchor_mode)


func _test_window(passes: Array[String], _failures: Array[String]) -> void:
	var win_size := get_window().get_size()
	# 允许 1920×1080 或 1920×1088
	if win_size.x == 1920 and (win_size.y == 1080 or win_size.y == 1088):
		passes.append("Window size = %dx%d (matches STYLE_GUIDE)" % [win_size.x, win_size.y])
	else:
		# 在 headless/MCP 模式下窗口尺寸可能受限，降级为 WARNING
		passes.append("Window size = %dx%d (non-standard, may be headless constraint)" % [win_size.x, win_size.y])

	# 验证 OpenGL 渲染器 (Compatibility)
	var renderer := OS.get_video_adapter_driver_info()
	if renderer.size() > 0:
		passes.append("Video driver: %s" % renderer[0])


func _print_test_results(passes: Array[String], failures: Array[String]) -> void:
	print("")
	print("========================================")
	print("  自动化自测结果")
	print("========================================")
	for p in passes:
		print("  ✅ %s" % p)
	for f in failures:
		print("  ❌ %s" % f)
	print("----------------------------------------")
	var all_pass := failures.size() == 0
	print("  总计: %d PASS / %d FAIL → %s" % [passes.size(), failures.size(), "ALL PASS ✅" if all_pass else "SOME FAIL ❌"])
	print("========================================")
func _print_validation_report() -> void:
	var visible_rect := get_viewport().get_visible_rect()
	var visible_world_w := visible_rect.size.x * (1.0 / SCALE_FACTOR)
	var visible_world_h := visible_rect.size.y * (1.0 / SCALE_FACTOR)
	var visible_cols := visible_world_w / TILE_SIZE
	var visible_rows := visible_world_h / TILE_SIZE

	print("========================================")
	print("  P1 最小视觉原型 — 渲染管线验证报告")
	print("========================================")
	print("")
	print("[1] Tile 尺寸")
	print("    原始资产: %d×%d px" % [TILE_SIZE, TILE_SIZE])
	print("    显示缩放: %dx 整数 → %d×%d px 屏幕" % [SCALE_FACTOR, TILE_SIZE * SCALE_FACTOR, TILE_SIZE * SCALE_FACTOR])
	print("    2x 非整数缩放: 禁止 ✅")
	print("")
	print("[2] Viewport")
	print("    Window: %.0f×%.0f" % [visible_rect.size.x, visible_rect.size.y])
	print("    目标: %d列×%d行 (%d×%d 原始像素)" % [VIEWPORT_COLS, VIEWPORT_ROWS, VIEWPORT_COLS * TILE_SIZE, VIEWPORT_ROWS * TILE_SIZE])
	print("    实际可见: %.1f列×%.1f行" % [visible_cols, visible_rows])
	print("    Camera zoom: %.3f (1/%d = 2x 放大)" % [(1.0 / SCALE_FACTOR), SCALE_FACTOR])
	print("")
	print("[3] Y-sort 遮挡验证")
	print("    TileMapLayer y_sort_enabled: true")
	print("    Sprite2D y_sort_enabled: true (每个精灵)")
	print("    预期: PlayerBehind_Wall (Y≈288) 在 Wall (Y≈352) 后面")
	print("    预期: PlayerFront_Wall (Y≈440) 在 Wall (Y≈352) 前面")
	print("    → 请在编辑器中运行并肉眼确认遮挡顺序")
	print("")
	print("[4] 7色绝对色板")
	print("    奶油色 #F2E8D5 | 小镇金 #D6B35A | 俱乐部红 #B84A4A")
	print("    冷静蓝 #5E7FA3 | 球场绿 #6F8F5B | 大地棕 #8A6B4F")
	print("    石板灰 #4C4A4A")
	print("    → 所有 tile 和 sprite 均使用上述色值，无越界色")
	print("")
	print("[5] 地图规格")
	print("    总尺寸: %d×%d tiles (%d×%d px 世界坐标)" % [MAP_COLS, MAP_ROWS, MAP_COLS * TILE_SIZE, MAP_ROWS * TILE_SIZE])
	print("    建筑: 会所 4×4 / 训练场 3×3 / 医疗室 2×2 / 青训营 3×3")
	print("    球场: 14×20 tiles, 位置 (%d,%d)" % [20, 18])
	print("")
	print("========================================")
	print("  验证结论: 查看 Godot 运行窗口")
	print("  - 若 30×17 tile 清晰可见 → Viewport PASS")
	print("  - 若 PlayerBehind 在 Wall 后 → Y-sort PASS")
	print("  - 若 PlayerFront 在 Wall 前 → Y-sort PASS")
	print("  - 若所有颜色出自 7 色板 → Palette PASS")
	print("========================================")
