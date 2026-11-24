extends Node2D
## Artwork, shadow and warnings are authored in the reusable actor scene.
@export var native_facing = 1.0
@onready var visual: Node2D = $Visual
@onready var sprite: AnimatedSprite2D = $Visual/Sprite
@onready var rest_rotation = visual.rotation
@onready var rest_y = visual.position.y
@onready var animation_speed = sprite.speed_scale
@onready var rest_tint = sprite.modulate
@onready var hint_origin: Vector2 = $AttackHint.position if has_node("AttackHint") else Vector2.ZERO

func pose(direction: float, tint: Color = Color.WHITE, tilt: float = 0.0, bob: float = 0.0) -> void:
	sprite.flip_h = direction != native_facing
	sprite.modulate = rest_tint * tint
	visual.rotation = rest_rotation + tilt
	visual.position.y = rest_y + bob

func present_enemy(enemy: Dictionary, player_x: float, frozen: bool) -> void:
	var windup: bool = enemy.mode == "windup"
	var attacking: bool = windup or enemy.mode == "strike"
	$Telegraph.visible = attacking
	$AttackHint.visible = attacking
	$Health.visible = not enemy.boss
	$Health.max_value = enemy.max_hp
	$Health.value = enemy.hp
	var reach = 190.0 if enemy.boss else 120.0
	var sweep: bool = enemy.boss and enemy.move % 2 == 0
	$Telegraph.present(enemy.facing, reach, sweep, enemy.mode == "strike")
	$AttackHint.text = "横扫" if sweep else "突刺"
	$AttackHint.position.x = hint_origin.x if enemy.facing < 0 else -hint_origin.x - $AttackHint.size.x
	var tint = Color(1.8, 1.4, 0.9) if enemy.flash > 0 else Color.WHITE
	pose(enemy.facing, tint, -enemy.facing * 0.13 if windup else 0.0)
	var motion = "idle"
	if windup:
		motion = "windup"
	elif enemy.mode == "strike":
		motion = "attack"
	elif enemy.mode == "recover":
		motion = "recover"
	elif absf(enemy.x - player_x) > (145 if enemy.boss else 95):
		motion = "walk"
	animate(motion, frozen)

const FRAME_INDICES = {"idle": [0], "walk": [0, 1, 2, 3], "windup": [4], "attack": [5, 6, 7], "heavy": [5, 6, 7], "recover": [7], "guard": [4], "hurt": [7]}
@export var frame_baselines = PackedFloat32Array()
var original_offset = Vector2.ZERO

func _ready() -> void:
	original_offset = sprite.offset
	if sprite is AnimatedSprite2D:
		sprite.frame_changed.connect(_align_frame)
		sprite.animation_changed.connect(_align_frame)
		_align_frame()

func animate(animation: String, frozen: bool) -> void:
	if sprite.animation != animation:
		sprite.play(animation)
	sprite.speed_scale = 0.0 if frozen else animation_speed

func _align_frame() -> void:
	if frame_baselines.is_empty():
		return
	var indices: Array = FRAME_INDICES.get(str(sprite.animation), [0])
	var index: int = indices[mini(sprite.frame, indices.size() - 1)]
	sprite.offset.y = original_offset.y + frame_baselines[0] - frame_baselines[index]
