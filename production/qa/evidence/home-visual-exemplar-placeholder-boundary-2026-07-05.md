# Home Visual Exemplar and Placeholder Boundary — 2026-07-05

> **Story**: `production/epics/main-loop-ui-framework/story-002-home-visual-exemplar-placeholder-boundary.md`  
> **Sprint**: Sprint 3 — Production Visual Follow-through  
> **Result**: PASS WITH WARNINGS  
> **Scope**: Home / MainLoop Shell visual exemplar boundary only

## Scope

This evidence records the minimum Home/shell visual-boundary pass for the Production follow-through slice.

In scope:

- Home visual hierarchy and information grouping.
- Warm-town readable panel treatment.
- Match unavailable / disabled reason presentation.
- Placeholder tolerance check for reviewed Home route states.
- Existing route guardrails and MVP visual walkthrough coverage.

Out of scope:

- No `ScreenManager` changes.
- No new route IDs.
- No gameplay authority changes.
- No save/event schema changes.
- No Player/Training/Match page internals replacement.
- No final production art claim.

## Implemented Changes

- Home was reorganized from one long summary block into a short player-facing summary plus six read-only information cards:
  - current date / phase;
  - next match;
  - team overview;
  - resources and action windows;
  - recommended next step;
  - town warmth / recent activity.
- Match unavailable state now appears as a dedicated player-facing reason block: `比赛暂未开放：...`.
- Home card and button styling uses warm cream panels, deep readable text, restrained accent borders, and focus/hover border changes so state is not communicated by color alone.
- Bottom Match navigation keeps authority-free behavior and adds a clearer disabled tooltip/accessibility description pointing the player back to Home's reason text.

## Placeholder Boundary Verification

| Rule | Status | Notes |
|---|---|---|
| No blank or empty Home main panel | PASS | Home now always mounts summary plus card container. |
| No internal IDs / enum / debug labels in Home cards | PASS BY TEST INTENT | Guardrails assert no `Opponent 1`, `待同步`, or `debug` text in Home card output. |
| Placeholder does not hide critical actions | PASS | Primary and secondary CTA remain visible; disabled match reason is explicit. |
| Placeholder does not imply false interaction | PASS | Home cards are read-only panels; only CTA buttons are interactive. |
| Return path to Home remains visible / stable | PASS | Route IDs and shell return behavior are unchanged. |
| Warm-town direction preserved | PASS WITH WARNINGS | Uses warm panels and text treatment; not final art. |

## Walkthrough States to Review

The MVP visual walkthrough runner now verifies the Home visual exemplar card set on these states:

- `01_home_initial`
- `06_home_after_training`
- `07_home_match_disabled_reason`
- `12_home_final`

Expected screenshot output directory when the renderer exposes viewport images:

- `user://mvp_visual_walkthrough`

If the headless dummy renderer returns no image, the runner must print `MVP_VISUAL_WALKTHROUGH_SCREENSHOT_UNAVAILABLE=...` and the result is treated as structure / route evidence only, not as completed screenshot review evidence.

## Automated Guardrails

Fresh local verification was run with Godot `v4.6.3.stable.official.7d41c59c4`:

```text
/home/kylin/godot/godot --headless --path /home/kylin/little-football-town --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/main_loop_shell_navigation_test.gd
/home/kylin/godot/godot --headless --path /home/kylin/little-football-town --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/l2_playable_loop_panels_test.gd
/home/kylin/godot/godot --headless --path /home/kylin/little-football-town --script res://tests/integration/ui/mvp_visual_walkthrough_runner.gd
```

Observed headless markers:

- `MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS`
- `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`
- `MVP_VISUAL_WALKTHROUGH_SCREENSHOT_UNAVAILABLE=headless renderer produced no screenshot artifacts`
- `MVP_VISUAL_WALKTHROUGH_STRUCTURE_PASS`

Visible-window screenshot verification was then run with:

```text
/home/kylin/godot/godot --path /home/kylin/little-football-town --script res://tests/integration/ui/mvp_visual_walkthrough_runner.gd
```

Visible-window observed markers:

