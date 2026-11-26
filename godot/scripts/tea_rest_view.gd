extends Node2D
## The stall remains part of the world; only its nearby interaction is conditional.
var steam_time = 0.0
var active = false
var reduced = false
var used = false
var _was_recovering = false

func _exit_tree() -> void:
	$Sip.stop()

func present(game: Node) -> void:
	active = game.state == "play" and game.window_active
	reduced = game.reduced_motion
	used = game.ext.rest_used
	visible = true
	var nearby: bool = absf(game.x - game.rest_x) <= game.ext.REST_RANGE
	$Hint.visible = nearby and (game.ext.can_rest(game) or used) and game.phase == 4
	$Hint/Key.visible = not used
	$Hint/Caption.text = "已歇脚" if used else "歇脚"
	var recovering: bool = game.ext.rest_feedback > 0
	if recovering and not _was_recovering and not game.muted: $Sip.play()
	if not recovering: $Sip.stop()
	$Sip.stream_paused = not active
	$Sip.volume_db = -80 if game.muted else -13
	_was_recovering = recovering
	_paint_steam()

func _process(dt: float) -> void:
	if not active or reduced: return
	steam_time += dt
	_paint_steam()

func _paint_steam() -> void:
	for i in $Steam.get_child_count():
		var wisp: Line2D = $Steam.get_child(i)
		var age = fposmod(steam_time * .42 + float(i) / 3.0, 1.0)
		wisp.position = Vector2(sin(age * TAU + i) * 2, -age * 20)
		wisp.modulate.a = (.12 if reduced else sin(age * PI) * .3) * (.55 if used else 1.0)
