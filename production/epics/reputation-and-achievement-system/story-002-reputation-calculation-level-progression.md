# Story 002: 声望计算 + 等级推进

> **Epic**: 声望与成就系统
> **Status**: Complete
> **Layer**: Feature
> **Type**: Logic
> **Estimate**: M (3-4 hours)
> **Manifest Version**: 2026-07-05
> **Last Updated**: 2026-07-10

## Context

**GDD**: `design/gdd/reputation-and-achievement-system.md`
**Requirement**: `TR-reputation-001`, `TR-reputation-002`
**ADR Governing Implementation**: ADR-0011

**Engine**: Godot 4.6 + GDScript | **Risk**: LOW

## Acceptance Criteria

- [ ] **AC-1**: `reputation_gain = floor((base_reputation_source + bonus_reputation_source) × source_weight × stage_multiplier)` — 公式实现，base/bonus 由上游事件提供，weight/multiplier 从 config 读取
- [ ] **AC-2**: `reputation_progress_ratio = (reputation_total - current_level_threshold) / max(1, next_level_threshold - current_level_threshold)` — 返回 0–1 float，≥1 时触发升级
- [ ] **AC-3**: 一次结算跨越多个等级时，顺序处理所有合法升级 (Lv.2→Lv.3→Lv.4)，不遗漏、不重复
- [ ] **AC-4**: `reputation_total`、`reputation_level`、`reputation_progress_ratio` 为 `ReputationAchievementManager` 独占 durable truth，其他系统只读消费
- [ ] **AC-5**: 等级阈值表 (`reputation_level_thresholds`) 数据驱动，从 config 加载

## Implementation Notes

- `reputation_gain` 只定义"长期认可增加多少"，不定义事件本身是否发生
- 上游系统 (Match/League/Player/Town) 只提供已确认事件标签，声望系统拥有映射规则
- 若同一事件满足多个声望来源，先按来源拆分，再批量结算汇总
- 等级阈值表: `Lv.1: 0, Lv.2: 100, Lv.3: 180, Lv.4: 260, Lv.5: 360` (MVP 默认值，可从 config 覆盖)

## Out of Scope

- Story 001: recognition summary stub (UI 容器 + payload 绑定)
- Story 003: 成就判定 (`achievement_completed`) + settlement key 去重
- Story 004: serialize/deserialize + view payloads
- 实际成就条件表、事件→声望来源映射表 (后续 story)

## QA Test Cases

- **AC-1**: 声望获取公式
  - Given: base=12, bonus=3, source_weight=1.0, stage_multiplier=1.0
  - When: 调用 `calculate_reputation_gain()`
  - Then: 返回 `floor(15) = 15`

- **AC-2**: 等级进度比例
  - Given: reputation_total=135, current_level_threshold=100, next_level_threshold=180
  - When: 调用 `get_reputation_progress_ratio()`
  - Then: 返回 `(135-100)/(180-100) = 0.4375`

- **AC-3**: 跨越多级升级
  - Given: reputation_total=320, 当前 Lv.2 (100→180)
  - When: 执行 `process_reputation_gain()`
  - Then: Lv.2→Lv.3→Lv.4 顺序升级，最终停留在 Lv.4，progress_ratio = 0.60

## Test Evidence

**Story Type**: Logic
**Required evidence**: `tests/unit/reputation/reputation_formula_test.gd`

## Dependencies

- Depends on: Story 001 (ReputationAchievementManager auth stub)
- Unlocks: Story 003 (成就判定 + settlement key 去重)

## Completion Notes
**Completed**: 2026-07-10
**Criteria**: 5/5 passing (all auto-verified)
**Deviations**: None
**Test Evidence**: Logic — `tests/unit/reputation/reputation_formula_test.gd` (PASS)
**Code Review**: Pending
**Implementation**: `src/core/reputation_achievement_manager.gd` + `src/config/reputation_config.gd` + `config/reputation_config.tres` + ConfigLoader integration
