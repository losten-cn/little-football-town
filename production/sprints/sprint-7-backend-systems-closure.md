# Sprint 7 — 后端系统补齐与视觉收尾 — 2026-07-27 to 2026-08-03

## Sprint Goal

补齐 4 个已设计但未创建 epic 的后端系统（随机事件/音频/建设UI/教程），完成 visual-direction-alignment 的 deferred AC 验证项，为 Feature 层全面上线做准备。

## Capacity

- Total days: 6 working days
- Buffer (20%): 1.2 days reserved for unplanned work
- Available: 4.8 days

## Scope Guard

- 本 sprint 以 epic 创建和基础设施搭建为主，不要求完整 UI 闭环
- visual-direction-alignment deferred AC 仅为手动验证，不涉及新代码
- 所有新 epic 必须先通过 `/create-epics` → `/story-readiness` 验证
- 不新增 gameplay logic、route topology 变更、save/event schema 变更

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S7-01 | 创建 4 个后端 epic（随机事件/音频/建设UI/教程） | Producer | 0.5 | systems-index.md, 已有 ADR-0012/0013 | 4 个 EPIC.md 写入并通过 `/create-epics` 审批；每个 epic stories 已拆解 |
| S7-02 | 随机事件系统 — Story 001: RandomEventManager 最小 auth stub | Gameplay Programmer | 1.0 | S7-01, ADR-0012 | `RandomEventManager` 为场景实例化节点；独占 `pending_random_event_instance`/`recent_random_event_history`/`event_cooldown_state`/`processed_event_settlement_keys` durable truth；通过 `time_phase_changed` 触发稳定窗口检查 |
| S7-03 | 建设与经营 UI — Story 001: TownMgmtUI 最小 grid 容器 | UI Programmer | 1.0 | S7-01, ADR-0008, Story 001 world renderer | 消费 `TownBuilding` read model；渲染 5×5 facility grid 占位；从 Home 可访问；不实现 construction flow |
| S7-04 | 音频系统 — Story 001: AudioManager 最小 auth + save 集成 | Engine Programmer | 1.0 | S7-01, ADR-0013 | `AudioManager` 注册 serialize/deserialize callbacks 到 SaveManager；实现 `audio_master_volume`/`audio_bgm_volume`/`audio_sfx_volume`/`audio_ambience_volume`/`audio_muted_categories` 耐久字段；two-phase restore；不加载实际音频资产 |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S7-05 | 教程与提示系统 — Story 001: TutorialHintManager 最小 stub | UI Programmer | 0.5 | S7-01, OnboardingSystem ADR | 消费 `OnboardingSystem` 引导完成标记；实现提示冷却/已读/禁用状态；记录 `seen_hints`/`disabled_hints`/`help_index_visibility`；不包含自动弹出逻辑 |
| S7-06 | Visual-direction-alignment deferred AC 手动验证 | QA | 0.3 | Story 001-003 Complete | AC-7 (时间冷暖视觉提示) + AC-5 (比赛暗色 5s 渐变) 肉眼确认；截图写入 `production/qa/evidence/`；关闭对应 tech debt 条目 |

### Nice to Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S7-07 | P3 重校准: 从世界建筑点击进入功能面板 | UI Programmer | 0.5 | Story 001 + 002 Complete, S7-03 | 点击训练场建筑 tile → ScreenManager.push_screen(Training)；点击球场 → push_screen(Match)；通过 ADR-0001 Screen Stack 模式 |

## Carryover from Previous Sprint

无 — visual-direction-alignment epic (3 stories) 已于 Sprint 间隙完成。Sprint 5-6 按计划执行。

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| 音频系统 SaveManager 集成时出现 GDScript typed dict 边界问题 | Medium | Low | ADR-0013 已定义 two-phase restore；Story 001 有明确实现指南 |
| TownMgmtUI grid 与 Story 001 world renderer 建筑位置不同步 | Low | Medium | 两者均为 presentation-only；tech-debt-register 已记录硬编码建筑位置 |
| RandomEventManager durable truth 字段与 ADR-0012 定义不完全对齐 | Low | Medium | ADR-0012 已 Accepted；字段列表明确，Stable Settlement Key 规范已定义 |

## Dependencies on External Factors

- 无外部依赖

## Definition of Done for this Sprint

- [ ] All Must Have tasks completed and tested
- [ ] S7-01 4 个 EPIC.md 全部创建 + stories 拆解
- [ ] S7-02—S7-04 实现 + 测试 PASS
- [ ] No S1 or S2 bugs in delivered features
- [ ] Tech debt register 更新（S7-06 关闭对应条目）
- [ ] Code reviewed and merged
