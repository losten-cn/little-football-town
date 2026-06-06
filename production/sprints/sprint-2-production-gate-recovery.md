# Sprint 2 — Production Gate Recovery

## Sprint Goal

在不扩 scope 的前提下，补齐 Production gate 缺失证据：完成本 gate 接受的 AI-agent 代理观察 vertical slice playtest、确认 core fun / core fantasy、通过关键 UX 规格评审、补齐 slice 相关 prototype REPORT，并形成可重跑 gate 的证据包。

## Duration

- 2026-06-08 to 2026-06-19
- 10 working days
- 20% buffer: 2 days
- Target: Day 8 前形成 re-gate decision，剩余时间只留给一次修复/复验回路

## Scope Guard

- 本 sprint 只允许 gate recovery 工作，不做新功能扩展。
- 已通过但带 warning 的 GDD / cross-GDD / Art Bible / ADR / architecture / control manifest / automated route sanity / visual walkthrough 不在本 sprint 重开，除非它们直接变成 stop-the-line blocker。
- Warning 可以接受；blocker 必须闭环或明确 no-retry。

## Owner Roles

- **Producer** — 锁 scope、排依赖、汇总证据、给出 re-gate 建议
- **Game Designer** — 定义 core fun / fantasy 验证标准
- **UX Designer** — 执行关键 UX 规格评审与缺陷分级
- **QA Lead** — 组织并记录 AI-agent 代理观察 playtest，负责复验
- **UI Programmer** — 修复 gate-blocking UX / flow 问题
- **Creative Director** — 对 core fun / core fantasy 做最终 PASS / FAIL 判定

## Critical Path

PGR-02 → PGR-05 → PGR-06 → PGR-07 → PGR-08 → PGR-09 → PGR-10 → PGR-11 → PGR-12

## Tasks by Topology

### L0 — 并行启动

| ID | Task | Owner | Estimate | Dependencies | Acceptance Criteria |
|----|------|-------|----------|--------------|---------------------|
| PGR-01 | 刷新 sprint 计划并锁定 recovery scope | Producer | 0.5d | None | 当前 sprint 日期有效；任务仅覆盖 gate blockers；关键路径明确。 |
| PGR-02 | 定义 core fun / fantasy / key UX 验证 rubric | Game Designer | 0.5d | None | 形成一页检查表，明确 pass/fail 问题、关键体验时刻、关键界面。 |
| PGR-03 | 盘点 slice 相关 prototypes 与缺失 REPORT | Producer | 0.5d | None | 列出所有 slice-critical prototype、当前状态、缺失 REPORT 目标。 |

### L1 — 证据与准备

| ID | Task | Owner | Estimate | Dependencies | Acceptance Criteria |
|----|------|-------|----------|--------------|---------------------|
| PGR-04 | 补齐 slice-critical prototypes 的 REPORT.md | Producer | 1d | PGR-03 | 每个 slice-critical prototype 都有 REPORT，至少包含 purpose、current state、findings、keep/cut recommendation。 |
| PGR-05 | 对关键 slice surfaces 执行 /ux-review | UX Designer | 1d | PGR-02 | Home / Town / Match / Result / Player 关键面通过评审，或形成带严重级别与 owner 的问题单。 |
| PGR-06 | 准备 moderated playtest 脚本与排期 | QA Lead | 1d | PGR-01, PGR-02 | 锁定 playtest build、脚本、观察记录模板，并预约至少 3 场 AI-agent 代理观察 session。 |

### L2 — AI-agent 代理验证

| ID | Task | Owner | Estimate | Dependencies | Acceptance Criteria |
|----|------|-------|----------|--------------|---------------------|
| PGR-07 | 执行 AI-agent 代理观察 vertical slice playtests | QA Lead | 1.5d | PGR-05, PGR-06 | 至少完成 3 场观察 session；记录 completion path、fun moments、fantasy clarity、主要 friction。 |
| PGR-08 | 汇总 findings 并形成 gate issue list | Producer | 0.5d | PGR-05, PGR-07 | 输出单一优先级列表，按 Fun / Fantasy / UX 与 S1 / S2 / S3、must-fix / allowed-warning 标记。 |

