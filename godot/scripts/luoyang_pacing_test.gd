extends SceneTree
const Chapter = preload("res://scripts/luoyang_chapter_model.gd")
const Pacing = preload("res://scripts/luoyang_pacing.gd")
var checks = 0
var failures = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)
func chase(dt: float, initial: int, reaction: float, penalties = 0) -> Dictionary:
	var m = Chapter.new()
	m.start()
	m._begin_play("chase")
	m.lane = initial
	m.from_lane = initial
	m.target_lane = initial
	var respond_at = INF
	var direction = 0
	var applied = 0
	var seen: Dictionary = {}
	var arrivals: Array[float] = []
	for frame in int(66.0 / dt):
		if m.phase != "chase": break
		if applied < penalties and m.elapsed >= [8.0, 18.0, 28.0][applied]:
			m._hit("barricade")
			applied += 1
		if m.elapsed >= respond_at:
			m.request_lane(direction)
			respond_at = INF
		var nearest = INF
		for h in m.hazards:
			if not h.resolved and h.distance <= Pacing.READABLE_DEPTH: nearest = minf(nearest, h.distance)
		var blocked: Array[int] = []
		for h in m.hazards:
			if not h.resolved and absf(h.distance - nearest) < 0.1: blocked.append(h.lane)
		if m.target_lane in blocked and m.lane_time >= m.LANE_SECONDS and not is_finite(respond_at):
			var safe = 0
			var best = INF
			for candidate in [-1, 0, 1]:
				if candidate not in blocked and absf(candidate - m.lane) < best:
					safe = candidate
					best = absf(candidate - m.lane)
			direction = signi(safe - m.target_lane)
			respond_at = m.elapsed + reaction
		m.step(dt)
		for h in m.hazards:
			if not seen.has(h.id):
				seen[h.id] = true
				if arrivals.is_empty() or absf(arrivals[-1] - (m.elapsed + h.distance / m.ROAD_SPEED)) > 0.1:
					arrivals.append(m.elapsed + h.distance / m.ROAD_SPEED)
	var spacing = INF
	for i in range(1, arrivals.size()): spacing = minf(spacing, arrivals[i] - arrivals[i - 1])
	return {"phase": m.phase, "seconds": m.seconds, "hits": m.hits, "hp": m.hp, "row_spacing": spacing, "rows": arrivals.size()}
func sprint(dt: float, initial: int, reaction: float) -> Dictionary:
	var m = Chapter.new()
	m.start()
	m.wounded = true
	m._begin_play("sprint")
	m.lane = initial
	m.from_lane = initial
	m.target_lane = initial
	var pending = INF
	var seen: Dictionary = {}
	var shots = 0
	var max_active = 0
	for frame in int(33.0 / dt):
		if m.phase != "sprint": break
		if m.elapsed >= pending:
			m.request_lane(-1 if m.target_lane >= 0 else 1)
			pending = INF
		var active = 0
		for h in m.hazards:
			if not h.resolved: active += 1
			if h.phase == "locked" and not seen.has(h.id):
				seen[h.id] = true
				shots += 1
				pending = m.elapsed + reaction
		max_active = maxi(max_active, active)
		m.step(dt)
	return {"phase": m.phase, "hits": m.hits, "shots": shots, "max_active": max_active, "victory": m.victory_locked}
