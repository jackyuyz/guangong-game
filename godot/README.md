# 东岭关 · 第一版试玩

入口：`project.godot`，主场景 `scenes/main.tscn`。使用 Godot 4、GDScript、Compatibility 渲染器。已用 Godot 4.7.2 实际运行并导出单线程 Web。

## 运行与导出

- Godot 编辑器导入本目录工程，按 F5 运行。
- 本机已有导出文件时，在仓库根目录执行 `python3 tools/serve_demo.py`，或双击 `play-web.command`。
- 命令行导出：`godot --headless --path godot --export-release Web ../builds/web/index.html`，需要对应版本的 Web 导出模板。
- Web 输出约 40 MB（主要为 Godot WASM）；首次加载需等待。通过 HTTP 访问，不能直接双击 HTML。当前本地地址为 `http://127.0.0.1:8765/`。
- 回归检查：`godot --headless --path godot --script scripts/smoke_test.gd`。测试存档使用 `/tmp/guangong-test-progress.cfg`，不污染玩家存档。

## 现在能玩什么

开场、三步操作教学、两波守军、孔秀两阶段战斗、Boss 检查点、清兵/孔秀重试、暂停/失焦暂停、合成音效、文化回顾、评分与本机保存。按键说明也在游戏底栏。

素材来源记录在 [assets/SOURCES.md](assets/SOURCES.md)，故事草稿独立放在 `data/story.json`。源素材库未修改。

## 已知边界

这是试玩原型，不代表第一关完整规格已交付。

- 人物为现有静态像素图，使用程序动作与刀光；缺少逐帧侧视动画。
- 背景使用无角色概念场景的轻微平移；地面纹理截取同图，尚无完整 3400px 分层地图。
- 闪避教学仅要求执行动作，尚无示范突刺；无教学跳过/重播入口。
- 目前仅简体中文和草稿字幕，无两套配音、英文/繁体/拼音与正式文本组内容。
- 声音开关可保存；没有独立音量滑块。保存通关及同版本最佳分数，尚无最佳时间记录。
- 过关以守军淡出/退让和结尾对白表示，尚无城门开启动画。
- Chrome 已确认加载、输入及暂停；Safari 和手机尚未验证。
- 战斗难度、招式可读性和完成时长需要真人试玩继续调整。

[返回首页](../README.md) · [完整关卡设计](../docs/design/chapter-01-godot-spec.md)
