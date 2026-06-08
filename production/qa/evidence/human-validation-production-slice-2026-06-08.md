# Production Slice AI Surrogate Validation

> Date: 2026-06-08  
> Build / commit: `d16c291`  
> Validation type: AI surrogate professional playtest + automated route and readability guardrails  
> Verdict: PASS WITH WARNINGS  
> Current project rule: AI surrogate validation is accepted as effective validation evidence; external-human validation is not required.

## Scope

Validate the current MVP route and decision readability without expanding route topology, `ScreenManager`, gameplay authority, save/event schemas, or Match Live / Halftime command depth.

Reviewed route:

`Home -> Roster -> Player Detail -> Training -> Home -> Match Pre -> Match Live -> Match Result -> Home`

This report retains the earlier human-validation document shape for continuity, but under the current project rule the AI surrogate reviewer is accepted as effective validation evidence and no external-human sample is required for this slice.

## Participants

- Total participants: 1
- External new players: 0
- Familiar management / football game players: 0
- AI surrogate professional game-experience reviewer: 1
- Observation mode: automated Godot interaction tests, scripted route walkthrough, and source-level player-facing copy review

## Route Completion

- Completed full route: 1 / 1 surrogate validation path
- Successfully returned Home: 1 / 1
- Average completion time: automated route, not timed as human play
- Average hint count: 0
- Wrong route observed: none
- Blank page / wrong route / blocking modal observed: none in route assertions

Evidence markers:

```text
L2_PLAYABLE_LOOP_PANELS_TEST_PASS
MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS
WHAT_NEXT_GUIDANCE_TEST_PASS
MVP_VISUAL_WALKTHROUGH_PASS
```

Commands run locally with Godot `4.6.3.stable.official.7d41c59c4`:

```bash
/home/kylin/godot/godot --headless --path /home/kylin/little-football-town --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/l2_playable_loop_panels_test.gd
/home/kylin/godot/godot --headless --path /home/kylin/little-football-town --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/main_loop_shell_navigation_test.gd
/home/kylin/godot/godot --headless --path /home/kylin/little-football-town --script res://tests/test_script_runner.gd -- --test-script=res://tests/integration/ui/what_next_guidance_test.gd
/home/kylin/godot/godot --headless --path /home/kylin/little-football-town --script res://tests/integration/ui/mvp_visual_walkthrough_runner.gd
```

## Decision Readability

- Home understanding: PASS. Home exposes actionable next-step copy and routes non-match planning toward roster / training. Disabled match entry stays on Home and shows a player-facing reason.
- Roster / Player Detail understanding: PASS. Roster rows expose `关注`, `用途`, and `下一步`; Player Detail exposes `用途`, `本轮判断`, `成本/回报`, and `下一步`.
- Training cost / benefit / tradeoff understanding: PASS. Training view preserves authoritative cost, AP cost, return preview, risk / opportunity cost, result line, and next-step anchor.
- Match Pre understanding: PASS. Pre-match summary frames readiness as `赛前检查`, `是否适合开赛`, `判断`, and `下一步`; disabled state gives a player-facing reason.
- Match Live understanding: PASS WITH WARNING. Live view explains `现场状态`, `刚刚重点`, `影响`, and `下一步关注`; timeline events include impact text. Warning remains because live interaction depth is intentionally shallow.
- Match Result understanding: PASS. Result view shows score/result, reason, player performance / league impact, and a clear return-Home next step.

Estimated surrogate readability rates:

- Home: 100%
- Roster / Player Detail: 100%
- Training cost / benefit / tradeoff: 100%
- Match Pre / Live / Result: 100% for route-critical understanding

These rates are automation/surrogate rates only, not external-human statistics.

## Blockers

None found.

Blocker criteria checked:

- Main route can complete.
- Result confirmation returns to Home.
- No route assertion failure occurred.
- Critical buttons have route or explanation behavior.
- Match Pre disabled state exposes a player-facing reason.
- Training and match flows remain request/display layer and do not bypass authority in the tested path.

## Warnings

Readability:

- Some copy is explicit and functional rather than natural; acceptable for MVP validation because it clarifies cost, benefit, risk, and next action.

Visual:

- Not evaluated for final UI or art quality by request. Existing warm-town baseline remains a production-polish warning.

Depth:

- Match Live and Halftime still lack meaningful tactical/player commands. This is a deferred depth warning and should not reopen the frozen MVP topology.

Validation:

- Under the current project rule, external-human validation is not required for this evidence set.
- The Linux headless dummy renderer returned null texture errors while saving PNGs, so this local run did not produce fresh screenshot files. The scripted walkthrough still reached `MVP_VISUAL_WALKTHROUGH_PASS`; screenshot backend failure is treated as an environment warning.
- `xvfb-run` is not installed in the current environment, so a virtual-display screenshot rerun was unavailable.

## Verdict

PASS WITH WARNINGS.

The current Production MVP route is valid for AI-surrogate human-validation format: the full route completes, return Home is confirmed, and the training / match decision explanations are route-critical readable. The warnings are acceptable because they do not block the main loop or require reopening route topology.

## Next

Only fix route, authority, blocker, or return-Home failures if discovered later. Carry environment-warning cleanup, readability polish, visual polish, and Match Live / Halftime depth into later Production polish work.
