# Change Log: Story 001: 建立 Facility 数据模型与网格索引契约

## 基础信息
- **Story ID**: Story 001
- **Epic**: Town Building System
- **负责代理**: gameplay-programmer (执行), lead-programmer (审查)
- **完成日期**: 2026-05-25

## 变更摘要
实现了 TownBuilding 的 5×5 扁平 typed grid 权威模型与 Facility 运行时数据模型，并补齐 Story 001 所需的集成合同测试。实现重点是将网格与设施注册表收敛到 Core 层权威状态，提供只读查询副本边界，并验证非法查询不会改变状态。

## 设计决策
| 决策点 | 选择方案 | 理由 | 替代方案 (已否决) |
|--------|----------|------|--------------------|
| Facility 运行时载体 | `RefCounted` + 手动 `to_dict()/from_dict()` | 与 ADR-0008 一致，适合轻量运行时对象，也为后续序列化故事保留明确边界 | `Resource` 作为运行时设施实例 —— 更重，且会把运行时模型和资源语义混在一起 |
| Town 网格存储 | `Array[Facility]` 扁平数组 + `x + y * width` | 满足 TR-town-001 与 ADR-0008，对 5×5 小网格最直接，typed collection 也符合控制清单 | `Dictionary` 稀疏网格 —— 不符合 ADR-0008 的 flat typed grid 方向 |
| 下游读接口边界 | `get_facility_at()` / `get_facility()` 返回 `duplicate_for_query()` 副本 | 防止泄漏权威可变实例，保持 TownBuilding 是唯一真实状态持有者 | 直接返回内部 `Facility` 引用 —— 会让外部调用方绕过权威边界修改状态 |
| 测试接入方式 | 独立 headless `SceneTree` 集成脚本 | 可直接通过 Godot `-s` 执行，覆盖 Story 001 的三条验收标准 | 仅依赖后续更大的系统测试 —— 当前故事关闭时缺少最小可验证证据 |

## 影响范围
- **修改/新增的文件**:
  - `src/core/facility.gd`
  - `src/core/town_building.gd`
  - `tests/integration/town/town_grid_contract_test.gd`
  - `production/epics/town-building-system/story-001-town-grid-facility-contract.md`
- **影响的其他系统**: Town Building System, Core runtime model, future Save/Load serialization story, future build/upgrade/demolish stories
- **数据/配置变更**: 无

## 质量保证
- **通过的测试**: `tests/integration/town/town_grid_contract_test.gd`（Godot headless PASS，输出 `TOWN_GRID_CONTRACT_TEST_PASS`）
- **Agent 审查摘要**: `/code-review` 复审通过；ADR-0008 合规；测试覆盖 3/3 验收标准。另有非阻塞告警：测试退出时存在资源清理 warning。

## 依赖关系
- **前置 Story**: None
- **后置 Story**: `production/epics/town-building-system/story-002-facility-cost-time-formulas.md`, `production/epics/town-building-system/story-003-build-request-validation.md`, `production/epics/town-building-system/story-004-upgrade-completion-flow.md`, `production/epics/town-building-system/story-005-demolish-grid-release.md`, `production/epics/town-building-system/story-006-training-medical-youth-formulas.md`, `production/epics/town-building-system/story-007-stadium-adjacency-formulas.md`, `production/epics/town-building-system/story-008-downstream-query-maintenance.md`, `production/epics/town-building-system/story-009-serialization-restore-regression.md`
