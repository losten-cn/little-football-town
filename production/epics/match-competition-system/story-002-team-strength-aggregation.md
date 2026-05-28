# Story 002: 实现阵容合法性、位置适配与队伍强度聚合

> **Epic**: 比赛竞技系统
> **Status**: Complete
> **Layer**: Core
> **Type**: Logic
> **Estimate**: M
> **Manifest Version**: 2026-05-19
> **Last Updated**: 2026-05-28

## Context

**GDD**: `design/gdd/match-competition-system.md`
**Requirement**: `TR-match-002`
*(Requirement text lives in `docs/architecture/tr-registry.yaml` — read fresh at review time)*

**GDD Rule / Acceptance Mapping**:
- `TR-match-002`: team_match_strength = weighted positional ratings × chemistry + facility_bonus

This story implements only the mapped rules above; neighbouring requirements remain out of scope unless listed below.

**ADR Governing Implementation**: ADR-0006: Match Simulation Architecture
**ADR Decision Summary**: MatchSimulation builds TeamProfile data from PlayerRoster lineup inputs and computes team strength from positional ratings, lineup weights, chemistry, and facility bonus.

**Engine**: Godot 4.6 | **Risk**: LOW
**Engine Notes**: Pure GDScript state machine and Dictionary math; no post-cutoff APIs used.

**Control Manifest Rules (this layer)**:
- Required: Produce a standardized match computation path that consumes PlayerRoster data from ADR-0005.
- Forbidden: Never implement match simulation as a one-shot black-box formula with no event flow.
- Guardrail: Full match simulation <20ms compute time target from ADR.

**Performance Note**: This story must respect the applicable Core guardrails from the control manifest and stay within the global 60fps / 16ms frame budget. No per-frame polling is expected unless explicitly listed in the acceptance criteria.

---

## Acceptance Criteria

*From GDD `design/gdd/match-competition-system.md`, scoped to this story:*

- [ ] `team_match_strength = weighted positional ratings × chemistry + facility bonus`.
- [ ] A player assigned out of preferred position receives lower `positional_overall_rating` than in a preferred position.
- [ ] Recommended lineup and recommended tactics allow a player to start a match without manual adjustment.

---

## Implementation Notes

*Derived from ADR-0006 Implementation Guidelines:*

Build a TeamProfile from 11 LineupSlot entries, selected tactics, chemistry factor, and facility rating bonus. Compute team strength as weighted positional rating average multiplied by chemistry, then add facility bonus. The positional rating formula is consumed from the balance/player data boundary; this story defines aggregation and legality behavior, not the shared rating formula itself.

---

## Out of Scope

*Handled by neighbouring stories — do not implement here:*

- Story 003: Converting team strength into actual win probability.
- Player Development stories: Authoritative player attributes and preferred-position data.

---

## QA Test Cases

*Written by qa-lead at story creation. The developer implements against these — do not invent new test cases during implementation.*

- **AC-1**: `team_match_strength = weighted positional ratings × chemistry + facility bonus`
  - Given: 一套已知球员评分、位置权重、chemistry 与 facility bonus 的固定阵容数据。
  - When: 计算 `team_match_strength`。
  - Then: 输出值与公式手工期望值一致，且各组成项都参与聚合。
  - Edge cases: chemistry 取低/高边界；facility bonus 为 0；个别位置评分极低但阵容仍合法。

- **AC-2**: 错位球员的 `positional_overall_rating` 低于偏好位置
  - Given: 同一名球员在偏好位置与一个非偏好位置各计算一次 `positional_overall_rating`。
  - When: 比较两个结果。
  - Then: 非偏好位置评分严格低于偏好位置评分。
  - Edge cases: 邻近位置与极端错位都应降分；多偏好位置球员在任一偏好位不应被视为错位；最低值不得出现负数或异常溢出。

- **AC-3**: 推荐阵容/推荐战术可在玩家不手动调整时直接合法开赛
  - Given: 玩家未对推荐阵容与推荐战术做任何手动修改。
  - When: 从 Pre-Match 直接进入 Confirmation 并确认开赛。
  - Then: 系统判定阵容合法并允许比赛开始，无需额外补位或手动修正。
  - Edge cases: 替补席人数最小可行；个别球员状态较差但仍满足合法性；推荐战术与推荐阵容组合后仍必须可开赛。

---

## Test Evidence

**Story Type**: Logic
**Required evidence**:
- Logic: `tests/unit/match/team_strength_aggregation_test.gd` — must exist and pass

**Status**: [x] Created — tests/unit/match/team_strength_aggregation_test.gd

---

## Completion Notes
**Completed**: 2026-05-28
**Criteria**: 3/3 passing
**Deviations**: Scoped preferred-position handling to the current single `Player.position` field; full multi-position preference and richer availability modeling remain out of scope for this story closeout.
**Test Evidence**: Logic: `tests/unit/match/team_strength_aggregation_test.gd`
**Code Review**: Not run

---

## Dependencies

- Depends on:
  - `production/epics/player-development-system/story-001-player-data-serialization-boundary.md` — must be DONE
  - `production/epics/balance-system/story-005-positional-rating.md` — must be DONE
- Unlocks:
  - `production/epics/match-competition-system/story-003-actual-win-probability.md`
  - `production/epics/match-competition-system/story-006-match-result-packet.md`
