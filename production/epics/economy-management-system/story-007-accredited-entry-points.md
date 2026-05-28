# Story 007: 实现认证入口与 caller 约束

> **Epic**: 经济管理系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-28

## Context

**GDD**: `design/gdd/economy-management-system.md`
**Requirement**: `TR-economy-011`, `TR-economy-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-economy-011`: Accredited entry points: accredit_match_reward, accredit_facility_cost, accredit_training_cost
- `TR-economy-002`: execute_transaction() is the SOLE resource mutation path

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0007: Economy Transaction Framework
**ADR Decision Summary**: Downstream systems request resource changes through accredited caller-specific entry points that delegate to `execute_transaction()`.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript API boundary and Dictionary metadata; no post-cutoff APIs required.

**Control Manifest Rules (this layer)**:
- Required: Downstream systems must use accredited economy entry points.
- Required: Transactions include source and reason metadata for auditability.
- Forbidden: Match, Town, or Player systems must not directly mutate economy balances.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/economy-management-system.md`, scoped to this story:*

- [x] `accredit_match_reward()`, `accredit_facility_cost()`, and `accredit_training_cost()` exist and delegate to `execute_transaction()`.
- [x] Each accredited entry writes correct `source_system`, `reason`, and `metadata` for transaction audit.
- [x] Downstream systems cannot successfully modify balances through unaccredited resource write paths.

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

Accredited methods are the public cross-system contract for MatchCompetition, TownBuilding, and PlayerDevelopment. Build transaction metadata that can carry `match_id`, `facility_id`, or `player_id` without coupling EconomyManager to those systems' internal objects.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Caller business workflows.
- UI affordability display.
- Save/load persistence.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: Accredited entry points delegate to execute_transaction
  - Given: Match reward, facility cost, and training cost scenarios.
  - When: Each accredited method is called.
  - Then: Each resource change is executed through `execute_transaction()`.
  - Edge cases: Zero-cost training; facility cost with funds only; reward with no RP.

- **AC-2**: Audit metadata is complete
  - Given: Valid calls through each accredited method.
  - When: Transactions are committed.
  - Then: Transaction history contains correct `source_system`, `reason`, and metadata values.
  - Edge cases: Missing optional metadata; repeated match id; localized reason text.

- **AC-3**: Unaccredited writes cannot modify resources
  - Given: A downstream caller without a valid accredited path.
  - When: It attempts to modify balances.
  - Then: Balances do not change and a traceable failure is returned.
  - Edge cases: Spoofed source_system; duplicate request; empty caller identity.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/economy/accredited_entry_points_test.gd` OR playtest doc

**Status**: [x] Created and verified — `ACCREDITED_ENTRY_POINTS_TEST_PASS`

---

## Dependencies

- Depends on:
  - `production/epics/economy-management-system/story-001-economy-authority-transaction-model.md` — must be DONE
  - `production/epics/economy-management-system/story-002-execute-transaction-atomic-validation.md` — must be DONE
- Unlocks:
  - Downstream work: PlayerDevelopment, TownBuilding, and MatchCompetition economy integration

## Completion Notes
**Completed**: 2026-05-28
**Criteria**: 3/3 passing
**Deviations**: Advisory only — internal authorization token was introduced to preserve the sole `execute_transaction()` mutation boundary while preventing spoofed business `source_system` writes; Town construction now uses a dedicated `accredit_facility_construction_cost()` accredited entry so build requests can enforce stricter insufficient-funds rejection without changing the debt-capable facility-upgrade path.
**Test Evidence**: Integration test at `tests/integration/economy/accredited_entry_points_test.gd` — PASS (`ACCREDITED_ENTRY_POINTS_TEST_PASS`); supporting regressions passed in `tests/integration/economy/budget_preview_affordability_query_test.gd`, `tests/integration/town/build_request_validation_test.gd`, and `tests/integration/town/upgrade_completion_flow_test.gd`
**Code Review**: Complete — APPROVED WITH SUGGESTIONS
