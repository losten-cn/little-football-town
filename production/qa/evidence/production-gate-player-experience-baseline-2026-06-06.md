# Production Gate Player Experience Baseline — 2026-06-06

> Result: READY / PASS WITH WARNINGS after focused revision rerun  
> Scope: MVP player-experience readiness for entering Production  
> Tester: Claude as professional game experience tester + QA/UX review support  
> Platform: Windows 11 / Godot 4.6.2 console  
> Review Mode: lean  
> Rereview Date: 2026-06-07

## Executive Verdict

Production entry no longer needs to pause on player-experience route quality under the project’s accepted warning policy.

The MVP loop is route-complete, visually reviewable, and the focused display-layer revision addressed the earlier UX sign-off concerns that were blocking this evidence package: Home information architecture, actionable match-state copy, Player/Training decision clarity, and Match Pre/Live/Result readability. The UX rereview now signs off as **PASS WITH WARNINGS / READY WITH WARNINGS**.

Remaining issues are warnings or separately scoped compliance/infrastructure items, not route-level player-experience blockers.

## Evidence Summary

| Gate Item | Result | Notes |
|---|---:|---|
| Accepted AI-agent surrogate playtest | PASS WITH WARNINGS | `production/qa/evidence/mvp-human-playtest-production-gate-2026-06-06.md`; accepted as Production gate substitute, external-human claim not made |
| Visible MVP walkthrough | PASS | `MVP_VISUAL_WALKTHROUGH_PASS`; 12 screenshots reviewed after focused revision |
| Focused UI route regression | PASS | `MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS`, `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`, `WHAT_NEXT_GUIDANCE_TEST_PASS` |
| UX sign-off | PASS WITH WARNINGS | `production/qa/evidence/ux-review-production-gate-2026-06-06.md` rereviewed after focused revision |
| Compatible full automated baseline | PASS | Earlier compatible mode passed 69/69 |
| Local standard split-runner baseline | PASS | Current local Node/SceneTree split-routing baseline passed 69/69; remote GitHub Actions green status is not claimed |
| QA gate opinion | PASS WITH WARNINGS | Product behavior evidence is acceptable; no new route blocker observed |

## Focused Revision Summary

The focused revision was intentionally display-layer-only and topology preserving.

| Topology Slice | File | Player-Experience Change |
|---|---|---|
| L1 Home information / warm-town presentation | `src/ui/hud/main_loop_shell.gd` | Home now surfaces resources, action context, town warmth, direct next action, and visible match-block reason. |
| L2 Player / Training decision clarity | `src/ui/player/player_mgmt_panel.gd` | Player Detail / Training now explain why to train, what training affects, and when payoff should appear. |
| L2 Match readability / agency perception | `src/ui/match/match_perf_panel.gd` | Match Pre / Live / Result now show pre-match judgment, live outlook/current operation, result interpretation, and next-step guidance. |

Guardrails kept:

- No route ID changes.
- No `ScreenManager` changes.
- No core gameplay authority changes.
- No new tactical/training systems.
- UI remains display-only: it consumes authoritative payloads and emits request events.

## Visual Walkthrough Evidence

### Command

```bash
"D:/Program Files/godot/Godot_v4.6.2-stable_win64_console.exe" --path "E:/code/little-football-town" --script res://tests/integration/ui/mvp_visual_walkthrough_runner.gd
```

### Result

```text
MVP_VISUAL_WALKTHROUGH_PASS
MVP_VISUAL_WALKTHROUGH_OUTPUT_DIR=C:/Users/kylin/AppData/Roaming/Godot/app_userdata/Football Town/mvp_visual_walkthrough
```

### Screenshots Reviewed After Focused Revision

| Step | Screenshot | Expected | Result | Notes |
|---|---|---|---|---|
| 01 | `01_home_initial.png` | Home initial | PASS WITH WARNINGS | Home now includes phase/resources, town warmth, action context, and clear next step. Low-fidelity visuals remain a warning. |
| 02 | `02_roster.png` | Roster | PASS WITH WARNINGS | Route works; roster sorting/filtering remains deferred. |
| 03 | `03_player_detail.png` | Player Detail | PASS WITH WARNINGS | Player detail now explains training rationale, impact, and payoff timing. Deeper attributes remain a warning. |
| 04 | `04_training.png` | Training | PASS WITH WARNINGS | Training action and rationale are clear; training choice depth remains intentionally thin. |
| 05 | `05_training_result.png` | Training Result | PASS | Training result and growth feedback are clear. |
| 06 | `06_home_after_training.png` | Home after training | PASS | Training feedback returns to Home successfully. |
| 07 | `07_home_match_disabled_reason.png` | Disabled match reason | PASS WITH WARNINGS | Disabled state now provides clearer visible reasoning; deeper lineup tooling remains deferred. |
| 08 | `08_match_pre.png` | Match Pre | PASS WITH WARNINGS | Pre-match judgment, lineup state, tactic, and next step are readable. |
| 09 | `09_match_live_empty.png` | Match Live initial | PASS WITH WARNINGS | Live screen now frames outlook/current operation; match agency remains shallow. |
| 10 | `10_match_live_timeline.png` | Match Live timeline | PASS WITH WARNINGS | Timeline appears with clearer context; halftime command depth remains warning. |
| 11 | `11_match_result.png` | Match Result | PASS WITH WARNINGS | Result interpretation, performance summary, league impact, and next-step guidance are visible. |
| 12 | `12_home_final.png` | Home final | PASS | Final Home return works. |

### Visual Verdict

