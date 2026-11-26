extends SceneTree
## Tutorial movement, camera, and enemy release share the authored boundary.
var game: Node
var failures = 0
var checks = 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func key(code: int) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	game._unhandled_input(event)

func step(seconds: float) -> void:
	for i in ceili(seconds * 100): game._process(.01)

func guards_hidden() -> bool:
	for actor in game.level.guard_views:
		if actor.visible: return false
	return not game.level.boss.visible

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "/tmp/guangong-tutorial-boundary-%d.cfg" % Time.get_ticks_usec()
	game.get_node("Level/Ground").position.x = 120
	game.get_node("Level/Ground/Training/Exit").position.x = 1120
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game._reset_run()
	game.state = "play"
	game.phase = 0
	game.window_active = true
	var edge: float = game.level.training_exit_x
	var wall: float = edge - 80
	var target_stop: float = game.level.dummy_origin.x - 95
	var camera_end: float = maxf(game.level.world_left, edge - game.VIEWPORT_WIDTH)
	check(edge == 1240, "boundary follows the authored marker and relocated ground")
	game.x = edge + 600
	game.camera_x = edge + 500
	step(.01)
	check(game.phase == 1 and game.x == target_stop, "intact target stops the player within real slash range")
	check(game.camera_x <= camera_end, "camera cannot look past the tutorial boundary")
	check(game.enemies.is_empty() and guards_hidden(), "all guard and boss actors stay absent before practice")
	game.facing = 1
	key(KEY_SPACE)
	step(.4)
	check(game.phase == 1 and game.x == target_stop and not game.tutorial_forward_dodge, "early dodge cannot pass the target or pre-complete the final lesson")
	check(game.enemies.is_empty() and guards_hidden(), "early dodge never spawns visible guards")
	step(.5)
	game.x = game.level.dummy_origin.x - 90
	key(KEY_J)
	step(.1)
	check(game.get_meta("dummy_hits") == 1 and game.phase == 1, "first real hit leaves the tutorial gate locked")
	step(.4)
	key(KEY_J)
	step(.1)
	check(game.get_meta("dummy_hits") == 2 and game.phase == 2, "second real hit enables only the dodge lesson")
	step(.4)
	check(game.enemies.is_empty() and guards_hidden(), "destroying the target alone does not release guards")
	check(game._clamp_player_x(wall + 200) == wall, "broken target opens the short practice road but keeps the outer wall")
	check(game.ui.get_node("Root/HUD/ObjectivePanel/Objective").text == "向右闪避", "current objective explains the required dodge direction")
	game.facing = -1
	key(KEY_SPACE)
	step(.4)
	check(game.phase == 2 and game.enemies.is_empty(), "a completed backward dodge cannot unlock the road")
	step(.5)
	game.facing = 1
	key(KEY_SPACE)
	step(.1)
	check(game.phase == 2 and game.tutorial_forward_dodge and game.enemies.is_empty() and guards_hidden(), "forward dodge windup stays inside the tutorial with no guards")
	var held_x: float = game.x
	var held_time: float = game.dodge_time
	key(KEY_P)
	step(.5)
	check(game.x == held_x and game.dodge_time == held_time and game.tutorial_forward_dodge, "pause freezes a pending forward dodge and its boundary")
	check(game.enemies.is_empty() and guards_hidden(), "pause cannot release the waiting guards")
	key(KEY_P)
	game._pause_for_focus_loss()
	step(.5)
	check(game.x == held_x and game.dodge_time == held_time and game.phase == 2, "focus loss also holds the lesson before completion")
	game.window_active = true
	key(KEY_P)
	step(.15)
	check(game.phase == 2 and game.enemies.is_empty(), "returning does not skip the remaining dodge animation")
	step(.15)
	check(game.phase == 2 and game.dodge_time == 0 and game.tutorial_dodge_completed, "completed forward dodge unlocks the approach road")
	check(not game.tutorial_forward_dodge and game.enemies.is_empty() and guards_hidden(), "finishing the lesson does not spawn enemies before the encounter marker")
	check(game.ui.get_node("Root/HUD/Controls/Hint/Content/Action").text == "前行", "unlocked approach shows movement rather than repeating dodge practice")
	check(game._clamp_player_x(wall + 200) == wall + 200, "completed lesson removes the temporary movement boundary")
	game.x = wall + 20
	step(.2)
	check(game.camera_x > camera_end, "camera can follow into the battle area after completion")
	check(game.phase == 2 and game.enemies.is_empty(), "walking short of the encounter keeps the next enemies hidden")
	game.x = game.level.training_encounter_x
	step(.01)
	check(game.phase == 3 and game.enemies.size() == 2, "crossing the encounter after the lesson releases exactly the first wave")
	check(game.enemies[0].x > game.camera_x + game.VIEWPORT_WIDTH and game.enemies[0].x > game.x, "first guards enter from offscreen right instead of spawning behind the player")
	game.state = "dead"
	game._retry()
	check(game.phase == 3 and game.enemies.size() == 2 and game.get_meta("dummy_hits") == 2, "wave retry preserves completed teaching without restoring the wall")
	game._reset_run()
	game.phase = 0
	game.state = "play"
	game.x = edge + 400
	step(.01)
	check(game.x == target_stop and game.enemies.is_empty() and not game.tutorial_forward_dodge and not game.tutorial_dodge_completed, "new run restores the target stop and clears completion")
	check(not FileAccess.file_exists(game.save_path), "tutorial checks never write player progress")
	game.queue_free()
	await process_frame
	print("TUTORIAL BOUNDARY CHECKS: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)
