# Change Log: Story 005: 实现每日 AP 恢复、休息恢复与维护费结算

## 基础信息
- **Story ID**: Story 005
- **Epic**: 经济管理系统
- **负责代理**: gameplay-programmer (执行), lead-programmer (审查)
- **完成日期**: 2026-05-26

## 变更摘要
为 EconomyManager 增加 `settle_day()` 每日结算入口，通过统一 transaction pipeline 结算 AP 恢复、休息日额外恢复与每日维护费扣减；为 TownBuilding 补齐每日 AP bonus 与设施维护费查询合同；将医疗室-训练场邻接 AP 系数提升为 `TownConfig` 数据配置；补充并通过 Story 005 集成测试，验证恢复、封顶、维护费扣减、邻接加成与 balance-change 事件。

## 设计决策
| 决策点 | 选择方案 | 理由 | 替代方案 (已否决) |
|--------|----------|------|--------------------|
| 每日结算入口 | 在 `EconomyManager.settle_day()` 中通过单次 `Transaction` 统一提交 AP 与 Funds 变化 | 符合 ADR-0007 “所有资源变更经 execute_transaction() 统一边界处理”的要求，且便于审计与事件发射 | 直接写 `_funds` / `_action_points`；拆成多次独立 transaction |
| 设施侧输入来源 | 由 `TownBuilding` 提供 `get_daily_action_points_bonus()` 与 `get_daily_maintenance_cost()` 查询合同 | 保持 EconomyManager 只消费系统合同，不内嵌 TownBuilding 公式细节，符合 story manifest 约束 | 在 EconomyManager 内重算设施公式；直接读取设施内部状态结构 |
| 邻接 AP 系数位置 | 将 `adj_med_tr_coeff` 放入 `TownConfig` 与 `config/town_config.tres` | 满足“调参值必须 data-driven，不能硬编码在 src/”规则 | 在 `src/core/town_building.gd` 中硬编码 `0.6` |
| 回归证据形态 | 使用 headless integration test 覆盖 daily settlement 主路径与邻接 bonus | Story 类型为 Integration，且能直接验证跨系统交互、事件与余额变化 | 仅做手工 playtest 记录；只写 unit test 验证局部公式 |

## 影响范围
- **修改/新增的文件**:
  - `src/core/economy_manager.gd`
  - `src/core/town_building.gd`
  - `src/config/town_config.gd`
  - `config/town_config.tres`
  - `tests/integration/economy/daily_recovery_maintenance_settlement_test.gd`
  - `production/epics/economy-management-system/story-005-daily-recovery-maintenance-settlement.md`
- **影响的其他系统**: Town Building System, EventBus contract consumers, config loading path for town tuning
- **数据/配置变更**: 新增 `TownConfig.adj_med_tr_coeff`，默认资源 `config/town_config.tres` 写入 `adj_med_tr_coeff = 0.6`

## 质量保证
- **通过的测试**: `tests/integration/economy/daily_recovery_maintenance_settlement_test.gd` — PASS (`DAILY_RECOVERY_MAINTENANCE_SETTLEMENT_TEST_PASS`)
- **Agent 审查摘要**: `/code-review` 结论为 `APPROVED WITH SUGGESTIONS`。已修复阻塞项：补齐医疗室-训练场邻接 AP bonus、补齐 `economy_balance_changed` 发射、补强集成测试；剩余建议为 transaction log 裁剪、只读边界与额外 edge case 覆盖，均非阻塞。

## 依赖关系
- **前置 Story**: `production/epics/economy-management-system/story-002-execute-transaction-atomic-validation.md`, `production/epics/economy-management-system/story-003-warning-threshold-cooldown-events.md`, `production/epics/economy-management-system/story-004-budget-preview-affordability-query.md`
- **后置 Story**: `production/epics/economy-management-system/story-009-settlement-order-concurrency-regression.md`
