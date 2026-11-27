extends "res://scripts/luoyang_prototype.gd"
## Chapter presentation reuses the tested road/input blockout. Host owns persistence.
signal return_requested
signal cleared(result: Dictionary)
signal preferences_changed(sound_muted: bool, reduce_motion: bool)
const ChapterModel = preload("res://scripts/luoyang_chapter_model.gd")
const ArtBarricade = preload("res://scenes/luoyang/barricade.tscn")
const ArtArrow = preload("res://scenes/luoyang/arrow.tscn")
var art = preload("res://scripts/luoyang_art.gd").new()
const CAPTIONS = {
	"intro": ["洛阳关前", "韩福阻路，孟坦出战。\n孟坦拨马退去，关羽策马追赶。"],
	"meng_strike": ["追上孟坦", "赤兔疾驰，关羽追及孟坦，一刀斩落。"],
	"ambush": ["回马遭伏", "韩福从门边放出暗箭，射中关羽左臂。\n关羽负伤，仍策马冲向城门。"],
	"han_strike": ["冲门斩韩福", "关羽飞马近前，挥刀击败韩福。"],
	"ending": ["束伤前行", "关羽束住箭伤，接应二位夫人的车仗。\n一行继续前往汜水关。"],
	"fall": ["止步洛阳", ""],
	"escape": ["孟坦逃脱", ""],
	"culture": ["洛阳 · 故事回顾", "孟坦佯败诱敌，却被快马追上；韩福门前暗箭，关羽负伤仍进。\n据《三国演义》第二十七回改编。三车道、连射为玩法设计，非历史复原。"]}
var embedded = false
var reported_victory = false
var previous_phase = ""
var exit_confirmation = false
var help_open = false
var settings_open = false
var help_from_settings = false
var window_active = true
var result_details = false
var save_notice = ""
@onready var story_panel: Control = $UI/Story

func _init() -> void:
	model = ChapterModel.new()

func _ready() -> void:
	super._ready()
	$UI/Story/Advance.pressed.connect(_advance_story)
	$UI/Culture/Card/Advance.pressed.connect(_advance_story)
	$UI/Overlay/Panel/SettingsAction.pressed.connect(_open_settings)
	var settings = $UI/Overlay/Settings
	settings.get_node("Close").pressed.connect(_close_settings)
	settings.get_node("Help").pressed.connect(_show_help.bind(true))
	settings.get_node("Sound/On").pressed.connect(_set_sound.bind(false))
	settings.get_node("Sound/Off").pressed.connect(_set_sound.bind(true))
	settings.get_node("Motion/On").pressed.connect(_set_motion.bind(true))
	settings.get_node("Motion/Off").pressed.connect(_set_motion.bind(false))
	if embedded:
		begin_chapter()

func begin_chapter() -> void:
	settings_open = false
	help_open = false
	exit_confirmation = false
	$UI/Overlay/Settings.hide()
	$UI/Overlay/Panel.show()
	reported_victory = false
	previous_phase = ""
	model.start("chapter")
	_close_overlay()
	_sync_world()

func apply_preferences(sound_muted: bool, reduce_motion: bool) -> void:
	muted = sound_muted
	reduced_motion = reduce_motion
	$UI/Sound.text = "声音 关" if muted else "声音 开"
	$UI/Overlay/Panel/Motion.set_pressed_no_signal(reduced_motion)
	_sync_world()

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key = event.physical_keycode if event.physical_keycode else event.keycode
		if overlay.visible and overlay_guard > 0.0:
			get_viewport().set_input_as_handled()
			return
		if settings_open:
			if key in [KEY_ESCAPE, KEY_P]: _close_settings()
			else: $UI/Overlay/Settings.handle_key(event)
			get_viewport().set_input_as_handled()
			return
		if exit_confirmation or help_open:
			if key in [KEY_ESCAPE, KEY_P]:
				if exit_confirmation:
					_cancel_exit()
				else:
					_close_help()
				get_viewport().set_input_as_handled()
				return
		if overlay.visible and key in [KEY_TAB, KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT, KEY_A, KEY_D]:
			if key in [KEY_TAB, KEY_UP, KEY_DOWN]: _cycle_focus(-1 if event.shift_pressed or key == KEY_UP else 1)
			get_viewport().set_input_as_handled()
			return
		if model.state in ["story", "culture"]:
			if key in [KEY_ESCAPE, KEY_P]:
				_toggle_pause()
				get_viewport().set_input_as_handled()
				return
			if key in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
				_advance_story()
				get_viewport().set_input_as_handled()
				return
	super._input(event)

