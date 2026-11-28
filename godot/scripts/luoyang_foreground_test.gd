extends SceneTree
var checks = 0
var failures = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)
func run() -> void:
	var game = load("res://scenes/levels/luoyang_chapter.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.begin_chapter()
	game.model._begin_play("chase")
	game.model.next_spawn = INF
	for lane in [-1, 0, 1]: game.model._add_hazard("barricade", lane)
	var viewport = Rect2(Vector2.ZERO, Vector2(960, 540))
	for lane_index in 3:
		var h = game.model.hazards[lane_index]
		var previous_y = -INF
		var previous_scale = 0.0
		var continued = true
		for depth in [4.0, 2.0, 0.0, -2.0, -4.0, -6.0, -8.0, -10.0, -12.0, -17.8]:
			h.distance = depth
			h.resolved = depth <= 0.0
			game._sync_world()
			var view = game.hazard_nodes[h.id]
			var sprite: Sprite2D = view.get_node("Sprite")
			var bounds: Rect2 = sprite.global_transform * sprite.get_rect()
			if bounds.intersects(viewport):
				continued = continued and view.position.y > previous_y and view.scale.x > previous_scale
			previous_y = view.position.y
			previous_scale = view.scale.x
		check(continued, "visible lane %d barricade keeps moving and enlarging beyond the hoof line" % (lane_index - 1))
		var sprite: Sprite2D = game.hazard_nodes[h.id].get_node("Sprite")
		check(not (sprite.global_transform * sprite.get_rect()).intersects(viewport), "lane %d artwork is fully offscreen before model retirement" % (lane_index - 1))
	check(is_equal_approx(game.road.factor(0.0), 1.0) and is_equal_approx(game.road.factor(18.0), 0.5), "rider and incoming obstacle projection are unchanged")
	check(is_finite(game.road.factor(-18.0)) and game.road.factor(-18.0) <= game.road.max_near_scale + 0.001, "near-plane cap stays finite behind the camera")
	game.model.hazards.clear()
	game.model._add_hazard("barricade", 0)
	game.model.hazards[0].distance = 0.1
	game.model.lane = 0.0
	game.model.target_lane = 0
	game.model.from_lane = 0.0
	game.model.step(0.1)
	game._sync_world()
	check(game.model.hp == 3 and game.model.hits == 1 and game.model.hazards[0].resolved, "contact still resolves once at the original ground crossing")
	var id = game.model.hazards[0].id
	game.model.pause()
	var frozen = [game.hazard_nodes[id].position, game.hazard_nodes[id].scale, game.model.hazards[0].distance]
	game.model.step(2.0)
	game._sync_world()
	check(frozen == [game.hazard_nodes[id].position, game.hazard_nodes[id].scale, game.model.hazards[0].distance], "pause freezes a departing foreground barricade")
	game.model.resume()
	game.model.step(1.8)
	game._sync_world()
	check(game.model.hits == 1 and not game.hazard_nodes.has(id), "passing artwork is retired without a second collision")
	game.model.pause()
	game.model.retry()
	game._sync_world()
	check(game.model.hp == 4 and game.model.hazards.is_empty() and game.hazard_nodes.is_empty(), "retry clears all departing artwork and restores the checkpoint")
	game.queue_free()
	await process_frame
	await create_timer(0.25).timeout
	print("LUOYANG FOREGROUND CHECKS: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
