# Story 002: 实现 execute_transaction 原子执行与资源底线校验

> **Epic**: 经济管理系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-26

## Context

**GDD**: `design/gdd/economy-management-system.md`
**Requirement**: `TR-economy-001`, `TR-economy-002`, `TR-economy-003`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-economy-001`: Three resources: funds (可负债), AP (≥1), RP (≥0, MVP隐藏)
- `TR-economy-002`: execute_transaction() is the SOLE resource mutation path
- `TR-economy-003`: Pre-validation rejects transactions violating resource floors

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0007: Economy Transaction Framework
**ADR Decision Summary**: `execute_transaction()` validates resource floors before applying a transaction and commits all deltas atomically.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript arithmetic and Dictionary result payloads; no post-cutoff APIs required.

**Control Manifest Rules (this layer)**:
- Required: Resource changes must be atomic and auditable.
- Required: EconomyManager is the sole mutation boundary for funds, AP, and RP.
- Forbidden: Never apply partial resource deltas after validation failure.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/economy-management-system.md`, scoped to this story and resolved by ADR-0007 / `TR-economy-001`:*

- [ ] `execute_transaction()` validates before applying; failed validation returns failure and leaves all three resources unchanged.
- [ ] Resource floor policy is explicit and enforced: `funds` may enter debt, `action_points` must not drop below their configured floor, and `research_points` must not drop below `0`.
- [ ] Successful transactions receive unique increasing `tx_id` values and apply all deltas as one atomic commit.

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

Centralize floor checks in `_validate_transaction()` and call it before applying any delta. Treat a transaction as all-or-nothing.

### Readiness Resolution

For this story's implementation and tests, `funds` follow the Accepted ADR / TR baseline and are debt-capable. `action_points` must not drop below their configured floor, and `research_points` must not drop below `0`.

The conflicting GDD wording that states all resources share a lower bound of `0` is treated as stale for this story and does not override ADR-0007 or `TR-economy-001`.

All acceptance tests for this story must use the debt-capable `funds` policy.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: Warning events and cooldown.
- Story 006: Settlement formulas.
- Story 008: Transaction log retention and serialization.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: Validation failure leaves resources unchanged
  - Given: One legal transaction and one transaction that violates AP or RP floors.
  - When: Each is passed to `execute_transaction()`.
  - Then: The legal transaction applies completely; the invalid transaction returns failure and no balance changes.
  - Edge cases: Single-resource failure; multiple-resource failure; all deltas are zero.

- **AC-2**: Resource floors follow economy policy
  - Given: Balances near AP and RP floors, and funds already negative.
  - When: Transactions attempt to reduce AP/RP below floors or reduce funds further.
  - Then: AP/RP violations are rejected; funds debt behavior follows the configured debt policy.
  - Edge cases: AP exactly at floor; RP exactly 0; funds transitions from positive to negative.

- **AC-3**: Successful transactions receive increasing ids
  - Given: Several successful transactions with one failed transaction between them.
  - When: They are executed in order.
  - Then: Successful `tx_id` values are unique and increasing, and failed transactions do not create committed ids.
  - Edge cases: Retrying the same transaction object; system reload after restored `next_tx_id`.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/economy/execute_transaction_atomic_validation_test.gd` — must exist and pass

**Status**: [x] Created — `tests/unit/economy/execute_transaction_atomic_validation_test.gd`

---

## Completion Notes
**Completed**: 2026-05-26
**Criteria**: 3/3 passing
**Deviations**: Test entry was adapted to a `SceneTree` runner so Godot headless `--script` can execute it directly; `EconomyManager` now exposes `set_economy_config_for_testing()` and `get_transaction_log()` as minimal test/audit seams; local Godot runs still emit resource cleanup warnings at exit.
**Test Evidence**: Logic: `tests/unit/economy/execute_transaction_atomic_validation_test.gd` present and locally verified with `D:/Program Files/godot/Godot_v4.6.2-stable_win64_console.exe` (PASS).
**Code Review**: Complete — implementation gaps around auditability were closed and local Godot verification passed.

---

## Dependencies

- Depends on:
  - `production/epics/economy-management-system/story-001-economy-authority-transaction-model.md` — must be DONE
- Unlocks:
  - `production/epics/economy-management-system/story-003-warning-threshold-cooldown-events.md`
  - `production/epics/economy-management-system/story-005-daily-recovery-maintenance-settlement.md`
  - `production/epics/economy-management-system/story-006-staged-settlement-formulas.md`
  - `production/epics/economy-management-system/story-007-accredited-entry-points.md`
  - `production/epics/economy-management-system/story-009-settlement-order-concurrency-regression.md`
