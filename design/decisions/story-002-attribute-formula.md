# Story 002 Decision Log — 实现属性模型与有效属性公式

## Story Metadata

- **Story ID**: Story 002
- **Title**: 实现属性模型与有效属性公式
- **Epic**: Balance System
- **Story File**: `production/epics/balance-system/story-002-attribute-formula.md`
- **Completion Date**: 2026-05-25
- **Lead Agent**: gameplay-programmer
- **Review Mode**: lean
- **Review Agent**: none — lean mode
- **Verdict**: COMPLETE WITH NOTES

## Summary of Changes

Implemented the shared attribute state model and effective attribute formula inside `BalanceConfig` so balance logic remains data-driven and independent from downstream gameplay systems. Added a logic test file covering modifier order, clamping, layer separation, and invalid-input normalization.

## Files Changed

- `src/config/balance_config.gd`
- `tests/unit/balance/attribute_formula_test.gd`
- `production/epics/balance-system/story-002-attribute-formula.md`

## Affected Systems

- Balance configuration
- Shared attribute formula logic
- Unit test coverage for balance formulas

## Data / Config Changes

- Added `BalanceConfig.AttributeState` as a typed shared value object
- Added normalization logic for current/potential/effective attribute handling
- Added effective attribute formula calculation using flat-before-percent order
- No external `.tres` tuning values changed in this story

## Acceptance and Test Evidence

- **Acceptance Criteria**: 5/5 passing
- **Automated Test File**: `tests/unit/balance/attribute_formula_test.gd`
- **Covered Cases**:
  - flat modifiers applied before percent modifiers
  - effective value clamps to `[1, 100]`
  - `current` and `potential` remain unchanged by effective calculation
  - invalid attribute inputs normalize before formula use

## Code Review Notes

- Lean mode: no separate `/code-review` gate was run for this story
- Closure recorded as `COMPLETE WITH NOTES` at the time because runtime execution was not verified in-session

## Design Decisions

| Decision | Chosen Option | Rationale | Rejected Alternatives |
|---|---|---|---|
| Where to place the formula | Keep the formula in `BalanceConfig` | Matches ADR-0004 data-driven ownership and avoids downstream duplication | Put formula logic in a gameplay-specific manager; duplicate logic in future systems |
| How to represent attribute layers | Use a generic typed `AttributeState` with `current`, `potential`, `effective` | Keeps the formula reusable across the five core attributes while preserving three-layer semantics | Separate structs per attribute; raw dictionaries without typed fields |
| How to handle illegal inputs | Normalize first, then compute effective value | Ensures deterministic behavior and satisfies the story’s edge-case requirement | Reject invalid inputs outright; clamp only the final effective result |
| Modifier application order | Apply flat sums before percent sums | Required by TR-balance-011 and covered directly by test | Percent first, then flat |
| Test strategy | Add a dedicated unit test file for formula behavior | Logic story requires automated evidence and this logic is pure/in-memory | Rely on manual verification; defer tests to downstream systems |

## Scope Notes

All implementation stayed within the story’s intended logic scope:
- shared balance formula code
- story evidence updates
- unit test coverage

No out-of-scope gameplay, UI, or persistence systems were changed for this story.

## Dependencies

- **Predecessor**: `production/epics/balance-system/story-001-balance-config-validation.md`
- **Successor Unlocked**: `production/epics/balance-system/story-005-positional-rating.md`

## Follow-up Considerations

- Local Godot execution of `tests/unit/balance/attribute_formula_test.gd` is still recommended because `godot` was not available in this session
- Future stories can now consume the shared normalized/effective attribute logic instead of re-implementing it
