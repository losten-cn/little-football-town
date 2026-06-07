# CI Runner Mismatch Waiver — Production Gate — 2026-06-07

**Status**: Resolved locally / remote CI not claimed  
**Gate**: Production gate readiness  
**Classification**: Historical infrastructure warning, no longer a local standard-baseline blocker  
**Owner**: QA / DevOps / Tools  

## Summary

The prior project-standard CI-like runner path reported false negatives for existing `SceneTree`-based tests because `tests/test_script_runner.gd` expects test scripts that instantiate as `Node`.

This risk is now resolved for local standard-baseline evidence because the active workflow policy routes tests by base class:

- `extends Node` tests run through `res://tests/test_script_runner.gd`.
- `extends SceneTree` tests run directly via `--script res://...`.
- A local full-baseline rerun using that same routing passed all known automated test assets.
- Focused UI route tests and MVP visual walkthrough pass after the player-experience focused revision.

This evidence does **not** claim that remote GitHub Actions has run green on the current branch; it only closes the local standard-baseline mismatch that previously required a waiver.

## Observed Prior CI-like Runner Result

```text
AUTOMATED_TEST_BASELINE_SUMMARY passed=32 failed=37 total=69
ERROR: Test script must extend Node: res://...
```

## Root Cause

- `tests/test_script_runner.gd` accepts scripts that extend/instantiate as `Node`.
- 37 existing tests extend `SceneTree` and are designed to run directly via Godot `--script`.
- Running those direct `SceneTree` scripts through the Node-only runner produces false-negative infrastructure failures.

## Standard Split-Runner Baseline Evidence

The standard local policy now matches `.github/workflows/tests.yml` routing:

- `extends Node` tests: run through `res://tests/test_script_runner.gd`.
- `extends SceneTree` tests: run directly via `--script res://...`.

Previously observed compatible result:

```text
COMPATIBLE_AUTOMATED_TEST_BASELINE_SUMMARY passed=69 failed=0 total=69 elapsed=18.26s modes={'node_runner': 32, 'direct_scene_tree': 37}
COMPATIBLE_AUTOMATED_TEST_BASELINE_PASS
```

Current local standard split-runner result:

```text
STANDARD_AUTOMATED_TEST_BASELINE_SUMMARY node=32 scenetree=37 passed=69 failed=0 total=69 elapsed=19.00s
STANDARD_AUTOMATED_TEST_BASELINE_PASS
```

## Focused Gate Rerun Evidence

After the focused display-layer revision and final typed-boundary cleanup, the gate-critical UI route checks pass:

```text
MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS
L2_PLAYABLE_LOOP_PANELS_TEST_PASS
WHAT_NEXT_GUIDANCE_TEST_PASS
MVP_VISUAL_WALKTHROUGH_PASS
```

Additional rerun after typed-boundary cleanup:

```text
L2_PLAYABLE_LOOP_PANELS_TEST_PASS
MVP_VISUAL_WALKTHROUGH_PASS
```

## Waiver Decision

- **Original waiver**: Approved for this Pre-Production → Production gate.
- **Current local status**: Resolved by using the same Node/SceneTree split-runner policy recorded in `.github/workflows/tests.yml`.
- **Reason**: The mismatch was a test infrastructure execution-mode issue, not a product behavior failure, and the local standard split-runner baseline now passes 69/69.
- **Restriction**: Do not claim remote GitHub Actions green status until the workflow has actually run and produced passing checks for the current branch.

## Required Follow-up

Before claiming remote CI green:

1. Run or observe the GitHub Actions workflow for the current branch.
2. Confirm the workflow uses Node/SceneTree split routing and reports zero failures.
3. Archive that remote CI evidence if a future gate requires remote-check proof.

## Gate Impact

- **Production gate blocker?** No.
- **Carry-forward local baseline warning?** No; local standard split-runner baseline passed 69/69.
- **Remote CI claim available?** No; remote GitHub Actions green status is not claimed by this local evidence.
