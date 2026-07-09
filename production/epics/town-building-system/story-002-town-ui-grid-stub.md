# Story 002: Town Management UI — 最小 facility grid stub

> **Epic**: 小镇建设系统
> **Status**: Ready
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: S–M
> **Manifest Version**: 2026-07-05
> **Last Updated**: 2026-07-10

## Context

**GDD**: `design/gdd/town-building-system.md`, `design/gdd/town-management-ui.md`
**Requirement**: `TR-townui-001`, `TR-townui-002`

This story is a minimum Alpha presentation stub for the Town Management facility grid. It does not implement build/upgrade/demolish flows, construction timers, cost preview, budget validation, or adjacency editing. Its only goal is to establish a read-only UI consumption path for TownBuilding grid state — so that when the full town management UI is built in Alpha, the presentation layer is already wired to the authoritative data source.

This is the first Town UI Presentation story. It follows the same Presentation-stub pattern as the Skill/Trait Growth Summary (S5-01), and it applies the authority-contract decision checklist from Sprint 4 governance.

**ADR Governing Implementation**:

- Primary: ADR-0008 — Town Grid & Facility System
- Secondary: ADR-0001 — Scene Management & Autoload Architecture
- Secondary: ADR-0002 — Event/Signal Architecture + TimeManager

**ADR Decision Summary**:

- ADR-0008 defines `TownBuilding` as the authoritative grid owner with `get_facility_at()`, `get_grid_width()`, `get_grid_height()`, and events `town_grid_changed` / `town_facility_completed`. UI must consume these read models without recomputing facility state, construction cost, or upgrade eligibility.
- ADR-0002 requires EventBus-based subscription and forbids ad hoc direct coupling.
- ADR-0001 requires the new surface to remain inside the existing shell route/container lifecycle.

**Engine**: Godot 4.6 | **Risk**: Medium

**Engine Notes**:

- No new Godot 4.6 feature adoption is required.
- This is a presentation-only story over existing Control-node patterns.
- The existing Home town summary card (`HomeCardTownWarmth`) already consumes `town_anchor_summary` from system payload — this story extends that area or adds a sibling grid card without breaking the existing card.

**Control Manifest Rules (Presentation / Foundation)**:

- Required: UI modules must consume grid state, facility type/level/state, and construction progress as read-only payloads from TownBuilding authority.
- Required: If a UI screen needs a new display field, add it to the authoritative payload by the owning Core system before presenting it.
- Forbidden: Never recompute construction cost, upgrade eligibility, adjacency bonuses, or completion timing in UI.
- Forbidden: Never resolve authority nodes through hardcoded `NodePath`, arbitrary scene-tree search, or implicit pseudo-singletons.
- Guardrail: UI implementations must stay within the global 60fps / 16ms frame budget and 500 draw-call ceiling.

**Pre-Implementation Decisions (S4-02 checklist applied)**:

- [ ] Authority purity first — missing grid payload → neutral placeholder only
- [ ] Latest producer wins — grid state refresh from `town_grid_changed` event only
- [ ] Explanatory fields from producer, UI read-only — facility type names, level labels from TownBuilding/Facility model
- [ ] Selection context from authority only — selected cell/facility from TownBuilding query, not local cache
- [ ] `disable_reason` ≠ `risk_summary` — N/A for this story (no disable/risk fields in grid stub)
- [ ] Test contract: new integration test file; existing L2/walkthrough should not be broken by a new read-only surface

---

## Acceptance Criteria

- [ ] A 5×5 facility grid surface exists inside the existing MainLoop Shell, visible from Home (as a new card or section), without new route IDs.
- [ ] The grid consumes TownBuilding read models (`get_facility_at()`, `get_grid_width()`, `get_grid_height()`) as read-only snapshots and renders each cell with a placeholder icon based on facility type (or empty-state indicator for unbuilt cells).
- [ ] The surface subscribes to `town_grid_changed` EventBus events and refreshes grid display from the authoritative TownBuilding state.
- [ ] The surface does not compute: construction cost, upgrade eligibility, adjacency bonuses, completion timing, budget preview, or build/upgrade/demolish validation.
- [ ] If TownBuilding grid data is absent, uninitialized, or empty, the surface degrades to a neutral placeholder grid (all cells showing empty state) without exposing internal IDs, debug labels, or false interaction.
- [ ] Each occupied cell shows at minimum: facility type icon (placeholder), level indicator (Lv.N), and construction/upgrade progress (if in CONSTRUCTING or UPGRADING state).
- [ ] Focus, hover, and disabled states remain understandable without color alone on grid cells.
  - **Stub note (2026-07-10)**: All grid cells use `mouse_filter = IGNORE` in this read-only stub. There are no focus, hover, or disabled interactive states to verify. This criterion is deferred to the Alpha build/upgrade interaction story when cells become clickable.
