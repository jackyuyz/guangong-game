extends SceneTree
const Chapter = preload("res://scripts/luoyang_chapter_model.gd")
const Pursuer = preload("res://scripts/luoyang_pursuer.gd")
var checks = 0
var failures = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func route(frame_dt: float, penalties: bool) -> Dictionary:
	var m = Chapter.new()
	m.start()
	m._begin_play("chase")
	m.invulnerable = 999.0
	var contacts = 0
	var rows_passed = 0
	var spawns_ahead = true
	var seen: Dictionary = {}
	var penalty_index = 0
	var penalty_times = [5.0, 13.0, 21.0, 32.0]
	for frame in int(67.0 / frame_dt):
		if m.phase != "chase": break
		var before: Dictionary = {}
		var old_gap: float = m.gap
		var old_lane: float = m.pursuer.lane
		for h in m.hazards: before[h.id] = float(h.distance) - old_gap
		if penalties and penalty_index < penalty_times.size() and m.elapsed >= penalty_times[penalty_index]:
			m.hp = 4
			m.invulnerable = 0.0
			m._hit("barricade")
			m.invulnerable = 999.0
			penalty_index += 1
		m.step(frame_dt)
		for h in m.hazards:
			if not seen.has(h.id):
				seen[h.id] = true
				spawns_ahead = spawns_ahead and h.distance > m.gap + 40.0
			var relative: float = h.distance - m.gap
			if before.has(h.id) and before[h.id] > 0.0 and relative <= 0.0:
				rows_passed += 1
				var fraction: float = before[h.id] / (before[h.id] - relative)
				var crossing_lane = lerpf(old_lane, m.pursuer.lane, fraction)
				if absf(crossing_lane - h.lane) < 0.43: contacts += 1
	return {"contacts": contacts, "passed": rows_passed, "ahead": spawns_ahead, "changes": m.pursuer.changes, "phase": m.phase, "seconds": m.seconds}

func run() -> void:
	var p = Pursuer.new()
	var empty: Array[Dictionary] = []
	p.step(0.5, 50.0, empty)
	check(p.target_lane == 0 and p.lane == 1.0, "Meng Tan initiates an occasional move on an empty road without teleporting")
	p.step(0.25, 50.0, empty)
	check(p.lane > 0.0 and p.lane < 1.0, "enemy lane change has a continuous intermediate position")
	p.step(0.4, 50.0, empty)
	check(is_zero_approx(p.lane), "enemy finishes the lane change on the road center")
	p.reset()
	var single: Array[Dictionary] = [{"kind": "barricade", "distance": 82.0, "lane": 1, "resolved": false}]
	p.step(0.01, 50.0, single)
	check(p.target_lane == 0 and p.avoiding, "enemy picks the nearest open lane before the same barricade reaches him")
	check(not single[0].resolved and single[0].distance == 82.0, "enemy avoidance does not consume, move or resolve the player's barricade")
	p.reset()
	var pair: Array[Dictionary] = [{"kind": "barricade", "distance": 82.0, "lane": 0}, {"kind": "barricade", "distance": 82.0, "lane": 1}]
	p.step(0.01, 50.0, pair)
	check(p.target_lane == -1, "two blocked lanes send Meng Tan through the actual remaining opening")
	for i in 70: p.step(1.0 / 120.0, 50.0, pair)
	check(is_equal_approx(p.lane, -1.0), "crossing two lanes also finishes smoothly before the obstacle row")
	p.reset()
	p.next_roam = 0.0
	var rear: Array[Dictionary] = [{"kind": "barricade", "distance": 47.0, "lane": 0}]
	p.step(0.1, 50.0, rear)
	check(p.target_lane == 1, "enemy holds his opening until the row clears the rear of the horse")
	var m = Chapter.new()
	m.start()
	m._begin_play("chase")
	m.step(2.0)
	m.pause()
	var frozen = [m.pursuer.lane, m.pursuer.lane_time, m.pursuer.elapsed, m.pursuer.target_lane]
	m.step(10.0)
	check([m.pursuer.lane, m.pursuer.lane_time, m.pursuer.elapsed, m.pursuer.target_lane] == frozen, "chapter pause freezes enemy movement and planning")
	m.retry()
	check(m.pursuer.lane == 1.0 and m.pursuer.changes == 0 and m.pursuer.elapsed == 0.0, "chase retry resets enemy path and its scheduling")
	for dt in [1.0 / 120.0, 1.0 / 15.0]:
		for penalties in [false, true]:
			var result = route(dt, penalties)
			check(result.contacts == 0 and result.passed >= 8, "enemy clears shared rows at %d FPS, player penalties=%s: %s" % [roundi(1.0 / dt), penalties, result])
			check(result.ahead and result.changes >= 4, "all rows spawn ahead and the target changes lanes throughout that route")
	var game = load("res://scenes/levels/luoyang_chapter.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.model._begin_play("chase")
	game.model.step(0.7)
	game._sync_world()
	check(game.get_node("World/MengTan").position.is_equal_approx(game.road.project(game.model.pursuer.lane, game.model.gap)), "rendered target follows its continuous model lane instead of a fixed art override")
	game.reduced_motion = true
	game._sync_world()
	check(game.get_node("World/MengTan/Body").rotation == 0.0 and game.model.pursuer.lane < 1.0, "reduced motion keeps necessary enemy travel while removing decorative leaning")
	game.queue_free()
	await process_frame
	print("LUOYANG PURSUER CHECKS: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
