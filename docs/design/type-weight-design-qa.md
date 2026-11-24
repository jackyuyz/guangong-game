> 历史：楷书字重调整验收。当前UI收尾见根design-qa.md。

# 武侠界面中等字重验收

日期：2026-11-23。范围：将现有楷书标题、按钮、设置项调整为用户认可的较厚方向。未提交、推送或公开发布。

## 结果与证据

- 原始依据为 `docs/art/wuxia-sharp-font-reference.png`，属于生成概念图；用户明确喜欢其中较厚且有笔锋的字。原生 Godot 比较 0／0.4／0.7／1.0／1.3 五档，选择 0.45。0.7 以上的密字逐渐拥挤，0.45 保留字内留白和尖收笔；不宣称字形完全还原生成稿。
- 新增 `themes/wuxia-display-font.tres`，所有原楷书引用统一接入；原字体、宋体正文／字幕／数字／键帽和美术图片未修改。没有修改布局、交互逻辑或存档规则，没有使用描边加粗。
- 原生 1280×720，逐页与异常状态在 `builds/previews/type-weight/native-*.png`，已查看 `overview.png`。文化正文仍为 5 行／最小147px／可用220px；六幕字幕仍为1／2／1／2／1／2行，最大70px／可用79px。未发现标题、较长按钮或地图关卡名裁切。
- 原生 `reference-vs-implemented.png` 标明左为 REFERENCE generated concept，右为 IMPLEMENTED Godot current build，统一到960×540；已实际打开对比。候选对比为 `guangong-weight-comparison.png`，不是最终运行截图。
- 编辑器2D已从磁盘重载，100%居中查看真实设置场景，确认设置、减少动态、操作指南和完成字形。
- 独立本机来源 `http://localhost:18936/?audio_debug=1`，实际查看首页、设置和指南，Tab／Enter打开指南，Escape关闭后重新打开设置。最终停留设置，声音开／减少动态关，焦点在声音开。控制台 error／warn 为空；没有使用或清除旧试玩来源的玩家进度。
- 网页真实截图 `browser-settings-final.jpg` 为1707×960，无黑边，保留整幅背景和面板；另有 `browser-home.jpg`、`browser-guide.jpg`。最终输出使用本轮网页截图，不再把概念图和游戏图混为“已实现”。

## 验证

- 186项现有隔离检查全部通过：scene42、main_menu19、settings_panel23、keyboard_guide10、journey_map45、prologue47；完整日志已读取，无错误或警告。此项可逆字体调整未新增机械重复的测试。
- Godot导入、Web导出通过；新字体资源已纳入PCK。正文及原画文件保持与本轮开始时相同；Git空白及新文本等效检查通过。
- Safari、触屏、屏幕阅读器和长时间运行不属于本轮专项验证。字体风格仍有真实字库与生成笔迹的差异，没有阻塞使用的问题。

## 完成项

- [x] 候选实际渲染与全图比较，选取中等字重。
- [x] 全游戏楷书展示角色引用单一字体资源。
- [x] 正文／字幕／美术文字保持，原生各页与编辑器检查。
- [x] 本机网页运行、键盘操作、控制台与最终截图。
- [x] Spec、来源、任务记录与交接同步。

上一轮338项全游戏迁移报告见 `docs/design/game-language-design-qa.md`，早前设置页报告见 `docs/design/settings-design-qa.md`。

final result: passed