- [ ] This stub does not add build/upgrade/demolish UI, construction flow, cost preview, budget validation, new route IDs, new save/event schema, or new persistence fields.
- [ ] Existing Home visual exemplar cards (6 warm-town info cards) are not degraded or displaced by the addition of the grid stub.
- [ ] Automated regression coverage proves the grid consumes authoritative TownBuilding state and degrades safely when grid is empty.
- [ ] Existing route and handoff guardrails still pass.

---

## Scope

### In Scope

- A read-only 5×5 grid container inside the existing shell, accessible from Home.
- Subscription to `town_grid_changed` EventBus events.
- Per-cell rendering: empty (unbuilt) → neutral empty indicator; occupied → facility type placeholder icon + level label + progress bar (if constructing/upgrading).
- Warm-town visual treatment consistent with the approved Home/Player/Training exemplar direction.
- Integration test for grid payload consumption and safe degradation.
- Walkthrough/screenshot evidence.

### Out of Scope

- Build/upgrade/demolish UI flows.
- Construction/upgrade cost preview or budget validation.
- Facility selection, detail popup, or tooltip interaction.
- Adjacency visualization or bonus display.
- Construction timer countdown animation beyond a simple progress indicator.
- Maintenance fee summary (already covered by existing Home economy card).
- Any new Core authority, gameplay formula, save/event schema change, or persistence contract.
- Full Town Management interaction depth (build confirmation, upgrade path planning, demolish confirmation, grid reordering).
- Production art replacement — grid cells use placeholder shapes/colors consistent with the warm-town palette.

---

## Dependencies

- Depends on:
  - `production/epics/town-building-system/story-001-town-grid-facility-contract.md` (Complete — Facility model, grid indexing)
  - `production/epics/town-building-system/story-008-downstream-query-maintenance.md` (Complete — `get_facility_at()`, `get_grid_width()`, `get_grid_height()`)
  - `production/epics/main-loop-ui-framework/story-002-home-visual-exemplar-placeholder-boundary.md` (Complete — Home card layout)
  - `docs/architecture/control-manifest.md` Manifest Version `2026-07-05`
- Parallel with:
  - `production/sprints/sprint-5-feature-adjacent-presentation.md#s5-01` (Complete — Growth Summary stub)
- Unlocks:
  - future Town Management build/upgrade interaction stories (Alpha)
  - future Town grid adjacency visualization stories (Alpha)
  - future facility detail/tooltip stories
- Story dependencies: All Core town-building stories (001–009) are Complete. No blocking dependencies.

---

## Implementation Notes

This is a presentation-stub story, not a feature-growth story.

Preserve:

- existing route IDs
- existing Home → Roster → Player Detail → Training flow
- existing 6 Home warm-town info cards
- existing save/event schema
- existing MainLoop Shell mounting and return paths

Allowed changes:

- add a new read-only grid container inside the shell (as a new Home card or section);
- subscribe to `town_grid_changed` EventBus events;
- query `TownBuilding.get_facility_at()` for each of the 25 cells on refresh;
- render cells as non-interactive placeholder icons with level labels;
- show "暂无设施" neutral placeholder when the grid is entirely empty;
- add screenshot or walkthrough evidence.

Not allowed:

- adding build/upgrade/demolish UI widgets;
- recomputing construction cost, upgrade eligibility, or adjacency bonuses;
- writing facility state from UI;
- adding new route IDs;
- changing `ScreenManager`;
- expanding into full Town Management interaction depth.

**Authority access pattern**: TownBuilding is a Core scene-instantiated node, not an Autoload. The grid stub must receive its TownBuilding reference through the existing shell dependency injection path (consistent with how `TrainingRequestCoordinator` is accessed), or consume grid state through EventBus payloads emitted by TownBuilding (`town_grid_changed`). No hardcoded `NodePath` search is permitted.

---

## Test Evidence

**Story Type**: UI

**Required evidence**:

- Manual visual evidence:
  - `production/qa/evidence/town-ui-grid-stub-2026-07-10.md`
- Automated guardrails:
  - `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`
  - `MVP_VISUAL_WALKTHROUGH_PASS` or updated walkthrough evidence
- Authority contract evidence:
  - `tests/integration/ui/town_grid_authoritative_payload_test.gd`

**Status**: [ ] Not yet created

---

## Definition of Done

- [ ] 5×5 Facility grid surface exists and is visible from Home.
- [ ] Integration test for authoritative grid payload consumption passes.
- [ ] Existing route/handoff guardrails still pass.
- [ ] No new route IDs, gameplay formulas, or schema contracts were introduced.
- [ ] Code review confirms presentation-only scope was preserved.
- [ ] Any advisory deviations are documented.
