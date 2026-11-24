extends SceneTree
## Standalone checks for combat_extensions.gd against a minimal fake game.
## Run: Godot --headless --path godot --script scripts/extensions_test.gd
const Extensions = preload("res://scripts/combat_extensions.gd")

# Mirrors the slice of main.gd the module touches, including the agreed
# _hurt contract: existing guards first, then absorb_damage, then HP loss.
const FAKE_GAME = """
extends Node
var ext
var state = "play"
var phase = 3
var hp = 6
var x = 1000.0
var player_y = 440.0
var rest_x = 2060.0
var facing = 1.0
var enemies: Array[Dictionary] = []
var checkpoint: Dictionary = {}
var attack_time = 0.0
var attack_cooldown = 0.0
var dodge_time = 0.0
var dodge_cooldown = 0.0
var invincible = 0.0
var combat_seconds = 0.0
var hits = 0
var shake = 0.0
var hit_stop = 0.0
var banners: Array = []
var win_calls = 0

func _hurt(direction: float, attacker: Dictionary = {}) -> void:
	if invincible > 0 or (dodge_time > 0.06 and dodge_time < 0.30) or state != "play":
		return
	if ext.absorb_damage(self, direction, attacker):
		return
	hp -= 1
	hits += 1
	invincible = 0.8

func _win() -> void:
	win_calls += 1
	phase = 7
	enemies.clear()
	state = "dialogue"

func _banner(text: String) -> void:
	banners.append(text)

func _sparks(_px: float, _py: float, _color: Color) -> void:
	pass

func _tone(_frequency: float, _seconds: float, _volume: float) -> void:
	pass
"""

var fake_script: GDScript
var failures = 0

func _initialize() -> void:
	call_deferred("run")

func check(condition: bool, label: String) -> void:
	if not condition:
		push_error("FAIL: " + label)
		failures += 1
		return
	print("PASS: ", label)

func make_game() -> Node:
	var game: Node = fake_script.new()
	game.ext = Extensions.new()
	game.ext.reset()
	root.add_child(game)
	return game

func enemy(px: float, boss: bool = false, mode: String = "approach") -> Dictionary:
	var hp = 16 if boss else 2
	return {"x": px, "y": 440.0, "hp": hp, "max_hp": hp, "boss": boss, "mode": mode, "timer": 0.4,
		"facing": -1.0, "last_swing": -1, "flash": 0.0, "move": 1, "struck": mode == "strike",
		"combo_pending": false}

func run() -> void:
	fake_script = GDScript.new()
	fake_script.source_code = FAKE_GAME
	check(fake_script.reload() == OK, "fake game compiles")
	test_reset()
	test_guard_and_parry()
	test_guard_rules()
	test_boss_sweep()
	test_state_guards()
	test_resource_and_heavy()
	test_boss_lethal()
	test_rest_point()
	test_checkpoint_resource()
	test_status_text()
	print("EXTENSION CHECKS COMPLETE")
	for child in root.get_children():
		child.queue_free()
	await process_frame
	quit(1 if failures else 0)

func test_reset() -> void:
	var game = make_game()
	var ext = game.ext
	ext.resource = 3
	ext.guard_timer = 0.2
	ext.guard_cooldown = 0.5
	ext.heavy_cooldown = 0.5
	ext.rest_used = true
	ext.reset()
	check(ext.resource == 0 and ext.guard_timer == 0 and ext.guard_cooldown == 0 \
		and ext.heavy_cooldown == 0 and not ext.rest_used, "reset clears transient state")

func test_guard_and_parry() -> void:
	var game = make_game()
	var ext = game.ext
	var foe = enemy(1100, false, "strike")
	game.enemies.append(foe)
	check(ext.handle_key(game, KEY_K) and ext.is_guarding() and ext.in_parry_window(), "K raises guard in parry window")
	ext.update(game, 0.1)
	game._hurt(foe.facing, foe)
	check(game.hp == 6 and ext.parries == 1 and ext.resource == ext.PARRY_GAIN, "early hit is a perfect parry and grants 义气")
	check(foe.mode == "recover" and is_equal_approx(foe.timer, ext.PARRY_STAGGER_GUARD) and not foe.combo_pending, "parry staggers the attacker")
	check(ext.guard_cooldown == 0.0, "parry clears guard cooldown")
	# Plain block: late in the stance.
	ext.reset()
	foe.mode = "strike"
	ext.handle_key(game, KEY_K)
	ext.update(game, 0.25)
	var x_before: float = game.x
	game._hurt(foe.facing, foe)
	check(game.hp == 6 and ext.blocks == 1 and ext.resource == 0 and ext.parries == 0, "late hit is a plain block with no 义气")
	check(game.x < x_before and foe.mode == "strike", "block pushes back and does not stagger")
	# Stance expiry.
	ext.update(game, 0.2)
	game._hurt(foe.facing, foe)
	check(not ext.is_guarding() and game.hp == 5, "expired guard lets damage through")

