extends SceneTree
## Compare shared dialogue UI against chapter one's real scene; no player profile.
var checks = 0
var failures = 0
var game: Node
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if ok: print("PASS: ", label)
	else:
		failures += 1
		push_error("FAIL: " + label)
func sample(phase: String, stamp: float) -> void:
	game.model._story(phase)
	game.model.phase_clock = stamp
	game._sync_world()
func run() -> void:
	game = load("res://scenes/levels/luoyang_chapter.tscn").instantiate()
	root.add_child(game)
	game.set_process(false)
	game.muted = true
	game.begin_chapter()
	var first = load("res://scenes/ui/duel_dialogue.tscn").instantiate()
	root.add_child(first)
	first.set_process(false)
	var panel: Panel = game.story_panel
	check(panel.get_global_rect() == first.get_node("Card").get_global_rect() and panel.get_theme_stylebox("panel") == first.get_node("Card").get_theme_stylebox("panel"), "story card matches chapter one's actual rectangle and shared translucent HUD style")
	for pair in [["Title", "Speaker"], ["Text", "Body"], ["Advance", "Next"]]:
		var current: Control = panel.get_node(pair[0])
		var original: Control = first.get_node(pair[1])
		check(current.get_global_rect() == original.get_global_rect() and current.get_theme_font("font") == original.get_theme_font("font") and current.get_theme_font_size("font_size") == original.get_theme_font_size("font_size"), "dialogue element matches first-chapter placement, font and size: " + pair[0])
	check(panel.get_node("Title").get_theme_color("font_color") == first.get_node("Speaker").get_theme_color("font_color") and panel.get_node("Text").get_theme_color("font_color") == first.get_node("Body").get_theme_color("font_color"), "old-gold heading and ivory body colors match chapter one")
	check(panel.get_node("Advance").theme_type_variation == first.get_node("Next").theme_type_variation, "story playback action uses the same gold brush button")
	first.hide()
	for stamp in [0.0, 1.7, 2.9]:
		sample("intro", stamp)
		var han: Node2D = game.get_node("Cutscene/HanFu")
		check(game.get_node("Cutscene/Hero").position.x - han.position.x >= 240.0 and game.get_node("Cutscene/MengTan").position.x - han.position.x >= 480.0, "both riders remain clearly right of gate-side Han Fu at %.1fs" % stamp)
	sample("meng_strike", 1.1)
	check(game.get_node("Cutscene/Hero").position == game.get_node("Cutscene/HeroContact").position and game.get_node("Cutscene/MengTan").position.x - game.get_node("Cutscene/Hero").position.x == 130.0 and game.get_node("Cutscene/Contact").position == game.get_node("Cutscene/StrikeContact").position, "shifted slaying shot preserves rider spacing and the actual contact anchor")
	sample("ambush", 4.05)
	check(game.get_node("Cutscene/HeroTurn").position.x - game.get_node("Cutscene/HanFu").position.x >= 320.0 and game.get_node("Cutscene/Contact").position == game.get_node("Cutscene/HeroTurn/LeftArm").global_position, "returning rider has more bow-side space while the hit still lands on the left arm")
	sample("ending", 1.8)
	var gate: Sprite2D = game.get_node("Cutscene/BindingGate")
	var sprite: Sprite2D = game.get_node("Cutscene/HeroBinding/Body/Sprite")
	var ratio = (gate.get_rect().size.y * gate.scale.y) / (sprite.get_rect().size.y * sprite.scale.y)
	check(gate.visible and not game.get_node("Cutscene/ArcheryPosition").visible and gate.texture == game.get_node("Cutscene/Gate").texture and ratio >= 1.5 and ratio <= 2.0, "bandaging uses the chapter's actual gate at architectural scale, not a miniature archery tower")
	var ground: Marker2D = game.get_node("Cutscene/BindingGround")
	ground.position.x += 25.0
	game._sync_world()
	check(game.get_node("Cutscene/HeroBinding").position == ground.position, "binding staging reads its own editable ground marker")
	ground.position.x -= 25.0
	sample("ending", 7.1)
	check(not gate.visible and game.get_node("Cutscene/Gate").visible and game.get_node("Cutscene/Procession").visible, "wide caravan shot replaces the close gate and keeps the departure")
	sample("intro", 0.1)
	game.overlay_guard = 0.2
	panel.get_node("Advance").pressed.emit()
	check(game.model.phase == "intro", "the restyled native button respects the transition input guard")
	game.overlay_guard = 0.0
	game.model.phase_clock = 0.4
	panel.get_node("Advance").pressed.emit()
	panel.get_node("Advance").pressed.emit()
	check(game.model.phase == "tutorial" and game.model.hits == 0, "repeated brush-button activation advances once without leaking gameplay input")
	game.queue_free()
	first.queue_free()
	await process_frame
	print("LUOYANG STAGING CHECKS: %d; failures: %d" % [checks, failures])
	quit(1 if failures else 0)
