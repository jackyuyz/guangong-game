extends Node2D
## Game rules and session state. Presentation lives in editor-authored scenes.

const GOLD = Color("dfbc76")
const PAPER = Color("f3e8cd")
const MUTED = Color("b8b6a2")
const INK = Color("111c1b")
const JADE = Color("72b69a")
const RED = Color("cf6950")
const VIEWPORT_WIDTH = 960.0
const SCORE_VERSION = "ch01-v2-checkpoint"
var ext = preload("res://scripts/combat_extensions.gd").new()

@onready var level = $Level
@onready var ui = $UI
@onready var prologue = $UI/Root/Prologue
var prologue_return_state = ""
var await_input_release = false
var _web_focus_callback: JavaScriptObject
var _web_document: JavaScriptObject
var _web_window: JavaScriptObject
var story: Dictionary
var state = "menu"
var resume_state = "play"
var phase = 0
var x = 180.0
var player_y: float
var rest_x: float:
	get: return level.rest_origin.x
var moving = false
var facing = 1.0
var camera_x = 0.0
var hp = 6
var enemies: Array[Dictionary] = []
var attack_time = 0.0
var attack_cooldown = 0.0
var combo_window = 0.0
var combo = 0
var swing_id = 0
var dodge_time = 0.0
var dodge_cooldown = 0.0
var invincible = 0.0
var combat_seconds = 0.0
var hits = 0
var retries = 0
var checkpoint: Dictionary = {}
var clock = 0.0
var shake = 0.0
var hit_stop = 0.0
var particles: Array[Dictionary] = []
var floaters: Array[Dictionary] = []
var dialogue: Array = []
var dialogue_index = 0
var dialogue_after = "play"
var message = "向右前行，抵达旗标"
var message_time = 0.0
var tutorial_hits = 0
var score = 0
var best = 0
var cleared = false
var show_culture = false
var muted = false
var save_path = "user://progress.cfg"
var tone_player: AudioStreamPlayer

func _ready() -> void:
	story = JSON.parse_string(FileAccess.get_file_as_string("res://data/story.json"))
	var save = ConfigFile.new()
	if save.load(save_path) == OK:
		best = int(save.get_value(SCORE_VERSION, "best", 0))
		cleared = bool(save.get_value(SCORE_VERSION, "cleared", false))
		muted = bool(save.get_value("settings", "muted", false))
	tone_player = $Sound
	ui.action_requested.connect(_action)
	prologue.completed.connect(_finish_prologue)
	prologue.silence_requested.connect(_action.bind("prologue_silent"))
	prologue.narration_requested.connect(_action.bind("prologue_relisten"))
	if OS.has_feature("web"):
		_web_document = JavaScriptBridge.get_interface("document")
		_web_window = JavaScriptBridge.get_interface("window")
		_web_focus_callback = JavaScriptBridge.create_callback(_on_web_focus_change)
		_web_document.addEventListener("visibilitychange", _web_focus_callback)
		_web_window.addEventListener("blur", _web_focus_callback)
	_place_player(level.player_origin)
	camera_x = level.world_left
	_sync_scene()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT or (what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and not OS.has_feature("web")):
		_pause_for_focus_loss()

func _on_web_focus_change(_arguments: Array) -> void:
	if _web_document.hidden or not _web_document.hasFocus():
		_pause_for_focus_loss()

func _pause_for_focus_loss() -> void:
	if state in ["play", "dialogue", "prologue"]:
		resume_state = state
		state = "pause"
		if is_instance_valid(prologue):
			prologue.set_suspended(true)
			_sync_scene()

func _exit_tree() -> void:
	if _web_focus_callback != null:
		_web_document.removeEventListener("visibilitychange", _web_focus_callback)
		_web_window.removeEventListener("blur", _web_focus_callback)
	if tone_player != null:
		tone_player.stop()

func _unhandled_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	var key = event.physical_keycode
	if key == KEY_M:
		muted = not muted
		_save()
	if key in [KEY_ESCAPE, KEY_P]:
		if show_culture and state in ["menu", "victory"]:
			show_culture = false
		elif state == "confirm":
			state = "pause"
		elif state == "pause":
			state = resume_state
		elif state in ["play", "dialogue", "prologue"]:
			resume_state = state
			state = "pause"
		_sync_scene()
		return
	if key == KEY_ENTER:
		if show_culture and state in ["menu", "victory"]:
			show_culture = false
		elif state == "menu":
			_start()
		elif state == "dialogue":
			_next_dialogue()
		elif state == "prologue":
			prologue.advance()
		elif state == "dead":
			_retry()
		elif state == "victory":
			show_culture = not show_culture
		return
	if state != "play" or await_input_release:
		return
	if ext.handle_key(self, key):
		return
	if key == KEY_J and attack_cooldown <= 0.0 and dodge_time <= 0.0:
		combo = combo + 1 if combo_window > 0.0 else 1
		if combo > 3:
			combo = 1
		attack_time = 0.24
		attack_cooldown = 0.29 if combo < 3 else 0.48
		combo_window = 0.64
		swing_id += 1
		_tone(180.0 + combo * 55.0, 0.07, 0.08)
	if key == KEY_SPACE and dodge_cooldown <= 0.0 and attack_time <= 0.0:
		dodge_time = 0.36
		dodge_cooldown = 0.8
		_tone(120, 0.09, 0.06)

