# 千里寻兄 · 开篇素材

制作日期：2026-11-22。本片为《三国演义》文学改编，字幕为本项目现代中文改写。

## 当前六幕完整构图（v2）

用户反馈首版人物和道具像独立贴图后，使用内置 image_gen 重新制作六张 1983×793 完整像素连环画。人物、信纸、灯盏、印信、赏赐与环境一起绘制，统一透视、光照、比例和接触阴影。四、五幕另做定向编辑：辞曹幕室内留空避免误解为抛下夫人，挂印改为红绶方印；护送幕移除提前出现的关门，改为林间山路。

| 运行文件 | 场面与融合方式 | 最终原始生成文件 |
| --- | --- | --- |
| `frames-v2/01-separation.png` | 战乱城池与断开的山路，前景关羽、远处刘备 | `exec-b310abc9-df35-4e23-b28d-cf29c468e4c5.png` |
| `frames-v2/02-promise.png` | 门外守护与室内二夫人同一庭院透视 | `exec-651cb145-6148-41c0-ae3d-474e3657b3da.png` |
| `frames-v2/03-letter.png` | 手持信纸落在案前，灯、砚、人物共同受光 | `exec-51d9a1ff-69dc-47e0-ae2a-66962bfad6f1.png` |
| `frames-v2/04-farewell.png` | 案上封存赏赐、门柱挂印、门外辞行 | `exec-9cf1c4be-2de5-4dd8-9b47-8ad051cc306f.png` |
| `frames-v2/05-escort.png` | 林间路上的关羽、车马、二夫人与落地阴影 | `exec-8fb45101-21c9-4e10-aa32-a015cbb3cce2.png` |
| `frames-v2/06-dongling.png` | 护送队伍停在关闭的东岭关前 | `exec-7cc4cac6-666b-47c2-822d-5deaa5b2aa90.png` |

完整提示词、编辑提示和草稿来源见 [creation.json](frames-v2/creation.json)。原始输出保留在下文的本机生成目录，工程内为原文件复制，无程序修图。当前 TSCN 使用这些完整构图与最近邻采样，镜头轻推近 1.5%，转场 0.45 秒。旧版素材保留，以下记录为首轮制作历史。

## 首版新增图片

通过内置 image_gen 工具生成；未覆盖素材库原图。下表记录生成提示的摘要。原始生成图保留在本机 Codex generated_images 目录，工程中的 PNG 为原文件复制。透明图集通过 Godot AtlasTexture 分区使用，未修改原图像素。

| 文件 | 提示摘要与用途 | 原始生成文件 |
| --- | --- | --- |
| `separation.png` | 16:9 古代山路岔口、徐州战乱远城、冷灰山峦烟尘、破旗；无人物无文字，留出前景放像素人物 | `exec-e3b28860-563d-4302-b266-69a2df6bcc94.png` |
| `cao-residence.png` | 汉末宅院，左侧暖灯室内及空案，右侧冷月庭院与营门；无人物、书信和文字 | `exec-fb0fc911-029e-4f22-b175-d0bbbcaf2135.png` |
| `story-props.png` | 透明 2×2 道具表：红绳信件、空白卷轴、红绶铜印、绿布包裹金锭；每格 627×627 | `exec-a10f0a46-1bf8-484b-9589-836c0a35ebff.png` |
| `liu-bei.png` | 单人透明像素风汉末文武人物，长袍、冠、双剑，面朝左，供远景冷色剪影使用 | `exec-6525ff60-c559-4f99-b693-c7ed4e1665d5.png` |

原始生成目录：`/Users/yuyuanzhengjack/.codex/generated_images/01a1ef8d-02f7-7213-8d96-1388e2885ef6/`。人物保持最近邻采样；背景采用完整宽画幅，六幕的布局和动画轨道保存于 `scenes/ui/prologue.tscn`。

## 首版复用图片

- `lady-gan.png`、`lady-mi.png` 分别复制自仓库 `assets/art/shared/characters/` 的同名文件。
- `empty-carriage.png` 复制自仓库 `assets/art/shared/vehicles/carriage.png`，护送幕先呈现空车，再淡入已乘车版本，避免同时出现两组夫人。
- 关羽、马车、赤兔与东岭关背景复用 `godot/assets/` 已选素材，来源仍见上一级 [SOURCES.md](../SOURCES.md)。

## 六幕中文旁白

由用户认可的试音音色继续制作：ElevenLabs **Mr. Chen - Trustworthy Chinese Narrator**，voice ID `cwzmKSYMCC9Aym1ymCnt`，模型 `eleven_v4`，语言 `zh`，输出 `mp3_44100_128`。每幕均使用同一音色，辅以已试用的 `[elderly voice]` 及温和／严肃／坚定表演标记。角色承诺由同一说书人代言。

| 成品 | 实际时长 | 画面停留 |
| --- | --- | --- |
| `audio/zh-CN/01-separation.mp3` | 5.06 秒 | 7 秒 |
| `audio/zh-CN/02-promise.mp3` | 8.32 秒 | 10 秒 |
| `audio/zh-CN/03-letter.mp3` | 4.48 秒 | 7 秒 |
| `audio/zh-CN/04-farewell.mp3` | 8.16 秒 | 9 秒 |
| `audio/zh-CN/05-escort.mp3` | 4.40 秒 | 8 秒 |
| `audio/zh-CN/06-dongling.mp3` | 8.08 秒 | 10 秒 |

旁白合计 38.50 秒，留白及转场后自动播放约 51 秒，末幕等待确认。台词、控制标记、音色、模型、哈希和实际时长记录于 [voice-manifest.json](voice-manifest.json)。原始生成记录和已批准试音保存在忽略目录 `builds/audio/prologue/zh-CN/`。生成工具只从仓库根目录 `.env` 读取 Key，voice ID 为命令参数；游戏不调用 API。

首幕录音原本重复说了两次“话说”。按用户反馈，2026-11-22 用本地 ffmpeg 去掉前 1.10 秒，在两遍之间的静音处起剪并加 5 ms 淡入；保留第二遍与其余全文。原始 6.16 秒录音保留于忽略目录 `builds/audio/prologue/zh-CN/first-scene-edit/01-separation-original.mp3`，运行成品改为 5.06 秒；第一幕停留仍为 7 秒，总流程仍为 51 秒。使用临时安装的本地 mlx-whisper/base 核对剪前两遍、剪后一遍，识别正文其余部分不变；不以自动转写替代人名发音审听。剪点、原／成品哈希与工具记录在 manifest；未重新生成配音、未上传音频。

## 原创合成音效与字体

`audio/wind.wav`、`paper.wav`、`seal.wav`、`wheels.wav`、`gate.wav` 为确定性噪声和衰减振荡合成的轻环境声与拟音，不是实地录音；生成源为 `tools/generate_prologue_foley.py`。风声循环，其余每幕触发一次；统一服从静音与暂停。

`../demo-font.ttf` 使用官方 Google Fonts Noto Sans SC 可变字体的 400 字重重建子集，保留原工程字形并补开篇所需文字。许可证沿用 `../FONT-LICENSE.txt`（SIL OFL）。源文件来自 Google Fonts `ofl/notosanssc/NotoSansSC[wght].ttf`。
