# Story 006: 实现赛后/阶段/赛季结算公式与 floor 舍入

> **Epic**: 经济管理系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/economy-management-system.md`
**Requirement**: `TR-economy-005`, `TR-economy-006`, `TR-economy-007`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-economy-005`: Three settlement stages: post-match, stage settlement, season settlement
- `TR-economy-006`: post_match_funds = base × result_multiplier × stadium × season_bonus
- `TR-economy-007`: Float-to-int conversion: all uses floor()

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0007: Economy Transaction Framework
**ADR Decision Summary**: EconomyManager owns post-match, stage, and season settlement handlers and applies resource outcomes through atomic transactions.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Deterministic formula arithmetic and EventBus settlement inputs; no post-cutoff APIs required.

**Control Manifest Rules (this layer)**:
- Required: Settlement events are processed deterministically through EconomyManager.
- Required: Float-to-int settlement conversions use explicit rounding rules.
- Guardrail: Settlement output must remain auditable through transaction history.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/economy-management-system.md`, scoped to this story:*

- [ ] Post-match settlement computes funds and RP from GDD formulas and applies `floor()` to all float-to-int resource results.
- [ ] Stage and season settlement handlers run independently and consume current season context rather than next-season state.
- [ ] Abnormal inputs follow GDD edge-case behavior, including clamping `tactical_rating_ratio` to `[0.3, 1.0]` and identifying discarded overflow at resource caps.

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

Implement settlement handlers as EventBus-driven economy operations that create transactions instead of writing balances directly. `TR-economy-006` mentions `season_bonus`, while the GDD formula uses `league_tier_multiplier × match_result_multiplier × stadium_revenue_multiplier`; keep this mismatch visible for readiness review and implement the GDD-scoped formula unless the registry is updated.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: Daily recovery and maintenance.
- UI settlement summary.
- League ranking calculations.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: Post-match settlement follows formulas and floor rounding
  - Given: Known match result, league tier, stadium multiplier, and tactical rating ratio.
  - When: Post-match settlement runs.
  - Then: Funds and RP match the GDD formulas with `floor()` applied.
  - Edge cases: Win/draw/loss multipliers; stadium multiplier 1.0; tactical ratio clamped high or low.

- **AC-2**: Stage and season settlements use current context
  - Given: Current season ranking and tier context are available.
  - When: Stage and season settlements run.
  - Then: They use current season state and do not apply next-season promotion or relegation early.
  - Edge cases: Final matchday; mid-table rank; stage boundary.

- **AC-3**: Abnormal inputs clamp or overflow safely
  - Given: Inputs outside normal ratio bounds and resources near caps.
  - When: Settlement runs.
  - Then: Ratios are clamped, resources are capped, and discarded overflow can be identified in the result.
  - Edge cases: RP at cap; AP full; tactical ratio below 0.3 or above 1.0.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/economy/staged_settlement_formulas_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/economy-management-system/story-002-execute-transaction-atomic-validation.md` — must be DONE
- Unlocks:
  - `production/epics/economy-management-system/story-009-settlement-order-concurrency-regression.md`
