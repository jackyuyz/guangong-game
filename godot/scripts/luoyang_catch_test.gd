extends SceneTree
const Chapter = preload("res://scripts/luoyang_chapter_model.gd")
var checks = 0
var failures = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)
func approach(player_lane: int, enemy_lane: int) -> RefCounted:
	var m = Chapter.new()
	m.start()
	m._begin_play("chase")
	m.next_spawn = INF
	m.gap = m.CATCH_GAP + 0.01
	m.lane = player_lane
	m.from_lane = player_lane
	m.target_lane = player_lane
	m.pursuer.lane = enemy_lane
	m.pursuer.from_lane = enemy_lane
	m.pursuer.target_lane = enemy_lane
	return m
func run() -> void:
	for dt in [1.0 / 120.0, 1.0 / 15.0]:
		for lane in [-1, 0, 1]:
			var same = approach(lane, lane)
			same.step(dt)
			check(same.phase == "meng_strike" and same.meng_defeated and same.breakaways == 0, "same-lane capture at %d FPS, lane %d" % [roundi(1.0 / dt), lane])
		var m = approach(-1, 1)
		m.step(dt)
		check(m.phase == "chase" and not m.meng_defeated and m.breakaways == 1 and m.breakaway_left > 0.0, "wrong-lane arrival starts a breakaway rather than a kill")
		var previous: float = m.gap
		m.step(0.25)
		check(m.gap > previous and m.gap < previous + 3.0 and m.breakaways == 1 and m.hp == 4 and m.hits == 0, "breakaway visibly opens distance over time without damage or repeated triggers")
		m.pause()
		var frozen = [m.gap, m.breakaway_left, m.breakaway_notice, m.seconds, m.pursuer.lane]
		m.step(5.0)
		check([m.gap, m.breakaway_left, m.breakaway_notice, m.seconds, m.pursuer.lane] == frozen, "pause freezes the burst, feedback, enemy and route clock")
		m.resume()
		m.request_lane(1)
		m.step(0.21)
		m.request_lane(1)
		m.step(0.21)
		check(m.phase == "chase" and m.catch_lane_aligned() and m.gap > m.CATCH_GAP, "changing into the enemy lane during the burst still requires catching up")
		m.step(5.0)
		check(m.meng_defeated and m.breakaways == 1 and m.seconds < 5.2, "one burst is recoverable by matching the lane")
		var missed = approach(-1, 1)
		missed.step(11.0)
		check(missed.phase == "chase" and missed.breakaways >= 3 and not missed.meng_defeated, "remaining in another lane repeatedly misses instead of awarding a kill")
		missed.pause()
		missed.retry()
		check(missed.breakaway_left == 0.0 and missed.breakaway_notice == 0.0 and missed.breakaways == 0 and missed.gap == missed.INITIAL_GAP and missed.seconds == 0.0 and missed.hp == 4, "checkpoint retry clears bursts and failed-attempt time")
		var late = approach(-1, 1)
		late.elapsed = 64.99
		late.step(0.1)
		check(late.phase == "escape" and not late.meng_defeated and late.elapsed < 65.02, "a burst cannot extend the finite route past the escape")
	var crossing = approach(-1, 0)
	crossing.request_lane(1)
	crossing.step(1.0 / 120.0)
	check(crossing.phase == "chase" and crossing.breakaways == 1, "requesting the matching lane does not count before the horse arrives")
	var departing = approach(0, 0)
	departing.pursuer._change_lane(1)
	departing.step(1.0 / 120.0)
	check(departing.phase == "chase" and not departing.meng_defeated, "crossing horses with different target lanes cannot trigger a false capture")
	var lethal = approach(0, 0)
	lethal.hp = 1
	lethal._add_hazard("barricade", 0)
	lethal.hazards[-1].distance = 0.01
	lethal.step(0.1)
	check(lethal.phase == "fall" and not lethal.meng_defeated, "a simultaneous lethal collision remains final")
	var game = load("res://scenes/levels/luoyang_chapter.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.model = approach(-1, 1)
	game.model.step(0.02)
	game._sync_world()
	check(game.get_node("UI/Warning").text.contains("加速") and game.get_node("UI/WarningBacking").visible and not game.get_node("UI/Keys").visible, "burst feedback reuses the warning line without adding permanent hints")
	var start: Vector2 = game.get_node("World/MengTan").position
	game.model.step(0.4)
	game._sync_world()
	check(game.get_node("World/MengTan").position.y < start.y, "actual rider projection retreats smoothly during the burst")
	for label in ["孟坦加速 · 同道追击", "同道追击 · 孟坦在左道中道右道"]:
		var font: Font = game.get_node("UI/Stage").get_theme_font("font")
		var complete = true
		for c in label: complete = complete and font.has_char(c.unicode_at(0))
		check(complete, "stage font contains every new glyph: " + label)
	game.queue_free()
	await process_frame
	print("LUOYANG CATCH CHECKS: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
