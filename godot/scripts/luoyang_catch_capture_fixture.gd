extends SceneTree
## Save-free render sampling of a wrong-lane approach and the following catch.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://scenes/levels/luoyang_chapter.tscn").instantiate()
	game.set_script(load("res://scripts/luoyang_art_capture_view_fixture.gd"))
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.begin_chapter()
	game.model._begin_play("chase")
	game.model.next_spawn = INF
	game.model.gap = 10.01
	game.model.lane = -1.0
	game.model.from_lane = -1.0
	game.model.target_lane = -1
	var folder = ProjectSettings.globalize_path("res://../builds/previews/luoyang-catch")
	DirAccess.make_dir_recursive_absolute(folder)
	for sample in [["approach", 0.0], ["burst-start", 0.02], ["burst-middle", 0.5], ["burst-end", 0.5]]:
		game.model.step(sample[1])
		game._sync_world()
		await process_frame
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png(folder.path_join(sample[0] + ".png"))
		print("CAPTURE: %s gap=%.3f phase=%s" % [sample[0], game.model.gap, game.model.phase])
	game.model.request_lane(1)
	game.model.step(0.21)
	game.model.request_lane(1)
	game.model.step(0.21)
	game.model.step(4.0)
	game._sync_world()
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(folder.path_join("same-lane-strike.png"))
	print("CAPTURE: same-lane-strike phase=", game.model.phase)
	game.queue_free()
	await process_frame
	quit()
