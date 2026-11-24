extends Control
## Dialogue-only staging; these portraits never become combat actors.
@onready var guan: Sprite2D = $Portraits/GuanYu
@onready var kong: Sprite2D = $Portraits/KongXiu
@onready var guan_origin: Vector2 = guan.position
@onready var kong_origin: Vector2 = kong.position
var _duel = false
var _active = false
var _reduced = false
var _entrance = 1.0
var _speaker = ""

func present(game: Node) -> void:
	var in_conversation: bool = game.state == "dialogue" or (game.state in ["pause", "confirm"] and game.resume_state == "dialogue")
	var next_duel: bool = in_conversation and game.phase == 5 and not game.dialogue.is_empty()
	_reduced = game.reduced_motion
	if next_duel and not _duel: _entrance = 1.0 if _reduced else 0.0
	_duel = next_duel
	_active = _duel and game.state == "dialogue" and game.window_active
	$Portraits.visible = _duel
	$Dimmer.visible = _duel
	if game.state == "dialogue" and not game.dialogue.is_empty():
		var line: Array = game.dialogue[game.dialogue_index]
		_speaker = str(line[0])
		$Speaker.text = _speaker
		$Body.text = str(line[1])
	if _reduced: _entrance = 1.0
	_paint()

func _process(dt: float) -> void:
	if not _active or _entrance >= 1.0: return
	_entrance = minf(1.0, _entrance + dt / 0.24)
	_paint()

func _paint() -> void:
	var amount = 1.0 - pow(1.0 - _entrance, 3.0)
	$Portraits.modulate.a = amount
	guan.position = guan_origin + Vector2(-28.0 * (1.0 - amount), -4.0 if _speaker == "关羽" else 0.0)
	kong.position = kong_origin + Vector2(28.0 * (1.0 - amount), -4.0 if _speaker == "孔秀" else 0.0)
	guan.modulate = Color.WHITE if _speaker == "关羽" else Color(0.50, 0.55, 0.51, 1)
	kong.modulate = Color.WHITE if _speaker == "孔秀" else Color(0.50, 0.55, 0.51, 1)
	$Portraits/GuanMark.visible = _speaker == "关羽"
	$Portraits/KongMark.visible = _speaker == "孔秀"
