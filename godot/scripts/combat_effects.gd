extends Node2D
## Only transient effects remain procedural; level, actors and UI are real nodes.
var game: Node
const GOLD = Color("dfbc76")
const FONT = preload("res://assets/ui/wuxia-reading-font.ttf")
const TRAIL = preload("res://assets/guan-yu.png")

func _draw() -> void:
	if game == null:
		return
	var ground: float = game.player_y
	if game.dodge_time > 0:
		for i in 3:
			draw_set_transform(Vector2(game.x - game.facing * (i + 1) * 20, ground), 0, Vector2(game.facing, 1))
			draw_texture_rect_region(TRAIL, Rect2(-42, -143, 84, 143), Rect2(24, 8, 47, 80), Color(0.55, 0.85, 0.7, 0.12))
		draw_set_transform(Vector2.ZERO)
	if game.attack_time > 0:
		var arc_center = Vector2(game.x + game.facing * 30, ground - 63)
		var angle = -1.3 if game.facing > 0 else PI - 1.3
		var width = 10.0 if game.combo == 3 else 6.0
		var opacity = minf(1, game.attack_time * 3.0)
		# Inner glow stays inside the existing outer silhouette: same readable reach.
		draw_arc(arc_center, 94, angle, angle + 2.6, 32, Color(0.89, 0.66, 0.24, opacity * 0.18), width + 8, true)
		draw_arc(arc_center, 98, angle, angle + 2.6, 25, Color(0.94, 0.90, 0.64, game.attack_time * 3.0), 10 if game.combo == 3 else 6, true)
		draw_arc(arc_center, 82, angle + 0.2, angle + 2.4, 25, Color(0.51, 0.90, 0.72, game.attack_time * 3.0), 3, true)
		draw_arc(arc_center, 97, angle + 0.08, angle + 2.52, 32, Color(1, 0.99, 0.87, opacity * 0.8), 1.4, true)
		_blade_accents(arc_center, 92, angle, 2.6, (game.ATTACK_TIME - game.attack_time) / game.ATTACK_TIME, opacity)
	if game.ext.heavy_time > 0:
		var center = Vector2(game.x + game.facing * 43, ground - 70)
		var start = -1.25 if game.facing > 0 else PI - 1.25
		var opacity = minf(1.0, game.ext.heavy_time * 4.0)
		draw_arc(center, 138, start, start + 2.5, 40, Color(0.98, 0.72, 0.26, opacity * 0.18), 24, true)
		draw_arc(center, 145, start, start + 2.5, 32, Color(0.98, 0.85, 0.46, opacity), 11, true)
		draw_arc(center, 128, start + 0.15, start + 2.35, 32, Color(0.63, 0.96, 0.77, opacity), 4, true)
		draw_arc(center, 144, start + 0.07, start + 2.43, 40, Color(1, 0.98, 0.82, opacity * 0.9), 2.0, true)
		_blade_accents(center, 137, start, 2.5, (game.ext.HEAVY_TIME - game.ext.heavy_time) / game.ext.HEAVY_TIME, opacity)
	for p in game.particles:
		draw_rect(Rect2(p.pos, Vector2(3, 3)), Color(p.color, p.life * 2))
	for f in game.floaters:
		draw_string(FONT, Vector2(f.x, f.y), f.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(GOLD, minf(1, f.life * 3)))
	for i in 22:
		var pos = Vector2(game.camera_x + fposmod(i * 97.0 + game.clock * (7 + i % 5), 980), 100 + fposmod(i * 59.0 + sin(game.clock + i) * 10, 300))
		draw_circle(pos, 1.2, Color(0.95, 0.83, 0.5, 0.3))

func _blade_accents(center: Vector2, radius: float, start: float, span: float, progress: float, opacity: float) -> void:
	if game.reduced_motion: return
	for i in 4:
		var part = clampf(progress * 0.72 + i * 0.085, 0.03, 0.96)
		var angle = start + span * part
		var radial = Vector2(cos(angle), sin(angle))
		var tangent = Vector2(-radial.y, radial.x)
		var at = center + radial * (radius - i * 3)
		draw_line(at - tangent * (3 + i), at, Color(1, 0.93, 0.65, opacity * (0.72 - i * 0.12)), 1.3, true)
