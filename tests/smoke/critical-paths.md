# Smoke Test: Critical Paths

**Purpose**: Run these checks in under 15 minutes before any QA hand-off.
**Run via**: `/smoke-check` (this file is the seed checklist)
**Update**: Add new entries when a new core system becomes player-visible.

## Core Stability

1. Game launches in headless mode without startup errors.
2. Main gameplay autoloads initialize without parse/runtime startup failures.
3. Existing automated test entry point can run at least one unit test and one integration test.

## Sprint 1 Focus

4. HUD-related manual verification evidence exists and matches the current sprint scope.
5. Player Management UI readiness evidence is up to date before implementation begins.
6. Match Performance UI readiness evidence is up to date before implementation begins.

## Data Integrity

7. Save summary metadata test passes.
8. Time/status regression test passes.
9. Town serialization/restore regression test passes.

## Performance / Regression Guardrails

10. No single automated test used for sprint sign-off exceeds its documented threshold.
11. No smoke-signoff story is missing either automated evidence or a linked manual evidence file.
