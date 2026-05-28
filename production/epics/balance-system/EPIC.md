# Epic: 数值系统

> **Layer**: Foundation
> **GDD**: design/gdd/balance-system.md
> **Architecture Module**: ConfigLoader
> **Status**: Complete
> **Stories**: 9 stories

## Overview

本 epic 实现《足球小镇》的共享数值规则底座，通过 `ConfigLoader` 和数据驱动配置承载属性、成长、资源、比赛概率、修正预算和 KPI 目标等跨系统公式。它为运动员培养、比赛竞技、经济管理、小镇建设和 UI 展示提供统一、可测试、可调优的数值语言，但不拥有下游系统的具体内容表或业务流程。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0004: Data-Driven Configuration | 使用 Godot Custom Resources (`.tres`) 和 `ConfigLoader` 统一加载、校验、暴露所有调参数据，禁止在 `src/` 中硬编码玩法数值。 | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-balance-001 | Five core attributes (SPD/PWR/TEC/INT/STA) with three-layer semantics (current/potential/effective) | ADR-0004 ✅ |
| TR-balance-002 | effective_attribute_value = (current + flat_modifiers) × (1 + percent_modifiers), clamped [1, 100] | ADR-0004 ✅ |
| TR-balance-003 | attribute_growth = raw × (1 - current/potential)^decay_factor | ADR-0004 ✅ |
| TR-balance-004 | positional_overall_rating aggregates position-weighted attributes into 0-100 score | ADR-0004 ✅ |
| TR-balance-005 | base_win_probability = 0.5 + rating_win_slope × (home_strength - away_strength), clamped [0.05, 0.95] | ADR-0004 ✅ |
| TR-balance-006 | flat_modifier_sum_budget [-10, 15]; percent_modifier_sum_budget [-0.20, 0.30] | ADR-0004 ✅ |
| TR-balance-007 | resource_buffer_multiplier ∈ [2.0, 4.0] | ADR-0004 ✅ |
| TR-balance-008 | 4 player tiers with distinct potential_cap and training_efficiency bands | ADR-0004 ✅ |
| TR-balance-009 | 4 KPI formulas: AP use rate, overall win rate, even match win rate, resource efficiency | ADR-0004 ✅ |
| TR-balance-010 | All shared formula parameters must live in data-driven config, not hardcoded in src/ | ADR-0004 ✅ |
| TR-balance-011 | Modifier application order: flat first, then percent | ADR-0004 ✅ |
| TR-balance-012 | decay_factor ∈ [0.8, 1.8], default 1.2 | ADR-0004 ✅ |
| TR-balance-013 | potential_cap_span ∈ [10, 20], default 15 | ADR-0004 ✅ |
| TR-balance-014 | Numeric lifecycle states: Draft→Tuned→Locked→Revised→Deprecated | ADR-0004 ✅ |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [定义 BalanceConfig 数据资源与启动校验](story-001-balance-config-validation.md) | Config/Data | Complete | ADR-0004 |
| 002 | [实现属性模型与有效属性公式](story-002-attribute-formula.md) | Logic | Complete | ADR-0004 |
| 003 | [实现属性成长公式与潜力边界](story-003-attribute-growth.md) | Logic | Complete | ADR-0004 |
| 004 | [实现资源结算共享公式](story-004-resource-settlement.md) | Logic | Complete | ADR-0004 |
| 005 | [实现位置综合评分公式](story-005-positional-rating.md) | Logic | Complete | ADR-0004 |
| 006 | [实现基准胜率公式与边界](story-006-win-probability.md) | Logic | Complete | ADR-0004 |
| 007 | [实现 KPI 与诊断公式](story-007-kpi-formulas.md) | Logic | Complete | ADR-0004 |
| 008 | [建立数值生命周期元数据与跨系统一致性扫描](story-008-balance-consistency-scan.md) | Integration | Complete | ADR-0004 |
| 009 | [验证数值公式可复核性与随机统计边界](story-009-balance-statistical-validation.md) | Integration | Complete | ADR-0004 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/balance-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Epic complete. No further story creation work is required in this epic.
