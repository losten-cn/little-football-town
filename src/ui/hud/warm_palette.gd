class_name WarmPalette
## STYLE_GUIDE.md §3 绝对色板（7色闭环）— shared constant palette for HUD and world renderer.
##
## Usage:
##   const Palette := preload("res://src/ui/hud/warm_palette.gd")
##   var bg := Palette.CREAM
##   var border := Palette.WOOD_BORDER

# --- 7-Color Absolute Palette (STYLE_GUIDE.md §3) ---
const CREAM: Color = Color("F2E8D5")       # 基础亮色、面板、留白
const TOWN_GOLD: Color = Color("D6B35A")     # 温暖、自豪、进展、强调
const CLUB_RED: Color = Color("B84A4A")      # 团队精神、比赛能量、警报
const CALM_BLUE: Color = Color("5E7FA3")     # 信息、日程、次级结构
const FIELD_GREEN: Color = Color("6F8F5B")   # 成长、健康、训练、自然
const EARTH_BROWN: Color = Color("8A6B4F")   # 建筑、路径、木材、日常
const SLATE_GRAY: Color = Color("4C4A4A")    # 文字、轮廓、阴影

# --- Interface-Specific Variants (STYLE_GUIDE.md §4) ---
const ZONE_A_BG: Color = Color("FFF2D2")           # 顶部状态栏底色
const ZONE_A_TEXT: Color = Color("3A2A1A")          # 顶部栏文字（深棕）
const WOOD_BORDER: Color = Color("C58A3A")          # 木质边框（秋调变体）
const MATCH_DARK_BG: Color = Color("2A1F1A")        # 比赛直播暗色（唯一例外）
const MATCH_SCOREBOARD_BG: Color = Color("B84A4A")  # 比分牌底板
const MATCH_SCOREBOARD_TEXT: Color = Color("FFF2D5")# 比分牌大字
const PANEL_TITLE_BAR: Color = Color("D6B35A")      # 面板标题栏（=TOWN_GOLD）
const PANEL_OUTER_BORDER: Color = Color("3A2A1A")   # 面板外框 2px
const PANEL_INNER_BORDER: Color = Color("C58A3A")   # 面板内框 1px
const HOVER_FILL: Color = Color("FFF2D2")           # 悬停填充（=ZONE_A_BG）
const DISABLED_OVERLAY: Color = Color(1.0, 1.0, 1.0, 0.5)  # 禁用态 50% 白色蒙层
const CLOSE_BUTTON_HOVER: Color = Color("B84A4A")   # 关闭按钮悬停变红
const FOCUS_RING_WARM: Color = Color("FFD700")      # 焦点环金色

# --- Home Card Accent Variants ---
const HOME_CARD_BG: Color = Color("FFF8E8")         # Home info card background
const HOME_CARD_BORDER: Color = Color("D8A85A")     # Home info card border
const DISABLE_REASON_BG: Color = Color("FFE9C2")    # Disable reason label background

# --- Button Accent for Primary/Secondary ---
const BUTTON_PRIMARY_BG: Color = Color("C76A00")    # Primary button background
const BUTTON_SECONDARY_BG: Color = Color("F5DDA8")  # Secondary button background
const BUTTON_FOCUS_BORDER: Color = Color("5B8C5A")  # Focus border color (green)

# --- Forbidden Dark Tokens (STYLE_GUIDE.md §6, Story 002 AC-6) ---
const FORBIDDEN_DARK_HEX: Array[String] = [
	"1A1A2E",
	"252540",
	"12122A",
	"FF9800",
	"3D3D5C",
	"2E2E4A",
	"303058",
	"EAEAEA",
	"9E9EB8",
]

# --- Convenience helpers ---

## Returns true if the given hex string (uppercase, no #) matches any forbidden dark token.
static func is_forbidden_hex(hex: String) -> bool:
	return hex.to_upper() in FORBIDDEN_DARK_HEX

## Returns the full 7-color palette hex list (uppercase, no #) for test assertions.
static func seven_color_hex_list() -> Array[String]:
	return [
		"F2E8D5",
		"D6B35A",
		"B84A4A",
		"5E7FA3",
		"6F8F5B",
		"8A6B4F",
		"4C4A4A",
	]

## Normalize a Color to uppercase hex string (no #) for comparison.
static func color_to_hex(c: Color) -> String:
	return "%02X%02X%02X" % [
		clamp(int(c.r * 255.0), 0, 255),
		clamp(int(c.g * 255.0), 0, 255),
		clamp(int(c.b * 255.0), 0, 255),
	]
