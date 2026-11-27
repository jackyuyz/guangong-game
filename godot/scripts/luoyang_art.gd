extends RefCounted
## The chapter clock samples every pose/effect. No unowned tween or animation timer.
var last_phase = ""
var last_clock = -1.0
var last_hit = 0
var hit_age = 99.0
var hoof_clock = 0.0
var hoof_step = 0
var hoof_variants: Array[AudioStreamWAV] = []
var sounds: Dictionary = {}
var story = preload("res://scripts/luoyang_story.gd").new()
var finale = preload("res://scripts/luoyang_finale.gd").new()
const HOOF_GAPS = [0.10, 0.10, 0.20]

func _init() -> void:
	var rng = RandomNumberGenerator.new()
	rng.seed = 274
	# Dry, unpitched contacts: the old sine sweep sounded like a repeating alarm.
	for i in 3:
		hoof_variants.append(_hoof_contact(274 + i, [0.78, 0.55, 1.0][i]))
	sounds["hoof"] = hoof_variants[0]
	for kind in ["impact", "bow", "arrow", "slash", "wind"]:
		var stream = AudioStreamWAV.new()
		stream.format = AudioStreamWAV.FORMAT_16_BITS
		stream.mix_rate = 22050
		var count = int(22050 * (1.5 if kind == "wind" else 0.18))
		var filtered = 0.0
		var data = PackedByteArray()
		data.resize(count * 2)
		for i in count:
			var p = float(i) / count
			var noise = rng.randf_range(-1.0, 1.0)
			filtered = lerpf(filtered, noise, 0.035)
			var value = noise * sin(PI * p) * 0.3
			if kind == "impact":
				value = (sin(TAU * (140.0 - p * 50.0) * i / 22050.0) * 0.7 + noise * 0.3) * exp(-p * 8.0)
			elif kind == "bow":
				value = (sin(TAU * 310.0 * i / 22050.0) * 0.5 + noise * 0.12) * exp(-p * 7.0)
			elif kind == "wind":
				value = filtered * sin(PI * p)
			data.encode_s16(i * 2, int(value * 9000.0))
		stream.data = data
		if kind == "wind":
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			stream.loop_end = count
		sounds[kind] = stream

func _hoof_contact(seed_value: int, strength: float) -> AudioStreamWAV:
	var rng = RandomNumberGenerator.new()
	rng.seed = seed_value
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var count = int(stream.mix_rate * 0.075)
	var data = PackedByteArray()
	data.resize(count * 2)
	var body = 0.0
	var grit = 0.0
	for i in count:
		var t = float(i) / stream.mix_rate
		var noise = rng.randf_range(-1.0, 1.0)
		body = lerpf(body, noise, 0.24)
		grit = lerpf(grit, noise, 0.06)
		var attack = 1.0 - exp(-t / 0.0015)
		var contact = body * attack * exp(-t / 0.012)
		var scuff = grit * attack * exp(-t / 0.024) * 0.22
		# A softer toe/gravel contact follows the initial hoof, without a ringing tone.
		var toe = body * (1.0 - exp(-maxf(0.0, t - 0.017) / 0.002)) * exp(-maxf(0.0, t - 0.017) / 0.007) * 0.30
		var fade = clampf((0.075 - t) / 0.008, 0.0, 1.0)
		data.encode_s16(i * 2, int((contact + scuff + toe) * fade * strength * 18000.0))
	stream.data = data
	return stream

func cue(game: Node, kind: String, channel = "Effects") -> void:
	if game.muted or game.model.state not in ["running", "story"]: return
	var player: AudioStreamPlayer = game.get_node(channel)
	player.stream = sounds[kind]
	player.play()

func audio_state(game: Node) -> void:
	for name in ["Hooves", "Effects", "BowCue", "Wind"]:
		var player: AudioStreamPlayer = game.get_node(name)
		if game.muted or game.model.state in ["ready", "failed", "complete", "culture"]:
			player.stream_paused = false
			player.stop()
		else:
			player.stream_paused = game.model.state == "paused"

func release_audio(game: Node) -> void:
	for name in ["Hooves", "Effects", "BowCue", "Wind"]:
		var player: AudioStreamPlayer = game.get_node(name)
		player.stream_paused = false
		player.stop()
		player.stream = null

