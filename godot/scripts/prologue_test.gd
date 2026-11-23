extends SceneTree
## Input, sound, and session regressions use an isolated temporary save.
class AudioGate extends "res://scripts/prologue.gd":
	var test_ready = true
	func _audio_context_ready() -> bool:
		return test_ready

var failures = 0
var game: Node
var p: Control
func _initialize() -> void:
	call_deferred("run")
func check(ok: bool, text: String) -> void:
	if ok: print("PASS: ", text)
	else:
		failures += 1
		push_error("FAIL: " + text)
func next_frame() -> void:
	await process_frame
	await process_frame
func key(code: int, echo: bool = false) -> void:
	var e = InputEventKey.new()
	e.physical_keycode = code
	e.pressed = true
	e.echo = echo
	game._unhandled_input(e)
func click(at: Vector2) -> void:
	for down in [true, false]:
		var e = InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.pressed = down
		e.position = at
		e.global_position = at
		root.push_input(e, true)
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "/tmp/guangong-prologue-test.cfg"
	game.get_node("UI/Root/Prologue").set_script(AudioGate)
	root.add_child(game)
	game.set_process(false)
	game.muted = false
	p = game.prologue
	p.set_process(false)
	game._start()
	game._sync_scene()
	check(p.available and game.state == "prologue" and not game.ui.get_node("Root/HUD").visible, "new run opens authored prologue and hides HUD")
	var total = 0.0
	for scene in p.scenes:
		total += scene.duration
		var audio: AudioStream = load(scene.audio)
		check(audio.get_length() + .3 < scene.duration, "voice fits panel: " + scene.id)
	check(is_equal_approx(total, 51), "six-panel automatic timeline is 51 seconds")
	var start_x: float = game.x
	key(KEY_J);key(KEY_SPACE);key(KEY_D)
	game._process(1)
	check(game.attack_time == 0 and game.dodge_time == 0 and game.x == start_x and game.combat_seconds == 0, "prologue freezes movement, combat, and battle clock")
	click(Vector2(600, 250))
	check(p.index == 0, "blank image click does not turn a page")
	await next_frame()
	key(KEY_ENTER, true)
	check(p.index == 0, "held Enter echo is ignored")
	key(KEY_ENTER)
	p.get_node("Next").pressed.emit()
	check(p.index == 1, "Enter plus button in the same frame advances only once")
	await next_frame()
	p.previous()
	check(p.index == 0 and p.elapsed == 0, "previous restarts prior panel")
	await next_frame()
	p.toggle_auto()
	p._process(2)
	check(p.elapsed == 0 and p.voice.stream_paused, "manual reading pauses time and voice")
	await next_frame()
	p.advance()
	check(p.index == 1 and not p.auto_play and p.voice.stream_paused and not p.get_node("Transition").visible, "manual page turn shows the complete picture with voice paused")
	await next_frame()
	p.toggle_auto()
	p._process(1.3)
	var time: float = p.elapsed
	var anim_time: float = p.animation.current_animation_position
	game._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
	p._process(2)
	check(game.state == "pause" and p.elapsed == time and p.animation.current_animation_position == anim_time and p.voice.stream_paused and p.ambience.stream_paused and p.effect.stream_paused, "focus loss freezes animation and all three audio players")
	game._action("resume")
	p._process(.2)
	check(game.state == "prologue" and p.elapsed > time and not p.voice.stream_paused, "resume continues the same panel and voice")
	p._show_scene(4)
	check(p.get_node("Panels/Escort/Art/Illustration").texture != null and p.get_node("Transition").visible, "authored integrated frame crossfades from prior scene")
	p._process(5)
	check(not p.get_node("Transition").visible and p.get_node("Panels/Escort/Art").scale.x > 1, "crossfade finishes and gentle camera advances on scene clock")
	check(p.voice.playback_type == AudioServer.PLAYBACK_TYPE_STREAM, "narration uses stream playback for Web compatibility")
	game._action("prologue_sound")
	check(game.muted and p.get_node("Sound").text == "声音：关", "visible sound button controls shared mute and label")
	await next_frame()
	p.get_node("ReplayVoice").pressed.emit()
	check(not game.muted and p.index == 4 and p.elapsed == 0 and p.voice.playing and p.auto_play, "relisten unmutes and restarts only current panel")
	p.test_ready = false
	p._process(2)
	check(p.waiting_for_audio and p.elapsed == 0 and p.voice.stream_paused and p.ambience.stream_paused and p.get_node("Sound").text == "开启声音", "blocked audio holds timeline and all sound with visible unlock state")
	game._action("prologue_silent")
	p._process(.25)
	check(game.muted and not p.waiting_for_audio and p.elapsed > 0 and not p.voice.stream_paused, "explicit silent viewing releases blocked timeline")
	game._action("prologue_sound")
	p.test_ready = true
	p._process(.25)
	check(not p.waiting_for_audio and not p.voice.stream_paused and p.elapsed > .25, "audio becoming ready resumes same panel without reset")
	game._action("mute")
	check(p.voice.volume_db == -80 and p.ambience.volume_db == -80, "shared mute affects voice and sound bed")
	game._action("mute")
	check(p.voice.volume_db > -80, "unmute preserves playback")
	for i in 6:
		p._show_scene(i)
		p._process(float(p.scenes[i].duration))
	check(p.index == 5 and p.elapsed == p.scenes[5].duration and p.active, "automatic playback holds final mission panel")
	await next_frame()
	p.advance()
	p.completed.emit()
	check(game.state == "play" and game.phase == 0 and game.message.contains("寻刘备") and not p.active and not p.voice.playing, "completion is idempotent and enters tutorial with escort objective")
	key(KEY_J)
	check(game.attack_time == 0 and game.await_input_release, "tutorial blocks held transition input until release")
	var held = InputEventKey.new()
	held.keycode = KEY_D
	held.physical_keycode = KEY_D
	held.pressed = true
	Input.parse_input_event(held)
	Input.flush_buffered_events()
	game._process(.2)
	check(game.await_input_release and game.x == start_x, "held movement key cannot carry through the final confirmation")
	var released = held.duplicate()
	released.pressed = false
	Input.parse_input_event(released)
	Input.flush_buffered_events()
	game._process(0)
	key(KEY_J)
	check(game.attack_time > 0, "combat becomes available after inputs release")
	for i in 6:
		game._start()
		game._sync_scene()
		p._show_scene(i)
		await next_frame()
		p.finish()
		check(game.state == "play" and game.phase == 0 and not p.active, "skip enters tutorial from panel %d" % i)
	# Replay must preserve run state and persistent bytes from either entry screen.
	for origin in ["menu", "victory"]:
		game.state = origin
		game.show_culture = true
		game.hp = 3
		game.phase = 7 if origin == "victory" else 0
		game.best = 987
		game.checkpoint = {"hp":4,"seconds":21,"hits":2}
		game._save()
		var before = FileAccess.get_file_as_bytes(game.save_path)
		game._action("prologue_replay")
		check(game.state == "prologue" and p.replay, "culture replay opens from " + origin)
		await next_frame()
		p.finish()
		check(game.state == origin and game.show_culture and game.hp == 3 and game.best == 987 and game.checkpoint.hp == 4 and before == FileAccess.get_file_as_bytes(game.save_path), "replay returns without altering run or save: " + origin)
	game._start()
	game._action("pause_click")
	game._action("menu_confirm")
	game._action("menu")
	check(not p.active and not p.voice.playing and game.state == "menu", "return to menu cancels all prologue playback")
	game._start()
	check(p.index == 0 and p.elapsed == 0, "new departure resets the prologue to its beginning")
	game._retry()
	check(game.state == "play" and not p.active, "failed-run retry bypasses prologue")
	p.available = false
	game._start()
	check(game.state == "dialogue" and game.dialogue == game.story.opening and not p.active, "resource failure uses original short opening once")
	game.queue_free()
	await create_timer(.2).timeout
	print("PROLOGUE CHECKS COMPLETE; failures=", failures)
	quit(1 if failures else 0)
