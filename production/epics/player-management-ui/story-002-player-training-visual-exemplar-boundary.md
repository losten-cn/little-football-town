# Story 002: Player / Training visual exemplar boundary

> **Epic**: 球员管理 UI
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: S
> **Manifest Version**: 2026-07-05
> **Last Updated**: 2026-07-09

## Context

**GDD**: `design/gdd/player-management-ui.md`, `design/gdd/main-loop-ui-framework.md`  
**Requirement**: `TR-playerui-001`, `TR-playerui-003`, `TR-playerui-004`, `TR-playerui-008`, `TR-playerui-009`, `TR-mainui-005`

This story is a Production visual follow-through story for the existing Player / Training surfaces already mounted inside the MainLoop Shell. It does not reopen route topology, roster/training authority, save/event schema, or the current Player → Training request bridge. Its purpose is to turn the current Roster / Player Detail / Training surfaces into an explicit production-representative visual target, using the same bounded follow-through approach as the completed Home visual exemplar story.

**ADR Governing Implementation**:

- Primary: ADR-0001 — Scene Management & Autoload Architecture
- Secondary: ADR-0002 — Event/Signal Architecture + TimeManager
- Secondary: ADR-0010 — Cross-System Payload and Settlement Contracts

**ADR Decision Summary**:

- ADR-0001 requires all reviewed Player / Training surfaces to remain inside the existing `ScreenManager` route stack and stable shell/container lifecycle.
- ADR-0002 requires EventBus-based cross-system notifications and forbids ad hoc direct UI coupling.
- ADR-0010 requires Player / Training presentation to consume authoritative payloads only and never recompute rating, attributes, growth, affordability, training preview truth, or route availability truth locally.

**Engine**: Godot 4.6 | **Risk**: Medium

**Engine Notes**:

- UI must respect Godot 4.6 Control focus behavior and avoid focus ambiguity across roster rows, detail CTA, training actions, and return controls.
- The project targets PC keyboard/mouse only.
- This story is limited to visual hierarchy, readability, spacing, state cues, and placeholder-boundary refinement inside existing Player / Training surfaces.
- No post-cutoff engine API expansion is expected; this is a presentation refinement story over existing Godot UI flows.

**Control Manifest Rules (Presentation / Foundation)**:

- Required: All screen flows must continue to use the Screen Stack pattern managed by `ScreenManager`.
- Required: UI modules must consume snapshots, explanations, labels, acknowledgement flags, and visibility stages as read-only payloads.
- Required: UI screens must subscribe/unsubscribe through the approved event lifecycle boundaries already established by the current shell/page package.
- Forbidden: Never recompute roster truth, training availability, rating, growth, economy values, or route availability truth in UI.
- Forbidden: Never resolve authority nodes through hardcoded `NodePath`, arbitrary scene-tree search, or implicit pseudo-singletons.
- Guardrail: UI implementations must stay within the global 60fps / 16ms frame budget and 500 draw-call ceiling.

---

## Acceptance Criteria

- [ ] Roster, Player Detail, Training selection, and Training confirmation states remain inside the existing MainLoop Shell and preserve existing route IDs, return paths, and authority request flow.
- [ ] Roster rows remain production-representative and scan-friendly: readable field grouping, stable row separation, and no spreadsheet-like visual overload beyond the current MVP field contract.
- [ ] Player Detail preserves a readable warm-town visual hierarchy for identity, attributes, growth, status, and action entry without introducing new gameplay detail depth.
- [ ] Training-related disabled or unavailable states appear with clear player-facing reasons and do not present as silent gray-box controls.
- [ ] No reviewed Player / Training placeholder exposes internal IDs, debug labels, enum-like text, false interaction affordances, or route ambiguity.
- [ ] Rating, attributes, growth summary, AP/funds affordance, training availability, and selected `player_id` context continue to be consumed from authoritative payloads only.
- [ ] Focus, hover, selected, and disabled states on the reviewed Player / Training surfaces remain understandable without color alone.
- [ ] This visual pass does not add new sorting/filtering systems, new training mechanics, new player schema fields, new route IDs, or new save/event contracts.
- [ ] Player / Training reviewed states support stable screenshot review and/or walkthrough evidence for roster, player detail, training entry, disabled-state visibility, and return-path behavior.
- [ ] Existing route and handoff guardrails still pass after the Player / Training visual exemplar pass.

