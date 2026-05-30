# Gate Check: Technical Setup → Pre-Production

**Date**: 2026-05-30  
**Checked by**: `/gate-check` skill  
**Review mode**: lean  
**Verdict**: CONCERNS

## Summary

This re-run confirmed that the previous blocking issues for the Technical Setup → Pre-Production gate were resolved:

- CI/CD workflow now exists at `.github/workflows/tests.yml`
- A project-level automated test runner now exists at `tests/test_script_runner.gd`
- Technical test-framework documentation now matches the repository's real custom headless runner pattern

The gate still resolves to **CONCERNS**, not PASS, because the Director Panel returned Technical Director = CONCERNS and Producer = CONCERNS. No hard blockers remain.

## Required Artifacts

- [x] Engine chosen — Godot 4.6 (`CLAUDE.md`, `project.godot`)
- [x] Technical preferences configured — `.claude/docs/technical-preferences.md`
- [x] Art bible exists — `design/art/art-bible.md`
- [x] 3+ ADRs exist — 9 accepted ADRs under `docs/architecture/`
- [x] Engine reference exists — `docs/engine-reference/godot/VERSION.md`
- [x] Test framework initialized — `tests/unit/`, `tests/integration/`
- [x] CI/CD workflow exists — `.github/workflows/tests.yml`
- [x] Example test file exists — `tests/unit/player-dev/training_efficiency_formula_test.gd`
- [x] Project-level runner exists — `tests/test_script_runner.gd`
- [x] Master architecture document exists — `docs/architecture/architecture.md`
- [x] Traceability index exists — `docs/architecture/requirements-traceability.md`
- [x] Architecture review exists — `docs/architecture/architecture-review-2026-05-17.md`
- [x] Accessibility requirements exist — `design/accessibility-requirements.md`
- [x] Interaction pattern library exists — `design/ux/interaction-patterns.md`
- [x] At least one UX spec started — `design/ux/hud.md`

## Quality Checks

- [x] Architecture decisions cover core systems
- [x] Technical preferences match the actual automated test path
- [x] Naming conventions and performance budgets are documented
- [x] Accessibility tier is defined
- [x] At least one screen UX spec exists
- [x] All ADRs include ADR Dependencies / Engine Compatibility / GDD Requirements Addressed
- [x] No ADR dependency cycle detected
- [x] ADR engine version usage is consistent (Godot 4.6)
- [x] No deprecated API references were found in ADRs
- [x] Traceability matrix shows zero Foundation/Core gaps
- [~] Two Core partial coverage items remain:
  - `TR-economy-008` — AP daily recovery timing detail
  - `TR-town-013` — adjacency bonus cap 15.0 enforcement detail
- [~] One sampled unit test passes but emits Godot object/resource leak warnings at exit

## Test Verification Evidence

### Unit sample

Command path: `res://tests/unit/player-dev/training_efficiency_formula_test.gd`

Observed output:

```text
TRAINING_EFFICIENCY_FORMULA_TEST_PASS
WARNING: ObjectDB instances leaked at exit
ERROR: 3 resources still in use at exit
```

Result: PASS WITH WARNING

### Integration sample

Command path: `res://tests/integration/save/save_summary_performance_test.gd`

Observed output:

```text
SAVE_SUMMARY_PERFORMANCE_TEST_PASS
```

Result: PASS

## Director Panel Assessment

### Creative Director — READY
- Core fantasy and pillars are preserved strongly enough for Pre-Production.
- No creative blockers.
- Follow-up note: formalize canonical pillar design tests before Production.

### Technical Director — CONCERNS
- Architecture, ADRs, engine reference, traceability, CI, and test runner are in place.
- No blockers.
- Concerns:
  - Track the two Core partial coverage items.
  - Investigate sampled unit-test leak warnings before the Production gate.

### Producer — CONCERNS
- Required artifacts are sufficient to enter Pre-Production.
- No blockers.
- Concerns:
  - `production/stage.txt` is still missing.
  - Current planning artifacts already lean toward Production/HUD execution.
  - Vertical-slice scope must be bounded tightly to avoid expansion across too many UI/system fronts.

### Art Director — READY
- Art bible, accessibility requirements, interaction patterns, HUD UX, and entity inventory are sufficient for Pre-Production.
- No blockers.
- Follow-up note: align minor palette/text-size consistency details and verify AccessKit in engine before production QA.

## Remaining Concerns

1. `production/stage.txt` is still absent, so stage-aware tooling remains inference-based.
2. The two Core partial coverage items must be attached to future story acceptance criteria or ADR follow-up.
3. Sampled unit-test leak warnings should be investigated before the Production gate.
4. Pre-Production planning should be re-centered around vertical-slice scope rather than continuing a Production/HUD execution path unchanged.

## Chain-of-Verification

Five challenge questions were checked. Verdict remained **unchanged**.

- Reconfirmed CI workflow existence.
- Reconfirmed project-level test runner existence and sample execution.
- Rechecked stale GUT/gdunit4 active-framework references.
- Rechecked traceability partial items.
- Reapplied Director Panel minimum-verdict rule.

## Recommended Next Step

**Priority next action accepted by user**: tighten and define the Pre-Production vertical-slice scope before further execution planning.