### L3 — 收敛与复验

| ID | Task | Owner | Estimate | Dependencies | Acceptance Criteria |
|----|------|-------|----------|--------------|---------------------|
| PGR-09 | 只修 gate-blocking UX / flow 问题 | UI Programmer | 2d | PGR-08 | 所有 must-fix UX / flow 问题已修复或被升级为 blocker；未引入新功能 scope。 |
| PGR-10 | 进行 core fun / core fantasy 创意判定 | Creative Director | 0.5d | PGR-08, PGR-09 | 给出明确 PASS / FAIL；若 FAIL，指出最小 cut / change 列表。 |
| PGR-11 | 对修复后 build 做 QA 复验与 route / walkthrough 回归 | QA Lead | 1d | PGR-09 | 关键 loop 可端到端完成；无新 route blocker；关键 UX specs 通过，或仅剩 allowed warnings。 |

### L4 — Gate 封包

| ID | Task | Owner | Estimate | Dependencies | Acceptance Criteria |
|----|------|-------|----------|--------------|---------------------|
| PGR-12 | 组装 recovery evidence pack 并给出 re-gate 建议 | Producer | 0.5d | PGR-04, PGR-10, PGR-11 | 证据包包含 REPORT 链接、playtest 记录、UX 结果、修复复验、retry / no-retry recommendation。 |

## Definition of Done

- [ ] PGR-01 至 PGR-12 完成
- [x] 至少 3 场 AI-agent 代理观察 vertical slice session 已记录
- [ ] Creative Director 对 core fun 与 core fantasy 给出 PASS
- [ ] 关键 UX specs 已通过 /ux-review，或只剩 allowed warnings
- [ ] 所有 slice-critical prototypes 已补齐 REPORT.md
- [ ] Onboarding / Home / Town / Match / Result / Return loop 无 S1 / S2 blocker
- [ ] 已形成可用于重跑 Pre-Production → Production gate 的证据包
- [ ] 未引入未经批准的新 scope

## Risks

| Risk | Probability | Impact | Mitigation |
|------|------------|--------|------------|
| Playtest 排期滑动，导致证据不足 | Medium | High | Day 1 即预约 session，并准备内部替补观察对象。 |
| Playtest 暴露的是 fantasy gap 而非纯 UX 问题 | High | High | 用 PGR-10 做 24 小时内创意裁剪，不允许借机扩 scope。 |
| UX 修复触发主流程回归 | Medium | High | 修复后必须执行 route sanity + visual walkthrough + AI-agent 关键路径复验。 |
| REPORT 补录耗时过长，挤占验证节奏 | Low | Medium | REPORT 仅保留最小字段，不补非 gate-critical prototype。 |

## Allowed Warnings

- 现有 cross-GDD warnings，只要不影响当前 slice 的可完成路径
- 非关键路径上的轻度文案/美术 polish 问题
- 已记录 owner 与后续跟进时间的 secondary UX paper cuts
- REPORT 中记录的 future work，只要不否定当前 gate 证据

## Stop-the-Line Blockers

- Day 4 结束前仍未完成 AI-agent 代理观察 playtest
- Core fun 或 core fantasy 在 PGR-10 被判定为 FAIL
- 任一关键 slice surface 在复验后仍存在 S1 / S2 UX failure
- 任一 slice-critical prototype 仍缺少 REPORT.md
- Onboarding → Home/Town → Match → Result → Return 主 loop 在 AI-agent 代理或自动验证中断裂
- Sprint 中出现未经批准的新 scope 注入

## Notes

- 这是一个最小 recovery sprint，不是 feature sprint。
- 如果 PGR-10 为 FAIL，本 sprint 的正确输出是 “no-retry + 最小 cut list”，而不是继续堆功能。
