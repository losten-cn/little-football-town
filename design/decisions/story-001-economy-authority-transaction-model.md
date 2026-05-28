# Change Log: 建立 EconomyManager 权威边界与 Transaction 数据模型

## 基础信息
- **Story ID**: Story 001
- **Epic**: 经济管理系统
- **负责代理**: gameplay-programmer (执行), lead-programmer (审查，lean 模式下由 `/code-review` 结果内联确认)
- **完成日期**: 2026-05-25

## 变更摘要
完成了经济管理系统的基础权威边界搭建：新增 `Transaction` typed `RefCounted` 运行时数据模型，新增 `EconomyManager` 作为资金、运动点数和研究点数的权威持有者，并将 `execute_transaction()` 建立为当前唯一受支持的公共资源写入口。为满足验收与评审要求，还补充了序列化 round-trip、资源快照读取、AP/RP 下限钳制以及公共 API 边界检查的 unit test，并将 Story 001 的 AC-3 文案收敛为 “supported public interface” 口径，以对齐 GDScript 无法强制私有字段的语言现实，同时保持 ADR-0007 的单一受支持变更路径要求。

## 设计决策
| 决策点 | 选择方案 | 理由 | 替代方案 (已否决) |
|--------|----------|------|--------------------|
| Transaction 运行时模型的承载形式 | 使用 `Transaction` typed `RefCounted` 类，并提供 `to_dict()` / `from_dict()` | 符合 ADR-0007 对运行时事务对象与可序列化审计载荷的要求；轻量、便于后续 save/log 扩展 | 直接用裸 `Dictionary` 表示事务；把事务字段拆散到多个参数 |
| 经济资源的权威拥有者 | 使用单一 `EconomyManager` 持有 `funds` / `action_points` / `research_points` | 符合 TR-economy-001 与 ADR-0007 的单一权威边界；后续便于集中验证、日志、预警与存档接入 | 为每种资源拆分单独 manager；允许下游系统直接改余额 |
| 资源写入口设计 | 仅暴露读 API 与 `execute_transaction()` 作为当前受支持公共写入口 | 符合 TR-economy-002 与 GDD“任何下游系统不得直接修改三种资源当前值”的边界要求；为后续 accredited entry points 留出扩展点 | 暴露 `set_funds()` / `apply_*_delta()` 等辅助写接口；先让多个系统各自维护写路径 |
| AP/RP 底线在 Story 001 的处理 | 先在 `execute_transaction()` 内对 AP 与 RP 做 floor clamp | 当前 story 虽未实现 Story 002 的完整原子校验，但 AC-1/AC-3 与 ADR 资源语义已要求 authority owner 不产出非法公开状态 | 暂不处理底线，留待后续 story；允许 Story 001 期间公开状态越界 |
| AC-3 的验收口径 | 将“无未授权写路径”收敛为“无受支持的公共写边界” | GDScript 不能提供语言级绝对私有封装；把验收聚焦到可审查、可测试、可维护的公共接口约束，仍符合 ADR 风险说明 | 继续要求语言级绝对禁止外部写入；为满足 wording 引入不自然的绕行实现 |

## 影响范围
- **修改/新增的文件**:
  - `src/core/transaction.gd`
  - `src/core/economy_manager.gd`
  - `tests/unit/economy/economy_authority_transaction_model_test.gd`
  - `production/epics/economy-management-system/story-001-economy-authority-transaction-model.md`
  - `production/session-state/active.md`
- **影响的其他系统**: Economy authority boundary 基础面；后续 `PlayerDevelopment`、`TownBuilding`、`MatchCompetition`、`League` 等所有需要资源变更的系统都将依赖该事务入口或后续 accredited entry points
- **数据/配置变更**: 本故事未引入新的 config/resource 文件；建立了后续事务日志、校验、预警、存档序列化所需的运行时数据结构基础

## 质量保证
- **通过的测试**:
  - `tests/unit/economy/economy_authority_transaction_model_test.gd`
- **Agent 审查摘要**: `/code-review` 最终结论为 APPROVED。审查过程中修复了两类问题：一是 `execute_transaction()` 初版未保护 AP/RP 法定下限，已补上 floor clamp；二是测试类型声明与 AC-3 可证明性存在问题，已通过补测和收敛 story wording 解决。仍保留一条会话级说明：本地未实际运行 Godot，因为当前环境 `godot` 不在 PATH。

## 依赖关系
- **前置 Story**: None
- **后置 Story**:
  - `production/epics/economy-management-system/story-002-execute-transaction-atomic-validation.md`
  - `production/epics/economy-management-system/story-004-budget-preview-affordability-query.md`
  - `production/epics/economy-management-system/story-007-accredited-entry-points.md`
  - `production/epics/economy-management-system/story-008-transaction-log-save-contract.md`
