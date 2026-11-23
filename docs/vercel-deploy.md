# 导出与 Vercel 手动发布

目标项目为 Jacky11's Team 的 `guangong-game`：
[项目控制台](https://vercel.com/jacky-111111s-projects/guangong-game)，
[正式网站](https://guangong-game.vercel.app)。

2026-11-23 已完成本机导出、关联、正式部署与固定域名发布，状态 Ready。
已检查云端文件哈希、响应头和文件排除；按用户决定不做线上交互试玩。

## 固定目录与磁盘占用

- `builds/web/`：Godot Web 原始导出，本机试玩沿用此目录。
- `builds/vercel/`：正式发布目录，上传内容为九个正式导出文件及 Vercel 配置。
- `builds/logs/`：固定名称的导入／导出日志。

导出工具覆盖同名文件，不创建日期目录、ZIP 或历史版本，也不删除文件。
当前 Web 和正式发布包各约 66 MiB，两份合计约 132 MiB；重复导出不会每次增加一份。
体积会随游戏内容变化，首次使用 Vercel／npm 还会产生工具缓存。
原导出目录中的音频测试页保留在本机，不复制进正式发布目录。
发布目录出现额外文件时工具会停止并列出路径，交由人工检查，不自动清理。

保存代码不会自动导出，导出也不会自动上传。以下命令需要显式运行。

## 1. 导出当前游戏

双击仓库根目录的 `export-web.command`，或在终端运行：

```sh
cd /Users/yuyuanzhengjack/Developments/GitHub_Repos/guangong-game
python3 tools/export_web.py
```

默认使用 `/Applications/Godot.app/Contents/MacOS/Godot`，要求 4.7.2。
其他安装位置可使用 `GODOT` 环境变量或 `--godot /path/to/Godot`。
工具依次执行资源导入、Web Release 导出、正式文件校验与发布目录覆盖。
Godot 输出含 `ERROR:` 或命令失败时停止准备发布包，完整输出在 `builds/logs/`。
看到“未通过”时先解决错误，不要上传上次留下的发布包。

`tools/vercel-static.json` 是托管配置源文件，导出时复制为发布包内的 `vercel.json`。
配置使用静态托管、跳过构建与安装、输出目录 `.`、WASM MIME 类型及浏览器缓存重新验证。
不需要数据库、服务端 API Key 或 `.env`。

## 2. 首次登录与关联已有项目

使用 Node.js／npm 自带的 `npx` 执行固定版本 CLI。浏览器登录和 CLI 登录互相独立：

```sh
npx --yes vercel@66.6.0 login
cd /Users/yuyuanzhengjack/Developments/GitHub_Repos/guangong-game/builds/vercel
npx --yes vercel@66.6.0 link --yes --project guangong-game --scope jacky-111111s-projects
npx --yes vercel@66.6.0 project inspect --non-interactive --scope jacky-111111s-projects
```

在官方登录页面完成授权，不要发送密码或 Token。
确认关联的是上述已有团队与项目，再进行部署；不要在关联失败时另建同名项目。
关联信息保存在本目录的 `.vercel/`，下次导出保留。
CLI 关联时可能另建 `.env.local`（本地 OIDC 数据）与 `.gitignore`；保留在本机，不查看或发送其中的凭据。
`.vercel/`、`.env.local` 和 `.gitignore` 均不在上传白名单中；不要手工打包整个目录上传到其他服务。
整个 `builds/` 已被 Git 忽略，发布包的 `.vercelignore` 只允许正式静态文件上传。

## 3. 预览与正式发布

每次修改后先重新执行第 1 步，然后在发布目录运行：

```sh
cd /Users/yuyuanzhengjack/Developments/GitHub_Repos/guangong-game/builds/vercel
npx --yes vercel@66.6.0 project inspect --non-interactive --scope jacky-111111s-projects
npx --yes vercel@66.6.0 deploy --scope jacky-111111s-projects
```

CLI 返回预览链接。预览可能需要团队登录，不必为了测试关闭访问保护。
检查加载、声音、地图、进入教学、暂停、刷新保存与浏览器控制台。
测试使用独立浏览器资料，不用玩家已有进度。

确认可用后，在同一个发布目录执行正式部署：

```sh
npx --yes vercel@66.6.0 deploy --prod --scope jacky-111111s-projects
```

等待 Ready，再访问正式网站并刷新检查。CLI 部署只上传该目录，不会推送 Git。
当前项目仍关联 GitHub 的 `main` 分支，但没有云端 Godot 导出流程。
仓库根 `vercel.json` 设置 `git.deploymentEnabled: false`，关闭 Git 推送触发的自动部署，
避免不含游戏导出包的源码部署覆盖已发布游戏；Git 关联保留，CLI 手动部署不受影响。
这份根配置只管 Git 触发；正式包仍使用 `tools/vercel-static.json` 生成的静态托管配置。
接入自动导出流程前，以此处的 CLI 部署为准，不要用控制台 Git Redeploy 替代本机导出。

需要先暂存正式部署、验收后再更新固定域名时，可使用：

```sh
npx --yes vercel@66.6.0 deploy --prod --skip-domain --scope jacky-111111s-projects
# 验证上一步返回的部署地址后，将下面的占位地址替换为该地址：
npx --yes vercel@66.6.0 promote https://YOUR-DEPLOYMENT.vercel.app --scope jacky-111111s-projects
```

参考：[CLI 项目关联](https://vercel.com/docs/cli/link)、
[静态构建配置](https://vercel.com/docs/builds/configure-a-build#skip-build-step)、
[关闭 Git 自动部署](https://vercel.com/docs/git/external-pipelines)、
[CLI 部署](https://vercel.com/docs/cli/deploy)。
