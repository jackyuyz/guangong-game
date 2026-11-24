extends SceneTree
## Native hit testing, focus, feedback and modal suppression use a disposable save.
var failures = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)
func move(at: Vector2) -> void:
	var event = InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	root.push_input(event, true)
func click(at: Vector2) -> void:
	for down in [true, false]:
		var event = InputEventMouseButton.new()
		event.position = at
		event.global_position = at
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = down
		root.push_input(event, true)
func key(code: int) -> void:
	for down in [true, false]:
		var event = InputEventKey.new()
		event.keycode = code
		event.physical_keycode = code
		event.pressed = down
		root.push_input(event, true)
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "/tmp/guangong-menu-test-%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	game.set_process(false)
	game.window_active = true
	game.muted = false
	game._sync_scene()
	await process_frame
	var menu = game.ui.get_node("Root/MainMenu")
	var culture: Button = menu.get_node("Culture")
	var wash = culture.get_node("Wash")
	var hover = menu.get_node("HoverSound")
	var center = culture.get_global_rect().get_center()
	move(center)
	check(menu.hovered == culture and hover.playing, "hovering the actual label hit area plays feedback")
	check(root.gui_get_focus_owner() == culture, "mouse hover aligns keyboard selection with the same entry")
	var stamp = menu.last_hover_sound
	culture.grab_focus()
	check(menu.last_hover_sound == stamp, "hover and focus on one entry never double-play the sound")
	await menu.tweens[culture].finished
	check(wash.modulate.a > .15, "hover reveals a gold brush background behind the label")
	culture.release_focus()
	move(Vector2(50, 30))
	await menu.tweens[culture].finished
	check(is_zero_approx(wash.modulate.a) and game.state == "menu", "leaving the label restores its background without navigation")
	game.reduced_motion = true
	game._sync_scene()
	culture.grab_focus()
	check(wash.modulate.a > .15, "keyboard focus remains visible with reduced motion")
	game.muted = true
	game._sync_scene()
	menu.get_node("Start").grab_focus()
	check(not hover.playing, "muting silences hover and keyboard feedback")
	menu._enter(culture)
	check(wash.modulate.a > .15 and not hover.playing, "muted hover retains its visual feedback")
	game.muted = false
	game._sync_scene()
	culture.button_down.emit()
	check(menu.get_node("ConfirmSound").playing and wash.modulate.a > .3, "pressing has a distinct sound and stronger background")
	game._action("settings")
	var covered_center = menu.get_node("Start").get_global_rect().position + Vector2(8, 8)
	move(covered_center)
	click(covered_center)
	check(game.state == "menu" and game.utility_panel == "settings" and not menu.active and is_zero_approx(wash.modulate.a), "settings blocks the covered menu text hit area and clears highlights")
	check(not hover.playing, "covered menu never produces hover sound")
	game._action("utility_close")
	game.window_active = false
	game._sync_scene()
	menu._enter(culture)
	check(not hover.playing and is_zero_approx(wash.modulate.a), "an unfocused window suppresses menu feedback")
	game.window_active = true
	game._sync_scene()
	menu.get_node("Start").release_focus()
	move(Vector2(50, 30))
	click(center)
	check(game.show_culture and game.state == "menu", "clicking the native text button opens story and culture")
	game.show_culture = false
	game._sync_scene()
	culture.grab_focus()
	key(KEY_DOWN)
	check(root.gui_get_focus_owner() == menu.get_node("Mute"), "Down selects settings within the main menu")
	key(KEY_ENTER)
	check(game.utility_panel == "settings" and game.state == "menu", "Enter confirms the selected settings entry instead of starting the journey")
	game._action("utility_close")
	key(KEY_UP)
	check(root.gui_get_focus_owner() == culture, "Up returns keyboard focus to story and culture")
	key(KEY_SPACE)
	check(game.show_culture and game.utility_panel.is_empty() and game.state == "menu", "Space confirms culture without leaking into the start shortcut")
	game.show_culture = false
	game._sync_scene()
	game.progress.set_intro("completed")
	game._sync_scene()
	check(menu.get_node("Start").text == "继续旅程" and menu.get_node("Start").get_theme_font_size("font_size") == 38, "returning players get a fitting continue label")
	check(not FileAccess.file_exists(game.save_path), "menu feedback and previews never write player progress")
	var credits: Button = menu.get_node("Credits")
	menu.get_node("Mute").grab_focus()
	key(KEY_DOWN)
	check(root.gui_get_focus_owner() == credits, "Down reaches credits after settings")
	key(KEY_DOWN)
	check(root.gui_get_focus_owner() == menu.get_node("Start"), "four-entry menu wraps from credits to start")
	key(KEY_UP)
	key(KEY_ENTER)
	var panel = game.ui.get_node("Root/Utility/Credits")
	var close = panel.get_node("Close")
	check(game.utility_panel == "credits" and panel.is_visible_in_tree() and game.state == "menu", "keyboard opens credits without starting the journey")
	check(root.gui_get_focus_owner() == close and not menu.get_node("Credits").visible, "credits focuses return and hides the covered menu")
	check(not game.ui.get_node("Root/Utility/Settings").visible and not game.ui.get_node("Root/Utility/Body").visible, "credits replaces other utility content")
	check(panel.get_node("Team").text == "吴老师的82439-Black Myth: Wukong and the Journey to the West F26", "credits preserves the supplied team name exactly")
	for code in [KEY_TAB, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]: key(code)
	check(root.gui_get_focus_owner() == close, "credits traps keyboard navigation inside its return action")
	var echo_key = InputEventKey.new()
	echo_key.physical_keycode = KEY_ENTER
	echo_key.pressed = true
	echo_key.echo = true
	root.push_input(echo_key, true)
	check(game.utility_panel == "credits", "held confirmation never dismisses credits")
	click(Vector2(70, 40))
	game._action("start")
	check(game.utility_panel == "credits" and game.state == "menu", "backdrop clicks and covered start actions cannot leave credits")
	key(KEY_ESCAPE)
	check(game.utility_panel.is_empty() and root.gui_get_focus_owner() == credits and menu.active, "Esc restores the credits entry and menu feedback")
	move(credits.get_global_rect().get_center())
	click(credits.get_global_rect().get_center())
	check(game.utility_panel == "credits", "native mouse hit area opens credits")
	key(KEY_SPACE)
	check(game.utility_panel.is_empty() and game.state == "menu" and root.gui_get_focus_owner() == credits, "Space returns once without leaking into departure")
	click(credits.get_global_rect().get_center())
	click(close.get_global_rect().get_center())
	check(game.utility_panel.is_empty() and root.gui_get_focus_owner() == credits, "mouse return restores its source focus")
	check(not FileAccess.file_exists(game.save_path), "opening and closing credits never writes progress")
	game.state = "map"
	game._action("credits")
	check(game.utility_panel.is_empty() and game.state == "map", "credits entry is restricted to the home menu")
	game.queue_free()
	await create_timer(.2).timeout
	print("MAIN MENU CHECKS COMPLETE; failures=", failures)
	quit(1 if failures else 0)