func _process(delta: float) -> void:
	if model.state == "running":
		# Parent handles real key edges, bounded queuing, common cues and hazards.
		super._process(delta)
	else:
		overlay_guard = maxf(0.0, overlay_guard - delta)
		if model.state == "story":
			model.step(minf(delta, 0.25))
			_sync_world()
		elif model.state == "culture":
			$UI/Story/Advance.disabled = overlay_guard > 0.0
			$UI/Culture/Card/Advance.disabled = overlay_guard > 0.0
	_handle_chapter_events()
	if previous_phase != model.phase:
		previous_phase = model.phase
		_clear_input()
		feedback_time = 0.0
		overlay_guard = 0.25
		_sync_world()
	if model.state == "failed" and not overlay.visible:
		_show_result()
	_sync_interface()

func _handle_chapter_events() -> void:
	# The parent drains presentation events during gameplay; state is the durable signal.
	if model.victory_locked and not reported_victory:
		reported_victory = true
		cleared.emit(model.result())
	model.events.clear()

func _advance_story() -> void:
	if overlay_guard > 0.0 or model.state not in ["story", "culture"]:
		return
	if model.state == "culture":
		model.finish_culture()
		_show_result()
	else:
		model.advance_story(model.phase)
	_clear_input()
	overlay_guard = 0.25
	_sync_world()

func _sync_world() -> void:
	super._sync_world()
	var phase: String = model.phase
	var story_state: bool = model.state == "story" or (model.state == "paused" and model.resume_kind == "story")
	var active: bool = model.state in ["running", "story", "culture", "paused"]
	$UI/Title.text = "洛阳关"
	$UI/Keys.text = "换道" if phase == "tutorial" else "锁定后换道"
	$UI/Stage.text = {"tutorial": "左右换道", "chase": "追孟坦", "sprint": "带伤冲门", "escape": "孟坦逃脱", "ending": "束伤离关"}.get(phase, "追孟坦，躲韩福")
	if phase == "chase":
		$UI/Stage.text = "追孟坦 · 相距 %d" % ceili(maxf(0.0, model.gap - ChapterModel.CATCH_GAP))
		$UI/Progress.value = clampf((ChapterModel.INITIAL_GAP - model.gap) / (ChapterModel.INITIAL_GAP - ChapterModel.CATCH_GAP) * 100.0, 0.0, 100.0)
		if model.elapsed >= ChapterModel.CHASE_LIMIT - art.finale.WARNING_SECONDS:
			$UI/Warning.text = "岔口将近 · 孟坦即将逃脱"
			$UI/WarningBacking.show()
	elif phase == "sprint":
		$UI/Progress.value = model.elapsed / ChapterModel.SPRINT_SECONDS * 100.0
	else:
		$UI/Progress.value = 0.0
	$UI/Pause.disabled = model.state not in ["running", "story", "culture", "paused"]
	$World/MengTan.visible = active and phase in ["tutorial", "chase"]
	if phase in ["tutorial", "chase"]:
		$World/MengTan.position = road.project(model.pursuer.lane, model.gap)
		$World/MengTan.scale = Vector2.ONE * road.factor(model.gap)
		$World/MengTan.z_index = int(109.0 - model.gap)
	var approach = clampf(model.elapsed / ChapterModel.SPRINT_SECONDS, 0.0, 1.0) if phase == "sprint" else 0.0
	$World/Gate.position = Vector2(480, 159).lerp($DoorArrival.position, approach)
	$World/Gate.scale = Vector2.ONE * lerpf(0.12, 0.22, approach)
	rider.visible = (not story_state or phase == "fall") and phase != "culture"
	$Cutscene.visible = story_state and phase != "fall"
	story_panel.visible = model.state == "story"
	story_panel.modulate = Color.WHITE
	if model.state in ["story", "culture"]:
		var caption: Array = CAPTIONS.get(phase, ["", ""])
		var timed_caption: Array = art.story.caption(phase, model.phase_clock)
		if not timed_caption.is_empty(): caption = timed_caption
		var finale_caption: Array = art.finale.caption(phase, model.phase_clock)
		if not finale_caption.is_empty(): caption = finale_caption
		$UI/Story/Title.text = caption[0]
		$UI/Story/Text.text = caption[1] if phase != "fall" else model.failure_reason
		$UI/Story/Advance.visible = phase not in ["fall", "escape"]
		$UI/Story/Advance.text = "查看结算" if phase == "culture" else "跳过  Enter"
		$UI/Story/Advance.disabled = overlay_guard > 0.0
		$UI/Story/Advance.focus_mode = Control.FOCUS_NONE
	$UI/SaveNotice.text = save_notice
	$UI/Keys.visible = save_notice.is_empty() and model.state == "running" and (phase == "tutorial" or (phase == "sprint" and model.elapsed < 5.5))
	$UI/Footer.visible = not save_notice.is_empty()
	art.update(self)
	_sync_arrow_tells()
	_sync_interface()
	if OS.has_feature("web"):
		var state_name: String = {"ready": "选择模式", "running": "闯关中", "story": "剧情中", "paused": "已暂停", "culture": "故事回顾", "failed": "失败", "complete": "洛阳已过"}.get(model.state, "")
		var text = "洛阳关。%s。%s。气血%d。%s。%s" % [state_name, $UI/Stage.text, model.hp, ["左道", "中道", "右道"][clampi(roundi(model.lane), -1, 1) + 1], $UI/Warning.text]
		if CAPTIONS.has(phase): text += "。" + $UI/Story/Title.text + "。" + $UI/Story/Text.text
		var nearest = 71.0
		for h in model.hazards:
			if h.kind == "barricade" and not h.resolved:
				nearest = minf(nearest, h.distance)
		var blocked: Array[String] = []
		for h in model.hazards:
			if not h.resolved and h.kind == "barricade" and absf(h.distance - nearest) < 0.2:
				blocked.append(["左道", "中道", "右道"][h.lane + 1])
			elif not h.resolved and h.kind == "arrow" and h.phase != "aim":
				text += "。锁定" + ["左道", "中道", "右道"][h.lane + 1]
		if not blocked.is_empty(): text += "。前方拒马：" + "、".join(blocked)
		JavaScriptBridge.eval("document.getElementById('canvas').setAttribute('aria-label', %s)" % JSON.stringify(text))

