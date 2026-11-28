extends "res://scripts/luoyang_model.gd"
## Full chapter session. Persistence belongs to the host, never this model.
const INITIAL_GAP = 78.0
const CATCH_GAP = 10.0
const CLOSING_SPEED = 2.0
const CATCH_LANE_TOLERANCE = 0.22
const CLOSE_APPROACH = 24.0
const BREAKAWAY_SECONDS = 1.0
const BREAKAWAY_SPEED = 10.0
const CHASE_LIMIT = 65.0
const SPRINT_SECONDS = 32.0
const Story = preload("res://scripts/luoyang_story.gd")
const Finale = preload("res://scripts/luoyang_finale.gd")
const Pacing = preload("res://scripts/luoyang_pacing.gd")
const GAP_PENALTY = 21.0
const STORY_SECONDS = {"intro": Story.INTRO_SECONDS, "meng_strike": 2.4, "ambush": Story.AMBUSH_SECONDS, "han_strike": 2.4, "ending": Finale.ENDING_SECONDS, "escape": Finale.ESCAPE_SECONDS, "fall": 0.8}
var phase = "intro"
var phase_clock = 0.0
var resume_kind = "running"
var gap = INITIAL_GAP
var seconds = 0.0
var wounded = false
var wound_events = 0
var meng_defeated = false
var han_defeated = false
var victory_locked = false
var failure_reason = ""
var escape_origin = Vector2.ZERO
var gap_recoil = 0.0
var breakaway_left = 0.0
var breakaway_notice = 0.0
var breakaways = 0
var _pursuer_dt = 0.0
var tutorial_directions: Array[int] = []
var checkpoint: Dictionary = {}
var pursuer = preload("res://scripts/luoyang_pursuer.gd").new()

func start(_selected_mode: String = "chapter") -> void:
	mode = "chapter"
	retries = 0
	hits = 0
	switches = 0
	seconds = 0.0
	wounded = false
	wound_events = 0
	meng_defeated = false
	han_defeated = false
	victory_locked = false
	gap = INITIAL_GAP
	pursuer.reset()
	tutorial_directions.clear()
	checkpoint.clear()
	escape_origin = Vector2.ZERO
	gap_recoil = 0.0
	breakaway_left = 0.0
	breakaway_notice = 0.0
	breakaways = 0
	_begin_stage("barricades")
	_story("intro")

func _story(selected_phase: String) -> void:
	phase = selected_phase
	phase_clock = 0.0
	state = "story"
	hazards.clear()
	queued_direction = 0
	lane_time = LANE_SECONDS
	from_lane = lane
	target_lane = roundi(lane)
	events.append("phase")

func _begin_play(selected_phase: String) -> void:
	_begin_stage("arrows" if selected_phase == "sprint" else "barricades")
	pursuer.reset()
	phase = selected_phase
	phase_clock = 0.0
	failure_reason = ""
	escape_origin = Vector2.ZERO
	gap_recoil = 0.0
	breakaway_left = 0.0
	breakaway_notice = 0.0
	breakaways = 0
	if phase == "chase": next_spawn = Pacing.ROWS[0][0]
	elif phase == "sprint": next_spawn = Pacing.SHOTS[0]
	if phase == "chase":
		gap = INITIAL_GAP
		hits = 0
		switches = 0
		seconds = 0.0
	if phase in ["chase", "sprint"]:
		checkpoint = {"phase": phase, "seconds": seconds, "hits": hits, "switches": switches, "wounded": wounded}
	events.append("phase")

func request_lane(direction: int) -> void:
	var previous = switches
	super.request_lane(direction)
	if phase == "tutorial" and switches > previous and signi(direction) not in tutorial_directions:
		tutorial_directions.append(signi(direction))

func step(delta: float) -> void:
	var remaining = maxf(0.0, delta)
	while remaining > 0.000001 and state in ["running", "story"]:
		var dt = minf(remaining, 1.0 / 120.0)
		if state == "story":
			phase_clock += dt
			if phase_clock >= float(STORY_SECONDS.get(phase, 999.0)):
				_next_story()
		else:
			_tick(dt)
		remaining -= dt

func _tick(dt: float) -> void:
	# Door arrival wins a simultaneous projectile contact; an earlier failure stays final.
	if phase == "sprint" and elapsed + dt >= SPRINT_SECONDS:
		seconds += maxf(0.0, SPRINT_SECONDS - elapsed)
		elapsed = SPRINT_SECONDS
		han_defeated = true
		victory_locked = true
		_story("han_strike")
		events.append("victory")
		return
	if phase in ["chase", "sprint"]:
		seconds += dt
	if phase == "chase":
		breakaway_notice = maxf(0.0, breakaway_notice - dt)
		var burst = minf(breakaway_left, dt)
		gap += BREAKAWAY_SPEED * burst
		breakaway_left = maxf(0.0, breakaway_left - dt)
		# A hit opens distance over the horse's actual recovery, avoiding an enemy teleport.
		var pushed = minf(gap_recoil, (GAP_PENALTY - Pacing.GAP_IMPACT) / Pacing.GAP_RECOIL_SECONDS * dt)
		gap += pushed
		gap_recoil -= pushed
		gap = maxf(CATCH_GAP, gap - CLOSING_SPEED * dt * (0.55 if slowdown > 0.0 else 1.0))
	_pursuer_dt = dt
	super._tick(dt)
	if state == "running":
		phase_clock = elapsed

