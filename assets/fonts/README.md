# Zpix Font (最像素) -- Required Asset

## Download

Zpix (最像素) v3.1.2 by SolidZORO

- **Official source**: https://github.com/SolidZORO/zpix-pixel-font
- **License**: MIT (free for commercial use)
- **Covers**: CJK (GB2312 + Big5 + Japanese + Korean), Latin, Cyrillic

## Import Settings

Place the `.ttf` file as `zpix.ttf` in this directory, then configure in Godot:

| Setting | Value |
|---------|-------|
| `antialiased` | `false` |
| `hinting` | `0` (None) |
| `subpixel_positioning` | `0` (Disabled) |
| `msdf` | `false` |
| `compress` | `false` |
| `fixed_size` | `12` |

## Fallback Behavior

Until Zpix is installed, the HUD theme falls back to Godot's default system font.
All font sizes are set for pixel-perfect rendering at multiples of 12px.

## Post-Install

After placing `zpix.ttf` in this directory:
1. Open `assets/themes/hud_theme.tres` in the Godot editor
2. Set the `default_font` property to `res://assets/fonts/zpix.ttf`
3. Save the theme resource
