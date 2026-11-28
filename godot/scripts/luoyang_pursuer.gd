extends RefCounted
## Meng Tan shares the player's road/rows, but owns his own continuous lane position.
const CHANGE_SECONDS = 0.55
const LOOK_AHEAD = 48.0
const REAR_CLEARANCE = 7.0
const ROAM_INTERVAL = 3.8
var lane = 1.0
var from_lane = 1.0
var target_lane = 1
var lane_time = CHANGE_SECONDS
var elapsed = 0.0
var next_roam = 0.45
var roam_direction = -1
var changes = 0
var avoiding = false

func reset() -> void:
	lane = 1.0
	from_lane = lane
	target_lane = 1
	lane_time = CHANGE_SECONDS
	elapsed = 0.0
	next_roam = 0.45
	roam_direction = -1
	changes = 0
	avoiding = false

func step(dt: float, depth: float, hazards: Array[Dictionary], allow_roam: bool = true) -> void:
	elapsed += dt
	lane_time = minf(CHANGE_SECONDS, lane_time + dt)
	var t = lane_time / CHANGE_SECONDS
	lane = lerpf(from_lane, float(target_lane), t * t * (3.0 - 2.0 * t))
	# Keep the chosen gap until this row has cleared the horse's rear, not just its feet.
	var nearest = INF
	for h in hazards:
		var relative: float = h.distance - depth
		if h.kind == "barricade" and relative >= -REAR_CLEARANCE and relative <= LOOK_AHEAD:
			nearest = minf(nearest, h.distance)
	var blocked: Array[int] = []
	if is_finite(nearest):
		for h in hazards:
			if h.kind == "barricade" and absf(h.distance - nearest) < 0.1:
				blocked.append(int(h.lane))
	avoiding = not blocked.is_empty()
	if avoiding:
		if target_lane in blocked:
			var destination = target_lane
			var best = INF
			for candidate in [-1, 0, 1]:
				if candidate not in blocked and absf(candidate - lane) < best:
					best = absf(candidate - lane)
					destination = candidate
			_change_lane(destination)
		next_roam = maxf(next_roam, elapsed + 0.8)
	elif allow_roam and lane_time >= CHANGE_SECONDS and elapsed >= next_roam:
		if target_lane + roam_direction not in [-1, 0, 1]:
			roam_direction *= -1
		_change_lane(target_lane + roam_direction)
		next_roam = elapsed + ROAM_INTERVAL

func _change_lane(destination: int) -> void:
	if destination == target_lane:
		return
	from_lane = lane
	target_lane = destination
	lane_time = 0.0
	changes += 1