func update(game: Node) -> void:
	var m = game.model
	var phase: String = m.phase
	var clock: float = m.phase_clock
	if phase != last_phase or clock < last_clock - 0.001:
		last_phase = phase
		last_clock = -1.0
		hit_age = 99.0
		last_hit = m.hits
		hoof_clock = clock
		hoof_step = 0
		for name in ["Hooves", "Effects", "BowCue", "Wind"]:
			game.get_node(name).stream_paused = false
			game.get_node(name).stop()
	var active: bool = m.state in ["running", "story"]
	var dt: float = maxf(0.0, clock - last_clock) if last_clock >= 0.0 and active else 0.0
	if m.hits > last_hit:
		hit_age = 0.0
		last_hit = m.hits
	elif active:
		hit_age += dt
	var cycle = int(clock * (5.5 if m.slowdown > 0.0 else 10.0)) % 4
	var body: Node2D = game.rider.get_node("Body")
	body.position = Vector2.ZERO
	body.rotation = 0.0
	body.modulate = Color(1.0, 0.68, 0.52) if hit_age < 0.18 else Color.WHITE
	var pose = (4 if m.wounded else 0) + cycle
	if m.lane_time < m.LANE_SECONDS and not m.wounded: pose = 8 if m.target_lane < m.from_lane else 9
	if hit_age < 0.24 and not m.wounded: pose = 10
	if phase == "fall" or m.state == "failed": pose = 11 if m.wounded else 10
	if m.state == "ready": pose = 0
	game.rider.pose(pose)
	game.get_node("World/MengTan").pose(cycle)
	game.get_node("World/MengTan").modulate = Color.WHITE
	var enemy_body: Node2D = game.get_node("World/MengTan/Body")
	enemy_body.rotation = (float(m.pursuer.target_lane) - m.pursuer.lane) * 0.055 if not game.reduced_motion else 0.0
	# The gate is behind the camera while chasing away from it.
	game.get_node("World/Gate").visible = phase in ["sprint", "han_strike", "ending"]
	game.get_node("Cutscene").modulate = Color.WHITE
	game.get_node("World/Rider/Wound").hide()
	var name_label: Label = game.get_node("World/MengTan/Name")
	name_label.visible = phase == "chase"
	var factor: float = game.road.factor(m.gap)
	name_label.scale = Vector2.ONE / factor
	name_label.position = Vector2(-22.0 / factor, -205.0 - 23.0 / factor)
	name_label.size = Vector2(44, 22)
	var archer_pose = 0
	for h in m.hazards:
		if h.kind == "arrow" and not h.resolved: archer_pose = 2 if h.phase == "aim" else (3 if h.phase == "locked" else 4)
	game.get_node("World/Archer").pose(archer_pose)
	game.get_node("World/Archer").modulate = Color.WHITE
	game.get_node("World/Archer").visible = phase == "sprint" and m.state in ["running", "paused"]
	if phase == "sprint":
		var gate: Node2D = game.get_node("World/Gate")
		game.get_node("World/Archer").position = gate.position + game.get_node("World/Gate/ArcherGround").position * gate.scale
	for i in game.get_node("Road/Verge").get_child_count():
		var verge: Node2D = game.get_node("Road/Verge").get_child(i)
		var depth = fposmod(float(i / 2) * 15.0 - m.distance + 8.0, 90.0)
		verge.position = game.road.project(-2.0 if i % 2 == 0 else 2.0, depth)
		verge.scale = Vector2.ONE * game.road.factor(depth)
		verge.z_index = int(100.0 - depth)
	for i in game.get_node("Road/Grit").get_child_count():
		var grit: Node2D = game.get_node("Road/Grit").get_child(i)
		var depth = fposmod(i * 7.7 - m.distance, 90.0)
		grit.position = game.road.project(sin(i * 7.1) * 1.4, depth)
		grit.scale = Vector2.ONE * game.road.factor(depth)
	var dust: Node2D = game.get_node("World/Dust")
	dust.position = game.rider.position
	dust.visible = m.state == "running" and not game.reduced_motion
	for i in dust.get_child_count():
		var particle: Polygon2D = dust.get_child(i)
		var p = fposmod(clock * 2.5 + i * 0.22, 1.0)
		particle.position = Vector2((i % 2 * 2 - 1) * (12.0 + p * 26.0), p * 32.0)
		particle.scale = Vector2.ONE * (0.7 + p * 1.4)
		particle.modulate.a = (1.0 - p) * 0.45
	var impact: Node2D = game.get_node("World/Impact")
	impact.position = game.rider.position
	impact.visible = hit_age < 0.25
	impact.modulate.a = clampf(1.0 - hit_age / 0.25, 0.0, 1.0)
	game.get_node("World").position = Vector2.ZERO
	if not game.reduced_motion and hit_age < 0.18: game.get_node("World").position.x = sin(hit_age * 120.0) * 3.0
	game.get_node("UI/HitFlash").color.a = 0.06 * clampf(1.0 - hit_age / 0.18, 0.0, 1.0) if not game.reduced_motion else 0.0
	var story_gallop = (phase == "intro" and clock >= 2.65) or (phase == "ambush" and clock >= 2.4 and clock < 3.35)
	var procession_walk = phase == "ending" and (clock >= 3.8 and clock < finale.MEET or clock >= finale.DEPART and clock < finale.EXIT)
	if active and (phase in ["tutorial", "chase", "sprint"] or story_gallop or procession_walk) and clock >= hoof_clock:
		if not game.muted:
			var hooves: AudioStreamPlayer = game.get_node("Hooves")
			hooves.stream = hoof_variants[hoof_step]
			hooves.play()
		hoof_clock = clock + (0.38 if procession_walk else HOOF_GAPS[hoof_step] * (1.6 if m.slowdown > 0.0 else 1.0))
		hoof_step = (hoof_step + 1) % hoof_variants.size()
	if phase in ["meng_strike", "han_strike", "ambush", "intro", "ending"]: _story(game, phase, clock)
	finale.update(game, phase, clock)
	if active and phase != "fall" and not game.muted and not game.get_node("Wind").playing:
		cue(game, "wind", "Wind")
	audio_state(game)
	last_clock = clock

