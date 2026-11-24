extends Control
## Authored HUD nodes display current combat state; this script never changes game rules.
var active = false
var reduced_motion = false
var damage_delay = 0.0
var last_hp = 6
var last_boss_hp = 16
var boss_visible = false
var last_state = ""

const FILLED = Color.WHITE
const EMPTY = Color("747766")

func present(game: Node) -> void:
	var new_session: bool = game.state == "play" and last_state not in ["play", "pause", "confirm"]
	active = game.state in ["play", "finishing"] and game.window_active
	reduced_motion = game.reduced_motion
	var health: int = clampi(game.hp, 0, 6)
	if health < last_hp and not new_session and not reduced_motion:
		damage_delay = 0.14
	else:
		if health > last_hp or new_session or reduced_motion:
			$Health/Trail.value = health
			damage_delay = 0.0
	$Health/HP.value = health
	$Health/HP.tooltip_text = "气血 %d / 6" % health
	$Health/LowHealth.visible = health > 0 and health <= 2
	last_hp = health
	$Extensions.visible = game.phase >= 3 and (game.phase < 7 or game.state == "finishing")
	for i in 4:
		$Extensions/Pips.get_child(i).self_modulate = FILLED if i < game.ext.resource else EMPTY
	$Extensions.tooltip_text = "义气 %d / %d" % [game.ext.resource, game.ext.RESOURCE_MAX]
	var ready: bool = game.ext.heavy_ready()
	$Extensions/Skill.modulate = Color.WHITE if ready else Color(0.68, 0.7, 0.61, 1)
	$Extensions/Skill/Ready.visible = ready
	$ObjectivePanel.visible = game.phase < 6
	$ObjectivePanel/Objective.text = ["前往旗标", "练习挥刀", "练习闪避", "击退第一阵守军", "清除守军，前往关门", "关前对话", "", ""][game.phase]
	if game.phase == 4 and game.enemies.is_empty(): $ObjectivePanel/Objective.text = "前往关门"
	$Controls/Backdrop.visible = game.phase < 3
	$Controls/Keys.visible = game.phase < 3
	$Controls/Keys.text = ["A / D  移动", "J  挥刀，连按三段", "SPACE  闪避"][mini(game.phase, 2)]
	$Controls/Dodge.visible = game.dodge_cooldown > 0.0
	$Mute.text = "开声" if game.muted else "静音"
	# Entry narration is already communicated by the boss name. Event/error messages remain.
	$Message.visible = game.message_time > 0.0 and game.phase >= 3 and not game.message.begins_with("孔秀 ·")
	$Message/Text.text = game.message
	var showing_boss: bool = (game.phase == 6 and not game.enemies.is_empty()) or (game.state == "finishing" and not game.defeated_boss.is_empty())
	$BossHealth.visible = showing_boss
	if showing_boss:
		var hp: int = maxi(0, game.enemies[0].hp) if game.phase == 6 else 0
		$BossHealth/Name.text = "孔秀 · 东岭守将"
		$BossHealth/Phase.visible = hp <= 8
		if not boss_visible or reduced_motion or hp > last_boss_hp: $BossHealth/Trail.value = hp
		$BossHealth/HP.value = hp
		last_boss_hp = hp
	boss_visible = showing_boss
	last_state = game.state
	set_process(active)

func _process(delta: float) -> void:
	if not active: return
	if damage_delay > 0.0:
		damage_delay = maxf(0.0, damage_delay - delta)
	else:
		$Health/Trail.value = move_toward($Health/Trail.value, $Health/HP.value, delta * 8.0)
	if boss_visible:
		$BossHealth/Trail.value = move_toward($BossHealth/Trail.value, $BossHealth/HP.value, delta * 14.0)
