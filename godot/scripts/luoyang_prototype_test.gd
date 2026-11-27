extends SceneTree
const Model = preload("res://scripts/luoyang_model.gd")
var checks = 0
var failures = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if ok:
		print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func run() -> void:
	var m = Model.new()
	m.start("barricades")
	m.request_lane(-1)
	m.step(0.10)
	check(m.lane < 0.0 and m.lane > -1.0, "lane change moves continuously, not instantaneously")
	m.request_lane(1)
	m.request_lane(1)
	m.step(0.31)
	check(is_equal_approx(m.lane, 0.0) and m.switches == 2, "only one extra lane request is buffered")
	m.request_lane(-1)
	m.step(0.21)
	m.request_lane(-1)
	check(m.target_lane == -1 and m.switches == 3, "outside-lane input does not create a movement")
	m.request_lane(1)
	m.request_lane(1)
	m.pause()
	var frozen = [m.lane, m.elapsed, m.distance, m.lane_time]
	m.step(2.0)
	m.request_lane(-1)
	check([m.lane, m.elapsed, m.distance, m.lane_time] == frozen and m.queued_direction == 0, "pause freezes movement and clears queued input")
	m.resume()
	m.step(0.21)
	check(is_equal_approx(m.lane, 0.0), "resume finishes only the lane change already in progress")
	m.start("barricades")
	m._add_hazard("barricade", 0)
	m.hazards[0].distance = 0.5
	m.request_lane(1)
	m.step(0.05)
	check(m.hp == 3 and m.hits == 1 and m.lane < 1.0, "changing lane late still collides at the actual crossing")
	m.step(0.9)
	check(m.hp == 3 and m.hits == 1, "same barricade never damages twice")
	m.start("barricades")
	m._add_hazard("barricade", 0)
	m.hazards[0].distance = 12.0
	m.request_lane(1)
	m.step(0.7)
	check(m.hp == 4, "timely lane change avoids the barricade")
	for frame_delta in [1.0 / 120.0, 1.0 / 30.0, 0.25]:
		m.start("barricades")
		m.next_spawn = 99.0
		m._add_hazard("barricade", 0)
		m.hazards[0].distance = 2.0
		for i in ceili(0.5 / frame_delta):
			m.step(frame_delta)
		check(m.hp == 3 and m.hits == 1, "cross-frame collision at frame delta %s" % frame_delta)
	m.start("arrows")
	m.step(1.02)
	check(m.hazards.size() == 1 and m.hazards[0].phase == "aim", "arrow begins with a visible aiming interval")
	m.request_lane(1)
	m.step(0.3)
	check(m.hazards[0].lane == 1 and m.hazards[0].phase == "aim", "early movement is tracked while aiming")
	m.step(0.8)
	check(m.hazards[0].phase == "locked" and m.hazards[0].lane == 1, "arrow locks the aimed lane before release")
	var arrow_age: float = m.hazards[0].age
	m.pause()
	m.step(4.0)
	check(m.hazards[0].age == arrow_age, "pause freezes the arrow windup clock")
	m.resume()
	m.request_lane(-1)
	m.step(1.6)
	check(m.hp == 4 and m.hazards[0].lane == 1, "locked arrow does not home; switching after lock succeeds")
	m.start("arrows")
	m.step(4.0)
	check(m.hp == 3 and m.hits == 1, "standing still is hit once by the first arrow")
	m.step(1.0)
	check(m.hits == 1, "passed arrow cannot hit from behind")
	m.start("arrows")
	m.step(19.0)
	check(m.state == "failed" and m.hp == 0, "stationary arrow play reaches a clear failure state")
	var failed_time: float = m.elapsed
	m.step(20.0)
	check(m.elapsed == failed_time and m.hp == 0, "failure locks time and all future damage")
	m.retry()
	check(m.state == "running" and m.hp == 4 and m.retries == 1 and m.elapsed == 0.0 and m.hazards.is_empty(), "retry resets health, hazards and clocks")
	# A simple safety policy uses only the upcoming visible pattern / lock state.
	for selected_mode in ["barricades", "arrows", "course"]:
		m.start(selected_mode)
		for frame in 8000:
			if m.state != "running":
				break
			if m.lane_time >= Model.LANE_SECONDS:
				if m.stage == "barricades":
					var nearest = 999.0
					for h in m.hazards:
						if not h.resolved:
							nearest = minf(nearest, h.distance)
					var blocked: Array[int] = []
					for h in m.hazards:
						if not h.resolved and absf(h.distance - nearest) < 0.2:
							blocked.append(h.lane)
					if m.target_lane in blocked:
						for candidate in [-1, 0, 1]:
							if candidate not in blocked:
								m.request_lane(signi(candidate - m.target_lane))
								break
				else:
					for h in m.hazards:
						if not h.resolved and h.phase != "aim" and h.lane == m.target_lane:
							m.request_lane(-1 if m.target_lane >= 0 else 1)
			m.step(1.0 / 120.0)
		check(m.state == "complete" and m.hits == 0, "authored %s course has a reachable no-hit route" % selected_mode)
	m.start("course")
	m.checkpoint_hits = 2
	m.checkpoint_switches = 7
	m._begin_stage("arrows")
	m.hits = 5
	m.switches = 12
	m.pause()
	m.retry()
	check(m.stage == "arrows" and m.hits == 2 and m.switches == 7 and m.hp == 4, "arrow checkpoint discards the failed segment stats only")
	var game = load("res://scenes/prototypes/luoyang_prototype.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	check(game.get_node("Road/Horizon") is Marker2D and game.get_node("World/Rider/Body/Cape") is Polygon2D, "road anchors and placeholder rider exist as editable nodes")
	var point: Vector2 = game.road.project(1.0, 0.0)
	game.road.get_node("LaneEdge").position.x += 20.0
	check(is_equal_approx(game.road.project(1.0, 0.0).x, point.x + 20.0), "projection reads the authored lane anchor")
	game.model.start("arrows")
	game.overlay.hide()
	game.wait_release = false
	var key = InputEventKey.new()
	key.physical_keycode = KEY_RIGHT
	key.pressed = true
	game._input(key)
	game._process(0.25)
	check(game.model.target_lane == 1, "real controller accepts the first key-down")
	key.echo = true
	game._input(key)
	game._process(0.25)
	check(game.model.switches == 1, "keyboard repeat does not change lanes again")
	game.overlay_guard = 0.0
	game._notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	var focus_time: float = game.model.elapsed
	game._process(0.4)
	check(game.model.state == "paused" and game.overlay.visible and game.model.elapsed == focus_time, "focus loss opens a frozen pause overlay")
	game.overlay_guard = 0.0
	game._overlay_action(1)
	check(game.model.state == "running" and not game.overlay.visible and game.model.hp == 4, "native overlay retry resumes a clean segment")
	key.echo = false
	key.physical_keycode = KEY_LEFT
	game._input(key)
	game._process(0.25)
	check(game.model.target_lane == -1, "first fresh key immediately after retry is accepted before the next rendered frame")
	game.model.step(2.2)
	game._sync_world()
	var target = game.hazard_nodes[game.model.hazards[0].id].get_node("Target")
	check(target.visible and target.global_scale.is_equal_approx(Vector2.ONE), "locked lane marker stays at ground scale instead of shrinking with arrow")
	game.reduced_motion = true
	game._sync_world()
	check(game.rider.get_node("Body").rotation == 0.0 and game.get_node("UI/HitFlash").color.a == 0.0, "reduced motion removes lean and flash without hiding hazards")
	var font = load("res://assets/ui/wuxia-kai.otf")
	var text = FileAccess.get_file_as_string("res://scripts/luoyang_prototype.gd") + FileAccess.get_file_as_string("res://scenes/prototypes/luoyang_prototype.tscn")
	var missing = ""
	for i in text.length():
		var code = text.unicode_at(i)
		if ((code >= 0x4e00 and code <= 0x9fff) or text[i] in ["←", "→", "●", "○", "·"]) and not font.has_char(code) and text[i] not in missing:
			missing += text[i]
	check(missing.is_empty(), "prototype font covers every Chinese UI character and symbol: " + missing)
	game.overlay_guard = 0.12
	game._notification(Node.NOTIFICATION_WM_WINDOW_FOCUS_OUT)
	check(game.model.state == "paused", "window focus loss pauses even during a UI input guard")
	game.model.state = "failed"
	game._show_result()
	game.overlay_guard = 0.0
	game._overlay_action(1)
	check(game.model.state == "ready" and game.buttons[2].visible, "returning from a result restores all three practice choices")
	game.queue_free()
	await process_frame
	print("LUOYANG CHECKS: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)
