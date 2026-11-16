#!/bin/zsh
set -eu
cd "${0:A:h}"
if [[ ! -f builds/web/index.html ]]; then
  print '请先用 Godot 的 Web 预设导出至 builds/web/index.html。'
  exit 1
fi
python3 tools/serve_demo.py
