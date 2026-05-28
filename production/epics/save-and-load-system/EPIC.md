# Epic: 存档与读档系统

> **Layer**: Foundation
> **GDD**: design/gdd/save-and-load-system.md
> **Architecture Module**: SaveManager
> **Status**: Complete
> **Stories**: 9 stories

## Overview

本 epic 实现《足球小镇》的持久化基础，通过 `SaveManager` 提供唯一磁盘写入入口、存档槽、自动存档、快照组装、完整性校验、版本迁移和恢复流程。它确保小镇、球员、资源、赛季和 UI 位置等长期状态可以在稳定节点被一致保存和恢复，但不拥有下游系统的业务数据定义。

## Governing ADRs

| ADR | Decision Summary | Engine Risk |
|-----|-----------------|-------------|
| ADR-0003: Save/Load Persistence | 使用 Godot `.tres` Resource 快照、3 个手动槽 + 1 个自动槽、注册式序列化契约和 additive-forward 迁移策略。 | MEDIUM |

## GDD Requirements

| TR-ID | Requirement | ADR Coverage |
|-------|-------------|--------------|
| TR-save-001 | SaveManager is the sole disk writer | ADR-0003 ✅ |
| TR-save-002 | 3 manual save slots + 1 autosave slot | ADR-0003 ✅ |
| TR-save-003 | Save completeness: all 12 dependency systems captured atomically | ADR-0003 ✅ |
| TR-save-004 | Cross-system consistency: save_time_state == TimeManager.get_state() instantaneously | ADR-0003 ✅ |
| TR-save-005 | Stable save nodes: Planning, Match Trigger, Post-Match Settlement, Stage Settlement, Season Settlement, Offseason | ADR-0003 ✅ |
| TR-save-006 | Match In Progress is NOT a stable save node | ADR-0003 ✅ |
| TR-save-007 | Version migration: additive-forward only, no field deletion | ADR-0003 ✅ |
| TR-save-008 | Save integrity verified via hash checksum | ADR-0003 ✅ |
| TR-save-009 | Load time < 500ms for full save | ADR-0003 ✅ |
| TR-save-010 | Auto-save triggers: match_completed, time_season_ended, town_facility_completed, WM_CLOSE_REQUEST | ADR-0003 ✅ |
| TR-save-011 | Registration contract: each Core system registers serialize/deserialize callables with SaveManager | ADR-0003 ✅ |
| TR-save-012 | Deserialize order: Time→Town→Player→League→Economy→Match | ADR-0003 ✅ |

## Stories

| # | Story | Type | Status | ADR |
|---|-------|------|--------|-----|
| 001 | [建立 SaveSnapshot 与存档槽结构](story-001-save-snapshot-slots.md) | Integration | Complete | ADR-0003 |
| 002 | [实现系统注册契约与快照组装](story-002-save-registration-snapshot.md) | Integration | Complete | ADR-0003 |
| 003 | [实现稳定节点判定与瞬时节点保存拦截](story-003-stable-node-save-gate.md) | Logic | Complete | ADR-0003 |
| 004 | [接入自动保存触发与延后保存队列](story-004-autosave-triggers.md) | Integration | Complete | ADR-0003 |
| 005 | [实现原子提交、完整性哈希与损坏检测](story-005-save-integrity-atomic-commit.md) | Integration | Complete | ADR-0003 |
| 006 | [实现版本兼容判定与 additive-forward 迁移](story-006-save-migration.md) | Integration | Complete | ADR-0003 |
| 007 | [实现读档恢复顺序与权威状态重建](story-007-load-restore-order.md) | Integration | Complete | ADR-0003 |
| 008 | [实现存档恢复失败与玩家风险操作语义](story-008-save-recovery-flow.md) | Integration | Complete | ADR-0003 |
| 009 | [实现存档摘要、性能预算与回归样本](story-009-save-summary-performance.md) | Integration | Complete | ADR-0003 |

## Definition of Done

This epic is complete when:
- All stories are implemented, reviewed, and closed via `/story-done`
- All acceptance criteria from `design/gdd/save-and-load-system.md` are verified
- All Logic and Integration stories have passing test files in `tests/`
- All Visual/Feel and UI stories have evidence docs with sign-off in `production/qa/evidence/`

## Next Step

Run `/create-stories save-and-load-system` to break this epic into implementable stories.
