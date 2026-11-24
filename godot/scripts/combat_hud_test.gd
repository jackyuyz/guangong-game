extends SceneTree
## Presentation checks use a disposable session, including paused health feedback.
var failures = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "/tmp/guangong-combat-hud-%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	game.set_process(false)
	game.window_active = true
	game.muted = true
	game.state = "play"
	game.phase = 3
	game._sync_scene()
	var hud = game.ui.get_node("Root/HUD")
	hud.set_process(false)
	check(hud.get_node("Health/HP").value == 6 and hud.get_node("Health/HP").max_value == 6, "continuous brush health uses the actual six-point health model")
	game.hp = 4
	game._sync_scene()
	check(hud.get_node("Health/HP").value == 4 and hud.get_node("Health/Trail").value == 6, "damage updates health immediately and leaves a temporary loss trail")
	hud._process(0.15)
	hud._process(0.1)
	check(hud.get_node("Health/Trail").value > 4 and hud.get_node("Health/Trail").value < 6, "loss trail settles progressively after its short delay")
	var held = hud.get_node("Health/Trail").value
	game.state = "pause"
	game._sync_scene()
	game._sync_scene()
	hud._process(1.0)
	check(hud.get_node("Health/Trail").value == held, "repeated pause syncs and time cannot advance health feedback")
	game.state = "play"
	game._sync_scene()
	hud._process(1.0)
	check(hud.get_node("Health/Trail").value == 4, "resuming continues and completes the pending trail")
	game.hp = 5
	game._sync_scene()
	check(hud.get_node("Health/HP").value == 5 and hud.get_node("Health/Trail").value == 5, "healing never leaves a false damage trail")
	game.hp = 2
	game.reduced_motion = true
	game._sync_scene()
	check(hud.get_node("Health/Trail").value == 2 and hud.get_node("Health/LowHealth").visible, "reduced motion snaps health and low health has a text cue")
	game.ext.resource = 3
	game._sync_scene()
	check(hud.get_node("Extensions/Pips").get_child_count() == 4 and hud.get_node("Extensions/Pips/Pip3").self_modulate != hud.get_node("Extensions/Pips/Pip4").self_modulate, "four authored diamonds distinguish filled from empty qi")
	check(not hud.get_node("Extensions/Skill/Ready").visible, "three qi cannot imply the heavy attack is ready")
	game.ext.resource = 4
	game.ext.heavy_cooldown = 0.4
	game._sync_scene()
	check(not hud.get_node("Extensions/Skill/Ready").visible, "full qi during cooldown keeps the action unavailable")
	game.ext.heavy_cooldown = 0.0
	game._sync_scene()
	check(hud.get_node("Extensions/Skill/Ready").visible, "full qi with no cooldown marks L ready")
	game._enter_boss()
	game.enemies[0].x = game.x + 100
	game.enemies[0].hp = 8
	game._sync_scene()
	check(hud.get_node("BossHealth").visible and hud.get_node("BossHealth/HP").value == 8 and hud.get_node("BossHealth/Phase").visible, "boss half health shows the named bottom bar and second-phase marker")
	check(not hud.get_node("ObjectivePanel").visible and not hud.get_node("Message").visible, "boss entry removes duplicate objective and entry-banner text")
	game.ext.handle_key(game, KEY_L)
	game.ext.update(game, game.ext.HEAVY_CONTACT)
	game._sync_scene()
	check(game.ext.resource == 0 and not hud.get_node("Extensions/Skill/Ready").visible and hud.get_node("BossHealth/HP").value == 5, "real heavy attack consumption and damage are reflected together")
	game._banner("横扫破防 · 须精准弹反或闪避")
	game._sync_scene()
	check(hud.get_node("Message").visible and hud.get_node("Message/Text").text == game.message, "important combat explanations still appear")
	game.enemies[0].mode = "windup"
	game.enemies[0].move = 2
	game.enemies[0].facing = -1.0
	game._sync_scene()
	var tell = game.level.boss.get_node("Telegraph")
	check(tell.get_node("Sweep").visible and not tell.get_node("Thrust").visible and tell.scale.x < 0, "sweep telegraph has its own ground shape and faces the real attack direction")
	game.enemies[0].move = 3
	game.enemies[0].facing = 1.0
	game._sync_scene()
	check(tell.get_node("Thrust").visible and not tell.get_node("Sweep").visible and tell.scale.x > 0, "thrust telegraph differs by shape, not only color")
	game.enemies[0].facing = 0.0
	game._sync_scene()
	check(tell.visible and tell.scale.x > 0, "exact overlap cannot collapse the warning to zero width")
	game.enemies[0].mode = "recover"
	game._sync_scene()
	check(not tell.visible, "recovery clears the ground warning")
	game.state = "dead"
	game._sync_scene()
	game._retry()
	game._sync_scene()
	check(hud.get_node("Health/HP").value == game.checkpoint.hp and hud.get_node("Health/Trail").value == game.checkpoint.hp and hud.get_node("BossHealth/HP").value == 16, "checkpoint retry resets both real bars and any old damage feedback")
	game.phase = 0
	game._sync_scene()
	check(hud.get_node("Controls/Keys").visible and not hud.get_node("Extensions").visible and not hud.get_node("BossHealth").visible, "tutorial shows only its current instruction and health")
	check(not FileAccess.file_exists(game.save_path), "HUD and telegraph checks never write player progress")
	game.queue_free()
	await process_frame
	print("COMBAT HUD CHECKS COMPLETE; failures=", failures)
	quit(1 if failures else 0)
