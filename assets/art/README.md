# Guan Gong · HD-2D 开发素材

素材来自已选定的实验 06。开发用 PNG 位于 `assets/art/`。索引中的 `path` 和 `variant_of` 均相对于仓库根目录，`source` 相对于原美术项目的 `guangong_assets_06/`。索引记录每张图的尺寸、透明度和 SHA-256。 [素材索引](catalog.json)

| 目录 | 素材 |
| --- | --- |
| `shared/` | 关羽、受伤关羽、甘夫人、糜夫人、守关士兵、赤兔、空车、载客马车和青龙偃月刀 |
| `chapters/01-dongling-pass/` | 第一关 · 东岭关 |
| `chapters/02-luoyang/` | 第二关 · 洛阳 |
| `chapters/03-sishui-pass/` | 第三关 · 汜水关 |
| `chapters/04-xingyang/` | 第四关 · 荥阳 |
| `chapters/05-yellow-river/` | 第五关 · 黄河渡口 |

各关的 `backgrounds/` 提供已有的无角色背景，可在其上单独放置角色和物件。`scenes/` 收录完整的构图，可用于分镜或整幅画面。`effects/` 收录透明的火烟和晨雾。其余 PNG 按角色、动物、武器、车辆、道具、建筑和环境存放。

东岭关现有的像素工作图为 96 × 96。导入像素图时使用最近邻采样，可保持边缘清晰。第二至第五关的新像素图保留原交付尺寸，受伤关羽也使用原尺寸。现有图像为静态美术，角色帧、锚点和碰撞信息需要在接入引擎时定义。

`docs/art/` 收录各关展示图、东岭关 12 倍像素预览和五关总览，用于查阅画风和构图。 [五关总览](../../docs/art/five-passes-overview.png)
