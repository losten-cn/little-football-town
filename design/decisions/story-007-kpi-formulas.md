# Change Log: Story 007: 实现 KPI 与诊断公式

## 基础信息
- **Story ID**: Story 007
- **Epic**: 数值系统
- **负责代理**: engine-programmer (执行), godot-gdscript-specialist + qa-tester (审查)
- **完成日期**: 2026-05-26

## 变更摘要
在 `BalanceConfig` 中补齐了共享诊断公式层：`action_point_use_rate`、`overall_win_rate`、`even_match_win_rate`、`milestone_completion_time`，统一返回 `DiagnosticSample` 以承载数值与 `invalid_sample` 标记。实现过程中将 even-match 判定阈值改为读取 `BalanceConfig` 目标区间，并补充了对 `NaN`/`Inf`、零分母、负输入、超上限输入和小数可用量场景的回归测试。评审过程中同步修正了 `TR-balance-009` 与 story 文档的映射文字，使其与当前 GDD/实现口径一致地指向 milestone completion time，而非 resource efficiency。

## 设计决策
| 决策点 | 选择方案 | 理由 | 替代方案 (已否决) |
|--------|----------|------|--------------------|
| 诊断公式返回结构 | 使用 `DiagnosticSample(value, invalid_sample)` 统一封装结果 | 允许共享公式同时表达“安全返回值”和“该样本不应进入调优审查”，与故事 AC 中的 invalid-sample 语义一致 | 仅返回 `float`；由调用方各自维护 invalid 标记 |
| even-match 阈值来源 | 读取 `BalanceConfig.even_match_win_rate_target_min/max` | 避免在 `src/` 中硬编码 `0.45/0.55`，符合 ADR-0004 数据驱动配置原则 | 在 `compute_even_match_win_rate()` 内直接写死 `[0.45, 0.55]` |
| action point 零分母与小数分母处理 | `available == 0` 返回安全零且标 invalid；`available > 0` 时按真实分母相除 | 保持零分母安全，同时修复 `0 < available < 1` 时 `max(1, available)` 会压低结果的问题 | 严格沿用 `max(1, action_points_available)` 到所有正分母场景 |
| Story 007 范围对齐 | 将 story / TR 映射文字对齐到 `milestone_completion_time` | 当前 GDD、故事 AC 与实现都落在 milestone completion time；继续追补未定义的 resource efficiency 会引入无依据扩 scope | 为了迎合旧 TR 文字，额外新增 `resource_efficiency` 公式与测试 |

## 影响范围
- **修改/新增的文件**:
  - `src/config/balance_config.gd`
  - `tests/unit/balance/kpi_formula_test.gd`
  - `production/epics/balance-system/story-007-kpi-formulas.md`
  - `docs/architecture/tr-registry.yaml`
- **影响的其他系统**: Balance System、Match Competition（消费 even-match 诊断口径）、后续统计验证流程
- **数据/配置变更**: 未新增 `.tres` 字段；复用既有 KPI target range 配置作为 diagnostic threshold 来源；修正文档侧 `TR-balance-009` 映射文字

## 质量保证
- **通过的测试**: `tests/unit/balance/kpi_formula_test.gd`（5 个测试函数，覆盖公式值、归一化、invalid sample、非有限输入、config-backed threshold）
- **Agent 审查摘要**: 先后修复了 even-match 的 `NaN/Inf` 样本过滤、milestone timestamp 非有限值防护、action-point 小数分母计算错误，并补齐对应回归测试。最终剩余问题仅为仓库级 Godot 测试基础设施缺口（缺少 `addons/gut` / `addons/gdunit4` / `tests/gdunit4_runner.gd`），已作为非 story 独有说明保留在 completion notes 中。

## 依赖关系
- **前置 Story**: `production/epics/balance-system/story-001-balance-config-validation.md`
- **后置 Story**: `production/epics/balance-system/story-009-balance-statistical-validation.md`
