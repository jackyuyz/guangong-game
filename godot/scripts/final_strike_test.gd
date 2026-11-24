extends SceneTree
## End-to-end lethal contact, animation ordering and modal regression checks.
var game: Node
var failures = 0
var checks = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
 checks += 1
 if not ok:
  failures += 1
  push_error("FAIL: " + label)
 else: print("PASS: ", label)
func key(code: int) -> void:
 var event = InputEventKey.new()
 event.physical_keycode = code
 event.pressed = true
 game._unhandled_input(event)
func step(seconds: float) -> void:
 for i in ceili(seconds * 100): game._process(0.01)
func boss_ready(heavy: bool = false) -> Dictionary:
 game._reset_run()
 game._enter_boss()
 game.x = game.enemies[0].x - 100
 game.facing = 1
 game.hp = 1
 game.combat_seconds = 42
 game.hits = 3
 game.ext.resource = 4 if heavy else 0
 var boss: Dictionary = game.enemies[0]
 boss.hp = 3 if heavy else 1
 boss.mode = "windup"
 boss.timer = 99.0
 game._sync_scene()
 return boss
func run() -> void:
 game = load("res://scenes/main.tscn").instantiate()
 game.save_path = "/tmp/guangong-final-strike-%d.cfg" % Time.get_ticks_usec()
 root.add_child(game)
 game.set_process(false)
 game.muted = true
 for heavy in [false, true]:
  var label = "L" if heavy else "J"
  var boss = boss_ready(heavy)
  var starting_hp: int = boss.hp
  key(KEY_L if heavy else KEY_J)
  game._process(0.04)
  check(boss.hp == starting_hp and game.state == "play", label + " has a visible windup before contact")
  check(game.level.player.sprite.frame == 0, label + " windup stays on first frame")
  # The opponent would strike this same tick: lethal contact must win priority.
  if heavy: game._process(0.04)
  boss.mode = "strike"
  boss.struck = false
  boss.timer = 1.0
  game.invincible = 0.0
  game._process(0.04)
  check(game.state == "finishing" and game.phase == 7 and game.hp == 1 and game.hits == 3, label + " lethal contact locks victory before enemy damage")
  check(game.level.player.sprite.animation == (&"heavy" if heavy else &"attack") and game.level.player.sprite.frame == 1, label + " lethal contact is second attack frame")
  check(game.cleared and game.progress.is_cleared("dongling") and not game.defeated_boss.is_empty(), label + " locks progress but retains defeated actor")
  check(game.ui.get_node("Root/HUD").visible and game.ui.get_node("Root/HUD/BossHealth/HP").value == 0 and not game.level.get_node("Ground/RetreatGuards").visible, label + " holds empty boss bar without premature retreat")
  var elapsed: float = game.finish_elapsed
  var seconds: float = game.combat_seconds
  var finish_score: int = game.score
  var last_x: float = game.x
  var saved = FileAccess.get_file_as_bytes(game.save_path)
  game._win()
  game._hurt(-1)
  for code in [KEY_J, KEY_L, KEY_K, KEY_SPACE, KEY_ENTER]: key(code)
  game._action("skip")
  game._action("next")
  check(game.state == "finishing" and game.x == last_x and game.hp == 1 and game.finish_elapsed == elapsed, label + " ignores repeated win and stale combat/dialogue input")
  key(KEY_P)
  step(0.4)
  check(game.state == "pause" and game.resume_state == "finishing" and game.finish_elapsed == elapsed, label + " pause freezes finish timeline")
  game._action("map_confirm")
  step(0.2)
  game._action("cancel")
  game._action("resume")
  game._pause_for_focus_loss()
  step(0.2)
  check(game.state == "pause" and game.finish_elapsed == elapsed, label + " focus loss and cancelled exit preserve finish")
  game.window_active = true
  game._action("resume")
  step(0.2)
  check(game.state == "finishing" and game.level.boss.visible and game.level.boss.sprite.frame <= 1, label + " resumes stagger without popup")
  step(0.4)
  check(game.state == "finishing" and game.level.player.sprite.animation in [&"finish_recover", &"idle"] and game.level.boss.sprite.frame >= 3, label + " recovery overlaps actual fall poses")
  step(0.55)
  check(game.state == "finishing" and game.level.boss.sprite.frame == 7 and not game.ui.get_node("Root/Dialogue").visible, label + " final lying pose holds before ending")
  step(0.6)
  check(game.state == "dialogue" and game.dialogue == game.story.ending and game.level.player.sprite.animation == &"idle" and game.level.boss.sprite.frame == 7, label + " ending waits for full recovery, fall and hold")
  check(game.combat_seconds == seconds and game.score == finish_score and game.hits == 3 and saved == FileAccess.get_file_as_bytes(game.save_path), label + " finish cannot change stats or write duplicate progress")
  check(not game.level.boss.get_node("Telegraph").visible and not game.level.boss.get_node("AttackHint").visible and game.ext.heavy_time == 0, label + " corpse has no attack warning or lingering slash")
  game._action("skip")
  check(game.state == "victory" and game.show_culture, label + " ending then leads to culture and settlement")
 game.reduced_motion = true
 boss_ready()
 key(KEY_J)
 step(0.2)
 check(game.state == "finishing" and game.level.get_node("Camera").offset.x == game.level.camera_offset.x, "reduced motion retains death animation without shake")
 step(2)
 check(game.state == "dialogue" and game.level.boss.sprite.frame == 7, "reduced motion still completes the entire finish")
 game._retry()
 game._sync_scene()
 check(game.defeated_boss.is_empty() and game.state == "play" and game.enemies[0].hp == 16 and game.level.boss.sprite.animation != &"fall", "checkpoint retry clears corpse and restores live boss")
 game._reset_run()
 check(game.defeated_boss.is_empty() and game.finish_elapsed == 0 and not game.ext.heavy_pending, "new run clears all finish state")
 for actor in [game.level.player, game.level.boss]:
  var animation = "fall" if actor == game.level.boss else "finish_recover"
  check(not actor.sprite.sprite_frames.get_animation_loop(animation) and actor.sprite.sprite_frames.get_frame_count(animation) == 8, animation + " is a real eight-frame non-looping animation")
  for direction in [-1.0, 1.0]:
   actor.pose(direction)
   var aligned = true
   for i in 8:
    actor.sprite.animation = animation
    actor.sprite.frame = i
    actor._align_frame()
    var texture = actor.sprite.sprite_frames.get_frame_texture(animation, i)
    aligned = aligned and is_equal_approx(float(texture.get_meta("ground_baseline")) + actor.sprite.offset.y, actor.frame_baselines[0] + actor.original_offset.y)
   check(aligned, animation + " keeps authored ground baseline facing " + str(direction))
 print("FINAL STRIKE CHECKS: ", checks, "; failures: ", failures)
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)
