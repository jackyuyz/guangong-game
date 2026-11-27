#!/usr/bin/env python3
"""Author the prototype's editable, geometric TSCN scenes. No source art is modified."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1] / "godot/scenes/prototypes"


def polygon(name, parent, points, color, extra=""):
    coords = ", ".join(str(v) for p in points for v in p)
    return (f'\n[node name="{name}" type="Polygon2D" parent="{parent}"]\n'
            f'polygon = PackedVector2Array({coords})\ncolor = Color({color})\n{extra}')


def line(name, parent, points, color, width=3):
    coords = ", ".join(str(v) for p in points for v in p)
    return (f'\n[node name="{name}" type="Line2D" parent="{parent}"]\n'
            f'points = PackedVector2Array({coords})\nwidth = {width}.0\n'
            f'default_color = Color({color})\n')


def label(name, parent, rect, text, size=20, align=0, color="0.95, 0.89, 0.73, 1"):
    x, y, right, bottom = rect
    return (f'\n[node name="{name}" type="Label" parent="{parent}"]\n'
            f'offset_left = {x}.0\noffset_top = {y}.0\noffset_right = {right}.0\noffset_bottom = {bottom}.0\n'
            f'mouse_filter = 2\ntheme_override_colors/font_color = Color({color})\n'
            f'theme_override_font_sizes/font_size = {size}\ntext = "{text}"\n'
            f'horizontal_alignment = {align}\nvertical_alignment = 1\n')


def button(name, parent, rect, text, focus=2):
    x, y, right, bottom = rect
    return (f'\n[node name="{name}" type="Button" parent="{parent}"]\n'
            f'offset_left = {x}.0\noffset_top = {y}.0\noffset_right = {right}.0\noffset_bottom = {bottom}.0\n'
            f'focus_mode = {focus}\ntheme_override_font_sizes/font_size = 22\ntext = "{text}"\n')


def build():
    ROOT.mkdir(parents=True, exist_ok=True)
    rider = '[gd_scene format=3]\n\n[node name="Rider" type="Node2D"]\n'
    rider += polygon('Shadow', '.', [(-48, -3), (-32, -10), (32, -10), (48, -3), (34, 6), (-34, 6)], '0.12, 0.15, 0.11, 0.45')
    rider += '\n[node name="Body" type="Node2D" parent="."]\n'
    rider += polygon('FarLegs', 'Body', [(-25,-48),(-17,-48),(-13,-12),(-22,-12),(-28,-22)], '0.36, 0.15, 0.12, 1')
    rider += polygon('FarLegRight', 'Body', [(17,-48),(25,-48),(28,-22),(22,-12),(13,-12)], '0.36, 0.15, 0.12, 1')
    rider += polygon('Horse', 'Body', [(-21,-113),(-28,-99),(-38,-73),(-36,-43),(-24,-27),(24,-27),(36,-43),(38,-73),(28,-99),(21,-113)], '0.63, 0.25, 0.15, 1')
    rider += polygon('Neck', 'Body', [(-14,-111),(-13,-137),(-10,-151),(-4,-143),(4,-143),(10,-151),(13,-137),(14,-111)], '0.69, 0.29, 0.16, 1')
    rider += polygon('Mane', 'Body', [(-4,-142),(5,-142),(10,-116),(-5,-113)], '0.24, 0.13, 0.10, 1')
    rider += polygon('Saddle', 'Body', [(-30,-87),(-32,-49),(32,-49),(30,-87)], '0.80, 0.62, 0.28, 1')
    rider += polygon('Back', 'Body', [(-24,-116),(-32,-97),(-19,-73),(19,-73),(32,-97),(24,-116)], '0.10, 0.24, 0.18, 1')
    rider += polygon('Cape', 'Body', [(-22,-115),(-25,-89),(-31,-60),(-17,-53),(0,-58),(17,-53),(31,-60),(25,-89),(22,-115)], '0.17, 0.38, 0.27, 1')
    rider += line('CapeTrim', 'Body', [(-28,-61),(-17,-57),(0,-62),(17,-57),(28,-61)], '0.72, 0.64, 0.31, 1', 2)
    rider += polygon('Head', 'Body', [(-11,-137),(-13,-124),(-8,-114),(8,-114),(13,-124),(11,-137)], '0.64, 0.40, 0.23, 1')
    rider += polygon('Turban', 'Body', [(-13,-134),(-9,-145),(9,-145),(13,-134),(11,-127),(-11,-127)], '0.10, 0.30, 0.21, 1')
    rider += polygon('TurbanTail', 'Body', [(-8,-132),(-14,-103),(-6,-111),(0,-134)], '0.08, 0.25, 0.18, 1')
    rider += line('BladeShaft', 'Body', [(33,-39),(39,-151)], '0.64, 0.49, 0.25, 1', 4)
    rider += polygon('Blade', 'Body', [(39,-151),(44,-179),(61,-192),(55,-175),(46,-165),(44,-148)], '0.81, 0.88, 0.75, 1')
    rider += polygon('Tail', 'Body', [(-5,-42),(-10,-16),(-6,-3),(3,-12),(6,-42)], '0.25, 0.12, 0.09, 1')
    rider += polygon('HindLegLeft', 'Body', [(-32,-43),(-21,-40),(-27,-17),(-22,-3),(-35,-3),(-38,-14)], '0.50, 0.20, 0.13, 1')
    rider += polygon('HindLegRight', 'Body', [(21,-40),(32,-43),(38,-14),(35,-3),(22,-3),(27,-17)], '0.50, 0.20, 0.13, 1')
    rider += line('HoofLeft', 'Body', [(-35,-3),(-23,-3)], '0.15, 0.13, 0.10, 1', 5)
    rider += line('HoofRight', 'Body', [(23,-3),(35,-3)], '0.15, 0.13, 0.10, 1', 5)
    (ROOT/'luoyang_rider.tscn').write_text(rider)

    barrier = '[gd_scene format=3]\n\n[node name="Barricade" type="Node2D"]\n'
    barrier += polygon('Shadow','.',[(-76,0),(-59,-10),(60,-10),(76,0),(60,8),(-60,8)],'0.17, 0.14, 0.10, 0.35')
    for i, x in enumerate([-52,-26,0,26,52]):
        barrier += polygon(f'Spike{i}','.',[(x-8,0),(x-10,-50),(x-4,-72),(x+4,-50),(x+8,0)],'0.35, 0.22, 0.12, 1')
        barrier += line(f'Edge{i}','.',[(x-4,-61),(x-4,-8)],'0.79, 0.62, 0.35, 1',2)
    barrier += line('Beam','.',[(-70,-34),(70,-34)],'0.49, 0.30, 0.15, 1',12)
    barrier += line('BeamLight','.',[(-68,-38),(68,-38)],'0.84, 0.66, 0.36, 1',3)
    barrier += line('BraceLeft','.',[(-60,-4),(-20,-61)],'0.54, 0.34, 0.18, 1',7)
    barrier += line('BraceRight','.',[(60,-4),(20,-61)],'0.54, 0.34, 0.18, 1',7)
    (ROOT/'luoyang_barricade.tscn').write_text(barrier)

    arrow = '[gd_scene format=3]\n\n[node name="Arrow" type="Node2D"]\n'
    arrow += polygon('Ground','.',[(-10,0),(0,-4),(10,0),(0,4)],'0.12, 0.12, 0.09, 0.5')
    arrow += line('Shaft','.',[(0,-97),(0,-45)],'0.96, 0.86, 0.58, 1',4)
    arrow += polygon('Head','.',[(0,-37),(-9,-54),(0,-50),(9,-54)],'0.98, 0.94, 0.79, 1')
    arrow += '\n[node name="Target" type="Node2D" parent="."]\nz_index = 220\n'
    arrow += line('Outline','Target',[(-86,-6),(-69,-27),(69,-27),(86,-6),(-86,-6)],'1, 1, 1, 1',3)
    arrow += polygon('Direction','Target',[(-9,15),(0,23),(9,15),(0,18)],'1, 1, 1, 1')
    (ROOT/'luoyang_arrow.tscn').write_text(arrow)

    scene = '''[gd_scene load_steps=10 format=3]

[ext_resource type="Script" path="res://scripts/luoyang_prototype.gd" id="controller"]
[ext_resource type="Script" path="res://scripts/luoyang_road.gd" id="road"]
[ext_resource type="PackedScene" path="res://scenes/prototypes/luoyang_rider.tscn" id="rider"]
[ext_resource type="Texture2D" path="res://assets/luoyang-prototype/luoyang-gatehouse.png" id="gate"]
[ext_resource type="FontFile" path="res://assets/ui/wuxia-kai.otf" id="font"]

[sub_resource type="StyleBoxFlat" id="button"]
bg_color = Color(0.16, 0.24, 0.19, 1)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.56, 0.49, 0.30, 1)
corner_radius_top_left = 3
corner_radius_top_right = 3
corner_radius_bottom_left = 3
corner_radius_bottom_right = 3

[sub_resource type="StyleBoxFlat" id="hover"]
bg_color = Color(0.27, 0.35, 0.24, 1)
border_width_left = 2
border_width_top = 2
border_width_right = 2
border_width_bottom = 2
border_color = Color(0.88, 0.73, 0.40, 1)

[sub_resource type="StyleBoxFlat" id="panel"]
bg_color = Color(0.065, 0.11, 0.09, 0.98)
border_width_left = 1
border_width_top = 1
border_width_right = 1
border_width_bottom = 1
border_color = Color(0.57, 0.48, 0.28, 1)

[sub_resource type="Theme" id="theme"]
default_font = ExtResource("font")
default_font_size = 20
Button/styles/normal = SubResource("button")
Button/styles/hover = SubResource("hover")
Button/styles/pressed = SubResource("hover")
Button/styles/focus = SubResource("hover")
Button/colors/font_color = Color(0.95, 0.89, 0.73, 1)
Button/colors/font_hover_color = Color(1, 0.95, 0.81, 1)
Button/colors/font_focus_color = Color(1, 0.95, 0.81, 1)
Label/colors/font_color = Color(0.95, 0.89, 0.73, 1)
CheckButton/colors/font_color = Color(0.82, 0.81, 0.69, 1)

[node name="LuoyangPrototype" type="Node2D"]
texture_filter = 1
script = ExtResource("controller")
'''
    scene += polygon('Sky','.',[(0,0),(960,0),(960,540),(0,540)],'0.80, 0.77, 0.60, 1')
    scene += polygon('Mountains','.',[(0,153),(80,116),(146,146),(230,103),(341,159),(430,127),(550,155),(641,108),(751,148),(860,104),(960,148),(960,300),(0,300)],'0.39, 0.47, 0.38, 1')
    scene += polygon('Hills','.',[(0,188),(107,156),(195,186),(290,156),(410,178),(520,163),(650,181),(741,157),(865,187),(960,169),(960,540),(0,540)],'0.43, 0.48, 0.32, 1')
    scene += '\n[node name="Road" type="Node2D" parent="."]\nscript = ExtResource("road")\n'
    scene += polygon('Shoulder','Road',[(420,174),(540,174),(1120,540),(-160,540)],'0.67, 0.56, 0.34, 1')
    scene += polygon('Ground','Road',[(434,174),(526,174),(1060,540),(-100,540)],'0.73, 0.62, 0.41, 1')
    scene += polygon('CenterShade','Road',[(464,174),(496,174),(674,540),(286,540)],'0.70, 0.58, 0.37, 1')
    scene += line('LeftRut','Road',[(447,174),(75,540)],'0.64, 0.52, 0.31, 0.5',4)
    scene += line('RightRut','Road',[(513,174),(885,540)],'0.64, 0.52, 0.31, 0.5',4)
    scene += '''
[node name="Horizon" type="Marker2D" parent="Road"]
position = Vector2(480, 150)

[node name="PlayerLine" type="Marker2D" parent="Road"]
position = Vector2(480, 470)

[node name="LaneEdge" type="Marker2D" parent="Road"]
position = Vector2(710, 470)

[node name="Marks" type="Node2D" parent="Road"]
'''
    for i in range(18):
        # Authored visible markers can be selected in the editor before runtime.
        depth = (i//2)*10.0
        t = 1/(1+depth/18)
        t2 = 1/(1+(depth+3.2)/18)
        side = -0.5 if i%2 == 0 else 0.5
        scene += line(f'Track{i}','Road/Marks',[(round(480+side*230*t,2),round(150+320*t,2)),(round(480+side*230*t2,2),round(150+320*t2,2))],'0.88, 0.76, 0.51, 0.65',2)
    scene += '\n[node name="Flags" type="Node2D" parent="Road"]\n'
    for i in range(8):
        depth = i//2*22.5
        t = 1/(1+depth/18)
        side = -1.9 if i%2 == 0 else 1.9
        scene += f'\n[node name="Flag{i}" type="Node2D" parent="Road/Flags"]\nposition = Vector2({480+side*230*t}, {150+320*t})\nscale = Vector2({t}, {t})\n'
        scene += line('Pole',f'Road/Flags/Flag{i}',[(0,0),(0,-130)],'0.24, 0.22, 0.14, 1',4)
        scene += polygon('Cloth',f'Road/Flags/Flag{i}',[(0,-128),(40,-123),(34,-88),(0,-92)],'0.49, 0.16, 0.12, 1')
        scene += polygon('Emblem',f'Road/Flags/Flag{i}',[(12,-114),(21,-120),(29,-109),(21,-100)],'0.74, 0.59, 0.31, 1')
    scene += '''
[node name="World" type="Node2D" parent="."]

[node name="Gate" type="Sprite2D" parent="World"]
position = Vector2(480, 159)
scale = Vector2(0.12, 0.12)
texture = ExtResource("gate")

[node name="Archer" type="Node2D" parent="World"]
visible = false
position = Vector2(409, 192)
scale = Vector2(0.62, 0.62)
'''
    scene += polygon('Body','World/Archer',[(-10,0),(-12,-23),(12,-23),(10,0)],'0.23, 0.24, 0.18, 1')
    scene += polygon('Head','World/Archer',[(-6,-25),(-7,-36),(7,-36),(6,-25)],'0.80, 0.60, 0.33, 1')
    scene += line('Bow','World/Archer',[(19,-40),(27,-29),(29,-18),(24,-7),(17,0)],'0.74, 0.48, 0.19, 1',4)
    scene += line('String','World/Archer',[(19,-40),(17,0)],'0.94, 0.82, 0.54, 1',1)
    scene += '''
[node name="Rider" parent="World" instance=ExtResource("rider")]
z_index = 110
position = Vector2(480, 470)

[node name="Cue" type="AudioStreamPlayer" parent="."]

[node name="UI" type="CanvasLayer" parent="."]

[node name="Header" type="ColorRect" parent="UI"]
offset_right = 960.0
offset_bottom = 78.0
mouse_filter = 2
color = Color(0.06, 0.11, 0.085, 0.97)
'''
    # CanvasLayer cannot carry a Theme; assign it to every root Control.
    scene += label('Title','UI',(24,7,310,37),'洛阳 · 操作原型',24)
    scene += label('Stage','UI',(24,39,360,69),'拒马 · 看路换道',19)
    scene += label('Health','UI',(366,9,685,65),'气血  ● ● ● ●',24)
    scene += button('Sound','UI',(724,16,824,57),'声音 开',0)
    scene += button('Pause','UI',(840,16,936,57),'暂停',0)
    scene += '''
[node name="Progress" type="ProgressBar" parent="UI"]
offset_top = 76.0
offset_right = 960.0
offset_bottom = 81.0
mouse_filter = 2
show_percentage = false

[node name="Footer" type="ColorRect" parent="UI"]
offset_top = 504.0
offset_right = 960.0
offset_bottom = 540.0
mouse_filter = 2
color = Color(0.06, 0.11, 0.085, 0.96)
'''
    scene += label('Keys','UI',(20,505,940,539),'A / D 或 ← / → 换道    P 暂停    R 重试',19,1)
    scene += '''
[node name="WarningBacking" type="ColorRect" parent="UI"]
visible = false
offset_left = 314.0
offset_top = 87.0
offset_right = 646.0
offset_bottom = 123.0
mouse_filter = 2
color = Color(0.06, 0.11, 0.085, 0.94)
'''
    scene += label('Warning','UI',(314,85,646,124),'',24,1)
    scene += '''
[node name="HitFlash" type="ColorRect" parent="UI"]
offset_top = 81.0
offset_right = 960.0
offset_bottom = 504.0
mouse_filter = 2
color = Color(0.8, 0.12, 0.05, 0)

[node name="Overlay" type="Control" parent="UI"]
offset_right = 960.0
offset_bottom = 540.0
mouse_filter = 0

[node name="Shade" type="ColorRect" parent="UI/Overlay"]
offset_right = 960.0
offset_bottom = 540.0
mouse_filter = 2
color = Color(0.015, 0.025, 0.02, 0.55)

[node name="Panel" type="Panel" parent="UI/Overlay"]
offset_left = 240.0
offset_top = 90.0
offset_right = 720.0
offset_bottom = 466.0
theme_override_styles/panel = SubResource("panel")
'''
    scene += label('Title','UI/Overlay/Panel',(20,14,460,59),'洛阳 · 三车道试跑',30,1)
    scene += label('Description','UI/Overlay/Panel',(20,65,460,128),'左右换道，绕开拒马。\\n箭路锁定后，再换道闪开。',22,1)
    scene += button('First','UI/Overlay/Panel',(98,143,382,190),'连续试跑')
    scene += button('Second','UI/Overlay/Panel',(98,204,382,251),'拒马练习')
    scene += button('Third','UI/Overlay/Panel',(98,265,382,312),'箭矢练习')
    scene += '''
[node name="Motion" type="CheckButton" parent="UI/Overlay/Panel"]
offset_left = 266.0
offset_top = 327.0
offset_right = 458.0
offset_bottom = 366.0
text = "减少动态"
'''
    scene += label('Prototype','UI/Overlay/Panel',(24,331,263,363),'几何占位 · 不计旅程进度',16)
    # Set the shared full Kai font on all top-level Controls and the overlay.
    import re
    scene = re.sub(r'(\[node[^\n]+type="(?:Label|Button|ProgressBar|Control|ColorRect)" parent="UI"\]\n)',r'\1theme = SubResource("theme")\n',scene)
    (ROOT/'luoyang_prototype.tscn').write_text(scene)
    print('Authored 4 editable blockout scenes in', ROOT)


if __name__ == '__main__':
    build()
