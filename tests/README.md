# Test Infrastructure

**Engine**: Godot 4.6
**Test Framework**: Custom headless script runner
**CI**: `.github/workflows/tests.yml`
**Setup date**: 2026-05-30

## Directory Layout

```text
tests/
  unit/                 # Isolated unit tests (formulas, state machines, logic)
  integration/          # Cross-system and save/load tests
  manual/               # Manual verification scenes/scripts that require human review
  smoke/                # Critical path checklist for /smoke-check gate
  test_script_runner.gd # Generic headless launcher for any *_test.gd script
```

## Test Shape

This project currently uses a **custom headless test pattern** instead of GdUnit4/GUT.

Each automated test script should:
- extend `Node`
- execute its assertions from `_ready()` or a deterministic setup path
- print a stable `*_TEST_PASS` marker on success
- call `get_tree().quit(0)` on success
- call `get_tree().quit(1)` on failure

Existing story-specific `*_runner.gd` files remain supported, but the standard entry point
for automation is `tests/test_script_runner.gd`.

## Running Tests

Run an individual test:

```bash
/home/kylin/godot/godot --headless --path /home/kylin/little-football-town \
  --script res://tests/test_script_runner.gd -- \
  --test-script=res://tests/unit/player-dev/training_efficiency_formula_test.gd
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
|---|---|---|
| Logic | Automated unit test — must pass | `tests/unit/[system]/` |
| Integration | Automated integration test — must pass | `tests/integration/[system]/` |
| Visual/Feel | Screenshot + lead sign-off | `production/qa/evidence/` |
| UI | Manual walkthrough OR interaction verification | `production/qa/evidence/` or `tests/manual/` |
| Config/Data | Smoke check pass | `production/qa/smoke-*.md` |

## CI

Tests run automatically on every push to `main` and on every pull request.
The workflow enumerates all `*_test.gd` files and runs them through
`tests/test_script_runner.gd` in headless Godot.
