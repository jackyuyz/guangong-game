extends CanvasLayer
## Native Controls own all layout, text wrapping, focus and mouse hit testing.
signal action_requested(action: String)
var stats_expanded = false
var _last_state = ""
var _utility_focus: Control

func remember_utility_focus() -> void:
	_utility_focus = get_viewport().gui_get_focus_owner()

func restore_utility_focus() -> void:
	if is_instance_valid(_utility_focus) and _utility_focus.is_visible_in_tree():
		_utility_focus.grab_focus()

func focus_utility() -> void:
	var target = $Root/Utility/Close if $Root/Utility/Body.visible else $Root/Utility/Settings/Mute
	target.grab_focus()

func _input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed: return
	var code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	if not $Root/Utility.visible:
		if not $Root/MainMenu.visible or not $Root/MainMenu.active: return
		var entries: Array = [$Root/MainMenu/Start, $Root/MainMenu/Culture, $Root/MainMenu/Mute]
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
	if code in [KEY_TAB, KEY_UP, KEY_DOWN]:
		var controls: Array = [$Root/Utility/Switch, $Root/Utility/Close] if $Root/Utility/Body.visible else [$Root/Utility/Settings/Mute, $Root/Utility/Settings/Motion, $Root/Utility/Settings/Help, $Root/Utility/Close]
		var current = controls.find(get_viewport().gui_get_focus_owner())
		controls[posmod(current + (-1 if event.shift_pressed or code == KEY_UP else 1), controls.size())].grab_focus()
		get_viewport().set_input_as_handled()
	elif code in [KEY_LEFT, KEY_RIGHT]:
		get_viewport().set_input_as_handled()

const OBJECTIVES = ["前往旗标", "练习挥刀", "练习闪避", "击退第一阵守军", "清除守军，前往关门", "关前对话", "击败孔秀", "关门已开"]

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
	$Root/Pause.visible = game.state == "pause"
	$Root/Confirm.visible = game.state == "confirm"
	$Root/Defeat.visible = game.state == "dead"
	$Root/Victory.visible = game.state == "victory"
	$Root/Culture.visible = game.show_culture and game.state in ["menu", "victory"]
	$Root/HUD/Health/HP.value = game.hp
	$Root/HUD/Extensions.visible = game.phase >= 3 and game.phase < 7
	$Root/HUD/Extensions.text = "义气 %d/%d   L 偃月斩%s" % [game.ext.resource, game.ext.RESOURCE_MAX, " · 就绪" if game.ext.heavy_ready() else ""]
	if game.ext.can_rest(game): $Root/HUD/Extensions.text += "   E 歇脚"
	$Root/HUD/Controls/Backdrop.visible = game.phase < 3
	$Root/HUD/Controls/Keys.visible = game.phase < 3
	$Root/HUD/Controls/Keys.text = ["A / D  移动", "J  挥刀，连按三段", "SPACE  闪避"][mini(game.phase, 2)]
	$Root/HUD/ObjectivePanel/Objective.text = "◆  " + OBJECTIVES[game.phase]
	$Root/HUD/Message.visible = game.message_time > 0 and game.phase >= 3
	$Root/HUD/Message/Text.text = game.message
	$Root/HUD/Controls/Dodge.visible = game.dodge_cooldown > 0
	$Root/HUD/Controls/Dodge.text = "闪避冷却…"
	$Root/HUD/Mute.text = "开声" if game.muted else "静音"
	$Root/HUD/BossHealth.visible = game.phase == 6 and not game.enemies.is_empty()
	if $Root/HUD/BossHealth.visible:
		var boss: Dictionary = game.enemies[0]
		$Root/HUD/BossHealth/Name.text = "孔秀" + ("  ·  奋战" if boss.hp <= 8 else "  ·  东岭守将")
		$Root/HUD/BossHealth/HP.value = boss.hp
	var sound = "声音：关" if game.muted else "声音：开"
	$Root/Utility.visible = not game.utility_panel.is_empty()
	var helping: bool = game.utility_panel == "help"
	$Root/Utility/Title.text = "操作指南" if helping else "设置"
	$Root/Utility/Body.visible = helping
	$Root/Utility/Body.set_demo_state(helping and not game.utility_panel.is_empty(), game.reduced_motion, game.window_active, game.progress.error_text)
	$Root/Utility/Card.visible = not helping
	$Root/Utility/Title.visible = not helping
	$Root/Utility/Rule.visible = not helping
	$Root/Utility/Settings.visible = not helping
	$Root/Utility/Switch.visible = helping
	$Root/Utility/Settings/Mute.text = sound
	$Root/Utility/Settings/Motion.text = "减少动态：开" if game.reduced_motion else "减少动态：关"
	$Root/Utility/SaveNotice.text = game.progress.error_text
	$Root/Utility/SaveNotice.visible = not helping and not game.progress.error_text.is_empty()
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
	$Root/MainMenu/Record.visible = not game.progress.error_text.is_empty()
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