func _action(action: String) -> void:
	match action:
		"start": _start()
		"culture": show_culture = not show_culture
		"prologue_sound":
			if prologue.waiting_for_audio:
				prologue.request_audio()
			else:
				muted = not muted
				_save()
		"prologue_silent":
			muted = true
			_save()
		"prologue_relisten":
			muted = false
			_save()
		"prologue_replay":
			if show_culture and state in ["menu", "victory"]:
				prologue_return_state = state
				if prologue.begin(true):
					state = "prologue"
					show_culture = false
		"next": _next_dialogue()
		"skip": _finish_dialogue()
		"resume": state = resume_state
		"pause_click":
			resume_state = state
			state = "pause"
		"retry": _retry()
		"restart":
			checkpoint.clear()
			_retry()
		"menu_confirm": state = "confirm"
		"menu":
			prologue.stop()
			prologue_return_state = ""
			_reset_run()
			phase = 0
			_place_player(level.player_origin)
			camera_x = level.world_left
			state = "menu"
			show_culture = false
		"cancel": state = "pause"
		"mute":
			muted = not muted
			_save()
	_sync_scene()

func _start() -> void:
	_reset_run()
	phase = 0
	_place_player(level.player_origin)
	set_meta("dummy_hits", 0)
	tutorial_hits = 0
	show_culture = false
	prologue_return_state = ""
	prologue.set_muted(muted)
	if prologue.begin():
		state = "prologue"
	else:
		_begin_dialogue(story.opening, "play")

func _finish_prologue() -> void:
	if state != "prologue":
		return
	if not prologue_return_state.is_empty():
		state = prologue_return_state
		prologue_return_state = ""
		show_culture = true
	else:
		state = "play"
		await_input_release = true
		_banner("护送二位夫人，过关寻刘备。向右前行，抵达旗标")
	_sync_scene()

func _inputs_held() -> bool:
	for key in [KEY_A, KEY_D, KEY_LEFT, KEY_RIGHT, KEY_ENTER, KEY_J, KEY_K, KEY_L, KEY_E, KEY_SPACE]:
		if Input.is_physical_key_pressed(key):
			return true
	return Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)

func _reset_run() -> void:
	await_input_release = false
	hp = 6
	facing = 1
	combat_seconds = 0
	hits = 0
	retries = 0
	checkpoint.clear()
	enemies.clear()
	ext.reset()
	_reset_effects()

func _reset_effects() -> void:
	moving = false
	attack_time = 0
	attack_cooldown = 0
	dodge_time = 0
	dodge_cooldown = 0
	combo_window = 0
	combo = 0
	invincible = 0
	hit_stop = 0
	shake = 0
	particles.clear()
	floaters.clear()

func _begin_dialogue(lines: Array, after: String) -> void:
	dialogue = lines
	dialogue_index = 0
	dialogue_after = after
	state = "dialogue"

func _next_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index >= dialogue.size():
		_finish_dialogue()

func _finish_dialogue() -> void:
	state = dialogue_after
	if phase == 5:
		_enter_boss()
	elif dialogue_after == "victory":
		show_culture = true

func _place_player(origin: Vector2) -> void:
	x = origin.x
	player_y = origin.y

func _spawn(origin: Vector2, view: Node2D, boss: bool = false) -> void:
	enemies.append({"x": origin.x, "y": origin.y, "view": view, "hp": 16 if boss else 2, "max_hp": 16 if boss else 2,
		"boss": boss, "mode": "approach", "timer": 0.4, "facing": -1.0,
		"last_swing": -1, "flash": 0.0, "move": 0, "struck": false, "combo_pending": false})

func _enter_boss() -> void:
	phase = 6
	hp = maxi(hp, 4)
	_place_player(level.boss_player_origin)
	checkpoint = {"hp": hp, "seconds": combat_seconds, "hits": hits}
	enemies.clear()
	_reset_effects()
	_spawn(level.boss_origin, level.boss, true)
	state = "play"
	ext.update(self, 0.0)
	_banner("孔秀 · 东岭关守将  /  看清蓄力，闪避后反击")

