# 武侠设置页素材

- `wuxia-panel.png`：内置 image_gen 参照已选设置样板生成的无字墨绿绢面／旧金角饰。完整提示、参考与返回信息见 `panel-creation.json`。Atlas 裁掉外围透明边；未覆盖源图。
- `wuxia-primary-brush.png`：同工具按设置样板生成的无字旧金笔刷，透明背景；完整记录见 `primary-brush-creation.json`。
- 细线与悬停薄刷复用 `../main-menu/menu-brush.png`；声音复用该目录原创 `hover.wav`、`confirm.wav`，设置页播放音量分别 -12／-10 dB，保持 75 ms 去重。
- `wuxia-brush-font.ttf`：Google Fonts Ma Shan Zheng Regular 400 派生字符子集，字体族改名 Guangong Wuxia Brush。覆盖“设置声音开关减少动态操作指南完成”；许可见 `FONT-LICENSE-BRUSH.txt`。来源：https://github.com/google/fonts/tree/main/ofl/mashanzheng 。
- `wuxia-reading-font.ttf`：Google Fonts Noto Serif SC，变量字体固定到 400 后派生字符子集，字体族改名 Guangong Wuxia Reading。覆盖当前保存／读取／版本错误汉字及 ›；许可见 `FONT-LICENSE-READING.txt`。来源：https://github.com/google/fonts/tree/main/ofl/notoserifsc 。
- 字体子集使用 fontTools subset，保留现有字体全局回退。新增文案须检查 cmap 并从官方原字体重建，不可仅追加文字而不检查字形；更改字体族时同步 name 表。原字体下载仅保存在本机临时目录，不作为运行依赖。
- 运行文案全部为原生 Label／Button，未烘焙在图片中。生成记录、来源说明与测试夹具排除出游戏导出，许可文件保留。
