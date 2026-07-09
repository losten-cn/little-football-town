## Smoke Check Report — Sprint 5
**Date**: 2026-07-10
**Sprint**: Sprint 5 — Feature-Adjacent Presentation
**Engine**: Godot 4.6.3
**QA Plan**: `production/qa/qa-plan-sprint-5-2026-07-10.md`
**Argument**: sprint

---

### Automated Tests

**Status**: PASS WITH WARNINGS (8 suites, 7 PASS, 1 pre-existing failure)

| Test Suite | Result |
|------------|--------|
| `l2_playable_loop_panels_test.gd` | ✅ L2_PLAYABLE_LOOP_PANELS_TEST_PASS |
| `town_grid_authoritative_payload_test.gd` | ✅ TOWN_GRID_AUTHORITATIVE_PAYLOAD_TEST_PASS |
| `skill_trait_growth_summary_authoritative_payload_test.gd` | ✅ SKILL_TRAIT_GROWTH_SUMMARY_AUTHORITATIVE_PAYLOAD_TEST_PASS |
| `main_loop_shell_navigation_test.gd` | ✅ MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS |
| `player_mgmt_authoritative_explanatory_payload_test.gd` | ✅ PLAYER_MGMT_AUTHORITATIVE_EXPLANATORY_PAYLOAD_TEST_PASS |
| `match_start_request_bridge_test.gd` | ✅ MATCH_START_REQUEST_BRIDGE_TEST_PASS |
| `what_next_guidance_test.gd` | ✅ WHAT_NEXT_GUIDANCE_TEST_PASS |
| `mvp_visual_walkthrough_runner.gd` | ✅ MVP_VISUAL_WALKTHROUGH_STRUCTURE_PASS |
| `training_request_bridge_test.gd` | ⚠️ 3 pre-existing failures (not Sprint 5 regression) |

**Pre-existing failures** (`training_request_bridge_test.gd`, last modified `dd567cc`):
- `training request should emit training_completed`
- `training request should emit player_action_completed`
- `completion should include selected training id`

These failures pre-date Sprint 5 and are not caused by Sprint 5 changes.

---

### Test Coverage

| Story | Type | Test File | Coverage Status |
|-------|------|-----------|----------------|
| S5-01: Growth Summary | UI | `skill_trait_growth_summary_authoritative_payload_test.gd` | COVERED |
| S5-02: Town Grid | UI | `town_grid_authoritative_payload_test.gd` | COVERED |
| L2 Regression | Integration | `l2_playable_loop_panels_test.gd` | COVERED |
| Route Guardrails | Integration | `main_loop_shell_navigation_test.gd` | COVERED |
| Walkthrough | UI | `mvp_visual_walkthrough_runner.gd` | COVERED |

**Summary**: 2/2 Sprint 5 stories COVERED. 3 regression guardrails COVERED.

---

### Manual Smoke Checks

Per user directive, all manual checks replaced by automated test equivalents:

- [x] Core stability — 7/7 Node-based test suites instantiate `Hud.tscn` without crash
- [x] S5-01 Growth Summary — authority test passes; neutral placeholder verified
- [x] S5-02 Town Grid — authority test passes; empty/occupied cell rendering verified
- [x] Regression — L2 + navigation + walkthrough all pass
- [-] Save / load — N/A (not in Sprint 5 scope)
- [-] Performance — not profiled this session

---

### Verdict: **PASS WITH WARNINGS**

All Sprint 5 story tests pass cleanly. All regression guardrails intact. One pre-existing `training_request_bridge_test.gd` failure pre-dates Sprint 5 and does not block sprint close-out.

**Advisory items**:
- `training_request_bridge_test.gd` pre-existing failures → triage in follow-up sprint
- S5-01 / S5-02 manual visual evidence files not created (UI type: ADVISORY)
