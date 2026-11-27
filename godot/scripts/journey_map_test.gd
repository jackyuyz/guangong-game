extends SceneTree
var failures = 0
var game: Node
var map: Control
func _initialize() -> void: call_deferred("run")
func check(ok: bool, text: String) -> void:
	if ok: print("PASS: ", text)
	else:
		failures += 1
		push_error("FAIL: " + text)
func frames() -> void:
	await process_frame
	await process_frame
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	var save = "/tmp/guangong-journey-%d.cfg" % Time.get_ticks_usec()
	game.save_path = save
	check(game.get_node("UI/Root/JourneyMap/ScrollClip/Stops").get_child_count() == 5, "five selectable stops are authored before ready")
	check(game.get_node("UI/Root/JourneyMap/ScrollClip/Illustration").texture != null, "integrated scroll artwork exists in editor scene")
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	map = game.journey
	map.set_process(false)
	game._start()
	check(game.state == "prologue" and game.progress.intro_state() == "unseen", "first departure opens intro without prematurely marking it seen")
	game.prologue._show_scene(5)
	await frames()
	game.prologue.advance()
	check(game.state == "map" and game.progress.intro_state() == "completed", "first final confirmation saves intro and opens map")
	check(game.prologue.get_node("Next").text == "展开旅图" and not game.prologue.active, "first intro uses map completion label and stops audio")
	check(not map.ready_to_start and not game.ui.get_node("Root/HUD").visible, "opening animation gates departure and hides HUD")
	game._enter_chapter("dongling")
	check(game.state == "map", "chapter cannot start during scroll reveal")
	map._process(.9)
	check(map.ready_to_start and is_equal_approx(map.get_node("ScrollClip").size.x, 960), "scroll reveal completes to full authored width")
	check(game.progress.completed_count() == 0 and map.selected == 0, "new journey keeps zero progress and the first recommendation")
	check(map.can_enter("dongling"), "first chapter is available")
	var caravan: Vector2 = map.get_node("ScrollClip/Caravan").position
	check(not map.has_node("ScrollClip/ReadyFlag") and not map.nodes[0].has_node("State"), "map uses no ambiguous red flag or redundant per-stop state captions")
	check(not map.get_node("ScrollClip/Veils/Pass1").visible, "available first pass stays clear")
	for i in range(1, 5):
		map.select_chapter(i)
		check(map.get_node("ScrollClip/Veils").get_child(i).visible and not map.nodes[i].has_node("State") and not map.get_node("ScrollClip/Details/Start").visible and map.get_node("ScrollClip/Details/Start").disabled, "future chapter preview stays disabled: " + map.chapters[i].id)
		game._enter_chapter(map.chapters[i].id)
		check(game.state == "map", "direct chapter request cannot bypass availability: " + map.chapters[i].id)
	check(map.get_node("ScrollClip/Caravan").position == caravan and game.progress.completed_count() == 0, "browsing preserves the actual party position and creates no progress")
	var event = InputEventKey.new()
	event.physical_keycode = KEY_LEFT
	event.pressed = true
	map._input(event)
	check(map.selected == 3 and game.state == "map", "arrow navigation selects without starting")
	game.hp = 3
	game.checkpoint = {"hp":4,"seconds":21,"hits":2}
	game._save()
	var before = FileAccess.get_file_as_bytes(save)
	map.get_node("Review").grab_focus()
	game._action("map_replay")
	check(game.state == "prologue" and game.prologue.entry == "map" and game.hp == 3, "map review opens without resetting run")
	check(game.prologue.get_node("Skip").text == "返回旅图", "map review has explicit return button")
	await frames()
	game.prologue.finish()
	check(game.state == "map" and map.selected == 3 and game.hp == 3 and game.checkpoint.hp == 4, "review returns to original selection and preserves run")
	check(map.get_viewport().gui_get_focus_owner() == map.get_node("Review") and before == FileAccess.get_file_as_bytes(save), "review restores focus without writing progress")
	game.progress.config.set_value("custom", "note", "keep")
	game._action("mute")
	var reread = ConfigFile.new()
	reread.load(save)
	check(reread.get_value("journey", "intro_state") == "completed" and reread.get_value("custom", "note") == "keep", "sound saves retain journey and unknown fields")
	game._action("motion")
	check(game.reduced_motion and map.ready_to_start and game.ui.get_node("Root/Utility/Settings/Motion/On").button_pressed, "reduced motion setting immediately finishes entrance")
	map._process(0)
	game._unhandled_input(event)
	check(game.attack_time == 0 and game.combat_seconds == 0, "map never advances combat")
	map.select_chapter(0)
	await frames()
	map._process(0)
	map.get_node("ScrollClip/Details/Start").pressed.emit()
	check(game.state == "play" and game.phase == 0 and game.hp == 6 and game.await_input_release, "explicit map departure initializes chapter tutorial once")
	var spawn_x: float = game.x
	map.chapter_requested.emit("dongling")
	check(game.state == "play" and game.x == spawn_x, "duplicate departure cannot restart active chapter")
	game._process(0)
	game._enter_boss()
	game._action("pause_click")
	game._action("map_confirm")
	check(game.state == "confirm" and not game.checkpoint.is_empty(), "leaving active chapter requires confirmation")
	game._action("cancel")
	check(game.state == "pause" and not game.checkpoint.is_empty(), "cancel exit preserves checkpoint")
	game._action("map_confirm")
	game._action("map_exit")
	check(game.state == "map" and game.checkpoint.is_empty() and not game.progress.is_cleared("dongling"), "confirmed exit discards only in-flight chapter")
	game.state = "dead"
	game.resume_state = "prologue"
	game._action("map_confirm")
	check(game.ui.get_node("Root/Confirm/Menu").get_meta("action") == "map_exit", "failure exit target does not depend on stale prologue pause state")
	game._action("cancel")
	check(game.state == "dead", "cancel from failure confirmation returns to failure")
	game._return_to_map()
	map._process(0)
	game._enter_chapter("dongling")
	game._enter_boss()
	game._win()
	for i in 60: game._process(1.0 / 30)
	check(game.progress.completed_count() == 1 and game.progress.is_cleared("dongling"), "actual victory records one chapter completion")
	game._finish_dialogue()
	game._action("culture")
	game._action("map_return")
	check(game.state == "map" and map.selected == 1 and game.progress.completed_count() == 1, "settlement recommends the newly available second chapter with one of five complete")
	map.select_chapter(0)
	check(map.get_node("ScrollClip/Stops/Pass1/Seal").visible and map.get_node("ScrollClip/Details/Start").text == "再次挑战", "completed chapter shows stamp and replay action")
	check(map.get_node("ScrollClip/Caravan").position == map.get_node("ScrollClip/TravelEnd").position and map.get_node("ScrollClip/Caravan").scale.x > 1.0, "larger party reaches the authored first-pass exit without entering an unfinished chapter")
	check(map.nodes[0].get_node("Seal/Glyph").text == game.ui.get_node("Root/Victory/Seal/Glyph").text and map.nodes[0].get_node("Seal").texture == game.ui.get_node("Root/Victory/Seal").texture, "map reuses the victory page's legible guo glyph and red seal artwork")
	check(map.nodes[0].get_node("Name").get_theme_color("font_color") != map.nodes[2].get_node("Name").get_theme_color("font_color"), "clear and unavailable names use distinct readable inks")
	map.select_chapter(1)
	check(game.progress.is_unlocked("luoyang") and map.can_enter("luoyang") and map.get_node("ScrollClip/Details/Start").visible, "first clear opens the implemented second chapter")
	map._process(0)
	game._enter_chapter("luoyang")
	check(game.state == "chapter_two" and game.chapter_two != null, "second chapter routes into its own controller")
	game.chapter_two.set_process(false)
	game._leave_luoyang()
	await frames()
	map.select_chapter(0)
	game.best = 5000
	game._save()
	map._process(0)
	game._enter_chapter("dongling")
	check(game.state == "play" and game.cleared and game.best == 5000 and not game.prologue.active, "replay preserves completion and best without replaying intro")
	game._win()
	for i in 60: game._process(1.0 / 30)
	check(game.best == 5000 and game.progress.best_score() == 5000 and not game._first_clear_pending and game.progress.completed_count() == 1, "lower-score replay cannot lower best or replay first-clear reward")
	game.queue_free()
	await frames()
	var loaded = load("res://scenes/main.tscn").instantiate()
	loaded.save_path = save
	root.add_child(loaded)
	loaded.set_process(false)
	loaded.muted = true
	loaded._start()
	check(loaded.state == "map" and loaded.cleared and loaded.best == 5000 and loaded.reduced_motion, "reloaded journey enters map with persistent progress and settings")
	for i in range(1, 5):
		loaded.journey.chapters[i].released = true
		loaded.journey.chapters[i].entry = "res://scenes/levels/dongling_pass.tscn"
	loaded.journey.present()
	check(not loaded.journey.get_node("ScrollClip/Veils/Pass2").visible and loaded.journey.get_node("ScrollClip/Veils/Pass3").visible, "mist clears for a genuinely available chapter while later locked stops remain veiled")
	check(loaded.journey.can_enter("luoyang") and not loaded.journey.can_enter("sishui"), "test release configuration still enforces sequence")
	loaded.progress.mark_cleared("luoyang", 0)
	check(loaded.journey.can_enter("sishui") and not loaded.journey.can_enter("xingyang"), "later test release opens only after required completion")
	loaded.queue_free()
	await create_timer(.2).timeout
	print("JOURNEY CHECKS COMPLETE; failures=", failures)
	quit(1 if failures else 0)
