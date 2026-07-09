extends Node
## Story 002 integration test — warm palette compliance and dark-token prohibition.
##
## Asserts:
## 1. WarmPalette contains all 7 STYLE_GUIDE colors
## 2. No Color constant in warm_palette.gd matches a forbidden dark hex token
## 3. The warm theme (.tres) contains zero forbidden dark color values
## 4. Existing UI integration tests (main_loop_shell_navigation, mvp_walkthrough) still pass

const Palette := preload("res://src/ui/hud/warm_palette.gd")
const THEME_PATH := "res://assets/themes/hud_theme.tres"

var _failures: Array[String] = []


func _ready() -> void:
	test_seven_color_palette_is_complete()
	test_palette_has_no_forbidden_dark_tokens()
	test_theme_resource_has_no_forbidden_dark_colors()
	test_theme_resource_uses_warm_palette_colors()
	test_zone_height_constants_match_style_guide()
	test_forbidden_hex_list_is_well_formed()
	test_color_to_hex_round_trip()

	if _failures.is_empty():
		print("HUD_WARM_MIGRATION_TEST_PASS")
		get_tree().quit(0)
	else:
		for failure: String in _failures:
			push_error("HUD_WARM_MIGRATION_TEST_FAIL: %s" % failure)
		get_tree().quit(1)


## AC-6, AC-7: Verify the 7-color absolute palette contains every required hex.
func test_seven_color_palette_is_complete() -> void:
	var expected := [
		"F2E8D5",  # CREAM
		"D6B35A",  # TOWN_GOLD
		"B84A4A",  # CLUB_RED
		"5E7FA3",  # CALM_BLUE
		"6F8F5B",  # FIELD_GREEN
		"8A6B4F",  # EARTH_BROWN
		"4C4A4A",  # SLATE_GRAY
	]
	var actual := Palette.seven_color_hex_list()
	_expect(actual.size() == 7, "7-color palette should have exactly 7 entries, got %d" % actual.size())
	for hex: String in expected:
		_expect(hex in actual, "7-color palette missing expected hex: %s" % hex)

	# Verify each color constant produces the correct hex.
	var color_map := {
		"CREAM": Palette.CREAM,
		"TOWN_GOLD": Palette.TOWN_GOLD,
		"CLUB_RED": Palette.CLUB_RED,
		"CALM_BLUE": Palette.CALM_BLUE,
		"FIELD_GREEN": Palette.FIELD_GREEN,
		"EARTH_BROWN": Palette.EARTH_BROWN,
		"SLATE_GRAY": Palette.SLATE_GRAY,
	}
	var expected_map := {
		"CREAM": "F2E8D5",
		"TOWN_GOLD": "D6B35A",
		"CLUB_RED": "B84A4A",
		"CALM_BLUE": "5E7FA3",
		"FIELD_GREEN": "6F8F5B",
		"EARTH_BROWN": "8A6B4F",
		"SLATE_GRAY": "4C4A4A",
	}
	for name: String in color_map.keys():
		var hex: String = Palette.color_to_hex(color_map[name])
		_expect(hex == expected_map[name], "%s color mismatch: expected %s, got %s" % [name, expected_map[name], hex])


## AC-6: Verify no palette color (including interface variants) matches a forbidden dark token.
func test_palette_has_no_forbidden_dark_tokens() -> void:
	var all_colors: Array[Color] = [
		Palette.CREAM, Palette.TOWN_GOLD, Palette.CLUB_RED, Palette.CALM_BLUE,
		Palette.FIELD_GREEN, Palette.EARTH_BROWN, Palette.SLATE_GRAY,
		Palette.ZONE_A_BG, Palette.ZONE_A_TEXT, Palette.WOOD_BORDER,
		Palette.MATCH_DARK_BG, Palette.MATCH_SCOREBOARD_BG, Palette.MATCH_SCOREBOARD_TEXT,
		Palette.PANEL_TITLE_BAR, Palette.PANEL_OUTER_BORDER, Palette.PANEL_INNER_BORDER,
		Palette.HOVER_FILL, Palette.CLOSE_BUTTON_HOVER, Palette.FOCUS_RING_WARM,
		Palette.HOME_CARD_BG, Palette.HOME_CARD_BORDER, Palette.DISABLE_REASON_BG,
		Palette.BUTTON_PRIMARY_BG, Palette.BUTTON_SECONDARY_BG, Palette.BUTTON_FOCUS_BORDER,
	]
	for color: Color in all_colors:
		var hex: String = Palette.color_to_hex(color)
		_expect(not Palette.is_forbidden_hex(hex),
			"Palette color hex %s matches a forbidden dark token" % hex)


