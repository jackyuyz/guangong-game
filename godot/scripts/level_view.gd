extends Node2D
## Scene-authored transforms are captured once, then used as spawn positions.
@onready var player: Node2D = $Player
@onready var player_origin = player.position
@onready var boss_origin = $Boss.position
@onready var boss_player_origin = $BossPlayerSpawn.position
@onready var backdrop_origin = $Backdrop.position
@onready var wave_one: Array = $Guards/WaveOne.get_children()
@onready var wave_two: Array = $Guards/WaveTwo.get_children()
@onready var guard_views: Array = wave_one + wave_two
var authored_waves: Dictionary = {}

func _ready() -> void:
	for wave in [1, 2]:
		var views: Array = wave_one if wave == 1 else wave_two
		authored_waves[wave] = views.map(func(view): return view.position.x)

func wave_positions(wave: int) -> Array:
	return authored_waves[wave]

func present(game: Node) -> void:
	$Camera.position.x = game.camera_x + 480
	$Backdrop.position.x = backdrop_origin.x + game.camera_x * 0.92 + sin(game.clock * 65) * game.shake
	$Training/Flag.visible = game.phase <= 1
	$Training/Dummy.visible = game.phase <= 2
	$Companions.visible = game.camera_x < 350
	$RetreatGuards.visible = game.phase == 7
	player.position.x = game.x
	var moving = game.state == "play" and (Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_RIGHT))
	var bob = sin(game.clock * 15) * 2.3 if moving else sin(game.clock * 2) * 0.7
	var tint = Color(1, 1, 1, 0.35) if game.invincible > 0 and int(game.clock * 18) % 2 == 0 else Color.WHITE
	var tilt: float = game.facing * (0.16 if game.dodge_time > 0 else (-0.10 if game.attack_time > 0 else 0.0))
	player.pose(game.facing, tint, tilt, bob)
	var motion = "idle"
	if game.ext.heavy_time > 0 or game.attack_time > 0:
		motion = "attack"
	elif game.ext.is_guarding():
		motion = "guard"
	elif game.invincible > 0 and game.dodge_time <= 0:
		motion = "hurt"
	elif moving or game.dodge_time > 0:
		motion = "walk"
	player.animate(motion)
	$RestPoint.visible = game.phase in [4, 5]
	$RestPoint/Hint.text = "已歇脚" if game.ext.rest_used else "E  茶摊歇脚"
	$RestPoint.modulate.a = 0.5 if game.ext.rest_used else 1.0
	for view in guard_views:
		view.hide()
	$Boss.hide()
	var index = 0
	for enemy in game.enemies:
		if enemy.hp <= 0:
			continue
		var view: Node2D = $Boss if enemy.boss else guard_views[index]
		if not enemy.boss:
			index += 1
		view.show()
		view.present_enemy(enemy, game.x)
	$Effects.game = game
	$Effects.queue_redraw()
