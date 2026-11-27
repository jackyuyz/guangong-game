#!/usr/bin/env python3
"""Author real atlas/sprite scenes; read alpha bounds without modifying source PNGs.

Run with `uv run --with pillow python tools/build_luoyang_art_scenes.py`.
Only the explicitly named derived TSCN files are written. Chapter layout is separate.
"""
from pathlib import Path
from PIL import Image

ROOT = Path(__file__).resolve().parents[1] / "godot"
OUT = ROOT / "scenes/luoyang"


def actor(name, image, rows, indices, scale, default=0, columns=4):
    source = Image.open(ROOT / "assets/luoyang-art" / image)
    width, height = source.size
    cw, ch = width / columns, height / rows
    resources, pivots = [], []
    for j, i in enumerate(indices):
        x, y = i % columns * cw, i // columns * ch
        alpha = source.getchannel("A").crop((round(x), round(y), round(x + cw), round(y + ch)))
        box = alpha.point(lambda a: 255 if a >= 192 else 0).getbbox()
        # Anchor the ground; keep intentional suspension in the gallop cycle.
        airborne = [0, 5, 11, 2][i % 4] if (name in ["rider", "meng_rear"] or (name == "hero_side" and i < 2)) else 0
        baseline = box[3] + airborne
        clip = (0, 0, cw, ch)
        # This generated lower row has a few pixels from the neighboring fall frame.
        # Clip only the atlas window; keep the original PNG unchanged, and include
        # the falling hand that starts 21px left of the nominal third cell.
        if image == "meng-tan-mounted.png" and i == 5:
            clip = (17, 34, 381, 368)
        elif image == "meng-tan-mounted.png" and i == 6:
            clip = (-21, 90, 427, 327)
        left, top, rw, rh = clip
        pivots.append((cw / 2 - left, baseline - top))
        resources.append(f'''[sub_resource type="AtlasTexture" id="frame{j}"]
atlas = ExtResource("sheet")
region = Rect2({x + left}, {y + top}, {rw}, {rh})
filter_clip = true
metadata/ground_baseline = {baseline}.0
metadata/ground_pivot = Vector2({cw / 2 - left}, {baseline - top})
''')
    refs = ", ".join(f'SubResource("frame{i}")' for i in range(len(indices)))
    x, y = pivots[default]
    text = f'''[gd_scene load_steps={len(indices) + 5} format=3]

[ext_resource type="Script" path="res://scripts/luoyang_sprite.gd" id="script"]
[ext_resource type="Texture2D" path="res://assets/luoyang-art/{image}" id="sheet"]
[ext_resource type="Shader" path="res://scripts/sprite_cutout.gdshader" id="cutout"]

[sub_resource type="ShaderMaterial" id="material"]
shader = ExtResource("cutout")

''' + "\n".join(resources) + f'''
[node name="{name}" type="Node2D"]
texture_filter = 1
script = ExtResource("script")
frames = Array[AtlasTexture]([{refs}])

[node name="Shadow" type="Polygon2D" parent="."]
polygon = PackedVector2Array(-42, 0, -25, -7, 25, -7, 42, 0, 25, 6, -25, 6)
color = Color(0.14, 0.12, 0.08, 0.27)

[node name="Body" type="Node2D" parent="."]

[node name="Sprite" type="Sprite2D" parent="Body"]
material = SubResource("material")
scale = Vector2({scale}, {scale})
texture = SubResource("frame{default}")
centered = false
offset = Vector2({-x}, {-y})

[node name="Weapon" type="Node2D" parent="."]

[node name="Wound" type="Node2D" parent="."]
visible = false
'''
    if name == "hero_side":
        text += '''
[node name="Wrap" type="Polygon2D" parent="Wound"]
position = Vector2(12, -126)
polygon = PackedVector2Array(-6, -5, 6, -3, 5, 5, -7, 3)
color = Color(0.88, 0.83, 0.66, 1)

[node name="Binding" type="Line2D" parent="Wound"]
points = PackedVector2Array(6, -128, 18, -126, 6, -124, 17, -122)
width = 1.0
default_color = Color(0.57, 0.53, 0.42, 1)
'''
    (OUT / f"{name}.tscn").write_text(text)


def prop(name, rect, scale, pivot):
    x, y, w, h = rect
    px, py = pivot
    (OUT / f"{name}.tscn").write_text(f'''[gd_scene load_steps=3 format=3]

[ext_resource type="Texture2D" path="res://assets/luoyang-art/roadside-props.png" id="props"]

[sub_resource type="AtlasTexture" id="atlas"]
atlas = ExtResource("props")
region = Rect2({x}, {y}, {w}, {h})
filter_clip = true

[node name="{name}" type="Node2D"]
texture_filter = 1

[node name="Sprite" type="Sprite2D" parent="."]
scale = Vector2({scale}, {scale})
texture = SubResource("atlas")
centered = false
offset = Vector2({-px}, {-py})
''')


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    actor("rider", "guan-yu-rear.png", 3, list(range(12)), 0.57)
    actor("hero_side", "guan-yu-mounted.png", 2, list(range(8)), 0.60)
    # The last extended-gallop cell touches the right image edge; unused in this cut.
    actor("hero_turn", "guan-yu-turn.png", 2, list(range(7)), 0.60)
    actor("hero_binding", "guan-yu-binding.png", 2, list(range(8)), 0.60)
    actor("carriage_walk", "carriage-walk-v2.png", 2, list(range(4)), 0.48, columns=2)
    actor("meng_rear", "meng-tan-mounted.png", 2, list(range(4)), 0.48)
    actor("meng_side", "meng-tan-mounted.png", 2, list(range(4, 8)), 0.56)
    actor("han_fu", "han-fu-actions.png", 2, list(range(8)), 0.49)
    prop("barricade", (32, 168, 904, 489), 0.18, (452, 460))
    prop("banner", (1028, 0, 468, 716), 0.21, (85, 697))
    prop("grass", (1590, 238, 560, 402), 0.21, (280, 375))


if __name__ == "__main__":
    main()
