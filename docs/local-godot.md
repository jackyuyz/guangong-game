# 本地用 Godot 运行东岭关

给要在自己电脑上打开工程、试玩或改完再跑一遍的同事。网页试玩是另一条路径，见文末。

## 安装

使用 **Godot 4.7.2 标准版**（GDScript，不是 .NET 版）。工程功能版本是 4.7，用 4.3、4.4、4.5 或 4.6 打开会提示版本不符，不要把工程改回旧版本。

下载：[Godot 4.7.2 stable](https://godotengine.org/download/archive/4.7.2-stable/)

- macOS：下载 `macos.universal` 压缩包，解压出 `Godot.app`。可放在「应用程序」或自己的 `~/Applications`。第一次打开若被系统拦截，在 Finder 里对 `Godot.app` 按住 Control 点「打开」。
- Windows：下载 `win64.exe` 压缩包，解压后直接运行里面的 `Godot_v4.7.2-stable_win64.exe`，无需安装。
- Linux：下载对应架构的压缩包，解压后运行其中的 `Godot` 可执行文件。

编辑器里直接运行不需要 Web 导出模板。只有要导出浏览器版本时才下载模板。

## 打开工程

1. 启动 Godot，在项目管理器里选 **Import**。
2. 选仓库里的这个文件，不要选仓库根目录：

   `godot/project.godot`

3. 点 **Import & Edit**。第一次导入会处理贴图，等右下角进度结束再运行。
4. 按 **F5**，或点编辑器右上角的播放按钮。主场景已经是 `scenes/main.tscn`，如果弹出选择主场景，选它即可。

窗口标题是「关公 · 东岭关」。能看到开场菜单就可以开始。

只想在编辑器里看场景、不运行：打开 `godot/scenes/main.tscn`，切到上方 **2D**。关卡节点在 `scenes/levels/dongling_pass.tscn`，界面在 `scenes/ui/game_ui.tscn`。

## 操作

| 按键 | 作用 |
| --- | --- |
| A / D 或左右方向键 | 移动 |
| J | 挥刀，连按最多三段 |
| Space | 闪避 |
| K | 格挡；敌人出手瞬间按下是弹反 |
| L | 义气满后使用偃月斩 |
| E | 第二波清空后，在茶摊歇脚 |
| Enter | 推进对白、确认 |
| Esc 或 P | 暂停 |
| M | 开关声音 |

流程是开场对白、移动/挥刀/闪避教学、两波守军、孔秀两阶段，然后文化回顾和结算。Boss 战失败可以从检查点重试。

通关记录和声音开关保存在本机 Godot 的用户目录里，下次打开还会在。这和别人电脑上的存档互不影响。自动化测试使用临时存档，不要拿自己的游玩存档去做测试，也不要把它提交到 Git。

## 命令行运行

在仓库根目录执行。把 `GODOT` 换成自己机器上的可执行文件。

macOS：

```sh
GODOT="/Applications/Godot.app/Contents/MacOS/Godot"
"$GODOT" --path godot
```

如果应用在个人目录，路径是 `"$HOME/Applications/Godot.app/Contents/MacOS/Godot"`。

Windows（在解压目录里，或把 exe 路径写全）：

```bat
Godot_v4.7.2-stable_win64.exe --path godot
```

Linux：

```sh
/path/to/Godot --path godot
```

## 改完代码后的自动检查

在仓库根目录运行，仍使用上面的 `GODOT`。先看完整输出里有没有 `ERROR`，不要只看进程是否退出。

```sh
"$GODOT" --headless --path godot --editor --import --quit
"$GODOT" --headless --path godot --script scripts/smoke_test.gd
"$GODOT" --headless --path godot --script scripts/scene_test.gd
"$GODOT" --headless --path godot --script scripts/extensions_test.gd
```

这三组检查不能代替在编辑器里看画面和自己打一局。

## 和网页试玩的区别

`play-web.command` 和 `python3 tools/serve_demo.py` 打开的是已经导出的网页包，地址是 <http://127.0.0.1:8765/>。那个目录 `builds/web/` 不在 Git 里，同事克隆仓库后默认没有这份文件。

日常改 Godot 工程，用上面的编辑器或 `--path godot` 即可，改动会马上体现在 F5 里。只有要核对浏览器里的版本时，才需要重新导出：

```sh
"$GODOT" --headless --path godot --export-release Web ../builds/web/index.html
python3 tools/serve_demo.py
```

导出前要在 Godot 里装好 **与 4.7.2 相同版本** 的 Web 导出模板。不要直接双击 `index.html`。
