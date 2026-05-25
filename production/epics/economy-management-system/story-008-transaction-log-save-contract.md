# Story 008: 实现交易流水上限与存档序列化契约

> **Epic**: 经济管理系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/economy-management-system.md`
**Requirement**: `TR-economy-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-economy-010`: Transaction log retained (last ~200), serialized in save

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0007: Economy Transaction Framework
**ADR Decision Summary**: EconomyManager stores a bounded transaction log and registers a serializable save contract for balances, ids, and recent transactions.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Resource-compatible Dictionary serialization and SaveManager registration; no post-cutoff APIs required.

**Control Manifest Rules (this layer)**:
- Required: Core systems register serialization contracts with SaveManager.
- Required: Save payloads contain primitives, typed Arrays, and Dictionaries only.
- Guardrail: Economy transaction history stays bounded to prevent save bloat.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/economy-management-system.md`, scoped to this story:*

- [ ] Transaction log retains only the latest approximately 200 entries in stable order; entry 201 evicts the oldest entry.
- [ ] `serialize()` / `deserialize()` restores all three balances, `next_tx_id`, and recent transaction log with state matching the pre-save economy state.
- [ ] EconomyManager registers with SaveManager and restores through the centralized load pipeline at the economy restore stage.

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

Keep committed transaction history bounded and serializable. Do not persist runtime object references. Restore `next_tx_id` so subsequent transactions remain unique after load.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Save slot UI.
- Save integrity hash and migration behavior.
- Full multi-system load-order regression.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: Transaction log retains latest 200 entries
  - Given: 201 successful transactions have been committed.
  - When: The recent transaction log is read.
  - Then: Only the latest 200 entries remain, in stable chronological order.
  - Edge cases: Exactly 200 entries; empty log; failed transactions not logged.

- **AC-2**: Economy save/load roundtrip restores state
  - Given: Balances, `next_tx_id`, and transaction history exist.
  - When: EconomyManager serializes and deserializes its state.
  - Then: Balances, id counter, and transaction log contents match the original state.
  - Edge cases: Negative funds; RP 0; empty metadata; empty log.

- **AC-3**: SaveManager registration is present
  - Given: SaveManager initializes registered Core systems.
  - When: EconomyManager enters the save/load pipeline.
  - Then: It is handled as an independent economy block at the expected restore stage.
  - Edge cases: Duplicate registration; missing economy save block; old save with optional fields absent.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/economy/transaction_log_save_contract_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/economy-management-system/story-001-economy-authority-transaction-model.md` — must be DONE
- Unlocks:
  - `production/epics/economy-management-system/story-009-settlement-order-concurrency-regression.md`
