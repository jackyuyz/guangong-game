extends SceneTree
## Native-renderer evidence of the save-free prototype; not an interactive pass.
var game: Node
var output = ""
func _initialize() -> void:
	call_deferred("run")

func capture(name: String) -> void:
	game._sync_world()
	await process_frame
	await RenderingServer.frame_post_draw
	var result = root.get_texture().get_image().save_png(output.path_join(name + ".png"))
	if result != OK:
		push_error("capture failed: " + name)
	print("CAPTURE: ", name)

func run() -> void:
	output = ProjectSettings.globalize_path("res://../builds/previews/luoyang-prototype")
	DirAccess.make_dir_recursive_absolute(output)
	game = load("res://scenes/prototypes/luoyang_prototype.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	await capture("menu")
	game.model.start("barricades")
	game.overlay.hide()
	game.model.request_lane(-1)
	game.model.step(3.8)
	await capture("barricades")
	game.model.start("arrows")
	game.model.step(2.25)
	await capture("arrow-lock")
	game.model.step(0.8)
	game.model.request_lane(1)
	game.model.step(0.2)
	await capture("arrow-dodge")
	game.overlay_guard = 0.0
	game._toggle_pause()
	await capture("pause")
	game.queue_free()
	await process_frame
	quit()
