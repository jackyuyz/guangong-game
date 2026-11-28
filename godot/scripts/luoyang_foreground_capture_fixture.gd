extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var folder = ProjectSettings.globalize_path("res://../builds/previews/luoyang-foreground")
	DirAccess.make_dir_recursive_absolute(folder)
	var game = load("res://scenes/levels/luoyang_chapter.tscn").instantiate()
	game.set_script(load("res://scripts/luoyang_art_capture_view_fixture.gd"))
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.begin_chapter()
	game.model._begin_play("chase")
	game.model.next_spawn = INF
	game.model.lane = 1.0
	game.model.from_lane = 1.0
	game.model.target_lane = 1
	for lane in [-1, 0]: game.model._add_hazard("barricade", lane)
	for i in 8:
		var depth = [4.0, 0.0, -2.0, -4.0, -6.0, -8.0, -12.0, -17.8][i]
		for h in game.model.hazards:
			h.distance = depth
			h.resolved = depth <= 0.0
		game._sync_world()
		await process_frame
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png(folder.path_join("pass-%02d.png" % i))
		print("CAPTURE depth ", depth)
	game.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	quit()
