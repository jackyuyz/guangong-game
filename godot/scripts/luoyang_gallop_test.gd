extends SceneTree
## Real playback checks use CoreAudio and a save-free chapter instance.
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
	game.set_script(load("res://scripts/luoyang_art_capture_view_fixture.gd"))
	root.add_child(game)
	game.set_process(false)
	game.muted = false
	game.begin_chapter()
	var hooves: AudioStreamPlayer = game.get_node("Hooves")
	check(hooves.stream is AudioStreamMP3 and hooves.stream.loop and hooves.stream.resource_path.ends_with("harse-gallop-loop2.mp3"), "authored player uses the user's MP3 with whole-file looping")
	check(not hooves.playing, "standing opening is silent")
	game.model._begin_play("chase")
	game.model.next_spawn = INF
	game._sync_world()
	await create_timer(0.4).timeout
	var position_before = hooves.get_playback_position()
	check(hooves.playing and position_before > 0.03 and hooves.pitch_scale == 1.0 and is_equal_approx(hooves.volume_db, -12.0), "running starts the continuous recording at its original speed")
	for i in 12:
		game.model.step(0.01)
		game._sync_world()
	await create_timer(0.15).timeout
	check(hooves.get_playback_position() > position_before + 0.08, "render updates do not restart the recording on every frame or old hoof beat")
	var playback = hooves.get_stream_playback()
	game.model.pause()
	game._sync_world()
	await create_timer(0.07).timeout
	var paused = hooves.get_playback_position()
	await create_timer(0.2).timeout
	game._sync_world()
	check(hooves.stream_paused and absf(hooves.get_playback_position() - paused) < 0.02, "pause holds the exact recording position")
	game.model.resume()
	game._sync_world()
	await create_timer(0.4).timeout
	check(not hooves.stream_paused and hooves.get_stream_playback() == playback and hooves.get_playback_position() > paused + 0.08, "resume continues the same playback rather than restarting at zero")
	game.model.slowdown = 0.4
	game._sync_world()
	check(is_equal_approx(hooves.pitch_scale, 0.8) and is_equal_approx(hooves.volume_db, -15.0), "collision recovery slows and softens the same recording")
	game.model.slowdown = 0.0
	game._sync_world()
	check(hooves.pitch_scale == 1.0 and is_equal_approx(hooves.volume_db, -12.0), "full-speed gallop returns after recovery")
	await create_timer(3.3).timeout
	check(hooves.playing and hooves.get_playback_position() < hooves.stream.get_length(), "recording keeps playing across the three-second loop boundary")
	game._toggle_sound()
	check(not hooves.playing, "mute stops the complete recording immediately")
	game._toggle_sound()
	game._sync_world()
	check(hooves.playing, "unmute while riding restarts one loop")
	game.model._story("ambush")
	game.model.phase_clock = 2.8
	game._sync_world()
	check(hooves.playing, "returning horse has gallop only during its actual travel")
	game.model.phase_clock = 4.4
	game._sync_world()
	check(not hooves.playing, "stopped horse during the arrow scene does not keep galloping")
	game.model._story("ending")
	game.model.phase_clock = 4.3
	game._sync_world()
	check(hooves.playing and is_equal_approx(hooves.pitch_scale, 0.65) and is_equal_approx(hooves.volume_db, -16.0), "caravan travel uses a quieter slower playback")
	game.model.phase_clock = 5.9
	game._sync_world()
	check(not hooves.playing, "caravan meeting rest is silent")
	game.model._begin_play("sprint")
	game._sync_world()
	game.model._fail("气血耗尽")
	game._sync_world()
	check(not hooves.playing, "failure stops hoof audio before retry controls")
	game.model.phase_clock = 1.0
	game.model._next_story()
	game.model.retry()
	game._sync_world()
	check(hooves.playing and hooves.pitch_scale == 1.0, "checkpoint retry starts one clean running loop")
	game.art.release_audio(game)
	check(not hooves.playing and hooves.stream == null, "scene departure releases the loop stream")
	game.queue_free()
	await process_frame
	await create_timer(0.2).timeout
	print("LUOYANG GALLOP CHECKS: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