func _retry() -> void:
	prologue.stop()
	await_input_release = false
	retries += 1
	ext.reset()
	_reset_effects()
	enemies.clear()
	if not checkpoint.is_empty():
		hp = checkpoint.hp
		combat_seconds = checkpoint.seconds
		hits = checkpoint.hits
		_place_player(level.boss_player_origin)
		phase = 6
		_spawn(level.boss_origin, level.boss, true)
	else:
		hp = 6
		_place_player(level.wave_retry_origin)
		phase = 3
		hits = 0
		combat_seconds = 0
		_spawn_wave(1)
	state = "play"
	ext.update(self, 0.0)

func _process(dt: float) -> void:
	if await_input_release and not _inputs_held():
		await_input_release = false
	if state == "menu" or (state == "play" and hit_stop <= 0):
		clock += dt
	if state == "play" and not await_input_release:
		if hit_stop > 0:
			hit_stop -= dt
		else:
			_update_play(minf(dt, 0.04))
	if state in ["play", "dialogue", "victory"]:
		var camera_end = maxf(level.world_left, level.world_right - VIEWPORT_WIDTH)
		var target = camera_end if phase == 6 else clampf(x - 350, level.world_left, camera_end)
		camera_x = lerpf(camera_x, target, minf(dt * 5, 1))
	if state in ["play", "victory"]:
		shake = maxf(0, shake - dt * 20)
		for p in particles:
			p.life -= dt
			p.pos += p.vel * dt
			p.vel.y += dt * 420
		particles = particles.filter(func(p): return p.life > 0)
		for f in floaters:
			f.life -= dt
			f.y -= dt * 26
		floaters = floaters.filter(func(f): return f.life > 0)
	_sync_scene()

func _update_play(dt: float) -> void:
	ext.update(self, dt)
	attack_time = maxf(0, attack_time - dt)
	attack_cooldown = maxf(0, attack_cooldown - dt)
	combo_window = maxf(0, combo_window - dt)
	dodge_cooldown = maxf(0, dodge_cooldown - dt)
	invincible = maxf(0, invincible - dt)
	message_time = maxf(0, message_time - dt)
	var direction = float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT))
	moving = false
	if dodge_time > 0:
		dodge_time = maxf(0, dodge_time - dt)
		x += facing * 580 * dt
	elif attack_time <= 0 and ext.heavy_time <= 0:
		moving = direction != 0
		x += direction * 215 * dt
		if direction != 0:
			facing = direction
	x = _clamp_player_x(x)
	if phase in [3, 4, 6] and not enemies.is_empty():
		combat_seconds += dt
	if phase == 0 and x >= level.flag_origin.x:
		phase = 1
		_banner("按 J 挥刀，击中前方训练靶两次")
	if phase == 1 and attack_time > 0.1 and (level.dummy_origin.x - x) * facing > -24 and absf(x - level.dummy_origin.x) < 135:
		if tutorial_hits != swing_id:
			tutorial_hits = swing_id
			var count = int(get_meta("dummy_hits", 0)) + 1
			set_meta("dummy_hits", count)
			_sparks(level.dummy_origin.x, level.dummy_origin.y - 55, GOLD)
			if count >= 2:
				phase = 2
				_banner("按空格向前闪避，再向右迎战守军")
	if phase == 2 and dodge_time > 0:
		phase = 3
		_spawn_wave(1)
		_banner("第一阵 · 击退两名守军")
	for enemy in enemies:
		if enemy.hp <= 0:
			continue
		enemy.flash = maxf(0, enemy.flash - dt)
		if attack_time > 0.03 and enemy.last_swing != swing_id:
			var distance: float = (enemy.x - x) * facing
			if distance > -24 and distance < 145:
				enemy.last_swing = swing_id
				var damage = 2 if combo == 3 else 1
				enemy.hp -= damage
				ext.on_attack_hit(self, enemy, damage)
				enemy.flash = 0.15
				if not enemy.boss:
					enemy.x += facing * 20
				_sparks(enemy.x, enemy.y - 60, GOLD)
				floaters.append({"x": enemy.x, "y": enemy.y - 110, "life": 0.6, "text": "重斩 −2" if combo == 3 else "−1"})
				shake = 2.5 if combo < 3 else 5.0
				hit_stop = 0.035
				_tone(360, 0.055, 0.12)
				if enemy.boss and enemy.hp <= 0:
					_win()
					return
		if enemy.hp > 0:
			_update_enemy(enemy, dt)
		if state != "play":
			return
	enemies = enemies.filter(func(e): return e.hp > 0)
	if phase == 3 and enemies.is_empty():
		phase = 4
		_spawn_wave(2)
		_banner("第二阵 · 三名守军正在集结")
	elif phase == 4 and enemies.is_empty() and x > level.gate_x:
		phase = 5
		_begin_dialogue(story.boss, "play")

