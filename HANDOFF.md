# 关公游戏交接 — 2026-11-16

## 停在什么位置

用户要求先停工，之后继续。目前停在 **场景节点迁移、新玩法与动画已接入，自动检查通过，但最终编辑器验收、整体验证和新版 Web 导出尚未完成** 的阶段。不要把它称为已完成的新版。

工作目录：`/Users/wuyuetian/Documents/Developer/course/guangong-game`。
工程入口：`godot/project.godot`。实际使用 **Godot 4.7.2**；用户已下载并导入工程，工程的功能版本标记已由编辑器更新为 `4.7`，不要改回 `4.3`。

以上为暂停时的实现快照。用户之后授权编写 AGENT.MD 并将当前工程提交、推送至现有 GitHub 仓库；这不表示已公开部署游戏，也不表示待验证事项已完成。不要 reset/clean 或用旧提交覆盖当前目录。

## 用户决定与目标

- 先做能玩的 demo；人物使用已有像素素材，背景由我们选择。
- 初版用东岭关无角色背景，加关羽、守军、孔秀、赤兔与载客马车。
- 用户在 Godot 2D 编辑器里看不到场景，要求改成真实场景节点，方便直接看到和调整背景、角色、UI。
- 用户随后明确授权使用 **Claude Fable 5.2 medium 或 Opus 5.5 high** 协作，鼓励新增功能和交互，不拘泥于最初 spec；同时希望基于现有角色补动画帧。
- Claude 不负责 computer use：由 Codex 负责整合、实际编辑器/浏览器操作、画面与试玩验证。
- 最新要求是暂停并写交接；不要自行继续扩展功能。

## 已完成的代码

### 真实场景节点

- `godot/scenes/main.tscn`：组合 `Level`、`UI` 和音效节点。
- `godot/scenes/levels/dongling_pass.tscn`：背景 Sprite2D、地面、同伴、旗标、训练靶、关羽、两波守军、孔秀、退让守军、茶摊、Camera2D、特效节点。
- `godot/scenes/characters/guan_yu.tscn`、`guard.tscn`、`kong_xiu.tscn`：可复用角色；AnimatedSprite2D、脚底阴影、攻击预警、血条等均为真实节点。
- `godot/scenes/ui/game_ui.tscn`：原生 Control / Button / Label / ProgressBar，包含 HUD、菜单、对白、暂停、退出确认、失败、胜利和文化卡。布局与主题保存在 TSCN，而非运行时生成。
- UI 场景默认显示 HUD、隐藏菜单，便于在编辑器预览；运行时由状态切换显示。

### 脚本职责

- `godot/scripts/main.gd`：保留原战斗、阶段、检查点、评分和保存；不再负责绘制整个世界/UI，改为 `_sync_scene()` 调用表现层。
- `level_view.gd`：场景表现、相机跟随、角色状态；启动时读取关羽、两波守军和 Boss 的场景出生位置。
- `actor_view.gd`：朝向、动画、姿态、脚底对齐、预警和血条。
- `game_ui.gd`：状态映射到原生 UI，按钮通过 `action_requested` 信号调用主逻辑，不再手写鼠标矩形命中。
- `combat_effects.gd`：仅保留刀光、残影、粒子和浮字等程序特效。
- `sprite_cutout.gdshader`：去掉生成图集的低透明度杂边，不修改源 PNG。

### Claude 新增玩法（已接入）

由 Claude Code CLI **`claude-opus-5-5` / effort `high`** 实现：

- **K 格挡/弹反**：架刀 0.42 秒，前 0.18 秒精准弹反；只防正面。弹反积攒义气并打断敌人。孔秀横扫会击破普通格挡，须弹反或闪避。
- **L 偃月斩**：义气满 4 格才能用，普通命中 +1、弹反 +2；前方 220px 范围伤害 3，短暂无敌。无目标不消耗资源。Boss 致命伤优先结算胜利。
- **E 茶摊歇脚**：第二波清空后、x≈2060，单次回复 1 格血并补满义气；已放置茶摊节点和提示。
- Boss 进入时保存义气快照；重试恢复义气，和已有血量/时间/受击数检查点衔接。

