extends SceneTree
## Run against the actual exported PCK, not the editor's source scene cache.
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
	var scene = load("res://scenes/levels/luoyang_chapter.tscn")
	var game = scene.instantiate()
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	check(game.overlay.theme.resource_path.ends_with("wuxia-game.tres") and game.buttons[0].theme_type_variation == &"WuxiaPrimary", "exported chapter uses the shared menu theme and primary brush")
	check(game.title.text == "洛阳关" and not game.get_node("UI/Overlay/Panel/Motion").visible and game.get_node("UI/Culture/Card").theme_type_variation == &"WuxiaPaper", "exported entry, settings and culture retain the unified interface")
	var anchors_ok = true
	for path in ["World/Rider", "World/MengTan", "World/Archer", "Cutscene/Hero", "Cutscene/MengTan", "Cutscene/HanFu", "Cutscene/HeroTurn", "Cutscene/HeroBinding", "Cutscene/Procession"]:
		var actor = game.get_node(path)
		for i in actor.frames.size():
			var frame = actor.frames[i]
			anchors_ok = anchors_ok and frame.has_meta("ground_pivot")
			actor.pose(i)
			anchors_ok = anchors_ok and actor.get_node("Body/Sprite").offset == -Vector2(frame.get_meta("ground_pivot", Vector2.ZERO))
	check(anchors_ok, "exported actor frames retain every ground anchor and sprite offset")
	game.model._begin_play("chase")
	game.model.step(0.3)
	game._sync_world()
	check(not game.get_node("UI/Keys").visible and game.get_node("UI/HealthDisplay/HP").max_value == 4, "exported chase clears the hint while retaining four-hit HUD rules")
	check(game.rider.position == game.road.project(game.model.lane, 0.0), "exported rider follows the authored player ground line")
	check(game.get_node("World/MengTan").is_visible_in_tree() and game.get_node("World/MengTan/Name").visible and not game.get_node("World/Gate").visible, "exported chase keeps a visible target with the gate behind the camera")
	game.model.step(0.5)
	game._sync_world()
	check(game.model.pursuer.lane < 1.0 and game.get_node("World/MengTan").position.is_equal_approx(game.road.project(game.model.pursuer.lane, game.model.gap)), "exported target follows the moving shared-road lane")
	var s = game.rider.get_node("Body/Sprite")
	check(s.offset.y < -250 and s.scale.y < 1.0, "exported rear rider stays above its hoof anchor")
	game.model._story("intro")
	game._sync_world()
	check(game.get_node("Cutscene/Hero").position == game.get_node("Cutscene/HeroRest").position and game.get_node("Cutscene/Hero/Body/Sprite").offset.y < -250, "exported side-view hero remains above the story panel")
	game.model._story("ambush")
	game.model.phase_clock = 4.4
	game._sync_world()
	check(game.get_node("Cutscene/HeroTurn").pose_index == 6 and game.get_node("Cutscene/HeroTurn").visible, "exported ambush selects the injured returning mounted pose")
	game.model.phase_clock = 1.4
	game._sync_world()
	check(game.get_node("Cutscene/HeroTurn").pose_index == 2 and game.get_node("Cutscene/Gate").visible, "exported pivot retains frontal angle and the gate on the return side")
	game.model.lane = -1.0
	game.model.phase_clock = 6.6
	game._sync_world()
	check(game.rider.position == game.road.project(0.0, 0.0) and game.get_node("World/Gate").visible and game.story_panel.modulate.a == 0.0, "exported return aligns the next center-lane start and clears the story panel")
	game.model._begin_play("chase")
	game.model.elapsed = game.model.CHASE_LIMIT - 8.0
	game._sync_world()
	check(game.get_node("ForkLandscape").visible and game.get_node("ForkLandscape").modulate.a == 1.0, "exported junction is fully visible for the final eight seconds")
	game.model._fail("孟坦逃脱")
	game.model.phase_clock = 2.2
	game._sync_world()
	check(game.get_node("World/MengTan").visible and game.get_node("World/MengTan").position.x > game.get_node("ForkBend").position.x and game.get_node("ForkLandscape/Foliage").visible, "exported escape uses the right fork and foreground foliage")
	game.model._story("ending")
	game.model.phase_clock = 1.8
	game._sync_world()
	check(game.get_node("Cutscene/HeroBinding").pose_index == 3 and game.get_node("Cutscene/HeroBinding").visible, "exported ending contains the drawn cloth-tightening pose")
	game.model.phase_clock = 7.0
	game._sync_world()
	check(game.get_node("Cutscene/Procession").visible and game.get_node("Cutscene/HeroBinding").pose_index in [6, 7] and game.get_node("Cutscene/Gate").visible, "exported departure shows the wheeled caravan following the bound rider")
	check(game.get_node("Cutscene/Procession").frames[0].atlas.resource_path.ends_with("carriage-walk-v2.png") and not ResourceLoader.exists("res://assets/luoyang-art/carriage-walk.png"), "exported caravan uses the first-chapter identity revision and excludes the rejected candidate")
	game.model._begin_play("sprint")
	game.model.step(3.2)
	game._sync_world()
	var arrow = game.model.hazards[0]
	var target = game.hazard_nodes[arrow.id].get_node("Target")
	check(arrow.phase == "locked" and arrow.lock_seconds == 0.75 and target.get_node("Locked").visible and target.get_node("ReleaseBar").visible, "exported opening shot retains the longer lock and authored shape/countdown")
	game.queue_free()
	await process_frame
	print("LUOYANG EXPORTED PACK CHECKS: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
