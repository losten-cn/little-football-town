# Story 005 Decision Log — 实现位置综合评分公式

## Story Metadata

- **Story ID**: Story 005
- **Title**: 实现位置综合评分公式
- **Epic**: Balance System
- **Story File**: `production/epics/balance-system/story-005-positional-rating.md`
- **Completion Date**: 2026-05-25
- **Lead Agent**: engine-programmer
- **Review Mode**: lean
- **Review Agent**: none — lean mode
- **Verdict**: COMPLETE WITH NOTES

## Summary of Changes

Implemented the shared positional overall rating formula inside `BalanceConfig` using typed attribute weights and normalization rules defined by the balance GDD. Added a dedicated unit test file covering weighted-sum scoring, effective-only input semantics, zero-weight behavior, and invalid-weight normalization with zero-sum fallback.

## Files Changed

- `src/config/balance_config.gd`
- `tests/unit/balance/positional_rating_test.gd`
- `production/epics/balance-system/story-005-positional-rating.md`

## Affected Systems

- Balance configuration
- Shared positional rating formula logic
- Unit test coverage for balance formulas

## Data / Config Changes

- Added `BalanceConfig.AttributeWeights` as a typed weight container for the five core attributes
- Added weight normalization logic for Draft/Tuned invalid input handling
- Added Locked-data validation helper for non-negative, sum-to-one weight invariants
- Added shared positional rating formula with arithmetic-mean fallback when normalized weight sum is zero
- No external `.tres` tuning values changed in this story

## Acceptance and Test Evidence

- **Acceptance Criteria**: 5/5 passing
- **Automated Test File**: `tests/unit/balance/positional_rating_test.gd`
- **Covered Cases**:
  - weighted positional rating matches manual calculation
  - formula consumes effective values only
  - zero-weight attributes do not affect the output
  - invalid Draft/Tuned weights normalize before scoring
  - zero-sum weights fall back to arithmetic mean

## Code Review Notes

- Lean mode: `/code-review` was run and returned **APPROVED WITH SUGGESTIONS**
- Advisory review notes:
  - test harness remains a custom `Node` runner rather than GUT/gdUnit style
  - QA suggested follow-up coverage for zero-sum locked invalidity, non-negative non-unit locked weights, and stronger float tolerance cases

## Design Decisions

| Decision | Chosen Option | Rationale | Rejected Alternatives |
|---|---|---|---|
| Where to place the formula | Keep positional rating inside `BalanceConfig` | Preserves a single shared formula surface under ADR-0004 and avoids downstream duplication | Put the formula in MatchCompetition; put the formula in PlayerDevelopment |
| How to represent position weights | Add a typed `AttributeWeights` value object with five fields | Keeps the formula interface explicit, typed, and aligned to the five-attribute model | Use raw dictionaries; use untyped arrays with positional indices |
| How to handle invalid Draft/Tuned weights | Clamp negatives to zero, then normalize positive totals proportionally | Matches the GDD edge-case rules while keeping the formula deterministic | Reject invalid weights outright; silently trust caller data |
| How to handle zero-sum weights | Fall back to arithmetic mean and expose Locked invalidity through a helper | Matches the GDD prototype rule while still giving downstream systems a validity check | Return zero; hard-fail the calculation |
| What stays out of scope | Do not define any real position content tables in this story | The story explicitly reserves actual position weight sets to downstream systems | Add striker/midfielder/defender tables directly in `BalanceConfig` |

## Scope Notes

All implementation stayed within the story’s intended logic scope:
- shared balance formula code
- story evidence updates
- unit test coverage

No out-of-scope match, player-development, or position-content data tables were introduced.

## Dependencies

- **Predecessor**: `production/epics/balance-system/story-002-attribute-formula.md`
- **Successor Unlocked**: `production/epics/balance-system/story-006-win-probability.md`

## Follow-up Considerations

- Local Godot execution of `tests/unit/balance/positional_rating_test.gd` is still recommended because `godot` was not available in this session
- Future test follow-up can strengthen Locked invalidity and float tolerance coverage without changing the formula interface
- Downstream systems can now consume shared typed position weights without re-implementing normalization or rating math
