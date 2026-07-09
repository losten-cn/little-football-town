# Story 003: 收敛 PlayerMgmt explanatory payload authority contract

> **Epic**: 球员管理 UI
> **Status**: Complete
> **Layer**: Presentation
> **Type**: Integration
> **Estimate**: S
> **Manifest Version**: 2026-07-05
> **Last Updated**: 2026-07-09

## Context

**GDD**: `design/gdd/player-management-ui.md`, `design/gdd/main-loop-ui-framework.md`  
**Requirement**: `TR-playerui-001`, `TR-playerui-003`, `TR-playerui-008`, `TR-playerui-009`, `TR-mainui-005`

This story is a bounded authority-convergence follow-up for the existing Player / Training UI package. It does not expand gameplay systems, route topology, sorting/filtering depth, or save/event schema. Its only goal is to remove remaining explanatory fallback drift from `PlayerMgmtPanel` by moving player-facing explanation fields into authoritative read-model payloads and making the UI consume them read-only.

This story exists because the current Player / Training visual exemplar pass still allows the UI layer to generate some explanation text locally when upstream payload fields are missing. That behavior weakens the ADR-0010 contract and makes it harder to prove that Player / Training presentation is a pure consumer of authoritative truth.

**ADR Governing Implementation**:

- Primary: ADR-0010 — Cross-System Payload and Settlement Contracts
- Secondary: ADR-0002 — Event/Signal Architecture + TimeManager
- Secondary: ADR-0001 — Scene Management & Autoload Architecture

**ADR Decision Summary**:

- ADR-0010 requires UI modules to consume authoritative payloads and forbids recomputing truth conditions locally.
- ADR-0002 requires EventBus-based cross-system communication and explicit subscription boundaries.
- ADR-0001 requires the existing shell route/container flow to remain stable.

**Engine**: Godot 4.6 | **Risk**: Medium

**Engine Notes**:

- No new Godot 4.6 feature adoption is required; this is a payload-contract and presentation-boundary convergence story.
- Existing Control-node focus behavior must remain unchanged from the current Player / Training route flow.
- This story should not introduce any new node hierarchy dependency, dynamic scene lookup pattern, or runtime route mutation.

**Control Manifest Rules (Presentation / Foundation)**:

- Required: UI modules must consume snapshots, explanations, labels, acknowledgement flags, and visibility stages as read-only payloads.
- Required: If a UI screen needs a new display field, add it to the authoritative payload by the owning Core system before presenting it.
- Forbidden: Never recompute roster truth, training availability, rating, growth, economy values, or route availability truth in UI.
- Forbidden: Never resolve authority nodes through hardcoded `NodePath`, arbitrary scene-tree search, or implicit pseudo-singletons.
- Guardrail: UI implementations must remain within existing shell/page boundaries and must not change route IDs or save/event schema.

---

## Acceptance Criteria

- [ ] `PlayerMgmtPanel` no longer derives player-facing explanatory fields from local rating, growth, status, or availability heuristics when authoritative equivalents are required by the reviewed flow.
- [ ] The reviewed roster/detail/training explanatory fields are supplied through authoritative payload contracts before rendering, including at minimum: attention reason, role/usage summary, next-step summary, training reason, training risk/disabled explanation, and training payoff summary.
- [ ] If an expected explanatory field is absent from the payload, the UI falls back only to neutral placeholder copy and does not generate new strategy-like or recommendation-like truth locally.
- [ ] Default selected player context for Player Detail / Training is not silently chosen from local UI-side rating order when the authoritative selection context is absent.
- [ ] Existing route IDs, shell containment, training request flow, and save/event schema remain unchanged.
- [ ] Existing Player / Training visual exemplar behavior remains readable after the contract convergence pass and does not regress into blank, broken, or debug-facing output.
- [ ] Automated regression coverage proves that authoritative explanatory payload fields override local fallback behavior and that read-model refreshes do not reintroduce UI-side explanatory truth generation.
- [ ] Existing route and handoff guardrails still pass after this authority-convergence pass.

---

## Scope

### In Scope

- Adding or refining authoritative explanatory fields in the existing Player / Training read-model payload path.
- Updating `PlayerMgmtPanel` so reviewed explanatory strings are consumed from payload instead of locally inferred.
- Tightening fallback behavior to neutral placeholders only.
- Adding regression tests for explanatory-payload authority and selection-context authority.
- Updating walkthrough/test payload fixtures if needed to reflect the authoritative contract.

### Out of Scope

- Any new route IDs or route topology changes.
- Any new sorting/filtering features.
- Any new training mechanics, ROI formulas, or growth formulas.
- Any new player schema persistence fields unless required purely as non-durable presentation payload surface.
- Any save/load schema change.
- Final art pass or broad visual polish unrelated to authority convergence.
- Skill/Trait, recruitment, compare, contract, market, or identity-history feature expansion.

---

