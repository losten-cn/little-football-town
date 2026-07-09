# Story 002: Match visual exemplar boundary

> **Epic**: 比赛表现 UI
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: S
> **Manifest Version**: 2026-07-05
> **Last Updated**: 2026-07-09

## Context

**GDD**: `design/gdd/match-performance-ui.md`, `design/gdd/main-loop-ui-framework.md`  
**Requirement**: `TR-matchui-001`, `TR-matchui-002`, `TR-matchui-003`, `TR-matchui-004`, `TR-matchui-007`, `TR-matchui-009`, `TR-matchui-010`, `TR-matchui-011`

This story is a Production visual follow-through story for the existing Match Pre / Match Live / Match Result surfaces already mounted inside the MainLoop Shell. It does not reopen route topology, match authority, save/event schema, halftime command depth, or live match interaction depth. Its purpose is to turn the current Match flow into an explicit production-representative visual target, using the same bounded follow-through approach as the completed Home and Player / Training visual exemplar stories.

**ADR Governing Implementation**:

- Primary: ADR-0001 — Scene Management & Autoload Architecture
- Secondary: ADR-0002 — Event/Signal Architecture + TimeManager
- Secondary: ADR-0010 — Cross-System Payload and Settlement Contracts

**ADR Decision Summary**:

- ADR-0001 requires all reviewed Match surfaces to remain inside the existing `ScreenManager` route stack and stable shell/container lifecycle.
- ADR-0002 requires EventBus-based cross-system notifications and forbids ad hoc direct UI coupling.
- ADR-0010 requires Match presentation to consume authoritative payloads only and never recompute score, match result, lineup legality, player performance, ranking, funds, or AP locally.

**Engine**: Godot 4.6 | **Risk**: Medium

**Engine Notes**:

- UI must respect Godot 4.6 Control focus behavior and avoid focus ambiguity across pre-match confirm, live timeline, halftime entry, result confirm, and return controls.
- The project targets PC keyboard/mouse only.
- This story is limited to visual hierarchy, readability, spacing, state cues, and placeholder-boundary refinement inside existing Match Pre / Match Live / Match Result surfaces.
- No post-cutoff engine API expansion is expected; this is a presentation refinement story over existing Godot UI flows.

**Control Manifest Rules (Presentation / Foundation)**:

- Required: All screen flows must continue to use the Screen Stack pattern managed by `ScreenManager`.
- Required: UI modules must consume snapshots, explanations, labels, acknowledgement flags, and visibility stages as read-only payloads.
- Required: UI screens must subscribe/unsubscribe through the approved event lifecycle boundaries already established by the current shell/page package.
- Forbidden: Never recompute match result, score, lineup legality, player performance, team strength, ranking, funds, or AP in UI.
- Forbidden: Never resolve authority nodes through hardcoded `NodePath`, arbitrary scene-tree search, or implicit pseudo-singletons.
- Guardrail: UI implementations must stay within the global 60fps / 16ms frame budget and 500 draw-call ceiling.

---

## Acceptance Criteria

- [ ] Match Pre, Match Live, and Match Result states remain inside the existing MainLoop Shell and preserve existing route IDs, return paths, and authority request flow.
- [ ] Match Pre retains a readable warm-town visual hierarchy for opponent, home/away, round, ranking summary, lineup context, tactical context, and start confirmation without introducing new tactical command depth.
- [ ] Match Live retains a readable score, match time, half indicator, key event timeline, halftime separator, and exit warning visual hierarchy without introducing new live interaction depth.
- [ ] Match Result retains a readable warm-town visual hierarchy for final score, win/loss reason, key event review, player performance summary, league impact, and confirm-return-home action.
- [ ] Opponent strength labels and matchup badges remain derived from authoritative `team_match_strength` and do not introduce UI-local strength recomputation.
- [ ] Halftime placeholder remains explanatory and does not present as a hidden interactive action or silent gray-box.
- [ ] No reviewed Match placeholder exposes internal IDs, debug labels, enum-like text, false interaction affordances, or route ambiguity.
- [ ] This visual pass does not add new halftime mechanics, new live command interactions, new match depth, new route IDs, or new save/event contracts.
- [ ] Match reviewed states support stable screenshot review and/or walkthrough evidence for match_pre, match_live, live timeline, match_result, league impact visibility, and return-path behavior.
- [ ] Existing route and handoff guardrails still pass after the Match visual exemplar pass.

