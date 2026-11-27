extends SceneTree
## Render-only, isolated from all profile storage; deliberately samples failure too.
var game: Node
var output: String
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	game._sync_world()
	await process_frame
	RenderingServer.force_draw(false)
	var code = root.get_texture().get_image().save_png(output.path_join(name + ".png"))
	if code != OK: push_error("Capture failed: " + name)
	print("CAPTURE: ", name)
func run() -> void:
	output = ProjectSettings.globalize_path("res://../builds/previews/luoyang-finale")
	DirAccess.make_dir_recursive_absolute(output)
	game = load("res://scenes/levels/luoyang_chapter.tscn").instantiate()
	game.set_script(load("res://scripts/luoyang_art_capture_view_fixture.gd"))
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.begin_chapter()
	game.model._begin_play("chase")
	game.model.gap = 24.0
	for t in [56.5, 57.0, 61.0, 64.9]:
		game.model.elapsed = t
		game.model.phase_clock = t
		await capture("junction-%03d" % roundi(t * 10))
	game.model._fail("孟坦逃脱")
	for t in [0.0, 0.6, 1.2, 1.8, 2.2, 2.6, 2.9]:
		game.model.phase_clock = t
		await capture("escape-%02d" % roundi(t * 10))
	game.model.step(0.4)
	game._show_result()
	await capture("escape-result")
	game._close_overlay()
	game.model.victory_locked = true
	game.model.wounded = true
	game.model._story("ending")
	for t in [0.0, 0.7, 1.25, 1.8, 2.3, 2.9, 3.5, 4.3, 5.3, 5.9, 6.5, 7.1, 7.7, 8.8, 10.05]:
		game.model.phase_clock = t
		await capture("ending-%03d" % roundi(t * 10))
	game.model.step(0.5)
	await capture("recap")
	game.queue_free()
	await process_frame
	quit()
