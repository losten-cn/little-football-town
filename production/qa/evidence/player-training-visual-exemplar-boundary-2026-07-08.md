# Player / Training Visual Exemplar Boundary — 2026-07-08

> **Story**: `production/epics/player-management-ui/story-002-player-training-visual-exemplar-boundary.md`  
> **Sprint**: Sprint 3 — Production Visual Follow-through  
> **Result**: PASS WITH WARNINGS  
> **Scope**: Roster / Player Detail / Training visual-boundary pass only

## Scope

This evidence records the minimum Player / Training visual-boundary pass for the Production follow-through slice.

In scope:

- Roster row readability and scan-friendly grouping.
- Player Detail hierarchy for identity, attributes, growth, status, and action entry.
- Training entry / confirmation readability and disabled-state explanation.
- Warm-town readable panel treatment aligned with the Home exemplar pass.
- Placeholder tolerance check for reviewed Player / Training states.
- Existing route guardrails and walkthrough coverage for roster → detail → training.

Out of scope:

- No `ScreenManager` changes.
- No new route IDs.
- No gameplay authority changes.
- No save/event schema changes.
- No new sorting/filtering systems.
- No new training mechanics, ROI logic, or player-detail depth.
- No final production art claim.

## Implemented Changes

- Roster rows were reorganized into a more scan-friendly multi-line structure that keeps authoritative identity, rating, state, growth, attention, role, and next-step cues readable without turning the list into a spreadsheet.
- Player Detail was rewritten into clearer visual sections for identity, attributes, growth, status, usage, and cost/return context while preserving the existing training handoff.
- Training entry and confirmation text now present player-facing disabled or unavailable language rather than a silent generic lock.
- Player / Training visual states keep the warm-town cream surface, restrained accent borders, and explicit focus/disabled differentiation established by the Home visual exemplar pass.
- Placeholder copy was tightened to avoid internal/debug-facing phrasing in the reviewed Player / Training flow.

## Placeholder Boundary Verification

| Rule | Status | Notes |
|---|---|---|
| No blank roster / detail / training main panel | PASS | Reviewed states mount visible summary content inside the existing shell. |
| No internal IDs / debug labels / enum-like text in reviewed Player / Training states | PASS BY TEST INTENT | Updated copy and walkthrough states do not expose debug/internal labels in the reviewed surfaces. |
| Placeholder does not hide critical actions | PASS | Roster row selection, training entry, and return controls remain visible. |
| Placeholder does not imply false interaction | PASS | Read-only text remains visually distinct from actual CTA buttons. |
| Return path remains visible / stable | PASS | Existing roster → detail → training → home flow is unchanged. |
| Warm-town direction preserved | PASS WITH WARNINGS | Readable and aligned with Home exemplar, but still not a final art pass. |

## Walkthrough States Reviewed

The walkthrough runner reviewed these Player / Training states within the existing MVP route:

- `02_roster`
- `03_player_detail`
- `04_training`
- `05_training_result`

Visible-window screenshot output directory:

- `/home/kylin/.local/share/godot/app_userdata/Football Town/mvp_visual_walkthrough`

Key screenshots:

- `02_roster.png`
- `03_player_detail.png`
- `04_training.png`
- `05_training_result.png`

## Automated Guardrails

Fresh local verification was run with Godot `v4.6.3.stable.official.7d41c59c4`:

```text
/home/kylin/godot/godot --headless --path /home/kylin/little-football-town --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/l2_playable_loop_panels_test.gd
/home/kylin/godot/godot --headless --path /home/kylin/little-football-town --script res://tests/integration/ui/mvp_visual_walkthrough_runner.gd
/home/kylin/godot/godot --path /home/kylin/little-football-town --script res://tests/integration/ui/mvp_visual_walkthrough_runner.gd
```

Observed markers:

- `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`
- `MVP_VISUAL_WALKTHROUGH_SCREENSHOT_UNAVAILABLE=headless renderer produced no screenshot artifacts`
- `MVP_VISUAL_WALKTHROUGH_STRUCTURE_PASS`
- `MVP_VISUAL_WALKTHROUGH_PASS`

Visible-window screenshot markers generated:

- `MVP_VISUAL_WALKTHROUGH_SCREENSHOT=/home/kylin/.local/share/godot/app_userdata/Football Town/mvp_visual_walkthrough/02_roster.png`
- `MVP_VISUAL_WALKTHROUGH_SCREENSHOT=/home/kylin/.local/share/godot/app_userdata/Football Town/mvp_visual_walkthrough/03_player_detail.png`
- `MVP_VISUAL_WALKTHROUGH_SCREENSHOT=/home/kylin/.local/share/godot/app_userdata/Football Town/mvp_visual_walkthrough/04_training.png`
- `MVP_VISUAL_WALKTHROUGH_SCREENSHOT=/home/kylin/.local/share/godot/app_userdata/Football Town/mvp_visual_walkthrough/05_training_result.png`

## Acceptance Criteria Coverage

| AC | Coverage |
|---|---|
| Player / Training states remain inside MainLoop Shell with same route IDs and return paths | Covered by `l2_playable_loop_panels_test.gd` and walkthrough route checks. |
| Roster rows remain scan-friendly and production-representative | Covered by updated roster row formatting and walkthrough screenshot `02_roster.png`. |
| Player Detail preserves readable warm-town hierarchy | Covered by sectioned summary layout and walkthrough screenshot `03_player_detail.png`. |
| Training disabled / unavailable states are player-facing | Covered by updated training entry text, disabled option text, and `l2_playable_loop_panels_test.gd` assertions. |
| No placeholder exposes internal/debug labels or route ambiguity | Covered by reviewed screenshot states and placeholder boundary checks. |
| Authoritative payloads remain read-only UI inputs | Covered by code scope review; no new gameplay truth recomputation was introduced in this pass. |
| Focus / hover / selected / disabled states remain understandable without color alone | Covered by retained button borders, disabled readability, and explicit text anchors on actionable states. |
| No new gameplay systems, routes, or schema contracts | Covered by file scope and implementation boundary review. |
| Screenshot / walkthrough evidence exists for reviewed Player / Training states | Covered by visible-window walkthrough PNG output and `MVP_VISUAL_WALKTHROUGH_PASS`. |
| Existing route and handoff guardrails still pass | Covered by `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`. |

## Remaining Warnings

- This is a production-representative Player / Training exemplar pass, not a final art pass.
- The walkthrough still shares the existing MVP route runner rather than a Player-only dedicated runner.
- Headless screenshot capture remains structure-only evidence; visible-window capture is the authoritative screenshot review path.
- `MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS` was not re-run specifically for this story slice because the implementation stayed inside the Player / Training panel and the dedicated `L2_PLAYABLE_LOOP_PANELS_TEST_PASS` route/handoff guardrail remained green.
