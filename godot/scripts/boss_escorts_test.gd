extends SceneTree
## Real first-chapter encounter, checkpoint and lethal-contact regressions.
var game: Node
var checks = 0
var failures = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if ok:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func prepare() -> void:
	game._reset_run()
	game.state = "play"
	game.phase = 4
	game.ext.update(game, 0.0) # As in the pre-boss road: discard any prior run's qi snapshot.
	game.hp = 4
	game.combat_seconds = 20.0
	game.hits = 2
	game.ext.resource = 3
	game._enter_boss()
	game._sync_scene()

func step(seconds: float) -> void:
	for i in ceili(seconds * 100):
		game._process(0.01)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "/tmp/guangong-boss-escorts-%d.cfg" % Time.get_ticks_usec()
	# Scene edits must remain the source of truth for all three spawn positions.
	game.get_node("Level/Ground/BossGuards").position.x = -10
	game.get_node("Level/Ground/BossGuards/RightGuard").scale = Vector2(1.1, 1.1)
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.window_active = true
	game.phase = 5
	game._begin_dialogue(game.story.boss, "play")
	game._sync_scene()
	var left: Node2D = game.level.boss_guards[0]
	var right: Node2D = game.level.boss_guards[1]
	check(not left.visible and not right.visible and game.enemies.is_empty(), "escorts remain absent throughout the introduction")
	game._action("skip")
	game._sync_scene()
	check(game.enemies.size() == 3 and game.enemies[0].boss, "dialogue ends with one boss and exactly two escorts, boss first")
	check(left.visible and right.visible and game.level.boss.visible, "all three authored combat actors appear together")
	var boss: Dictionary = game.enemies[0]
	var a: Dictionary = game.enemies[1]
	var b: Dictionary = game.enemies[2]
	check(a.x < boss.x and b.x > boss.x and a.y == boss.y and b.y == boss.y, "one escort stands on either side of Kong Xiu on the road")
	check(a.x == left.global_position.x and b.x == right.global_position.x and b.x == 2900 and right.scale == Vector2(1.1, 1.1), "authored parent offset and actor scale survive spawning")
	check(a.hp == 2 and b.hp == 2 and not a.boss and not b.boss and boss.hp == 16, "escorts reuse ordinary guard strength without changing boss health")
	check(a.x >= game.level.arena_min_x and b.x <= game.level.world_right - 80, "both escorts start inside the playable arena")
	game._action("skip")
	game._action("next")
	check(game.enemies.size() == 3, "stale dialogue actions cannot duplicate the formation")
	prepare()
	var before: float = game.enemies[1].x
	game._update_play(0.04)
	check(game.enemies[1].x < before, "escort advances using the existing guard AI")
	game.x = game.enemies[1].x - 90
	var guard: Dictionary = game.enemies[1]
	guard.mode = "strike"
	guard.timer = 0.16
	guard.facing = -1.0
	guard.move = 1
	game._update_enemy(guard, 0.01)
	check(game.hp == 3 and game.hits == 3, "escort can damage the player with real spear contact")
	game._sync_scene()
	check(left.get_node("Telegraph").visible and left.get_node("AttackHint").text == "突刺", "escort uses the existing guard range warning")
	var held: float = guard.timer
	game._action("pause_click")
	step(0.3)
	check(guard.timer == held and game.hp == 3, "pause freezes escorts and their attacks")
	game._action("resume")
	guard.hp = 0
	game._update_play(0.01)
	game._sync_scene()
	check(game.enemies.size() == 2 and not left.visible and right.visible and game.enemies[1].view == right, "defeated escort hides without rebinding its surviving neighbor")
	game.hp = 1
	game.ext.resource = 0
	game.hits = 9
	game.combat_seconds = 45
	game._retry()
	game._sync_scene()
	check(game.enemies.size() == 3 and game.enemies[1].hp == 2 and game.enemies[2].hp == 2 and left.visible and right.visible, "boss retry restores both fresh escorts exactly once")
	check(game.hp == 4 and game.hits == 2 and game.combat_seconds == 20 and game.ext.resource == 3 and game.retries == 1, "retry restores the original checkpoint stats and qi")
	# All three try to start a tell at once: retain the existing two-attacker cap.
	for e in game.enemies:
		e.x = game.x + 80
		e.timer = 0
		e.mode = "approach"
	for e in game.enemies:
		game._update_enemy(e, 0.01)
	check(game.enemies.filter(func(e): return e.mode == "windup").size() == 2, "three combatants retain the maximum of two simultaneous windups")
	for heavy in [false, true]:
		prepare()
		boss = game.enemies[0]
		game.x = boss.x - 90
		game.facing = 1
		game.hp = 1
		boss.hp = 3 if heavy else 1
		for e in game.enemies:
			e.mode = "strike"
			e.timer = 0.16
			e.facing = -1
			e.struck = false
		for e in game.enemies.slice(1):
			e.x = game.x + 60
		if heavy:
			game.ext.resource = 4
			game.ext.handle_key(game, KEY_L)
			game.ext.heavy_time = game.ext.HEAVY_TIME - game.ext.HEAVY_CONTACT + 0.005
		else:
			game.attack_time = game.ATTACK_TIME - game.ATTACK_CONTACT + 0.005
			game.swing_id += 1
		game._update_play(0.01)
		game._sync_scene()
		var label = "L" if heavy else "J"
		check(game.state == "finishing" and game.hp == 1 and game.enemies.is_empty(), label + " lethal boss contact cancels both escorts before damage")
		check(not left.visible and not right.visible and not left.get_node("Telegraph").is_visible_in_tree(), label + " escorts and warnings leave the finishing stage")
		step(2.0)
		check(game.state == "dialogue" and game.dialogue == game.story.ending, label + " full final strike still leads to ending dialogue")
	prepare()
	game._reset_run()
	game._sync_scene()
	check(game.enemies.is_empty() and not left.visible and not right.visible, "new run removes escorts until the next boss encounter")
	print("BOSS ESCORT CHECKS: ", checks, "; failures: ", failures)
	game.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	quit(1 if failures else 0)
