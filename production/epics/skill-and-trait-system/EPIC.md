# Epic: 技能与特性系统

> **Layer**: Feature (Alpha)
> **GDD**: design/gdd/skill-and-trait-system.md
> **Status**: Planned
> **Topology**: Alpha — deferred from Sprint 3, activated Sprint 5
> **Stories**: 1 stub story

## Overview

本 epic 交付 Skill/Trait 系统的最小 Alpha Presentation stub。核心目标不是实现技能解锁或特性触发逻辑，而是建立 `pending_skill_trait_feedback` 和 `feedback_ack` 只读 UI 消费路径——当 Core authority 开始产出这些 payload 时，Presentation 层已经 ready。

## Goal

- 在现有 shell 内提供一个可到达的 Growth Summary 容器。
- 消费 `pending_skill_trait_feedback` 只读 payload。
- 不做 unlock/trigger/candidate/dedup 等 Core 逻辑。
- 不新增 route ID 或 save/event schema。

## Scope

### In Scope

- Read-only Growth Summary container.
- `pending_skill_trait_feedback` payload subscription.
- Neutral placeholder when payload missing.
- Integration test + evidence.

### Out of Scope

- Skill unlock/trait trigger logic.
- Candidate evaluation.
- `feedback_ack` write-back logic.
- Full interaction depth.

## Traceability

| TR-ID | Requirement Focus | Story |
|-------|-------------------|-------|
| `TR-skill-006` | `pre_match_skill_trait_snapshot` UI consumption | Story 001 |
| `TR-skill-007` | `pending_skill_trait_feedback` / `feedback_ack` modeling | Story 001 |
| `TR-playerui-011` | Player Detail feedback consumption | Story 001 |

## Stories

| # | Story | Type | Status | Notes |
|---|-------|------|--------|-------|
| 001 | [Skill/Trait Growth Summary — 最小 Alpha UI stub](story-001-growth-summary-stub.md) | UI | Ready | Sprint 5 Must Have. First Skill/Trait story. |

## Status / Notes

- Skill/Trait was deferred from Sprint 3 (see `production/sprints/deferred-systems-governance-2026-07-09.md`).
- This epic begins with a presentation stub only — no Core authority changes.
- Full unlock/trigger/candidate stories belong in future Skill/Trait wave.
