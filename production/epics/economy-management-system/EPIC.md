# Epic: 经济管理系统

> **Layer**: Core
> **GDD**: design/gdd/economy-management-system.md
> **Architecture Module**: EconomyManager
> **Status**: Complete
> **Stories**: 9 stories

## Overview

本 epic 实现《足球小镇》的资源交易与结算权威层，通过 `EconomyManager` 和 `Transaction` 管理经费、运动点数、研究点数、交易预览、原子执行、流水记录、预警事件，以及赛后、阶段和赛季结算。它是所有资源变更的唯一入口，确保训练、建设、比赛和联赛系统只能通过认证接口请求资源变化。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0007: Economy Transaction Framework | 使用 `Transaction` 与 `EconomyManager.execute_transaction()` 统一验证、原子执行和记录所有资源变更，并提供认证入口给下游系统。 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-economy-001 | Three resources: funds (可负债), AP (≥1), RP (≥0, MVP隐藏) | ADR-0007 ✅ |
| TR-economy-002 | execute_transaction() is the SOLE resource mutation path | ADR-0007 ✅ |
| TR-economy-003 | Pre-validation rejects transactions violating resource floors | ADR-0007 ✅ |
| TR-economy-004 | Warning thresholds: funds_low, ap_low, debt → emit economy_warning_triggered | ADR-0007 ✅ |
| TR-economy-005 | Three settlement stages: post-match, stage settlement, season settlement | ADR-0007 ✅ |
| TR-economy-006 | post_match_funds = base × result_multiplier × stadium × season_bonus | ADR-0007 ✅ |
| TR-economy-007 | Float-to-int conversion: all uses floor() | ADR-0007 ✅ |
| TR-economy-008 | Daily AP recovery and rest AP recovery formulas | ADR-0007 ✅ |
| TR-economy-009 | daily_maintenance_cost deducted from funds, computed by TownBuilding | ADR-0007 ✅ |
| TR-economy-010 | Transaction log retained (last ~200), serialized in save | ADR-0007 ✅ |
| TR-economy-011 | Accredited entry points: accredit_match_reward, accredit_facility_cost, accredit_training_cost | ADR-0007 ✅ |
| TR-economy-012 | Warning cooldown per threshold type to prevent alert spam | ADR-0007 ✅ |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [建立 EconomyManager 权威边界与 Transaction 数据模型](story-001-economy-authority-transaction-model.md) | Logic | Complete | ADR-0007 |
| 002 | [实现 execute_transaction 原子执行与资源底线校验](story-002-execute-transaction-atomic-validation.md) | Logic | Complete | ADR-0007 |
| 003 | [实现资源预警阈值、debt 预警与冷却机制](story-003-warning-threshold-cooldown-events.md) | Integration | Complete | ADR-0007 |
| 004 | [实现预算预览与可负担性查询合同](story-004-budget-preview-affordability-query.md) | Integration | Complete | ADR-0007 |
| 005 | [实现每日 AP 恢复、休息恢复与维护费结算](story-005-daily-recovery-maintenance-settlement.md) | Integration | Complete | ADR-0007 |
| 006 | [实现赛后/阶段/赛季结算公式与 floor 舍入](story-006-staged-settlement-formulas.md) | Integration | Complete | ADR-0007 |
| 007 | [实现认证入口与 caller 约束](story-007-accredited-entry-points.md) | Integration | Complete | ADR-0007 |
| 008 | [实现交易流水上限与存档序列化契约](story-008-transaction-log-save-contract.md) | Integration | Complete | ADR-0007 |
| 009 | [实现结算顺序、并发请求拒绝与经济回归验证](story-009-settlement-order-concurrency-regression.md) | Integration | Complete | ADR-0007 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/economy-management-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories economy-management-system` to break this epic into implementable stories.
