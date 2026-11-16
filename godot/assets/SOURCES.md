# Demo 使用的素材

所有 PNG 均原样复制自仓库素材库，保留原图；运行时读取 alpha 边界，统一脚底锚点，并使用最近邻采样。

| 工程文件 | 素材库来源（相对仓库根目录） |
| --- | --- |
| dongling.png | assets/art/chapters/01-dongling-pass/backgrounds/environment-only.png |
| guan-yu.png | assets/art/shared/characters/guan-yu.png |
| guard.png | assets/art/shared/characters/checkpoint-guard.png |
| kong-xiu.png | assets/art/chapters/01-dongling-pass/characters/kong-xiu.png |
| carriage.png | assets/art/shared/vehicles/carriage-occupied.png |
| red-hare.png | assets/art/shared/animals/red-hare.png |

背景是完整概念场景，原型仅做少量水平平移，地面纹理取同图的一块区域。尚不是可无缝展开的多层关卡美术。人物为静态像素立绘，动作使用程序位移、摇摆、倾斜、残影及刀光，尚无逐帧动作。

`demo-font.ttf` 是 Noto Sans SC Regular 的字符子集，来源于 [Google Fonts](https://github.com/google/fonts/tree/main/ofl/notosanssc)，遵循同目录 `FONT-LICENSE.txt` 中的 SIL Open Font License。修改/添加中文文本后需重新生成字符子集。

音效由程序生成短音，未使用外部音频。故事文本见 `data/story.json`，均为原型草稿，尚无配音或文本组审定版本。
