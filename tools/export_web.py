#!/usr/bin/env python3
"""Export Godot Web and overwrite a fixed, allowlisted Vercel staging directory."""
import argparse
import json
import os
from pathlib import Path
import shutil
import subprocess

ROOT = Path(__file__).resolve().parents[1]
WEB = ROOT / "builds/web"
PUBLISH = ROOT / "builds/vercel"
FILES = (
    "index.html",
    "index.js",
    "index.wasm",
    "index.pck",
    "index.png",
    "index.icon.png",
    "index.apple-touch-icon.png",
    "index.audio.worklet.js",
    "index.audio.position.worklet.js",
)


def check_publish_directory():
    if WEB.is_symlink() or PUBLISH.is_symlink():
        raise SystemExit("导出／发布目录不能是符号链接。")
    # Vercel link may create local OIDC/environment and Git-ignore files.
    # Preserve them locally; the upload allowlist below excludes all of them.
    allowed = set(FILES) | {"vercel.json", ".vercelignore", ".vercel", ".env.local", ".gitignore"}
    if PUBLISH.exists():
        unexpected = [str(p) for p in PUBLISH.iterdir() if p.name not in allowed]
        if unexpected:
            raise SystemExit("发布目录有额外文件，请手动检查；本工具不会删除：\n" + "\n".join(unexpected))
        for name in allowed:
            p = PUBLISH / name
            if p.is_symlink() or (p.exists() and name != ".vercel" and not p.is_file()):
                raise SystemExit(f"发布目标不是普通文件：{p}")


def run_godot(godot, args, log_name):
    logs = ROOT / "builds/logs"
    logs.mkdir(parents=True, exist_ok=True)
    log = logs / log_name
    result = subprocess.run(
        [godot, "--headless", "--path", str(ROOT / "godot"),
         "--log-file", str(logs / (log_name + ".engine.log")), *args],
        cwd=ROOT, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True,
    )
    log.write_text(result.stdout, encoding="utf-8")
    issues = [line for line in result.stdout.splitlines()
              if "ERROR:" in line or "WARNING:" in line]
    for line in issues:
        print(line)
    if result.returncode or any("ERROR:" in line for line in issues):
        raise SystemExit(f"Godot 未通过，停止准备发布包。完整日志：{log}")
    print(f"Godot 检查通过：{log.name}", flush=True)


def stage():
    check_publish_directory()
    for name in FILES:
        p = WEB / name
        if not p.is_file() or p.is_symlink() or not p.stat().st_size:
            raise SystemExit(f"导出文件缺失、为空或不是普通文件：{p}")
    html = (WEB / "index.html").read_text(encoding="utf-8")
    if "$GODOT_CONFIG" in html or "$GODOT_URL" in html:
        raise SystemExit("HTML 仍有未替换的 Godot 模板占位符。")
    PUBLISH.mkdir(parents=True, exist_ok=True)
    for name in FILES:
        shutil.copyfile(WEB / name, PUBLISH / name)
    config = json.loads((ROOT / "tools/vercel-static.json").read_text(encoding="utf-8"))
    (PUBLISH / "vercel.json").write_text(
        json.dumps(config, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    # Only these static files are eligible for upload, even if local CLI state exists.
    (PUBLISH / ".vercelignore").write_text(
        "*\n" + "".join(f"!{name}\n" for name in (*FILES, "vercel.json")),
        encoding="utf-8",
    )
    size = sum((PUBLISH / name).stat().st_size for name in FILES)
    print(f"发布目录：{PUBLISH}")
    print(f"正式文件：{len(FILES)} 个，{size / 1024**2:.2f} MiB")
    print("已覆盖固定目录；未创建版本副本，未删除文件，未上传。")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=os.environ.get(
        "GODOT", "/Applications/Godot.app/Contents/MacOS/Godot"))
    args = parser.parse_args()
    check_publish_directory()
    godot = shutil.which(args.godot)
    if not godot:
        raise SystemExit("未找到 Godot；请用 --godot 指定 Godot 4.7.2 可执行文件。")
    version = subprocess.check_output([godot, "--version"], text=True).strip()
    if not version.startswith("4.7.2."):
        raise SystemExit(f"需要 Godot 4.7.2，当前为 {version}")
    WEB.mkdir(parents=True, exist_ok=True)
    run_godot(godot, ["--editor", "--import", "--quit"], "web-import.log")
    run_godot(godot, ["--export-release", "Web", str(WEB / "index.html")], "web-export.log")
    stage()


if __name__ == "__main__":
    main()
