# Demo 使用的素材

下表为从仓库素材库复制到工程的 PNG，源文件保留。角色使用最近邻采样，按帧调整脚底基线。

关羽新增倒地与孔秀新增收枪：`animations/guan-yu-fall-sheet.png`、`animations/kong-xiu-recover-sheet.png`，由OpenAI imagegen参考原对应角色图集派生，原图不改。均为1774×887透明PNG、4×2浮点切片；运行时最近邻、原透明边缘材质。`animations/player-defeat-creation.json`记录完整提示、废弃初稿原因及用户指出第6帧后的修正，导出排除该记录。没有新增外部下载素材或配音。

倒地第6帧为向侧卧过渡的承重姿态，长刀降至地面，未旋转站立图代替新姿势。关羽逐帧接地基线411／411／411／412／388／393／395／395，对齐原393；孔秀收枪前四帧408、后四帧410，对齐原408。基线存入真实角色场景的AtlasTexture元数据，两种方向均校准。

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

## 攻击范围表现（2026-11-26）

关羽刀弧在原程序绘制基础上增加内侧金光、细白亮锋与短流光；敌方地面箭形／弧带为真实Polygon2D、Line2D节点。没有新增生成图、外部下载、音频或人物动作素材，原图集与角色场景未改。实现与验证见[攻击范围表现规格](../../docs/design/attack-range-effects-spec.md)。

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

## 起步教学器具（2026-11-24）

`training-props/training-waymark.png`（1254×1254）与`training-props/training-post-states.png`（2172×724）为内置OpenAI imagegen新生成透明派生素材，参考原关羽图集的像素风格、素材库`assets/art/chapters/01-dongling-pass/environment/military-banner.png`的木／布材质；原素材未覆盖或删除。练刀桩含完整、斜裂、断落三个状态，不是连续破碎动画；首次草束图有背景残留，使用imagegen清理后的版本接入。保留生成透明度，复用原cutout材质；Atlas裁取和逐状态锚点见`scenes/levels/training_dummy.tscn`及[教学器具规格](../../docs/design/training-props-spec.md)。完整原始提示、清理提示及参考路径见`training-props/creation.json`，该记录排除Web包。没有新增外部下载素材，沿用课程项目使用范围，不声称为历史复原。

## 战斗玉牌头像（2026-11-24）

HUD头像复用`animations/guan-yu-sheet.png`首帧，AtlasTexture取(180,122,144,180)头肩区域，保留原绿巾、红脸、长须和朝右姿态。真实TextureRect配`portrait_cutout.gdshader`圆形及透明边缘遮罩，最近邻采样；保留原玉牌背景，不新增生成图、不覆盖原PNG，来源与原角色素材一致。

## 道旁茶歇（2026-11-25）

一体木桌、青瓷壶碗、低凳与水篮的透明像素图由内置OpenAI imagegen生成，原样复制；短饮茶提示音为本项目程序合成。素材、完整提示及来源见[茶歇素材说明](tea-rest/SOURCES.md)。蒸汽／阴影／交互是独立真实节点，恢复轮廓和光点由短暂表现层驱动；原tea-set和素材库保留。

## 项目图标（2026-11-25）

朱砂红底、米白简体“关”字图标由内置OpenAI imagegen生成，设置为项目`application/config/icon`，Web导出同步favicon及Apple触屏图标。原图、完整提示与使用范围见[品牌图标来源](branding/SOURCES.md)。原有通关章框／角色素材保留。

## 制作团队默认字体补字（2026-11-25）

`demo-font.ttf`继续使用上述官方Noto Sans SC Regular 400，保留旧版全部540个码点及对应轮廓／水平指标，补齐制作团队新文案后共555个码点。字体族、版权及SIL Open Font License保持；实际制作团队正文仍使用宋体，默认字体补齐用于全局回退。
