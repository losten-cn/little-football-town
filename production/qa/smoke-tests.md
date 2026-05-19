# Sprint 1 Smoke Test List

**Date Created**: 2026-05-19
**Source**: `production/qa/qa-plan-sprint-1-2026-05-19.md`
**Scope**: Sprint 1 HUD Framework, UI readiness, and infrastructure smoke checks

---

## Critical Paths

1. Game launches to main menu / Home without crash.
2. Existing save or new session reaches a Home state where Zone A and Zone C render correctly.
3. HUD shows date/season, funds, action points, available actions, next match status, menu, player entry, and match entry with no overlap or missing labels.
4. Match entry and next-match state stay synchronized when upstream match availability changes.
5. Disabled match entry presents a readable reason.
6. Pause menu opens and closes without focus loss; focus returns to the menu trigger.
7. Entering Match Pre / Match Live / Match Result hides the persistent HUD completely; leaving the match flow restores it.
8. Player entry remains usable even when the roster is empty.
9. Sprint 1 HUD code introduces none of the forbidden Godot/API patterns listed in `docs/architecture/control-manifest.md`.
10. If Sprint 1 includes infrastructure cleanup, referenced production files remain where QA and sprint tooling expect them.

---

## Current Automated Manual Scene Coverage

`tests/manual/HudInteractionVerification.tscn` currently verifies:

- MVP HUD nodes exist in the non-match context.
- Non-MVP HUD zones `ZoneB` and `ZoneC2` are hidden.
- Read-only HUD text controls do not allow Tab focus.
- Enabled Menu, Roster, and Match buttons are Tab focusable.
- Tooltip display respects the 300ms delay.
- Reduced-motion toast behavior avoids horizontal slide offset and completes the short fade-in.
- Match flow hides Zone A, Zone C1, overlays, tooltip, and active toast content.

---

## Manual Evidence Still Required

- Screenshot of Home HUD with strict MVP elements visible.
- Screenshot of disabled Match entry with readable reason.
- Screenshot of Match Ready emphasis state.
- Screenshot of Pause Menu overlay and notes about focus return.
- 1280×720, 1920×1080, and 125% UI scale visual checks.
- Visual issue notes for clipping, alignment, contrast, and focus indicators.
