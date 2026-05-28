# Story 003: 实现资源预警阈值、debt 预警与冷却机制

> **Epic**: 经济管理系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-26

## Context

**GDD**: `design/gdd/economy-management-system.md`
**Requirement**: `TR-economy-004`, `TR-economy-012`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-economy-004`: Warning thresholds: funds_low, ap_low, debt → emit economy_warning_triggered
- `TR-economy-012`: Warning cooldown per threshold type to prevent alert spam

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0007: Economy Transaction Framework
**ADR Decision Summary**: EconomyManager emits standardized warning events after successful resource changes, with cooldown tracked independently per warning type.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: EventBus signal integration and Dictionary payloads; no post-cutoff APIs required.

**Control Manifest Rules (this layer)**:
- Required: Cross-system notifications use EventBus rather than direct UI calls.
- Required: Warning payloads must be serializable primitive/Dictionary data.
- Guardrail: Warning cooldown prevents repeated alert spam during settlement cascades.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/economy-management-system.md`, scoped to this story:*

- [ ] After successful transactions or settlements, EconomyManager evaluates `funds_low`, `ap_low`, and `debt` warning conditions.
- [ ] When a warning first triggers or retriggers after cooldown, it emits `economy_warning_triggered` with `warning_type`, `current_value`, and `threshold`.
- [ ] Warning cooldown is tracked per threshold type so repeated settlement cascades do not spam duplicate warnings.

---

## Implementation Notes

*Derived from ADR-0007 Implementation Guidelines:*

Run warning checks after resource mutations have been committed. Emit through EventBus only; do not implement UI display behavior in this story. Track cooldown by warning type so `funds_low`, `ap_low`, and `debt` can fire independently.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- UI warning rendering.
- Budget Preview refresh behavior.
- Settlement summary presentation.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: Warning conditions are evaluated after resource changes
  - Given: Balances move from safe values into `funds_low`, `ap_low`, or `debt` ranges.
  - When: A successful transaction or settlement completes.
  - Then: The corresponding warning condition is detected.
  - Edge cases: Multiple warnings at once; exact threshold value; recovering from debt.

- **AC-2**: Warning event payload is complete
  - Given: A warning type is outside cooldown and newly active.
  - When: EconomyManager emits `economy_warning_triggered`.
  - Then: EventBus receives `warning_type`, `current_value`, and `threshold`.
  - Edge cases: Negative current value; threshold loaded from config; multiple warnings in one frame.

- **AC-3**: Cooldown prevents spam per warning type
  - Given: One warning type is already in cooldown.
  - When: Repeated transactions or settlements keep the same condition active.
  - Then: The same warning type does not re-emit until cooldown expires, while other warning types may still emit.
  - Edge cases: Cooldown boundary tick; value recovers then drops again; three warning types mixed.

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/economy/warning_threshold_cooldown_events_test.gd` OR playtest doc

**Status**: [x] Created and locally verified (`WARNING_THRESHOLD_COOLDOWN_EVENTS_TEST_PASS`)

---

## Completion Notes
**Completed**: 2026-05-26
**Criteria**: 3/3 passing
**Deviations**: `EconomyManager` exposes `set_event_bus_for_testing()` and `set_warning_cooldown_for_testing()` as minimal deterministic test seams; code review noted a low-risk runtime edge where cooldown is recorded before confirming EventBus availability, but this does not block the implemented Story 003 path.
**Test Evidence**: Integration: `tests/integration/economy/warning_threshold_cooldown_events_test.gd` present and locally verified with `D:/Program Files/godot/Godot_v4.6.2-stable_win64_console.exe` (PASS).
**Code Review**: Complete — Story 003 implementation approved with one non-blocking low-risk note.

---

## Dependencies

- Depends on:
  - `production/epics/economy-management-system/story-002-execute-transaction-atomic-validation.md` — must be DONE
- Unlocks:
  - `production/epics/economy-management-system/story-009-settlement-order-concurrency-regression.md`
