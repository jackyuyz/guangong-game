extends SceneTree
## Real two-swing tutorial damage and authored prop rendering state.
var game: Node
var failures = 0
var checks = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
 checks += 1
 if ok: print("PASS: ",label)
 else:
  failures += 1
  push_error("FAIL: "+label)
func key(code: int) -> void:
 var event=InputEventKey.new()
 event.physical_keycode=code
 event.pressed=true
 game._unhandled_input(event)
func step(seconds: float) -> void:
 for i in ceili(seconds*100): game._process(0.01)
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 game.save_path="/tmp/guangong-training-%d.cfg"%Time.get_ticks_usec()
 # Preserve authored marker positions and transforms, including a relocated ground.
 game.get_node("Level/Ground").position.y=20
 game.get_node("Level/Ground/Training/Dummy").position=Vector2(800,420)
 game.get_node("Level/Ground/Training/Dummy/Visual").position=Vector2(3,-1)
 root.add_child(game)
 game.set_process(false)
 game.muted=true
 game.window_active=true
 game._reset_run()
 game.state="play"
 game.phase=0
 game._sync_scene()
 var flag=game.level.get_node("Ground/Training/Flag")
 var dummy=game.level.get_node("Ground/Training/Dummy")
 var sprite=dummy.get_node("Visual/States")
 check(flag.get_node("Visual") is Sprite2D and sprite is AnimatedSprite2D,"flag and target are real editor-visible artwork nodes")
 check(sprite.sprite_frames.get_frame_count("damage")==3 and not sprite.sprite_frames.get_animation_loop("damage"),"intact, split and broken are three distinct non-looping authored states")
 check(game.level.dummy_hit_origin==Vector2(800,375),"hit effects read relocated authored target marker")
 check(sprite.frame==0 and game.get_meta("dummy_hits")==0,"new run starts with intact target")
 game.x=game.level.flag_origin.x-1
 step(0.01)
 check(game.phase==0,"movement still requires reaching actual flag")
 game.x=game.level.flag_origin.x
 step(0.01)
 check(game.phase==1 and flag.visible,"crossing flag begins attack practice without removing the physical flag")
 game.x=game.level.dummy_origin.x-90
 game.facing=-1
 key(KEY_J)
 step(0.24)
 check(game.get_meta("dummy_hits")==0 and sprite.frame==0,"swinging away cannot damage target")
 step(0.35)
 game.facing=1
 game.x=game.level.dummy_origin.x-170
 key(KEY_J)
 step(0.24)
 check(game.get_meta("dummy_hits")==0,"out-of-range swing cannot damage target")
 step(0.35)
 game.x=game.level.dummy_origin.x-90
 key(KEY_J)
 step(0.04)
 check(game.get_meta("dummy_hits")==0 and sprite.frame==0,"target stays intact during attack windup")
 step(0.05)
 check(game.get_meta("dummy_hits")==1 and game.phase==1 and sprite.frame==1,"first real contact shows split straw while tutorial remains active")
 check(game.ui.get_node("Root/HUD/Controls/Keys").text.contains("1 / 2"),"tutorial feedback reflects actual first-hit count")
 check(not game.particles.is_empty(),"first slash spawns contact particles")
 var pose=dummy.get_node("Visual").transform
 var age: float=dummy.impact_age
 key(KEY_P)
 step(0.4)
 dummy._process(0.4)
 check(dummy.impact_age==age and dummy.get_node("Visual").transform==pose and sprite.frame==1,"pause freezes target state and hit motion")
 key(KEY_P)
 step(0.2)
 dummy._process(0.1)
 check(game.get_meta("dummy_hits")==1 and sprite.frame==1,"one swing cannot count again after pause or later frames")
 game._reset_effects()
 key(KEY_J)
 step(0.09)
 check(game.get_meta("dummy_hits")==2 and game.phase==2 and sprite.frame==2,"second distinct slash breaks target and unlocks dodge practice")
 check(dummy.visible and flag.visible,"both physical props persist after completion")
 game._reset_effects()
 step(0.01)
 key(KEY_J)
 step(0.24)
 check(game.get_meta("dummy_hits")==2 and sprite.frame==2,"further swings cannot overflow or restore broken state")
 game._reset_effects()
 key(KEY_SPACE)
 step(0.01)
 check(game.phase==3 and game.enemies.size()==2 and sprite.frame==2 and dummy.visible,"dodge still starts first wave and leaves grounded debris")
 game.state="dead"
 game._action("retry")
 game._sync_scene()
 check(game.phase==3 and sprite.frame==2 and game.get_meta("dummy_hits")==2,"first-wave retry preserves completed practice and broken target")
 game.reduced_motion=true
 game._reset_run()
 game.state="play"
 game.phase=1
 game.x=game.level.dummy_origin.x-90
 game._sync_scene()
 check(sprite.frame==0 and dummy.impact_age>=dummy.IMPACT_TIME,"new run resets damage and old shake")
 key(KEY_J)
 step(0.09)
 check(sprite.frame==1 and dummy.get_node("Visual").position==Vector2(3,-1),"reduced motion keeps damage progression at authored transform")
 game._pause_for_focus_loss()
 step(0.4)
 check(sprite.frame==1,"focus loss cannot change target damage")
 for i in 3:
  game.set_meta("dummy_hits",i)
  game._sync_scene()
  var tex=sprite.sprite_frames.get_frame_texture("damage",i)
  check(is_equal_approx(sprite.offset.y+float(tex.get_meta("ground_baseline")),0) and is_equal_approx(sprite.offset.x+float(tex.get_meta("ground_anchor_x")),0),"state %d keeps ground and post anchor aligned"%i)
 var font: Font=game.ui.get_node("Root/HUD/Controls/Keys").get_theme_font("font")
 var covered=true
 for character in "练习挥刀": covered=covered and font.has_char(character.unicode_at(0))
 check(covered,"updated practice instruction has all required glyphs")
 check(not FileAccess.file_exists(game.save_path),"practice checks never write progress or player saves")
 print("TRAINING PROP CHECKS: ",checks,"; failures: ",failures)
 game.queue_free()
 await process_frame
 quit(1 if failures else 0)
