# Story 003 决策日志 — 实现属性成长公式与潜力边界

- **Story ID**: Story 003
- **故事文件**: `production/epics/balance-system/story-003-attribute-growth.md`
- **完成日期**: 2026-05-27
- **主执行代理**: engine-programmer
- **系统**: Balance System
- **相关实现文件**:
  - `src/config/balance_config.gd`
  - `tests/unit/balance/attribute_growth_test.gd`

## 变更摘要
本次实现将共享属性成长公式收口到 `BalanceConfig`，补入潜力边界归一化与配置驱动的衰减参数读取，并新增可 headless 运行的逻辑测试，验证成长曲线、上限归零、低潜力归一化以及配置默认值与校验边界。

## 关键决策

| 主题 | 采用方案 | 原因 | 放弃方案 |
|---|---|---|---|
| 共享公式归属 | 将 `compute_attribute_growth(...)` 放入 `src/config/balance_config.gd` | 该公式属于跨系统共享数值面，符合 ADR-0004 的 data-driven config 方向 | 继续只保留在 `src/core/player_development.gd` 中 |
| 实现范围 | 先补共享公式与专用测试，不迁移整条 PlayerDevelopment 调用链 | 这是最小可验证收口，能先关闭 Balance story，避免把下游玩家成长逻辑一起卷入 | 同步重构 PlayerDevelopment 所有成长调用 |
| 潜力边界处理 | 当 `potential_cap < current_attribute` 时将 potential 归一化到 current | 与 Story 003 acceptance criteria 对齐，并保证不会产生负增长或非法分母 | 直接报错中断计算 |
| 测试入口 | 使用 `SceneTree` 形式的 headless 逻辑测试 | 与当前仓库已通过的 balance/unit 测试风格保持一致，便于直接 `--script` 运行 | 使用普通 `Node` 入口或依赖场景运行器 |

## 影响范围
- **Balance System**：共享成长曲线正式进入 `BalanceConfig`
- **Player Development**：为下游成长结算故事提供统一公式基线
- **Testing**：补齐 `tests/unit/balance/attribute_growth_test.gd` 自动化证据

## 质量验证
- 运行结果：`ATTRIBUTE_GROWTH_TEST_PASS`
- 验证文件：`tests/unit/balance/attribute_growth_test.gd`
- 结论：Story 003 所需 6/6 条验收标准已通过当前实现与自动化证据覆盖

## 后续影响
- 直接解锁：下游 Player Development growth stories
- 推荐后续：`production/epics/balance-system/story-008-downstream-formula-consistency-scan.md`
