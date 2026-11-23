# Demo 使用的素材

下表为从仓库素材库复制到工程的 PNG，源文件保留。角色使用最近邻采样，按帧调整脚底基线。

| 工程文件 | 素材库来源（相对仓库根目录） |
| --- | --- |
| dongling.png | assets/art/chapters/01-dongling-pass/backgrounds/environment-only.png |
| guan-yu.png | assets/art/shared/characters/guan-yu.png |
| guard.png | assets/art/shared/characters/checkpoint-guard.png |
| kong-xiu.png | assets/art/chapters/01-dongling-pass/characters/kong-xiu.png |
| carriage.png | assets/art/shared/vehicles/carriage-occupied.png |
| red-hare.png | assets/art/shared/animals/red-hare.png |
| tea-set.png | assets/art/chapters/03-sishui-pass/props/tea-cup-and-tableware.png |
| green-dragon-blade.png | assets/art/shared/weapons/green-dragon-blade.png |

鼠标光标复用青龙偃月刀原图。在 GameUI 场景中逆时针旋转 90 度、缩放为 0.65 倍并对齐刀尖，采用最近邻采样。刀尖朝左上，刀刃朝左下。

背景是完整概念场景，原型仅做少量水平平移，地面纹理取同图的一块区域。尚不是可无缝展开的多层关卡美术。角色图集 `animations/guan-yu-sheet.png`、`animations/guard-sheet.png`、`animations/kong-xiu-sheet.png` 由图像模型参考对应的素材库立绘生成。图集为 1774×887，按 4×2 切片。走路用四帧，攻击用三帧，其余姿态复用图集帧。偃月斩复用关羽攻击帧，刀光、粒子和闪避残影由程序绘制。

`demo-font.ttf` 是 Noto Sans SC Regular 的字符子集，来源于 [Google Fonts](https://github.com/google/fonts/tree/main/ofl/notosanssc)，遵循同目录 `FONT-LICENSE.txt` 中的 SIL Open Font License。修改/添加中文文本后需重新生成字符子集。界面精简版已补齐运行字形；从完整可变字体实例化为 Regular 400 后再取子集，保持原有常规字重。

音效由程序生成短音，未使用外部音频。故事文本见 `data/story.json`，均为原型草稿，尚无配音或文本组审定版本。

## 千里寻兄开篇

六幕当前使用统一透视光照的完整像素连环画（`prologue/frames-v2/`）与 ElevenLabs 中文旁白，见 [开篇来源](prologue/SOURCES.md)。首版背景、道具和人物素材保留为迭代记录，源素材库保持不变。

## 五关旅图

完整卷轴山水图、地标、队伍复用、纸张声音与生成提示记录见 [旅图素材来源](journey-map/SOURCES.md)。地图文字、节点、路线与印章使用真实 Godot 节点；源素材库未修改。
