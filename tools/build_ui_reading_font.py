#!/usr/bin/env python3
"""Rebuild the OFL reading subset from an official NotoSerifSC.ttf source."""
import argparse
from pathlib import Path
from fontTools import subset
from fontTools.ttLib import TTFont
from fontTools.varLib.instancer import instantiateVariableFont

ROOT = Path(__file__).resolve().parents[1]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("source", type=Path)
    args = parser.parse_args()
    text = "".join(chr(i) for i in range(32, 127)) + "←→↑↓›◆·—，。！？：；（）「」、…％"
    target = ROOT / "godot/assets/ui/wuxia-reading-font.ttf"
    # Older delivered text must remain renderable even if it moves out of current scenes.
    if target.exists():
        with TTFont(target) as existing:
            text += "".join(chr(code) for code in existing.getBestCmap())
    for folder, suffixes in [("scenes", {".tscn"}), ("scripts", {".gd"}), ("data", {".json"})]:
        for path in sorted((ROOT / "godot" / folder).rglob("*")):
            if path.suffix in suffixes and not path.stem.endswith(("_test", "_fixture")):
                text += path.read_text()
    font = TTFont(args.source)
    if "fvar" in font:
        font = instantiateVariableFont(font, {"wght": 400}, inplace=True)
    options = subset.Options()
    options.name_IDs = ["*"]
    options.name_legacy = True
    options.name_languages = ["*"]
    sub = subset.Subsetter(options=options)
    sub.populate(text=text)
    sub.subset(font)
    for name in font["name"].names:
        value = {1: "Guangong Wuxia Reading", 2: "Regular", 3: "GuangongWuxiaReading-Regular",
                 4: "Guangong Wuxia Reading Regular", 6: "GuangongWuxiaReading-Regular",
                 16: "Guangong Wuxia Reading", 17: "Regular"}.get(name.nameID)
        if value is not None:
            name.string = value.encode(name.getEncoding())
    font.save(target)
    print(f"Saved {target.relative_to(ROOT)}: {target.stat().st_size} bytes")


if __name__ == "__main__":
    main()
