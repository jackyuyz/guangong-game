#!/usr/bin/env python3
"""Run or export the save-free Luoyang prototype, independently of the main game."""
import argparse
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
import os
from pathlib import Path
import shutil
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "builds/luoyang-source"
WEB = ROOT / "builds/luoyang-prototype"
LOGS = ROOT / "builds/logs/luoyang"
SCENE = "res://scenes/prototypes/luoyang_prototype.tscn"
RESOURCES = (
    "scripts/luoyang_model.gd", "scripts/luoyang_road.gd", "scripts/luoyang_prototype.gd",
    "scenes/prototypes/luoyang_prototype.tscn", "scenes/prototypes/luoyang_rider.tscn",
    "scenes/prototypes/luoyang_barricade.tscn", "scenes/prototypes/luoyang_arrow.tscn",
    "assets/luoyang-prototype/luoyang-gatehouse.png", "assets/ui/wuxia-kai.otf",
    "assets/ui/FONT-LICENSE-KAI.txt", "assets/ui/FANDOL-README.txt",
    "assets/branding/guan-seal-icon.png",
)
CHAPTER_RESOURCES = (
    "scripts/luoyang_chapter_model.gd", "scripts/luoyang_chapter.gd",
    "scripts/luoyang_interface.gd", "scripts/wuxia_feedback.gd",
    "scripts/settings_panel.gd", "scenes/ui/settings_panel.tscn",
    "themes/wuxia-game.tres", "themes/wuxia-panel.tres", "themes/wuxia-display-font.tres",
    "assets/ui/wuxia-reading-font.ttf", "assets/ui/FONT-LICENSE-READING.txt",
    "assets/ui/wuxia-panel.png", "assets/ui/wuxia-primary-brush.png",
    "assets/ui/combat-jade-medallion.png", "assets/ui/combat-ink-wash.png",
    "assets/ui/cinnabar-seal-frame.png", "assets/animations/guan-yu-sheet.png",
    "scripts/portrait_cutout.gdshader", "assets/main-menu/menu-brush.png",
    "assets/main-menu/hover.wav", "assets/main-menu/confirm.wav",
    "assets/journey-map/five-passes-scroll.png",
    "scripts/luoyang_pursuer.gd", "scripts/luoyang_story.gd",
    "scripts/luoyang_pacing.gd", "scenes/luoyang/arrow.tscn",
    "scripts/luoyang_finale.gd", "assets/luoyang-art/guan-yu-binding.png",
    "assets/luoyang-art/carriage-walk-v2.png", "assets/luoyang-art/approach-fork.png",
    "scenes/luoyang/hero_binding.tscn", "scenes/luoyang/carriage_walk.tscn",
    "scenes/levels/luoyang_chapter.tscn", "scenes/prototypes/luoyang_side_rider.tscn",
    "scripts/luoyang_sprite.gd", "scripts/luoyang_art.gd", "scripts/sprite_cutout.gdshader",
    "scenes/luoyang/rider.tscn", "scenes/luoyang/hero_side.tscn",
    "scenes/luoyang/hero_turn.tscn", "assets/luoyang-art/guan-yu-turn.png",
    "scenes/luoyang/meng_rear.tscn", "scenes/luoyang/meng_side.tscn",
    "scenes/luoyang/han_fu.tscn", "scenes/luoyang/barricade.tscn",
    "scenes/luoyang/banner.tscn", "scenes/luoyang/grass.tscn",
    "assets/luoyang-art/guan-yu-rear.png", "assets/luoyang-art/guan-yu-mounted.png",
    "assets/luoyang-art/meng-tan-mounted.png", "assets/luoyang-art/han-fu-actions.png",
    "assets/luoyang-art/approach-forward.png", "assets/luoyang-art/roadside-props.png",
    "assets/luoyang-art/carriage-occupied.png", "assets/luoyang-art/archery-position.png",
    "assets/luoyang-art/duel-side.png",
)


def checked_run(godot, project, args, name):
    LOGS.mkdir(parents=True, exist_ok=True)
    result = subprocess.run(
        [godot, "--headless", "--path", str(project), "--log-file",
         str(LOGS / f"{name}.engine.log"), *args],
        stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, cwd=ROOT)
    log = LOGS / f"{name}.log"
    log.write_text(result.stdout)
    issues = [line for line in result.stdout.splitlines()
              if "ERROR:" in line or "WARNING:" in line or "SCRIPT ERROR:" in line]
    for issue in issues:
        print(issue)
    if result.returncode or any("ERROR:" in line for line in issues):
        raise SystemExit(f"Godot 未通过，完整日志：{log}")
    print(f"Godot 完成：{log}", flush=True)


