# Story 008 决策日志 — 建立数值生命周期元数据与跨系统一致性扫描

- **Story ID**: Story 008
- **故事文件**: `production/epics/balance-system/story-008-balance-consistency-scan.md`
- **完成日期**: 2026-05-27
- **系统**: Balance System
- **相关实现文件**:
  - `tests/integration/balance/balance_consistency_test.gd`
  - `src/core/player_development.gd`

## 变更摘要
本次实现以 `tests/integration/balance/balance_consistency_test.gd` 为 Story 008 的集成证据，聚焦清除已确认的下游重复共享公式，并验证同一输入下共享公式输出与下游消费者输出保持一致。完成范围收敛在 `PlayerDevelopment` 中已确认的 duplicate growth formula 漂移；在 story 完成时没有发现额外的共享资源结算重复实现，因此未扩展到不存在的缺陷上。

## 关键决策

| 主题 | 采用方案 | 原因 | 放弃方案 |
|---|---|---|---|
| 权威来源 | 继续以 `BalanceConfig` 作为共享数值常量与公式的唯一权威来源 | 与 ADR-0004 对齐，确保下游一致性检查始终围绕同一 data-driven source 展开 | 允许各系统保留自己的共享公式副本后再做人工比对 |
| Story 008 闭环范围 | 先修复并验证已确认的重复 growth formula 漂移 | 这是当前仓库里有证据支撑的真实问题，先以最小范围形成可验证闭环 | 为了追求“全扫描”而补写无依据的重复缺陷或扩到不存在的资源结算分叉 |
| 一致性验证方式 | 使用同一输入比较 shared output 与 downstream consumer output | 直接对应 acceptance criteria，且能在 headless 环境下稳定复现 | 只做静态 grep 扫描；或只依赖人工代码审阅结论 |
| 测试入口 | 使用 `tests/integration/balance/balance_consistency_test.gd` 作为集成证据 | Story 008 属于 Integration，现有脚本已能覆盖下游/共享输出一致性并支持本地 Godot headless 验证 | 仅写文档说明；或等待统一 CI 扫描器成熟后再关闭 story |
| 未发现的疑似项处理 | 对没有证据支持的重复实现保持不扩 scope | Story 文档完成说明已明确：完成时未发现 duplicate shared resource settlement implementation | 把“理论上可能存在”的问题也记为本 story 已处理范围 |

## 影响范围
- **Balance System**：共享公式与下游消费的一致性验证形成可复用集成证据
- **Player Development**：移除已确认的 duplicate growth formula 漂移，恢复对共享公式的对齐
- **Testing**：补齐 `tests/integration/balance/balance_consistency_test.gd` 作为 downstream/shared consistency 基线

## 质量验证
- 验证文件：`tests/integration/balance/balance_consistency_test.gd`
- 结论：Story 008 所需 5/5 条验收标准以当前实现范围完成闭环，已确认问题完成修复并通过本地 Godot headless 验证
- 备注：完成说明保留 partial-scope 事实——完成时未发现 duplicate shared resource settlement implementation，因此未对不存在的缺陷扩 scope

## 后续影响
- 直接解锁：下游 player-development validation 与 broader downstream readiness work
- 推荐后续：围绕更多 shared-balance consumers 做更窄范围的后续验证，但仅在出现新证据时再扩展实现面
