extends RefCounted
## Combat extensions: K guard / parry, L 偃月斩 powered by 义气, E roadside tea stall.
## Pure logic module; main.gd owns input routing, damage, drawing and deaths.
## See docs/design/combat-extensions.md for controls, tuning and integration hooks.

const GUARD_TIME = 0.42 # K stance length.
const PARRY_WINDOW = 0.18 # First part of the stance; a hit here is a perfect parry.
const GUARD_COOLDOWN = 0.65 # From the K press; a successful parry clears it.
const PARRY_STAGGER = 1.1 # Attacker recover time after being parried (boss / guard).
const PARRY_STAGGER_GUARD = 1.25
const BLOCK_PUSH = 14.0
const RESOURCE_MAX = 4 # 义气 pips.
const HIT_GAIN = 1 # Per valid J hit.
const PARRY_GAIN = 2
const HEAVY_COST = 4
const HEAVY_DAMAGE = 3
const HEAVY_RANGE = 220.0 # Forward reach; slightly beyond J's 145.
const HEAVY_BACK = 30.0 # Also catches enemies overlapping from behind.
const HEAVY_TIME = 0.35 # Pose time; also the heroic invincibility window.
const HEAVY_CONTACT = 1.0 / 9.0 # Second attack frame, matching the authored heavy animation.
const HEAVY_COOLDOWN = 0.9
const HEAVY_STAGGER = 0.9
const REST_RANGE = 85.0
const REST_HEAL = 1
const REST_FEEDBACK_TIME = 0.8
const JADE = Color("72b69a")
const GOLD = Color("dfbc76")
const PAPER = Color("f3e8cd")
const RED = Color("cf6950")

# Readable public state for poses and effects.
var guard_timer = 0.0 # > 0 while the K stance is up.
var guard_age = 0.0 # Seconds since K was pressed.
var guard_cooldown = 0.0
var parry_flash = 0.0 # > 0 briefly after a perfect parry.
var block_flash = 0.0 # > 0 briefly after a plain block.
var guard_broken = 0.0 # > 0 briefly after a boss sweep broke a plain guard.
var resource = 0 # 义气, 0..RESOURCE_MAX.
var heavy_time = 0.0 # > 0 while the 偃月斩 pose plays.
var heavy_cooldown = 0.0
var heavy_pending = false
var rest_used = false
var rest_announced = false
var rest_feedback = 0.0
var rest_notice = 0.0
var rest_hp_before = 6
var rest_qi_before = 0
var parries = 0
var blocks = 0
# Boss-checkpoint snapshot of 义气 (-1 = none). Kept across reset() so a boss
# retry restores what the player entered the gate with; cleared once main's
# own checkpoint is empty (new run, restart from wave one, menu).
var checkpoint_resource = -1
var _last_phase = -1

func reset() -> void:
	guard_timer = 0.0
	guard_age = 0.0
	guard_cooldown = 0.0
	parry_flash = 0.0
	block_flash = 0.0
	guard_broken = 0.0
	resource = 0
	heavy_time = 0.0
	heavy_pending = false
	heavy_cooldown = 0.0
	rest_used = false
	rest_announced = false
	rest_feedback = 0.0
	rest_notice = 0.0
	parries = 0
	blocks = 0
	_last_phase = -1

func is_guarding() -> bool:
	return guard_timer > 0.0

func in_parry_window() -> bool:
	return guard_timer > 0.0 and guard_age <= PARRY_WINDOW

func heavy_ready() -> bool:
	return resource >= HEAVY_COST and heavy_cooldown <= 0.0

func can_rest(game: Node) -> bool:
	return not rest_used and game.state == "play" and game.phase == 4 \
		and game.enemies.is_empty() and absf(game.x - game.rest_x) <= REST_RANGE \
		and game.attack_time <= 0 and game.dodge_time <= 0 and heavy_time <= 0

func update(game: Node, dt: float) -> void:
	if game.state != "play":
		return
	rest_feedback = maxf(0, rest_feedback - dt)
	rest_notice = maxf(0, rest_notice - dt)
	if guard_timer > 0.0:
		guard_age += dt
		guard_timer = maxf(0.0, guard_timer - dt)
	guard_cooldown = maxf(0.0, guard_cooldown - dt)
	parry_flash = maxf(0.0, parry_flash - dt)
	block_flash = maxf(0.0, block_flash - dt)
	guard_broken = maxf(0.0, guard_broken - dt)
	heavy_time = maxf(0.0, heavy_time - dt)
	if heavy_pending and heavy_time <= HEAVY_TIME - HEAVY_CONTACT:
		heavy_pending = false
		_heavy_contact(game)
		if game.state != "play":
			return
	heavy_cooldown = maxf(0.0, heavy_cooldown - dt)
	if game.checkpoint.is_empty():
		checkpoint_resource = -1
	if game.phase == 6 and _last_phase != 6 and not game.checkpoint.is_empty():
		if checkpoint_resource < 0:
			checkpoint_resource = resource
		else:
			resource = checkpoint_resource
	_last_phase = game.phase
	if not rest_used and not rest_announced and game.phase == 4 and game.enemies.is_empty():
		rest_announced = true
		game._banner("道旁茶摊就在关前 · 走近按 E 歇脚")

