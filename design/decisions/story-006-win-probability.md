# Change Log: Story 006 — 实现基准胜率公式与边界

## 基础信息
- **Story ID**: Story 006
- **Epic**: 数值系统
- **负责代理**: engine-programmer (执行), none — lean mode (审查)
- **完成日期**: 2026-05-26

## 变更摘要
在 `BalanceConfig` 已有共享胜率公式与配置字段的基础上，补齐了 Story 006 所需的专用逻辑测试与故事闭环记录，确认 `base_win_probability` 继续作为共享数值锚点存在于 `BalanceConfig` 中，由 `rating_win_slope`、`win_probability_floor`、`win_probability_ceiling` 三个配置参数驱动。新增的单元测试覆盖了五五开、线性评分差、极端差值钳制，以及比赛系统传入超过 100 的有效队伍评分这四类核心验收路径。

## 设计决策
| 决策点 | 选择方案 | 理由 | 替代方案 (已否决) |
|--------|----------|------|--------------------|
| 共享公式归属位置 | 保持 `base_win_probability` 在 `BalanceConfig` 中作为共享公式 | 符合 ADR-0004 的共享配置与共享公式边界，避免在 MatchCompetition 中重新定义一套基础胜率规则 | 把公式迁到 MatchCompetition；由下游系统自行持有基础胜率公式 |
| 胜率参数来源 | 继续使用 `rating_win_slope`、`win_probability_floor`、`win_probability_ceiling` 的 config 字段 | 符合 data-driven tuning 约束，避免把数值边界硬编码进 `src/` | 在公式函数里直接写死 `0.0045 / 0.05 / 0.95` |
| >100 队伍评分处理 | 接受比赛系统传入大于 100 的 team rating，不做属性式 1–100 钳制 | GDD 已明确队伍评分可因设施等赛前修正超过 100，公式只负责消费差值并在结果侧钳制到 0.05–0.95 | 在输入侧把 team rating 强行钳制回 100；把 >100 视为无效输入 |
| 本 story 的实现范围 | 仅补齐共享锚点的故事证据与闭环，不扩展到 MatchCompetition 行为 | 该 story 的职责是共享锚点，不是主场、战术、事件模拟或实际胜率整合 | 顺手实现 actual win probability；顺手修改 MatchCompetition 调用链 |
| 测试策略 | 先为 Story 006 增加最小专用公式测试文件，并复用现有 `balance_config_validation_test.gd` 作为配置校验证据补充 | 以最小改动满足 story close 所需证据，同时不重复已有 config range 校验逻辑 | 为 Story 006 重写一整套独立配置校验测试；等待统一测试 runner 基础设施完善后再补故事证据 |

## 影响范围
- **修改/新增的文件**:
  - `production/epics/balance-system/story-006-win-probability.md`
  - `tests/unit/balance/win_probability_test.gd`
- **影响的其他系统**: BalanceConfig 共享公式面、MatchCompetition 下游消费边界、Balance 测试证据
- **数据/配置变更**: 无新增 `.tres` 数据变更；继续使用已有 `rating_win_slope = 0.0045`、`win_probability_floor = 0.05`、`win_probability_ceiling = 0.95` 配置字段

## 质量保证
- **通过的测试**:
  - `tests/unit/balance/win_probability_test.gd`
  - 交叉参考：`tests/unit/balance/balance_config_validation_test.gd` 已覆盖 `rating_win_slope` 范围校验与公式配置变化路径
- **Agent 审查摘要**:
  - Lean mode 下完成代码审查，结论为 **APPROVED WITH SUGGESTIONS**
  - 主要 advisory：
    - `win_probability_test.gd` 通过脚本默认值验证公式输出，没有直接加载 `res://config/balance_config.tres`
    - 未在 Story 006 专用证据文件里单独断言“恰好命中 0.05 / 0.95 边界值”的保持行为
    - 仓库仍缺少项目文档声明的标准 Godot test runner wiring

## 依赖关系
- **前置 Story**: `production/epics/balance-system/story-005-positional-rating.md`
- **后置 Story**: `production/epics/balance-system/story-009-balance-statistical-validation.md`
