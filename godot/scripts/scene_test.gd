extends SceneTree
## Checks the editor-authored scene and its connection to the existing game.
var failures = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, description: String) -> void:
	if condition:
		print("PASS: ", description)
	else:
		push_error("FAIL: " + description)
		failures += 1

func mouse_button(at: Vector2, down: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
	event.pressed = down
	event.position = at
	event.global_position = at
	root.push_input(event, true)

func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	check(game.has_node("Level/Ground/Player/Visual/Sprite"), "player sprite exists before scene enters tree")
	check(game.has_node("Level/Backdrop"), "background is an authored node")
	check(game.has_node("UI/Root/HUD/Health/HP"), "HUD is an authored Control hierarchy")
	check(game.has_node("UI/Root/MainMenu/Start"), "menu has a native Button before runtime")
	if failures > 0:
		game.free()
		quit(1)
		return
	var sprite: AnimatedSprite2D = game.get_node("Level/Ground/Player/Visual/Sprite")
	check(sprite.sprite_frames != null and sprite.sprite_frames.get_frame_count("walk") == 4 and sprite.sprite_frames.get_frame_count("attack") == 3, "player artwork previews without running scripts")
	check(game.get_node("Level/Backdrop").texture != null, "background artwork previews without running scripts")
	check(game.get_node("UI/Root/HUD").visible, "game HUD previews in editor")
	var cursor_grip: Node2D = game.get_node("UI/BladeCursor/Grip")
	var cursor_blade: Sprite2D = cursor_grip.get_node("Blade")
	var cursor_arc: Line2D = game.get_node("UI/BladeCursor/Arc")
	var cursor_rest_rotation := cursor_blade.rotation
	var tip_in_blade := Vector2(83.5, 8.5) + cursor_blade.offset
	var resting_tip := cursor_grip.transform * (cursor_blade.transform * tip_in_blade)
	check(not cursor_blade.flip_h and is_equal_approx(cursor_rest_rotation, -PI / 2.0) and resting_tip.is_zero_approx() and cursor_blade.is_pixel_opaque(tip_in_blade), "left-facing blade tip aligns with the mouse at rest")
	check(cursor_blade.scale.is_equal_approx(Vector2(0.65, 0.65)), "blade cursor uses the enlarged scale")
	# Author edits before ready must become the starting positions/layout at runtime.
	game.get_node("Level/Ground").position.y = 20
	game.get_node("Level/Ground/Player").position.x = 355
	game.get_node("Level/Ground/Guards/WaveOne/Guard1").position.x = 1175
	game.get_node("Level/Ground/Training/Flag").position.x = 510
	game.get_node("Level/Ground/Training/Dummy").position = Vector2(800, 420)
	game.get_node("Level/Ground/RestPoint").position.x = 1900
	game.get_node("Level/Ground/Guards/WaveTwo").position.x = 40
	var second_guard = game.get_node("Level/Ground/Guards/WaveTwo/Guard2")
	second_guard.scale = Vector2(1.2, 1.2)
	game.get_node("UI/Root/HUD/Health").position = Vector2(25, 22)
	game.save_path = "/tmp/guangong-scene-test-progress.cfg"
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game._sync_scene()
	check(game.get_node("UI/Root/MainMenu").visible, "runtime starts with menu")
	var start_button: Button = game.get_node("UI/Root/MainMenu/Start")
	var start_position := start_button.get_global_rect().get_center()
	var backdrop_position := Vector2(850, 240)
	mouse_button(backdrop_position, true)
	mouse_button(backdrop_position, false)
	check(game.state == "menu" and is_zero_approx(cursor_grip.rotation), "background click does not animate the blade or start the game")
	mouse_button(start_position, true)
	var cursor_swing: Tween = game.get_node("UI/BladeCursor")._swing
	check(game.state == "menu" and cursor_swing != null, "left button press starts the slash before native button release")
	cursor_swing.pause()
	var grip_position := cursor_grip.position
	cursor_swing.custom_step(0.035)
	var raised_tip := cursor_grip.transform * (cursor_blade.transform * tip_in_blade)
	check(raised_tip.y < resting_tip.y - 5.0, "windup lifts the blade head")
	cursor_swing.custom_step(0.065)
	var lowered_tip := cursor_grip.transform * (cursor_blade.transform * tip_in_blade)
	check(cursor_grip.position.is_equal_approx(grip_position) and lowered_tip.y > resting_tip.y + 20.0 and lowered_tip.x < resting_tip.x, "downstroke moves the head down and left around a fixed handle grip")
	check(cursor_arc.get_point_count() == 9 and (cursor_arc.position + cursor_arc.get_point_position(8)).is_equal_approx(lowered_tip), "slash trail follows the moving blade tip")
	mouse_button(start_position, false)
	game._sync_scene()
	check(game.state == "prologue" and game.x == 355 and game.player_y == 460, "native start button uses authored player spawn")
	cursor_swing.custom_step(0.11)
	check(is_zero_approx(cursor_grip.rotation) and is_zero_approx(cursor_arc.self_modulate.a), "blade and arc settle after a click across a screen transition")
	await process_frame
	await process_frame
	game.get_node("UI/Root/Prologue/Skip").pressed.emit()
	game._sync_scene()
	check(game.state == "play", "native skip button enters tutorial")
	game.x = 460
	game._update_play(0.01)
	check(game.phase == 0, "flag trigger moves with the authored flag")
	game.x = 510
	game._update_play(0.01)
	check(game.phase == 1, "crossing the relocated flag advances the tutorial")
	game.x = 780
	game.attack_time = 0.22
	game.swing_id += 1
	game._update_play(0.01)
	check(game.get_meta("dummy_hits") == 1 and not game.particles.is_empty() and game.particles[0].pos == Vector2(800, 385), "target hit and sparks follow the relocated dummy")
	game._reset_effects()
	game.dodge_time = 0.3
	game._sync_scene()
	sprite.set_frame_and_progress(1, 0.5)
	game.muted = false
	game._tone(440, 1.0, 0.1)
	game.get_node("UI/Root/HUD/Pause").pressed.emit()
	game._sync_scene()
	check(game.state == "pause" and game.get_node("UI/Root/Pause").visible, "pause button opens modal")
	await create_timer(0.2).timeout
	check(sprite.animation == &"walk" and sprite.frame == 1 and is_equal_approx(sprite.frame_progress, 0.5), "pause freezes the current animation frame and progress")
	check(game.tone_player.stream_paused, "pause silences the in-flight sound")
	check(game.get_node("UI/Root/Pause/Dimmer").mouse_filter == Control.MOUSE_FILTER_STOP, "modal dimmer captures pointer events")
	game.get_node("UI/Root/Pause/Resume").pressed.emit()
	game._sync_scene()
	await create_timer(0.2).timeout
	check(sprite.frame != 1 and not game.tone_player.stream_paused, "resuming advances animation and audio")
	game.muted = true
	game.phase = 2
	game.dodge_time = 0.2
	game._update_play(0.01)
	game._sync_scene()
	check(game.enemies.size() == 2 and game.enemies[0].x > 1170, "first wave comes from authored guard positions")
	var guard = game.get_node("Level/Ground/Guards/WaveOne/Guard1")
	check(guard.visible and is_equal_approx(guard.position.x, game.enemies[0].x), "enemy presentation tracks combat position")
	game.enemies[0].mode = "windup"
	game.enemies[0].facing = -1.0
	game.enemies[0].hp = 1
	game.hp = 3
	game._sync_scene()
	check(guard.get_node("Telegraph").visible and guard.get_node("AttackHint").visible, "windup shows real warning nodes")
	check(guard.get_node("Health").value == 1 and game.get_node("UI/Root/HUD/Health/HP").value == 3, "health nodes track combat values")
	check(game.get_node("UI/Root/HUD/Health").position == Vector2(25, 22), "view syncing preserves authored UI layout")
	game.enemies.clear()
	game._sync_scene()
	check(not guard.visible, "removed enemies disappear")
	game._update_play(0.01)
	game._sync_scene()
	check(game.phase == 4 and second_guard.visible and not guard.visible, "second wave uses its own authored actor nodes")
	check(second_guard.scale == Vector2(1.2, 1.2) and absf(game.enemies[1].x - 1970) < 3, "wave spawn includes the parent transform and preserves the actor scale")
	game.enemies[0].hp = 0
	game._update_play(0.01)
	game._sync_scene()
	check(second_guard.visible and absf(second_guard.global_position.x - float(game.enemies[0].x)) < 0.01, "removing a guard keeps its surviving neighbor bound to the same actor")
	game.enemies.clear()
	game.x = 1900
	check(game.ext.can_rest(game), "rest interaction follows the relocated tea stall")
	game._enter_boss()
	game._sync_scene()
	check(game.get_node("Level/Ground/Boss").visible and game.level.boss.global_position.y == 460 and game.get_node("UI/Root/HUD/BossHealth").visible, "boss and boss HUD appear together")
	game.enemies[0].mode = "windup"
	game._retry()
	game._sync_scene()
	check(not game.get_node("Level/Ground/Boss/Telegraph").visible, "retry clears boss warning")
	game.state = "menu"
	game.show_culture = true
	game._sync_scene()
	check(game.get_node("UI/Root/Culture").visible, "culture is a native modal")
	mouse_button(start_position, true)
	mouse_button(start_position, false)
	check(game.state == "menu" and game.show_culture and is_zero_approx(cursor_grip.rotation), "culture modal blocks clicks and slash feedback on the underlying start button")
	game.get_node("UI/Root/Culture/Close").pressed.emit()
	check(not game.show_culture, "culture close button returns to underlying screen")
	game.queue_free()
	await create_timer(0.15).timeout
	print("SCENE CHECKS COMPLETE; failures=", failures)
	quit(1 if failures else 0)
