# Repository Guidelines Design

## 目标

在仓库根目录新增 `AGENTS.md`，为贡献者提供一份简洁、可执行且符合当前 Football Town 项目实况的中文指南。文档标题固定为 `Repository Guidelines`，正文控制在约 200–400 词。

## 内容范围

指南以 Godot 4.6 游戏项目为主，不复述根目录 `CONTRIBUTING.md` 中仅适用于上游 CCGS 框架的贡献规则。正文包含：

- `src/`、`tests/`、`config/`、`assets/`、`design/`、`docs/` 与 `production/` 的职责。
- 使用 Godot 编辑器运行项目，以及通过 `tests/test_script_runner.gd` 执行单个无头测试的命令。
- GDScript 的制表符缩进、静态类型、文件与标识符命名、公共 API 文档注释和数据驱动配置要求。
- 测试文件与函数命名、确定性和隔离性要求，以及逻辑系统 70% 最低覆盖目标。
- 从 Git 历史和现有规范提炼的 Conventional Commits、任务引用和 PR 验证要求。

## 边界与验证

文档保持高密度，不声明仓库中不存在的格式化、lint 或全量测试命令。完成后检查标题、Markdown 结构、命令路径、篇幅和与 `.claude/docs/` 规则的一致性。
