# Change Log: Story 008: 实现交易流水上限与存档序列化契约

## 基础信息
- **Story ID**: Story 008
- **Epic**: 经济管理系统
- **负责代理**: gameplay-programmer (执行), lead-programmer (审查)
- **完成日期**: 2026-05-27

## 变更摘要
补齐并验证 `EconomyManager` 的交易流水上限与存档序列化契约：保留最近 200 条 committed transactions，支持 `serialize()` / `deserialize()` 恢复 balances、`next_tx_id` 与 recent log，通过 `register_with_save_manager()` 接入 SaveManager 集中式 economy block；同时补强集成测试，覆盖 201 条淘汰最旧项、partial old-save payload 的默认 `next_tx_id` 语义、centralized restore contract，以及显式资源清理后的无泄漏测试退出。

## 设计决策
| 决策点 | 选择方案 | 理由 | 替代方案 (已否决) |
|--------|----------|------|--------------------|
| 交易流水保留策略 | 固定保留最近 200 条，超限后淘汰最旧 entry | 符合 TR-economy-010 与 ADR-0007，对审计足够且可控制 save bloat | 无限增长日志；按日期/赛季分片但不做上限 |
| 序列化边界 | 仅序列化 primitives、`next_tx_id` 与 `Transaction.to_dict()` 结果数组 | 满足 SaveManager 约束，避免持久化运行时对象引用 | 持久化 `Transaction` 对象本身；写入运行时 Node/Resource 引用 |
| SaveManager 接入方式 | 通过 `register_with_save_manager()` 注册 `"economy"` block 的 `serialize` / `deserialize` callables | 对齐项目中心化 save/load 架构，让 economy 成为独立 restore block | EconomyManager 直接写盘；绕开 SaveManager 直接暴露专用恢复入口 |
| 旧档兼容语义 | 缺失 `next_tx_id` 时回退到默认计数器 `1`，并用测试固定当前行为 | 在不扩大产品改动面的前提下明确当前兼容语义，先保证旧档缺字段可恢复 | 直接推导下一个 tx_id；对缺字段旧档报错拒绝恢复 |

## 影响范围
- **修改/新增的文件**:
  - `src/core/economy_manager.gd`
  - `tests/integration/economy/transaction_log_save_contract_test.gd`
  - `production/epics/economy-management-system/story-008-transaction-log-save-contract.md`
- **影响的其他系统**: SaveManager, economy save snapshot assembly, downstream restore pipeline consumers
- **数据/配置变更**: 无新增配置；持久化内容限定为 balances、`next_tx_id` 与 bounded recent transactions

## 质量保证
- **通过的测试**: `tests/integration/economy/transaction_log_save_contract_test.gd` — PASS (`TRANSACTION_LOG_SAVE_CONTRACT_TEST_PASS`)
- **Agent 审查摘要**: 复审结论为 `APPROVED WITH CONCERNS`，后续通过补充 integration coverage 与显式 cleanup verification 消解。最终验证覆盖了 bounded retention、save/load roundtrip、centralized economy block restore、partial old-save payload 兼容语义，且重跑后无此前退出泄漏 warning。

## 依赖关系
- **前置 Story**: `production/epics/economy-management-system/story-001-economy-authority-transaction-model.md`
- **后置 Story**: `production/epics/economy-management-system/story-009-settlement-order-concurrency-regression.md`