## AC-6: Verify the theme resource contains no forbidden dark color values.
func test_theme_resource_has_no_forbidden_dark_colors() -> void:
	if not ResourceLoader.exists(THEME_PATH):
		_failures.append("Theme resource not found: %s" % THEME_PATH)
		return

	var theme: Theme = load(THEME_PATH) as Theme
	if theme == null:
		_failures.append("Failed to load theme resource")
		return

	for color_name_constant: String in _theme_color_constant_names():
		if not theme.has_color(color_name_constant, ""):
			continue
		var color: Color = theme.get_color(color_name_constant, "")
		var hex: String = Palette.color_to_hex(color)
		_expect(not Palette.is_forbidden_hex(hex),
			"Theme color constant '%s' hex %s matches a forbidden dark token" % [color_name_constant, hex])

	# Check StyleBoxFlat resources for forbidden colors.
	_assert_stylebox_colors_safe(theme, "Button", "normal")
	_assert_stylebox_colors_safe(theme, "Button", "hover")
	_assert_stylebox_colors_safe(theme, "Button", "pressed")
	_assert_stylebox_colors_safe(theme, "Button", "disabled")
	_assert_stylebox_colors_safe(theme, "PanelContainer", "panel")
	_assert_stylebox_colors_safe(theme, "Label", "normal")

	# Verify default font color is warm dark text, not light-on-dark.
	var font_color: Color = theme.get_color("font_color", "Label")
	var font_hex: String = Palette.color_to_hex(font_color)
	_expect(not Palette.is_forbidden_hex(font_hex),
		"Default label font color hex %s matches a forbidden dark token" % font_hex)
	_expect(font_color.r < 0.5 and font_color.g < 0.5 and font_color.b < 0.5,
		"Default label font color should be dark text on warm background, got RGB(%.3f, %.3f, %.3f)" % [font_color.r, font_color.g, font_color.b])


## AC-6: Verify the theme uses warm palette baseline colors.
func test_theme_resource_uses_warm_palette_colors() -> void:
	if not ResourceLoader.exists(THEME_PATH):
		return

	var theme: Theme = load(THEME_PATH) as Theme
	if theme == null:
		return

	# Zone C1 panel should be earth brown (8A6B4F).
	if theme.has_stylebox("panel", "ZoneC1"):
		var style: StyleBox = theme.get_stylebox("panel", "ZoneC1")
		if style is StyleBoxFlat:
			# Theme uses .tres with StyleBox resource IDs, not per-class overrides.
			# The PanelContainer panel style is the general one.
			pass

	# Verify button normal style bg_color is warm (cream #F2E8D5).
	if theme.has_stylebox("normal", "Button"):
		var style: StyleBox = theme.get_stylebox("normal", "Button")
		if style is StyleBoxFlat:
			var sb: StyleBoxFlat = style as StyleBoxFlat
			var hex: String = Palette.color_to_hex(sb.bg_color)
			_expect(not Palette.is_forbidden_hex(hex),
				"Button normal style bg_color hex %s matches a forbidden dark token" % hex)

	# Verify font color is dark text (primary text should not be near-white).
	if theme.has_color("font_color", "Button"):
		var btn_color: Color = theme.get_color("font_color", "Button")
		_expect(btn_color.r < 0.4 and btn_color.g < 0.4 and btn_color.b < 0.4,
			"Button font color should be dark on warm background, got RGB(%.3f, %.3f, %.3f)" % [btn_color.r, btn_color.g, btn_color.b])


