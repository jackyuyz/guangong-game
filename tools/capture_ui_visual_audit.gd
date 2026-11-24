extends SceneTree
## Native renderer evidence. Always uses a fresh temporary save; never a player profile.
var game: Node
var output := "/tmp/guangong-ui-visual-audit"
func _initialize() -> void:
 var args=OS.get_cmdline_user_args()
 if args.size()>0: output=args[0]
 DirAccess.make_dir_recursive_absolute(output)
 call_deferred("run")
func shot(name: String) -> void:
 game._sync_scene()
 await create_timer(0.15).timeout
 game.ui.get_node("Root/Utility/Body").set_process(false)
 for animation in game.ui.find_children("*","AnimationPlayer",true,false): animation.pause()
 await process_frame
 RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png(output+"/"+name+".png")
 var active: Node=game.ui.get_node("Root/HUD")
 if not game.utility_panel.is_empty(): active=game.ui.get_node("Root/Utility")
 elif game.show_culture: active=game.ui.get_node("Root/Culture")
 else:
  var paths={"menu":"MainMenu","map":"JourneyMap","pause":"Pause","confirm":"Confirm","dead":"Defeat","victory":"Victory","prologue":"Prologue","dialogue":"Dialogue"}
  if game.state in paths: active=game.ui.get_node("Root/"+paths[game.state])
 var markers: Array=[]
 var marker_restore: Array=[]
 var candidates: Array=[]
 if game.utility_panel=="settings":
  var settings=game.ui.get_node("Root/Utility/Settings")
  for path in ["Sound/On/Underline","Sound/Off/Underline","Motion/On/Underline","Motion/Off/Underline"]: candidates.append(settings.get_node(path))
 if game.state=="map" and game.utility_panel.is_empty():
  for stop in game.journey.get_node("ScrollClip/Stops").get_children(): candidates.append(stop.get_node("Selection/Gold"))
  candidates.append(game.journey.get_node("ScrollClip/ReadyFlag/Point"))
 for marker in candidates:
  if not marker.is_visible_in_tree() or marker.modulate.a<0.1: continue
  var bounds: Rect2
  if marker is Control: bounds=marker.get_global_rect()
  else:
   var points=marker.polygon if marker is Polygon2D else marker.points
   bounds=Rect2(marker.to_global(points[0]),Vector2.ZERO)
   for point in points: bounds=bounds.expand(marker.to_global(point))
   bounds=bounds.grow(2)
  markers.append({"path":str(marker.get_path()),"rect":[bounds.position.x,bounds.position.y,bounds.size.x,bounds.size.y]})
  marker_restore.append(marker)
  marker.visible=false
  if marker.name=="Gold": marker.get_parent().get_node("Highlight").visible=false
 await process_frame
 RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png(output+"/"+name+"-markers-background.png")
 for marker in marker_restore:
  marker.visible=true
  if marker.name=="Gold": marker.get_parent().get_node("Highlight").visible=true
 var rows: Array=[]
 var restore: Array=[]
 for node in game.ui.find_children("*","Control",true,false):
  if not(node is Label or node is Button) or not node.is_visible_in_tree() or node.text.is_empty(): continue
  var colors=["font_color"]
  var color_name="font_color"
  if node is Button:
   colors=["font_color","font_hover_color","font_focus_color","font_pressed_color","font_disabled_color","font_hover_pressed_color"]
   color_name=["font_color","font_pressed_color","font_hover_color","font_disabled_color","font_hover_pressed_color"][node.get_draw_mode()]
   if node.get_draw_mode()==0 and node.has_focus(): color_name="font_focus_color"
  var color: Color=node.get_theme_color(color_name)
  var tint: Color=node.self_modulate
  var ancestor: Node=node
  while ancestor is CanvasItem:
   tint*=ancestor.modulate
   ancestor=ancestor.get_parent()
  color*=tint
  var rect: Rect2=node.get_global_rect()
  if active==node or active.is_ancestor_of(node):
   var outline: Color=node.get_theme_color("font_outline_color")
   outline*=tint
   rows.append({"path":str(node.get_path()),"text":node.text,"rect":[rect.position.x,rect.position.y,rect.size.x,rect.size.y],"color":[color.r,color.g,color.b,color.a],"outline":[outline.r,outline.g,outline.b,outline.a],"outline_size":node.get_theme_constant("outline_size"),"disabled":node is Button and node.disabled,"decorative":"/Victory/Seal/" in str(node.get_path())})
  colors.append("font_outline_color")
  colors.append("font_shadow_color")
  for key in colors:
   var previous: Variant=node.get_theme_color(key) if node.has_theme_color_override(key) else null
   restore.append([node,key,previous])
   node.add_theme_color_override(key,Color(0,0,0,0))
 await process_frame
 RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png(output+"/"+name+"-background.png")
 for item in restore:
  if item[1] not in ["font_outline_color","font_shadow_color"]: item[0].add_theme_color_override(item[1],Color(1,0,1,1))
 await process_frame
 RenderingServer.force_draw(false)
 root.get_texture().get_image().save_png(output+"/"+name+"-mask.png")
 for item in restore:
  if item[2]==null: item[0].remove_theme_color_override(item[1])
  else: item[0].add_theme_color_override(item[1],item[2])
 var f=FileAccess.open(output+"/"+name+".json",FileAccess.WRITE)
 f.store_string(JSON.stringify({"state":game.state,"viewport":[root.size.x,root.size.y],"logical":[960,540],"text":rows,"markers":markers},"  "))
 print("Captured ",name," at ",root.size)
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate()
 # Focus changes from the editor cannot alter this render-only fixture.
 var fixture=GDScript.new()
 fixture.source_code='extends "res://scripts/main.gd"\nfunc _pause_for_focus_loss() -> void:\n window_active=true\n'
 if fixture.reload()!=OK: quit(1);return
 game.set_script(fixture)
 game.save_path="/tmp/guangong-ui-visual-%d.cfg"%Time.get_ticks_usec()
 root.add_child(game)
 game.set_process(false)
 game.window_active=true
 game.muted=true
 AudioServer.set_bus_mute(0,true)
 await shot("home")
 game.progress.set_intro("completed")
 await shot("home-returning")
 game._action("settings")
 game.muted=false
 await shot("settings")
 game.muted=true
 await shot("settings-muted")
 var click=InputEventMouseButton.new()
 click.button_index=MOUSE_BUTTON_LEFT
 click.position=game.ui.get_node("Root/Utility/Settings/Close").get_global_rect().get_center()
 click.pressed=true
 root.push_input(click,true)
 await shot("settings-pressed")
 click.pressed=false
 root.push_input(click,true)
 game._action("settings")
 game._action("help")
 await shot("guide")
 game._action("utility_close")
 game.show_culture=true
 await shot("culture")
 game.show_culture=false
 game._return_to_map()
 game.journey.set_reduced_motion(true)
 await shot("map")
 game.ui.get_node("Root/JourneyMap/Review").grab_focus()
 await shot("map-focus")
 click.position=game.ui.get_node("Root/JourneyMap/Review").get_global_rect().get_center()
 click.pressed=true
 root.push_input(click,true)
 await shot("map-pressed")
 # Reset the held pointer off the button before releasing; no replay action.
 var motion=InputEventMouseMotion.new()
 motion.position=Vector2(950,535)
 root.push_input(motion,true)
 click.position=motion.position
 click.pressed=false
 root.push_input(click,true)
 game.journey.select_chapter(1)
 await shot("map-locked")
 game.journey.select_chapter(0)
 game._enter_chapter("dongling")
 game.state="play"
 await shot("hud")
 game.resume_state="play"
 game.state="pause"
 await shot("pause")
 game._action("map_confirm")
 await shot("confirm")
 game.state="dead"
 await shot("defeat")
 game.checkpoint={"visual_fixture":true}
 await shot("defeat-checkpoint")
 game.checkpoint.clear()
 game.state="victory"
 await shot("victory")
 game._action("victory_details")
 await shot("stats")
 game.progress.error_text="本次进度未能保存"
 await shot("save-error")
 game.progress.error_text=""
 game.state="menu"
 game.show_culture=true
 game._action("prologue_replay")
 game.prologue.set_process(false)
 for index in range(6):
  game.prologue._show_scene(index,false)
  await shot("prologue-%d"%index)
 game.prologue.more_open=true
 game.prologue._set_more(true)
 await shot("more")
 game.queue_free()
 await create_timer(.3).timeout
 quit()
