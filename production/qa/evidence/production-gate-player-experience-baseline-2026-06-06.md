# Production Gate Player Experience Baseline — 2026-06-06

> Result: HOLD / NEEDS REVISION
> Scope: MVP player-experience readiness for entering Production
> Tester: Claude as professional game experience tester + QA/UX review support
> Platform: Windows 11 / Godot 4.6.2 console
> Review Mode: lean

## Executive Verdict

Production entry should pause for a focused revision slice.

The MVP loop is route-complete and visually reviewable, and all automated test assets pass when executed with a runner mode compatible with each test script's base class. However, UX sign-off is **NEEDS REVISION**, and the current project-standard CI-like runner path produces false negatives for SceneTree-based tests. The build should not be presented as fully Production-ready until the player-facing text/layout issues and test-runner infrastructure mismatch are addressed.

## Evidence Summary

| Gate Item | Result | Notes |
|---|---:|---|
| Existing playtest report | PASS WITH WARNINGS | `production/qa/playtests/playtest-2026-06-06-player-experience.md` |
| Visible MVP walkthrough | PASS | `MVP_VISUAL_WALKTHROUGH_PASS`; 12 screenshots reviewed |
| Compatible full automated baseline | PASS | 69/69 pass; 32 Node-runner tests + 37 direct SceneTree tests |
| CI-like project-standard runner baseline | FAIL / INFRA | 32 pass / 37 fail; failures are `Test script must extend Node`, not assertion failures |
| UX sign-off | NEEDS REVISION | No hard route blocker, but player-facing UX hygiene and Home information architecture are below Production sign-off bar |
| QA gate opinion | PASS WITH WARNINGS | Product behavior evidence is acceptable; CI/test infrastructure must be fixed or formally tracked |

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

### Screenshots Reviewed

| Step | Screenshot | Expected | Result | Notes |
|---|---|---|---|---|
| 01 | `01_home_initial.png` | Home initial | PASS WITH WARNINGS | Clear next step, but greybox presentation and incomplete MVP Home information set |
| 02 | `02_roster.png` | Roster | PASS WITH WARNINGS | Route works; onboarding exposes `RosterList` target ID |
| 03 | `03_player_detail.png` | Player Detail | PASS WITH WARNINGS | Multiple placeholder/sync labels reduce trust |
| 04 | `04_training.png` | Training | PASS WITH WARNINGS | Training action is available; target ID is player-visible |
| 05 | `05_training_result.png` | Training Result | PASS | `High` training result and +2 growth feedback are clear |
| 06 | `06_home_after_training.png` | Home after training | PASS | Training feedback returns to Home successfully |
| 07 | `07_home_match_disabled_reason.png` | Disabled match reason | PASS WITH WARNINGS | Shows `阵容不合法`, but lacks specific actionable reason |
| 08 | `08_match_pre.png` | Match Pre | PASS WITH WARNINGS | Text wraps severely; scan cost is too high for light-management UX |
| 09 | `09_match_live_empty.png` | Match Live initial | PASS WITH WARNINGS | `比分待同步` / `时间待同步` weakens confidence that the match has started |
| 10 | `10_match_live_timeline.png` | Match Live timeline | PASS WITH WARNINGS | Timeline appears, but match feel is static and placeholder-like |
| 11 | `11_match_result.png` | Match Result | PASS WITH WARNINGS | Result loop is complete; `home_win` internal enum is player-visible |
| 12 | `12_home_final.png` | Home final | PASS | Final Home return works |

### Visual Verdict

PASS WITH WARNINGS.

No black screen, blank page, wrong route, blocking modal, payload handoff blocker, or failure to return Home was observed. The route is usable as an MVP topology baseline, but player-facing copy and readability are not Production-signoff quality.

## Automated Test Baseline

### CI-like Project-Standard Runner Baseline

The current project-standard CI-like execution path runs every `tests/unit/**/*_test.gd` and `tests/integration/**/*_test.gd` through `res://tests/test_script_runner.gd`.

Observed result:

