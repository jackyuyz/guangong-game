extends SceneTree
const Chapter = preload("res://scripts/luoyang_chapter_model.gd")
var checks = 0
var failures = 0
var game: Node
var reports = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)
func avoid(m: RefCounted) -> void:
	if m.state != "running" or m.lane_time < m.LANE_SECONDS: return
	var nearest = 999.0
	for h in m.hazards:
		if not h.resolved: nearest = minf(nearest, h.distance)
	var blocked: Array[int] = []
	for h in m.hazards:
		if not h.resolved and absf(h.distance - nearest) < 0.2: blocked.append(h.lane)
	if m.target_lane in blocked:
		for candidate in [-1, 0, 1]:
			if candidate not in blocked:
				m.request_lane(signi(candidate - m.target_lane))
				break
func route(collisions: int, dt: float) -> RefCounted:
	var m = Chapter.new()
	m.start()
	m._begin_play("chase")
	var applied = 0
	for frame in int(66.0 / dt):
		if m.phase != "chase": break
		if applied < collisions and m.elapsed >= [8.0, 18.0, 28.0][applied]:
			m._hit("barricade")
			applied += 1
		avoid(m)
		m.step(dt)
	return m
func sample(phase: String, t: float) -> void:
	if game.model.phase != phase: game.model._story(phase)
	game.model.phase_clock = t
	game._sync_world()
func snapshot() -> Array:
	return [game.model.phase_clock, game.get_node("World/MengTan").position,
		game.get_node("World/MengTan").scale, game.get_node("World/MengTan").visible,
		game.get_node("Cutscene/HeroBinding").pose_index, game.get_node("Cutscene/HeroBinding").position,
		game.get_node("Cutscene/Procession").pose_index, game.get_node("Cutscene/Procession").position,
		game.get_node("Cutscene/ClosingShade").modulate, game.art.hoof_clock]
