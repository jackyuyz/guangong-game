extends SceneTree
## Save-free native comparison of lock, approach and near miss.
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var game = load("res://scenes/levels/luoyang_chapter.tscn").instantiate()
	game.set_script(load("res://scripts/luoyang_art_capture_view_fixture.gd"))
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.begin_chapter()
	game.model._begin_play("sprint")
	game.model.wounded = true
	game.model.next_spawn = INF
	game.model._add_hazard("arrow", 1)
	var h: Dictionary = game.model.hazards[-1]
	var folder = ProjectSettings.globalize_path("res://../builds/previews/luoyang-arrow")
	DirAccess.make_dir_recursive_absolute(folder)
	for row in [["tracking", "aim", 88.0, 0.5], ["locked", "locked", 88.0, 1.6], ["far", "flying", 75.0, 2.3], ["middle", "flying", 35.0, 2.9], ["near", "flying", 8.0, 3.5], ["passing", "flying", -4.0, 3.65], ["offscreen", "flying", -16.0, 3.85]]:
		h.phase = row[1]
		h.distance = row[2]
		h.age = row[3]
		h.resolved = h.distance <= 0.0
		game._sync_world()
		await process_frame
		RenderingServer.force_draw(false)
		root.get_texture().get_image().save_png(folder.path_join(row[0] + ".png"))
		print("CAPTURE: ", row[0], " ", h, " sprite ", game.hazard_nodes[h.id].get_node("Flight/Sprite").global_position, " scale ", game.hazard_nodes[h.id].get_node("Flight/Sprite").global_scale, " visible ", game.hazard_nodes[h.id].get_node("Flight/Sprite").is_visible_in_tree())
	h.phase = "flying"
	h.distance = 8.0
	h.age = 3.5
	h.resolved = false
	game.reduced_motion = true
	game._sync_world()
	await process_frame
	RenderingServer.force_draw(false)
	root.get_texture().get_image().save_png(folder.path_join("reduced.png"))
	game.queue_free()
	await process_frame
	quit()
