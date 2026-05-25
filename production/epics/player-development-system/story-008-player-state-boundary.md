# Story 008: 实现赛后状态消费与下游写保护边界

> **Epic**: 运动员培养系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Integration
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/player-development-system.md`
**Requirement**: `TR-playerdev-002`, `TR-playerdev-001`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-playerdev-002`: fatigue_adjusted_training_efficiency = efficiency × condition × morale, clamped [0.5, 1.8]
- `TR-playerdev-001`: Player must have: id, name, age, position, 5 attrs, train_efficiency, condition, morale, history, milestones

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0005: Player Data Model
**ADR Decision Summary**: PlayerDevelopment owns authoritative long-term player state; downstream systems may provide state changes through formal boundaries but must not directly mutate player attributes or growth fields.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `RefCounted`, `Resource`, and `Dictionary` serialization are stable Godot 4.x APIs; no post-cutoff API verification required.

**Control Manifest Rules (this layer)**:
- Required: EventBus is the sole cross-system communication channel for Foundation→Core, Core→Core, and Core→UI messages.
- Forbidden: Never mix a hybrid communication model where Core systems call each other directly while UI alone uses EventBus.
- Guardrail: EventBus steady-state memory <50KB.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/player-development-system.md`, scoped to this story:*

- [ ] Match-provided condition and morale changes affect the next training settlement.
- [ ] Downstream systems cannot bypass formal interfaces to directly modify long-term attributes, `potential_cap`, or `training_efficiency`.
- [ ] Conflicting state updates are rejected or marked for review instead of silently overwriting authoritative player state.

---

## Implementation Notes

*Derived from ADR-0005 Implementation Guidelines:*

Keep PlayerDevelopment as the owner of player long-term state and expose controlled methods for applying external state changes. Consume match/state events through EventBus or formal integration points with serializable Dictionary payloads. Reject or flag attempts to mutate authoritative player fields outside the declared PlayerDevelopment or Balance-system boundaries.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Match simulation internals and exact post-match state formula contents.
- UI messaging for conflict review or state warnings.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 比赛系统回传的 condition/morale 变化会在下一次训练结算中生效。
  - Given: 一名球员在比赛后收到明确的 condition/morale 变化，且其他训练输入保持不变。
  - When: 执行其下一次训练结算。
  - Then: 本次训练使用更新后的 condition/morale 参与有效训练效率计算，而非使用比赛前旧值。
  - Edge cases: 连续多场比赛后再训练，应使用最新已确认状态；若比赛未产生状态变化，则训练结果与基线一致。

- **AC-2**: 下游系统不得绕过正式接口直接改写长期属性、potential_cap 或 training_efficiency。
  - Given: 一个下游系统尝试通过非正式路径改写长期属性、potential_cap 或 training_efficiency。
  - When: 提交该写入请求并执行校验。
  - Then: 该写入被拒绝、忽略或转为复核，不会直接落入权威状态。
  - Edge cases: 通过正式接口的合法写入应正常生效；只读查询不应被误判为非法修改。

- **AC-3**: 冲突状态不会静默覆盖，至少会拒绝或标记复核。
  - Given: 同一球员存在两份相互冲突的状态更新请求，或旧版本状态尝试覆盖新版本状态。
  - When: 应用更新。
  - Then: 系统不会静默采用后写覆盖前写；至少有一方被拒绝或被标记复核。
  - Edge cases: 内容完全相同的重复写入不应被误报为冲突；冲突发生在读档恢复后也必须可检测。

---

## Test Evidence

**Story Type**: Integration
**Required evidence**:
- Integration: `tests/integration/player-dev/player_state_boundary_test.gd` OR playtest doc

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/player-development-system/story-002-training-efficiency-formula.md` — must be DONE
  - `production/epics/player-development-system/story-006-training-atomic-integration.md` — must be DONE
  - `production/epics/match-competition-system/story-006-match-result-packet.md` — must be DONE
- Unlocks:
  - `production/epics/player-development-system/story-009-player-development-regression.md`
