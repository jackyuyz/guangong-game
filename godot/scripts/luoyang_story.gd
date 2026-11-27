extends RefCounted
## Side-view geography: gate stays LEFT, pursuit travels RIGHT, return travels LEFT.
## Everything is sampled from phase_clock, including transitions and projectile contact.
const INTRO_SECONDS = 7.0
const AMBUSH_SECONDS = 7.0
const RELEASE = 3.65
const CONTACT = 3.95
const REVEAL_START = 5.4
const REVEAL_END = 6.5

func caption(phase: String, t: float) -> Array:
	if phase == "intro":
		if t < 1.65: return ["洛阳关外", "韩福阻路，孟坦出战。车仗暂候路旁。"]
		if t < 3.2: return ["孟坦佯退", "交锋未久，孟坦拨马退走。"]
		return ["策马追赶", "关羽催动赤兔，追着孟坦离开城门。"]
	if phase == "ambush":
		if t < 2.4: return ["勒马回身", "孟坦已败，关羽勒马，转身返回洛阳关。"]
		if t < RELEASE: return ["回望城门", "城门就在来路，韩福仍在门边。"]
		if t < 4.6: return ["门边暗箭", "韩福突然放箭，正中关羽左臂。"]
		return ["带伤冲门", "关羽忍住箭伤，催马直取门边的韩福。"]
	return []

func sample(game: Node, phase: String, t: float, art: RefCounted) -> void:
	if phase == "intro": _intro(game, t, art)
	else: _ambush(game, t, art)
	# Match the same rear-view ground anchors used on the first interactive frame.
	var blend = smoothstep(REVEAL_START, REVEAL_END, t)
	game.get_node("Cutscene").modulate.a = 1.0 - blend
	game.story_panel.modulate.a = 1.0 - blend
	game.rider.visible = blend > 0.0
	game.rider.position = game.road.project(0.0, 0.0)
	game.get_node("World/Gate").visible = phase == "ambush" and blend > 0.0
	if phase == "intro":
		var target = game.get_node("World/MengTan")
		target.visible = blend > 0.0
		target.position = game.road.project(game.model.pursuer.lane, game.model.gap)
		target.scale = Vector2.ONE * game.road.factor(game.model.gap)
		target.z_index = int(109.0 - game.model.gap)
	else:
		game.rider.pose(4 + int(t * 10.0) % 4)
		var gate = game.get_node("World/Gate")
		var archer = game.get_node("World/Archer")
		archer.visible = blend > 0.0
		archer.position = gate.position + game.get_node("World/Gate/ArcherGround").position * gate.scale
		archer.pose(0)
	# A short scrape is visible during braking/pivoting, never an independent particle timer.
	var dust = game.get_node("Cutscene/TurnDust")
	dust.visible = phase == "ambush" and t < 2.4 and not game.reduced_motion
	dust.position = game.get_node("Cutscene/HeroTurn").position
	dust.scale = Vector2.ONE * (0.7 + fposmod(t * 1.8, 1.0) * 0.8)
	dust.modulate.a = 0.35 * (1.0 - fposmod(t * 1.8, 1.0))

