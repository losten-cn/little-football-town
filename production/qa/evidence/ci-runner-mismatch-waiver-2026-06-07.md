# CI Runner Mismatch Waiver — Production Gate — 2026-06-07

**Status**: Waived / tracked for Pre-Production → Production gate  
**Gate**: Production gate readiness  
**Classification**: Infrastructure warning, not product behavior blocker  
**Owner**: QA / DevOps / Tools  

## Summary

The current project-standard CI-like runner path reports false negatives for existing `SceneTree`-based tests because `tests/test_script_runner.gd` expects test scripts that instantiate as `Node`.

This waiver allows the Pre-Production → Production gate to pass with warnings because:

- The failure mode is a known runner/base-class mismatch.
- It is not an assertion failure in product behavior.
- Compatible execution previously passed all known automated test assets.
- Focused UI route tests and MVP visual walkthrough pass after the player-experience focused revision.

This waiver does **not** claim the standard CI-like baseline is green.

## Observed Prior CI-like Runner Result

```text
AUTOMATED_TEST_BASELINE_SUMMARY passed=32 failed=37 total=69
ERROR: Test script must extend Node: res://...
```

## Root Cause

- `tests/test_script_runner.gd` accepts scripts that extend/instantiate as `Node`.
- 37 existing tests extend `SceneTree` and are designed to run directly via Godot `--script`.
- Running those direct `SceneTree` scripts through the Node-only runner produces false-negative infrastructure failures.

## Compatible Baseline Evidence

The compatible policy is:

- `extends Node` tests: run through `res://tests/test_script_runner.gd`.
- `extends SceneTree` tests: run directly via `--script res://...`.

Previously observed result:

```text
COMPATIBLE_AUTOMATED_TEST_BASELINE_SUMMARY passed=69 failed=0 total=69 elapsed=18.26s modes={'node_runner': 32, 'direct_scene_tree': 37}
COMPATIBLE_AUTOMATED_TEST_BASELINE_PASS
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

- **Waiver**: Approved for this Pre-Production → Production gate.
- **Reason**: The mismatch is a test infrastructure execution-mode issue, not a product behavior failure, and gate-critical UI route evidence is green.
- **Restriction**: Do not claim the standard CI-like runner baseline is green until this mismatch is fixed or the official CI policy supports both Node and SceneTree tests.

## Required Follow-up

Before claiming standard automated baseline green in CI:

1. Update the test execution workflow to route `Node` and `SceneTree` scripts through compatible modes, or migrate tests to a single standard base class.
2. Re-run the full automated suite through the official workflow.
3. Replace this waiver with a passing CI evidence file.

## Gate Impact

- **Production gate blocker?** No, waived/tracked for this gate.
- **Carry-forward warning?** Yes.
- **Blocks future claim of standard CI-like green baseline?** Yes, until fixed or policy updated.
