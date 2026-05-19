# HUD Walkthrough Evidence — Sprint 1

- Story Type: UI
- Output Location: `production/qa/evidence/`
- Gate Level: ADVISORY
- Scope: S1-1, S1-2
- Source: `production/qa/qa-plan-sprint-1-2026-05-19.md`, `production/qa/smoke-2026-05-19.md`

## Current Status

Godot MCP executed the expanded HUD interaction verification scene successfully. Screenshot evidence and full visual walkthrough notes are still missing.

## Evidence Summary

| Evidence Item | Status | Notes |
|---|---|---|
| Smoke-reported HUD render/state/focus/match takeover path | PASS | User corrected earlier failed selection as mistaken during `/smoke-check sprint`. |
| Screenshot package attached | NOT VERIFIED | No screenshot files were present when this evidence draft was created. |
| HUD interaction verification scene | PASS | Godot MCP and local Godot console both ran `res://tests/manual/HudInteractionVerification.tscn` on Godot 4.6.2 and output `HUD_INTERACTION_VERIFICATION_PASS` with no errors. |
| MVP HUD contract checks | PASS | Expanded scene verified required MVP HUD nodes, hidden non-MVP zones, read-only focus exclusion, and enabled button Tab focus. |
| Walkthrough notes completed | PARTIAL | Automated manual scene covered HUD contract, tooltip delay, reduced-motion toast, and match-flow HUD hiding; screenshots and full visual walkthrough remain missing. |

## Key Checklist

- [PASS] HUD render/state/focus/match takeover smoke path reported passing.
- [PASS] Godot MCP ran `res://tests/manual/HudInteractionVerification.tscn`; output contained `HUD_INTERACTION_VERIFICATION_PASS` and no errors.
- [PASS] Tooltip delay verification passed in the manual scene.
- [PASS] Reduced-motion toast verification passed in the manual scene.
- [PASS] Match-flow HUD hiding verification passed in the manual scene.
- [PASS] Required MVP HUD nodes exist in the non-match context: Date, Funds, Action Points, Action Windows, Next Match, Menu, Roster, and Match controls.
- [PASS] Non-MVP HUD zones `ZoneB` and `ZoneC2` are hidden.
- [PASS] Read-only HUD text controls do not allow Tab focus.
- [PASS] Enabled Menu, Roster, and Match buttons are Tab focusable.
- [NOT VERIFIED] Home HUD screenshot shows 日期/赛季、经费、运动点数、可用行动窗口、下一场比赛状态、菜单、球员入口、比赛入口.
- [NOT VERIFIED] Screenshot captures disabled match entry with readable reason.
- [NOT VERIFIED] Screenshot captures match-ready emphasis state.
- [NOT VERIFIED] Screenshot captures pause menu overlay.
- [NOT VERIFIED] Notes confirm focus returns to menu trigger after closing pause menu.
- [NOT VERIFIED] Tab order recorded and compared against `design/ux/hud.md`.
- [NOT VERIFIED] 1280×720, 1920×1080, and 125% UI scale checked for clipping, overlap, and focus-ring overflow.
- [NOT VERIFIED] Visual issues list includes contrast, alignment, clipping, and focus-indicator findings if any.

## Verification Runs

### Godot MCP

- Scene: `res://tests/manual/HudInteractionVerification.tscn`
- Engine: Godot 4.6.2 stable
- Result: PASS
- Output marker: `HUD_INTERACTION_VERIFICATION_PASS`
- Errors: none

### Local Godot Console

Command:

```bash
"/d/Program Files/godot/Godot_v4.6.2-stable_win64_console.exe" --headless --path "E:/code/Claude-Code-Game-Studios" "res://tests/manual/HudInteractionVerification.tscn" 2>&1
```

Output:

```text
Godot Engine v4.6.2.stable.official.71f334935
HUD_INTERACTION_VERIFICATION_PASS
```

Result: PASS

## Screenshot Manifest

| Screenshot | Required View | Status | File |
|---|---|---|---|
| Home HUD | Strict MVP persistent HUD elements | NOT VERIFIED | — |
| Disabled Match Entry | Disabled match entry + readable reason | NOT VERIFIED | — |
| Match Ready | Match-ready emphasis state | NOT VERIFIED | — |
| Pause Menu | Overlay open + focus trap | NOT VERIFIED | — |
| Scale / Resolution | 1280×720, 1920×1080, 125% UI scale | NOT VERIFIED | — |

## Open Gaps

No screenshots are currently evidenced. Do not mark S1-2 complete until walkthrough artifacts exist.
