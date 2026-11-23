# 组员部署操作手册：Godot Web → Vercel

适用对象：需要把关公游戏当前版本更新到网页的组员。更新时间：2026-11-23。

**日常流程：确认要发布的源码 → 本机导出 → 在发布目录核对项目 → 上传正式版本 → 记录结果。**
保存代码、推送 Git 和发布网站是三个独立动作；本项目目前使用手动发布。
已经完成首次配置的组员，可以直接看[每次更新的操作步骤](#3-每次更新的操作步骤)。

## 1. 发布到哪里，文件放在哪里

| 项目 | 固定值或用途 |
| --- | --- |
| Vercel 团队 | Jacky11's Team，命令中的 scope 为 `jacky-111111s-projects` |
| Vercel 项目 | `guangong-game`，使用已有项目，不新建同名项目 |
| 正式游戏地址 | [guangong-game.vercel.app](https://guangong-game.vercel.app) |
| 项目控制台 | [Vercel 控制台](https://vercel.com/jacky-111111s-projects/guangong-game) |
| `godot/` | 游戏工程源码，入口是 `godot/project.godot` |
| `builds/web/` | Godot 原始网页导出，供本机试玩 |
| `builds/vercel/` | **上传 Vercel 的发布目录**，命令必须在这里执行 |
| `builds/logs/` | 本次导入／导出的固定日志 |

所有路径都相对于你自己的仓库根目录，不需要与其他组员的电脑路径一致。

导出工具覆盖固定目录中的同名文件，不创建日期副本、ZIP 或历史版本，也不删除文件。
已发布版本的原始导出和发布包曾各约 66 MiB，两份合计约 132 MiB；实际以本次工具输出为准。
重复导出不会按次数增加整份包，但新增素材、预览图和工具缓存仍可能增加磁盘占用。

## 2. 第一次在自己电脑上配置

### 2.1 准备源码与工具

先获取本仓库：

```sh
git clone https://github.com/jackyuyz/guangong-game.git
cd guangong-game
```

已有仓库时，进入自己电脑上的 `guangong-game` 目录即可，不必再次克隆。

需要安装：

- **Godot 4.7.2 标准版**，并安装同版本导出模板：编辑器菜单 `Editor → Manage Export Templates`。使用现有 `Web` 预设，保持单线程与 Compatibility 渲染器。
- **Python 3**，用于运行导出工具。以下主线命令使用 `python3`；Windows 如果只有 `python` 命令，可替换为 `python`。
- **Node.js、npm／npx 和 Git**。Vercel CLI 固定使用 `66.6.0`，由 `npx` 按需下载，无需全局安装。
- 能访问上述已有 Vercel 项目的账户。没有权限时请联系项目负责人安排发布，不要共享密码或 Token，也不要另建项目绕过权限。

检查工具是否存在：

```sh
python3 --version
node --version
npm --version
git --version
```

Godot 安装与工程打开方法见[本地 Godot 运行说明](local-godot.md)。

### 2.2 指定自己电脑的 Godot 路径，完成一次导出

在仓库根目录执行。macOS 默认安装在 `/Applications/Godot.app` 时：

```sh
python3 tools/export_web.py
```

macOS 或 Linux 安装在其他位置时，替换示例中的可执行文件路径：

```sh
python3 tools/export_web.py --godot "/你的安装路径/Godot"
```

Windows 示例，路径也需要换成自己的真实位置：

```powershell
python tools/export_web.py --godot "C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe"
```

也可以通过 `GODOT` 环境变量指定路径。macOS 用户可双击仓库根的 `export-web.command`；
这个快捷入口使用默认路径或已有的 `GODOT` 环境变量，Windows／Linux 使用 Python 命令。

成功时终端会显示两项 Godot 检查通过、发布目录路径、正式文件数量和总大小。
如果显示“未通过”、错误或缺少文件，先停止并解决问题，不要继续上传旧发布包。

### 2.3 登录 CLI，并关联已有项目

浏览器已经登录 Vercel，不代表终端 CLI 也已登录。运行：

```sh
npx --yes vercel@66.6.0 login
```

按终端提示打开 Vercel 官方设备登录页，使用自己的有权限账户完成批准。
不要把密码、Token、设备登录资料放进仓库或发到群里。

然后从仓库根目录进入发布目录，关联已有项目：

```sh
cd builds/vercel
npx --yes vercel@66.6.0 link --yes --project guangong-game --scope jacky-111111s-projects
npx --yes vercel@66.6.0 project inspect --non-interactive --scope jacky-111111s-projects
```

确认输出为 `jacky-111111s-projects/guangong-game`，项目名和 Owner 正确。
如果报找不到项目或无权限，停止并核对登录账户与团队，不要继续创建或部署到其他项目。

关联信息写在本机 `builds/vercel/.vercel/`，后续导出会保留，通常不用每次登录和关联。
CLI 也可能生成 `.env.local` 与 `.gitignore`；它们属于本机状态，不在上传白名单内。
`builds/` 被 Git 忽略，新组员克隆仓库后需要自己导出和关联，不复制别人的关联目录或凭据。

## 3. 每次更新的操作步骤

每次由一位组员负责发布，避免多人同时更新同一个正式域名。

### 第一步：确认要发布的源码

进入自己的仓库根目录，先看：

```sh
git status --short
```

导出使用的是**当前工作区**，包含未提交改动；确认这些内容就是本轮要发布的版本。
如果有别人的未完成工作或不明改动，先协调，不要自动清理、覆盖或丢弃。

如果本轮约定发布远端最新 `main`，应先在工作区干净、已位于 `main` 的情况下运行：

```sh
git pull --ff-only origin main
```

不要在导出后再更换源码却直接使用旧包。根据改动完成必要的本地检查，
具体检查与独立测试存档规则见 [AGENTS.md](../AGENTS.md)。

### 第二步：重新导出并准备发布目录

在仓库根目录运行与你的安装位置对应的命令，例如默认 macOS 路径：

```sh
python3 tools/export_web.py
```

它依次执行资源导入、Web Release 导出、文件检查和发布目录覆盖：

```text
Godot 工程 → builds/web/ → builds/vercel/
```

正式上传内容为九个游戏文件及 `vercel.json`；音频测试页、素材库、开发日志和本地环境文件不上传。
工具遇到错误会停止，完整输出位于 `builds/logs/web-import.log` 与 `builds/logs/web-export.log`。
**仅在本次导出明确成功后继续下一步。**

需要本机网页预览时，在仓库根另开终端运行 `python3 tools/serve_demo.py`，
访问它打印的本机地址；不要直接双击 `index.html`。
测试使用隔离环境，不要使用或清除玩家原有浏览器进度。

### 第三步：核对目标，发布正式版本

从仓库根目录执行：

```sh
cd builds/vercel
npx --yes vercel@66.6.0 project inspect --non-interactive --scope jacky-111111s-projects
```

确认目标仍是上述已有团队和项目，再执行：

```sh
npx --yes vercel@66.6.0 deploy --prod --scope jacky-111111s-projects
```

等待命令完成，保留本次临时部署 URL、控制台链接和结果。
成功输出应显示 Ready，并将正式网址关联到此次部署。
失败时不要对外宣称已更新；保留错误信息再排查。

**不要从仓库根目录或 `godot/` 运行 `vercel deploy`，也不要只上传 `index.html`。**
前者会上传错误的目录，后者会缺少运行必需的 JS、WASM 和 PCK。

### 第四步：确认发布结果并交接

Ready 只表示平台完成部署，不证明首页有正确的游戏入口。
如本轮允许检查，至少确认正式首页 HTTP 200、网页入口正确；是否试玩由本轮任务决定。
例如只检查响应头、不启动游戏：

```sh
curl -I https://guangong-game.vercel.app/
curl -I https://guangong-game.vercel.app/index.wasm
```

Windows PowerShell 中如 `curl` 是其他命令的别名，可使用 `curl.exe`。
首页应为 200，WASM 应为 200 且 `Content-Type` 为 `application/wasm`。
这些检查不等于游戏完整验收；若本轮明确不做线上检查，记录“部署 Ready，线上未检查”。

在交接中记下发布内容、正式链接、本次临时部署链接、入口检查和试玩各自的实际完成情况，
以及上一次可恢复的完整游戏部署链接。发布相关实际改动按项目规则写入 `task.md`。

## 4. 需要先预览、再更新正式网址时

以下是可选流程，替代第三步的直接正式部署，不需要两套流程都跑。

普通预览：在发布目录运行 `npx --yes vercel@66.6.0 deploy --scope jacky-111111s-projects`。
它返回独立预览链接，不更新正式网址；预览可能需要团队登录，保留现有访问保护。

希望先上传正式版本，再让同一份包接管正式网址时：

```sh
npx --yes vercel@66.6.0 deploy --prod --skip-domain --scope jacky-111111s-projects
```

此时正式网址仍指向旧版。确认这份临时部署可以发布后，把下面占位 URL
替换为上一步返回的**真实部署 URL**：

```sh
npx --yes vercel@66.6.0 promote https://YOUR-DEPLOYMENT.vercel.app --yes --scope jacky-111111s-projects
```

`promote` 更新域名指向，不需要重新导出或再次上传。

## 5. Git 推送与两份 Vercel 配置

| 文件 | 职责 |
| --- | --- |
| 仓库根 `vercel.json` | `git.deploymentEnabled: false`，关闭 Git 推送触发的自动部署 |
| `tools/vercel-static.json` | 静态托管、WASM 类型与缓存配置的源文件 |
| `builds/vercel/vercel.json` | 导出工具生成的发布配置，Vercel 从发布目录读取 |
| `builds/vercel/.vercelignore` | 上传白名单，只允许正式静态文件与发布配置 |

**推送 `main` 用来同步源码，不负责生成或更新游戏网页。**
保留根配置，避免不含 Godot 导出包的源码自动部署覆盖已经发布的游戏。
后续如要自动发布，应先建立真正的 Godot 云端导出流程，再调整自动部署配置。

需要改静态托管行为时修改 `tools/vercel-static.json`，不要只改 `builds/` 中会被覆盖的副本。
不要使用控制台对 Git 源码执行的 Redeploy 代替本机 Godot 导出。
游戏配音已包含在资源中，发布者不需要配置 ElevenLabs API Key、数据库或其他服务端环境变量。

## 6. 出错时怎么处理

| 现象 | 处理方法 |
| --- | --- |
| 找不到 Godot、版本不对、缺少导出模板 | 核对 4.7.2 和 `--godot` 路径，安装同版本模板，再重新导出 |
| 导出报错或正式文件缺失 | 查看 `builds/logs/` 完整输出；解决前不上传旧包 |
| 发布目录有额外文件 | 按工具列出的路径人工检查，不运行批量删除或清理命令 |
| CLI 未登录、关联丢失或没有权限 | 按首次配置重新登录／关联，确认已有团队与项目 |
| 新代码在网页上没有变化 | 确认本次导出成功、从发布目录上传、正式域名已切换；再刷新页面 |
| 预览要求登录 | 使用有权限的账户访问，不随意关闭部署保护 |
| Ready 但首页 404 | 按下方步骤核对域名指向，恢复完整游戏部署 |

### Ready 但首页 404 的恢复步骤

1. 在控制台查看正式域名当前指向的部署，或在发布目录运行：

   ```sh
   npx --yes vercel@66.6.0 inspect https://guangong-game.vercel.app --scope jacky-111111s-projects
   npx --yes vercel@66.6.0 list guangong-game --limit 6 --scope jacky-111111s-projects
   ```

2. 核对来源：是否由 Git 源码直接构建，缺少 Godot 导出的入口？
   选定此前包含 `index.html`、JS、WASM 和 PCK 的完整游戏部署，不要只凭 Ready 判断。
3. 核验该部署的入口后，用第 4 节的 `promote` 命令将它恢复到正式网址。
   如果没有完整可用的部署，就从确认的源码重新导出并发布。
4. 保留 Git 自动部署保护，并核对是否还有较早触发的构建覆盖域名。

2026-11-23 曾发生这类覆盖：11:57 的 Git 源码部署覆盖游戏，11:59 才推送自动部署保护。
关闭自动部署不会恢复已经改变的域名指向，不能撤回此前已经触发的发布。
恢复域名即可解决此类发布问题，无需因此回退游戏源码。

## 7. 本机文件与团队交接

`builds/`、`.godot/`、日志、玩家存档、`.env` 和 CLI 凭据均不提交到 Git。
不要手工打包整个 `builds/vercel/` 目录分享；其中可能有本机 CLI 状态，上传依靠工具白名单。
组员获取源码后应在各自电脑导出，不共享账户凭据或复制他人的本机存档。

发布记录可以按以下内容填写，未完成的检查如实写“未做”：

```text
发布内容：
正式网址：https://guangong-game.vercel.app
本次临时部署 URL：
部署结果：Ready／失败
入口检查：已做／未做
游戏试玩：已做哪些／未做
可恢复的上一份完整游戏部署 URL：
```

参考：[本地 Godot 运行](local-godot.md)、[项目 Agent 约定](../AGENTS.md)、
[Vercel CLI 项目关联](https://vercel.com/docs/cli/link)、
[部署命令](https://vercel.com/docs/cli/deploy)、
[关闭 Git 自动部署](https://vercel.com/docs/git/external-pipelines)。