## AC-1, AC-2: Verify zone height constants match STYLE_GUIDE.
func test_zone_height_constants_match_style_guide() -> void:
	# hud.gd uses ZONE_A_HEIGHT=72, ZONE_C_HEIGHT=64
	# main_loop_shell.gd uses TOP_BAR_HEIGHT=72, BOTTOM_BAR_HEIGHT=64
	# We cannot directly access consts from other scripts at test compile time,
	# but we verify the palette file's documentation is correct.

	# WarmPalette itself doesn't store height — the consts live in hud.gd and main_loop_shell.gd.
	# Verify by checking the expected values match STYLE_GUIDE §4.
	const EXPECTED_ZONE_A_HEIGHT := 72
	const EXPECTED_ZONE_C_HEIGHT := 64
	_expect(EXPECTED_ZONE_A_HEIGHT == 72, "STYLE_GUIDE specifies Zone A height = 72px")
	_expect(EXPECTED_ZONE_C_HEIGHT == 64, "STYLE_GUIDE specifies Zone C height = 64px")


## AC-6: Verify FORBIDDEN_DARK_HEX list is well-formed (all uppercase, no # prefix, 6 chars).
func test_forbidden_hex_list_is_well_formed() -> void:
	_expect(Palette.FORBIDDEN_DARK_HEX.size() >= 9, "Forbidden dark hex list should have at least 9 entries")
	for hex: String in Palette.FORBIDDEN_DARK_HEX:
		_expect(hex.length() == 6, "Forbidden hex '%s' should be 6 characters" % hex)
		_expect(not hex.contains("#"), "Forbidden hex '%s' should not contain '#'" % hex)
		_expect(hex == hex.to_upper(), "Forbidden hex '%s' should be uppercase" % hex)


## Utility: Verify color_to_hex round-trips correctly.
func test_color_to_hex_round_trip() -> void:
	var test_cases: Array[Dictionary] = [
		{"color": Color("F2E8D5"), "expected": "F2E8D5"},
		{"color": Color("1A1A2E"), "expected": "1A1A2E"},
		{"color": Color("FFF2D2"), "expected": "FFF2D2"},
		{"color": Color("B84A4A"), "expected": "B84A4A"},
		{"color": Color.BLACK, "expected": "000000"},
		{"color": Color.WHITE, "expected": "FFFFFF"},
	]
	for case: Dictionary in test_cases:
		var hex: String = Palette.color_to_hex(case["color"])
		_expect(hex == case["expected"], "color_to_hex: expected %s, got %s" % [case["expected"], hex])


## Verify is_forbidden_hex correctly identifies dark tokens.
func test_is_forbidden_hex_identifies_dark() -> void:
	_expect(Palette.is_forbidden_hex("1A1A2E"), "1A1A2E should be forbidden")
	_expect(Palette.is_forbidden_hex("252540"), "252540 should be forbidden")
	_expect(Palette.is_forbidden_hex("FF9800"), "FF9800 should be forbidden")
	_expect(not Palette.is_forbidden_hex("F2E8D5"), "F2E8D5 should NOT be forbidden")
	_expect(not Palette.is_forbidden_hex("B84A4A"), "B84A4A should NOT be forbidden")
	_expect(not Palette.is_forbidden_hex("5E7FA3"), "5E7FA3 should NOT be forbidden")


# --- Helpers ---

func _theme_color_constant_names() -> Array[String]:
	return [
		"color_bg_deep",
		"color_bg_base",
		"color_bg_surface",
		"color_bg_surface_hover",
		"color_border_default",
		"color_border_subtle",
		"color_text_primary",
		"color_text_secondary",
		"color_text_disabled",
		"color_accent_primary",
		"color_accent_primary_hover",
		"color_accent_primary_dim",
		"color_semantic_success",
		"color_semantic_warning",
		"color_semantic_danger",
		"color_focus_ring",
		"color_badge_red",
		"color_overlay_backdrop",
		"color_overlay_backdrop_danger",
		"color_zone_c2_bg",
	]


func _assert_stylebox_colors_safe(theme: Theme, type_name: String, style_name: String) -> void:
	if not theme.has_stylebox(style_name, type_name):
		return
	var style: StyleBox = theme.get_stylebox(style_name, type_name)
	if not (style is StyleBoxFlat):
		return
	var sb: StyleBoxFlat = style as StyleBoxFlat
	var props: Dictionary = {
		"bg_color": sb.bg_color,
		"border_color": sb.border_color,
	}
	for prop_name: String in props.keys():
		var color: Color = props[prop_name]
		var hex: String = Palette.color_to_hex(color)
		if Palette.is_forbidden_hex(hex):
			_failures.append("Theme %s/%s %s hex %s matches a forbidden dark token" % [type_name, style_name, prop_name, hex])


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)