func test_guard_rules() -> void:
	var game = make_game()
	var ext = game.ext
	ext.handle_key(game, KEY_K)
	ext.update(game, 0.3)
	ext.update(game, 0.2)
	check(not ext.is_guarding() and ext.guard_cooldown > 0, "guard ends before cooldown")
	ext.handle_key(game, KEY_K)
	check(not ext.is_guarding(), "K on cooldown does nothing")
	ext.update(game, 0.2)
	game.attack_time = 0.1
	ext.handle_key(game, KEY_K)
	check(not ext.is_guarding(), "no guard mid-swing")
	game.attack_time = 0
	game.dodge_time = 0.2
	ext.handle_key(game, KEY_K)
	check(not ext.is_guarding(), "no guard mid-dodge")
	game.dodge_time = 0
	ext.handle_key(game, KEY_K)
	game.facing = 1.0
	game._hurt(1.0) # Attack from behind travels the same way Guan Yu faces.
	check(game.hp == 5, "guard does not cover the back")
	game.invincible = 0
	ext.reset()
	ext.handle_key(game, KEY_K)
	game.attack_cooldown = 0.2
	check(not ext.handle_key(game, KEY_J) and ext.is_guarding(), "J on cooldown keeps the guard and is not consumed")
	game.attack_cooldown = 0
	ext.handle_key(game, KEY_J)
	check(not ext.is_guarding(), "starting a swing drops the guard")
	ext.reset()
	ext.handle_key(game, KEY_K)
	check(not ext.handle_key(game, KEY_SPACE) and not ext.is_guarding(), "dodge drops the guard and is not consumed")

func test_boss_sweep() -> void:
	var game = make_game()
	var ext = game.ext
	game.phase = 6
	var boss = enemy(1150, true, "strike")
	boss.move = 2
	game.enemies.append(boss)
	ext.handle_key(game, KEY_K)
	ext.update(game, 0.25)
	game._hurt(boss.facing, boss)
	check(game.hp == 5 and not ext.is_guarding() and ext.guard_broken > 0, "boss sweep breaks a plain guard")
	game.invincible = 0
	ext.reset()
	boss.mode = "strike"
	boss.struck = true
	ext.handle_key(game, KEY_K)
	ext.update(game, 0.05)
	game._hurt(boss.facing, boss)
	check(game.hp == 5 and boss.mode == "recover" and is_equal_approx(boss.timer, ext.PARRY_STAGGER), "boss sweep can be perfectly parried")
	ext.reset()
	boss.mode = "strike"
	boss.move = 3
	ext.handle_key(game, KEY_K)
	ext.update(game, 0.3)
	game._hurt(boss.facing, boss)
	check(game.hp == 5 and ext.blocks == 1, "boss thrust can be blocked")

func test_state_guards() -> void:
	var game = make_game()
	var ext = game.ext
	ext.resource = 4
	game.enemies.append(enemy(1100))
	for state in ["menu", "finishing", "pause", "confirm", "dialogue", "dead", "victory"]:
		game.state = state
		var consumed = ext.handle_key(game, KEY_K) or ext.handle_key(game, KEY_L) or ext.handle_key(game, KEY_E)
		check(not consumed and not ext.is_guarding() and ext.resource == 4 and game.enemies[0].hp == 2, "no actions in " + state)
	game.state = "play"
	ext.handle_key(game, KEY_K)
	game.state = "pause"
	ext.update(game, 1.0)
	check(ext.guard_timer == ext.GUARD_TIME and ext.guard_cooldown == ext.GUARD_COOLDOWN, "pause freezes timers")
	check(not ext.absorb_damage(game, -1.0), "no absorb outside play")
	ext.on_attack_hit(game, game.enemies[0], 1)
	check(ext.resource == 4, "no 义气 gain outside play")