func run() -> void:
	for dt in [1.0 / 120.0, 1.0 / 15.0]:
		var recovered = route(2, dt)
		check(recovered.phase == "meng_strike" and recovered.hp == 2 and recovered.hits == 2, "two collisions remain recoverable at %d FPS" % roundi(1.0 / dt))
		var escaped = route(3, dt)
		check(escaped.phase == "escape" and escaped.hp == 1 and escaped.hits == 3 and not escaped.meng_defeated, "three collisions can reach the escape alive at %d FPS" % roundi(1.0 / dt))
		check(escaped.elapsed >= 65.0 and escaped.seconds < 65.1 and escaped.hazards.is_empty(), "escape locks at the finite route end and clears all dangers")
	game = load("res://scenes/levels/luoyang_chapter.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.begin_chapter()
	game.model._begin_play("chase")
	game.model.elapsed = 56.5
	game._sync_world()
	check(not game.get_node("ForkLandscape").visible, "junction does not appear on the early road")
	game.model.elapsed = 57.0
	game._sync_world()
	check(game.get_node("ForkLandscape").visible and game.get_node("ForkLandscape").modulate.a == 1.0 and game.get_node("UI/Warning").text.contains("岔口"), "junction and warning are fully readable eight seconds before escape")
	game.model.pause()
	var frozen = [game.model.elapsed, game.get_node("ForkLandscape").modulate, game.get_node("World/MengTan").position]
	game.model.step(10.0)
	game._sync_world()
	check([game.model.elapsed, game.get_node("ForkLandscape").modulate, game.get_node("World/MengTan").position] == frozen, "pause freezes the visible junction approach and chase timer")
	game.model.resume()
	game.model.gap = 15.0
	game.model.pursuer.lane = -1.0
	game.model._fail("孟坦逃脱")
	sample("escape", 0.0)
	check(game.get_node("World/MengTan").position == game.road.project(-1.0, 15.0) and not game.get_node("Cutscene").visible and game.rider.pose_index == 10, "escape begins at the actual enemy position while Guan Yu brakes intact")
	var stats = game.model.result()
	game.model.request_lane(1)
	game.model._hit("barricade")
	game.model.phase_clock = 0.3
	game.model.advance_story("escape")
	check(game.model.phase == "escape" and game.model.result() == stats and not game.get_node("UI/Story/Advance").visible, "locked escape blocks damage, lane input and premature skip")
	for t in [0.5, 1.3, 2.2]:
		sample("escape", t)
		var state = snapshot()
		game.model.pause()
		game.model.step(8.0)
		game._sync_world()
		check(snapshot() == state, "escape horse and branch path freeze at %.1fs" % t)
		game.model.resume()
	sample("escape", 2.2)
	check(game.get_node("World/MengTan").position.x > game.get_node("ForkBend").position.x and game.get_node("ForkLandscape/Foliage").z_index > game.get_node("World/MengTan").z_index, "fleeing rider takes the right branch under the pine foreground")
	sample("escape", 2.8)
	check(not game.get_node("World/MengTan").visible, "Meng Tan disappears only after travelling behind the trees")
	game.model.step(0.5)
	check(game.model.state == "failed" and not game.model.victory_locked, "escape finishes into retry controls without victory")
	game.model.retry()
	game._sync_world()
	check(game.model.phase == "chase" and game.model.hp == 4 and game.model.hits == 0 and game.model.seconds == 0.0 and game.model.retries == 1 and not game.get_node("ForkLandscape").visible, "retry restores the chase checkpoint and clears escape scenery")
	game.model._begin_play("sprint")
	game.model.wounded = true
	game.model.elapsed = 31.999
	game.cleared.connect(func(_result: Dictionary): reports += 1)
	game.model.step(0.01)
	game._handle_chapter_events()
	game._handle_chapter_events()
	check(reports == 1 and game.model.victory_locked, "victory is reported exactly once before the longer ending")
	game.model._next_story()
	var result = game.model.result()
	sample("ending", 0.1)
	check(game.get_node("Cutscene/HeroBinding").pose_index == 0 and not game.get_node("Cutscene/Procession").visible, "closing starts with the mounted wound check before the caravan arrives")
	for row in [[0.7, 1], [1.25, 2], [1.8, 3], [2.3, 4], [2.9, 5]]:
		sample("ending", row[0])
		check(game.get_node("Cutscene/HeroBinding").pose_index == row[1], "cloth action reaches its drawn pose at %.2fs" % row[0])
	for t in [1.8, 3.5, 4.7, 7.0]:
		sample("ending", t)
		var state = snapshot()
		game.model.pause()
		game.model.step(10.0)
		game._sync_world()
		check(snapshot() == state, "binding, transition, wheels and procession pause together at %.1fs" % t)
		game.model.resume()
	sample("ending", 4.3)
	var entering: Vector2 = game.get_node("Cutscene/Procession").position
	var frame: int = game.get_node("Cutscene/Procession").pose_index
	sample("ending", 4.6)
	check(game.get_node("Cutscene/Procession").position.x > entering.x and game.get_node("Cutscene/Procession").pose_index != frame, "approaching caravan advances through real wheel and draft-horse frames")
	sample("ending", 5.9)
	check(game.get_node("Cutscene/Procession").position == game.get_node("Cutscene/CaravanMeet").position and game.get_node("Cutscene/HeroBinding").pose_index == 5, "caravan pauses at the escort meeting marker beside the bound rider")
	var spacing: float = game.get_node("Cutscene/HeroBinding").position.x - game.get_node("Cutscene/Procession").position.x
	game.reduced_motion = true
	sample("ending", 7.6)
	check(game.get_node("Cutscene/HeroBinding").pose_index in [6, 7] and game.get_node("Cutscene/HeroBinding").position.x - game.get_node("Cutscene/Procession").position.x == spacing and game.story_panel.modulate.a == 0.0, "reduced motion retains essential escorted travel, spacing and clear wheels")
	sample("ending", 10.05)
	check(game.get_node("Cutscene/Procession").position.x > 1100 and game.get_node("Cutscene/HeroBinding").position.x > 1400, "both carriage and escort leave the gate before recap")
	game.model.step(0.5)
	game._handle_chapter_events()
	check(game.model.state == "culture" and game.model.result() == result and reports == 1, "natural closing keeps scored stats and saved victory unchanged")
	sample("ending", 1.2)
	game.overlay_guard = 0.0
	game._advance_story()
	game._advance_story()
	check(game.model.state == "culture" and game.model.result() == result, "repeated closing skip reaches recap once without changing results")
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("LUOYANG FINALE CHECKS: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
