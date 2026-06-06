# Story 001: 建立 Roster / Player Detail 最小切片与训练入口交接

> **Epic**: 球员管理 UI
> **Status**: Complete with warnings
> **Layer**: Presentation
> **Type**: UI
> **Estimate**: M
> **Manifest Version**: 2026-06-03
> **Last Updated**: 2026-06-03

## Context

**GDD**: `design/gdd/player-management-ui.md`  
**Requirement**: `TR-playerui-001`, `TR-playerui-002`, `TR-playerui-003`, `TR-playerui-004`, `TR-playerui-007`, `TR-playerui-008`, `TR-playerui-009`

This story is a topology L2 page package. It depends on MainLoop Shell route/container freeze and may be implemented in parallel with MatchPerfUI.

## Scope

### In Scope

- Implement `roster` page with the current-wave minimum list fields.
- Default sort by authoritative rating descending.
- Allow sorting by name and position.
- Add position filtering and `无匹配球员` empty result state.
- Implement `player_detail` with fixed section order: identity, attributes, growth, status, action entry.
- Use unified 1–100 attribute bars and distinct cap markers.
- Pass selected `player_id` into the training route.
- Disable training entry with a reason when AP or authoritative affordance blocks training.
- Provide stable interactive IDs for roster sort/filter/list rows and training entry.

## Acceptance Criteria

- [ ] Roster row shows no more than 7 fields and includes name, primary position, authoritative rating summary, development tier, status tag, and recent growth indicator.
- [ ] First roster load sorts by authoritative rating descending.
- [ ] Sorting by name or position applies immediately and resets the list to the first page/top.
- [ ] Position filter with no matching players displays `无匹配球员` instead of blank or stale results.
- [ ] Clicking a roster row opens `player_detail` inside the MainLoop Shell.
- [ ] Player detail sections appear in fixed order: identity → attributes → growth → status → action entry.
- [ ] Attribute display uses one consistent 1–100 visual scale and marks capped values distinctly.
- [ ] Rating, attributes, growth summary, and training affordance are consumed from authoritative payloads only.
- [ ] Clicking training entry passes the current `player_id` to the training route.
- [ ] If training is unavailable, the training entry is disabled and shows a clear reason.
- [ ] Sort controls, filter controls, roster rows, detail sections, and training entry expose stable interactive IDs.
- [ ] A first-time QA player can complete roster → player detail → training entry and explain who is strong, who is worth training, and where to click next within 30 seconds.

## Test Evidence

**Story Type**: UI  
**Required evidence**:
- Manual walkthrough: `production/qa/evidence/player-management-ui-story-001-roster-training-entry.md`

**Status**: [x] Created — `L2_PLAYABLE_LOOP_PANELS_TEST_PASS`

Walkthrough covers default roster sort, player detail, training entry handoff, and carried warnings for the full position filter/sort suite.

## Dependencies

- Depends on:
  - `production/epics/main-loop-ui-framework/story-001-home-loop-navigation.md`
  - `production/epics/balance-system/story-005-positional-rating.md`
  - `production/epics/player-development-system/story-001-player-data-serialization-boundary.md`
  - `production/epics/player-development-system/story-006-training-atomic-integration.md`
- Parallel with:
  - `production/epics/match-performance-ui/story-001-prematch-result-flow.md`

## Out of Scope

- Complete sorting/filtering suite, player compare, full roster management.
- Skill/Trait, identity history, or deep growth graph pages.
- Full onboarding/tutorial.
- Any change to player/save schema.
- UI-local recomputation of rating, attributes, growth, AP/funds, or training preview.

## Implementation Notes

- Keep roster scan-friendly; do not convert the slice into a spreadsheet.
- Detail page should help the player decide whether to train, not explain every future system.
- Training handoff must use stable route payload or equivalent context contract.
- If Skill/Trait data is not ready, omit it or show a low-noise placeholder without inventing local logic.

## Warnings Carried Forward

- Do not expand into full player management.
- Do not recompute `positional_overall_rating`, attributes, or `training_actual_gain` in UI.
- Any future Skill/Trait detail requires a separate story.