## Completion Notes
**Completed**: 2026-07-09
**Criteria**: 8/8 passing
**Deviations**: Advisory only — training summary `回报/时机` slot mapping not fully intuitive (UI copy follow-up, not authority gap); `TrainingRequestCoordinator._build_roster_view()` still generates explanatory content at producer layer (allowed per scope, future story could tighten); walkthrough downgraded to smoke/visibility verifier (authority semantics proven by dedicated integration test instead).
**Test Evidence**: `tests/integration/ui/player_mgmt_authoritative_explanatory_payload_test.gd` — `PLAYER_MGMT_AUTHORITATIVE_EXPLANATORY_PAYLOAD_TEST_PASS`.
**Code Review**: Complete — `/code-review` passed / approved with suggestions in lean mode.

## Dependencies

- Depends on:
  - `production/epics/player-management-ui/story-001-roster-training-entry.md`
  - `production/epics/player-management-ui/story-002-player-training-visual-exemplar-boundary.md`
  - `production/epics/main-loop-ui-framework/story-002-home-visual-exemplar-placeholder-boundary.md`
- Parallel with:
  - None
- Unlocks:
  - future Player / Training production art pass with stronger architecture evidence
  - cleaner `/code-review` and `/story-done` closure for Player / Training follow-through
- Story dependencies: None beyond the items listed above.

---

## Implementation Notes

This is an authority-convergence story, not a feature-growth story.

Preserve:

- existing route IDs
- existing Home → Roster → Player Detail → Training request flow
- existing save/event schema
- existing MainLoop Shell mounting and return paths

Required implementation direction:

- Move reviewed explanatory text responsibility to authoritative payload producers.
- Keep `PlayerMgmtPanel` as a read-only formatter and renderer.
- Replace local recommendation-like fallback logic with neutral placeholders where upstream fields are not yet provided.
- Do not silently pick the “first/highest-rated” player as an authoritative default drill-down target unless the payload explicitly provides selection context.
- Keep all request actions (`screen_requested`, `training_requested`, etc.) unchanged unless a purely additive payload contract refinement is needed.

Not allowed:

- adding gameplay logic to UI
- inventing new recommendation heuristics in UI
- using local UI cache as truth
- changing route IDs
- changing `ScreenManager`
- changing persistent player/save schema unless separately approved

---

## QA Test Cases

- **AC-1**: UI does not locally derive reviewed explanatory truth
  - Given: a roster/detail/training payload with explicit authoritative explanatory fields
  - When: `PlayerMgmtPanel` renders roster, detail, and training states
  - Then: the rendered text matches the authoritative explanatory fields rather than local heuristics
  - Edge cases: high-rated player with contradictory authoritative role text; growth-present player with contradictory authoritative next-step text

- **AC-2**: Missing explanatory fields degrade to neutral placeholders
  - Given: a payload missing one or more explanatory fields
  - When: the reviewed Player / Training state renders
  - Then: the UI uses neutral placeholder wording and does not generate strategy-like guidance from local rating/growth/status heuristics
  - Edge cases: missing all explanatory fields; missing only one field

- **AC-3**: Selected player context is not invented from local rating order
  - Given: roster payload exists but no authoritative selected-player context is provided
  - When: the UI is routed to `player_detail` or `training`
  - Then: the UI does not silently promote the top-rated local row as the authoritative selected player
  - Edge cases: two-player roster; empty roster; stale prior selection

- **AC-4**: Refresh does not reintroduce UI-side explanatory drift
  - Given: authoritative explanatory fields have already been delivered
  - When: a later read-model refresh, training refresh, or related payload update arrives
  - Then: the rendered explanatory text remains aligned with the authoritative fields and does not regress to local fallback reasoning
  - Edge cases: training options refresh only; roster refresh only; player action completion refresh

- **AC-5**: Existing route/handoff flow remains intact
  - Given: the current shell-mounted Player / Training route flow
  - When: the updated contract convergence pass is applied
  - Then: roster → player detail → training → return/home behavior still passes the existing integration route guardrails
  - Edge cases: disabled training option; blocked training entry; visible walkthrough flow

---

## Test Evidence

**Story Type**: Integration

**Required evidence**:

- Automated integration test:
  - `tests/integration/ui/player_mgmt_authoritative_explanatory_payload_test.gd`
- Supporting regression coverage may also extend:
  - `tests/integration/ui/l2_playable_loop_panels_test.gd`
  - `tests/integration/ui/mvp_visual_walkthrough_runner.gd`

**Status**: [ ] Not yet created

---

## Definition of Done

- [ ] A dedicated integration test exists for authoritative explanatory payload consumption and passes.
- [ ] Existing Player / Training route/handoff guardrails still pass.
- [ ] No new route IDs, gameplay formulas, or schema contracts were introduced.
- [ ] Code review confirms explanatory truth generation is no longer owned by `PlayerMgmtPanel`.
- [ ] Any remaining neutral-placeholder fallback behavior is explicitly documented.