func handle_key(game: Node, key: int) -> bool:
	if game.state != "play":
		return false
	if rest_feedback > 0 and key in [KEY_J, KEY_SPACE, KEY_K, KEY_L]:
		return true
	if heavy_time > 0 and key in [KEY_J, KEY_SPACE, KEY_K, KEY_L]:
		return true
	match key:
		KEY_K:
			if guard_cooldown <= 0.0 and game.attack_time <= 0.0 and game.dodge_time <= 0.0:
				guard_timer = GUARD_TIME
				guard_age = 0.0
				guard_cooldown = GUARD_COOLDOWN
				game._tone(240, 0.05, 0.05)
			return true
		KEY_L:
			_heavy(game)
			return true
		KEY_E:
			if can_rest(game):
				rest_used = true
				rest_feedback = REST_FEEDBACK_TIME
				rest_notice = 1.8
				rest_hp_before = game.hp
				rest_qi_before = resource
				guard_timer = 0.0
				game.hp = mini(6, game.hp + REST_HEAL)
				resource = RESOURCE_MAX
				return true
			return false
		KEY_J:
			# Swinging drops the stance, but only if the swing will actually start.
			if game.attack_cooldown <= 0.0 and game.dodge_time <= 0.0:
				guard_timer = 0.0
		KEY_SPACE:
			if game.dodge_cooldown <= 0.0 and game.attack_time <= 0.0:
				guard_timer = 0.0
	return false

func _heavy(game: Node) -> void:
	if not heavy_ready() or game.dodge_time > 0.0:
		return
	var targets: Array = []
	for enemy in game.enemies:
		var distance: float = (enemy.x - game.x) * game.facing
		if enemy.hp > 0 and distance > -HEAVY_BACK and distance < HEAVY_RANGE:
			targets.append(enemy)
	if targets.is_empty():
		# No whiffs: keep 义气 and say why.
		game._tone(110, 0.06, 0.05)
		return
	resource -= HEAVY_COST
	game.attack_time = 0.0
	heavy_time = HEAVY_TIME
	heavy_pending = true
	heavy_cooldown = HEAVY_COOLDOWN
	guard_timer = 0.0
	game.invincible = maxf(game.invincible, HEAVY_TIME)
	game._tone(150, 0.16, 0.14)

func _heavy_contact(game: Node) -> void:
	game.shake = 7.0
	game.hit_stop = 0.07
	var boss_down = false
	for enemy in game.enemies:
		var distance: float = (enemy.x - game.x) * game.facing
		if enemy.hp <= 0 or distance <= -HEAVY_BACK or distance >= HEAVY_RANGE:
			continue
		enemy.hp -= HEAVY_DAMAGE
		enemy.flash = 0.2
		game._sparks(enemy.x, enemy.y - 60, GOLD)
		if enemy.hp <= 0:
			boss_down = boss_down or enemy.boss
		else:
			_stagger(enemy, HEAVY_STAGGER)
	if boss_down:
		game._win()
		return
	game.enemies = game.enemies.filter(func(e): return e.hp > 0)
	game._banner("偃月斩！")

func _stagger(enemy: Dictionary, seconds: float) -> void:
	enemy.mode = "recover"
	enemy.recover_age = 0.0
	enemy.settling = false
	enemy.timer = seconds
	enemy.combo_pending = false
	enemy.struck = true

func absorb_damage(game: Node, direction: float, attacker: Dictionary = {}) -> bool:
	if game.state != "play" or guard_timer <= 0.0:
		return false
	# The guard only covers the front: the attack must come toward Guan Yu's face.
	if game.facing * direction >= 0.0:
		return false
	if in_parry_window():
		parries += 1
		resource = mini(RESOURCE_MAX, resource + PARRY_GAIN)
		guard_cooldown = 0.0
		parry_flash = 0.25
		if not attacker.is_empty():
			_stagger(attacker, PARRY_STAGGER if attacker.boss else PARRY_STAGGER_GUARD)
			attacker.flash = 0.15
		game.hit_stop = 0.08
		game.shake = 3.0
		game._sparks(game.x + game.facing * 40, game.player_y - 70, PAPER)
		game._tone(660, 0.09, 0.12)
		game._banner("弹反！破绽已现")
		return true
	if not attacker.is_empty() and attacker.boss and attacker.move % 2 == 0:
		# Kong Xiu's sweep breaks a plain guard; only a perfect parry or a dodge works.
		guard_timer = 0.0
		guard_broken = 0.4
		game._banner("横扫破防 · 须精准弹反或闪避")
		return false
	blocks += 1
	block_flash = 0.2
	game.x += direction * BLOCK_PUSH
	game.shake = 2.0
	game._sparks(game.x + game.facing * 30, game.player_y - 70, GOLD)
	game._tone(300, 0.06, 0.08)
	return true

func on_attack_hit(game: Node, _enemy: Dictionary, _damage: int) -> void:
	if game.state != "play":
		return
	var before = resource
	resource = mini(RESOURCE_MAX, resource + HIT_GAIN)
	if before < HEAVY_COST and resource >= HEAVY_COST:
		game._tone(520, 0.08, 0.07)

func status_text(game: Node) -> String:
	var guard = "K 格挡·弹反"
	if guard_timer > 0.0:
		guard = "K 架刀中"
	elif guard_cooldown > 0.0:
		guard = "K 回架…"
	var heavy = "L 偃月斩 义气 %d/%d" % [resource, RESOURCE_MAX]
	if heavy_ready():
		heavy += " 就绪"
	elif resource >= HEAVY_COST:
		heavy += " 冷却"
	var text = guard + "   " + heavy
	if can_rest(game):
		text += "   E 茶摊歇脚"
	return text
