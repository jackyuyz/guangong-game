extends SceneTree
## Modal recovery and progressive disclosure use a disposable save.
var failures = 0
var game: Node
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
 if ok: print("PASS: ", label)
 else:
  failures += 1
  push_error("FAIL: "+label)
func frames() -> void:
 await process_frame
 await process_frame
func key(code: int) -> void:
 var event=InputEventKey.new()
 event.physical_keycode=code
 event.keycode=code
 event.pressed=true
 game._unhandled_input(event)
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 game.save_path="/tmp/guangong-ui-flow-%d.cfg" % Time.get_ticks_usec()
 root.add_child(game)
 game.set_process(false)
 game.muted=true
 var ui=game.ui
 var map=game.journey
 map.set_process(false)
 ui.get_node("Root/MainMenu/Mute").grab_focus()
 game._action("settings")
 check(game.utility_panel=="settings" and ui.get_node("Root/Utility").visible, "menu settings opens without starting a journey")
 check(get_root().gui_get_focus_owner()==ui.get_node("Root/Utility/Settings").selected_sound(), "settings focus enters its first control")
 var navigation=InputEventKey.new()
 navigation.keycode=KEY_TAB
 navigation.physical_keycode=KEY_TAB
 navigation.pressed=true
 navigation.shift_pressed=true
 ui._input(navigation)
 check(get_root().gui_get_focus_owner()==ui.get_node("Root/Utility/Settings/Close"), "backward Tab wraps inside settings instead of reaching covered controls")
 navigation.shift_pressed=false
 navigation.keycode=KEY_DOWN
 navigation.physical_keycode=KEY_DOWN
 ui._input(navigation)
 check(get_root().gui_get_focus_owner()==ui.get_node("Root/Utility/Settings").selected_sound(), "arrow navigation stays inside settings")
 game._action("start")
 key(KEY_ENTER)
 check(game.state=="menu" and game.progress.intro_state()=="unseen", "settings blocks start button actions and Enter behind modal")
 game._action("motion")
 check(game.reduced_motion and game.progress.reduced_motion(), "motion preference still saves through shared settings")
 game._action("help")
 check(game.utility_panel=="help" and ui.get_node("Root/Utility/Body").visible, "settings exposes the full keyboard guide")
 key(KEY_ESCAPE)
 check(game.utility_panel.is_empty() and game.state=="menu" and get_root().gui_get_focus_owner()==ui.get_node("Root/MainMenu/Mute"), "Esc closes help and restores menu focus without departure")
 game._return_to_map()
 map._process(0)
 map.select_chapter(1)
 var position: Vector2=map.get_node("ScrollClip/Caravan").position
 game._action("settings")
 check(map.suspended, "settings pauses map motion")
 game._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
 check(map.suspended, "returning window focus cannot resume a covered map")
 game._enter_chapter("dongling")
 check(game.state=="map" and map.selected==1, "direct chapter entry remains blocked by settings")
 game._action("utility_close")
 check(map.selected==1 and map.get_node("ScrollClip/Caravan").position==position and not map.suspended, "closing map settings restores selection and actual position")
 check(not map.get_node("ScrollClip/Details/Start").visible and map.get_node("ScrollClip/Details/Reason").text.contains("通关东岭关后开启"), "second chapter prerequisite uses one actionable reason without a redundant button")
 map.select_chapter(0)
 map._process(0)
 await frames()
 game._enter_chapter("dongling")
 game._process(0)
 var mute_center: Vector2=ui.get_node("Root/HUD/Mute").get_global_rect().get_center()
 for pressed in [true,false]:
  var click=InputEventMouseButton.new()
  click.button_index=MOUSE_BUTTON_LEFT
  click.pressed=pressed
  click.position=mute_center
  click.global_position=mute_center
  root.push_input(click,true)
 await frames()
 var dodge=InputEventKey.new()
 dodge.physical_keycode=KEY_SPACE
 dodge.keycode=KEY_SPACE
 dodge.pressed=true
 root.push_input(dodge,true)
 dodge=dodge.duplicate()
 dodge.pressed=false
 root.push_input(dodge,true)
 game.muted=true
 check(game.dodge_time>0 and game.state=="play", "clicking HUD sound never steals Space from the dodge action")
 game.dodge_time=0
 game.dodge_cooldown=0
 game._action("help")
 var time: float=game.combat_seconds
 var x: float=game.x
 key(KEY_J)
 key(KEY_SPACE)
 game._process(.5)
 check(game.state=="pause" and game.utility_panel=="help" and game.combat_seconds==time and game.x==x and game.attack_time==0, "opening help from combat pauses time and blocks attacks")
 game._action("utility_close")
 check(game.state=="pause", "closing combat guide leaves a deliberate resume step")
 game._action("resume")
 check(game.state=="play" and game.phase==0, "resuming guide preserves the current tutorial")
 game.phase=3
 game._sync_scene()
 ui.get_node("Root/HUD")._process(0.3)
 check(not ui.get_node("Root/HUD/Controls/Hint").visible, "completed basic tutorial removes the persistent keyboard strip")
 game._return_to_map()
 game._action("map_replay")
 var prologue=game.prologue
 prologue.set_process(false)
 var picture_time: float=prologue.animation.current_animation_position
 prologue._process(.3)
 check(prologue.elapsed>0 and prologue.animation.current_animation_position==picture_time and not prologue.get_node("Transition").visible, "reduced motion holds the picture while narration timing continues")
 game.reduced_motion=false
 game._sync_scene()
 await frames()
 prologue.toggle_more()
 var elapsed: float=prologue.elapsed
 picture_time=prologue.animation.current_animation_position
 prologue._process(.3)
 check(prologue.more_open and not prologue.voice.stream_paused and not prologue.ambience.stream_paused and not prologue.effect.stream_paused and prologue.elapsed>elapsed and prologue.animation.current_animation_position>picture_time, "more menu keeps narration, ambience and scene animation playing")
 await frames()
 prologue.replay_current()
 check(not prologue.more_open and not prologue.voice.stream_paused and prologue.elapsed==0, "relisten closes menu and restarts current narration")
 prologue._process(.25)
 check(prologue.elapsed>0 and not prologue.voice.stream_paused, "relisten continues playing without an extra resume action")
 await frames()
 prologue.toggle_auto()
 await frames()
 prologue.toggle_more()
 elapsed=prologue.elapsed
 prologue._process(.3)
 check(prologue.more_open and prologue.elapsed==elapsed and prologue.voice.stream_paused, "more menu preserves an explicit playback pause")
 var escape=InputEventKey.new()
 escape.physical_keycode=KEY_ESCAPE
 escape.pressed=true
 prologue._input(escape)
 check(not prologue.more_open and not prologue.auto_play and prologue.voice.stream_paused and game.state=="prologue", "Esc closes more without pausing the screen or resuming manual narration")
 await frames()
 prologue.toggle_more()
 await frames()
 prologue.replay_current()
 check(prologue.auto_play and not prologue.voice.stream_paused and prologue.elapsed==0, "relisten from manual pause immediately restarts playback")
 prologue._show_scene(0, false)
 await frames()
 prologue.toggle_more()
 prologue.elapsed=float(prologue.scenes[0].duration)-.1
 prologue._process(.2)
 check(prologue.index==1 and not prologue.more_open and not prologue.voice.stream_paused, "automatic scene change closes the transient menu without stopping playback")
 prologue.stop()
 game.state="victory"
 game._sync_scene()
 check(not ui.get_node("Root/Victory/Stats").visible, "settlement statistics begin collapsed")
 game._action("victory_details")
 check(ui.get_node("Root/Victory/Stats").visible, "settlement details can be expanded")
 game.progress.error_text="本次进度未能保存"
 game._sync_scene()
 check(ui.get_node("Root/Victory/Saved").visible and ui.get_node("Root/Victory/Saved").text==game.progress.error_text, "simplified settlement retains save failure feedback")
 game.queue_free()
 await frames()
 await create_timer(.2).timeout
 print("UI FLOW CHECKS COMPLETE; failures=",failures)
 quit(1 if failures else 0)
