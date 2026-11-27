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
func sample(phase: String, t: float) -> void:
	if game.model.phase != phase: game.model._story(phase)
	game.model.phase_clock = t
	game._sync_world()
func freeze() -> Array:
	return [game.model.phase_clock, game.get_node("Cutscene/HeroTurn").pose_index,
		game.get_node("Cutscene/HeroTurn").position, game.get_node("Cutscene/AmbushArrow").position,
		game.get_node("Cutscene").modulate, game.get_node("Cutscene/TurnDust").scale,
		game.get_node("UI/Story/Title").text, game.art.hoof_clock]
func run() -> void:
	game = load("res://scenes/levels/luoyang_chapter.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.begin_chapter()
	var gate_x: float = game.get_node("Cutscene/Gate").position.x
	check(gate_x < game.get_node("Cutscene/Hero").position.x and game.get_node("Cutscene/HanFu").position.x < game.get_node("Cutscene/Hero").position.x, "opening locates gate and its guard behind the rightward pursuit")
	check(game.get_node("Cutscene/MengTan/Body").scale.x < 0 and game.get_node("Cutscene/HanFu").pose_index == 0 and not game.get_node("Cutscene/AmbushArrow").visible, "Meng Tan faces the challenger; Han Fu keeps his bow down without revealing the ambush")
	sample("intro", 1.7)
	check(game.get_node("Cutscene/MengTan").pose_index == 1 and game.get_node("Cutscene/Contact").visible and not game.model.meng_defeated, "opening clash causes a mounted recoil without a premature kill")
	sample("intro", 2.4)
	check(game.get_node("Cutscene/DepartingMeng").visible and not game.get_node("Cutscene/MengTan").visible, "feigned retreat bridges its direction change through the rear riding angle")
	sample("intro", 3.1)
	var ahead: Vector2 = game.get_node("Cutscene/MengTan").position
	check(game.get_node("Cutscene/MengTan/Body").scale.x > 0 and ahead.x > game.get_node("Cutscene/Hero").position.x, "fleeing Meng Tan turns away and takes the lead")
	sample("intro", 4.7)
	check(game.get_node("Cutscene/MengTan").position.x > ahead.x and game.get_node("Cutscene/Hero").position.x > game.get_node("Cutscene/IntroContact").position.x, "both horses leave the fixed gate in the same rightward direction")
	sample("intro", 6.6)
	check(game.get_node("Cutscene").modulate.a == 0.0 and game.rider.visible and game.get_node("World/MengTan").visible and not game.get_node("World/Gate").visible, "departure resolves into rear-view road with no gate ahead")
	game.model.step(0.5)
	game._sync_world()
	check(game.model.phase == "tutorial" and not game.get_node("Cutscene").visible and game.get_node("Cutscene").modulate.a == 1.0, "natural departure hands off cleanly and restores cinematic opacity")
	game.model._begin_play("chase")
	game._sync_world()
	check(not game.get_node("World/Gate").visible, "the gate remains behind throughout interactive pursuit")
	for t in [0.5, 1.0, 1.4, 1.9, 2.2]:
		sample("ambush", t)
		var snapshot = freeze()
		game.model.pause()
		game.model.step(10.0)
		game._sync_world()
		check(freeze() == snapshot and game.get_node("Cutscene/Gate").position.x == gate_x, "pause freezes pivot angle, ground path and fixed gate at %.1fs" % t)
		game.model.resume()
	sample("ambush", 2.2)
	var turn_position: Vector2 = game.get_node("Cutscene/HeroTurn").position
	check(game.get_node("Cutscene/HeroTurn").pose_index == 4 and turn_position.x > gate_x, "full right-front-left turn completes before returning towards the left gate")
	sample("ambush", 3.3)
	check(game.get_node("Cutscene/HeroTurn").position.x < turn_position.x and game.get_node("Cutscene/HanFu").pose_index == 3, "returning horse moves left while gate-side Han Fu draws")
	sample("ambush", 3.8)
	var arrow = game.get_node("Cutscene/AmbushArrow")
	check(arrow.visible and arrow.position.x > game.get_node("Cutscene/HanFu").position.x and arrow.position.x < game.get_node("Cutscene/HeroTurn").position.x, "arrow travels from the left gate towards the returning rider")
	var frozen = freeze()
	game.model.pause()
	game.model.step(9.0)
	game._sync_world()
	check(freeze() == frozen and arrow.visible, "pause also freezes the flying scripted arrow")
	game.model.resume()
	sample("ambush", 4.05)
	var arm = game.get_node("Cutscene/HeroTurn/LeftArm")
	check(game.get_node("Cutscene/HeroTurn").pose_index == 5 and game.get_node("Cutscene/Contact").position == arm.global_position and not arrow.visible, "contact lands on the authored left-arm marker and changes to the struck pose")
	check(game.model.hp == 4 and game.model.hits == 0 and game.model.hazards.is_empty() and game.model.seconds == 0.0, "longer story creates no hazards, avoidable damage or scored time")
	game.reduced_motion = true
	sample("ambush", 1.4)
	check(game.get_node("Cutscene/HeroTurn").pose_index == 2 and not game.get_node("Cutscene/TurnDust").visible, "reduced motion preserves the real frontal turn while removing the scrape effect")
	game.model.lane = 1.0
	sample("ambush", 6.6)
	check(game.get_node("Cutscene").modulate.a == 0.0 and game.get_node("World/Gate").visible and game.rider.pose_index in [4, 5, 6, 7] and game.rider.position == game.road.project(0.0, 0.0), "return reveals a gate ahead and centers the wounded rider even after a side-lane chase")
	var rear: Vector2 = game.rider.position
	var door: Vector2 = game.get_node("World/Gate").position
	game.model.step(0.5)
	game._sync_world()
	check(game.model.phase == "sprint" and game.model.wound_events == 1 and game.rider.position == rear and game.get_node("World/Gate").position.distance_to(door) < 1.0, "natural ambush completion preserves geography and applies the wound once")
	# Fast skip follows the same checkpoint path, with no duplicate phase advance.
	game.begin_chapter()
	game.model.step(0.3)
	game.overlay_guard = 0.0
	game._advance_story()
	game._advance_story()
	check(game.model.phase == "tutorial", "repeated skip cannot bypass the tutorial")
	sample("ambush", 0.3)
	game.overlay_guard = 0.0
	game._advance_story()
	game._advance_story()
	check(game.model.phase == "sprint" and game.model.wounded and game.model.wound_events == 1 and game.model.checkpoint.wounded, "early ambush skip establishes exactly one wounded sprint checkpoint")
	game.model.pause()
	game.model.retry()
	game._sync_world()
	check(game.model.phase == "sprint" and game.model.wound_events == 1 and not game.get_node("Cutscene/HeroTurn").is_visible_in_tree(), "sprint retry keeps wound continuity without replaying the turn")
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("LUOYANG STORY CHECKS: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
