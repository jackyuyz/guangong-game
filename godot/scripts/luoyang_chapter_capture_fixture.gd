extends SceneTree
## Authored full-chapter blockout rendered natively; never opens a player profile.
var game: Node
var output: String
func _initialize() -> void: call_deferred("run")
func capture(name: String) -> void:
	game.overlay_guard = 0.0
	game._sync_world()
	await process_frame
	RenderingServer.force_draw(false)
	var code = root.get_texture().get_image().save_png(output.path_join(name + ".png"))
	if code != OK: push_error("Capture failed: " + name)
	print("CAPTURE: ", name)
func run() -> void:
	output = ProjectSettings.globalize_path("res://../builds/previews/luoyang-chapter")
	DirAccess.make_dir_recursive_absolute(output)
	game = load("res://scenes/levels/luoyang_chapter.tscn").instantiate()
	game.set_script(load("res://scripts/luoyang_art_capture_view_fixture.gd"))
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.begin_chapter()
	await capture("intro")
	game.model._begin_play("chase")
	game.model.step(3.0)
	await capture("chase")
	game.model.gap = 32.0
	await capture("chase-near")
	game.model.gap = 35.0
	await capture("chase-close")
	game.model.meng_defeated = true
	game.model._story("meng_strike")
	game.model.phase_clock = 1.1
	await capture("meng-strike")
	game.model._story("ambush")
	game.model.phase_clock = 0.9
	await capture("ambush")
	game.model._next_story()
	game.model.step(2.9)
	await capture("wounded-sprint")
	game.model.elapsed = 26.0
	await capture("gate-approach")
	game.model.victory_locked = true
	game.model._story("han_strike")
	game.model.phase_clock = 1.2
	await capture("han-strike")
	game.model._story("ending")
	game.model._next_story()
	await capture("culture")
	game.model.seconds = 66.0
	game.model.finish_culture()
	game._show_result()
	await capture("result")
	game.queue_free()
	await process_frame
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "/tmp/guangong-ch02-capture-%d.cfg" % Time.get_ticks_usec()
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.progress.mark_cleared("dongling", 2000)
	game.progress.record_luoyang({"seconds": 66.0, "hits": 0, "retries": 0, "switches": 20})
	game._return_to_map()
	game.journey.set_reduced_motion(true)
	game.journey.select_chapter(1)
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(output.path_join("map-cleared.png"))
	print("CAPTURE: map-cleared")
	game.journey._release_pending = false
	game._enter_chapter("luoyang")
	game.chapter_two.set_process(false)
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(output.path_join("integrated-intro.png"))
	print("CAPTURE: integrated-intro")
	game.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	quit()
