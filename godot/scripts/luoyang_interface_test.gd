extends SceneTree
var checks = 0
var failures = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)
func run() -> void:
	var game = load("res://scenes/levels/luoyang_chapter.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	await process_frame
	check(game.overlay.get_theme().resource_path.ends_with("wuxia-game.tres") and game.title.get_theme_font("font").resource_path.ends_with("wuxia-display-font.tres"), "chapter uses the shared silk, body font and display font")
	check(game.buttons[0].theme_type_variation == &"WuxiaPrimary" and not game.title.text.contains("原型"), "entry uses the shared primary brush and chapter title")
	check(not game.get_node("UI/Overlay/Panel/Motion").visible and not game.get_node("UI/Overlay/Panel/Prototype").visible, "prototype labels and native switch are retired")
	game.overlay_guard = 0.0
	game._open_settings()
	check(game.settings_open and game.get_node("UI/Overlay/Settings").visible and not game.get_node("UI/Overlay/Panel").visible, "settings replaces the menu under one shade")
	check(game.get_viewport().gui_get_focus_owner() == game.get_node("UI/Overlay/Settings/Sound/Off"), "settings focuses the current sound choice")
	game.overlay_guard = 0.0
	var changes: Array = []
	game.preferences_changed.connect(func(a, b): changes.append([a, b]))
	game._set_motion(true)
	game._set_motion(true)
	game._set_sound(true)
	check(changes.size() == 1 and game.reduced_motion, "grouped preferences are idempotent")
	game._show_help(true)
	check(game.help_open and not game.settings_open and not game.get_node("UI/Overlay/Settings").visible, "guide replaces settings without a second modal")
	game.overlay_guard = 0.0
	game._close_help()
	check(game.settings_open and game.get_viewport().gui_get_focus_owner() == game.get_node("UI/Overlay/Settings/Help"), "guide returns to its settings focus")
	game.overlay_guard = 0.0
	game._close_settings()
	check(game.model.state == "ready" and game.overlay.visible, "entry settings cannot start a chapter")
	game.begin_chapter()
	game.model._begin_play("tutorial")
	game._sync_world()
	check(game.get_node("UI/Keys").visible and not game.get_node("UI/Footer").visible, "tutorial displays one brief lane hint")
	game.model._begin_play("chase")
	game._sync_world()
	check(not game.get_node("UI/Keys").visible and not game.get_node("UI/Footer").visible, "chase retires the persistent keyboard strip")
	game.model._begin_play("sprint")
	game.model.step(2.0)
	game._sync_world()
	check(game.get_node("UI/Keys").visible, "first arrow briefly explains locked-route dodging")
	game.model.elapsed = 5.6
	game._sync_world()
	check(not game.get_node("UI/Keys").visible, "later arrows leave the road clear of help text")
	game.model.hp = 1
	game._sync_world()
	check(game.get_node("UI/HealthDisplay/HP").value == 1 and game.get_node("UI/HealthDisplay/HP").max_value == 4 and game.get_node("UI/HealthDisplay/LowHealth").visible, "first-chapter HP brush displays four-hit rules and low health")
	game.overlay_guard = 0.0
	game._toggle_pause()
	var frozen = [game.model.elapsed, game.model.phase_clock, game.model.lane]
	game.overlay_guard = 0.0
	game._open_settings()
	game._process(1.0)
	check([game.model.elapsed, game.model.phase_clock, game.model.lane] == frozen, "settings keeps gameplay and arrow timers paused")
	game.overlay_guard = 0.0
	game._close_settings()
	check(game.model.state == "paused" and game.overlay.visible, "closing settings preserves an explicit resume step")
	game.overlay_guard = 0.0
	game._confirm_exit()
	game._sync_interface()
	check(game.buttons[1].has_focus() and game.buttons[1].theme_type_variation == &"WuxiaPrimary" and game.buttons[0].theme_type_variation == &"WuxiaDanger", "exit confirmation focuses the safe brush action")
	game._cycle_focus(1)
	check(game.buttons[0].has_focus(), "exit focus loops inside the two choices")
	game._cancel_exit()
	game.model.victory_locked = true
	game.model._story("ending")
	game.model._next_story()
	game._sync_world()
	check(game.get_node("UI/Culture").visible and not game.story_panel.visible, "culture uses the shared paper reading panel")
	game._process(0.0)
	game.overlay_guard = 0.15
	game._process(0.3)
	check(not game.get_node("UI/Culture/Card/Advance").disabled, "static culture button unlocks after transition guard")
	game.model.seconds = 66.0
	game._advance_story()
	check(game.model.state == "complete" and game.get_node("UI/Overlay/Panel/Seal").visible and not game.result_details, "result shows the first-chapter clear stamp with collapsed stats")
	game.overlay_guard = 0.0
	game._overlay_action(1)
	check(game.result_details and game.description.text.contains("66.0") and game.model.state == "complete", "expanding stats cannot restart the chapter")
	game.save_notice = "本次进度未能保存"
	game._sync_world()
	check(game.get_node("UI/SaveNotice").text == game.save_notice and game.get_node("UI/Footer").visible and not game.get_node("UI/Keys").visible, "save failure remains visible outside collapsed stats")
	var font = load("res://assets/ui/wuxia-reading-font.ttf")
	var text = FileAccess.get_file_as_string("res://scripts/luoyang_chapter.gd") + FileAccess.get_file_as_string("res://scenes/levels/luoyang_chapter.tscn") + FileAccess.get_file_as_string("res://scripts/luoyang_story.gd") + FileAccess.get_file_as_string("res://scripts/luoyang_finale.gd")
	var missing = ""
	for i in text.length():
		var code = text.unicode_at(i)
		if code >= 0x4e00 and code <= 0x9fff and not font.has_char(code) and text[i] not in missing: missing += text[i]
	check(missing.is_empty(), "shared reading font covers all chapter text: " + missing)
	game.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("LUOYANG INTERFACE CHECKS: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