func _update_enemy(e: Dictionary, dt: float) -> void:
	e.timer -= dt
	var distance: float = absf(e.x - x)
	match e.mode:
		"approach":
			e.facing = signf(x - e.x)
			var reach = 145.0 if e.boss else 95.0
			if distance > reach:
				e.x += e.facing * (110 if e.boss else 90) * dt
			elif e.timer <= 0:
				var active = enemies.filter(func(other): return other.mode in ["windup", "strike"])
				if active.size() < 2:
					e.mode = "windup"
					e.move += 1
					var sweep: bool = e.boss and e.move % 2 == 0
					e.timer = (0.78 if e.hp <= 8 else 0.9) if sweep else (0.55 if e.boss and e.hp <= 8 else 0.65)
		"windup":
			if e.timer <= 0:
				e.mode = "strike"
				e.timer = 0.24
				e.struck = false
		"strike":
			var reach = 190.0 if e.boss else 120.0
			if e.boss and e.move % 2 != 0:
				e.x += e.facing * 390 * dt
			if not e.struck and (x - e.x) * e.facing > -25 and distance < reach:
				e.struck = true
				_hurt(e.facing, e)
			if e.timer <= 0:
				e.mode = "recover"
				e.timer = 0.85 if e.boss else 1.0
				e.combo_pending = e.boss and e.hp <= 8 and e.move % 3 == 0
		"recover":
			if e.combo_pending and e.timer < 0.35:
				e.combo_pending = false
				e.move = 2
				e.mode = "windup"
				e.timer = 0.55
			elif e.timer <= 0:
				e.mode = "approach"
				e.timer = 0.2

func _clamp_player_x(position_x: float) -> float:
	var left: float = level.world_left + 65 if phase < 6 else level.arena_min_x
	return clampf(position_x, left, level.world_right - 80)

func _hurt(direction: float, attacker: Dictionary = {}) -> void:
	if invincible > 0 or (dodge_time > 0.06 and dodge_time < 0.30) or state != "play":
		return
	if ext.absorb_damage(self, direction, attacker):
		return
	hp -= 1
	hits += 1
	invincible = 0.8
	x = _clamp_player_x(x + direction * 28)
	shake = 6
	hit_stop = 0.06
	_sparks(x, player_y - 60, RED)
	_tone(80, 0.10, 0.17)
	if hp <= 0:
		state = "dead"

func _win() -> void:
	phase = 7
	enemies.clear()
	_reset_effects()
	score = 600 + int(240.0 * hp / 6.0) + int(160.0 * clampf(1.0 - maxf(0, combat_seconds - 180) / 360.0, 0, 1))
	best = maxi(best, score)
	cleared = true
	_save()
	_begin_dialogue(story.ending, "victory")

func _save() -> void:
	var config = ConfigFile.new()
	config.set_value(SCORE_VERSION, "best", best)
	config.set_value(SCORE_VERSION, "cleared", cleared)
	config.set_value("settings", "muted", muted)
	config.save(save_path)

func _banner(text: String) -> void:
	message = text
	message_time = 5

func _sparks(px: float, py: float, color: Color) -> void:
	for i in 12:
		particles.append({"pos": Vector2(px, py), "vel": Vector2(randf_range(-130, 130), randf_range(-170, -20)), "life": randf_range(0.2, 0.5), "color": color})

func _tone(frequency: float, seconds: float, volume: float) -> void:
	if muted or tone_player == null:
		return
	var frames = int(seconds * 22050)
	var samples = PackedByteArray()
	samples.resize(frames * 2)
	for i in frames:
		var amplitude = sin(TAU * frequency * i / 22050.0) * volume * (1.0 - float(i) / frames)
		samples.encode_s16(i * 2, int(amplitude * 32767))
	var sound = AudioStreamWAV.new()
	sound.format = AudioStreamWAV.FORMAT_16_BITS
	sound.mix_rate = 22050
	sound.data = samples
	tone_player.stream = sound
	tone_player.play()


func _spawn_wave(wave: int) -> void:
	for spawn in level.wave_spawns(wave):
		_spawn(spawn.origin, spawn.view)

func _sync_scene() -> void:
	prologue.set_suspended(state != "prologue")
	prologue.set_muted(muted)
	if tone_player.playing and (muted or state in ["menu", "dead"] or phase == 7):
		tone_player.stop()
	tone_player.stream_paused = state != "play"
	level.present(self)
	ui.present(self)
