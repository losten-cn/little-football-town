# Authority-Contract Decision Checklist

> **用途**: 在 authority-contract / convergence 类 story 进入 `/dev-story` 之前快速自检。  
> **来源**: Sprint 3 Story 003 教训 — 实现前未先定语义决策，导致多轮 `/code-review` 往返。  
> **使用时机**: `/story-readiness` 通过后、`/dev-story` 开始前。

---

## 前置决策（实现前必须回答）

### 1. Authority Purity 优先级

> 当 "保持现有 UX richness" 和 "authority truth 只来自 payload" 冲突时，哪个优先？

- [ ] **Authority purity first** — UI 宁可显示 neutral placeholder，也不本地推导 explanation
- [ ] **UX richness first** — UI 在 payload 缺失时允许保留有限的 fallback 说明

**Story 003 教训**: 选了 authority purity first。如果在实现前就定好，至少节省一轮 review 往返。

---

### 2. Refresh 语义

> 当 authoritative payload 重新到达（read-model republish、time_advanced、system_state_changed），UI 应以哪个值为准？

- [ ] **Latest producer wins** — 以最新 authoritative producer 发出的值为准，即使与首次注入值不同
- [ ] **First value sticky** — 首次到达的 explanatory 值持续保留，直到上游显式替换

**Story 003 教训**: 选了 latest producer wins。如果没定这个，refresh 回归测试会一直不确定该验证什么。

---

### 3. Explanatory Field 归属

> 下面这些 player-facing explanation 字段，由谁生成？

| 字段 | Producer 生成 | UI 只读消费 | 允许 UI neutral fallback | 备注 |
|------|:---:|:---:|:---:|------|
| attention_reason | □ | □ | □ | |
| role_summary / usage_summary | □ | □ | □ | |
| next_step_summary | □ | □ | □ | |
| training_reason | □ | □ | □ | |
| training_risk_summary | □ | □ | □ | |
| training_payoff_summary | □ | □ | □ | |
| cost_summary | □ | □ | □ | |
| attributes_summary | □ | □ | □ | |
| growth_summary | □ | □ | □ | |
| status_summary | □ | □ | □ | |
| disable_reason (≠ risk_summary) | □ | □ | □ | 这两个字段语义分离 |

**规则**: 如果 "Producer 生成" 被勾选，该字段的 truth 必须在 `roster_updated` / `training_options_updated` 等 payload 中由 producer 提供。如果 "允许 UI neutral fallback" 被勾选，缺字段时 UI 只能给中性占位（如 `暂无说明`），不得生成策略性建议。

---

### 4. Selection Context Authority

> 谁来选定 "当前关注的球员 / 训练项"？

- [ ] **Authority only** — selected_player_id / selected_training_id 只能来自 payload 或显式 player_selected 事件
- [ ] **UI may default** — 在缺失 authoritative context 时，UI 可以本地默认选择第一个可用项

**Story 003 教训**: 选了 authority only。`_select_first_player_if_needed()` 被改为直接 `return`。

---

### 5. Test Contract Impact

> 这条 story 会导致现有测试 / walkthrough 需要同步改动吗？

- [ ] **是** — 下面列出预期影响：
  - [ ] `l2_playable_loop_panels_test.gd` 需要更新断言
  - [ ] `mvp_visual_walkthrough_runner.gd` 需要更新 fixture / flow
  - [ ] 需要新建 dedicated integration test 文件
- [ ] **否** — 现有测试应不受影响

---

### 6. Disable Reason vs. Risk Summary 分离

> `disable_reason`（为什么不能做）和 `risk_summary`（做了有什么风险）是否严格分开？

- [ ] **严格分离** — `disable_reason` 绝不能兼任 `risk_summary`
- [ ] **允许共用** — 在 unavailable 场景下可以将 `disable_reason` 当作 `risk_summary` 展示

**Story 003 教训**: 选了严格分离。如果允许共用，producer 默认值策略会导致测试无限失败。

---

## 使用方式

1. 在 `/story-readiness` 通过后、启动实现前，逐项勾选
2. 将勾选结果附在 story 的 Implementation Notes 或新增的 `## Pre-Implementation Decisions` 小节中
3. `/code-review` 时用此清单复核

**不要求所有 authority-contract stories 都填满本清单。** 如果某 story 完全不涉及 explanatory payload / selection authority / refresh semantics，可以标 `N/A`。
