# HUD Regression Evidence — Sprint 1

- Story Type: Integration
- Output Location: `production/qa/evidence/`
- Gate Level: BLOCKING
- Scope: S1-3
- Source: `production/qa/qa-plan-sprint-1-2026-05-19.md`, `production/qa/smoke-2026-05-19.md`

## Current Status

Formal integration regression coverage is still missing, but the expanded HUD manual verification scene now provides partial regression smoke evidence for HUD contract, focus, overlay, tooltip, reduced-motion toast, and match-flow hiding behavior.

## Evidence Summary

| Evidence Item | Status | Notes |
|---|---|---|
| Blocking HUD findings list from S1-2 | NOT VERIFIED | S1-2 walkthrough findings are not documented yet. |
| Manual regression smoke scene | PARTIAL PASS | `tests/manual/HudInteractionVerification.tscn` passed via Godot MCP and local Godot console after expansion. |
| Re-test of corrected build | PARTIAL | Expanded verification scene passed; no S1-2 blocking findings list exists yet for issue-by-issue retest. |
| Automated regression file present | FAIL | Missing expected file: `tests/integration/ui/hud_review_regression_test.gd`. |

## Key Checklist

- [FAIL] Regression test file exists for S1-3.
- [PARTIAL PASS] Expanded HUD manual verification scene passed via Godot MCP and local Godot console.
- [PARTIAL PASS] Focus/navigation contract checks did not regress in the expanded scene.
- [PARTIAL PASS] Overlay, tooltip, reduced-motion toast, and match-flow HUD hiding checks passed in the expanded scene.
- [NOT VERIFIED] Every blocking finding from S1-2 is listed with bug ID/title.
- [NOT VERIFIED] Each blocking finding is retested on the corrected build.
- [NOT VERIFIED] No S1 or S2 HUD issues remain open after retest.
- [NOT VERIFIED] Focus/navigation did not regress.
- [NOT VERIFIED] Overlay visibility did not regress.
- [NOT VERIFIED] Match takeover still hides/restores persistent HUD correctly.
- [NOT VERIFIED] Any deferred issue names owner, rationale, and next checkpoint.

## Blocking Findings Register

| ID | Finding | Severity | Fix Status | Retest Status | Notes |
|---|---|---|---|---|---|
| — | No S1-2 finding list has been recorded yet. | — | — | NOT VERIFIED | Populate after HUD walkthrough. |

## Open Gaps

This file remains incomplete until S1-2 findings exist and a formal integration regression test or issue-by-issue retest is executed. Current status is partial: the expanded manual verification scene passes, but the expected integration regression test file is still missing.
