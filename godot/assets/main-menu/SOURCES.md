# 首页素材与制作来源

2026-11-23：采用用户选中的五张候选中的第 4 张「赤兔征途」首页。设计原图保留于 `docs/art/main-menu-reference-04.png`；没有修改素材库源文件。

- `rider-dawn.png`：内置 image_gen 编辑选中的概念图，移除所有文字与菜单，保留关羽、赤兔、青龙偃月刀、雄关与曙光。完整提示、原输出及参考路径见 `background-creation.json`。
- `title-calligraphy.png`：内置 image_gen 参考同图生成透明书法「关公」，作为独立 TextureRect；不是可编辑文字。生成记录见 `title-creation.json`。
- `menu-brush.png`：内置 image_gen 生成透明旧金笔触；使用 AtlasTexture 的 Rect2(120,270,1940,180) 保留原图、避开透明留白。下划线与悬停背景共用，记录见 `brush-creation.json`。
- `menu-brush-font.ttf`：由 [Google Fonts 的 Ma Shan Zheng](https://github.com/google/fonts/tree/main/ofl/mashanzheng) 取首页用字子集（Regular 400），派生字体名 Guangong Menu Brush；[上游许可](https://github.com/googlefonts/mashanzheng/blob/master/OFL.txt) 为 SIL OFL 1.1，完整文本在 `FONT-LICENSE.txt`。缺少的间隔点 `·` 经 FontVariation 回退现有 Noto Sans SC；全部中文菜单字均在新字体内。仅首页使用该字体，正文仍沿用原字体。
- `hover.wav` / `confirm.wav`：本项目用 `tools/generate_menu_sounds.py` 原创合成的短拨弦音（95 / 160 ms，44.1 kHz 单声道 PCM16），没有外部录音或服务。悬停 -12 dB、确认 -10 dB；遵循全局静音及失焦，75 ms 防重复触发。

背景、标题、按钮及笔触都由 TSCN 原生节点呈现；菜单文案与点击仍为真实 Button，不把整张概念图当作静态交互界面。创建记录只作开发追溯，Web 导出不包含这些 JSON 与本说明。