func _story(game: Node, phase: String, t: float) -> void:
	var hero = game.get_node("Cutscene/Hero")
	var meng = game.get_node("Cutscene/MengTan")
	var han = game.get_node("Cutscene/HanFu")
	var attack = phase in ["meng_strike", "han_strike"]
	hero.show()
	for actor in [hero, meng, han]: actor.get_node("Body").scale = Vector2.ONE
	game.get_node("Cutscene/HeroTurn").hide()
	game.get_node("Cutscene/DepartingMeng").hide()
	game.get_node("Cutscene/TurnDust").hide()
	game.get_node("Cutscene/Gate").visible = phase in ["intro", "meng_strike", "ambush"]
	game.get_node("Cutscene/Carriage").scale = Vector2.ONE * 1.8
	meng.position = game.get_node("Cutscene/Opponent").position
	han.position = game.get_node("Cutscene/IntroHan" if phase == "intro" else "Cutscene/Opponent").position
	game.get_node("Cutscene").visible = game.model.state == "story" or (game.model.state == "paused" and game.model.resume_kind == "story")
	game.rider.visible = false
	hero.scale = Vector2.ONE
	hero.position = game.get_node("Cutscene/HeroRest").position
	hero.get_node("Weapon").rotation = 0.0
	hero.get_node("Wound").hide()
	meng.rotation = 0.0
	han.rotation = 0.0
	meng.modulate = Color.WHITE
	game.get_node("Cutscene/Carriage").visible = phase in ["intro", "ending"]
	game.get_node("Cutscene/ArcheryPosition").visible = phase in ["ambush", "han_strike", "intro"]
	game.get_node("Cutscene/Slash").visible = attack and t >= 0.95 and t <= 1.16
	game.get_node("Cutscene/Slash").modulate.a = 0.5 if game.reduced_motion else clampf((1.16 - t) / 0.21, 0.0, 1.0)
	meng.visible = phase in ["meng_strike", "intro"]
	han.visible = phase in ["ambush", "han_strike", "intro"]
	game.get_node("Cutscene/AmbushArrow").visible = phase == "ambush" and t > 0.88 and t < 1.10
	if phase in ["intro", "ambush"]:
		han.get_node("Body").scale.x = -1.0
		story.sample(game, phase, t, self)
		return
	if attack:
		hero.get_node("Wound").visible = game.model.wounded
		var start: Vector2 = game.get_node("Cutscene/HeroStart").position
		var contact: Vector2 = game.get_node("Cutscene/HeroContact").position
		hero.position = start.lerp(contact, smoothstep(0.0, 0.9, t))
		hero.pose((int(t * 9.0) % 2) if t < 0.50 else (2 if t < 0.86 else (3 if t < 0.98 else (4 if t < 1.16 else 5))))
		meng.pose(0 if t < 1.0 else (1 if t < 1.24 else (2 if t < 1.55 else 3)))
		han.pose(0 if t < 1.0 else (5 if t < 1.24 else (6 if t < 1.55 else 7)))
		if last_clock < 0.86 and t >= 0.86: cue(game, "slash")
		if last_clock < 1.0 and t >= 1.0: cue(game, "impact", "BowCue")
		game.get_node("Cutscene/Contact").visible = t >= 1.0 and t < 1.16
	else:
		hero.pose(6 if phase == "ending" else 0)
		meng.pose(0)
		han.pose(0)
		game.get_node("Cutscene/Contact").hide()
		var carriage = game.get_node("Cutscene/Carriage")
		carriage.position = game.get_node("Cutscene/CarriageStart").position
		if phase == "ending" and not game.reduced_motion: carriage.position.x += t * 22.0
	if phase != "ambush": game.get_node("Cutscene/Contact").position = game.get_node("Cutscene/StrikeContact").position
