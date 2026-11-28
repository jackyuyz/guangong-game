extends SceneTree
const Chapter = preload("res://scripts/luoyang_chapter_model.gd")
const Store = preload("res://scripts/progress_store.gd")
var checks = 0
var failures = 0

func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func avoid(m: RefCounted) -> void:
	if m.state != "running" or m.lane_time < m.LANE_SECONDS: return
	if m.phase == "tutorial":
		m.request_lane(-1 if -1 not in m.tutorial_directions else 1)
	elif m.phase == "chase":
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
		elif m.gap <= m.CLOSE_APPROACH and m.pursuer.target_lane not in blocked:
			m.request_lane(signi(m.pursuer.target_lane - m.target_lane))
	elif m.phase == "sprint":
		for h in m.hazards:
			if not h.resolved and h.phase != "aim" and h.lane == m.target_lane:
				m.request_lane(-1 if m.target_lane >= 0 else 1)

func play_to(m: RefCounted, destination: String) -> void:
	for frame in 24000:
		if m.phase == destination or m.state in ["failed", "complete"]: return
		avoid(m)
		m.step(1.0 / 120.0)

func run() -> void:
	var m = Chapter.new()
	m.start()
	check(m.phase == "intro" and m.state == "story" and m.hazards.is_empty(), "chapter begins with a safe noninteractive opening")
	m.request_lane(1)
	check(m.switches == 0, "story cannot accept combat or lane input")
	m.step(0.3)
	m.advance_story("intro")
	m.advance_story("intro")
	check(m.phase == "tutorial", "skip uses the expected phase and cannot double advance")
	m.step(8.0)
	check(m.phase == "tutorial" and m.hp == 4 and m.hits == 0 and m.seconds == 0.0, "tutorial repeats without damage, chase progress or scored time")
	play_to(m, "chase")
	check(m.checkpoint.phase == "chase" and m.hp == 4 and m.switches == 0, "both tutorial directions establish a clean chase checkpoint")
	var initial_gap: float = m.gap
	m.step(0.5)
	check(m.gap < initial_gap, "safe running truly closes the gap")
	var before_gap: float = m.gap
	m._hit("barricade")
	check(m.gap > before_gap and m.hp == 3 and m.slowdown > 0.0, "barricade hit damages, slows and widens the chase gap")
	m.pause()
	var frozen = [m.gap, m.seconds, m.elapsed, m.lane]
	m.step(5.0)
	check([m.gap, m.seconds, m.elapsed, m.lane] == frozen, "pause freezes scored time, chase and lane movement")
	m.retry()
	check(m.phase == "chase" and m.hits == 0 and m.seconds == 0.0 and m.retries == 1 and m.hp == 4, "chase retry discards the failed attempt and keeps retries")
	play_to(m, "meng_strike")
	check(m.meng_defeated and m.state == "story" and m.hazards.is_empty() and m.hits == 0, "a no-hit route catches Meng Tan and clears hazards")
	check(m.seconds >= 30.0 and m.seconds < 45.0, "clean chase duration matches the target range")
	var meng_time: float = m.seconds
	m.pause()
	var cut_time: float = m.phase_clock
	m.step(8.0)
	check(m.phase_clock == cut_time, "pause freezes the slaying cutscene")
	m.resume()
	m.step(0.35)
	m.advance_story("meng_strike")
	m.advance_story("meng_strike")
	check(m.phase == "ambush" and not m.wounded, "slaying skips once into a distinct ambush")
	m.step(0.35)
	m.advance_story("ambush")
	check(m.phase == "sprint" and m.wounded and m.wound_events == 1 and m.hp == 4 and m.hits == 0, "scripted arrow is applied once without avoidable damage")
	check(is_equal_approx(m.seconds, meng_time) and m.checkpoint.wounded, "cutscenes add no scored time; wounded sprint checkpoint is captured")
	m._hit("arrow")
	m.step(1.0)
	m.pause()
	m.retry()
	check(m.phase == "sprint" and m.hp == 4 and m.hits == 0 and m.retries == 2 and m.seconds == meng_time and m.wound_events == 1, "sprint retry keeps successful chase and does not replay scripted arrow")
	play_to(m, "han_strike")
	check(m.victory_locked and m.han_defeated and m.hazards.is_empty(), "reaching the gate locks victory and removes all projectiles")
	m._hit("arrow")
	check(m.hp == 4 and m.hits == 0, "locked victory cannot receive late damage")
	play_to(m, "culture")
	check(m.state == "culture" and m.wounded and m.wound_events == 1, "ending reaches a literary adaptation recap with wound continuity")
	m.finish_culture()
	m.finish_culture()
	check(m.state == "complete" and m.phase == "result", "recap finishes once into results")
	var clean = m.result()
	m.start()
	m._begin_play("chase")
	m.gap = 999.0
	m.invulnerable = 100.0
	m.step(65.5)
	check(m.phase == "escape" and m.failure_reason == "孟坦逃脱", "finite chase route begins an explicit escape when the gap cannot be closed")
	m.step(3.2)
	check(m.state == "failed", "escape feedback completes before retry controls")
	m.retry()
	check(m.gap == Chapter.INITIAL_GAP and m.phase == "chase" and not m.wounded, "escape retry restores the original pursuit")
	m._begin_play("sprint")
	m.hp = 1
	m.elapsed = Chapter.SPRINT_SECONDS - 0.001
	m._add_hazard("arrow", 0)
	m.hazards[0].phase = "flying"
	m.hazards[0].distance = 0.001
	m.step(0.01)
	check(m.victory_locked and m.hp == 1, "gate arrival takes priority over a simultaneous lethal arrow")
	m.start()
	m._begin_play("sprint")
	m.hp = 1
	m._hit("arrow")
	m.step(40.0)
	check(m.state == "failed" and not m.victory_locked, "an earlier lethal hit cannot later become gate victory")
	var store = Store.new()
	var save = "/tmp/guangong-luoyang-chapter-%d.cfg" % Time.get_ticks_usec()
	store.load_file(save)
	store.config.set_value("custom", "preserve", "yes")
	store.mark_cleared("dongling", 4567)
	check(store.record_luoyang(clean), "second chapter completion and independent route record save")
	var reloaded = Store.new()
	reloaded.load_file(save)
	check(reloaded.is_cleared("luoyang") and reloaded.best_score() == 4567 and reloaded.config.get_value("custom", "preserve") == "yes", "second chapter save preserves the first score and unknown fields")
	var slower = clean.duplicate()
	slower.seconds += 20.0
	store.record_luoyang(slower)
	check(store.luoyang_record().seconds == clean.seconds, "a slower replay cannot lower the best route time")
	check(not store.record_luoyang({"seconds": NAN, "hits": 0, "retries": 0, "switches": 0}), "invalid route cannot create bogus persisted stats")
	var bad = Store.new()
	bad.load_file("/tmp/guangong-no-such-parent-%d/progress.cfg" % Time.get_ticks_usec())
	check(not bad.record_luoyang(clean) and not bad.error_text.is_empty(), "save failure is explicit instead of falsely reporting persistence")
	var game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "/tmp/guangong-luoyang-host-%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.progress.set_intro("skipped")
	game._start()
	game.journey._process(0.9)
	game.journey._release_pending = false
	game._enter_chapter("luoyang")
	check(game.state == "map" and game.chapter_two == null, "fresh journey cannot bypass first chapter prerequisite")
	game.progress.mark_cleared("dongling", 0)
	game.ui.get_node("BladeCursor").show()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	game._enter_chapter("luoyang")
	var chapter: Node = game.chapter_two
	chapter.set_process(false)
	await process_frame
	await process_frame
	check(game.state == "chapter_two" and not game.ui.visible and not game.level.visible and chapter.model.phase == "intro", "map routes into a separate chapter and suspends first-chapter UI")
	check(Input.mouse_mode == Input.MOUSE_MODE_VISIBLE and not game.ui.get_node("BladeCursor").visible, "chapter handoff restores a visible system cursor before disabling the first UI")
	check(chapter.get_node("UI/Overlay/Panel").position == Vector2(215, 77) and chapter.buttons[0].position == Vector2(116, 176), "chapter UI retains editor-authored offsets after deferred layout settles")
	var font = load("res://assets/ui/wuxia-kai.otf")
	var text = FileAccess.get_file_as_string("res://scripts/luoyang_chapter.gd") + FileAccess.get_file_as_string("res://scripts/luoyang_chapter_model.gd") + FileAccess.get_file_as_string("res://scripts/luoyang_story.gd") + FileAccess.get_file_as_string("res://scripts/luoyang_finale.gd") + FileAccess.get_file_as_string("res://scenes/levels/luoyang_chapter.tscn")
	var missing = ""
	for i in text.length():
		var code = text.unicode_at(i)
		if code >= 0x4e00 and code <= 0x9fff and not font.has_char(code) and text[i] not in missing:
			missing += text[i]
	check(missing.is_empty(), "full chapter font covers new dialogue, stats and UI: " + missing)
	chapter._show_menu()
	chapter.overlay_guard = 0.0
	chapter._overlay_action(1)
	check(chapter.help_open and chapter.get_viewport().gui_get_focus_owner() == chapter.buttons[0], "chapter guide gives keyboard focus to its visible return button")
	chapter._overlay_action(0)
	chapter.begin_chapter()
	chapter.model.step(0.4)
	chapter.overlay_guard = 0.0
	chapter._toggle_pause()
	var pose = chapter.model.phase_clock
	chapter._process(1.0)
	check(chapter.model.phase_clock == pose and not chapter.story_panel.visible, "chapter UI pause freezes story time and hides interactive story controls")
	chapter.overlay_guard = 0.0
	chapter._overlay_action(2)
	chapter.overlay_guard = 0.0
	chapter._overlay_action(1)
	check(not chapter.exit_confirmation and chapter.model.state == "story" and game.state == "chapter_two", "cancel exit preserves and resumes the chapter cutscene")
	chapter.model._story("ending")
	chapter.model._next_story()
	chapter.overlay_guard = 0.15
	chapter._sync_world()
	chapter._process(0.0)
	chapter._process(0.3)
	check(not chapter.get_node("UI/Story/Advance").disabled, "static culture recap enables its mouse button after the transition guard expires")
	chapter.model.start()
	game._enter_chapter("luoyang")
	check(game.chapter_two == chapter, "duplicate departure cannot instantiate a second chapter")
	check(not game.journey.can_enter("sishui"), "unimplemented third chapter remains unavailable")
	chapter.model._begin_play("chase")
	play_to(chapter.model, "han_strike")
	chapter._handle_chapter_events()
	chapter._handle_chapter_events()
	check(game.progress.is_cleared("luoyang") and not game.progress.luoyang_record().is_empty(), "integrated victory reports and saves once before ending/recap")
	chapter._toggle_sound()
	check(game.muted == chapter.muted and game.progress.is_cleared("luoyang"), "chapter sound settings preserve both chapter records")
	game._leave_luoyang()
	await process_frame
	check(game.state == "map" and game.journey.selected == 1 and game.ui.visible and game.level.visible, "chapter return restores map and selected Luoyang stop")
	check(game.journey.get_node("ScrollClip/Stops/Pass2/Seal").visible and not game.journey.can_enter("sishui"), "second completion seal does not open an unavailable third chapter")
	check(game.journey.get_node("ScrollClip/Caravan").position == game.journey.get_node("ScrollClip/TravelLuoyangEnd").position, "caravan advances to the authored second exit")
	game.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("LUOYANG CHAPTER CHECKS: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)
