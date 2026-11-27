extends SceneTree
## Isolated deterministic rendering; never loads progress or alters player input.
var game: Node
var output: String
func _initialize() -> void: call_deferred("run")
func capture(phase: String, t: float, name: String) -> void:
	game.model._story(phase)
	game.model.phase_clock = t
	game._sync_world()
	await process_frame
	RenderingServer.force_draw(false)
	var error = root.get_texture().get_image().save_png(output.path_join(name + ".png"))
	if error != OK: push_error("Capture failed: " + name)
	print("CAPTURE: ", name)
func run() -> void:
	output = ProjectSettings.globalize_path("res://../builds/previews/luoyang-story")
	DirAccess.make_dir_recursive_absolute(output)
	game = load("res://scenes/levels/luoyang_chapter.tscn").instantiate()
	game.set_script(load("res://scripts/luoyang_art_capture_view_fixture.gd"))
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.begin_chapter()
	for t in [0.0, 1.5, 1.7, 2.4, 2.9, 3.7, 4.9, 5.8, 6.6]:
		await capture("intro", t, "intro-%02d" % roundi(t * 10))
	await capture("meng_strike", 1.1, "meng-contact")
	game.model.lane = 1.0
	for t in [0.0, 0.6, 1.0, 1.4, 1.9, 2.2, 3.1, 3.8, 4.05, 4.45, 5.2, 5.8, 6.6]:
		await capture("ambush", t, "return-%02d" % roundi(t * 10))
	game.model._next_story()
	game.model.step(0.1)
	game._sync_world()
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(output.path_join("sprint-first.png"))
	game.queue_free()
	await process_frame
	quit()