func _show_menu() -> void:
	help_open = false
	settings_open = false
	exit_confirmation = false
	$UI/Overlay/Panel.show()
	$UI/Overlay/Settings.hide()
	super._show_menu()
	title.text = "洛阳关"
	description.text = "追孟坦，躲韩福。"
	buttons[0].text = "策马闯关"
	buttons[1].text = "操作指南"
	buttons[1].show()
	buttons[2].visible = embedded
	buttons[2].text = "返回旅图"
	_sync_world()

func _overlay_action(index: int) -> void:
	if overlay_guard > 0.0 or settings_open:
		return
	if exit_confirmation:
		if index == 0:
			_leave()
		else:
			_cancel_exit()
		return
	if help_open:
		_close_help()
		return
	match model.state:
		"ready":
			if index == 0:
				begin_chapter()
			elif index == 1:
				_show_help()
			else: _leave()
		"paused":
			if index == 0: _toggle_pause()
			elif index == 1:
				if model.checkpoint.is_empty() or model.victory_locked:
					begin_chapter()
				else: _retry()
			else: _confirm_exit()
		"failed":
			if index == 0: _retry()
			elif index == 1: begin_chapter()
			else: _leave()
		"complete":
			if index == 0: _leave()
			elif index == 1:
				result_details = not result_details
				_paint_result_details()
			else: begin_chapter()
func _toggle_pause() -> void:
	if overlay_guard > 0.0:
		return
	if model.state in ["running", "story", "culture"]:
		model.pause()
		_clear_input()
		overlay.show()
		story_panel.hide()
		_show_pause_panel()
		audio.stream_paused = true
		overlay_guard = 0.15
	elif model.state == "paused":
		model.resume()
		_close_overlay()
	_sync_world()

func _pause_for_focus_loss() -> void:
	if model.state in ["running", "story", "culture"]:
		overlay_guard = 0.0
		_toggle_pause()

