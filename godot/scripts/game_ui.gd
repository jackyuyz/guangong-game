extends CanvasLayer
## Native Controls own all layout, text wrapping, focus and mouse hit testing.
signal action_requested(action: String)
const OBJECTIVES = ["前往旗标", "练习挥刀", "练习闪避", "击退第一阵守军", "清除守军，前往关门", "关前对话", "击败孔秀", "关门已开"]

func _ready() -> void:
	for button in $Root.find_children("*", "Button", true, false):
		button.pressed.connect(_emit_action.bind(str(button.get_meta("action"))))
		button.gui_input.connect($BladeCursor.on_button_input.bind(button))

func _emit_action(action: String) -> void:
	action_requested.emit(action)

func present(game: Node) -> void:
	$Root/HUD.visible = game.state != "menu"
	$Root/MainMenu.visible = game.state == "menu"
	$Root/Dialogue.visible = game.state == "dialogue"
	$Root/Pause.visible = game.state == "pause"
	$Root/Confirm.visible = game.state == "confirm"
	$Root/Defeat.visible = game.state == "dead"
	$Root/Victory.visible = game.state == "victory"
	$Root/Culture.visible = game.show_culture and game.state in ["menu", "victory"]
	$Root/HUD/Health/HP.value = game.hp
	$Root/HUD/Extensions.text = game.ext.status_text(game)
	$Root/HUD/ObjectivePanel/Objective.text = "◆  " + OBJECTIVES[game.phase]
	$Root/HUD/Message.visible = game.message_time > 0
	$Root/HUD/Message/Text.text = game.message
	$Root/HUD/Controls/Dodge.text = "闪避就绪" if game.dodge_cooldown <= 0 else "闪避冷却…"
	$Root/HUD/Controls/Time.text = "%02d:%02d" % [int(game.combat_seconds) / 60, int(game.combat_seconds) % 60]
	$Root/HUD/Mute.text = "开声" if game.muted else "静音"
	$Root/HUD/BossHealth.visible = game.phase == 6 and not game.enemies.is_empty()
	if $Root/HUD/BossHealth.visible:
		var boss: Dictionary = game.enemies[0]
		$Root/HUD/BossHealth/Name.text = "孔秀" + ("  ·  奋战" if boss.hp <= 8 else "  ·  东岭守将")
		$Root/HUD/BossHealth/HP.value = boss.hp
	var sound = "声音：关" if game.muted else "声音：开"
	$Root/MainMenu/Mute.text = sound
	$Root/Pause/Mute.text = sound
	$Root/MainMenu/Record.text = "最佳纪录  %d" % game.best if game.cleared else "护送二位夫人，闯过东岭关。"
	if game.state == "dialogue" and not game.dialogue.is_empty():
		var line: Array = game.dialogue[game.dialogue_index]
		$Root/Dialogue/Speaker.text = str(line[0])
		$Root/Dialogue/Body.text = str(line[1])
	$Root/Defeat/Retry.text = "重试孔秀  ENTER" if not game.checkpoint.is_empty() else "从第一阵重试  ENTER"
	$Root/Victory/Score.text = str(game.score)
	$Root/Victory/Best.text = "本次得分    /    最佳 %d" % game.best
	$Root/Victory/Stats.text = "战斗 %ds    剩余 %d / 6    受击 %d    重试 %d" % [int(game.combat_seconds), game.hp, game.hits, game.retries]
	$Root/Culture/Body.text = game.story.culture
	$Root/Culture/Close.text = "查看结算" if game.state == "victory" else "返回"
