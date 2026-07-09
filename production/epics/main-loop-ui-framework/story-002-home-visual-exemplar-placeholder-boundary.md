# Story 002: Home visual exemplar and placeholder boundary

> **Epic**: 主循环 UI 框架
> **Status**: Complete
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: S
> **Manifest Version**: 2026-07-05
> **Last Updated**: 2026-07-08

## Context

**GDD**: `design/gdd/main-loop-ui-framework.md`  
**Requirement**: `TR-mainui-001`, `TR-mainui-004`, `TR-mainui-005`, `TR-mainui-006`, `TR-mainui-007`

This story is a Production follow-through story for the Home and shell exemplar surfaces identified in:

- `production/qa/evidence/production-visual-exemplar-placeholder-tolerance-2026-07-05.md`
- `production/gate-checks/2026-07-05-pre-production-to-production-followup.md`

It does not reopen route topology, `ScreenManager`, gameplay authority, or the existing Home → Player/Training → Match → Result → Home loop. It turns the current Home/shell visual baseline into an explicit production-follow-through acceptance target.

**ADR Governing Implementation**:

- Primary: ADR-0001 — Scene Management & Autoload Architecture
- Secondary: ADR-0002 — Event/Signal Architecture + TimeManager
- Secondary: ADR-0010 — Cross-System Payload and Settlement Contracts

**ADR Decision Summary**:

- ADR-0001 requires screen flows to use the `ScreenManager` stack and stable screen lifecycle.
- ADR-0002 requires EventBus for cross-system notifications and forbids ad hoc direct UI coupling.
- ADR-0010 requires UI to consume authoritative payloads and never recompute gameplay truth.

**Engine**: Godot 4.6 | **Risk**: Medium

**Engine Notes**:

- UI must respect Godot 4.6 Control focus behavior and avoid introducing focus ambiguity.
- The project targets PC keyboard/mouse only.
- The game is a 2D pixel-art management sim and must keep the Compatibility renderer / warm readable UI baseline.

**Control Manifest Rules (Presentation / Foundation)**:

- Required: All screen flows must use the Screen Stack pattern managed by `ScreenManager`.
- Required: UI screens must respect the `Screen` lifecycle and subscribe/unsubscribe from events at the correct lifecycle boundaries.
- Required: UI modules must consume snapshots, explanations, labels, acknowledgement flags, and visibility stages as read-only payloads.
- Forbidden: Never poll Core state from `_process()` for routine UI refresh when an EventBus update exists.
- Forbidden: Never recompute roster, training, economy, league, match, or route availability truth in UI.
- Forbidden: Never resolve authority nodes through hardcoded `NodePath`, arbitrary scene-tree search, or implicit pseudo-singletons.
- Guardrail: UI implementations must stay within the global 60fps / 16ms frame budget and 500 draw-call ceiling.

---

## Acceptance Criteria

- [ ] Home initial, Home after training, Home final, and Home match-disabled-reason states remain inside the existing MainLoop Shell with the same route IDs and return-path behavior.
- [ ] Home preserves the approved warm-town visual direction: cream/warm neutral panel base, readable deep text, restrained semantic accents, and no dark corporate default UI treatment.
- [ ] Home shows a production-representative layout for date/phase, next match, team summary, action windows, resources, next action, and town warmth without exceeding the GDD `home_info_density` constraint.
- [ ] Any placeholder on Home is allowed only if it does not hide critical actions, create route ambiguity, expose internal IDs/enums/debug labels, imply false interaction, or obscure the return path to Home.
- [ ] Match unavailable / disabled state on Home gives a player-facing reason and does not appear as a silent gray-box or broken action.
- [ ] Home visual polish does not add new gameplay systems, new route IDs, new save/event schema, or new interaction depth.
- [ ] Home and shell continue to consume authoritative payloads only; they do not recompute roster truth, training availability, economy values, league state, match trigger state, or match results.
- [ ] Home supports stable screenshot review for the exemplar surfaces listed in `production-visual-exemplar-placeholder-tolerance-2026-07-05.md`.
- [ ] Focus, hover, disabled, and selected states remain understandable without color alone in the reviewed Home route.
- [ ] Existing route guardrails still pass after the visual exemplar pass.

---

## Implementation Notes

This story is a small visual-boundary and presentation-readiness pass, not a route or gameplay refactor.

Use the existing MainLoop Shell and Home route. Preserve:

- route IDs: `home`, `roster`, `player_detail`, `training`, `match_pre`, `match_live`, `match_result`
- `shell_top_bar`
- `shell_main_content`
- `shell_bottom_bar`
- existing Home return paths
- current request/event authority boundaries

If any new display field is needed, add it through the authoritative payload owner first; do not synthesize gameplay truth in UI.

Allowed changes:

