extends RefCounted
## Save-free mechanics for the isolated Luoyang readability prototype.
const LANE_SECONDS = 0.20
const STAGE_SECONDS = 28.0
const ROAD_SPEED = 22.0
const SPAWN_DISTANCE = 88.0
const AIM_SECONDS = 1.10
const LOCK_SECONDS = 0.45
const ARROW_SPEED = 72.0
const PATTERN = [[0], [-1], [1], [-1, 0], [0, 1], [-1, 1], [0], [-1, 0]]

var mode = "course"
var stage = "barricades"
var state = "ready"
var hp = 4
var hits = 0
var switches = 0
var retries = 0
var checkpoint_hits = 0
var checkpoint_switches = 0
var elapsed = 0.0
var distance = 0.0
var invulnerable = 0.0
var slowdown = 0.0
var lane = 0.0
var target_lane = 0
var from_lane = 0.0
var lane_time = LANE_SECONDS
var queued_direction = 0
var next_spawn = 1.0
var spawn_index = 0
var hazards: Array[Dictionary] = []
var serial = 0
var events: Array[String] = []

func start(selected_mode: String) -> void:
	mode = selected_mode if selected_mode in ["course", "barricades", "arrows"] else "course"
	retries = 0
	hits = 0
	switches = 0
	checkpoint_hits = 0
	checkpoint_switches = 0
	_begin_stage("arrows" if mode == "arrows" else "barricades")

func _begin_stage(selected_stage: String) -> void:
	stage = selected_stage
	state = "running"
	hp = 4
	elapsed = 0.0
	distance = 0.0
	invulnerable = 0.0
	slowdown = 0.0
	lane = 0.0
	target_lane = 0
	from_lane = 0.0
	lane_time = LANE_SECONDS
	queued_direction = 0
	next_spawn = 1.0
	spawn_index = 0
	hazards.clear()
	events.clear()

func request_lane(direction: int) -> void:
	if state != "running" or direction == 0:
		return
	direction = signi(direction)
	if lane_time < LANE_SECONDS:
		queued_direction = direction
		return
	var destination = clampi(target_lane + direction, -1, 1)
	if destination == target_lane:
		return
	from_lane = lane
	target_lane = destination
	lane_time = 0.0
	switches += 1

func pause() -> void:
	if state == "running":
		state = "paused"
	queued_direction = 0

func resume() -> void:
	if state == "paused":
		state = "running"

func retry() -> void:
	if state not in ["failed", "paused", "complete"]:
		return
	retries += 1
	if mode == "course" and stage == "arrows":
		hits = checkpoint_hits
		switches = checkpoint_switches
	else:
		hits = 0
		switches = 0
	_begin_stage(stage)

func step(delta: float) -> void:
	if state != "running":
		return
	# Substeps keep crossing checks and lane interpolation consistent at low FPS.
	var remaining = maxf(0.0, delta)
	while remaining > 0.000001 and state == "running":
		var dt = minf(remaining, 1.0 / 120.0)
		_tick(dt)
		remaining -= dt

func _tick(dt: float) -> void:
	elapsed += dt
	invulnerable = maxf(0.0, invulnerable - dt)
	slowdown = maxf(0.0, slowdown - dt)
	lane_time = minf(LANE_SECONDS, lane_time + dt)
	var t = lane_time / LANE_SECONDS
	lane = lerpf(from_lane, float(target_lane), t * t * (3.0 - 2.0 * t))
	if lane_time >= LANE_SECONDS and queued_direction != 0:
		var direction = queued_direction
		queued_direction = 0
		request_lane(direction)
	var speed = ROAD_SPEED * (0.55 if slowdown > 0.0 else 1.0)
	distance += speed * dt
	_spawn_due()
	_advance_hazards(dt, speed)
	_finish_tick()

func _spawn_due() -> void:
	if elapsed >= next_spawn and next_spawn < 23.0:
		if stage == "barricades":
			for occupied_lane in PATTERN[spawn_index % PATTERN.size()]:
				_add_hazard("barricade", occupied_lane)
			next_spawn += 2.8
		else:
			_add_hazard("arrow", clampi(roundi(lane), -1, 1))
			next_spawn += 3.4
		spawn_index += 1

func _advance_hazards(dt: float, speed: float) -> void:
	for hazard in hazards:
		hazard.age += dt
		if hazard.kind == "barricade":
			hazard.distance -= speed * dt
		else:
			var aim_seconds: float = hazard.get("aim_seconds", AIM_SECONDS)
			var lock_seconds: float = hazard.get("lock_seconds", LOCK_SECONDS)
			if hazard.phase == "aim":
				hazard.lane = clampi(roundi(lane), -1, 1)
				if hazard.age >= aim_seconds:
					hazard.phase = "locked"
					events.append("lock")
			elif hazard.phase == "locked" and hazard.age >= aim_seconds + lock_seconds:
				hazard.phase = "flying"
				events.append("release")
			elif hazard.phase == "flying":
				hazard.distance -= float(hazard.get("speed", ARROW_SPEED)) * dt
		if hazard.distance <= 0.0 and not hazard.resolved:
			hazard.resolved = true
			var half_width = 0.43 if hazard.kind == "barricade" else 0.32
			if absf(lane - float(hazard.lane)) < half_width:
				_hit(hazard.kind)
		if state != "running":
			break
	hazards = hazards.filter(func(hazard: Dictionary) -> bool: return hazard.distance > -18.0)

func _finish_tick() -> void:
	if state == "running" and elapsed >= STAGE_SECONDS and hazards.is_empty():
		if mode == "course" and stage == "barricades":
			checkpoint_hits = hits
			checkpoint_switches = switches
			_begin_stage("arrows")
			events.append("stage")
		else:
			state = "complete"
			queued_direction = 0
			events.append("complete")

func _add_hazard(kind: String, occupied_lane: int) -> void:
	serial += 1
	hazards.append({"id": serial, "kind": kind, "lane": occupied_lane,
		"distance": SPAWN_DISTANCE, "age": 0.0, "phase": "aim", "resolved": false})

func _hit(kind: String) -> void:
	if invulnerable > 0.0 or state != "running":
		return
	hp = maxi(0, hp - 1)
	hits += 1
	invulnerable = 0.8
	if kind == "barricade":
		slowdown = 0.6
	events.append("hit")
	if hp == 0:
		state = "failed"
		queued_direction = 0
		events.append("failed")
