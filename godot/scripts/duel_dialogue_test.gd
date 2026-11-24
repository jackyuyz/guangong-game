extends SceneTree
var failures = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "/tmp/guangong-duel-%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.window_active = true
	game.phase = 5
	game.x = game.level.gate_x + 1
	game._begin_dialogue(game.story.boss, "play")
	game._sync_scene()
	var panel = game.ui.get_node("Root/Dialogue")
	panel.set_process(false)
	check(panel.visible and panel.get_node("Portraits").visible and panel.get_node("Portraits/GuanYu").texture != null and panel.get_node("Portraits/KongXiu").texture != null, "both real portraits appear before the boss combat actor exists")
	check(game.enemies.is_empty() and not game.level.player.visible and not game.level.boss.visible, "dialogue portraits have no enemies or duplicate world actors")
	check(panel.get_node("Speaker").text == "孔秀" and panel.kong.modulate == Color.WHITE and panel.guan.modulate.r < 1, "first line highlights Kong Xiu while keeping Guan Yu visible")
	panel._process(0.1)
	var held: float = panel.get_node("Portraits").modulate.a
	check(held > 0 and held < 1, "portraits enter with a short fade and slide")
	game._action("pause_click")
	game._sync_scene()
	panel._process(1)
	check(not panel.visible and panel.get_node("Portraits").modulate.a == held, "pause hides the dialogue and freezes its entrance")
	game._action("resume")
	game._sync_scene()
	panel._process(0.2)
	check(panel.visible and panel.get_node("Portraits").modulate.a == 1, "resume finishes the same entrance without restarting it")
	game._action("next")
	game._sync_scene()
	check(panel.get_node("Speaker").text == "关羽" and panel.guan.modulate == Color.WHITE and panel.kong.modulate.r < 1 and panel.get_node("Portraits/GuanMark").visible, "reply switches portrait emphasis and the speaker cue")
	check(panel.get_node("Body").text == game.story.boss[1][1], "the complete original draft reply remains unchanged")
	game.window_active = false
	panel.present(game)
	var frozen_position: Vector2 = panel.guan.position
	panel._process(1)
	check(panel.guan.position == frozen_position, "focus loss cannot advance portrait motion")
	game.window_active = true
	game.reduced_motion = true
	panel.present(game)
	check(panel.get_node("Portraits").modulate.a == 1 and panel.guan.position.x == panel.guan_origin.x, "reduced motion presents the authored positions immediately")
	var saved_resource = game.ext.resource
	game.ui.get_node("Root/Dialogue/Skip").pressed.emit()
	game._sync_scene()
	check(game.phase == 6 and game.state == "play" and game.enemies.size() == 1 and not panel.visible and game.level.player.visible and game.level.boss.visible, "skip enters one real boss fight and restores world actors")
	game._action("skip")
	game._action("next")
	check(game.enemies.size() == 1 and game.ext.resource == saved_resource, "stale dialogue button actions cannot repeat boss entry or spend qi")
	game._retry()
	game._sync_scene()
	check(game.phase == 6 and not panel.visible and game.enemies.size() == 1, "checkpoint retry bypasses the introduction")
	game.phase = 5
	game.enemies.clear()
	game._begin_dialogue(game.story.boss, "play")
	game._sync_scene()
	game._action("next")
	game._sync_scene()
	game._action("next")
	game._sync_scene()
	check(game.dialogue_index == 2 and game.state == "dialogue" and panel.get_node("Speaker").text == "孔秀", "all three lines remain in order")
	game._action("next")
	game._sync_scene()
	check(game.phase == 6 and game.enemies.size() == 1 and not panel.visible, "finishing the third line enters the same boss flow")
	game.phase = 7
	game._begin_dialogue(game.story.ending, "victory")
	game._sync_scene()
	check(panel.visible and not panel.get_node("Portraits").visible and not panel.get_node("Dimmer").visible, "ending dialogue never resurrects the defeated boss portrait")
	check(not FileAccess.file_exists(game.save_path), "dialogue checks do not write player progress")
	game.queue_free()
	await process_frame
	print("DUEL DIALOGUE CHECKS COMPLETE; failures=", failures)
	quit(1 if failures else 0)
