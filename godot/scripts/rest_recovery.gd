extends Node2D
## Short visual feedback follows the actual actor pose and the gameplay-owned timer.
var age = 0.0
var strength = 0.0

func present(game: Node, actor: Node2D) -> void:
	var remaining: float = game.ext.rest_feedback
	visible = remaining > 0 and not game.reduced_motion and game.state in ["play", "pause", "confirm"]
	age = game.ext.REST_FEEDBACK_TIME - remaining
	strength = sin(clampf(age / game.ext.REST_FEEDBACK_TIME, 0, 1) * PI)
	global_position = actor.global_position
	var source: AnimatedSprite2D = actor.sprite
	var frame: Texture2D = source.sprite_frames.get_frame_texture(source.animation, source.frame)
	$Silhouette.texture = frame
	$Silhouette.global_transform = source.global_transform
	$Silhouette.offset = source.offset
	$Silhouette.flip_h = source.flip_h
	$Silhouette.material.set_shader_parameter("strength", strength * .65)
	var rect = Vector4(0, 0, 1, 1)
	if frame is AtlasTexture:
		var size: Vector2 = frame.atlas.get_size()
		$Silhouette.material.set_shader_parameter("source_atlas", frame.atlas)
		$Silhouette.material.set_shader_parameter("atlas_pixel_size", Vector2.ONE / size)
		rect = Vector4(frame.region.position.x / size.x, frame.region.position.y / size.y, frame.region.size.x / size.x, frame.region.size.y / size.y)
	else:
		$Silhouette.material.set_shader_parameter("source_atlas", frame)
	$Silhouette.material.set_shader_parameter("frame_rect", rect)
	queue_redraw()

func _draw() -> void:
	if not visible or strength <= 0: return
	draw_set_transform(Vector2(0, -2), 0, Vector2(1, .22))
	draw_circle(Vector2.ZERO, 40 + age * 10, Color(.5, .84, .61, strength * .08))
	draw_arc(Vector2.ZERO, 35 + age * 18, 0, TAU, 48, Color(.8, .88, .57, strength * .4), 2, true)
	draw_set_transform(Vector2.ZERO)
	for i in 6:
		var rise = fposmod(age * 1.25 + float(i) / 6, 1)
		var side = -1 if i % 2 == 0 else 1
		var point = Vector2(side * (34 + sin(rise * PI) * 11), -12 - rise * 108)
		draw_circle(point, 1.3, Color(.83, .94, .67, strength * sin(rise * PI) * .75))