文件：`godot/scripts/combat_extensions.gd`、`extensions_test.gd`、`docs/design/combat-extensions.md`。

接入钩子：主逻辑的按键分发、`_update_play`、普通攻击命中、`_hurt`、开局/重试，以及 Boss 进入时的零时间更新。HUD 已显示 K/L 和资源状态。

注意：Claude 的设计文档仍有“未接入主游戏”的阶段性表述，现已过时，下一次需要同步文档。

## 动画与素材

使用内置 imagegen、以原有角色为参考生成了三套透明 4×2 图集，每个角色 8 个不同姿势：4 帧走路 + 4 帧攻击姿势。游戏 SpriteFrames 配置为走路 4 帧、攻击 3 帧，另一个攻击姿势用于蓄力/架刀；idle、recover、hurt 目前复用其中的静态帧，**不是每种动作都有独立新画帧**。

项目内最终文件：

- `godot/assets/animations/guan-yu-sheet.png`
- `godot/assets/animations/guard-sheet.png`
- `godot/assets/animations/kong-xiu-sheet.png`

原始素材库 `assets/art/` 未改动；原图集副本也保留在 `godot/assets/`。茶具复制自 `assets/art/chapters/03-sishui-pass/props/tea-cup-and-tableware.png`，工程内为 `godot/assets/tea-set.png`。

生成图实际尺寸均为 **1774×887**，所以每格为 443.5×443.5；TSCN 使用浮点 AtlasTexture 区域。生成图有少量杂边，当前 shader 以 alpha < 0.75 discard 处理。需要继续目视检查武器边缘、跨格裁切和姿态一致性。

图集提示词核心：保持原角色身份、装备与像素风；4 列 2 行；第一排四帧走路，第二排起手/出招/跟进/收招；同一尺度与脚底基线；全武器入格；透明背景、无标签和网格。关羽朝右，守军/孔秀朝左。完整调用在本聊天工具记录中。

`actor_view.gd` 的 `frame_baselines` 用来补偿每帧脚底差异。Noto Sans SC 字符子集 `godot/assets/demo-font.ttf` 已重新生成，覆盖新增脚本/TSCN/JSON 中的汉字。添加新汉字时记得重新生成子集。

## 验证证据（暂停前最后一轮）

以下三组均实际运行，无 `ERROR`，合计 **95 项 PASS**：

| 测试 | 结果 | 覆盖范围 |
| --- | --- | --- |
| `scripts/smoke_test.gd` | 19/19 | 原流程、单次攻击不重复扣血、闪避、检查点、死亡/重试、暂停计时、通关保存 |
| `scripts/scene_test.gd` | 22/22 | 未进入场景树前已存在角色贴图/UI；原生按钮；UI 布局保留；场景出生点；血条/预警；Boss 与清理 |
| `scripts/extensions_test.gd` | 54/54 | Claude 模块的时间窗、冷却、资源、重击、胜利优先、一次性歇脚和义气快照 |

场景检查最初在旧版单节点工程上出现 4 项预期失败，再迁移至通过。

- Headless 导入已成功，最后一次导入日志无 ERROR/WARNING。
- `git diff --check` 通过；但它不检查未跟踪文件的全部内容，不要把它等同完整代码检查。
- **实际桌面运行确认**：新版菜单、HUD、角色和扩展状态能显示；Enter 可以进入教学。已看过运行画面。
- **未最终确认**：没有成功观察到 Godot 编辑器 2D 视图中的节点场景截图。启动了编辑器命令但窗口选择出现应用实例定位问题；自动场景检查证明节点和贴图已序列化，不能代替实际编辑器验收。
- **未实际通关新版**，K/L/E 目前主要是模块和集成接线检查，尚需手动试玩。
- **新版尚未 Web 导出**。`builds/web/` 仍可能是旧版，不能拿旧网页当新版完成证据。

测试命令（在仓库根目录）：

