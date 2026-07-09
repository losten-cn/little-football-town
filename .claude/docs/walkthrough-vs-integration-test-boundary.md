# Walkthrough vs. Integration Test Validation Boundary

> **用途**: 规范 walkthrough runner 和 integration test 的验证职责，避免 Sprint 3 Story 003 中 walkthrough 被 authority contract 变更反复打坏的教训。  
> **来源**: Sprint 3 retrospective — walkthrough 维护成本偏高，与 authority contract 耦合太紧。  
> **生效范围**: 所有 Presentation / UI / Integration stories。

---

## 职责边界

| 维度 | Integration Test | Walkthrough Runner |
|------|-----------------|-------------------|
| **主验证目标** | Authority semantics — UI 是否消费了正确的权威 payload | Visibility / route smoke — 页面能不能走通、控件能不能看到 |
| **典型断言** | "detail 显示的是权威 `training_reason`，不是本地推导的" | "roster route 可到达，PlayerMgmtPanel 可见，RosterList 存在" |
| **对 payload 变更的敏感度** | 高 — 应该敏感，这正是 integration test 存在的意义 | 低 — 应该不敏感，只需要最少的 payload fixture |
| **失败时意味什么** | Authority contract 被破坏或漂移 | 路由、渲染、节点层次被破坏 |
| **应由谁维护** | 与 story 的 authority contract 一起演进 | 只在 route / shell / 节点名变更时更新 |
| **证据类别** | BLOCKING (Logic/Integration stories) | ADVISORY (UI/Visual stories) |

---

## Walkthrough 只验证

- 路由可达（Home → Roster → Player Detail → Training → Home）
- 关键控件可见（不要求具体文案，只要求节点存在且 visible）
- 页面非空白
- 无 crash 或 fatal error

## Walkthrough 不验证

- authority explanatory 字段的具体值
- selected player / selected training ID 的来源
- refresh 后是否回退到本地 fallback
- disable_reason / risk_summary 的语义正确性

## Integration Test 验证

- authoritative payload 字段是否被 UI 正确消费
- 缺失 explanatory 字段时 UI 是否只给 neutral placeholder
- selected player context 是否来自 authority
- refresh 是否保持 authority alignment

---

## Story Template 建议

在后续 story 的 `## Test Evidence` section 中，建议区分两条 evidence 链：

```markdown
## Test Evidence

**Story Type**: UI

**Required evidence**:

- Authority contract evidence (BLOCKING):
  - `tests/integration/ui/[system]_authoritative_[feature]_test.gd`
- Visibility / route evidence (ADVISORY):
  - `MVP_VISUAL_WALKTHROUGH_STRUCTURE_PASS` or walkthrough smoke
```

---

## 对现有 Runner 的适用性

| Runner | 当前职责 | 建议 |
|--------|---------|------|
| `mvp_visual_walkthrough_runner.gd` | 混合 (route + authority + placeholder checks) | 保留 route/visibility/placeholder checks；去掉 authority-field 断言 |
| `main_loop_shell_navigation_test.gd` | Route + Home exemplar guardrails | 不变 — 已在正确边界内 |
| `l2_playable_loop_panels_test.gd` | Route + handoff + structural anchors | 保持不变；结构锚点属于 route/visibility 范畴 |
| `player_mgmt_authoritative_explanatory_payload_test.gd` | Pure authority contract | 不变 — 正确示范 |

---

## 决策记录

- **Adopted**: 2026-07-09 (Sprint 4 governance)
- **Applies to**: all future Presentation / UI / Integration stories
- **Review point**: after next authority-contract story completes, assess whether this boundary reduced walkthrough churn
