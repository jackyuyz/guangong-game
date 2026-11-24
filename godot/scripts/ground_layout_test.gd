extends SceneTree
## Spatial integration checks with a disposable session, never a player's save.
var failures = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "/tmp/guangong-ground-%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	game.set_process(false)
	game.window_active = true
	game.muted = true
	game.state = "play"
	game.phase = 3
	var level = game.level
	var gate = level.get_node("Ground/Structures/Gate")
	var road = level.get_node("Ground/Road")
	var gate_start: Vector2 = gate.global_position
	var road_start: Vector2 = road.global_position
	var scenery_start: Vector2 = level.get_node("Backdrop").position
	check(level.world_left == 0 and level.world_right == 3000, "the authored three-screen road retains its world limits")
	check(road.region_rect.size.x * road.scale.x >= level.world_right and road.texture_repeat == CanvasItem.TEXTURE_REPEAT_MIRROR, "mirrored terrain covers the whole world without an empty seam")
	check(road.position.y < level.player_origin.y and road.position.y + road.texture.get_height() * road.scale.y > 540, "feet and the bottom viewport stay inside real terrain")
	check(gate.position.x > 2400 and gate.position.y + gate.texture.get_height() * gate.scale.y < level.player_origin.y, "the single endpoint gate stays behind the actor foot line")
	check(level.rest_origin.y < level.player_origin.y - 30, "the tea stall occupies the rear shoulder")
	var origins = [level.player_origin, level.boss_origin, level.boss_player_origin, level.wave_retry_origin, level.flag_origin, level.dummy_origin]
	for wave in [1, 2]:
		for spawn in level.wave_spawns(wave): origins.append(spawn.origin)
	check(origins.all(func(origin): return origin.y == level.player_origin.y), "all combat and retry feet share the authored road baseline")
	for camera in [0.0, 500.0, 1020.0, 1550.0, 2040.0, 0.0]:
		game.camera_x = camera
		game._sync_scene()
		check(gate.global_position == gate_start and road.global_position == road_start and is_equal_approx(level.get_node("Backdrop").position.x, scenery_start.x + camera * 0.8), "camera %d keeps road and gate fixed while only mountains parallax" % camera)
	game._spawn_wave(1)
	game.enemies.clear()
	game._update_play(0.01)
	check(game.phase == 4 and game.enemies.size() == 3, "second wave still binds three separate authored actors")
	game.enemies.clear()
	game.x = level.rest_origin.x
	game.hp = 3
	check(game.ext.can_rest(game), "rear-shoulder tea remains reachable from the road")
	var key = InputEventKey.new()
	key.physical_keycode = KEY_E
	key.pressed = true
	game._unhandled_input(key)
	check(game.hp == 4 and game.ext.rest_used and game.ext.resource == 4, "tea interaction still heals once and fills qi")
	game.x = level.gate_x + 1
	game._update_play(0.01)
	check(game.phase == 5 and game.state == "dialogue", "world gate trigger still enters the boss introduction")
	game._finish_dialogue()
	check(game.phase == 6 and game.x == level.boss_player_origin.x and game.player_y == level.player_origin.y, "boss introduction places actors on the same road")
	var boss: Dictionary = game.enemies[0]
	boss.mode = "strike"
	boss.move = 1
	boss.timer = 0.2
	boss.facing = 1.0
	boss.x = level.world_right - 81
	game.invincible = 2
	game._update_enemy(boss, 0.2)
	check(boss.x == level.world_right - 80, "boss thrust cannot leave the road at its right boundary")
	boss.mode = "strike"
	boss.timer = 0.2
	boss.facing = -1.0
	boss.x = level.arena_min_x + 1
	game._update_enemy(boss, 0.2)
	check(boss.x == level.arena_min_x, "boss thrust respects the left arena marker")
	game.hp = 1
	game.invincible = 0
	game._hurt(1)
	game._retry()
	check(game.x == level.boss_player_origin.x and game.hp == 4 and game.ext.resource == 4 and game.enemies[0].x == level.boss_origin.x, "failed boss retry restores the checkpoint and authored road spawns")
	game.state = "pause"
	game.resume_state = "play"
	game._sync_scene()
	var paused_camera = level.get_node("Camera").position
	game._process(0.2)
	check(level.get_node("Camera").position == paused_camera and level.get_node("Backdrop").position == scenery_start + Vector2(game.camera_x * 0.8, 0), "pause holds camera and scenery together")
	game.state = "map"
	game._sync_scene()
	check(not level.get_node("Ground").visible and not level.get_node("Ground/Foreground").is_visible_in_tree(), "map hides both world props and foreground")
	check(not FileAccess.file_exists(game.save_path), "layout checks never write player progress")
	game.queue_free()
	await process_frame
	print("GROUND LAYOUT CHECKS COMPLETE; failures=", failures)
	quit(1 if failures else 0)
