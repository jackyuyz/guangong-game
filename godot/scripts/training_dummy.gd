extends Node2D
## Three authored prop states. Hit count belongs to the tutorial, never to this view.
@onready var visual: Node2D = $Visual
@onready var sprite: AnimatedSprite2D = $Visual/States
@onready var visual_origin: Vector2 = visual.position
@onready var visual_rotation: float = visual.rotation
var damage_stage = 0
var impact_age = 1.0
var _last_hits = -1
var _active = false
var _reduced = false
const IMPACT_TIME = 0.22

func present(game: Node) -> void:
 var count = clampi(int(game.get_meta("dummy_hits", 0)), 0, 2)
 _active = game.state == "play" and game.window_active and game.hit_stop <= 0
 _reduced = game.reduced_motion
 if _last_hits >= 0 and count > _last_hits and game.state == "play":
  impact_age = 0.0
 elif count < _last_hits or _last_hits < 0:
  impact_age = IMPACT_TIME
 _last_hits = count
 damage_stage = count
 sprite.pause()
 sprite.frame = count
 var texture: Texture2D = sprite.sprite_frames.get_frame_texture("damage", count)
 sprite.offset = -Vector2(float(texture.get_meta("ground_anchor_x")), float(texture.get_meta("ground_baseline")))
 if _reduced: impact_age = IMPACT_TIME
 _paint()

func _process(dt: float) -> void:
 if not _active or impact_age >= IMPACT_TIME: return
 impact_age = minf(IMPACT_TIME, impact_age + dt)
 _paint()

func _paint() -> void:
 var weight = maxf(0, 1.0 - impact_age / IMPACT_TIME)
 visual.position = visual_origin + Vector2(sin(impact_age * 90.0) * weight * 3.0, 0)
 visual.rotation = visual_rotation + sin(impact_age * 60.0) * weight * 0.035