func _show_result() -> void:
	_clear_input()
	overlay.show()
	story_panel.hide()
	overlay_guard = 0.25
	title.text = "洛阳已过" if model.victory_locked else model.failure_reason
	result_details = false
	description.text = "" if not model.victory_locked else "双将已斩，车仗离关。"
	buttons[0].text = ("返回旅图" if embedded else "返回开场") if model.victory_locked else ("重试冲门" if model.wounded else "重追孟坦")
	buttons[1].text = "查看战绩" if model.victory_locked else "从头开始"
	buttons[1].show()
	buttons[2].show()
	buttons[2].text = "再次挑战" if model.victory_locked else ("返回旅图" if embedded else "返回开场")
	buttons[0].grab_focus()
	_sync_world()

func _retry() -> void:
	audio.stop()
	model.retry()
	_close_overlay()

func _confirm_exit() -> void:
	exit_confirmation = true
	title.text = "返回旅图？" if embedded else "返回开场？"
	description.text = "返回后将结束本次闯关。"
	buttons[0].text = "返回旅图" if embedded else "返回开场"
	buttons[1].text = "继续本关"
	buttons[2].hide()
	buttons[1].grab_focus()
	overlay_guard = 0.15

func _cancel_exit() -> void:
	exit_confirmation = false
	model.resume()
	_close_overlay()
	overlay_guard = 0.25

func _leave() -> void:
	audio.stop()
	if embedded:
		return_requested.emit()
	else:
		_show_menu()

func _toggle_sound() -> void:
	super._toggle_sound()
	art.audio_state(self)
	preferences_changed.emit(muted, reduced_motion)

func _motion_changed(enabled: bool) -> void:
	super._motion_changed(enabled)
	preferences_changed.emit(muted, reduced_motion)

func _show_pause_panel() -> void:
	$UI/Overlay/Panel.show()
	$UI/Overlay/Settings.hide()
	title.text = "稍歇片刻"
	description.text = ""
	buttons[0].text = "继续前行"
	buttons[1].text = "从头开始" if model.checkpoint.is_empty() or model.victory_locked else ("重追孟坦" if model.checkpoint.phase == "chase" else "重试冲门")
	buttons[2].text = "返回旅图" if embedded else "返回开场"
	buttons[1].show()
	buttons[2].show()
	buttons[0].grab_focus()
	_sync_interface()

func _cycle_focus(direction: int) -> void:
	var choices: Array[Button] = []
	for button in buttons + [$UI/Overlay/Panel/SettingsAction]:
		if button.is_visible_in_tree() and not button.disabled: choices.append(button)
	if choices.is_empty(): return
	var current = choices.find(get_viewport().gui_get_focus_owner())
	choices[posmod(current + direction, choices.size())].grab_focus()

func _show_help(from_settings: bool = false) -> void:
	if overlay_guard > 0.0: return
	help_open = true
	help_from_settings = from_settings
	settings_open = false
	$UI/Overlay/Settings.hide()
	$UI/Overlay/Panel.show()
	title.text = "操作指南"
	description.text = "A / D 或左右键换道，按住只换一次。\n箭路锁定后再闪开。P 暂停，R 重试本段。\nEnter 继续剧情，M 切换声音。"
	buttons[0].text = "返回设置" if from_settings else "返回"
	buttons[1].hide()
	buttons[2].hide()
	buttons[0].grab_focus()
	_clear_input()
	overlay_guard = 0.15
	_sync_interface()

func _close_help() -> void:
	help_open = false
	if help_from_settings:
		_open_settings()
		$UI/Overlay/Settings/Help.grab_focus()
	else:
		_show_menu()
		buttons[1].grab_focus()
	overlay_guard = 0.15

func _open_settings() -> void:
	if not overlay.visible or exit_confirmation or overlay_guard > 0.0: return
	settings_open = true
	help_open = false
	$UI/Overlay/Panel.hide()
	$UI/Overlay/Settings.show()
	_clear_input()
	overlay_guard = 0.15
	_sync_interface()
	$UI/Overlay/Settings.focus_initial()

func _close_settings() -> void:
	if overlay_guard > 0.0: return
	settings_open = false
	$UI/Overlay/Settings.hide()
	if model.state == "paused": _show_pause_panel()
	elif model.state == "ready": _show_menu()
	else: _show_result()
	$UI/Overlay/Panel/SettingsAction.grab_focus()
	_clear_input()
	overlay_guard = 0.15
	_sync_world()

func _set_sound(silence: bool) -> void:
	if overlay_guard <= 0.0 and silence != muted: _toggle_sound()
	_sync_interface()

func _set_motion(reduce_motion: bool) -> void:
	if overlay_guard <= 0.0 and reduce_motion != reduced_motion: _motion_changed(reduce_motion)
	_sync_interface()

