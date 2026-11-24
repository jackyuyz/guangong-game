extends Node2D
## Ground-space warning geometry is separate from the enemy art and damage rules.
@onready var authored_scale = scale

func present(direction: float, reach: float, sweep: bool, striking: bool) -> void:
	# At exact overlap the existing combat direction can be zero; keep the tell visible.
	var facing = -1.0 if direction < 0.0 else 1.0
	scale = authored_scale * Vector2(facing * reach / 190.0, 1.0)
	$Sweep.visible = sweep
	$Thrust.visible = not sweep
	modulate.a = 1.0 if striking else 0.72
