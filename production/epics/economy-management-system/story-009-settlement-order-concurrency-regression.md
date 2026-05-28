# Story 009: 实现结算顺序、并发请求拒绝与经济回归验证

> **Epic**: 经济管理系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-27

## Context

**GDD**: `design/gdd/economy-management-system.md`
**Requirement**: `TR-economy-003`, `TR-economy-005`, `TR-economy-010`, `TR-economy-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-economy-003`: Pre-validation rejects transactions violating resource floors
- `TR-economy-005`: Three settlement stages: post-match, stage settlement, season settlement
- `TR-economy-010`: Transaction log retained (last ~200), serialized in save
- `TR-economy-012`: Warning cooldown per threshold type to prevent alert spam

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0007: Economy Transaction Framework
**ADR Decision Summary**: EconomyManager serializes resource mutations through atomic transactions so simultaneous requests and adjacent settlements preserve ledger correctness.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Deterministic EventBus processing and integration regression tests; no post-cutoff APIs required.

**Control Manifest Rules (this layer)**:
- Required: Resource changes must remain deterministic under same-frame events.
- Required: Economy ledger must reconcile income, spending, clamping, and rejected transactions.
- Guardrail: Bounded transaction history and warning cooldown must remain stable under batch settlement.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/economy-management-system.md`, scoped to this story:*

- [x] If post-match and daily/stage/season settlement signals arrive adjacent or in the same frame, EconomyManager processes them in a fixed serial priority without interleaving balance writes.
- [x] Multiple same-frame training/building cost requests validate in submission order against latest balances; later insufficient requests fail without dirty state.
- [x] A representative season regression satisfies ledger integrity: `ending_balance = starting_balance + total_income - total_spending`, adjusted only by legal clamp/debt rules.

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

This is the economy epic regression story. Reuse transaction, warning, settlement, accredited entry, and save-log behavior from prior stories; do not add new formulas here. The goal is evidence that the single authority and atomicity rules survive realistic ordering pressure.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- New resource formulas.
- UI settlement presentation.
- New save/load features beyond economy state validation.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: Settlement signals process serially in fixed order
  - Given: Post-match, daily, stage, and season settlement signals arrive close together.
  - When: EconomyManager handles the batch.
  - Then: Settlement transactions apply in fixed priority, with no interleaved writes.
  - Edge cases: Same-frame double signal; all settlement types queued; earlier settlement triggers warning.

- **AC-2**: Same-frame cost requests validate against latest balances
  - Given: Multiple training and construction cost requests whose combined cost exceeds available resources.
  - When: Requests are submitted in the same frame.
  - Then: Earlier valid requests succeed, later insufficient requests fail, and failed requests leave no partial deltas.
  - Edge cases: First request fails; first two succeed and third fails; duplicate request object.

- **AC-3**: Representative season ledger reconciles
  - Given: A sample season containing daily, post-match, stage, and season settlements.
  - When: Total income, total spending, and ending balances are calculated.
  - Then: The ledger reconciles with legal clamp/debt adjustments and all settlement validity checks pass.
  - Edge cases: Negative funds; RP cap overflow; rejected transaction during the season.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/economy/settlement_order_concurrency_regression_test.gd` OR playtest doc

**Status**: [x] Created — `tests/integration/economy/settlement_order_concurrency_regression_test.gd`

---

## Completion Notes

**Completed**: 2026-05-27  
**Criteria**: 3/3 passing  
**Deviations**: None  
**Test Evidence**: Integration: `tests/integration/economy/settlement_order_concurrency_regression_test.gd`  
**Code Review**: Approved with suggestions  
**Review Notes**: Fixed ordering, same-frame rejection behavior, representative ledger reconciliation, bounded transaction history, and settlement-side atomicity all passed review. Remaining feedback is advisory only around future queue-level same-frame signal coverage and explicit batch cooldown assertions if the event scheduler grows more complex.  
**Story Done Verdict**: Complete — automated integration evidence passed for fixed settlement ordering, same-frame cost rejection, and representative season ledger reconciliation.

---

## Dependencies

- Depends on:
  - `production/epics/economy-management-system/story-003-warning-threshold-cooldown-events.md` — must be DONE
  - `production/epics/economy-management-system/story-005-daily-recovery-maintenance-settlement.md` — must be DONE
  - `production/epics/economy-management-system/story-006-staged-settlement-formulas.md` — must be DONE
  - `production/epics/economy-management-system/story-007-accredited-entry-points.md` — must be DONE
  - `production/epics/economy-management-system/story-008-transaction-log-save-contract.md` — must be DONE
- Unlocks:
  - Downstream work: Economy epic completion gate
