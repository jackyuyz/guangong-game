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

原完整概念背景保留；当前东岭关使用可编辑分层场景、连续水平道路与独立终点关口。原图复制、三张派生纹理、完整提示与来源见 [东岭关分层素材](dongling-layers/SOURCES.md)。角色图集 `animations/guan-yu-sheet.png`、`animations/guard-sheet.png`、`animations/kong-xiu-sheet.png` 由图像模型参考对应的素材库立绘生成。图集为 1774×887，按 4×2 切片。走路用四帧，攻击用三帧，其余姿态复用图集帧。偃月斩复用关羽攻击帧，刀光、粒子和闪避残影由程序绘制。

`demo-font.ttf` 是 Noto Sans SC Regular 的字符子集，来源于 [Google Fonts](https://github.com/google/fonts/tree/main/ofl/notosanssc)，遵循同目录 `FONT-LICENSE.txt` 中的 SIL Open Font License。修改/添加中文文本后需重新生成字符子集。界面精简版已补齐运行字形；从完整可变字体实例化为 Regular 400 后再取子集，保持原有常规字重。

音效由程序生成短音，未使用外部音频。故事文本见 `data/story.json`，均为原型草稿，尚无配音或文本组审定版本。

## 孔秀登场前对白

孔秀登场前的双人对白复用 `animations/guan-yu-sheet.png` 与 `animations/kong-xiu-sheet.png` 首个idle帧；原生AtlasTexture裁取，最近邻采样、共享透明边缘材质，未增加生成素材或独立口型帧。布局见 `scenes/ui/duel_dialogue.tscn`。

## 千里寻兄开篇

六幕当前使用统一透视光照的完整像素连环画（`prologue/frames-v2/`）与 ElevenLabs 中文旁白，见 [开篇来源](prologue/SOURCES.md)。首版背景、道具和人物素材保留为迭代记录，源素材库保持不变。

## 五关旅图

完整卷轴山水图、地标、队伍复用、纸张声音与生成提示记录见 [旅图素材来源](journey-map/SOURCES.md)。地图文字、节点、路线与印章使用真实 Godot 节点；源素材库未修改。

## 赤兔征途首页

独立背景、透明书法标题、金色笔触、首页书法字体及短音来源见 [首页素材说明](main-menu/SOURCES.md)。采用用户选中的第 4 张概念图；原关卡背景与素材库保留。

## 最后一击收尾动画（2026-11-24）

新增 `animations/guan-yu-recover-sheet.png` 与 `animations/kong-xiu-fall-sheet.png`，由 OpenAI imagegen 参考原对应图集生成；原图集和素材库均保留。两张均为透明1774×887、4×2图集，新增独立八帧收招与八帧踉跄／侧倒，使用最近邻及原透明边缘材质。完整提示和参考文件见 `animations/final-strike-creation.json`，生成记录不进入Web包。没有引入外部下载素材；生成素材沿用本课程项目的使用范围，不声称其为历史复原。

角色场景中的AtlasTexture保存各帧接地基线：孔秀前四帧407、后四帧400；关羽前四帧401、后四帧395。运行时对齐原脚底393／408；不修改PNG，不旋转站立图冒充倒地。普通斩与偃月斩的攻击尾段保持伸刀帧，再接独立收招；原idle／hurt等复用情况保持。
