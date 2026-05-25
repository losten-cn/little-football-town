# Story 004: 实现球员层级、潜力区间与训练效率差异

> **Epic**: 运动员培养系统
> **Status**: Ready
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: set by /dev-story when implementation begins

## Context

**GDD**: `design/gdd/player-development-system.md`
**Requirement**: `TR-playerdev-009`, `TR-playerdev-010`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-playerdev-009`: Tier potential bands: 普通(60-75), 优秀(72-85), 明星(82-95), 传奇胚子(90-99)
- `TR-playerdev-010`: Individual training_efficiency ∈ [0.8, 1.5] per player

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0005: Player Data Model
**ADR Decision Summary**: Player tier and training efficiency are authoritative player fields; tier determines potential bands and supports differentiated player growth value.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: `RefCounted`, `Resource`, and `Dictionary` serialization are stable Godot 4.x APIs; no post-cutoff API verification required.

**Control Manifest Rules (this layer)**:
- Required: All config domains must be typed Custom Resources with a `validate()` contract enforced by `ConfigLoader`.
- Forbidden: Never model runtime players as individual Resource assets or plain nested Dictionaries.
- Guardrail: Player runtime memory ~25KB target for roster structures.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/player-development-system.md`, scoped to this story:*

- [ ] Four player tiers have verifiable potential band mapping and training efficiency differences.
- [ ] Each player's `potential_cap` falls inside its tier's default band, unless marked as a special individual with an explicit source.
- [ ] With identical conditions, the player with higher `training_efficiency` gains more from the same training unless potential cap clipping applies.

---

## Implementation Notes

*Derived from ADR-0005 Implementation Guidelines:*

Store `Player.tier` and `Player.training_efficiency` as typed authoritative fields. Use tier mapping to constrain generated or assigned potential values. Keep tier band and efficiency validation deterministic and data-driven so QA can sample tier differences without relying on random distribution.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 005: ROI sample comparisons between player tiers.
- Presentation UI stories: Recruitment or player detail visual presentation of tier labels.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: 四类球员层级具有可验证的潜力区间映射与训练效率差异。
  - Given: 四类 tier 的球员样本各至少一名，且 tier 默认配置已定义潜力区间与训练效率差异。
  - When: 校验每名球员的 tier、潜力区间映射与训练效率配置。
  - Then: 每个 tier 都能映射到其默认潜力区间，且训练效率差异与 tier 配置一致，可被明确区分。
  - Edge cases: 落在区间最小值或最大值的 potential_cap 视为合法；tier 配置缺失应直接失败而非回退到隐式默认值。

- **AC-2**: 每名球员的 potential_cap 必须落在其 tier 默认区间内，特殊个体需标记来源。
  - Given: 一名普通球员的 potential_cap 位于 tier 区间内，另一名特殊球员的 potential_cap 超出区间但带有来源标记。
  - When: 执行球员层级与潜力校验。
  - Then: 普通球员通过；超区间球员只有在携带明确来源标记时才允许通过，否则进入复核/失败。
  - Edge cases: 超区间但缺少来源标记不得静默接受；来源标记存在但无内容也视为无效。

- **AC-3**: 同条件训练下，更高 training_efficiency 的球员成长更高，除非被潜力上限裁剪。
  - Given: 两名除 training_efficiency 外完全相同的球员，先使用“都有足够成长空间”的样本，再使用“高效率样本接近 cap”的样本。
  - When: 执行同一训练结算。
  - Then: 在不触发 cap 裁剪时，高 training_efficiency 样本的成长严格更高；若触发 cap 裁剪，则差异可被上限裁剪解释。
  - Edge cases: training_efficiency 相等时成长应相等；被 cap 裁剪导致相等或反超时，不应误判为公式错误。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/player-dev/player_tier_band_test.gd` — must exist and pass

**Status**: [ ] Not yet created

---

## Dependencies

- Depends on:
  - `production/epics/player-development-system/story-001-player-data-serialization-boundary.md` — must be DONE
  - `production/epics/player-development-system/story-002-training-efficiency-formula.md` — must be DONE
- Unlocks:
  - `production/epics/player-development-system/story-005-training-roi.md`
