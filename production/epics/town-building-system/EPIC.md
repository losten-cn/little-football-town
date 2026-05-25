# Epic: 小镇建设系统

> **Layer**: Core
> **GDD**: design/gdd/town-building-system.md
> **Architecture Module**: TownBuilding
> **Status**: Ready
> **Stories**: 9 stories

## Overview

本 epic 实现《足球小镇》的设施与小镇网格权威层，通过 `TownBuilding` 和 `Facility` 管理 5×5 网格、设施建造、升级、拆除、建设状态机、邻接加成、设施公式查询和建设进度持久化。它向培养、比赛和经济系统提供只读加成与倍率，让建设投入转化为长期训练、比赛和资源回报。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0008: Town Grid & Facility System | 使用 `Facility` RefCounted、flat typed array 网格和 `TownBuilding` Core 节点管理设施状态、邻接计算、公式接口和序列化契约。 | LOW |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-town-001 | 5×5 grid, 4-directional adjacency (Manhattan distance = 1) | ADR-0008 ✅ |
| TR-town-002 | 4 MVP facility types, 5 levels each | ADR-0008 ✅ |
| TR-town-003 | Facility state machine: Empty→Constructing→Active↔Upgrading→Demolishing→Empty | ADR-0008 ✅ |
| TR-town-004 | Construction cost: ceil(base × 1.8^(level-1)) | ADR-0008 ✅ |
| TR-town-005 | Construction time: ceil(base × 1.3^(level-1)) | ADR-0008 ✅ |
| TR-town-006 | training_efficiency_multiplier = 1.0 + 0.05 × training_ground_level | ADR-0008 ✅ |
| TR-town-007 | home_advantage_bonus = 2.0 × stadium_level, max 10.0 | ADR-0008 ✅ |
| TR-town-008 | stadium_revenue_multiplier = 1.0 + 0.08 × stadium_level, max 1.40 | ADR-0008 ✅ |
| TR-town-009 | medical_ap_bonus: clamp(floor(level × bonus_per_level), 1, 3) + adjacency, total [0, 3] | ADR-0008 ✅ |
| TR-town-010 | injury_recovery_reduction: clamp(floor(level × recovery_per_level), 1, 2) | ADR-0008 ✅ |
| TR-town-011 | youth_potential_floor_boost: base + adjacency, clamp [0, 5] | ADR-0008 ✅ |
| TR-town-012 | 3 adjacency pairs: training_ground↔medical_room, training_ground↔youth_academy, stadium↔training_ground | ADR-0008 ✅ |
| TR-town-013 | Maximum adjacency bonus: 15.0 (stadium Lv.5 + training_ground Lv.5 adjacent) | ADR-0008 ✅ |
| TR-town-014 | Construction/upgrade costs via EconomyManager.accredit_facility_cost() exclusively | ADR-0008 ✅ |
| TR-town-015 | Demolish under-construction facility returns error | ADR-0008 ✅ |
| TR-town-016 | Construction timers decrement on time_phase_changed | ADR-0008 ✅ |
| TR-town-017 | Adjacency bonuses computed on state change, not polled per-frame | ADR-0008 ✅ |
| TR-town-018 | 8 public formula methods for downstream consumption | ADR-0008 ✅ |
| TR-town-019 | Daily maintenance = Σ active facilities × (base + delta × (level-1)) | ADR-0008 ✅ |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [建立 Facility 数据模型与网格索引契约](story-001-town-grid-facility-contract.md) | Integration | Ready | ADR-0008 |
| 002 | [实现设施建造/升级成本与工期公式](story-002-facility-cost-time-formulas.md) | Logic | Ready | ADR-0008 |
| 003 | [实现建造发起校验与 accredited 扣费入口](story-003-build-request-validation.md) | Integration | Ready | ADR-0008 |
| 004 | [实现升级流转与 time_phase_changed 完工结算](story-004-upgrade-completion-flow.md) | Integration | Ready | ADR-0008 |
| 005 | [实现拆除限制、空地释放与邻接重算触发](story-005-demolish-grid-release.md) | Integration | Ready | ADR-0008 |
| 006 | [实现训练/医疗/青训基础公式接口](story-006-training-medical-youth-formulas.md) | Logic | Ready | ADR-0008 |
| 007 | [实现球场与三组邻接加成公式](story-007-stadium-adjacency-formulas.md) | Logic | Ready | ADR-0008 |
| 008 | [实现下游只读查询面与维护费汇总](story-008-downstream-query-maintenance.md) | Integration | Ready | ADR-0008 |
| 009 | [实现建设状态序列化与读档恢复回归](story-009-serialization-restore-regression.md) | Integration | Ready | ADR-0008 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/town-building-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories town-building-system` to break this epic into implementable stories.
