extends Node2D
## Pure sampling of the existing projectile state: no separate clock or hit logic.
@export var flight_height = 48.0
@export var sprite_height = 120.0
@export var minimum_screen_scale = 0.24
@export var trail_seconds = 0.12

func sample(hazard: Dictionary, road: Node2D, reduced_motion: bool) -> void:
	$Shaft.hide()
	$Head.hide()
	var flying: bool = hazard.phase == "flying"
	$Flight.visible = flying
	$Wake.visible = flying and not reduced_motion
	$Ground.visible = flying
	if not flying: return
	var depth: float = hazard.distance
	var lane: float = hazard.lane
	var factor: float = road.factor(depth)
	var direction: Vector2 = (road.project(lane, depth - 0.5) - road.project(lane, depth)).normalized()
	if direction.is_zero_approx(): direction = Vector2.DOWN
	$Flight.position = Vector2(0.0, -flight_height)
	$Flight.rotation = direction.angle() - PI / 2.0
	$Flight.scale = Vector2.ONE * maxf(1.0, minimum_screen_scale / factor)
	# The wake follows previous road projections, rather than a vertical screen line.
	var points = PackedVector2Array()
	var speed: float = hazard.get("speed", 72.0)
	var elapsed: float = maxf(0.0, hazard.age - float(hazard.get("aim_seconds", 1.1)) - float(hazard.get("lock_seconds", 0.45)))
	for fraction in [0.0, 0.3, 0.65, 1.0]:
		var previous_depth = depth + speed * minf(elapsed, trail_seconds * fraction)
		var previous_factor: float = road.factor(previous_depth)
		var tip: Vector2 = road.project(lane, previous_depth) - position + Vector2(0, -flight_height * previous_factor)
		var behind_feathers = direction * sprite_height * maxf(previous_factor, minimum_screen_scale)
		points.append((tip - behind_feathers) / factor)
	$Wake/Trail.points = points
	$Wake/Core.points = points
	var proximity = clampf(1.0 - depth / 65.0, 0.0, 1.0)
	var exit_fade = clampf((depth + 12.0) / 12.0, 0.0, 1.0)
	$Wake.modulate.a = lerpf(0.25, 0.85, proximity) * exit_fade
	for i in 2:
		var slip: Line2D = $Wake.get_node("Slip%d" % i)
		slip.visible = depth < 42.0
		var side = -1.0 if i == 0 else 1.0
		var perpendicular = Vector2(-direction.y, direction.x)
		var offset = perpendicular * side * lerpf(10.0, 19.0, proximity)
		var lead = Vector2(0, -flight_height) + offset - direction * 18.0
		slip.points = PackedVector2Array([lead, lead - direction * lerpf(24.0, 65.0, proximity)])
	# Ghosts reuse the image with subtle opacity, never a second damaging projectile.
	$Flight/Ghost.visible = not reduced_motion
	$Flight/Ghost.position = Vector2(0, -lerpf(8.0, 21.0, proximity))
	$Flight/Ghost.modulate.a = lerpf(0.06, 0.18, proximity) * exit_fade
