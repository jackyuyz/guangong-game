extends Control
## Authored HUD nodes display current combat state; this script never changes game rules.
var active = false
var reduced_motion = false
var damage_delay = 0.0
var last_hp = 6
var last_boss_hp = 16
var boss_visible = false
var last_state = ""
var hint_phase = -1
var hint_alpha = 0.0
const HINT_FADE_TIME = 0.28

const FILLED = Color.WHITE
const EMPTY = Color("747766")

func present(game: Node) -> void:
	var new_session: bool = game.state == "play" and last_state not in ["play", "pause", "confirm"]
	active = game.state in ["play", "finishing", "dying"] and game.window_active
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
	_present_rest(game)
	$Extensions.tooltip_text = "义气 %d / %d" % [game.ext.resource, game.ext.RESOURCE_MAX]
	var ready: bool = game.state == "play" and game.ext.heavy_ready()
	$Extensions/Skill.modulate = Color.WHITE if ready else Color(0.68, 0.7, 0.61, 1)
	$Extensions/Skill/Ready.visible = ready
	$ObjectivePanel.visible = game.phase < 6
	$ObjectivePanel/Objective.text = ["前往旗标", "练习挥刀", "向右闪避", "击退第一阵守军", "清除守军，前往关门", "关前对话", "", ""][game.phase]
	if game.phase == 4 and game.enemies.is_empty(): $ObjectivePanel/Objective.text = "前往关门"
	var approach: bool = game.phase == 2 and game.tutorial_dodge_completed
	if approach: $ObjectivePanel/Objective.text = "向右前行"
	_present_hint(0 if approach else game.phase, new_session)
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
	if hint_phase >= 3 and hint_alpha > 0.0:
		hint_alpha = maxf(0.0, hint_alpha - delta / HINT_FADE_TIME)
		_paint_hint()
	if damage_delay > 0.0:
		damage_delay = maxf(0.0, damage_delay - delta)
	else:
		$Health/Trail.value = move_toward($Health/Trail.value, $Health/HP.value, delta * 8.0)
	if boss_visible:
		$BossHealth/Trail.value = move_toward($BossHealth/Trail.value, $BossHealth/HP.value, delta * 14.0)

func _present_hint(phase: int, reset: bool) -> void:
	if phase < 3:
		hint_alpha = 1.0
		$Controls/Hint/Content/Key1.text = ["A", "J", "SPACE"][phase]
		$Controls/Hint/Content/Key1.custom_minimum_size.x = 58.0 if phase == 2 else 30.0
		$Controls/Hint/Content/Key1.add_theme_font_size_override("font_size", 12 if phase == 2 else 16)
		$Controls/Hint/Content/Key2.visible = phase == 0
		$Controls/Hint/Content/Action.text = ["前行", "挥刀", "闪避"][phase]
		$Controls/Hint/Content.size.x = 0.0
		$Controls/Hint/Backdrop.size.x = $Controls/Hint/Content.get_combined_minimum_size().x + 56.0
	elif hint_phase < 0 or reduced_motion or reset:
		hint_alpha = 0.0
	hint_phase = phase
	_paint_hint()

func _paint_hint() -> void:
	$Controls/Hint.modulate.a = hint_alpha
	$Controls/Hint.visible = hint_alpha > 0.0

func _present_rest(game: Node) -> void:
	var recovering: bool = game.ext.rest_feedback > 0
	var age: float = game.ext.REST_FEEDBACK_TIME - game.ext.rest_feedback
	var weight = sin(clampf(age / game.ext.REST_FEEDBACK_TIME, 0, 1) * PI)
	$Health/RestGain.visible = recovering and not game.reduced_motion and game.hp > game.ext.rest_hp_before
	$Health/RestGain.position.x = $Health/HP.position.x + $Health/HP.size.x * game.ext.rest_hp_before / 6.0
	$Health/RestGain.size.x = $Health/HP.size.x * maxf(0, game.hp - game.ext.rest_hp_before) / 6.0
	$Health/RestGain.modulate.a = weight * .7
	if recovering and not game.reduced_motion:
		for i in 4:
			var pulse = maxf(0, 1.0 - absf(age - (.14 + i * .12)) / .17)
			$Extensions/Pips.get_child(i).self_modulate = Color(1 + pulse, 1 + pulse * .8, 1 + pulse * .35)
	$RestNotice.visible = game.ext.rest_notice > 0 and game.phase in [4, 5] and game.state in ["play", "pause", "confirm"]
	$RestNotice.modulate.a = minf(1, game.ext.rest_notice / .4)
	$RestNotice/Text.text = ("气血已满" if game.ext.rest_hp_before >= 6 else "气血回复") + " · 义气充盈"
