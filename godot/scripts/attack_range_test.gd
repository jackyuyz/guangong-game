extends SceneTree
## Integrates the visual envelope with unchanged real enemy updates and authored scale.
var game: Node
var checks = 0
var failures = 0
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
 checks += 1
 if ok: print("PASS: ",label)
 else:
  failures += 1
  push_error("FAIL: "+label)
func setup() -> Dictionary:
 game._reset_run()
 game._enter_boss()
 game._sync_scene()
 return game.enemies[0]
func interval(tell: Node2D) -> Vector2:
 var start: float=game.level.to_local(tell.to_global(Vector2.ZERO)).x
 var end: float=game.level.to_local(tell.to_global(Vector2(190,0))).x
 return Vector2(minf(start,end),maxf(start,end))
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 game.save_path="/tmp/guangong-range-test-%d.cfg"%Time.get_ticks_usec()
 root.add_child(game)
 game.set_process(false)
 game.muted=true
 var tell:Node2D=game.level.boss.get_node("Telegraph")
 var initial_scale:Vector2=game.level.boss.scale
 for boss in [false,true]:
  for direction in [-1.0,1.0]:
   for move in [1,2]:
    for factor in [1.0,1.3]:
     var e=setup()
     e.boss=boss
     e.move=move
     e.x=(game._clamp_player_x(-1e20)+game._clamp_player_x(1e20))*0.5
     e.facing=direction
     e.mode="windup"
     e.timer=0.65
     game.x=e.x+direction*((190 if boss else 120)-10+(80 if boss and move==1 else 0))
     game.level.boss.scale=initial_scale*factor
     game._sync_scene()
     var promised=interval(tell)
     var hp:int=game.hp
     var all_covered=true
     e.mode="strike"
     e.timer=0.24
     for i in 7:
      var previous_hits:int=game.hits
      var target:float=game.x
      game._update_enemy(e,0.037)
      game._sync_scene()
      if game.hits>previous_hits: all_covered=all_covered and target>=promised.x and target<=promised.y
     check(game.hp==hp-1 and all_covered,"real contact inside visible distance: boss=%s facing=%s move=%s scale=%s"%[boss,direction,move,factor])
     game.level.boss.scale=initial_scale
 var e=setup()
 e.move=1
 e.mode="windup"
 e.timer=0.65
 game._sync_scene()
 var first:Vector2=interval(tell)
 var initial_timing:float=tell.get_node("Timing").position.x
 e.timer=0.16
 game._sync_scene()
 check(tell.get_node("Timing").position.x>initial_timing and interval(tell).is_equal_approx(first),"windup progress fills a fixed whole attack range")
 var fill:float=tell.get_node("Thrust/Charge").scale.x
 game.state="pause"
 game.resume_state="play"
 for i in 10:game._process(0.04)
 check(tell.get_node("Thrust/Charge").scale.x==fill and e.timer==0.16,"pause freezes the range fill and release marker")
 game._action("resume")
 game._pause_for_focus_loss()
 for i in 10:game._process(0.04)
 check(tell.get_node("Thrust/Charge").scale.x==fill,"focus loss freezes ground feedback")
 game.window_active=true
 game._action("resume")
 e.mode="recover"
 game._sync_scene()
 check(not tell.visible,"recovery removes danger feedback")
 game._retry()
 game._sync_scene()
 check(not tell.visible,"retry clears the previous lunge envelope")
 print("ATTACK RANGE CHECKS: ",checks,"; failures: ",failures)
 game.queue_free()
 await process_frame
 await create_timer(0.25).timeout
 quit(1 if failures else 0)