```text
AUTOMATED_TEST_BASELINE_SUMMARY passed=32 failed=37 total=69
```

All 37 failures share the same infrastructure error:

```text
ERROR: Test script must extend Node: res://...
```

Root cause: `tests/test_script_runner.gd` only accepts scripts that instantiate as `Node`, while 37 existing tests extend `SceneTree` and are designed to run directly via Godot `--script`.

QA interpretation: this is a test infrastructure false-negative, not evidence of 37 product behavior failures. It still blocks any claim that the current CI-like standard runner baseline is green.

### Compatible Full Baseline

A compatible full baseline was run with this policy:

- `extends Node` tests: run through `res://tests/test_script_runner.gd`.
- `extends SceneTree` tests: run directly via `--script res://...`.

Observed result:

```text
COMPATIBLE_AUTOMATED_TEST_BASELINE_SUMMARY passed=69 failed=0 total=69 elapsed=18.26s modes={'node_runner': 32, 'direct_scene_tree': 37}
COMPATIBLE_AUTOMATED_TEST_BASELINE_PASS
```

QA interpretation: the automated test assets themselves are green under their compatible execution modes.

## UX Sign-off Summary

UX sign-off verdict: **NEEDS REVISION**.

No hard UX blocker was found for route completion:

- No black/blank screen.
- No broken critical route.
- No blocking modal.
- No inability to return Home.
- No obvious deadlock in the walked MVP path.

However, the current player-facing presentation is below Production sign-off quality:

1. Internal IDs and developer-facing strings are visible to players: `RosterList`, `TrainingConfirmButton`, `PreMatchStartButton`, `ResultConfirmButton`, `home_win`.
2. Placeholder/sync text is visible in core screens: `属性待同步`, `成长待同步`, `状态待同步`, `比分待同步`, `时间待同步`.
3. Home does not yet fully prove the MVP main-loop UI minimum information architecture, especially core resources and minimum town presence.
4. Match Pre readability is too poor for the light-management pillar.
5. The pixel-town cultivation pillar is barely represented in the current Home/player loop.

## Pillar Alignment

| Pillar | Assessment | Evidence |
|---|---|---|
| 轻度足球经营 | Partially aligned | Clear route and next-step guidance, but disabled-state reasons and pre-match readability need revision |
| 像素小镇养成 | Weak | Current UI is mostly functional greybox; minimum town identity/presence is not yet validated |
| 低压力长期成长 | Mostly aligned with warnings | Training feedback and route friction are good; placeholder text weakens trust in growth feedback |

## Production-Blocking Revision Items

These should be addressed before claiming Production entry:

1. Replace all player-visible internal IDs/enums/debug strings with player-facing copy.
2. Remove or replace placeholder sync text from Player Detail, Training, Match Live, and Match Result.
3. Make Home satisfy the MVP minimum information set: current phase, next match, team summary, action windows, core resources, and a minimum town summary/building touchpoint.
4. Give disabled match states actionable reasons, not only `阵容不合法`.
5. Fix Match Pre layout so opponent, round, home/away, ranking summary, lineup summary, and tactic summary are readable.
6. Fix the test-runner / CI workflow mismatch so the project-standard automated baseline can go green without a custom compatibility harness.

## Non-blocking Warnings / Polish Backlog

- Strengthen Match Live emotion with larger score display, phase title, and key-event cards.
- Improve Player Detail as an emotional connection point for player development.
- Strengthen training-to-match causality in result copy.
- Clarify top menu and bottom tab navigation affordance.
- Explain why Home says 8-player roster while Roster shows only the currently surfaced subset.
- Add stronger pixel-town warmth and belonging in Home and loop return states.

## Recommended Gate Decision

Do not mark the project as fully ready to enter Production yet.

Recommended next state: **Production-prep focused revision**.

Minimum retest checklist after revision:

1. Re-run visible MVP walkthrough.
2. Re-run compatible full automated baseline.
3. Re-run the project-standard CI-like baseline after runner/workflow fix.
4. Re-run UX sign-off.
5. Update this evidence file or create a new dated follow-up evidence file with the revised verdict.
