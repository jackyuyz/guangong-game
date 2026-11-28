extends SceneTree
var checks = 0
var failures = 0
var game: Node
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)
func arrow(lane: int, depth: float, phase = "flying") -> Node2D:
	game.model._begin_play("sprint")
	game.model.hits = 0
	game.model.seconds = 0.0
	game.model.next_spawn = INF
	game.model._add_hazard("arrow", lane)
	var h: Dictionary = game.model.hazards[-1]
	h.phase = phase
	h.distance = depth
	h.age = 2.8 if phase == "flying" else (0.4 if phase == "aim" else 1.6)
	game._sync_world()
	return game.hazard_nodes[h.id]
func snapshot(view: Node2D) -> Array:
	return [view.transform, view.get_node("Flight").transform, view.get_node("Wake/Trail").points,
		view.get_node("Wake").modulate, view.get_node("Flight/Ghost").position, game.model.hp, game.model.seconds]
func run() -> void:
	game = load("res://scenes/levels/luoyang_chapter.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.begin_chapter()
	var aim = arrow(0, 88.0, "aim")
	check(not aim.get_node("Flight").visible and not aim.get_node("Wake").visible and aim.get_node("Target/Tracking").visible, "no projectile or wake before release; tracking brackets remain")
	var image: Image = aim.get_node("Flight/Sprite").texture.atlas.get_image()
	check(image.get_pixel(0, 0).a == 0.0 and image.get_pixel(512, 780).a > 0.75, "generated texture retains genuine transparent background and opaque shaft")
	var locked = arrow(0, 88.0, "locked")
	check(not locked.get_node("Flight").visible and locked.get_node("Target/Locked").visible and locked.get_node("Target/ReleaseBar").visible, "locked warning/countdown remains separate from the actual flight")
	for lane in [-1, 0, 1]:
		var far = arrow(lane, 75.0)
		var sprite: Sprite2D = far.get_node("Flight/Sprite")
		var far_height = sprite.get_rect().size.y * sprite.global_scale.y
		check(far_height >= 28.0 and sprite.texture is AtlasTexture and sprite.texture.atlas.resource_path.ends_with("war-arrow-incoming.png"), "generated arrow remains readable at launch in lane %d" % lane)
		var near = arrow(lane, 4.0)
		sprite = near.get_node("Flight/Sprite")
		check(sprite.get_rect().size.y * sprite.global_scale.y > far_height * 3.0, "perspective enlarges the incoming image toward the player in lane %d" % lane)
		var direction: Vector2 = (game.road.project(lane, 3.5) - game.road.project(lane, 4.0)).normalized()
		var facing = Vector2.DOWN.rotated(near.get_node("Flight").rotation)
		check(facing.dot(direction) > 0.999 and not near.get_node("Shaft").visible and not near.get_node("Head").visible, "arrowhead follows the actual lane's radial flight, replacing old geometry")
		check(near.get_node("Wake/Trail").points.size() == 4 and near.get_node("Wake/Slip0").visible and near.get_node("Wake/Slip1").visible, "tapered sampled wake and flanking air streaks strengthen the near pass")
		game.model.pause()
		var before = snapshot(near)
		game.model.step(5.0)
		game._sync_world()
		check(snapshot(near) == before, "pause freezes projectile, wake, ghost and scored time")
		game.model.resume()
		game.reduced_motion = true
		game._sync_world()
		check(sprite.is_visible_in_tree() and not near.get_node("Wake").visible and not near.get_node("Flight/Ghost").visible and near.get_node("Target/Locked").visible, "reduced motion retains the arrow and locked route but removes decorative streaks")
		game.reduced_motion = false
		var departing = arrow(lane, -17.8)
		sprite = departing.get_node("Flight/Sprite")
		check(not (sprite.global_transform * sprite.get_rect()).intersects(Rect2(0, 0, 960, 540)) and departing.get_node("Wake").modulate.a == 0.0 and departing.get_node("Flight/Ghost").modulate.a == 0.0, "entire arrow and decorative wake leave cleanly before retirement in lane %d" % lane)
	var contact = arrow(0, 0.01)
	game.model.step(0.03)
	game._sync_world()
	check(game.model.hp == 3 and game.model.hits == 1 and contact.get_node("Flight").visible and not contact.get_node("Target").visible, "single hit resolves once while the projectile continues past")
	game.model.step(0.08)
	game._sync_world()
	check(game.model.hp == 3 and game.model.hits == 1, "ghost and trail never cause repeated damage")
	game.model.pause()
	game.model.retry()
	game._sync_world()
	check(game.model.hp == 4 and game.hazard_nodes.is_empty(), "checkpoint retry removes every old projectile and effect")
	for dt in [1.0 / 120.0, 1.0 / 15.0]:
		arrow(0, 2.0)
		game.model.request_lane(1)
		for i in int(0.3 / dt):
			game.model.step(dt)
			game._sync_world()
		check(game.model.hits == 1 and game.model.hp == 3, "existing late-dodge timing and single damage remain at %d FPS" % roundi(1.0 / dt))
		arrow(0, 18.0)
		game.model.request_lane(1)
		for i in int(0.4 / dt):
			game.model.step(dt)
			game._sync_world()
		check(game.model.hits == 0 and game.model.hp == 4, "timely dodge still clears the visible projectile at %d FPS" % roundi(1.0 / dt))
	game.queue_free()
	await process_frame
	print("LUOYANG ARROW CHECKS: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
