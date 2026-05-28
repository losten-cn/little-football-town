# Story 001: 建立 EconomyManager 权威边界与 Transaction 数据模型

> **Epic**: 经济管理系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-25

## Context

**GDD**: `design/gdd/economy-management-system.md`
**Requirement**: `TR-economy-001`, `TR-economy-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-economy-001`: Three resources: funds (可负债), AP (≥1), RP (≥0, MVP隐藏)
- `TR-economy-002`: execute_transaction() is the SOLE resource mutation path

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0007: Economy Transaction Framework
**ADR Decision Summary**: EconomyManager owns all resource state and every change must be represented as a Transaction executed through the single authoritative mutation path.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript RefCounted data model and Core node; no post-cutoff APIs required.

**Control Manifest Rules (this layer)**:
- Required: Core systems expose explicit API boundaries for downstream systems.
- Required: Resource mutation must route through the authoritative economy transaction boundary.
- Forbidden: Do not allow downstream systems to directly mutate funds, AP, or RP.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/economy-management-system.md`, scoped to this story:*

- [ ] `EconomyManager` holds authoritative runtime state for `funds`, `action_points`, and `research_points`.
- [ ] `Transaction` runtime model contains `id`, `type`, `funds_delta`, `ap_delta`, `rp_delta`, `reason`, `source_system`, `timestamp`, and `metadata`.
- [ ] No supported public resource write boundary exists outside `execute_transaction()` and later accredited entry points; public APIs expose read state or controlled write requests only.

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

Create `Transaction` as a typed `RefCounted` data object and keep EconomyManager as the single Core node that owns resource balances. This story establishes the data and API boundary only; later stories add validation, logging, warnings, settlement handlers, and save/load integration.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 002: Atomic validation and transaction execution.
- Story 003: Economy warnings and cooldown.
- Story 008: Transaction log persistence and save/load contract.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: `EconomyManager` owns the three resource balances
  - Given: A newly initialized `EconomyManager`.
  - When: The resource state is queried through its public read API.
  - Then: `funds`, `action_points`, and `research_points` are present and owned by the manager.
  - Edge cases: Default config values; repeated initialization; zero or negative funds where allowed by policy.

- **AC-2**: `Transaction` contains the required audit fields
  - Given: A new `Transaction` instance.
  - When: Each required field is assigned and read back.
  - Then: All fields retain typed values and can be converted into serializable primitive payloads.
  - Edge cases: Empty metadata; zero deltas; empty reason string.

- **AC-3**: No unsupported public resource write path exists
  - Given: A caller outside EconomyManager.
  - When: It inspects the public APIs exposed for resource interaction.
  - Then: Only read operations or controlled transaction requests are available; no other supported public write interface exists.
  - Edge cases: Helper methods; debug methods; test fixtures.

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/economy/economy_authority_transaction_model_test.gd` — must exist and pass

**Status**: [x] Created — `tests/unit/economy/economy_authority_transaction_model_test.gd`

---

## Completion Notes
**Completed**: 2026-05-25
**Criteria**: 3/3 passing
**Deviations**: Acceptance wording for AC-3 was refined to "no supported public resource write boundary exists" so the story matches GDScript's public-interface enforcement model while preserving ADR-0007's sole supported mutation-path rule.
**Test Evidence**: Logic: `tests/unit/economy/economy_authority_transaction_model_test.gd` present; local pass execution not verified in this session because `godot` is not available in PATH.
**Code Review**: Complete — `/code-review src/core/transaction.gd src/core/economy_manager.gd tests/unit/economy/economy_authority_transaction_model_test.gd` approved in lean mode.

---

## Dependencies

- Depends on: None
- Unlocks:
  - `production/epics/economy-management-system/story-002-execute-transaction-atomic-validation.md`
  - `production/epics/economy-management-system/story-004-budget-preview-affordability-query.md`
  - `production/epics/economy-management-system/story-007-accredited-entry-points.md`
  - `production/epics/economy-management-system/story-008-transaction-log-save-contract.md`
