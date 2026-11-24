# 东岭关分层素材

2026-11-24。沿用项目原有像素绘制质感、晨光与配色；源素材库、`assets/dongling.png` 和人物图集不覆盖、不删除。

| 运行文件 | 来源与用途 |
| --- | --- |
| `gate.png` | 原样复制 `assets/art/chapters/01-dongling-pass/architecture/dongling-gate.png`，仅终点关口使用一次。 |
| `wall.png` | 原样复制同目录 `wall-section.png`，终点两侧世界固定墙段。 |
| `tree.png` | 原样复制 `assets/art/chapters/01-dongling-pass/environment/tree.png`，路肩树木。 |
| `mountains.png` | 内置image_gen参考原 `godot/assets/dongling.png` 派生远山林海；2172×724，不含建筑和近景障碍。 |
| `road.png` | 内置image_gen参考原背景与素材库 `environment/mountain-path.png` 派生水平土路；2172×724，镜像重复，原生着色器仅柔化后沿。 |
| `roadside.png` | 内置image_gen参考素材库 `environment/rocks.png` 派生低矮草石；2172×724，真实Alpha，分别用于后路肩与前景。 |

前三项字节与原件一致，原始来源遵循素材库已有记录。后三项为本项目生成派生图，不宣称逐像素复刻或手工绘制。完整提示、输入和未采用的城门尝试见 `creation.json`，生成采用内置工具。原城门已含有效Alpha，部分看图器显示透明像素隐藏RGB会看似有底色，最终直接复用原件。

所有素材由真实Sprite2D节点引用、最近邻采样；布局与比例在 `scenes/levels/dongling_pass.tscn`。来源与生成记录排除出运行导出包，源PNG及导入配置保留在Git范围内。
