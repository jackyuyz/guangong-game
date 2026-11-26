extends SceneTree
var game: Node
var failures = 0
var checks = 0

func _initialize() -> void: call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)

func key(code: int) -> void:
	var event = InputEventKey.new()
	event.physical_keycode = code
	event.pressed = true
	game._unhandled_input(event)

func step(seconds: float) -> void:
	for i in ceili(seconds * 100): game._process(.01)

func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	game.save_path = "/tmp/guangong-tea-rest-%d.cfg" % Time.get_ticks_usec()
	game.get_node("Level/Ground/RestPoint").position = Vector2(2010, 386)
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.window_active = true
	game._reset_run()
	game.state = "play"
	game.phase = 3
	game.x = game.rest_x
	var stall = game.level.get_node("Ground/RestPoint")
	var recovery = game.level.get_node("Ground/RestRecovery")
	var hud = game.ui.get_node("Root/HUD")
	game._sync_scene()
	check(stall.get_node("Artwork") is Sprite2D and game.level.rest_origin == Vector2(2010,386), "real stall artwork and interaction follow the editor placement")
	check(stall.visible and not stall.get_node("Hint").visible, "stall exists before rest is available without offering an invalid action")
	game.phase = 4
	game._spawn(Vector2(game.rest_x-300,game.player_y), game.level.wave_two[0])
	game._sync_scene()
	check(not stall.get_node("Hint").visible and not game.ext.can_rest(game), "guards block both the E prompt and recovery")
	game.enemies.clear()
	game.x = game.rest_x + 100
	game._sync_scene()
	check(not stall.get_node("Hint").visible and not game.ext.can_rest(game), "distant stall has no floating interaction label")
	game.x = game.rest_x - 40
	game.hp = 3
	game.ext.resource = 1
	game._sync_scene()
	check(stall.get_node("Hint").visible and stall.get_node("Hint/Key").visible, "nearby clear road exposes a small native E keycap")
	game.attack_time = .1
	check(not game.ext.can_rest(game), "ongoing swings cannot enter the rest pose")
	game.attack_time = 0
	game.invincible = .6
	game.ext.guard_timer = .3
	game.muted = false
	key(KEY_E)
	game._sync_scene()
	check(game.hp == 4 and game.ext.resource == 4 and game.ext.rest_used, "E applies one health and full qi once")
	check(game.ext.rest_hp_before == 3 and game.ext.rest_qi_before == 1, "feedback remembers actual recovered amounts")
	check(stall.get_node("Sip").playing and not stall.get_node("Sip").stream_paused, "successful recovery starts the short tea sound")
	check(game.ext.guard_timer == 0 and game.level.player.sprite.animation == &"idle" and game.level.player.sprite.modulate.a == 1, "rest uses a calm idle pose without guard or hurt blinking")
	step(.2)
	check(recovery.visible and recovery.strength > 0 and hud.get_node("Health/RestGain").visible, "rest draws the actor outline and only the recovered health segment")
	check(is_equal_approx(hud.get_node("Health/RestGain").size.x, hud.get_node("Health/HP").size.x / 6), "health highlight covers exactly one gained point")
	check(hud.get_node("RestNotice").visible and hud.get_node("RestNotice/Text").text.contains("气血回复"), "short confirmation states the actual recovery")
	var actor = game.level.player.sprite
	check(recovery.get_node("Silhouette").texture == actor.sprite_frames.get_frame_texture(actor.animation,actor.frame) and recovery.get_node("Silhouette").global_transform.is_equal_approx(actor.global_transform), "outline follows the real current frame and authored actor transform")
	game.facing = -1
	game._sync_scene()
	check(recovery.get_node("Silhouette").flip_h == actor.flip_h, "recovery outline mirrors with the character")
	var held_age: float = game.ext.rest_feedback
	var held_notice: float = game.ext.rest_notice
	var held_x: float = game.x
	key(KEY_SPACE)
	key(KEY_J)
	key(KEY_E)
	check(game.dodge_time == 0 and game.attack_time == 0 and game.hp == 4 and game.ext.rest_feedback == held_age, "rest consumes attack and dodge and repeated E cannot heal or restart it")
	var first_pip: Color = hud.get_node("Extensions/Pips/Pip2").self_modulate
	key(KEY_P)
	var steam: float = stall.steam_time
	step(.6)
	stall._process(.6)
	check(game.ext.rest_feedback == held_age and game.ext.rest_notice == held_notice and game.x == held_x and stall.steam_time == steam, "pause freezes recovery, notice, position, and steam")
	check(stall.get_node("Sip").stream_paused and hud.get_node("Extensions/Pips/Pip2").self_modulate == first_pip, "pause freezes tea audio and the qi light wave")
	key(KEY_P)
	game._pause_for_focus_loss()
	step(.5)
	check(game.ext.rest_feedback == held_age and stall.get_node("Sip").stream_paused, "focus loss preserves the pending rest")
	game.window_active = true
	game.muted = true
	key(KEY_P)
	step(.25)
	check(game.ext.rest_feedback < held_age and game.ext.rest_feedback > 0, "resuming continues rather than restarting recovery")
	step(.5)
	check(game.ext.rest_feedback == 0 and not recovery.visible and not hud.get_node("Health/RestGain").visible, "glow and health highlight clear after the short pose")
	check(hud.get_node("RestNotice").visible, "confirmation remains briefly after the glow settles")
	step(1)
	check(not hud.get_node("RestNotice").visible and not stall.get_node("Sip").playing, "confirmation fades and audio ends without a persistent overlay")
	check(stall.modulate == Color.WHITE and stall.get_node("Hint/Caption").text == "已歇脚" and not stall.get_node("Hint/Key").visible, "used stall keeps its colors and replaces E with a quiet used label")
	game._reset_run()
	game.state = "play"
	game.phase = 4
	game.x = game.rest_x
	game.hp = 6
	game.reduced_motion = true
	key(KEY_E)
	game._sync_scene()
	check(game.hp == 6 and not hud.get_node("Health/RestGain").visible and hud.get_node("RestNotice/Text").text.contains("气血已满"), "full health gives no false healing highlight or message")
	check(not recovery.visible and game.ext.rest_feedback > 0, "reduced motion suppresses the pulse while retaining the rest timing")
	game.ext.reset()
	game._sync_scene()
	check(not hud.get_node("RestNotice").visible and not recovery.visible and not game.ext.rest_used, "reset clears recovery effects and restores the rest point")
	check(not FileAccess.file_exists(game.save_path), "tea tests never write player progress")
	game.queue_free()
	await create_timer(.25).timeout
	print("TEA REST CHECKS: ", checks, "; failures: ", failures)
	quit(1 if failures else 0)
