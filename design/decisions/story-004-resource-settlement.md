# Story 004 决策日志 — 实现资源结算共享公式

- **Story ID**: Story 004
- **故事文件**: `production/epics/balance-system/story-004-resource-settlement.md`
- **完成日期**: 2026-05-27
- **系统**: Balance System
- **相关实现文件**:
  - `src/config/balance_config.gd`
  - `tests/unit/balance/resource_settlement_test.gd`

## 变更摘要
本次实现将共享资源结算公式收口到 `BalanceConfig`，统一通过 `compute_resource_settlement(...)` 执行 `current + gained - spent` 后的合法区间钳制，并通过 `supports_shared_resource_settlement(...)` 明确仅有资金、研究点和行动点参与这层共享结算。配套逻辑测试覆盖了基础公式、上下界钳制、参与资源类型约束，以及 `resource_buffer_multiplier` 的配置校验边界。

## 关键决策

| 主题 | 采用方案 | 原因 | 放弃方案 |
|---|---|---|---|
| 共享公式归属 | 将资源结算共享公式放入 `src/config/balance_config.gd` | 资源结算属于跨系统共享数值规则，符合 ADR-0004 的 data-driven config 边界 | 在 `EconomyManager` 或其他下游系统中各自重复实现 |
| 参与资源类型判定 | 增加 `supports_shared_resource_settlement(...)` 显式限定 `funds` / `research` / `action_points` | 让“哪些资源参加共享结算”成为可复用且可测试的权威规则，避免调用方各自猜测 | 仅靠调用约定隐式限制；允许任意资源类型进入共享公式 |
| 边界处理 | 对最终结算结果统一做 legal boundary clamp | 与 story acceptance criteria 和 GDD Edge Cases 对齐，确保共享输出始终落在合法范围内 | 让调用方自行决定是否钳制；只校验不修正输出 |
| 实现范围 | 只补共享公式、参与规则和测试证据，不扩展到经济业务流程 | Story 004 只负责共享公式层，不拥有预算、交易授权或结算阶段流转 | 顺手把经济系统的业务路径一并纳入本 story |
| 测试策略 | 使用独立逻辑测试文件验证公式与配置边界 | 以最小改动满足 Logic story 的自动化证据要求，并保持当前 balance 测试风格一致 | 仅依赖手工验证；等待更大的统一测试 runner 改造 |

## 影响范围
- **Balance System**：共享资源结算规则正式进入 `BalanceConfig`
- **Economy System**：下游系统可复用统一的资源结算与参与规则，不再自行定义共享边界
- **Testing**：补齐 `tests/unit/balance/resource_settlement_test.gd` 自动化证据

## 质量验证
- 验证文件：`tests/unit/balance/resource_settlement_test.gd`
- 结论：Story 004 所需 5/5 条验收标准已通过当前实现与自动化证据覆盖
- 备注：本地 Godot headless 验证已通过；完成时未记录额外技术债

## 后续影响
- 直接解锁：Economy Management 下游资源结算相关故事
- 推荐后续：`production/epics/balance-system/story-003-attribute-growth.md` — 在已完成的共享公式面上继续补齐成长曲线与潜力边界归一化