func run() -> void:
	for lane in [-1, 0, 1]:
		var still = Chapter.new()
		still.start()
		still._begin_play("sprint")
		still.lane = lane
		still.from_lane = lane
		still.target_lane = lane
		still.step(32.0)
		check(still.state == "failed" and still.hits == 4 and not still.victory_locked, "standing in lane %d cannot bypass the aimed arrow stage" % lane)
	for dt in [1.0 / 120.0, 1.0 / 15.0]:
		for lane in [-1, 0, 1]:
			var result = chase(dt, lane, 0.45)
			check(result.phase == "meng_strike" and result.hits == 0 and result.seconds > 33.9 and result.seconds < 34.2, "450ms readable-depth response clears chase at %d FPS from lane %d: %s" % [roundi(1.0 / dt), lane, result])
			check(result.row_spacing >= 1.9 and result.rows >= 8, "adjacent rows preserve two-lane travel/reaction room")
			var arrows = sprint(dt, lane, 0.6)
			check(arrows.victory and arrows.hits == 0 and arrows.shots == 8 and arrows.max_active == 1, "600ms post-lock response clears eight individual shots at %d FPS, lane %d: %s" % [roundi(1.0 / dt), lane, arrows])
		for penalties in [1, 2, 3]:
			var result = chase(dt, 0, 0.35, penalties)
			check(result.hits == penalties and result.phase == ("escape" if penalties == 3 else "meng_strike"), "only deliberate collisions affect recovery/escape at %d FPS, hits=%d: %s" % [roundi(1.0 / dt), penalties, result])
	for index in Pacing.SHOTS.size():
		var profile = Pacing.shot_profile(index)
		var after_lock: float = profile.lock_seconds + 88.0 / profile.speed
		check(after_lock >= (2.0 if index == 0 else 1.5), "shot %d has a measured post-lock window of %.3fs" % [index + 1, after_lock])
		var contact: float = Pacing.SHOTS[index] + profile.aim_seconds + after_lock
		check(contact < (Pacing.SHOTS[index + 1] if index + 1 < Pacing.SHOTS.size() else 30.2), "shot clears before the next draw or final gate breathing room")
	var m = Chapter.new()
	m.start()
	m._begin_play("chase")
	m.invulnerable = 99.0
	m.step(33.5)
	var beats: int = m.spawn_index
	var serial: int = m.serial
	var before: float = m.gap
	m.invulnerable = 0.0
	m._hit("barricade")
	check(is_equal_approx(m.gap - before, 3.0) and m.gap_recoil == 18.0, "impact applies a small immediate recoil and reserves the remaining distance")
	m.step(0.3)
	check(m.gap > before + 8.0 and m.gap_recoil > 0.0 and m.gap_recoil < 18.0, "distance visibly opens during recovery instead of teleporting the target")
	m.pause()
	var freeze = [m.gap, m.gap_recoil, m.elapsed, m.spawn_index]
	m.step(5.0)
	check([m.gap, m.gap_recoil, m.elapsed, m.spawn_index] == freeze, "pause freezes both pending recoil and the authored beat cursor")
	m.resume()
	m.step(0.8)
	check(m.serial == serial and m.spawn_index == beats and is_zero_approx(m.gap_recoil), "a late hit does not replay previously suppressed rows")
	m.step(1.5)
	check(m.spawn_index == beats + 1 and m.serial - serial <= 2, "only the next scheduled row returns after a late mistake")
	m.pause()
	m.retry()
	check(m.spawn_index == 0 and m.gap_recoil == 0.0 and m.next_spawn == Pacing.ROWS[0][0] and m.hp == 4, "retry resets the beat cursor, recoil and first safe approach")
	m._begin_play("sprint")
	m.step(Pacing.SHOTS[0] + 0.2)
	check(m.hazards.size() == 1 and m.hazards[0].phase == "aim", "sprint starts safely and then demonstrates a single tracking shot")
	m.request_lane(1)
	m.step(0.3)
	check(m.hazards[0].lane == 1, "early switching is tracked during the draw")
	m.step(1.0)
	check(m.hazards[0].phase == "locked", "the first arrow reaches its longer fixed-route stage")
	var locked_lane: int = m.hazards[0].lane
	m.request_lane(-1)
	m.step(0.25)
	check(m.hazards[0].lane == locked_lane and m.lane == 0.0, "the locked route stays fixed while the player changes lanes")
	var game = load("res://scenes/levels/luoyang_chapter.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.model._begin_play("sprint")
	game.model.step(2.0)
	game._sync_world()
	var h = game.model.hazards[0]
	var target = game.hazard_nodes[h.id].get_node("Target")
	check(target.get_node("Tracking").visible and not target.get_node("Locked").visible, "aiming uses tracking brackets with a faint road ribbon")
	game.model.step(1.2)
	game._sync_world()
	check(target.get_node("Locked").visible and target.get_node("ReleaseBar").visible and not target.get_node("Tracking").visible, "locking changes shape and shows the release timing without relying on color")
	game.model.pause()
	var bar = target.get_node("ReleaseBar").points
	game.model.step(5.0)
	game._sync_world()
	check(target.get_node("ReleaseBar").points == bar, "lock countdown freezes while paused")
	game.model.resume()
	game.reduced_motion = true
	game._sync_world()
	check(target.get_node("Locked").visible and target.get_node("Ribbon").polygon.size() == 4, "reduced motion retains fixed route and phase shape")
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("LUOYANG PACING CHECKS: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