def prepare(chapter=False):
    for relative in RESOURCES + (CHAPTER_RESOURCES if chapter else ()):
        source = ROOT / "godot" / relative
        target = SOURCE / relative
        if target.is_symlink():
            raise SystemExit(f"原型暂存目标不能是符号链接：{target}")
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, target)
        imported = source.with_suffix(source.suffix + ".import")
        if imported.exists():
            # Shared themes reference stable asset UIDs as well as text paths.
            shutil.copyfile(imported, target.with_suffix(target.suffix + ".import"))
        uid = source.with_suffix(source.suffix + ".uid")
        if uid.exists():
            shutil.copyfile(uid, target.with_suffix(target.suffix + ".uid"))
    project = '''config_version=5

[application]
config/name="关公 · 洛阳操作原型"
config/icon="res://assets/branding/guan-seal-icon.png"
run/main_scene="res://scenes/prototypes/luoyang_prototype.tscn"
config/features=PackedStringArray("4.7", "GL Compatibility")

[display]
window/size/viewport_width=960
window/size/viewport_height=540
window/size/window_width_override=1280
window/size/window_height_override=720
window/stretch/mode="canvas_items"

[rendering]
renderer/rendering_method="gl_compatibility"
renderer/rendering_method.mobile="gl_compatibility"
environment/defaults/default_clear_color=Color(0.06, 0.11, 0.085, 1)
'''
    if chapter:
        project = project.replace("关公 · 洛阳操作原型", "关公 · 洛阳关").replace(
            "res://scenes/prototypes/luoyang_prototype.tscn", SCENE)
    (SOURCE / "project.godot").write_text(project)
    preset = '''[preset.0]
name="Web"
platform="Web"
runnable=true
advanced_options=false
dedicated_server=false
custom_features=""
export_filter="all_resources"
include_filter="assets/ui/*.txt"
exclude_filter=""
export_path="../luoyang-prototype/index.html"
script_export_mode=2

[preset.0.options]
variant/thread_support=false
vram_texture_compression/for_desktop=true
html/export_icon=true
html/canvas_resize_policy=2
html/focus_canvas_on_start=true
progressive_web_app/enabled=false
'''
    if chapter:
        preset = preset.replace("../luoyang-prototype/", "../luoyang-chapter/")
    (SOURCE / "export_presets.cfg").write_text(preset)


class Handler(SimpleHTTPRequestHandler):
    def end_headers(self):
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def main():
    global SOURCE, WEB, LOGS, SCENE
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--godot", default=os.environ.get("GODOT", "/Applications/Godot.app/Contents/MacOS/Godot"))
    parser.add_argument("--export", action="store_true", help="Build a separate Web prototype")
    parser.add_argument("--serve", action="store_true", help="Serve the separate export on loopback")
    parser.add_argument("--chapter", action="store_true", help="Run/export the full chapter instead of the three drills")
    parser.add_argument("--port", type=int)
    args = parser.parse_args()
    if args.chapter:
        SOURCE = ROOT / "builds/luoyang-chapter-source"
        WEB = ROOT / "builds/luoyang-chapter"
        LOGS = ROOT / "builds/logs/luoyang-chapter"
        SCENE = "res://scenes/levels/luoyang_chapter.tscn"
    port = args.port if args.port is not None else (8973 if args.chapter else 8972)
    if args.export or not args.serve:
        godot = shutil.which(args.godot)
        if not godot:
            raise SystemExit("请用 --godot 指定 Godot 4.7.2。")
        version = subprocess.check_output([godot, "--version"], text=True).strip()
        if not version.startswith("4.7.2."):
            raise SystemExit(f"需要 Godot 4.7.2，当前为 {version}")
        if args.export:
            # Keep each export's import registry coherent with the copied source UIDs.
            # Earlier staging trees are retained; never clear a cache recursively.
            (ROOT / "builds").mkdir(parents=True, exist_ok=True)
            SOURCE = Path(tempfile.mkdtemp(prefix="luoyang-chapter-source-" if args.chapter else "luoyang-source-", dir=ROOT / "builds"))
            prepare(args.chapter)
            WEB.mkdir(parents=True, exist_ok=True)
            checked_run(godot, SOURCE, ["--editor", "--import", "--quit"], "import")
            checked_run(godot, SOURCE, ["--export-release", "Web", str(WEB / "index.html")], "export")
            if args.chapter:
                # An empty base prevents resource lookup falling back to source assets.
                # Keep the directory in ignored builds; never recursively clean it.
                pack_check = ROOT / "builds/luoyang-pack-check"
                pack_check.mkdir(parents=True, exist_ok=True)
                if any(pack_check.iterdir()):
                    raise SystemExit(f"实际PCK检查目录必须为空：{pack_check}")
                checked_run(godot, pack_check, ["--main-pack", str(WEB / "index.pck"),
                    "--script", str(ROOT / "godot/scripts/luoyang_export_test.gd")], "exported-pack-test")
            print(f"独立原型：{WEB / 'index.html'}；正式 Web 包与玩家进度保持原样。")
        elif not args.serve:
            LOGS.mkdir(parents=True, exist_ok=True)
            raise SystemExit(subprocess.call([godot, "--path", str(ROOT / "godot"),
                "--log-file", str(LOGS / "native.log"), SCENE], cwd=ROOT))
    if args.serve:
        if not (WEB / "index.html").is_file():
            raise SystemExit("请先运行 python3 tools/luoyang_prototype.py --export" + (" --chapter" if args.chapter else "") + "。")
        server = ThreadingHTTPServer(("127.0.0.1", port), partial(Handler, directory=str(WEB)))
        print(f"洛阳原型：http://127.0.0.1:{server.server_port}/ （Ctrl+C 停止）", flush=True)
        try:
            server.serve_forever()
        except KeyboardInterrupt:
            pass
        finally:
            server.server_close()


if __name__ == "__main__":
    main()
