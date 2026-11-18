# 任务记录

实际改动按 [AGENTS.md](AGENTS.md) 追加。当前状态见 [HANDOFF.md](HANDOFF.md)。

### 2026-11-18 [文档] 合并 Agent 约定

- 将另一项目的过程规则改写成关公游戏约定，并与原 `AGENT.MD` 的工程、素材、战斗、验证和协作规则合并进 `AGENTS.md`。用户要求只保留一个说明文件，因此删除 `AGENT.MD`。
- `README.md` 和 `HANDOFF.md` 的入口改为只指向 `AGENTS.md`。当前实现状态仍留在 `HANDOFF.md`。
- 纯文档改动。`git diff --check` 通过，并对改动文件做了行尾空白检查。

### 2026-11-18 [文档] 本地 Godot 运行说明

- 新增 `docs/local-godot.md`，写明 Godot 4.7.2 的安装、导入 `godot/project.godot`、F5 试玩、操作、命令行和无头检查。编辑器运行与网页导出分开说明。
- `README.md`、`godot/README.md` 和 `HANDOFF.md` 加上该说明的入口。
- 纯文档改动，未运行 Godot。`git diff --check` 通过，新文件和改动文件无行尾空白、无 CR。
