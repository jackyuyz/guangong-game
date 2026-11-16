# Agent 工作约定

本仓库是「关公 · 过五关斩六将」课程合作项目。本文说明长期约定；当前进度与待办见 [HANDOFF.md](HANDOFF.md)。先阅读这两份文件，再根据用户最新指令工作。交接中的暂停状态是当时的快照，不覆盖之后的新指令。

## 工程与目录

- 使用 **Godot 4.7.2、GDScript、Compatibility 渲染器**，工程入口为 `godot/project.godot`；`res://` 对应 `godot/`。
- `godot/scenes/main.tscn` 是组合入口，关卡、角色、UI 分别在 `scenes/levels/`、`scenes/characters/`、`scenes/ui/`。
- 背景、人物、交互物和 UI 应使用可在编辑器中预览、选中、调整的真实节点，布局保存在 TSCN。不要重新退回单个 Node2D 在运行时绘制整个游戏，或只靠 `@tool` 假预览。
- `main.gd` 管战斗与会话状态；`level_view.gd`、`actor_view.gd`、`game_ui.gd` 管表现；`combat_extensions.gd` 管新增机制。刀光、残影、粒子等短暂效果可以程序绘制。
- 修改表现层时保留编辑器中配置的布局与变换；改变生成位置、移动范围或交互位置时，同时检查逻辑是否仍有硬编码。
- `docs/design/chapter-01-godot-spec.md` 是第一关原始设计依据。用户已授权探索额外功能和交互，不能仅因偏离旧 spec 回滚扩展；新决定需在设计文档中说明。

## 素材与动画

- 优先使用现有 `assets/art/` 素材库，源文件不覆盖、不删除。展示图位于 `docs/art/`。
- 实际使用的素材复制到 `godot/assets/`，保留来源和许可说明；不要把全部素材库导入运行工程。
- 保持像素角色画风，使用最近邻采样。扩展图集必须保留角色身份、比例、朝向与脚底基线，并检查武器裁切和帧切换。
- 现有关羽、守军、孔秀生成图集位于 `godot/assets/animations/`，尺寸 1774×887，按 4×2 浮点 AtlasTexture 切片。idle/hurt 等部分动作复用帧，不要宣称每种动作都有独立帧。
- 素材说明见 `godot/assets/SOURCES.md`，字体遵循 `FONT-LICENSE.txt`。`demo-font.ttf` 是 Noto Sans SC 字符子集，新增汉字后须检查缺字并重建子集。

## 战斗、保存与交互

- 现有操作：A/D 或左右移动，J 连击，Space 闪避，K 格挡/弹反，L 义气偃月斩，E 茶摊互动，Enter 对白，Esc/P 暂停，M 声音。
- 单次攻击对同一敌人只伤害一次。Boss 致命伤优先结算胜利，之后不得继续造成敌方伤害。
- 暂停、失焦、对白和失败时不接受战斗输入；检查独立动画与音频是否也正确停止。
- 原生按钮、键盘确认和模态遮罩不得重复触发或让输入穿透。
- Boss 检查点恢复血量、成功路径计时/受击数和义气；失败尝试统计丢弃，重试次数保留。更改这些规则时补针对性测试。
- 用户真实存档不得用于测试或被清除；测试使用隔离临时存档。不得将存档、缓存或机器凭据提交到 Git。
- 配音、题库、多语言和文本组审定内容尚未交付。草稿对白不得称为原文或已审定文本；文化说明保留文学改编与非历史复原的区分。

## 验证与交付

在仓库根目录运行，`GODOT` 可指向已安装的 Godot 4.7.2：

```sh
GODOT=/path/to/Godot
"$GODOT" --headless --path godot --editor --import --quit
"$GODOT" --headless --path godot --script scripts/smoke_test.gd
"$GODOT" --headless --path godot --script scripts/scene_test.gd
"$GODOT" --headless --path godot --script scripts/extensions_test.gd
```

- 读取完整输出，不能只看退出码；GDScript 错误可能出现在退出码为 0 的进程中。
- 场景/动画/UI 修改后，实际检查编辑器 2D 视图和运行画面；自动检查不等同视觉验收或真人通关。
- Web 单线程导出到 `builds/web/index.html`：`"$GODOT" --headless --path godot --export-release Web ../builds/web/index.html`。
- `python3 tools/serve_demo.py` 或 `play-web.command` 启动本机 HTTP 服务。先确认导出时间与源码对应，不能用旧 Web 包证明新版可玩。
- `.godot/`、`builds/`、IDE 状态不提交；保留源素材、`.import` 导入配置、脚本 `.uid`、TSCN 和导出预设。
- 汇报用简洁中文，区分已实现、自动验证、实际试玩和待验证。新一轮暂停/交接时更新 HANDOFF.md。

## Claude 协作

用户允许使用 Claude **Fable 5.2 medium** 或 **Opus 5.5 high** 协作。已验证本机 Claude Code CLI 能运行 `--model claude-opus-5-5 --effort high`。

- 给协作者清晰任务、独占文件范围和可调用接口，避免同时修改同一文件。
- Claude 适合实现新玩法、交互和独立审查；主代理负责整合及 computer use、编辑器/浏览器试玩。
- 不把模块测试通过当作整体验收，不把未交付的审查称为通过。
- 只授予任务需要的工具权限；不输出凭据，不提交本地模型日志。用户的新指令优先于既有分工。

## 接续重点

当前是整合中版本；具体问题与优先级以 HANDOFF.md 为准。优先核查动画暂停、场景位置与逻辑常量的关联、第二波守军实例绑定、新机制整合与实际通关，然后更新文档、重新导出验证。不要在没有检查现场的情况下宣称这些问题已修复。
