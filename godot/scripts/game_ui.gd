extends CanvasLayer
## Native Controls own all layout, text wrapping, focus and mouse hit testing.
signal action_requested(action: String)
var stats_expanded = false
var _last_state = ""
var _utility_focus: Control
var _dialog_panel: Control

func remember_utility_focus() -> void:
	_utility_focus = get_viewport().gui_get_focus_owner()

func restore_utility_focus() -> void:
	if is_instance_valid(_utility_focus) and _utility_focus.is_visible_in_tree():
		_utility_focus.grab_focus()

func focus_utility() -> void:
	if $Root/Utility/Credits.visible: $Root/Utility/Credits/Close.grab_focus()
	elif $Root/Utility/Body.visible: $Root/Utility/Close.grab_focus()
	else: $Root/Utility/Settings.focus_initial()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed: return
	var code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if not $Root/Utility.visible:
		var panel = _current_dialog()
		if panel != null:
			var controls = _dialog_buttons(panel)
			if controls.is_empty(): return
			var current = controls.find(get_viewport().gui_get_focus_owner())
			if code in [KEY_TAB, KEY_UP, KEY_DOWN]:
				var step = -1 if event.shift_pressed or code == KEY_UP else 1
				controls[posmod(current + step, controls.size()) if current >= 0 else (0 if step > 0 else controls.size() - 1)].grab_focus()
				get_viewport().set_input_as_handled()
			elif code in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
				get_viewport().set_input_as_handled()
				if event.echo: return
				var button: Button = controls[current] if current >= 0 else _default_dialog_button(controls)
				if panel == $Root/Prologue and current < 0: button = $Root/Prologue/Next
				button.button_down.emit()
				button.pressed.emit()
				button.button_up.emit()
			elif code in [KEY_LEFT, KEY_RIGHT] and panel != $Root/Prologue:
				get_viewport().set_input_as_handled()
			return
		if not $Root/MainMenu.visible or not $Root/MainMenu.active: return
		var entries: Array = $Root/MainMenu.buttons
		if code in [KEY_TAB, KEY_UP, KEY_DOWN]:
			var current = entries.find(get_viewport().gui_get_focus_owner())
			var direction = -1 if event.shift_pressed or code == KEY_UP else 1
			entries[posmod(current + direction, entries.size())].grab_focus()
			get_viewport().set_input_as_handled()
		elif code in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			get_viewport().set_input_as_handled()
			if event.echo: return
			var current = entries.find(get_viewport().gui_get_focus_owner())
			var button: Button = entries[maxi(current, 0)]
			button.button_down.emit()
			button.pressed.emit()
			button.button_up.emit()
		return
	if $Root/Utility/Credits.visible:
		get_viewport().set_input_as_handled()
		if code in [KEY_ESCAPE, KEY_P]:
			if not event.echo: action_requested.emit("utility_close")
		elif code == KEY_M:
			if not event.echo: action_requested.emit("mute")
		elif code in [KEY_TAB, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT]:
			$Root/Utility/Credits/Close.grab_focus()
		elif code in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE] and not event.echo:
			$Root/Utility/Credits/Close.button_down.emit()
			$Root/Utility/Credits/Close.pressed.emit()
			$Root/Utility/Credits/Close.button_up.emit()
		return
	if not $Root/Utility/Body.visible:
		if $Root/Utility/Settings.handle_key(event): get_viewport().set_input_as_handled()
		return
	if code in [KEY_TAB, KEY_UP, KEY_DOWN]:
		var controls: Array = [$Root/Utility/Switch, $Root/Utility/Close]
		var current = controls.find(get_viewport().gui_get_focus_owner())
		controls[posmod(current + (-1 if event.shift_pressed or code == KEY_UP else 1), controls.size())].grab_focus()
		get_viewport().set_input_as_handled()
	elif code in [KEY_LEFT, KEY_RIGHT]:
		get_viewport().set_input_as_handled()

func _current_dialog() -> Control:
	if $Root/Utility.visible: return null
	for path in ["Culture", "Confirm", "Pause", "Defeat", "Victory", "Dialogue", "Prologue"]:
		var panel = $Root.get_node(path)
		if panel.is_visible_in_tree(): return panel
	return null

func _dialog_buttons(panel: Control) -> Array[Button]:
	var result: Array[Button] = []
	for button in panel.find_children("*", "Button", true, false):
		if button.is_visible_in_tree() and not button.disabled:
			if panel == $Root/Prologue and $Root/Prologue.more_open and button not in [$Root/Prologue/ReplayVoice, $Root/Prologue/More]: continue
			result.append(button)
	return result

func _ready() -> void:
	for button in $Root.find_children("*", "Button", true, false):
		button.focus_mode = Control.FOCUS_NONE if $Root/HUD.is_ancestor_of(button) else Control.FOCUS_ALL
		if button.has_meta("action"):
			button.pressed.connect(_emit_button.bind(button))
		button.gui_input.connect($BladeCursor.on_button_input.bind(button))