---

## Scope

### In Scope

- Visual hierarchy refinement for:
  - `roster`
  - `player_detail`
  - `training`
- Readability, spacing, grouping, and state-cue improvements inside existing Player / Training surfaces.
- Warm-town visual treatment alignment with the approved Home exemplar direction.
- Clearer disabled-state explanation for training-related affordances.
- Screenshot / walkthrough / QA evidence updates for reviewed Player / Training states.

### Out of Scope

- New sorting/filtering logic or expanded roster-management features.
- New training formulas, ROI logic, cost logic, or growth logic.
- Skill/Trait, identity history, recruitment, compare, sell, contract, or market systems.
- Any route topology change.
- Any `ScreenManager` refactor.
- Any gameplay authority or save/event schema change.
- Any new player-detail depth beyond current MVP payloads.
- Final production art replacement.

---

## Completion Notes
**Completed**: 2026-07-09
**Criteria**: 10/10 passing
**Deviations**: Advisory only — `PlayerMgmtPanel` 仍保留部分 explanatory fallback；当上游 payload 未提供完整 explanation fields 时，UI 仍会生成部分关注/用途/下一步/风险/回报类说明文本。该 authority-contract 收敛问题已拆分到 `production/epics/player-management-ui/story-003-authoritative-explanatory-payload-contract.md`，当前 closure 仅声明 visual boundary pass 已完成，不声明 explanatory payload authority contract 已完全收敛。
**Test Evidence**: `production/qa/evidence/player-training-visual-exemplar-boundary-2026-07-08.md`; `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`; `MVP_VISUAL_WALKTHROUGH_PASS`.
**Code Review**: Complete — `/code-review` completed in lean mode and accepted for closure with follow-up notes.

## Dependencies

- Depends on:
  - `production/epics/player-management-ui/story-001-roster-training-entry.md`
  - `production/epics/main-loop-ui-framework/story-002-home-visual-exemplar-placeholder-boundary.md`
  - `production/qa/evidence/home-visual-exemplar-placeholder-boundary-2026-07-05.md`
  - `docs/architecture/control-manifest.md` Manifest Version `2026-07-05`
- Parallel with:
  - `production/sprints/sprint-3-production-visual-follow-through.md#s3-08`
- Unlocks:
  - future Player / Training production art pass evidence
  - future Player / Training readability/polish follow-up work
- Story dependencies: None beyond the items listed above.

---

## Implementation Notes

This story is a bounded visual-boundary and presentation-readiness pass, not a route or gameplay refactor.

Use the existing mounted Player / Training pages inside the MainLoop Shell. Preserve:

- route IDs already used by the current shell package
- existing Home → Roster → Player Detail → Training handoff
- authoritative read-model ownership for roster, training, AP/funds, and player selection context
- existing request/event boundaries

Allowed changes:

- improve Player / Training panel grouping and spacing;
- improve visual hierarchy and field readability;
- refine disabled-state explanation and CTA readability;
- strengthen warm-town visual treatment;
- improve focus / hover / selected / disabled differentiation;
- add screenshot or walkthrough evidence.

Not allowed:

- changing `ScreenManager`;
- adding new route IDs;
- changing gameplay authority;
- changing save/event schema;
- recomputing gameplay truth locally;
- adding new roster-management or training-system functionality;
- expanding into full compare/filter/market/history scope.

If any new display field is needed, add it through the authoritative payload owner first; do not synthesize gameplay truth in UI.

---

## Test Evidence

**Story Type**: UI

**Required evidence**:

- Manual visual evidence:
  - `production/qa/evidence/player-training-visual-exemplar-boundary-2026-07-08.md`
- Automated guardrails:
  - `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`
  - `MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS`
  - `MVP_VISUAL_WALKTHROUGH_PASS` or an updated Player / Training walkthrough evidence file

**Status**: [ ] Not yet created

---

## Definition of Done

- [ ] Existing Player / Training route and handoff tests still pass.
- [ ] Screenshot or walkthrough evidence exists for the reviewed Player / Training states.
- [ ] No new route IDs, gameplay rules, or schema contracts were introduced.
- [ ] Code review confirms presentation-only scope was preserved.
- [ ] Any advisory deviations are documented rather than silently introduced.