- `MVP_VISUAL_WALKTHROUGH_SCREENSHOT=/home/kylin/.local/share/godot/app_userdata/Football Town/mvp_visual_walkthrough/01_home_initial.png`
- `MVP_VISUAL_WALKTHROUGH_SCREENSHOT=/home/kylin/.local/share/godot/app_userdata/Football Town/mvp_visual_walkthrough/02_roster.png`
- `MVP_VISUAL_WALKTHROUGH_SCREENSHOT=/home/kylin/.local/share/godot/app_userdata/Football Town/mvp_visual_walkthrough/03_player_detail.png`
- `MVP_VISUAL_WALKTHROUGH_SCREENSHOT=/home/kylin/.local/share/godot/app_userdata/Football Town/mvp_visual_walkthrough/04_training.png`
- `MVP_VISUAL_WALKTHROUGH_SCREENSHOT=/home/kylin/.local/share/godot/app_userdata/Football Town/mvp_visual_walkthrough/05_training_result.png`
- `MVP_VISUAL_WALKTHROUGH_SCREENSHOT=/home/kylin/.local/share/godot/app_userdata/Football Town/mvp_visual_walkthrough/06_home_after_training.png`
- `MVP_VISUAL_WALKTHROUGH_SCREENSHOT=/home/kylin/.local/share/godot/app_userdata/Football Town/mvp_visual_walkthrough/07_home_match_disabled_reason.png`
- `MVP_VISUAL_WALKTHROUGH_SCREENSHOT=/home/kylin/.local/share/godot/app_userdata/Football Town/mvp_visual_walkthrough/08_match_pre.png`
- `MVP_VISUAL_WALKTHROUGH_SCREENSHOT=/home/kylin/.local/share/godot/app_userdata/Football Town/mvp_visual_walkthrough/09_match_live_empty.png`
- `MVP_VISUAL_WALKTHROUGH_SCREENSHOT=/home/kylin/.local/share/godot/app_userdata/Football Town/mvp_visual_walkthrough/10_match_live_timeline.png`
- `MVP_VISUAL_WALKTHROUGH_SCREENSHOT=/home/kylin/.local/share/godot/app_userdata/Football Town/mvp_visual_walkthrough/11_match_result.png`
- `MVP_VISUAL_WALKTHROUGH_SCREENSHOT=/home/kylin/.local/share/godot/app_userdata/Football Town/mvp_visual_walkthrough/12_home_final.png`
- `MVP_VISUAL_WALKTHROUGH_OUTPUT_DIR=/home/kylin/.local/share/godot/app_userdata/Football Town/mvp_visual_walkthrough`
- `MVP_VISUAL_WALKTHROUGH_STRUCTURE_PASS`
- `MVP_VISUAL_WALKTHROUGH_PASS`

Visual review result: PASS WITH WARNINGS. The reviewed Home screenshots are readable, warm-toned, non-blank, inside the shell, and include visible CTA / disabled-reason states. The remaining warning is that this is still a production-representative UI exemplar, not final art.

## Acceptance Criteria Coverage

| AC | Coverage |
|---|---|
| Home states remain inside MainLoop Shell with same route IDs | Covered by `main_loop_shell_navigation_test.gd` and walkthrough route checks. |
| Warm-town visual direction preserved | Covered by Home card/panel implementation and screenshot review requirement. |
| Production-representative layout for date/phase, next match, team summary, action windows, resources, next action, town warmth | Covered by six Home information cards. |
| Placeholder does not hide critical actions or expose internal/debug labels | Covered by card structure and guardrail text assertions. |
| Match unavailable state gives player-facing reason | Covered by `DisableReason` block, bottom Match disabled-state guard, and navigation test. |
| No new gameplay systems, route IDs, save/event schema, or interaction depth | No route/schema/authority files were changed. |
| Home consumes authoritative payloads only | Implementation reuses `_last_time_payload`, `_last_system_payload`, and `_last_player_action_payload`; no Core queries were added. |
| Stable screenshot review support | Covered by visible-window `mvp_visual_walkthrough_runner.gd` run with 12 saved PNGs and `MVP_VISUAL_WALKTHROUGH_PASS`; headless no-image runs remain structure-only evidence. |
| Focus/hover/disabled states understandable without color alone | Button focus/hover border and disabled reason text provide non-color cues. |
| Existing route guardrails pass | Must be confirmed with the commands above before `/story-done`. |

## Remaining Warnings

- This is a production-representative Home visual exemplar, not a final art pass.
- Headless dummy-renderer screenshot capture emitted no-image warnings; route and structure checks still passed with `MVP_VISUAL_WALKTHROUGH_STRUCTURE_PASS`, while `MVP_VISUAL_WALKTHROUGH_PASS` is intentionally withheld when screenshots are unavailable. Visible-window screenshot capture is required for the full screenshot review marker.
- Remote CI green status is not claimed by this document.