func test_resource_and_heavy() -> void:
	var game = make_game()
	var ext = game.ext
	var near = enemy(1100)
	var far = enemy(1300)
	game.enemies.append(near)
	game.enemies.append(far)
	ext.handle_key(game, KEY_L)
	check(near.hp == 2 and ext.heavy_time == 0, "L needs full 义气")
	for i in 6:
		ext.on_attack_hit(game, near, 1)
	check(ext.resource == ext.RESOURCE_MAX, "义气 caps at max")
	game.facing = -1.0
	check(ext.handle_key(game, KEY_L) and ext.resource == 4 and near.hp == 2, "L with no target keeps 义气")
	game.facing = 1.0
	ext.handle_key(game, KEY_L)
	check(ext.resource == 0 and ext.heavy_cooldown > 0 and game.invincible >= ext.HEAVY_TIME, "L spends 义气, starts cooldown and grants i-frames")
	ext.update(game, ext.HEAVY_CONTACT)
	check(game.enemies.size() == 1 and game.enemies[0] == far and far.hp == 2, "L kills in range, spares out of range, removes the dead")
	game.x = 1150
	ext.resource = 4
	ext.handle_key(game, KEY_L)
	check(far.hp == 2 and ext.resource == 4, "L on cooldown does nothing")
	ext.update(game, ext.HEAVY_COOLDOWN + 0.01)
	game.dodge_time = 0.2
	ext.handle_key(game, KEY_L)
	check(far.hp == 2, "no L mid-dodge")
	game.dodge_time = 0
	ext.handle_key(game, KEY_L)
	ext.update(game, ext.HEAVY_CONTACT)
	check(game.enemies.is_empty() and game.win_calls == 0, "guard kill does not win")

func test_boss_lethal() -> void:
	var game = make_game()
	var ext = game.ext
	game.phase = 6
	var boss = enemy(1100, true, "windup")
	game.enemies.append(boss)
	ext.resource = 4
	ext.handle_key(game, KEY_L)
	ext.update(game, ext.HEAVY_CONTACT)
	check(boss.hp == 13 and boss.mode == "recover" and game.win_calls == 0 and game.enemies.size() == 1, "L hurts and staggers the boss without winning")
	boss.hp = 2
	ext.resource = 4
	ext.update(game, ext.HEAVY_COOLDOWN + 0.01)
	game.invincible = 0
	ext.handle_key(game, KEY_L)
	ext.update(game, ext.HEAVY_CONTACT)
	check(game.win_calls == 1 and game.phase == 7 and game.enemies.is_empty(), "lethal L on the boss wins")
	var hp: int = game.hp
	game._hurt(-1.0)
	ext.resource = 4
	check(not ext.handle_key(game, KEY_L) and game.hp == hp and game.win_calls == 1, "nothing lands after victory")

func test_rest_point() -> void:
	var game = make_game()
	var ext = game.ext
	game.phase = 4
	game.hp = 3
	game.x = game.rest_x
	game.enemies.append(enemy(1900))
	check(not ext.handle_key(game, KEY_E), "rest closed while guards remain")
	game.enemies.clear()
	ext.update(game, 0.01)
	ext.update(game, 0.01)
	check(game.banners.count(game.banners[-1]) == 1 and "E" in game.banners[-1], "rest point announced once")
	game.x = game.rest_x + ext.REST_RANGE + 10
	check(not ext.handle_key(game, KEY_E), "rest needs proximity")
	game.x = game.rest_x
	check(ext.handle_key(game, KEY_E) and game.hp == 4 and ext.resource == ext.RESOURCE_MAX, "rest heals one and fills 义气")
	check(not ext.handle_key(game, KEY_E) and game.hp == 4, "rest is one-time")
	ext.reset()
	game.hp = 6
	ext.handle_key(game, KEY_E)
	check(game.hp == 6, "rest heal caps at six")
	ext.reset()
	game.phase = 3
	check(not ext.handle_key(game, KEY_E), "rest only after wave two")

func test_checkpoint_resource() -> void:
	var game = make_game()
	var ext = game.ext
	game.phase = 4
	ext.update(game, 0.01)
	ext.resource = 3
	game.phase = 6
	game.checkpoint = {"hp": 4, "seconds": 0.0, "hits": 0}
	ext.update(game, 0.01)
	check(ext.checkpoint_resource == 3, "boss entry snapshots 义气")
	ext.resource = 0
	ext.reset()
	ext.update(game, 0.01)
	check(ext.resource == 3, "boss retry restores checkpoint 义气")
	ext.resource = 1
	ext.update(game, 0.01)
	check(ext.resource == 1, "restore happens only on entry")
	game.checkpoint.clear()
	game.phase = 3
	ext.reset()
	ext.update(game, 0.01)
	check(ext.checkpoint_resource == -1 and ext.resource == 0, "new run or restart drops the snapshot")

func test_status_text() -> void:
	var game = make_game()
	var ext = game.ext
	var text: String = ext.status_text(game)
	check("K" in text and "L" in text and "0/4" in text and not text.contains("E "), "status names keys and 义气")
	ext.resource = 4
	game.phase = 4
	game.x = game.rest_x
	text = ext.status_text(game)
	check("就绪" in text and "E 茶摊" in text and text.length() <= 70, "status shows ready and nearby rest")
	ext.handle_key(game, KEY_K)
	check("架刀" in ext.status_text(game), "status shows guard")