---

## Scope

### In Scope

- Visual hierarchy refinement for:
  - `match_pre`
  - `match_live`
  - `match_result`
- Readability, spacing, grouping, and state-cue improvements inside existing Match surfaces.
- Warm-town visual treatment alignment with the approved Home and Player / Training exemplar direction.
- Clearer halftime explanatory presentation and live exit warning readability.
- Screenshot / walkthrough / QA evidence updates for reviewed Match states.

### Out of Scope

- New halftime mechanics, half-time tactical commands, or live substitution depth.
- New live command interactions beyond the current MVP event timeline and exit warning.
- New score calculation, match result reasoning, lineup legality logic, or player performance evaluation.
- Skill/Trait, deep stats, commentary, audio polish, or animated match scene.
- Any route topology change.
- Any `ScreenManager` refactor.
- Any gameplay authority or save/event schema change.
- Any new match-depth beyond current MVP payloads.
- Final production art replacement.

---

## Completion Notes
**Completed**: 2026-07-09
**Criteria**: 10/10 passing
**Deviations**: Advisory only — visual pass, not final art; no dedicated Match-only walkthrough runner (Match states verified through shared MVP route runner).
**Test Evidence**: `production/qa/evidence/match-visual-exemplar-boundary-2026-07-09.md`; `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`; `MVP_VISUAL_WALKTHROUGH_PASS`.
**Code Review**: Complete — accepted in lean mode.

## Dependencies

- Depends on:
  - `production/epics/match-performance-ui/story-001-prematch-result-flow.md`
  - `production/epics/main-loop-ui-framework/story-002-home-visual-exemplar-placeholder-boundary.md`
  - `production/epics/player-management-ui/story-002-player-training-visual-exemplar-boundary.md`
  - `production/qa/evidence/home-visual-exemplar-placeholder-boundary-2026-07-05.md`
  - `production/qa/evidence/player-training-visual-exemplar-boundary-2026-07-08.md`
  - `docs/architecture/control-manifest.md` Manifest Version `2026-07-05`
- Parallel with:
  - None
- Unlocks:
  - future Match production art pass evidence
  - future Match readability/polish follow-up work
- Story dependencies: None beyond the items listed above.

---

## Implementation Notes

This story is a bounded visual-boundary and presentation-readiness pass, not a route or gameplay refactor.

Use the existing mounted Match pages inside the MainLoop Shell. Preserve:

- route IDs already used by the current shell package
- existing Home → Match Pre → Match Live → Match Result → Home handoff
- authoritative payload ownership for match state, score, events, result, and league impact
- existing request/event boundaries

Allowed changes:

- improve Match Pre / Match Live / Match Result panel grouping and spacing;
- improve visual hierarchy and field readability;
- refine halftime and exit warning presentation;
- strengthen warm-town visual treatment;
- improve focus / hover / selected / disabled differentiation;
- add screenshot or walkthrough evidence.

Not allowed:

- changing `ScreenManager`;
- adding new route IDs;
- changing gameplay authority;
- changing save/event schema;
- recomputing gameplay truth locally;
- adding new halftime tactical commands or live interaction depth;
- expanding into full match HUD, deep stats, or commentary.

If any new display field is needed, add it through the authoritative payload owner first; do not synthesize gameplay truth in UI.

---

## Test Evidence

**Story Type**: UI

**Required evidence**:

- Manual visual evidence:
  - `production/qa/evidence/match-visual-exemplar-boundary-2026-07-09.md`
- Automated guardrails:
  - `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`
  - `MVP_VISUAL_WALKTHROUGH_PASS` or an updated Match walkthrough evidence file

**Status**: [ ] Not yet created

---

## Definition of Done

- [ ] Existing Match route and handoff tests still pass.
- [ ] Screenshot or walkthrough evidence exists for the reviewed Match Pre / Live / Result states.
- [ ] No new route IDs, gameplay rules, halftime commands, or schema contracts were introduced.
- [ ] Code review confirms presentation-only scope was preserved.
- [ ] Any advisory deviations are documented rather than silently introduced.
