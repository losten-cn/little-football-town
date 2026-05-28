# Change Log: Story 007: 实现认证入口与 caller 约束

## 基础信息
- **Story ID**: Story 007
- **Epic**: 经济管理系统
- **负责代理**: gameplay-programmer (执行), lead-programmer (审查)
- **完成日期**: 2026-05-27

## 变更摘要
为 `EconomyManager` 的 accredited entry points 与内部结算路径补齐 caller 约束：公开业务入口与合法内部结算现在通过一次性内部授权 token 委托到唯一的 `execute_transaction()` 写入边界，阻止下游系统仅靠伪造 `source_system` 直接改写余额；同时补强集成测试，覆盖伪造授权来源失败、失败无副作用，以及 `settle_post_match()` 合法内部路径仍可成功提交且不会把授权 token 泄漏到审计日志。

## 设计决策
| 决策点 | 选择方案 | 理由 | 替代方案 (已否决) |
|--------|----------|------|--------------------|
| caller 约束实现方式 | 使用一次性内部授权 token，并由合法入口包装后再调用 `execute_transaction()` | 保留 `execute_transaction()` 作为唯一资源写入边界，同时把“谁可以写”从可伪造字符串提升为仅内部可签发凭据 | 仅校验 `source_system` 字符串；直接新增多个分散写入入口 |
| 测试兼容策略 | 保留 `test` / `test_suite` 直调通道 | 不打破 Story 001/002 的既有 deterministic 单元测试与边界测试，避免为修业务 caller 约束而扩大改动面 | 全面禁止外部直调 `execute_transaction()` 并重写既有测试 |
| 审计数据处理 | 在提交前移除 `_authorization_token` | 保持 transaction log 只记录业务审计字段，不泄漏内部授权实现细节 | 将 token 留在 metadata 中；单独新增调试字段到日志 |
| 回归覆盖形态 | 在现有 accredited entry points 集成测试中补伪造来源失败与合法内部路径成功用例 | 直接验证 Story 007 的 AC-3 以及真实内部赛后结算路径，避免 review blocker 再次回归 | 仅补 unit test；仅验证 rogue source 而不验证伪造 `match` |

## 影响范围
- **修改/新增的文件**:
  - `src/core/economy_manager.gd`
  - `tests/integration/economy/accredited_entry_points_test.gd`
  - `production/epics/economy-management-system/story-007-accredited-entry-points.md`
- **影响的其他系统**: Match Competition, Town Building, Player Development, Economy audit/event consumers
- **数据/配置变更**: 无新增数据资源；仅调整 `EconomyManager` 内部授权与审计边界

## 质量保证
- **通过的测试**: `tests/integration/economy/accredited_entry_points_test.gd` — PASS (`ACCREDITED_ENTRY_POINTS_TEST_PASS`)
- **Agent 审查摘要**: 复审结论为 `APPROVED WITH SUGGESTIONS`。已修复阻塞项：caller 伪造 `source_system` 可绕过 accredited entry points、`settle_post_match()` 合法内部路径未迁移。剩余建议为补充 `settle_day()` / `settle_stage()` / `settle_season()` 同类路径的轻量回归覆盖，非阻塞。

## 依赖关系
- **前置 Story**: `production/epics/economy-management-system/story-001-economy-authority-transaction-model.md`, `production/epics/economy-management-system/story-002-execute-transaction-atomic-validation.md`
- **后置 Story**: `production/epics/economy-management-system/story-008-transaction-log-save-contract.md`, `production/epics/economy-management-system/story-009-settlement-order-concurrency-regression.md`