func _intro(game: Node, t: float, art: RefCounted) -> void:
	var hero = game.get_node("Cutscene/Hero")
	var meng = game.get_node("Cutscene/MengTan")
	var rear = game.get_node("Cutscene/DepartingMeng")
	var rest: Vector2 = game.get_node("Cutscene/HeroRest").position
	var contact: Vector2 = game.get_node("Cutscene/IntroContact").position
	var opponent: Vector2 = game.get_node("Cutscene/Opponent").position
	var flight: Vector2 = game.get_node("Cutscene/FlightExit").position
	hero.position = rest.lerp(contact, smoothstep(0.7, 1.5, t))
	hero.pose(0 if t < 1.2 else (2 if t < 1.5 else (3 if t < 1.65 else 5)))
	meng.position = opponent
	meng.get_node("Body").scale.x = -1.0
	meng.pose(1 if t >= 1.65 and t < 2.15 else 0)
	if t >= 1.65:
		meng.position.x += 40.0 * smoothstep(1.65, 2.15, t)
	# The rear angle bridges the facing change; the horse never spins as a flat card.
	if t >= 2.15 and t < 2.65:
		meng.hide()
		rear.show()
		rear.pose(int(t * 10.0) % 4)
		rear.position = (opponent + Vector2(40, 0)).lerp(opponent + Vector2(85, -14), smoothstep(2.15, 2.65, t))
	elif t >= 2.65:
		meng.get_node("Body").scale.x = 1.0
		meng.position = (opponent + Vector2(85, -14)).lerp(flight, smoothstep(2.65, 5.4, t))
	if t >= 3.2:
		hero.pose(int(t * 9.0) % 2)
		hero.position = contact.lerp(flight - Vector2(200, 0), smoothstep(3.2, 5.4, t))
	var spark = game.get_node("Cutscene/Contact")
	spark.position = game.get_node("Cutscene/IntroBladeContact").position
	spark.visible = t >= 1.6 and t < 1.78
	if art.last_clock < 1.5 and t >= 1.5: art.cue(game, "slash")
	if art.last_clock < 1.65 and t >= 1.65: art.cue(game, "impact", "BowCue")
	game.get_node("Cutscene/Carriage").position = game.get_node("Cutscene/WaitingCarriage").position
	game.get_node("Cutscene/Carriage").scale = Vector2.ONE * 0.95
	game.get_node("Cutscene/HanFu").pose(0)
	# The bow remains down: the opening does not reveal the ambush plan.
	game.get_node("Cutscene/ArcheryPosition").hide()

func _ambush(game: Node, t: float, art: RefCounted) -> void:
	game.get_node("Cutscene/Hero").hide()
	var hero = game.get_node("Cutscene/HeroTurn")
	hero.show()
	var start: Vector2 = game.get_node("Cutscene/HeroContact").position
	var pivot: Vector2 = game.get_node("Cutscene/TurnGround").position
	var returning: Vector2 = game.get_node("Cutscene/ReturnGround").position
	hero.position = start.lerp(pivot, smoothstep(0.0, 0.8, t))
	var pose = 0
	if t >= 0.8: pose = 1
	if t >= 1.2: pose = 2
	if t >= 1.65: pose = 3
	if t >= 2.1: pose = 4
	if t >= 2.4: hero.position = pivot.lerp(returning, smoothstep(2.4, 3.35, t))
	if t >= CONTACT: pose = 5 if t < 4.25 else 6
	if t >= 4.6: hero.position.x -= (t - 4.6) * 25.0
	hero.pose(pose)
	# Keep the fallen rider on the right, where the previous shot left him.
	var meng = game.get_node("Cutscene/MengTan")
	meng.show()
	meng.pose(3)
	var han = game.get_node("Cutscene/HanFu")
	han.position = game.get_node("Cutscene/IntroHan").position
	han.pose(0 if t < 2.4 else (1 if t < 2.75 else (2 if t < 3.2 else (3 if t < RELEASE else 4))))
	var arrow = game.get_node("Cutscene/AmbushArrow")
	var origin: Vector2 = han.position + game.get_node("Cutscene/GateArrowOffset").position
	var target: Vector2 = hero.position + hero.get_node("LeftArm").position
	arrow.visible = t >= RELEASE and t < CONTACT
	arrow.position = origin.lerp(target, clampf((t - RELEASE) / (CONTACT - RELEASE), 0.0, 1.0))
	arrow.rotation = (target - origin).angle() + PI
	var spark = game.get_node("Cutscene/Contact")
	spark.position = target
	spark.visible = t >= CONTACT and t < CONTACT + 0.18
	if art.last_clock < RELEASE and t >= RELEASE: art.cue(game, "bow", "BowCue")
	if art.last_clock < CONTACT and t >= CONTACT: art.cue(game, "impact")
	game.get_node("Cutscene/ArcheryPosition").hide()
