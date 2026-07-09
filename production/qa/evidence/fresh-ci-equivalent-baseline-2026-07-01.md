# Fresh CI-equivalent Automated Baseline — 2026-07-01

> **Result**: PASS
> **Scope**: Full local CI-equivalent automated baseline for current worktree
> **Engine**: Godot Engine v4.6.3.stable.official.7d41c59c4
> **Remote CI status**: Not claimed

## Purpose

Record a fresh full automated baseline after the 2026-07-01 architecture source-of-truth convergence and derived-artifact refresh.

This evidence addresses the Production gate concern that current fresh verification previously covered key route/UI guardrails only, not a full CI-equivalent automated suite rerun.

## CI-equivalent Dispatch Rule

This local run mirrored `.github/workflows/tests.yml`:

- Enumerate all `*_test.gd` files under:
  - `tests/unit`
  - `tests/integration`
- Read each file's first `extends` line.
- Dispatch by base class:
  - `extends Node` → run through `res://tests/test_script_runner.gd`
  - `extends SceneTree` → run directly with `--script`
- Unsupported or missing base classes count as failures.

## Command

```bash
set -uo pipefail
cd /home/kylin/little-football-town
mkdir -p test-logs/fresh-ci-equivalent-2026-07-01
fail_count=0
node_count=0
scenetree_count=0

while IFS= read -r test_file; do
  test_res_path="res://${test_file#./}"
  log_file="test-logs/fresh-ci-equivalent-2026-07-01/$(basename "${test_file%.gd}").log"
  base_class="$(grep -m1 -E '^[[:space:]]*extends[[:space:]]+' "$test_file" | awk '{print $2}')"

  case "$base_class" in
    Node)
      node_count=$((node_count + 1))
      /home/kylin/godot/godot --headless --path /home/kylin/little-football-town \
        --script res://tests/test_script_runner.gd -- \
        --test-script="$test_res_path" 2>&1 | tee "$log_file"
      ;;
    SceneTree)
      scenetree_count=$((scenetree_count + 1))
      /home/kylin/godot/godot --headless --path /home/kylin/little-football-town \
        --script "$test_res_path" 2>&1 | tee "$log_file"
      ;;
    *)
      echo "Unsupported test base class for ${test_res_path}: ${base_class:-missing extends}" | tee "$log_file"
      fail_count=$((fail_count + 1))
      ;;
  esac
done < <(find ./tests/unit ./tests/integration -type f -name '*_test.gd' | sort)

echo "STANDARD_AUTOMATED_TEST_BASELINE_SUMMARY node=${node_count} scenetree=${scenetree_count} failed=${fail_count} total=$((node_count + scenetree_count))"
```

## Result Summary

```text
STANDARD_AUTOMATED_TEST_BASELINE_SUMMARY node=34 scenetree=37 failed=0 total=71
STANDARD_AUTOMATED_TEST_BASELINE_PASS
```

## Interpretation

The current worktree passes the full local CI-equivalent automated baseline:

- Node-dispatched tests: 34
- SceneTree-dispatched tests: 37
- Total automated tests: 71
- Failed tests: 0

This closes the specific gate concern that fresh evidence covered only key route/UI guardrails.

## Warnings / Non-claims

- This evidence does not claim remote GitHub Actions green status.
- Several tests still emit Godot exit-time ObjectDB/resource leak or resource-in-use warnings.
- Some SaveManager negative-path tests intentionally emit error logs while validating failure handling.
- These warnings did not fail the CI-equivalent baseline and all tested scripts completed with their expected pass markers.

## Gate Impact

This evidence materially improves the Technical Director concern for the 2026-07-01 Production gate.

It does not by itself make the gate clean READY because the following concerns remain:

1. Accepted-but-unscheduled systems still need explicit story/test chains or documented deferral:
   - Random Event
   - Audio
   - Skill/Trait
   - Reputation/Achievement
   - Town UI
   - Tutorial/Hint
   - deeper Presentation API slices
2. Production-representative visual exemplar / placeholder tolerance evidence remains thin.
3. RTM full-chain coverage remains 97/201 = 48.3%.

## Related Artifacts

- `docs/architecture/architecture-review-2026-07-01.md`
- `docs/architecture/architecture-traceability.md`
- `docs/architecture/requirements-traceability.md`
- `production/gate-checks/2026-07-01-pre-production-to-production.md`
- `production/qa/evidence/sprint-2-fresh-gate-guardrails-2026-06-28.md`