func _paint_result_details() -> void:
	description.text = "用时 %.1f 秒  ·  受击 %d 次\n重试 %d 次" % [model.seconds, model.hits, model.retries] if result_details else "双将已斩，车仗离关。"
	buttons[1].text = "收起战绩" if result_details else "查看战绩"

func _sync_interface() -> void:
	var hud_visible: bool = model.state not in ["ready", "culture", "complete"]
	for path in ["Title", "Stage", "TitleInk", "Sound", "Pause", "Progress", "HealthDisplay"]:
		get_node("UI/" + path).visible = hud_visible
	for path in ["HintInk", "HintBrush", "KeyA", "KeyD"]:
		get_node("UI/" + path).visible = $UI/Keys.visible
	$UI/Culture.visible = model.state == "culture" and not overlay.visible
	$UI/Culture/Card/Advance.disabled = overlay_guard > 0.0
	$UI/Overlay/Panel/SettingsAction.visible = not help_open and not exit_confirmation
	$UI/Overlay/Panel/Seal.visible = model.state == "complete" and not settings_open
	for i in buttons.size():
		var variation = &"WuxiaPrimary" if i == (1 if exit_confirmation else 0) else (&"WuxiaDanger" if exit_confirmation and i == 0 else &"")
		if buttons[i].theme_type_variation != variation:
			buttons[i].theme_type_variation = variation
			buttons[i].remove_theme_stylebox_override("hover")
			buttons[i].remove_theme_stylebox_override("focus")
			$Interface.hover_styles.erase(buttons[i])
	$UI/HealthDisplay/HP.value = model.hp
	$UI/HealthDisplay/Trail.value = model.hp
	$UI/HealthDisplay/HP.tooltip_text = "气血 %d / 4" % model.hp
	$UI/HealthDisplay/LowHealth.visible = model.hp in [1, 2]
	$UI/Overlay/Settings.present_preferences(muted, reduced_motion, window_active, settings_open, save_notice)
	$Interface.present(self)

func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_WM_WINDOW_FOCUS_IN]: window_active = true
	elif what in [NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_WM_WINDOW_FOCUS_OUT]: window_active = false
	super._notification(what)

func _on_web_focus_change(arguments: Array) -> void:
	window_active = not web_document.hidden and web_document.hasFocus()
	super._on_web_focus_change(arguments)

func _sync_arrow_tells() -> void:
	for h in model.hazards:
		if h.kind != "arrow" or not hazard_nodes.has(h.id): continue
		var target: Node2D = hazard_nodes[h.id].get_node("Target")
		var aiming: bool = h.phase == "aim"
		var locked: bool = h.phase == "locked"
		target.get_node("Tracking").visible = aiming
		target.get_node("TrackingRight").visible = aiming
		target.get_node("Locked").visible = not aiming
		target.get_node("ReleaseBar").visible = locked
		target.get_node("Outline").width = 2.0 if aiming else 4.0
		target.get_node("Direction").visible = not aiming
		var anchor: Vector2 = road.project(h.lane, 0.0)
		target.get_node("Ribbon").polygon = PackedVector2Array([
			road.project(h.lane - 0.33, 0.0) - anchor, road.project(h.lane - 0.33, 64.0) - anchor,
			road.project(h.lane + 0.33, 64.0) - anchor, road.project(h.lane + 0.33, 0.0) - anchor])
		target.get_node("Ribbon").color.a = 0.055 if aiming else 0.14
		if locked:
			var duration: float = h.get("lock_seconds", model.LOCK_SECONDS)
			var remaining: float = clampf(1.0 - (h.age - float(h.get("aim_seconds", model.AIM_SECONDS))) / duration, 0.0, 1.0)
			target.get_node("ReleaseBar").points = PackedVector2Array([Vector2(-62, 8), Vector2(lerpf(-62, 62, remaining), 8)])

func _make_hazard(kind: String) -> Node2D:
	return ArtBarricade.instantiate() if kind == "barricade" else ArtArrow.instantiate()

func _cue(frequency: float, _seconds: float) -> void:
	var kind = "impact" if frequency < 200.0 else ("bow" if frequency > 500.0 else "arrow")
	art.cue(self, kind, "BowCue" if kind == "bow" else "Effects")

func _exit_tree() -> void:
	art.release_audio(self)
	super._exit_tree()
