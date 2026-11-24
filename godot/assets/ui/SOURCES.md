# 武侠设置页素材

- `wuxia-panel.png`：内置 image_gen 参照已选设置样板生成的无字墨绿绢面／旧金角饰。完整提示、参考与返回信息见 `panel-creation.json`。Atlas 裁掉外围透明边；未覆盖源图。
- `wuxia-primary-brush.png`：同工具按设置样板生成的无字旧金笔刷，透明背景；完整记录见 `primary-brush-creation.json`。
- 细线与悬停薄刷复用 `../main-menu/menu-brush.png`；声音复用该目录原创 `hover.wav`、`confirm.wav`，设置页播放音量分别 -12／-10 dB，保持 75 ms 去重。
- `wuxia-brush-font.ttf`（上一版保留，当前界面不使用）：Google Fonts Ma Shan Zheng Regular 400 派生字符子集，字体族改名 Guangong Wuxia Brush。覆盖“设置声音开关减少动态操作指南完成”；许可见 `FONT-LICENSE-BRUSH.txt`。来源：https://github.com/google/fonts/tree/main/ofl/mashanzheng 。
- `wuxia-reading-font.ttf`：Google Fonts Noto Serif SC，变量字体固定到 400 后派生字符子集，字体族改名 Guangong Wuxia Reading。覆盖全游戏运行文字与符号，制作人员页接入后共 422 个汉字；许可见 `FONT-LICENSE-READING.txt`。来源：https://github.com/google/fonts/tree/main/ofl/notoserifsc 。
- 字体子集使用 fontTools subset，保留现有字体全局回退。新增文案须检查 cmap 并从官方原字体重建，不可仅追加文字而不检查字形；更改字体族时同步 name 表。原字体下载仅保存在本机临时目录，不作为运行依赖。
- 运行文案全部为原生 Label／Button，未烘焙在图片中。生成记录、来源说明与测试夹具排除出游戏导出，许可文件保留。

- 当前短标题／按钮使用 `wuxia-kai.otf`，为 FandolKai Regular 原始 OTF，字节未修改。上游为 Fandol team（Clerk Ma、Jie Su），来源：[CTAN 原包](https://ctan.org/tex-archive/fonts/fandol)，本机下载自 CTAN MIT 镜像的 `fonts/fandol/FandolKai-Regular.otf`。完整 GPL 与字体嵌入例外见 `FONT-LICENSE-KAI.txt`，上游原说明保留为 `FANDOL-README.txt`；运行分发保留字体版权与许可。没有使用系统商业楷体或从效果图假称提取出旧字体。
- `tools/build_ui_reading_font.py /path/to/NotoSerifSC.ttf` 可重建宋体子集，扫描 scenes／scripts／data，固定 400 字重并改字体族名。当前实际运行汉字在两套字体中都无缺字；后续新增文字继续检查。
- `themes/wuxia-game.tres` 的绢面、旧金刷与淡金刷复用上文资源；文化页暖纸直接使用旅图底图右侧空白部分的 AtlasTexture（1280,230,250,490），未另存、覆盖或修改原画。首页飞白标识、背景与连环画内文字均不改。

- 按用户确认的较厚字重，所有楷书展示角色统一引用 `themes/wuxia-display-font.tres`，Godot FontVariation 的 `variation_embolden=0.45` 仅调整运行渲染，不改字体文件，不加粗描边。正文／字幕／数字与键帽的宋体 400 不变。方法依据 [Godot FontVariation 官方说明](https://docs.godotengine.org/en/stable/classes/class_fontvariation.html)。

- `cinnabar-seal-frame.png`：通过内置 image_gen 按本轮通关印记需求生成的透明朱红印泥章框，1254×1254 RGBA，中心透明。完整提示、输出来源与用途见 `seal-creation.json`。结算页以真实 TextureRect 加可编辑楷书“过”字组合，表示单关通过；不代表整个游戏完结，不使用生成字形替代交互文字。
