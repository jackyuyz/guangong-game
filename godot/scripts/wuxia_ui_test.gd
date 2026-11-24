extends SceneTree
## Native input checks for shared modal focus and sound suppression.
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
func frames() -> void:
	await process_frame
	await process_frame
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "/tmp/guangong-language-test-%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	game.set_process(false)
	game.window_active = true
	game.muted = true
	var ui = game.ui
	var feedback = ui.get_node("Feedback")
	game.state = "play"
	game._action("pause_click")
	check(root.gui_get_focus_owner() == ui.get_node("Root/Pause/Resume"), "pause begins on its safe primary action")
	key(KEY_TAB, true)
	check(root.gui_get_focus_owner() == ui.get_node("Root/Pause/Menu"), "backward Tab wraps within pause instead of the covered HUD")
	key(KEY_ENTER, false, true)
	check(game.state == "pause", "held confirmation cannot repeatedly activate pause actions")
	key(KEY_SPACE)
	check(game.state == "confirm" and root.gui_get_focus_owner() == ui.get_node("Root/Confirm/Cancel"), "exit request focuses the safe confirmation choice")
	key(KEY_ENTER)
	check(game.state == "pause", "confirming the initial choice preserves the paused run")
	key(KEY_TAB)
	check(root.gui_get_focus_owner() == ui.get_node("Root/Pause/Mute"), "pause Tab moves to settings")
	key(KEY_ENTER)
	check(game.utility_panel == "settings", "keyboard opens the shared settings panel from pause")
	check(not ui.get_node("Root/Pause").visible and ui.get_node("Root/Utility").visible, "settings replaces the pause overlay instead of stacking two dimmers")
	key(KEY_ESCAPE)
	check(game.state == "pause" and root.gui_get_focus_owner() == ui.get_node("Root/Pause/Mute"), "closing settings restores its source control without resuming combat")
	game.state = "menu"
	game.show_culture = true
	game._sync_scene()
	check(root.gui_get_focus_owner() == ui.get_node("Root/Culture/Close"), "culture begins on return rather than auto-playing the intro")
	game._action("help")
	check(not ui.get_node("Root/Culture").visible and ui.get_node("Root/Utility").visible, "guide replaces the culture overlay without a second dimmer")
	game._action("utility_close")
	check(ui.get_node("Root/Culture").visible and root.gui_get_focus_owner() == ui.get_node("Root/Culture/Close"), "closing the guide restores the culture surface and focus")
	key(KEY_TAB)
	check(root.gui_get_focus_owner() == ui.get_node("Root/Culture/Replay"), "culture focus wraps inside its two actions")
	key(KEY_TAB)
	key(KEY_ENTER)
	check(not game.show_culture and game.state == "menu", "keyboard return closes culture without triggering departure")
	game.state = "dead"
	game.checkpoint.clear()
	game._sync_scene()
	key(KEY_TAB)
	check(root.gui_get_focus_owner() == ui.get_node("Root/Defeat/Menu"), "failure Tab skips the hidden checkpoint-only restart")
	game.state = "victory"
	game._sync_scene()
	check(root.gui_get_focus_owner() == ui.get_node("Root/Victory/Culture"), "settlement defaults to the return-to-map primary action")
	game.muted = false
	game._sync_scene()
	feedback.get_node("Confirm").stop()
	feedback.last_hover = -1000
	feedback._enter(ui.get_node("Root/Victory/Restart"))
	check(feedback.get_node("Hover").playing, "shared text hover produces the common feedback sound")
	var stamp = feedback.last_hover
	feedback._hover(ui.get_node("Root/Victory/Restart"))
	check(feedback.last_hover == stamp, "focus and hover feedback are deduplicated")
	await feedback.tweens[ui.get_node("Root/Victory/Restart")].finished
	check(is_equal_approx(feedback.hover_styles[ui.get_node("Root/Victory/Restart")].modulate_color.a, 0.16), "shared hover reaches its visible brush state")
	ui.get_node("Root/Victory/Details").grab_focus()
	game.reduced_motion = true
	game._sync_scene()
	check(is_zero_approx(feedback.hover_styles[ui.get_node("Root/Victory/Restart")].modulate_color.a) and is_equal_approx(feedback.hover_styles[ui.get_node("Root/Victory/Details")].modulate_color.a, 0.16), "reduced motion immediately clears the old brush and lights only current focus")
	feedback._press(ui.get_node("Root/Victory/Restart"))
	check(feedback.get_node("Confirm").playing, "shared button press produces confirmation feedback")
	game.muted = true
	game._sync_scene()
	check(not feedback.get_node("Hover").playing and not feedback.get_node("Confirm").playing, "muting immediately stops both shared sound players")
	game.muted = false
	game._sync_scene()
	feedback.get_node("Hover").stop()
	feedback._enter(ui.get_node("Root/Pause/Menu"))
	check(not feedback.get_node("Hover").playing, "hidden screens cannot produce hover feedback")
	game.window_active = false
	game._sync_scene()
	feedback._press(ui.get_node("Root/Victory/Restart"))
	check(not feedback.get_node("Confirm").playing, "unfocused windows cannot produce confirmation feedback")
	game.window_active = true
	game.muted = true
	game.state = "menu"
	game._sync_scene()
	game.show_culture = true
	game._sync_scene()
	game._action("prologue_replay")
	await frames()
	game.prologue.set_process(false)
	game.prologue.get_node("More").grab_focus()
	key(KEY_ENTER)
	check(game.prologue.more_open and game.prologue.index == 0, "Enter activates the focused prologue control without also advancing")
	await frames()
	game.prologue.get_node("ReplayVoice").grab_focus()
	key(KEY_ENTER)
	check(not game.prologue.more_open and game.prologue.index == 0 and game.prologue.elapsed == 0, "focused replay restarts narration without advancing the scene")
	game.muted = true
	game._sync_scene()
	game.prologue.stop()
	await create_timer(.3).timeout
	game.queue_free()
	await frames()
	print("WUXIA UI CHECKS COMPLETE; failures=", failures)
	quit(1 if failures else 0)
