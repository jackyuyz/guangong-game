extends Node2D
## Presentation only: the whole upcoming threat stays visible throughout the attack.
@onready var authored_scale = scale
@onready var authored_position = position
var _mode = ""
var _move = -1
var _facing = 1.0
var _previous_time = 0.0
var _windup_total = 0.65
var _origin = 0.0

func present(enemy: Dictionary, reach: float, sweep: bool, road_limits: Vector2) -> void:
	# At exact overlap the existing combat direction can be zero; keep the tell visible.
	var facing = -1.0 if enemy.facing < 0.0 else 1.0
	var windup: bool = enemy.mode == "windup"
	var striking: bool = enemy.mode == "strike"
	var new_attack: bool = _move != enemy.move or _facing != facing or (windup and (_mode != "windup" or enemy.timer > _previous_time + 0.001))
	if new_attack or (_mode not in ["windup", "strike"] and striking):
		_origin = enemy.x
		_windup_total = maxf(0.001, enemy.timer)
	# A guard can be pushed while winding up. Follow that real origin before release.
	if windup or (striking and not enemy.boss): _origin = enemy.x
	var endpoint: float = enemy.x
	if windup or striking:
		# Existing main.gd advances a 390px/s lunge, including up to one capped 40ms
		# last tick. Show the conservative whole envelope without changing those rules.
		var travel = 390.0 * (0.24 + 0.04) if enemy.boss and not sweep else 0.0
		endpoint = clampf(_origin + facing * travel, road_limits.x, road_limits.y)
	else:
		_origin = enemy.x
	var rear = _origin - facing * 25.0
	var front = endpoint + facing * reach
	var actor_scale: float = maxf(absf(get_parent().scale.x), 0.001)
	position = authored_position + Vector2((rear - enemy.x) / actor_scale, 0)
	scale = authored_scale * Vector2(facing * absf(front - rear) / (190.0 * actor_scale), 1.0)
	$Sweep.visible = sweep
	$Thrust.visible = not sweep
	var progress = clampf(1.0 - enemy.timer / _windup_total, 0, 1) if windup else 1.0
	var shape: Node2D = $Sweep if sweep else $Thrust
	shape.get_node("Charge").scale.x = maxf(0.015, progress)
	$Timing.position.x = progress * 190.0
	$Timing.scale.y = 1.7 if sweep else 0.9
	$Timing.modulate.a = 0.45 + progress * 0.55
	$Limit.modulate.a = 0.65 + progress * 0.35
	modulate.a = 1.0 if striking else 0.72 + progress * 0.28
	_mode = enemy.mode
	_move = enemy.move
	_facing = facing
	_previous_time = enemy.timer
