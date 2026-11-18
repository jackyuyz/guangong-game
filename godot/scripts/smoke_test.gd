extends SceneTree
## Deterministic smoke checks for the prototype's combat/state transitions.
var game: Node
var failures = 0

func _initialize() -> void:
	call_deferred("run")

func press(key: int) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = key
	event.pressed = true
	game._unhandled_input(event)

func check(condition: bool, label: String) -> void:
	if not condition:
		push_error("FAIL: " + label)
		failures += 1
		return
	print("PASS: ", label)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "/tmp/guangong-test-progress.cfg"
	root.add_child(game)
	game.set_process(false)
	# Isolate tests from normal play saves.
	game.muted = true
	game._start()
	check(game.state == "dialogue", "opening dialogue")
	game._finish_dialogue()
	game.x = 450
	game._update_play(0.01)
	check(game.phase == 1, "movement tutorial")
	game.x = 600
	press(KEY_J)
	game._update_play(0.02)
	game._update_play(0.30)
	press(KEY_J)
	game._update_play(0.02)
	check(game.phase == 2, "two distinct training hits")
	game._update_play(0.30)
	press(KEY_SPACE)
	game._update_play(0.02)
	check(game.phase == 3 and game.enemies.size() == 2, "dodge and first wave")
	game._reset_effects()
	game.x = game.enemies[0].x - 90
	press(KEY_J)
	game._update_play(0.01)
	var hp_after: int = game.enemies[0].hp
	game._update_play(0.01)
	check(hp_after == 1 and game.enemies[0].hp == 1, "one hit per enemy per swing")
	game.enemies.clear()
	game._update_play(0.01)
	check(game.phase == 4 and game.enemies.size() == 3, "second wave")
	game.enemies.clear()
	game.x = 2060
	game.hp = 3
	press(KEY_E)
	check(game.hp == 4 and game.ext.resource == 4 and game.ext.rest_used, "tea stall heals and fills resolve through normal key handling")
	game.x = 2200
	game._update_play(0.01)
	check(game.phase == 5 and game.state == "dialogue", "boss introduction")
	game.hp = 2
	game.combat_seconds = 21.0
	game.hits = 4
	game._finish_dialogue()
	check(game.hp == 4 and game.phase == 6 and game.checkpoint.hp == 4, "boss checkpoint healing")
	game.hp = 1
	game.combat_seconds = 35
	game._hurt(1)
	check(game.state == "dead", "defeat")
	game._retry()
	check(game.hp == 4 and game.combat_seconds == 21 and game.hits == 4 and game.retries == 1, "checkpoint restores successful path stats")
	check(game.enemies[0].hp == 16 and game.enemies[0].mode == "approach", "boss reset")
	check(game.ext.resource == 4, "boss retry restores resolve from the tea stall")
	var boss: Dictionary = game.enemies[0]
	game.x = boss.x - 100
	game.facing = 1
	press(KEY_K)
	boss.mode = "strike"
	boss.facing = -1
	boss.timer = 0.2
	game._update_play(0.01)
	check(game.hp == 4 and boss.mode == "recover" and game.ext.parries == 1, "live strike can be parried through K")
	press(KEY_J)
	check(not game.ext.is_guarding() and game.attack_time > 0, "J releases the guard and starts a swing")
	game._sync_scene()
	press(KEY_L)
	game._sync_scene()
	check(boss.hp == 13 and game.ext.resource == 0 and game.attack_time == 0 and game.level.player.sprite.animation == &"heavy", "L replaces the J swing with one heavy hit and restarts the visual")
	press(KEY_SPACE)
	check(game.dodge_time == 0, "Space waits until the heavy strike finishes")
	game._retry()
	game.dodge_time = 0.2
	game._hurt(1)
	check(game.hp == 4, "dodge invulnerability")
	game.dodge_time = 0
	game._hurt(1)
	game._hurt(1)
	check(game.hp == 3, "damage invulnerability")
	game._action("pause_click")
	var seconds: float = game.combat_seconds
	game._process(1.0)
	check(game.state == "pause" and game.combat_seconds == seconds, "pause freezes combat clock")
	game._action("resume")
	game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(game.state == "pause", "focus loss auto pauses")
	game._action("resume")
	game.enemies[0].hp = 1
	game.x = game.enemies[0].x - 85
	game.facing = 1
	game._reset_effects()
	press(KEY_J)
	# Saving uses the isolated temporary save_path set above.
	game._update_play(0.01)
	check(game.phase == 7 and game.enemies.is_empty() and game.cleared, "boss victory stops all enemy damage and saves")
	game._finish_dialogue()
	check(game.state == "victory" and game.show_culture, "ending and culture card")
	var save = ConfigFile.new()
	check(save.load(game.save_path) == OK and save.get_value(game.SCORE_VERSION, "cleared", false), "persistent completion")
	game._start()
	check(game.get_meta("dummy_hits") == 0 and game.checkpoint.is_empty(), "new run clears tutorial and checkpoint")
	game._enter_boss()
	game.enemies[0].hp = 3
	game.x = game.enemies[0].x - 100
	game.ext.resource = 4
	press(KEY_L)
	game._sync_scene()
	check(game.state == "dialogue" and game.ext.heavy_time == 0 and game.level.player.sprite.animation == &"idle", "lethal heavy strike clears its pose and arc before the ending")
	print("SMOKE CHECKS COMPLETE")
	game.queue_free()
	await process_frame
	quit(1 if failures else 0)
