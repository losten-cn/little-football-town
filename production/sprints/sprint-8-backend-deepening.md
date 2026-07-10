# Sprint 8 — 后端系统深化 — 2026-08-04 to 2026-08-11

## Sprint Goal

深化 Sprint 7 的 4 个后端 authority stub，每个系统追加 1 个功能 story，关闭 visual-direction-alignment deferred AC 验证。

## Capacity

- Total days: 6 working days
- Buffer (20%): 1.2 days reserved for unplanned work
- Available: 4.8 days

## Tasks

### Must Have (Critical Path)

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S8-01 | 随机事件 — Story 002: 触发窗口 + offer 骨架 | Gameplay Programmer | 1.0 | S7-02 RandomEventManager stub, ADR-0012 | 订阅 `time_phase_changed` EventBus 事件；稳定窗口内触发 `_evaluate_event_trigger()`；冷却检查和近期历史过滤；输出 `random_event_offer_view_payload` 只读视图 |
| S8-02 | 音频 — Story 002: AudioServer 集成 + BGM 切换 | Engine Programmer | 1.0 | S7-04 AudioManager save integration, ADR-0013 | `_apply_volumes()` 调用 Godot AudioServer；BGM 根据 game state 切换（日常/比赛/结算）；SFX 播放资格检查（冷却/音量/焦点）；无资产时静默降级 |
| S8-03 | 建设UI — Story 002: 建造/升级确认流 | UI Programmer | 1.0 | S7-03 TownOverview grid stub, ADR-0008 | 点击 grid cell → 预算预览面板；展示经费变化 + 维护费变化 + 工期；确认按钮调用 accredited economy path；取消返回 grid |
| S8-04 | 教程 — Story 001: TutorialHintManager 最小 stub | UI Programmer | 0.5 | OnboardingSystem ADR, S7-01 tutorial epic | 消费 `OnboardingSystem` 引导完成标记；实现提示冷却/已读/禁用状态持久化；展示层通过 `tutorial_hint_view_payload` 只读消费 |

### Should Have

| ID | Task | Agent/Owner | Est. Days | Dependencies | Acceptance Criteria |
|----|------|-------------|-----------|--------------|---------------------|
| S8-05 | Visual-direction-alignment deferred AC 手动验证 | QA | 0.3 | Story 001-003 Complete | AC-7 (时间冷暖视觉提示) + AC-5 (比赛暗色 5s 渐变) 肉眼确认；截图写入 `production/qa/evidence/`；关闭对应 tech debt 条目 |
| S8-06 | QA plan sprint 8 | QA Lead | 0.3 | S8-01—S8-04 defined | 每个 Logic/Integration story 的测试用例规格；UI story 的手动验证步骤 |

## Carryover from Previous Sprint

| Task | Reason | New Estimate |
|------|--------|-------------|
| S7-05 教程 stub | 推迟到 S8-04 | 0.5d |
| S7-06 deferred AC 验证 | 推迟到 S8-05 | 0.3d |

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| AudioServer API 在 Godot 4.6 中有 post-cutoff 变化 | Low | Medium | 参考 `docs/engine-reference/godot/` 验证 API；使用 `AudioServer.get_bus_index()` 等标准接口 |
| TownMgmtUI 建造确认流需 EconomyManager accredited path 支持 | Low | Medium | S7-03 已确认 TownBuilding read model 可用；accredited economy entry 由 ADR-0007 定义 |

## Definition of Done for this Sprint

- [ ] All Must Have tasks completed and tested
- [ ] S8-01—S8-04 实现 + 测试 PASS
- [ ] S8-05 deferred AC 截图写入 evidence
- [ ] QA plan exists for sprint stories
- [ ] No S1 or S2 bugs
- [ ] Tech debt register 更新