- improve Home panel grouping and spacing;
- replace or refine Home placeholder visual elements;
- make disabled-state reason visually clearer;
- strengthen warm-town visual treatment;
- improve focus / disabled / hover readability;
- add screenshot evidence or QA walkthrough evidence.

Not allowed:

- changing `ScreenManager`;
- adding new route IDs;
- changing gameplay authority;
- changing save/event schema;
- recomputing gameplay truth locally;
- adding new Player, Match, Town, Audio, Tutorial, or Random Event functionality;
- replacing Player/Training/Match page internals.

---

## Out of Scope

Handled by neighboring or future stories:

- Player/Training visual exemplar stabilization — future `player-management-ui` follow-up story.
- Match Pre/Live/Result visual exemplar stabilization — future `match-performance-ui` follow-up story.
- First-pass production art replacement for Match surfaces.
- Full Town Management UI.
- Audio settings UI or audio event playback.
- Tutorial / Hint persistence, cooldown, replay, analytics, or help index.
- Random Event UI.
- Skill/Trait growth summary implementation beyond existing Home/shell placeholders.
- Any new gameplay or economy logic.

---

## QA Test Cases

Manual verification and interaction evidence are required because this is a UI / visual-readiness story.

- **AC-1**: Home route states remain in MainLoop Shell
  - Setup: Launch the MVP route and reach Home initial, Home after training, Home with match disabled reason, and Home final.
  - Verify: Each state appears inside the existing top/main/bottom shell and preserves existing route IDs.
  - Pass condition: No wrong route, blank page, blocking modal, or changed return path is observed.

- **AC-2**: Warm-town visual direction is preserved
  - Setup: Review Home screenshots after the visual pass.
  - Verify: Home uses warm/cream/neutral readable panels, deep readable text, restrained semantic accents, and avoids dark corporate dashboard treatment.
  - Pass condition: Home matches the Art Bible direction and does not violate the not-allowed placeholder list.

- **AC-3**: Placeholder tolerance rule is enforced
  - Setup: Inspect all Home placeholder elements.
  - Verify: No placeholder hides a critical action, exposes debug/internal labels, looks falsely clickable, or breaks the return path.
  - Pass condition: Any remaining placeholder fits the allowed-placeholder rule from `production-visual-exemplar-placeholder-tolerance-2026-07-05.md`.

- **AC-4**: Disabled match entry remains player-facing
  - Setup: Reach the Home state where match entry is unavailable.
  - Verify: The disabled match state includes a readable reason and next-step implication.
  - Pass condition: The unavailable action is not a silent gray-box and does not look like a broken button.

- **AC-5**: No gameplay authority or route topology changes
  - Setup: Compare the visual pass with the existing MVP route tests.
  - Verify: No new route IDs, no `ScreenManager` change, no gameplay authority change, no save/event schema change.
  - Pass condition: Existing UI route guardrails still pass.

- **AC-6**: Accessibility basics remain intact
  - Setup: Review focus, hover, selected, and disabled states on Home.
  - Verify: Critical state differences are understandable without color alone.
  - Pass condition: No reviewed Home interaction relies solely on hue or low-contrast visual treatment.

---

## Test Evidence

**Story Type**: UI

**Required evidence**:

- Manual visual evidence:
  - `production/qa/evidence/home-visual-exemplar-placeholder-boundary-2026-07-05.md`
- Automated guardrails:
  - `MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS`
  - `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`
  - `MVP_VISUAL_WALKTHROUGH_PASS` or an updated visual walkthrough evidence file

**Status**: [x] Structure / route evidence and visible-window screenshot review completed

---

## Completion Notes
**Completed**: 2026-07-08
**Criteria**: 10/10 passing
**Deviations**: Advisory only — Home 的 next match summary 仍有少量展示层文案判断，可在后续 story 中继续收口到 authority view-model；当前是 production-representative visual exemplar，不是 final art pass。
**Test Evidence**: UI evidence at `production/qa/evidence/home-visual-exemplar-placeholder-boundary-2026-07-05.md`; automated guardrails `MAIN_LOOP_SHELL_NAVIGATION_TEST_PASS`, `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`, `MVP_VISUAL_WALKTHROUGH_PASS`.
**Code Review**: Complete — `/code-review` passed / approved with suggestions in lean mode.

## Dependencies

- Depends on:
  - `production/epics/main-loop-ui-framework/story-001-home-loop-navigation.md`
  - `production/qa/evidence/production-visual-exemplar-placeholder-tolerance-2026-07-05.md`
  - `docs/architecture/control-manifest.md` Manifest Version `2026-07-05`
- Parallel with:
  - None for first implementation pass
- Unlocks:
  - `player-management-ui` visual exemplar follow-up story
  - `match-performance-ui` visual exemplar follow-up story
  - future Home + Match production art pass screenshot evidence
