extends SceneTree
var game: Node
var output: String
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	game.overlay_guard = 0.0
	game._sync_world()
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(output.path_join(name + ".png"))
	print("CAPTURE: ", name)
func run() -> void:
	output = ProjectSettings.globalize_path("res://../builds/previews/luoyang-interface")
	DirAccess.make_dir_recursive_absolute(output)
	game = load("res://scenes/levels/luoyang_chapter.tscn").instantiate()
	game.set_script(load("res://scripts/luoyang_art_capture_view_fixture.gd"))
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.reduced_motion = true
	await capture("entry")
	game._open_settings()
	await capture("settings")
	game._show_help(true)
	await capture("help")
	game.begin_chapter()
	game.model._begin_play("tutorial")
	await capture("tutorial")
	game.model._begin_play("chase")
	game.model.step(8.0)
	await capture("chase")
	game._toggle_pause()
	await capture("pause")
	game._confirm_exit()
	await capture("confirm")
	game._cancel_exit()
	game.model._fail("气血耗尽")
	game.model.step(0.9)
	game._show_result()
	await capture("failure")
	game.begin_chapter()
	game.model._story("ambush")
	game.model.phase_clock = 4.1
	await capture("story")
	game.model._begin_play("sprint")
	game.model.step(3.2)
	await capture("sprint")
	game.model.victory_locked = true
	game.model._story("ending")
	game.model._next_story()
	await capture("culture")
	game.model.seconds = 66.0
	game._advance_story()
	await capture("result")
	game.overlay_guard = 0.0
	game._overlay_action(1)
	await capture("stats")
	game.save_notice = "本次进度未能保存"
	await capture("save-error")
	game.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	quit()