func _spawn_due() -> void:
	if elapsed < next_spawn:
		return
	if phase == "tutorial":
		_add_hazard("barricade", 0)
		next_spawn += 5.0
	elif phase == "chase":
		while spawn_index < Pacing.ROWS.size() and elapsed >= Pacing.ROWS[spawn_index][0]:
			var row: Array = Pacing.ROWS[spawn_index]
			spawn_index += 1
			next_spawn = Pacing.ROWS[spawn_index][0] if spawn_index < Pacing.ROWS.size() else INF
			# Consume close-approach beats too: a later collision must not replay a backlog.
			if gap <= CLOSE_APPROACH: continue
			for occupied_lane in row[1]:
				_add_hazard("barricade", occupied_lane)
				hazards[-1].distance = maxf(SPAWN_DISTANCE, gap + pursuer.LOOK_AHEAD)
	elif phase == "sprint" and spawn_index < Pacing.SHOTS.size():
		_add_hazard("arrow", clampi(roundi(lane), -1, 1))
		spawn_index += 1
		next_spawn = Pacing.SHOTS[spawn_index] if spawn_index < Pacing.SHOTS.size() else INF

func _add_hazard(kind: String, occupied_lane: int) -> void:
	super._add_hazard(kind, occupied_lane)
	if kind == "arrow":
		var profile = Pacing.shot_profile(spawn_index)
		for key in profile: hazards[-1][key] = profile[key]

func _finish_tick() -> void:
	if state != "running":
		return
	if phase == "tutorial" and tutorial_directions.size() == 2 and elapsed >= 1.5 and lane_time >= LANE_SECONDS:
		_begin_play("chase")
	elif phase == "chase":
		# Hazards and the player already moved; sample the enemy before capture.
		pursuer.step(_pursuer_dt, gap, hazards, gap > CLOSE_APPROACH)
		if gap <= CATCH_GAP and breakaway_left <= 0.0 and catch_lane_aligned():
			meng_defeated = true
			_story("meng_strike")
		elif elapsed >= CHASE_LIMIT:
			_fail("孟坦逃脱")
		elif gap <= CATCH_GAP and breakaway_left <= 0.0:
			breakaway_left = BREAKAWAY_SECONDS
			breakaway_notice = 1.8
			breakaways += 1
			events.append("breakaway")

func catch_lane_aligned() -> bool:
	# Do not count a requested lane or two horses crossing between lanes as a catch.
	return target_lane == pursuer.target_lane and absf(lane - pursuer.lane) <= CATCH_LANE_TOLERANCE and absf(lane - target_lane) <= CATCH_LANE_TOLERANCE and absf(pursuer.lane - target_lane) <= CATCH_LANE_TOLERANCE

func _hit(kind: String) -> void:
	if phase == "tutorial" or victory_locked:
		return
	var previous = hits
	super._hit(kind)
	if hits > previous and phase == "chase":
		gap += Pacing.GAP_IMPACT
		gap_recoil += GAP_PENALTY - Pacing.GAP_IMPACT
	if state == "failed":
		_fail("气血耗尽")

func _fail(reason: String) -> void:
	failure_reason = reason
	escape_origin = Vector2(pursuer.lane, gap)
	_story("escape" if reason == "孟坦逃脱" else "fall")

func advance_story(expected_phase: String) -> void:
	if state != "story" or phase != expected_phase or phase_clock < 0.25 or phase in ["fall", "escape"]:
		return
	_next_story()

func _next_story() -> void:
	match phase:
		"intro": _begin_play("tutorial")
		"meng_strike": _story("ambush")
		"ambush":
			if not wounded:
				wounded = true
				wound_events += 1
			_begin_play("sprint")
		"han_strike": _story("ending")
		"ending":
			phase = "culture"
			state = "culture"
			phase_clock = 0.0
			events.append("phase")
		"fall", "escape":
			state = "failed"
			events.append("failed")

func finish_culture() -> void:
	if state == "culture" and victory_locked:
		state = "complete"
		phase = "result"
		events.append("complete")

func pause() -> void:
	if state in ["running", "story", "culture"]:
		resume_kind = state
		state = "paused"
	queued_direction = 0

func resume() -> void:
	if state == "paused":
		state = resume_kind

func retry() -> void:
	if state not in ["failed", "paused"] or victory_locked:
		return
	if checkpoint.is_empty():
		start()
		return
	var saved = checkpoint.duplicate(true)
	retries += 1
	hits = int(saved.hits)
	switches = int(saved.switches)
	seconds = float(saved.seconds)
	wounded = bool(saved.wounded)
	meng_defeated = wounded
	wound_events = 1 if wounded else 0
	_begin_play(str(saved.phase))

func result() -> Dictionary:
	return {"seconds": seconds, "hits": hits, "retries": retries, "switches": switches}