PASS WITH WARNINGS.

No black screen, blank page, wrong route, blocking modal, payload handoff blocker, or failure to return Home was observed. The route is usable as the MVP Production gate player-experience baseline, with polish/depth warnings carried forward.

## Automated Test Baseline

### Focused UI Regression Rerun

```text
MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS
L2_PLAYABLE_LOOP_PANELS_TEST_PASS
WHAT_NEXT_GUIDANCE_TEST_PASS
MVP_VISUAL_WALKTHROUGH_PASS
```

A follow-up typed-boundary safety fix in `src/ui/player/player_mgmt_panel.gd` was also rerun through:

```text
L2_PLAYABLE_LOOP_PANELS_TEST_PASS
MVP_VISUAL_WALKTHROUGH_PASS
```

### Automated Baseline

Earlier compatible full baseline policy:

- `extends Node` tests: run through `res://tests/test_script_runner.gd`.
- `extends SceneTree` tests: run directly via `--script res://...`.

Observed earlier result:

```text
COMPATIBLE_AUTOMATED_TEST_BASELINE_SUMMARY passed=69 failed=0 total=69 elapsed=18.26s modes={'node_runner': 32, 'direct_scene_tree': 37}
COMPATIBLE_AUTOMATED_TEST_BASELINE_PASS
```

A current local standard split-runner rerun used the same Node/SceneTree routing recorded in `.github/workflows/tests.yml` and passed:

```text
STANDARD_AUTOMATED_TEST_BASELINE_SUMMARY node=32 scenetree=37 passed=69 failed=0 total=69 elapsed=19.00s
STANDARD_AUTOMATED_TEST_BASELINE_PASS
```

QA interpretation: the automated test assets are green under the current local standard split-runner policy. This closes the local SceneTree-vs-Node runner mismatch as a player-experience baseline warning, but it does not claim remote GitHub Actions green status for the current branch.

## UX Sign-off Summary

UX sign-off verdict: **PASS WITH WARNINGS / READY WITH WARNINGS**.

No hard UX blocker remains for route completion:

- No black/blank screen.
- No broken critical route.
- No blocking modal.
- No inability to return Home.
- No obvious deadlock in the walked MVP path.
- Critical next actions and disabled states are now player-facing enough for this gate.
- Match Pre/Live/Result readability is acceptable for Production entry with warnings.

Earlier concerns have been reduced:

1. Player-visible internal IDs/enums/placeholders are no longer observed as blockers in the revised critical screenshot path.
2. Home now demonstrates the MVP main-loop information set: phase, resources, action context, next match, team summary, and minimum town presence.
3. Match disabled state and Match Pre readability have been improved.
4. Player Detail / Training now provides enough decision rationale for the MVP loop.
5. Match Result now communicates outcome, performance, league impact, and next step.

## Pillar Alignment

| Pillar | Assessment | Evidence |
|---|---|---|
| 轻度足球经营 | Aligned with warnings | Clear route, readable pre-match/result state, and training-to-match loop; deeper tactics remain deferred |
| 像素小镇养成 | Partially aligned with warnings | Home now has minimum town warmth/presence; visual fidelity and stronger pixel-town identity remain future polish |
| 低压力长期成长 | Aligned with warnings | Training rationale, result feedback, and return-to-Home loop are understandable; deeper long-term progression presentation remains backlog |

## Remaining Warnings / Polish Backlog

These are non-blocking for the current gate. The 2026-06-07 Production convergence pass is archived in `production/qa/evidence/production-gate-convergence-2026-06-07.md`.

### Reduced by first Production convergence batch

- Roster/player next-action clarity — roster rows now explain attention reason, usage, and next step in the walked MVP path.
- Player Detail training judgment — detail view now explains current usage, training rationale, impact, payoff timing, and recommended action.
- Training ROI/tradeoff readability — training view now shows selected option, cost, benefit, risk/tradeoff, payoff timing, next step, and result.
- Match Pre / Live / Result readability — match screens now show checklist framing, current focus, impact language, result interpretation, and next-step guidance.
- Warm town-light UI baseline — global UI styling now favors warm/light town panels and deep-brown text; dark treatment is reserved for local high-tension match contexts.

### Carried forward as Production warnings

- Low-fidelity placeholder visual presentation and final pixel-art production quality.
- Roster sorting/filtering depth.
- Player emotional attachment and deeper attribute presentation.
- Match Live moment-to-moment emotion and information hierarchy beyond the current readable baseline.
- Full localization key coverage beyond the reviewed route.
- Onboarding persistence / cooldowns / replay / analytics / anchor registry.
- Strict external-human participant validation, if a future gate owner requires it separately from the accepted AI-agent surrogate playtest substitute.
- CI-like test-runner infrastructure mismatch unless fixed or waived in gate-readiness documentation.

### Deferred warning, not current scope

- Match Live / Halftime command depth. Real halftime commands should wait for a dedicated gameplay/technical story because they may require new tactical command semantics, UI-to-simulation contracts, or save/event schema implications.

## Recommended Gate Decision

Mark the player-experience baseline as **READY / PASS WITH WARNINGS**.

Recommended next state: **Production gate-readiness convergence**.

Minimum next checklist:

1. Keep route topology frozen.
2. Do not expand roster, training, match, onboarding, or town-building scope before gate close.
3. Update gate-readiness documentation to reference this revised verdict and UX rereview.
4. Either fix or explicitly waive/track the CI-like runner mismatch.
5. Treat external-human playtest as optional/future validation unless gate ownership changes the accepted AI-agent surrogate policy.
