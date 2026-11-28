extends RefCounted
## End-of-route and procession staging use the same pause-owned chapter clock.
const ESCAPE_SECONDS = 3.2
const ENDING_SECONDS = 10.4
const WARNING_SECONDS = 8.0
const BIND_END = 3.2
const CUT = 3.5
const MEET = 5.7
const DEPART = 6.3
const EXIT = 10.0

func caption(phase: String, t: float) -> Array:
	if phase == "escape": return ["孟坦逃脱", "孟坦拨马奔入右侧岔路，转过林后，不见踪影。"]
	if phase == "ending":
		if t < CUT: return ["关前束伤", "关羽勒马取布，缠紧左臂箭伤。"]
		if t < DEPART: return ["接应车仗", "关羽接应二位夫人的车仗，整队出关。"]
		return ["离关前行", "车仗随关羽离开洛阳，继续前往汜水关。"]
	return []

func update(game: Node, phase: String, t: float) -> void:
	var m = game.model
	var junction = game.get_node("ForkLandscape")
	var warning_start: float = m.CHASE_LIMIT - WARNING_SECONDS
	var warning: bool = phase == "chase" and m.elapsed >= warning_start - 0.4
	junction.visible = warning or phase == "escape"
	junction.modulate.a = smoothstep(warning_start - 0.4, warning_start, m.elapsed) if warning else 1.0
	game.get_node("ForkLandscape/Foliage").visible = phase == "escape"
	game.get_node("Cutscene/HeroBinding").hide()
	game.get_node("Cutscene/Procession").hide()
	game.get_node("Cutscene/ClosingShade").hide()
	game.get_node("Cutscene/BindingGate").hide()
	if phase == "escape": _escape(game, t)
	elif phase == "ending": _ending(game, t)

func _escape(game: Node, t: float) -> void:
	game.get_node("Cutscene").hide()
	game.rider.show()
	game.rider.pose(10)
	var meng = game.get_node("World/MengTan")
	var origin: Vector2 = game.road.project(game.model.escape_origin.x, game.model.escape_origin.y)
	var initial_scale: float = game.road.factor(game.model.escape_origin.y)
	var fork: Vector2 = game.get_node("ForkTurn").position
	var bend: Vector2 = game.get_node("ForkBend").position
	var hidden: Vector2 = game.get_node("ForkHide").position
	meng.visible = t < 2.65
	meng.pose(int(t * 10.0) % 4)
	meng.position = origin.lerp(fork, smoothstep(0.0, 0.9, t))
	var size = lerpf(initial_scale, 0.22, smoothstep(0.0, 0.9, t))
	if t >= 0.9:
		meng.position = fork.lerp(bend, smoothstep(0.9, 1.8, t))
		size = lerpf(0.22, 0.14, smoothstep(0.9, 1.8, t))
	if t >= 1.8:
		meng.position = bend.lerp(hidden, smoothstep(1.8, 2.65, t))
		size = lerpf(0.14, 0.09, smoothstep(1.8, 2.65, t))
	meng.scale = Vector2.ONE * size
	meng.z_index = 115
	meng.get_node("Body").rotation = 0.08 if t >= 0.9 and not game.reduced_motion else 0.0
	game.get_node("World/Impact").hide()
	game.get_node("UI/Warning").text = ""
	game.get_node("UI/WarningBacking").hide()
	game.story_panel.modulate.a = 1.0 - smoothstep(0.65, 1.05, t)

func _ending(game: Node, t: float) -> void:
	game.get_node("Cutscene/Hero").hide()
	game.get_node("Cutscene/Carriage").hide()
	var hero = game.get_node("Cutscene/HeroBinding")
	var cart = game.get_node("Cutscene/Procession")
	hero.show()
	hero.position = game.get_node("Cutscene/BindingGround").position
	var poses = [0, 1, 2, 3, 4, 5]
	hero.pose(poses[mini(int(t / 0.55), 5)])
	var wide = t >= CUT
	game.get_node("Cutscene/Gate").visible = wide
	game.get_node("Cutscene/ArcheryPosition").hide()
	game.get_node("Cutscene/BindingGate").visible = not wide
	game.get_node("Cutscene/HanFu").hide()
	var shade = game.get_node("Cutscene/ClosingShade")
	shade.visible = t >= BIND_END and t < 3.8
	shade.modulate.a = clampf(1.0 - absf(t - CUT) / 0.3, 0.0, 1.0)
	if wide:
		var hero_wait: Vector2 = game.get_node("Cutscene/EscortWait").position
		var start: Vector2 = game.get_node("Cutscene/CaravanEnter").position
		var meet: Vector2 = game.get_node("Cutscene/CaravanMeet").position
		var exit: Vector2 = game.get_node("Cutscene/CaravanExit").position
		hero.position = hero_wait
		hero.pose(5)
		cart.show()
		cart.position = start.lerp(meet, smoothstep(3.8, MEET, t))
		var walking = t < MEET or t >= DEPART
		cart.pose(int(t * 5.0) % 4 if walking else 0)
		if t >= DEPART:
			var travel = meet.lerp(exit, smoothstep(DEPART, EXIT, t)) - meet
			cart.position = meet + travel
			hero.position = hero_wait + travel
			hero.pose(6 + int(t * 5.0) % 2)
	# Keep all feet, harness and wheels visible during the final wide departure.
	game.story_panel.modulate.a = 1.0 - smoothstep(DEPART, DEPART + 0.8, t)
