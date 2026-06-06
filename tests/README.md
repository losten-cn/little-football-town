# Test Infrastructure

**Engine**: Godot 4.6
**Test Framework**: Custom headless dispatch with Node runner + direct SceneTree tests
**CI**: `.github/workflows/tests.yml`
**Setup date**: 2026-05-30

## Directory Layout

```text
tests/
  unit/                 # Isolated unit tests (formulas, state machines, logic)
  integration/          # Cross-system and save/load tests
  manual/               # Manual verification scenes/scripts that require human review
  smoke/                # Critical path checklist for /smoke-check gate
  test_script_runner.gd # Node-only headless launcher for Node-based *_test.gd scripts
```

## Test Shape

This project currently uses a **custom headless test pattern** instead of GdUnit4/GUT.
Automated `*_test.gd` scripts may use one of two supported shapes:

- `extends Node` — for tests mounted into an existing `SceneTree` by `tests/test_script_runner.gd`.
- `extends SceneTree` — for full-tree tests that own setup, frame advancement, and process exit directly.

Each automated test script should:

- execute assertions from `_ready()` (`Node`) or `_initialize()` (`SceneTree`) through a deterministic setup path
- print a stable `*_TEST_PASS` marker on success
- exit with code `0` on success
- exit with code `1` on assertion failure

Existing story-specific `*_runner.gd` files remain supported. The standard automation policy
is to dispatch by the first `extends` line: `Node` tests use `tests/test_script_runner.gd`,
and `SceneTree` tests run directly with `--script`.

## Running Tests

Run an individual `Node` test through the Node-only launcher:

```bash
/home/kylin/godot/godot --headless --path /home/kylin/little-football-town \
  --script res://tests/test_script_runner.gd -- \
  --test-script=res://tests/unit/player-dev/training_efficiency_formula_test.gd
```

Run an individual `SceneTree` test directly:

```bash
/home/kylin/godot/godot --headless --path /home/kylin/little-football-town \
  --script res://tests/unit/time/action_window_formula_test.gd
```

Run a story-specific runner directly if needed:

```bash
/home/kylin/godot/godot --headless --path /home/kylin/little-football-town \
  --script res://tests/integration/save/save_summary_performance_runner.gd
```

## Test Naming

- **Files**: `[system]_[feature]_test.gd`
- **Functions**: `test_[system]_[scenario]_[expected_result]`
- **Example**: `training_efficiency_formula_test.gd` → `test_training_efficiency_low_condition_clamps_lower_bound()`

## Story Type → Test Evidence

| Story Type | Required Evidence | Location |
| --- | --- | --- |
| Logic | Automated unit test — must pass | `tests/unit/[system]/` |
| Integration | Automated integration test — must pass | `tests/integration/[system]/` |
| Visual/Feel | Screenshot + lead sign-off | `production/qa/evidence/` |
| UI | Manual walkthrough OR interaction verification | `production/qa/evidence/` or `tests/manual/` |
| Config/Data | Smoke check pass | `production/qa/smoke-*.md` |

## CI

Tests run automatically on every push to `main` and on every pull request.
The workflow enumerates all `*_test.gd` files, reads each file's first `extends`
line, and dispatches supported tests in headless Godot:

- `extends Node` tests run through `tests/test_script_runner.gd`.
- `extends SceneTree` tests run directly with `--script`.
- Missing or unsupported base classes fail fast.
