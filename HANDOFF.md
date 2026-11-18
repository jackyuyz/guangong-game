# 关公游戏交接 · 2026-11-18

## 当前状态

东岭关是可玩的课程 demo。Godot 4.7.2 工程位于 `godot/project.godot`，主场景是 `godot/scenes/main.tscn`，使用 GDScript 和 Compatibility 渲染器。新版已本地导出并在 Chrome 从开场打到结算。Web 成品在忽略目录 `builds/web/`，仅供本机试玩。最新改动在本地工作区，尚未提交。

## 本轮完成

- 地面、站位和互动节点归到关卡的 `Ground` 下。可移动旗标、训练靶、茶摊和关门标记来调整玩法位置。调地面高度时，角色、道具、触发点及命中特效随之对齐。移动范围取自地面边缘和 `ArenaLeft` 标记；重试位置取自 `WaveRetrySpawn` 和 `BossPlayerSpawn`。
- 两波守军的战斗数据与各自场景实例绑定。击倒一名守军后，其他守军保留各自的外观、变换和动画。
- 暂停、失焦、对白和失败期间停止战斗，动画可在暂停后从原帧续播。暂停时音效也停止播放并可续播。命中顿帧暂停角色动画。
- K 弹反把硬直施加给实际出招者。L 成功出招会取消 J 剩下的判定，播放独立重击动作和刀光，短暂锁定其他战斗动作；致命重击进入结尾时清除动作与刀光。第二阵清完后可用 E 在茶摊补血和补满义气，Boss 重试恢复入场时的义气。
- 茶摊绘制在角色后方，震屏移到相机，退让守军转身并隐藏血条。修正返回菜单时的场景复位、文化卡和退出确认的键盘处理，并将对白及重试按钮中的缺字回车符换成 `ENTER`。

## 验证

- Godot 4.7.2 导入和 Web 导出完成，日志无错误或警告。三组无头测试共 **112 项**通过（玩法 26、场景 32、扩展 54）。`git diff --check` 通过。
- 实际打开了 Godot 的主场景和东岭关场景的 2D 视图。主场景可见背景、角色和 HUD。单独打开关卡后，选中 `Ground` 并确认 Inspector 显示该节点。
- Chrome 用键鼠完成教程、两波守军、茶摊、孔秀两个阶段、文化卡和结算。单独走了一次 Boss 失败与检查点重试，恢复血量、战斗计时和满义气，结算显示 800 分、重试 1 次。最新重新导出的版本再次通关，结算 880 分、18 秒战斗、剩 3 格血、重试 0 次。浏览器试玩使用 8766 端口隔离存档，正常试玩端口为 8765。
- 精准弹反与偃月斩致命一击的表现复位有自动检查。Chrome 中已操作 K 并看到架刀状态。逐帧武器裁切、完美弹反手感、Safari 和移动端仍待进一步验收。
- 测试与浏览器试玩使用隔离存档。不要用真实玩家的 `user://progress.cfg` 验证。

## 本机运行

同事照着安装并在编辑器里试玩的步骤在 [本地 Godot 运行](docs/local-godot.md)。下面是本机核对用的命令。

在仓库根目录执行：

```sh
GODOT="$HOME/Applications/Godot.app/Contents/MacOS/Godot"
"$GODOT" --headless --path godot --editor --import --quit
"$GODOT" --headless --path godot --script scripts/smoke_test.gd
"$GODOT" --headless --path godot --script scripts/scene_test.gd
"$GODOT" --headless --path godot --script scripts/extensions_test.gd
"$GODOT" --headless --path godot --export-release Web ../builds/web/index.html
python3 tools/serve_demo.py
```

双击 `play-web.command` 也可用本机包启动 [网页版](http://127.0.0.1:8765/)。重新改动源码后先重新导出。

## 后续工作与资料

- 原始关卡依据见 [东岭关设计](docs/design/chapter-01-godot-spec.md)，扩展行为见 [战斗扩展](docs/design/combat-extensions.md)。先做真人难度、动作可读性和兼容性验收，再决定下一轮内容。
- 关羽、守军和孔秀用 1774×887 的 4×2 图集，最近邻采样。走路用四帧、攻击用三帧，其他姿态复用图集帧。脚底按帧对齐，背景是随相机平移的单张概念图。素材和字体来源见 [素材说明](godot/assets/SOURCES.md)。新增汉字后检查并更新字体子集。
- 教学闪避目前只要求触发动作。城门开启用目标文字、守军退让和对白表达。正式文本组内容、配音、题库、多语言、其他四关和文化网站尚未交付。
- 11 月 16 日的 Claude Opus 5.5 high 扩展实现与只读审查都已交付。审查在 `builds/claude/review.json`，只读审查早于本轮修复。生成图集和早期接线背景见 Git 中的上一版交接。仓库约定见 [AGENTS.md](AGENTS.md)，改动记录见 [task.md](task.md)。
