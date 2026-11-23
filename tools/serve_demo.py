#!/usr/bin/env python3
"""Serve the local Godot export, opening a browser after binding the socket."""
from functools import partial
from http.server import SimpleHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path
from urllib.request import urlopen
import webbrowser

ROOT = Path(__file__).resolve().parents[1]
URL = "http://127.0.0.1:8765/"


class DemoHandler(SimpleHTTPRequestHandler):
    def end_headers(self):
        # A local preview must load the newly exported PCK after a page refresh.
        self.send_header("Cache-Control", "no-store")
        super().end_headers()


def main():
    if not (ROOT / "builds/web/index.html").exists():
        raise SystemExit("请先用 Godot 的 Web 预设导出 builds/web/index.html。")
    handler = partial(DemoHandler, directory=str(ROOT / "builds/web"))
    try:
        server = ThreadingHTTPServer(("127.0.0.1", 8765), handler)
    except OSError:
        try:
            with urlopen(URL, timeout=2) as response:
                is_demo = "关公" in response.read().decode("utf-8")
        except Exception:
            is_demo = False
        if not is_demo:
            raise SystemExit("8765 端口被其他程序占用，请关闭该程序或改用其他端口。")
        webbrowser.open(URL)
        return
    print(f"关公试玩：{URL}  （Ctrl+C 停止）")
    webbrowser.open(URL)
    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()
