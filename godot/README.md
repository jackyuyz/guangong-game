# 东岭关 · 试玩工程

入口：`project.godot`，主场景 `scenes/main.tscn`。使用 Godot 4、GDScript、Compatibility 渲染器。已用 Godot 4.7.2 实际运行并导出单线程 Web。

## 运行与导出

同事在自己电脑上安装、导入并运行的步骤见 [本地 Godot 运行](../docs/local-godot.md)。

- Godot 4.7.2 导入本目录的 `project.godot`，按 F5 运行。编辑器运行不需要 Web 导出模板。
- 本机已有导出文件时，在仓库根目录执行 `python3 tools/serve_demo.py`，或双击 `play-web.command`。
- 命令行导出：`godot --headless --path godot --export-release Web ../builds/web/index.html`，需要对应版本的 Web 导出模板。
- Web 输出约 40 MB（主要为 Godot WASM）；首次加载需等待。通过 HTTP 访问，不能直接双击 HTML。当前本地地址为 `http://127.0.0.1:8765/`。
- 在仓库根目录运行 `godot --headless --path godot --script scripts/smoke_test.gd`，同样运行 `scene_test.gd`、`extensions_test.gd` 和 `prologue_test.gd`。测试使用临时存档。

## 现在能玩什么

五关卷轴选关与进度：东岭关可玩，通关后可进入洛阳完整玩法原型，后三关未开放。东岭关已有首次六幕说书前情、三步教学、两波守军、孔秀两阶段、检查点、暂停／失焦暂停、格挡／弹反（K）、偃月斩（L）、茶歇（E）、文化回顾与评分保存。

洛阳已接入像素骑乘、美术与受击反馈，跑通追孟坦、暗箭负伤、躲箭冲门、两次斩将、两段检查点及结算，宿主独立保存路线记录；佯退／回马衔接见规格第18节，最新岔口逃脱、束伤与统一车仗离关见[第19节](../docs/design/chapter-02-luoyang-spec.md#19-岔口逃脱束伤与车仗离关)。A/D或左右换道、P/Esc暂停、R重试本段、Enter跳过成功剧情；逃脱演出结束后可重追。独立免存档试玩可在仓库根运行 `python3 tools/luoyang_prototype.py --chapter`，旧三个练习不受影响；第二关尚未公开发布。

素材来源记录在 [assets/SOURCES.md](assets/SOURCES.md)，关卡故事草稿独立放在 `data/story.json`；开篇字幕、时长和音频在 `data/prologue.json`，六幕布局与轨道在 `scenes/ui/prologue.tscn`。运行构图在 `assets/prologue/frames-v2/`；原图与提示词有来源记录，源素材库未修改。Web 使用 `web/game.html` 处理音频开启；受阻时先等待，用户可开启声音或选择静音观看。

## 编辑关卡

打开 `scenes/main.tscn` 的 2D 视图可预览关卡与 HUD。在 `scenes/levels/dongling_pass.tscn` 中编辑旗标、训练靶、茶摊、角色站位和关门标记，它们的位置会用于触发和出生判定。整体抬高或降低地面时移动 `Ground`，道路、前景与角色子节点会一起移动。只有远景 `Backdrop` 随相机做20%视差，编辑器显示其初始位置；关口、墙段、树木与道路固定在世界坐标。UI 布局在 `scenes/ui/game_ui.tscn`。

## 已知边界

这是试玩原型，不代表第一关完整规格已交付。

- 关羽、守军和孔秀已有逐帧走路和攻击，待机、架刀、受击等姿态复用图集帧。偃月斩复用攻击帧并使用独立刀光。
- 当前是3000px分层横版道路：原城门／墙段／树木搭配同画风远景、水平土路与低矮植被派生图。保留原完整概念背景；没有自由上下行走、跳跃或城门开启动画。
- 闪避教学仅要求执行动作，尚无示范突刺；无教学跳过/重播入口。
- 目前仅简体中文与项目改编字幕；开篇使用同一 ElevenLabs 中文说书声，尚无战斗对白配音、英文／繁体／拼音与正式文本组内容。
- 声音开关可保存；没有独立音量滑块。东岭关保存通关及同版本最佳分数，尚无该关最佳时间；洛阳原型独立保存最快成功路线的时间与统计。
- 过关以守军淡出/退让和结尾对白表示，尚无城门开启动画。
- Chrome 已完成键鼠通关，验证茶摊、重击、暂停和结算。首版 Safari 检查过开篇与教程衔接；本轮应用内浏览器检查新版音频输出、解锁、静音观看和教程衔接，Safari 完整战斗和手机尚未试玩。
- 战斗难度、招式可读性和完成时长需要真人试玩继续调整。

[返回首页](../README.md) · [完整关卡设计](../docs/design/chapter-01-godot-spec.md)

界面当前采用按需展开：主菜单、地图与暂停页共用设置／操作指南，前情“更多”中重听本幕，结算可展开战绩。详见 [界面层级规格](../docs/design/interface-hierarchy-spec.md)。