func _emit_button(button: Button) -> void:
	action_requested.emit(str(button.get_meta("action")))

func present(game: Node) -> void:
	$Root/HUD.visible = game.state == "play"
	$Root/MainMenu.visible = game.state == "menu"
	$Root/Dialogue.visible = game.state == "dialogue"
	$Root/Pause.visible = game.state == "pause" and game.utility_panel.is_empty()
	$Root/Confirm.visible = game.state == "confirm"
	$Root/Defeat.visible = game.state == "dead"
	$Root/Victory.visible = game.state == "victory"
	$Root/Culture.visible = game.show_culture and game.state in ["menu", "victory"] and game.utility_panel.is_empty()
	$Root/HUD.present(game)
	$Root/Utility.visible = not game.utility_panel.is_empty()
	var helping: bool = game.utility_panel == "help"
	$Root/Utility/Body.visible = helping
	$Root/Utility/Body.set_demo_state(helping, game.reduced_motion, game.window_active, game.progress.error_text)
	$Root/Utility/Credits.visible = game.utility_panel == "credits"
	$Root/Utility/Settings.visible = game.utility_panel == "settings"
	$Root/Utility/Settings.present_preferences(game.muted, game.reduced_motion, game.window_active, game.utility_panel == "settings", game.progress.error_text)
	$Root/Utility/Switch.visible = helping
	$Root/Utility/Close.visible = helping
	$Root/Utility/Dimmer.color.a = 0.55
	$Root/MainMenu.set_controls_visible(game.utility_panel not in ["settings", "credits"])
	$Root/MainMenu/Start.text = "启程" if game.progress.intro_state() == "unseen" else "继续旅程"
	$Root/MainMenu/Start.add_theme_font_size_override("font_size", 64 if game.progress.intro_state() == "unseen" else 38)
	$Root/MainMenu.present_state(game.state == "menu" and not game.show_culture and game.utility_panel.is_empty(), game.muted, game.reduced_motion, game.window_active)
	$Root/Pause/Menu.text = "返回主菜单" if game.resume_state == "prologue" else "返回旅图"
	$Root/Pause/Menu.set_meta("action", "menu_confirm" if game.resume_state == "prologue" else "map_confirm")
	$Root/Confirm/Menu.text = "返回旅图" if game._confirm_to_map else "返回菜单"
	$Root/Confirm/Menu.set_meta("action", "map_exit" if game._confirm_to_map else "menu")
	$Root/Confirm/Description.text = "退出前情并返回主菜单，已有进度会保留。" if not game._confirm_to_map else "本次关内进度将丢失；通关记录与最佳成绩会保留。"
	$Root/Confirm/Cancel.text = "返回失败界面" if game._confirm_origin == "dead" else "继续游戏"
	$Root/Victory/Saved.text = game.progress.error_text
	$Root/Victory/Saved.visible = not game.progress.error_text.is_empty()
	$Root/MainMenu/Record.text = game.progress.error_text
	$Root/MainMenu/Record.visible = game.utility_panel.is_empty() and not game.progress.error_text.is_empty()
	if game.state == "dialogue" and not game.dialogue.is_empty():
		var line: Array = game.dialogue[game.dialogue_index]
		$Root/Dialogue/Speaker.text = str(line[0])
		$Root/Dialogue/Body.text = str(line[1])
	$Root/Defeat/Retry.text = "重试孔秀  ENTER" if not game.checkpoint.is_empty() else "从第一阵重试  ENTER"
	$Root/Defeat/Restart.visible = not game.checkpoint.is_empty()
	$Root/Defeat/Help.visible = not game.checkpoint.is_empty()
	if game.state == "victory" and _last_state != "victory": stats_expanded = false
	_last_state = game.state
	$Root/Victory/Score.text = "%d 分" % game.score
	$Root/Victory/Best.text = "最佳 %d" % game.best
	$Root/Victory/Stats.visible = stats_expanded
	$Root/Victory/Details.text = "收起战绩" if stats_expanded else "查看战绩"
	$Root/Victory/Stats.text = "战斗 %d 秒    剩余体力 %d / 6\n受击 %d 次    重试 %d 次" % [int(game.combat_seconds), game.hp, game.hits, game.retries]
	$Root/Culture/Body.text = game.story.culture
	$Root/Culture/Close.text = "查看结算" if game.state == "victory" else "返回"
	$Feedback.present(game)
	_refresh_dialog_focus()

func _refresh_dialog_focus() -> void:
	var panel = _current_dialog()
	if panel == _dialog_panel: return
	_dialog_panel = panel
	if panel == null or panel == $Root/Prologue or panel == $Root/Dialogue: return
	var controls = _dialog_buttons(panel)
	if not controls.is_empty(): _default_dialog_button(controls).grab_focus()

func _default_dialog_button(controls: Array[Button]) -> Button:
	for button in controls:
		if button.theme_type_variation == &"WuxiaPrimary": return button
	return controls[0]
