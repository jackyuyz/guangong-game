extends SceneTree
## Isolated native views of the shared-road target; no profile or persistence.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://scenes/levels/luoyang_chapter.tscn").instantiate()
	game.set_script(load("res://scripts/luoyang_art_capture_view_fixture.gd"))
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.begin_chapter()
	game.model._begin_play("chase")
	game.model.invulnerable = 999.0
	var output = ProjectSettings.globalize_path("res://../builds/previews/luoyang-pursuer")
	DirAccess.make_dir_recursive_absolute(output)
	var previous = 0.0
	for sample in [0.8, 1.3, 3.7, 4.0, 9.65, 12.45, 13.1, 22.0]:
		game.model.step(sample - previous)
		previous = sample
		game.overlay.hide()
		game._sync_world()
		await process_frame
		RenderingServer.force_draw(false)
		var name = "t-%.2f.png" % sample
		var code = root.get_texture().get_image().save_png(output.path_join(name))
		if code != OK: push_error("Capture failed: " + name)
		print("CAPTURE: %s lane=%.3f target=%d avoiding=%s" % [name, game.model.pursuer.lane, game.model.pursuer.target_lane, game.model.pursuer.avoiding])
	game.queue_free()
	await process_frame
	quit()
