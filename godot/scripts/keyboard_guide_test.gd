extends SceneTree
var failures = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
 if ok: print("PASS: ", label)
 else:
  failures += 1
  push_error("FAIL: "+label)
func run() -> void:
 var game=load("res://scenes/main.tscn").instantiate()
 game.save_path="/tmp/guangong-guide-%d.cfg" % Time.get_ticks_usec()
 root.add_child(game)
 game.set_process(false)
 game.muted=true
 var guide=game.ui.get_node("Root/Utility/Body")
 guide.set_process(false)
 game.state="play"
 game._action("help")
 guide.set_demo_state(true,false,true)
 guide._process(.4)
 check(is_equal_approx(guide.get_node("Keys/A/Face").position.y,0), "automatic demo depresses the A key")
 var triple = true
 for time in [2.8,3.35,3.9]:
  guide.clock=time
  guide._process(0)
  triple=triple and is_equal_approx(guide.get_node("Keys/J/Face").position.y,0)
 check(triple, "J demonstrates three separate presses")
 guide.clock=4.35
 guide._process(0)
 check(is_equal_approx(guide.get_node("Keys/J/Face").position.y,-4), "a key rebounds after its press")
 guide.clock=14.6
 guide._process(.4)
 check(is_equal_approx(guide.get_node("Keys/A/Face").position.y,0), "demo loops through the same first key")
 var before: float=guide.clock
 guide.set_demo_state(true,false,false)
 guide._process(3)
 check(guide.clock==before, "unfocused guide freezes its clock")
 guide.set_demo_state(true,true,true)
 guide._process(3)
 var resting=true
 for cap in guide.caps:
  resting=resting and is_equal_approx(cap.get_node("Face").position.y,-4)
 check(resting and guide.clock==before, "reduced motion leaves every key raised and static")
 guide.set_demo_state(false,false,true)
 guide.set_demo_state(true,false,true)
 check(guide.clock==0, "reopening starts the demo from its beginning")
 guide.hide()
 guide._process(2)
 check(guide.clock==0, "hidden guide never advances")
 guide.show()
 var hp: int=game.hp
 var x: float=game.x
 var seconds: float=game.combat_seconds
 for frame in 900: guide._process(1.0/60.0)
 check(game.state=="pause" and game.hp==hp and game.x==x and game.combat_seconds==seconds and game.attack_time==0 and game.dodge_time==0 and not FileAccess.file_exists(game.save_path), "animated keys neither execute gameplay nor write progress")
 guide.set_demo_state(true,false,true,"本次进度未能保存")
 check(guide.get_node("Notice").visible and guide.get_node("Notice").text=="本次进度未能保存", "wide guide retains important save feedback")
 game.queue_free()
 await create_timer(.2).timeout
 print("KEYBOARD GUIDE CHECKS COMPLETE; failures=",failures)
 quit(1 if failures else 0)