```sh
GODOT=/Users/wuyuetian/Applications/Godot.app/Contents/MacOS/Godot
"$GODOT" --headless --path godot --script scripts/smoke_test.gd
"$GODOT" --headless --path godot --script scripts/scene_test.gd
"$GODOT" --headless --path godot --script scripts/extensions_test.gd
```

这次实际测试用的引擎也可在 `/tmp/guangong-godot/Godot.app/Contents/MacOS/Godot` 找到，但 `/tmp` 路径不保证长久保留。正式应用已存在于上面的用户 Applications 目录。

测试存档分别在 `/tmp/guangong-test-progress.cfg` 和 `/tmp/guangong-scene-test-progress.cfg`；不要清除玩家自己的 `user://progress.cfg`。用户真实存档中已有 840 分记录，保留。

## 下一次优先处理

1. **先做最终审查和已知表现问题，再继续加内容。** 当前仍是整合中版本。
2. 检查暂停时 AnimatedSprite2D 是否继续播放。现在游戏只自定义暂停逻辑，尚未显式冻结独立动画播放；代码审查提示此处可能回退了旧版的暂停表现。补相应回归测试后修复。
3. 检查场景节点编辑是否真正影响玩法：旗标阈值 430、训练靶 x=650、茶摊 `REST_X=2060` 与地面 y=440 仍有硬编码。挪动这些美术节点不一定会同步改变逻辑位置。
4. `level_view.gd` 将敌人列表依次映射到前几个 guard_views；第二波虽读取了第二波的出生 x，却可能复用了第一波的视图节点。需考虑按实际场景实例绑定，才能完整保留每个守军的独立外观/变换。
5. 检查 K/L/E 在真实主循环中的组合、重击与 J/Space 的衔接、Boss 双阶段与重试。现有 54 项是独立模块测试，并不代表所有整合边界已覆盖。
6. 用 Godot 打开 `godot/scenes/main.tscn`，选 2D；确认背景/角色/HUD 可见且能选中。角色与 UI 可分别打开各自 TSCN。别仅用 @tool 预览代替真实节点。
7. 继续检查动画脚底/武器裁切、两种朝向、暂停/对白时的动作；至少实际玩通一次。
8. 更新 README、godot/README.md、assets/SOURCES.md 与新玩法文档。部分说明仍写着“无逐帧动画”等旧状态，需要按实际结果改。
9. 重新导出并在 Chrome 验证新版；Safari 尚未验证。

导出和本地启动：

```sh
"$GODOT" --headless --path godot --export-release Web ../builds/web/index.html
python3 tools/serve_demo.py
```

`play-web.command` 也会启动本地服务；地址 `http://127.0.0.1:8765/`，只供本机访问。先确认导出是新版。

## Claude 协作记录

- 实现模型确认是 `claude-opus-5-5`，effort high。
- 实现 session：`10eb87f9-485a-4e80-9e83-eccf4f47317c`。
- 完整实现任务、结果：`builds/claude/feature-task.md`、`features.jsonl`；该目录被 builds 忽略规则排除，不会自动进入 Git。
- 又启动了一个只读 Claude 最终审查，任务在 `builds/claude/review-task.md`，结果目标 `review.json`、stderr `review.stderr`。暂停前检查结果文件仍为空，**审查未交付，不能当作已通过**；已请求中止该进程。下次先检查是否已有结果或重新发起审查。
- 协作使用 CLI `claude -p --model claude-opus-5-5 --effort high`；仅授权所需工具和文件范围，不需要全局跳过权限。不要读取/输出凭据。

## Git 与本次边界

当前在 `main`，未新建 worktree，原因是用户要求继续修改已打开的本地 demo，且已有未提交/未跟踪工程文件。保留全部现场。

暂停前 `git status --short` 包括：旧根目录 spec 删除、README 修改，以及 `.gitignore`、`docs/design/`、`docs/superpowers/`、`godot/`、`play-web.command`、`tools/` 等未跟踪项。这些并非全是本次新增，不要一把清理或未经复核整体提交。

最初完整关卡方案仍在 `docs/design/chapter-01-godot-spec.md`；新增玩法是用户明确授权的扩展，不要因偏离原 spec 自动回滚。
