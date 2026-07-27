# Repository Guidelines

## 项目结构与模块组织

这是一个 Godot 4.6/GDScript 2D 经营模拟项目。运行时代码位于 `src/`：`core/` 放领域逻辑，`autoload/` 放全局服务，`config/` 定义配置资源，`ui/` 与 `world/` 负责表现。可调参数存放于 `config/*.tres`，不要硬编码进脚本。测试按 `tests/unit/`、`tests/integration/`、`tests/manual/` 和 `tests/smoke/` 分类。美术资源在 `assets/`，玩法设计在 `design/`，架构与 ADR 在 `docs/architecture/`，迭代及 QA 证据在 `production/`。

## 构建、测试与开发命令

- `godot --editor --path .`：在 Godot 编辑器中打开项目。
- `godot --path .`：运行配置的主场景。
- `godot --headless --path . --script res://tests/test_script_runner.gd -- --test-script=res://tests/unit/balance/balance_config_validation_test.gd`：无头运行单个测试；其他测试替换最后的资源路径。

仓库没有统一的格式化或 lint 脚本，也没有已配置的命令行导出流程；提交前应至少执行受影响的自动化测试，并在编辑器中检查场景或 UI 改动。

## 编码风格与命名约定

GDScript 使用制表符缩进和静态类型。类、场景使用 `PascalCase`，脚本、变量、方法及信号使用 `snake_case`，常量使用 `UPPER_SNAKE_CASE`；示例：`MatchFlow.tscn`、`match_simulation.gd`、`match_completed`。公共 API 使用 `##` 文档注释。稳定接口优先使用类型化集合，运行时 `Variant` 边界先规范化。依赖应可注入，新增系统需有对应 ADR；使用 Godot API 前查阅 `docs/engine-reference/godot/`。

## 测试指南

测试文件命名为 `[system]_[feature]_test.gd`，函数命名为 `test_[scenario]_[expected]`。测试必须确定、隔离且不依赖执行顺序；逻辑和公式系统目标覆盖率至少 70%，边界值及回归路径必须覆盖。UI 改动除交互测试外，还应在 `production/qa/evidence/` 留存截图或人工验证记录。

## 提交与拉取请求

历史提交采用 Conventional Commits：`feat:`、`fix:`、`docs:`、`chore:`、`refactor:`、`test:`。主题行简洁描述结果，并在正文引用 Story、任务 ID 或设计文档。PR 应说明变更范围、关联问题/故事、实际执行的测试及结果；UI 或视觉改动附前后截图。不要通过跳过失败测试来合并变更，也不要提交密钥、用户存档、导入缓存或临时测试日志。
