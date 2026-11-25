extends SceneTree
## Real enemy contact -> complete attacker/fall animation -> modal -> isolated retry.
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
 for i in ceili(seconds * 100): game._process(0.01)
func prepare(boss: bool, move: int, direction: float) -> Dictionary:
 game._reset_run()
 game.hp = 4
 game.combat_seconds = 12
 game.hits = 2
 game.ext.resource = 3
 if boss:
  game._enter_boss()
 else:
  game.state = "play"
  game.phase = 3
  game._spawn_wave(1)
 var foe: Dictionary = game.enemies[0]
 game.x = foe.x + direction * 90
 game.facing = -direction
 game.hp = 1
 foe.mode = "windup"
 foe.timer = 0.01
 foe.facing = direction
 foe.move = move
 foe.struck = false
 game._sync_scene()
 return foe
func run() -> void:
 game = load("res://scenes/main.tscn").instantiate()
 game.save_path = "/tmp/guangong-player-defeat-%d.cfg" % Time.get_ticks_usec()
 root.add_child(game)
 game.set_process(false)
 game.muted = true
 for kind in [{"boss":true,"move":1,"direction":-1.0}, {"boss":true,"move":2,"direction":1.0}, {"boss":false,"move":1,"direction":-1.0}]:
  var label = ("boss thrust" if kind.move == 1 else "boss sweep") if kind.boss else "guard"
  var foe = prepare(kind.boss, kind.move, kind.direction)
  step(0.05)
  check(game.hp == 1 and game.state == "play" and foe.view.sprite.frame == 0, label + " starts real first attack frame without premature damage")
  step(0.05)
  check(game.hp == 0 and game.hits == 3 and game.state == "dying", label + " lethal contact locks defeat on second attack frame")
  check(foe.view.sprite.animation == &"attack" and foe.view.sprite.frame == 1 and game.level.player.sprite.animation == &"fall", label + " shows impact and actual fall together")
  check(game.ui.get_node("Root/HUD").visible and not game.ui.get_node("Root/Defeat").visible and game.ui.get_node("Root/HUD/Health/HP").value == 0, label + " shows zero health before retry modal")
  check(not foe.view.get_node("Telegraph").visible and not foe.combo_pending, label + " cancels warnings and subsequent combo")
  var seconds: float = game.combat_seconds
  var at_x: float = game.x
  var elapsed: float = game.death_elapsed
  var attack_timer: float = foe.timer
  var frame: int = game.level.player.sprite.frame
  for code in [KEY_J, KEY_K, KEY_L, KEY_SPACE, KEY_ENTER]: key(code)
  game._action("skip")
  game._action("retry")
  game._action("restart")
  game._hurt(kind.direction, foe)
  check(game.state == "dying" and game.hp == 0 and game.hits == 3 and game.retries == 0 and game.x == at_x, label + " ignores combat and premature retry input")
  key(KEY_P)
  step(0.4)
  await create_timer(0.1).timeout
  check(game.state == "pause" and game.resume_state == "dying" and game.death_elapsed == elapsed and foe.timer == attack_timer and game.level.player.sprite.frame == frame, label + " pause freezes body and attacker timelines")
  game._action("map_confirm")
  step(0.2)
  game._action("cancel")
  game._action("resume")
  game._pause_for_focus_loss()
  step(0.2)
  check(game.state == "pause" and game.death_elapsed == elapsed, label + " cancelled exit and focus loss preserve exact pose")
  game.window_active = true
  game._action("resume")
  step(0.18)
  check(game.state == "dying" and foe.mode == "strike" and foe.view.sprite.frame == 2, label + " plays the remaining attack frame after lethal damage")
  step(0.15)
  check(game.state == "dying" and foe.mode == "recover", label + " follows through into recovery")
  if kind.boss:
   check(foe.view.sprite.animation == &"finish_recover", label + " uses independent spear recovery frames")
  step(0.8)
  check(game.state == "dying" and game.level.player.sprite.frame == 7 and not game.ui.get_node("Root/Defeat").visible, label + " holds settled body before modal")
  step(0.5)
  check(game.state == "dead" and game.ui.get_node("Root/Defeat").visible and foe.view.sprite.animation == &"idle", label + " waits for both full animations before failure")
  check(game.combat_seconds == seconds and game.hits == 3 and not game.progress.is_cleared("dongling") and not FileAccess.file_exists(game.save_path), label + " cannot add damage, time, completion or save writes during defeat")
  key(KEY_ENTER)
  game._sync_scene()
  check(game.state == "play" and not game.player_fallen and game.death_attacker.is_empty() and game.retries == 1 and game.level.player.sprite.animation != &"fall", label + " retry clears corpse and resumes live actors")
  if kind.boss:
   check(game.hp == 4 and game.hits == 2 and game.combat_seconds == 12 and game.ext.resource == 3 and game.enemies[0].hp == 16, label + " retry restores original checkpoint stats and qi")
  else:
   check(game.hp == 6 and game.hits == 0 and game.combat_seconds == 0 and game.phase == 3 and game.enemies.size() == 2, "guard defeat retries first wave with fresh attempt stats")
 game.reduced_motion = true
 var foe = prepare(true, 2, -1.0)
 step(0.3)
 check(game.state == "dying" and game.level.get_node("Camera").offset.x == game.level.camera_offset.x, "reduced motion keeps the fall without shake")
 step(2)
 check(game.state == "dead" and game.level.player.sprite.frame == 7, "reduced motion completes all death frames")
 game._action("menu")
 check(game.state == "menu" and not game.player_fallen and game.death_elapsed == 0, "returning to menu clears defeat state")
 game.reduced_motion = false
 prepare(true, 1, -1)
 game.attack_time = game.ATTACK_TIME
 game.ext.heavy_time = 0.2
 game.ext.heavy_pending = true
 game._hurt(-1, foe)
 check(game.state == "dying" and game.attack_time == 0 and game.ext.heavy_time == 0 and not game.ext.heavy_pending, "death cancels unfinished player swings and pending heavy damage")
 game._reset_run()
 game.state = "play"
 game.hp = 1
 game._hurt(-1)
 step(2)
 check(game.state == "dead" and game.level.player.sprite.frame == 7, "defeat without attacker still completes safely")
 for direction in [-1.0, 1.0]:
  var actor = game.level.player
  actor.pose(direction)
  var aligned = true
  for i in 8:
   actor.sprite.animation = &"fall"
   actor.sprite.frame = i
   actor._align_frame()
   var texture = actor.sprite.sprite_frames.get_frame_texture("fall",i)
   aligned = aligned and is_equal_approx(float(texture.get_meta("ground_baseline")) + actor.sprite.offset.y, actor.frame_baselines[0] + actor.original_offset.y)
  check(aligned, "fall maintains ground baseline facing " + str(direction))
 print("PLAYER DEFEAT CHECKS: ", checks, "; failures: ",failures)
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)
