# 洛阳三车道操作原型

- `luoyang-gatehouse.png`：原样复制自 `assets/art/chapters/02-luoyang/architecture/luoyang-gatehouse.png`，来源索引为仓库 `assets/art/catalog.json` 中实验 06 的 `chapters/chapter_02_luoyang/assets/architecture/LuoyangGatehouse.png`。原图不修改、不删除；沿用项目既有素材来源说明，不新增第三方许可声明。
- 骑乘人物、赤兔、拒马、箭、射手、山体与旗帜为本轮用 Polygon2D／Line2D 编写的原创几何占位节点，保存在 `godot/scenes/prototypes/luoyang_*.tscn`，不是已完成的角色像素动画或 AI 生成图集。`tools/build_luoyang_blockout.py` 可复建初始布局；手动调整 TSCN 后不要直接重跑生成器覆盖布局。
- 后续完整玩法原型新增 `luoyang_side_rider.tscn` 的原创侧面骑乘几何、`scenes/levels/luoyang_chapter.tscn` 的韩福／回马暗箭／刀光／左臂束布节点；均为代码编写的占位图形。完整场景拥有独立布局，不由初版生成器覆盖；原角色图集、素材库与字体保持不变。
- 短促命中／锁定／放箭提示音由 `luoyang_prototype.gd` 在内存中合成正弦音及包络，不使用外部录音，不写入本机文件。
- 界面复用已有 `assets/ui/wuxia-kai.otf` 完整 FandolKai Regular，版权与嵌入例外见同目录 `FONT-LICENSE-KAI.txt`、`FANDOL-README.txt`；没有修改字体。自动检查核对了原型新增中文和符号的字形覆盖。
- 独立导出脚本只复制显式列出的运行资源及字体许可到忽略目录 `builds/luoyang-source/`，导出 `builds/luoyang-prototype/`。不复制玩家存档、机器配置或整个美术库。
- `--chapter` 使用独立 `builds/luoyang-chapter-source/` 与 `builds/luoyang-chapter/`，默认本机端口8973；旧练习8972保留。宿主从旅图进入完整原型时才保存关卡进度，独立完整试玩仍不读写正式存档。
