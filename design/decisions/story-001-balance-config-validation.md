# Change Log: 定义 BalanceConfig 数据资源与启动校验

## 基础信息
- **Story ID**: Story 001
- **Epic**: 数值系统
- **负责代理**: gameplay-programmer (执行), lead-programmer (审查，lean 模式下由 `/code-review` 结果内联确认)
- **完成日期**: 2026-05-25

## 变更摘要
完成了数值系统的第一条基础故事：新增 `BalanceConfig` typed Resource 的启动校验接入，确保共享数值参数通过 `ConfigLoader` 从 `res://config/balance_config.tres` 加载，并在配置无效时阻止启动。为满足验收与评审要求，还将测试拆分为纯内存 unit coverage 与 loader-path integration coverage，并补充了 smoke evidence。

## 设计决策
| 决策点 | 选择方案 | 理由 | 替代方案 (已否决) |
|--------|----------|------|--------------------|
| Balance 共享参数的承载形式 | 使用 `BalanceConfig` Custom Resource + `.tres` 文件 | 符合 ADR-0004 的数据驱动配置决策，能在 Godot 中提供 typed `@export` 字段与启动校验 | 在 `src/` 中保留 gameplay 常量；使用 JSON / ConfigFile |
| 配置加载失败时的处理 | 由 `ConfigLoader` fail-fast，记录错误并退出启动 | 故事与 ADR 都要求 invalid config 不能进入运行时，避免静默坏数据污染后续系统 | 容忍坏配置继续启动；回退到隐式默认值 |
| 测试分层 | unit test 只测内存中的 `BalanceConfig.validate()` 与公式；integration test 负责真实资源和 loader 行为 | 修复 `/code-review` 指出的 unit test 读取真实文件问题，同时保持 Story 001 的验收路径可测 | 继续把真实 `.tres` 读取留在 unit test；只做静态检查不补 integration 覆盖 |
| Loader 可测接缝 | 在 `ConfigLoader` 增加 path/resource 级公开测试接缝 | 用最小改动覆盖缺失文件、无效资源、校验失败等路径，不改变生产启动逻辑 | 为测试重构完整配置域注册表；直接从测试里反射或访问私有方法 |

## 影响范围
- **修改/新增的文件**:
  - `src/config/balance_config.gd`
  - `src/autoload/config_loader.gd`
  - `config/balance_config.tres`
  - `tests/unit/balance/balance_config_validation_test.gd`
  - `tests/integration/balance/balance_config_loader_integration_test.gd`
  - `production/qa/smoke-2026-05-25.md`
  - `production/epics/balance-system/story-001-balance-config-validation.md`
  - `production/session-state/active.md`
- **影响的其他系统**: Balance System foundation config surface, ConfigLoader autoload contract, downstream balance consumers (`PlayerDevelopment`, `MatchCompetition`, `EconomyManager`, `TownBuilding`) 的共享参数入口
- **数据/配置变更**: 新增并固定使用 `res://config/balance_config.tres` 作为 BalanceConfig 权威资源；为 loader 增加按 path / resource 校验接口以支持测试

## 质量保证
- **通过的测试**:
  - `tests/unit/balance/balance_config_validation_test.gd`
  - `tests/integration/balance/balance_config_loader_integration_test.gd`
  - `production/qa/smoke-2026-05-25.md`（PASS WITH WARNINGS，因本会话未执行本地 Godot）
- **Agent 审查摘要**: `/code-review` 结论为可接受；修复了 unit test 直接依赖真实资源文件的问题，并补齐了 modifier budgets、KPI ranges、NaN/Inf、ordering 与 loader error-path coverage。仍保留两条 advisory：脚本导出默认值的解释空间，以及 smoke evidence 未在会话内实跑 Godot。

## 依赖关系
- **前置 Story**: None
- **后置 Story**:
  - `production/epics/balance-system/story-002-attribute-formula.md`
  - `production/epics/balance-system/story-003-attribute-growth.md`
  - `production/epics/balance-system/story-004-resource-settlement.md`
  - `production/epics/balance-system/story-005-positional-rating.md`
  - `production/epics/balance-system/story-006-win-probability.md`
  - `production/epics/balance-system/story-007-kpi-formulas.md`
