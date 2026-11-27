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
	check(game.get_node("Cutscene").visible and game.get_node("Cutscene/Carriage").visible, "opening shows the carriage in a distinct side-view scene")
	check(game.get_node("Cutscene/MengTan").position.x - game.get_node("Cutscene/HanFu").position.x >= 150, "opening keeps mounted Meng Tan and gate-side Han Fu separate")
	var atlas_ok = true
	for name in ["World/Rider", "World/MengTan", "World/Archer", "Cutscene/Hero", "Cutscene/MengTan", "Cutscene/HanFu", "Cutscene/HeroTurn", "Cutscene/HeroBinding", "Cutscene/Procession"]:
		var actor = game.get_node(name)
		for texture in actor.frames:
			var bounds = Rect2(Vector2.ZERO, texture.atlas.get_size())
			atlas_ok = atlas_ok and bounds.encloses(texture.region) and texture.filter_clip and texture.get_meta("ground_baseline") > 0
	check(atlas_ok, "all actor atlas regions stay inside source sheets with explicit ground baselines")
	check(game.rider.frames.size() == 12 and game.get_node("Cutscene/Hero").frames.size() == 8, "rear gallop/wound/steer/hit and mounted swing frames are real resources")
	game.model._begin_play("chase")
	game.model.step(0.1)
	game._sync_world()
	var pose: int = game.rider.pose_index
	game.model.step(0.12)
	game._sync_world()
	check(game.rider.pose_index != pose and game.rider.get_node("Body").position == Vector2.ZERO, "gallop changes texture instead of bobbing the whole rider")
	game.model.request_lane(-1)
	game.model.step(0.02)
	game._sync_world()
	check(game.rider.pose_index == 8, "left change uses its independent mounted lean pose")
	game.model.step(0.3)
	game.model._hit("barricade")
	game._sync_world()
	check(game.rider.pose_index == 10 and game.get_node("World/Impact").visible, "ordinary collision shows recoil and contact feedback")
	game.muted = false
	for channel in ["Hooves", "Effects", "BowCue"]: game.art.cue(game, "hoof", channel)
	game.model.pause()
	game._sync_world()
	var frozen = [game.rider.pose_index, game.art.hit_age, game.get_node("Road/Grit/Stone0").position, game.get_node("World/Dust/Puff0").position, game.art.hoof_clock, game.art.hoof_step]
	game.model.step(5.0)
	game._sync_world()
	check([game.rider.pose_index, game.art.hit_age, game.get_node("Road/Grit/Stone0").position, game.get_node("World/Dust/Puff0").position, game.art.hoof_clock, game.art.hoof_step] == frozen, "pause freezes gallop, feedback, road grit, dust and hoof cadence")
	check(game.get_node("Hooves").stream_paused and game.get_node("Effects").stream_paused and game.get_node("BowCue").stream_paused, "all new audio channels pause together")
	game.muted = true
	game.art.audio_state(game)
	game.model.retry()
	game._sync_world()
	check(not game.get_node("World/Impact").visible and game.rider.get_node("Body").modulate == Color.WHITE, "checkpoint restart clears hit effects and actor tint")
	var beat: int = game.art.hoof_step
	game.model.step(0.5)
	game._sync_world()
	check(game.art.hoof_step == (beat + 1) % 3 and game.art.hoof_clock > game.model.phase_clock, "a late frame schedules one hoof contact instead of replaying missed beats in a burst")
	game.reduced_motion = true
	game.model._hit("barricade")
	game._sync_world()
	check(not game.get_node("World/Dust").visible and game.get_node("World").position == Vector2.ZERO and game.get_node("UI/HitFlash").color.a == 0.0, "reduced motion removes dust, camera shake and screen flash")
	game.model._story("meng_strike")
	game.model.phase_clock = 0.7
	game._sync_world()
	check(game.get_node("Cutscene/Hero").pose_index == 2, "slaying has a deliberate blade anticipation pose")
	game.model.phase_clock = 1.05
	game._sync_world()
	check(game.get_node("Cutscene/Hero").pose_index == 4 and game.get_node("Cutscene/MengTan").pose_index == 1 and game.get_node("Cutscene/Contact").visible, "blade contact drives a distinct enemy recoil")
	game.model.phase_clock = 1.7
	game._sync_world()
	check(game.get_node("Cutscene/MengTan").pose_index == 3 and game.get_node("Cutscene/MengTan").rotation == 0.0, "Meng Tan falls with drawn dismount frames rather than a rotated horse")
	game.model._story("ambush")
	game.model.phase_clock = 3.8
	game._sync_world()
	check(game.get_node("Cutscene/HanFu").pose_index == 4 and game.get_node("Cutscene/AmbushArrow").visible, "ambush release uses the archer release frame and visible projectile")
	game.model.phase_clock = 4.1
	game._sync_world()
	check(game.get_node("Cutscene/HeroTurn").pose_index == 5 and game.model.hits == 1, "scripted hit changes the mounted pose without adding avoidable damage")
	game.model._next_story()
	game.model.step(0.3)
	game._sync_world()
	check(game.rider.pose_index in [4, 5, 6, 7] and game.model.wounded and game.model.wound_events == 1, "sprint keeps the dedicated left-arm-wounded gallop row")
	check(game.get_node("World/Archer").position.y > game.get_node("World/Gate").position.y + 45.0, "interactive archer stands by the low gate approach instead of floating on the tower")
	game.model._add_hazard("arrow", 0)
	game.model.hazards[-1].phase = "locked"
	game._sync_world()
	check(game.get_node("World/Archer").pose_index == 3, "interactive lock visibly holds full bow draw")
	game.model.hazards[-1].phase = "flying"
	game._sync_world()
	check(game.get_node("World/Archer").pose_index == 4, "interactive release changes the archer silhouette")
	game.model._story("han_strike")
	game.model.phase_clock = 1.7
	game._sync_world()
	check(game.get_node("Cutscene/HanFu").pose_index == 7 and game.get_node("Cutscene/HanFu").rotation == 0.0, "Han Fu finishes in an independent collapsed frame")
	check(game.get_node("Cutscene/Hero/Wound").visible, "slaying Han Fu preserves the left-arm binding across reused attack poses")
	game.model._story("ending")
	game._sync_world()
	game.model.phase_clock = 5.8
	game._sync_world()
	check(game.get_node("Cutscene/Procession").visible and game.get_node("Cutscene/HeroBinding").pose_index == 5, "ending reunites the moving carriage and newly bound rider")
	game.model._begin_play("sprint")
	game.muted = false
	game.art.cue(game, "hoof", "Hooves")
	game.art.cue(game, "bow", "BowCue")
	check(game.get_node("Hooves").playing and game.get_node("BowCue").playing, "hoof and bow cues can coexist without cutting each other off")
	game._toggle_sound()
	check(not game.get_node("Hooves").playing and not game.get_node("BowCue").playing, "mute immediately stops every new audio channel")
	game.model._story("fall")
	game._sync_world()
	check(game.rider.pose_index == 11 and game.rider.get_node("Body").rotation == 0.0, "wounded failure keeps an intact stopped horse and rider")
	game.model.start()
	game.model._story("fall")
	game._sync_world()
	check(game.rider.pose_index == 10, "unwounded failure does not invent an early arm bandage")
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("LUOYANG ART CHECKS: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
