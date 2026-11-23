extends SceneTree
## Exercise the actual native controls and shared preferences with an isolated save.
var failures = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)
func key(code: int, shift: bool = false, echo: bool = false) -> void:
	for down in [true, false]:
		var event = InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		event.shift_pressed = shift
		event.echo = echo
		root.push_input(event, true)
func click(button: Button) -> void:
	for down in [true, false]:
		var event = InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = button.get_global_rect().get_center()
		event.global_position = event.position
		event.pressed = down
		root.push_input(event, true)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.set_script(load("res://scripts/settings_save_fixture.gd"))
	game.save_path = "/tmp/guangong-settings-controls-%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	game.set_process(false)
	game.window_active = true
	game.ui.get_node("Root/MainMenu/Mute").grab_focus()
	game._action("settings")
	await process_frame
	var panel = game.ui.get_node("Root/Utility/Settings")
	check(root.gui_get_focus_owner() == panel.selected_sound(), "opening settings focuses its selected sound choice")
	check(panel.get_node("Sound/Off").focus_mode == Control.FOCUS_CLICK, "unselected choices do not duplicate Tab stops")
	game.progress.set_intro("completed")
	game.progress.mark_cleared("dongling", 900)
	click(panel.get_node("Sound/Off"))
	check(game.muted and game.progress.muted() and game.writes == 1, "native Off click saves its explicit value once")
	check(not panel.get_node("HoverSound").playing and not panel.get_node("ConfirmSound").playing, "switching sound off immediately silences feedback")
	click(panel.get_node("Sound/Off"))
	check(game.muted and game.writes == 1, "clicking the selected Off never reverses it or saves again")
	click(panel.get_node("Sound/On"))
	check(not game.muted and panel.get_node("ConfirmSound").playing, "switching sound on confirms after unmuting")
	panel.get_node("ConfirmSound").stop()
	click(panel.get_node("Sound/On"))
	check(not panel.get_node("ConfirmSound").playing and game.writes == 2, "selected On click is silent and idempotent")
	key(KEY_TAB)
	check(root.gui_get_focus_owner() == panel.selected_motion(), "Tab moves to the motion group")
	key(KEY_LEFT)
	check(game.reduced_motion and game.progress.reduced_motion(), "Left selects motion On and persists immediately")
	key(KEY_LEFT)
	check(game.writes == 3, "repeated same-value arrow selection never saves again")
	key(KEY_SPACE, false, true)
	check(game.reduced_motion, "held confirmation cannot repeatedly toggle preferences")
	key(KEY_TAB)
	check(root.gui_get_focus_owner() == panel.get_node("Help"), "Tab reaches the guide entry after the two groups")
	check(panel.get_node("Help/Wash").modulate.a > 0, "reduced motion applies focus feedback immediately")
	key(KEY_ENTER)
	check(game.utility_panel == "help", "Enter opens the existing animated keyboard guide")
	game._action("settings")
	check(root.gui_get_focus_owner() == panel.get_node("Help"), "returning from the guide restores its settings entry")
	key(KEY_TAB)
	check(root.gui_get_focus_owner() == panel.get_node("Close"), "Tab reaches completion")
	key(KEY_TAB)
	check(root.gui_get_focus_owner() == panel.selected_sound(), "Tab wraps within the four settings groups")
	key(KEY_TAB, true)
	check(root.gui_get_focus_owner() == panel.get_node("Close"), "Shift Tab wraps backward without entering covered controls")
	game.progress.error_text = "本次进度未能保存"
	game._sync_scene()
	check(panel.get_node("Notice").visible and panel.get_node("Notice").text == game.progress.error_text, "save failures remain visible beside completion")
	game.window_active = false
	game._sync_scene()
	panel._enter(panel.get_node("Help"))
	check(not panel.get_node("HoverSound").playing and is_zero_approx(panel.get_node("Help/Wash").modulate.a), "window blur clears hover and audio feedback")
	game.window_active = true
	game._sync_scene()
	key(KEY_ESCAPE)
	check(game.utility_panel.is_empty() and root.gui_get_focus_owner() == game.ui.get_node("Root/MainMenu/Mute"), "Escape restores the original menu focus")
	var store = load("res://scripts/progress_store.gd").new()
	store.load_file(game.save_path)
	check(store.intro_state() == "completed" and store.is_cleared("dongling") and store.best_score() == 900 and store.reduced_motion() and not store.muted(), "preference writes preserve progress and best score on reload")
	game._action("sound_off")
	check(not game.muted, "hidden settings cannot accept explicit preference actions")
	game.muted = true
	game._sync_scene()
	await create_timer(.3).timeout
	game.queue_free()
	await create_timer(.2).timeout
	print("SETTINGS CHECKS COMPLETE; failures=", failures)
	quit(1 if failures else 0)
