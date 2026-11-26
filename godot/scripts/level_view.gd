extends Node2D
## Scene-authored transforms are captured once, then used as spawn positions.
@export_range(0.0, 1.0) var distant_scroll_ratio: float = 0.2
@onready var player: Node2D = $Ground/Player
@onready var player_origin = to_local(player.global_position)
@onready var boss: Node2D = $Ground/Boss
@onready var boss_origin = to_local(boss.global_position)
@onready var boss_player_origin = to_local($Ground/BossPlayerSpawn.global_position)
@onready var wave_retry_origin = to_local($Ground/WaveRetrySpawn.global_position)
@onready var flag_origin = to_local($Ground/Training/Flag.global_position)
@onready var dummy_origin = to_local($Ground/Training/Dummy.global_position)
@onready var dummy_hit_origin = to_local($Ground/Training/Dummy/HitOrigin.global_position)
@onready var training_exit_x: float = to_local($Ground/Training/Exit.global_position).x
@onready var training_encounter_x: float = to_local($Ground/Training/Encounter.global_position).x
@onready var rest_origin = to_local($Ground/RestPoint.global_position)
@onready var gate_x: float = to_local($Ground/GateTrigger.global_position).x
@onready var arena_min_x: float = to_local($Ground/ArenaLeft.global_position).x
@onready var ground_edge: Line2D = $Ground/Edge
@onready var world_left: float = to_local(ground_edge.to_global(ground_edge.points[0])).x
@onready var world_right: float = to_local(ground_edge.to_global(ground_edge.points[-1])).x
@onready var camera_offset: Vector2 = $Camera.offset
@onready var backdrop_origin = $Backdrop.position
@onready var wave_one: Array = $Ground/Guards/WaveOne.get_children()
@onready var wave_two: Array = $Ground/Guards/WaveTwo.get_children()
@onready var guard_views: Array = wave_one + wave_two
var authored_waves: Dictionary = {}

func _ready() -> void:
	for wave in [1, 2]:
		var views: Array = wave_one if wave == 1 else wave_two
		authored_waves[wave] = []
		for view in views:
			authored_waves[wave].append({"origin": to_local(view.global_position), "view": view})
	for guard in $Ground/RetreatGuards.get_children():
		guard.get_node("Health").hide()
		guard.pose(1.0)

func wave_spawns(wave: int) -> Array:
	return authored_waves[wave]

func present(game: Node) -> void:
	$Ground.visible = game.state not in ["menu", "map", "prologue"] and not (game.state in ["pause", "confirm"] and game.resume_state == "prologue")
	$Camera.position.x = game.camera_x + 480
	$Camera.offset.x = camera_offset.x + (0.0 if game.reduced_motion else sin(game.clock * 65) * game.shake)
	# Only distant scenery has parallax. Road, architecture and props share world coordinates.
	$Backdrop.position.x = backdrop_origin.x + (game.camera_x - world_left) * (1.0 - distant_scroll_ratio)
	$Ground/Training/Flag.visible = true
	$Ground/Training/Dummy.visible = true
	$Ground/Training/Dummy.present(game)
	$Ground/Companions.visible = game.camera_x < world_left + 350
	var effective_state: String = game.resume_state if game.state in ["pause", "confirm"] else game.state
	$Ground/RetreatGuards.visible = game.phase == 7 and effective_state != "finishing"
	player.global_position = to_global(Vector2(game.x, game.player_y))
	var moving: bool = game.moving
	var frozen: bool = game.state != "play" or game.hit_stop > 0
	var bob = sin(game.clock * 15) * 2.3 if moving else sin(game.clock * 2) * 0.7
	if game.ext.rest_feedback > 0 and not game.reduced_motion:
		bob -= sin((game.ext.REST_FEEDBACK_TIME - game.ext.rest_feedback) / game.ext.REST_FEEDBACK_TIME * PI) * 1.4
	var tint = Color(1, 1, 1, 0.35) if game.ext.heavy_time <= 0 and game.invincible > 0 and int(game.clock * 18) % 2 == 0 else Color.WHITE
	if game.ext.rest_feedback > 0: tint = Color.WHITE
	var tilt: float = game.facing * (0.16 if game.dodge_time > 0 else (-0.10 if game.attack_time > 0 else 0.0))
	player.pose(game.facing, tint, tilt, bob)
	var motion = "idle"
	if game.ext.heavy_time > 0:
		motion = "heavy"
	elif game.attack_time > 0:
		motion = "attack"
	elif game.ext.is_guarding():
		motion = "guard"
	elif game.invincible > 0 and game.dodge_time <= 0:
		motion = "hurt"
	elif moving or game.dodge_time > 0:
		motion = "walk"
	if game.ext.rest_feedback > 0: motion = "idle"
	player.animate(motion, frozen)
	if game.attack_time > 0:
		player.pose_at("attack", game.ATTACK_TIME - game.attack_time)
	if game.ext.heavy_time > 0:
		player.pose_at("heavy", game.ext.HEAVY_TIME - game.ext.heavy_time)
	if not game.defeated_boss.is_empty():
		player.pose(game.facing)
		if game.finish_elapsed >= game.finish_attack_left:
			var recovery_time: float = game.finish_elapsed - game.finish_attack_left
			player.pose_at("finish_recover" if recovery_time < player.animation_length("finish_recover") else "idle", recovery_time)
	if game.player_fallen:
		player.pose(game.death_facing, Color(1.4, 1.15, 0.9) if game.death_elapsed < 0.08 else Color.WHITE)
		player.pose_at("fall", game.death_elapsed)
	# The dialogue stage owns the large portraits; avoid duplicate small actors behind it.
	var ending_portrait: bool = effective_state == "dialogue" and game.phase == 7 and game.dialogue_after == "victory" and not game.dialogue.is_empty() and str(game.dialogue[game.dialogue_index][0]) == "关羽"
	player.visible = game.phase != 5 and not ending_portrait
	$Ground/RestPoint.present(game)
	$Ground/RestRecovery.present(game, player)
	for view in guard_views:
		view.hide()
	boss.hide()
	for enemy in game.enemies:
		if enemy.hp <= 0:
			continue
		var view: Node2D = enemy.view
		view.global_position = to_global(Vector2(enemy.x, enemy.y))
		view.show()
		view.present_enemy(enemy, game.x, frozen, Vector2(game._clamp_player_x(-1.0e20), game._clamp_player_x(1.0e20)))
		if game.player_fallen:
			view.get_node("Telegraph").hide()
			view.get_node("AttackHint").hide()
	if not game.defeated_boss.is_empty():
		var fallen: Dictionary = game.defeated_boss
		boss.global_position = to_global(Vector2(fallen.x, fallen.y))
		boss.show()
		boss.get_node("Telegraph").hide()
		boss.get_node("AttackHint").hide()
		boss.get_node("Health").hide()
		boss.pose(fallen.facing, Color(1.4, 1.15, 0.9) if game.finish_elapsed < 0.08 else Color.WHITE)
		boss.pose_at("fall", game.finish_elapsed)
	$Effects.game = game
	$Effects.queue_redraw()
