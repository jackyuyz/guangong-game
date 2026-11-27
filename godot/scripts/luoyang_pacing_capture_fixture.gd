extends SceneTree
## Deterministic rendered poses; no player profile or exported gameplay shortcuts.
var game: Node
var folder: String
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	game._sync_world()
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(folder.path_join(name + ".png"))
	print("CAPTURE: ", name)
func avoid() -> void:
	if game.model.lane_time < game.model.LANE_SECONDS: return
	var nearest = INF
	for h in game.model.hazards:
		if not h.resolved: nearest = minf(nearest, h.distance)
	var blocked: Array[int] = []
	for h in game.model.hazards:
		if not h.resolved and absf(h.distance - nearest) < 0.1: blocked.append(h.lane)
	if game.model.target_lane in blocked:
		for lane in [-1, 0, 1]:
			if lane not in blocked:
				game.model.request_lane(signi(lane - game.model.target_lane))
				break
func run() -> void:
	folder = ProjectSettings.globalize_path("res://../builds/previews/luoyang-pacing")
	DirAccess.make_dir_recursive_absolute(folder)
	game = load("res://scenes/levels/luoyang_chapter.tscn").instantiate()
	game.set_script(load("res://scripts/luoyang_art_capture_view_fixture.gd"))
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.begin_chapter()
	game.model._begin_play("chase")
	for stamp in [6.0, 13.5, 18.0, 24.5, 29.0]:
		while game.model.elapsed < stamp:
			avoid()
			game.model.step(1.0 / 60.0)
		await capture("chase-%03d" % roundi(stamp * 10))
	game.model.invulnerable = 0.0
	game.model._hit("barricade")
	var previous_stamp = 0.0
	for stamp in [0.0, 0.2, 0.65]:
		game.model.step(stamp - previous_stamp)
		previous_stamp = stamp
		await capture("recoil-%02d" % roundi(stamp * 10))
	game.model.wounded = true
	game.model._begin_play("sprint")
	for stamp in [2.0, 3.2, 3.65, 4.3, 5.1, 5.6]:
		game.model.step(stamp - game.model.elapsed)
		await capture("first-arrow-%03d" % roundi(stamp * 10))
	game.model._begin_play("sprint")
	game.model.spawn_index = 7
	game.model.next_spawn = 27.6
	game.model.elapsed = 27.59
	game.model.step(0.06)
	for stamp in [28.0, 28.55, 29.2]:
		game.model.step(stamp - game.model.elapsed)
		await capture("late-arrow-%03d" % roundi(stamp * 10))
	game.reduced_motion = true
	await capture("late-arrow-reduced")
	game.queue_free()
	await process_frame
	quit()
