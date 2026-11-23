extends Control
## Editor-authored map anchors drive selection and the journey markers.
signal chapter_requested(id: String)
var chapters: Array = []
var progress: RefCounted
var selected = 0
var reduced_motion = false
var suspended = false
var ready_to_start = false
var _opened = false
var _opening = false
var _time = 0.0
var _release_pending = true
var _last_input_frame = -1
var _focus_before_review: Control
var _celebration: Tween
var _celebration_pending = false
var _caravan_origin = Vector2.ZERO
@onready var nodes: Array[Node] = $ScrollClip/Stops.get_children()
@onready var animation: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapters.json"))
	if data is Dictionary:
		chapters = data.get("chapters", [])
	for i in nodes.size():
		nodes[i].pressed.connect(select_chapter.bind(i, true))
		nodes[i].focus_entered.connect(select_chapter.bind(i, false))
	$ScrollClip/Details/Start.pressed.connect(confirm_selection)
	$Life.play("breathing")
	visible = false

func can_enter(id: String) -> bool:
	for chapter in chapters:
		if chapter.id == id:
			return progress != null and bool(chapter.released) and progress.is_unlocked(id) and not str(chapter.entry).is_empty() and ResourceLoader.exists(chapter.entry)
	return false

func recommended() -> int:
	for i in chapters.size():
		if can_enter(chapters[i].id) and not progress.is_cleared(chapters[i].id):
			return i
	for i in range(chapters.size() - 1, -1, -1):
		if can_enter(chapters[i].id) and progress.is_cleared(chapters[i].id):
			return i
	return 0

func open(preserve_selection: bool = false, celebrate: bool = false) -> void:
	visible = true
	set_suspended(false)
	_release_pending = true
	_last_input_frame = Engine.get_process_frames()
	if not preserve_selection:
		selected = recommended()
	_caravan_origin = $ScrollClip/Caravan.position
	_celebration_pending = celebrate
	_time = 0.0
	_opening = not _opened and not reduced_motion
	ready_to_start = not _opening
	_opened = true
	if _opening:
		animation.play("unroll")
		animation.advance(0)
		if not $Paper.stream_paused: $Paper.play()
	else:
		animation.stop()
		$ScrollClip.size.x = 960
	present()
	if preserve_selection and is_instance_valid(_focus_before_review):
		_focus_before_review.grab_focus()
	else:
		nodes[selected].grab_focus()

func remember_focus() -> void:
	_focus_before_review = get_viewport().gui_get_focus_owner()

func set_reduced_motion(value: bool) -> void:
	reduced_motion = value
	if value:
		$Life.stop()
		$ScrollClip/ReadyFlag.modulate.a = 1.0
	else:
		$Life.play("breathing")
	if value:
		_opening = false
		ready_to_start = true
		animation.stop()
		$ScrollClip.size.x = 960
		if _celebration: _celebration.kill()
		_celebration_pending = false
		$ScrollClip/TravelLine.modulate.a = 1.0
		$ScrollClip/Stops/Pass1/Seal.scale = Vector2.ONE
	if progress != null: present()

func set_suspended(value: bool) -> void:
	if suspended == value: return
	suspended = value
	$Paper.stream_paused = value
	if _celebration and _celebration.is_valid():
		if value: _celebration.pause()
		else: _celebration.play()

func set_muted(value: bool) -> void:
	$Paper.volume_db = -80 if value else -22
	$Mute.text = "声音：关" if value else "声音：开"

func select_chapter(i: int, focus: bool = true) -> void:
	if chapters.is_empty(): return
	selected = clampi(i, 0, chapters.size() - 1)
	if focus: nodes[selected].grab_focus()
	present()

func confirm_selection() -> void:
	if not visible or suspended or not ready_to_start or _release_pending or _last_input_frame == Engine.get_process_frames():
		return
	_last_input_frame = Engine.get_process_frames()
	if can_enter(chapters[selected].id):
		chapter_requested.emit(chapters[selected].id)

func present() -> void:
	if progress == null or chapters.size() != nodes.size(): return
	$Progress.text = "已通过 %d / 5 关" % progress.completed_count()
	$SaveNotice.text = progress.error_text
	$Motion.text = "减少动态：开" if reduced_motion else "减少动态：关"
	var chapter = chapters[selected]
	var cleared = progress.is_cleared(chapter.id)
	var unlocked = progress.is_unlocked(chapter.id)
	var playable = can_enter(chapter.id)
	for i in nodes.size():
		var complete = progress.is_cleared(chapters[i].id)
		nodes[i].get_node("Name").text = chapters[i].name
		nodes[i].get_node("State").text = "已通关" if complete else ("未解锁" if not chapters[i].released else ("待挑战" if can_enter(chapters[i].id) else "未解锁"))
		nodes[i].get_node("Selection").visible = i == selected
		nodes[i].get_node("Seal").visible = complete
	$ScrollClip/Details/Number.text = "第 %s 关  /  %s" % [["一", "二", "三", "四", "五"][selected], chapter.theme]
	$ScrollClip/Details/Title.text = chapter.name
	$ScrollClip/Details/Status.text = "已通关" if cleared else ("未解锁" if not chapter.released else ("待挑战" if playable else "未解锁"))
	$ScrollClip/Details/Description.text = chapter.description
	$ScrollClip/Details/Record.text = "最佳分数  %d" % progress.best_score() if cleared and chapter.id == "dongling" else "尚无通关记录"
	var reason = "沿途关隘，逐一前行。"
	if not chapter.released:
		reason = "已满足前置条件，敬候开放。" if unlocked else "通关前一关后，待开放即可挑战。"
	elif not unlocked:
		reason = "通关%s后开启。" % chapters[maxi(0, selected - 1)].name
	elif not playable:
		reason = "入口资源暂不可用，请稍后再试。"
	elif cleared:
		reason = "通关记录已保存，可再次挑战。"
	$ScrollClip/Details/Reason.text = reason
	$ScrollClip/Details/Start.text = ("再次挑战" if cleared else "开始挑战") if playable else ("未解锁" if not chapter.released or not unlocked else "暂不可用")
	$ScrollClip/Details/Start.disabled = not playable or not ready_to_start
	var complete_first = progress.is_cleared("dongling")
	$ScrollClip/Caravan.position = $ScrollClip/TravelEnd.position if complete_first else $ScrollClip/TravelStart.position
	$ScrollClip/ReadyFlag.position = $ScrollClip/FlagEnd.position if complete_first else $ScrollClip/FlagStart.position
	$ScrollClip/ReadyFlag.visible = true
	$ScrollClip/TravelLine.visible = complete_first
	$NextStop.text = "下一站 · 洛阳未解锁" if complete_first else "护送二位夫人，过关寻刘备"
	if _celebration_pending and ready_to_start:
		_celebration_pending = false
		if not reduced_motion and complete_first:
			var destination = $ScrollClip/Caravan.position
			$ScrollClip/Caravan.position = _caravan_origin
			$ScrollClip/TravelLine.modulate.a = 0
			$ScrollClip/Stops/Pass1/Seal.scale = Vector2(1.5, 1.5)
			_celebration = create_tween()
			_celebration.tween_property($ScrollClip/TravelLine, "modulate:a", 1.0, .35)
			_celebration.parallel().tween_property($ScrollClip/Caravan, "position", destination, .8)
			_celebration.parallel().tween_property($ScrollClip/Stops/Pass1/Seal, "scale", Vector2.ONE, .6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _input(event: InputEvent) -> void:
	if not visible or suspended or not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode in [KEY_LEFT, KEY_RIGHT] or event.physical_keycode in [KEY_LEFT, KEY_RIGHT]:
		var code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
		select_chapter(selected + (-1 if code == KEY_LEFT else 1))
		get_viewport().set_input_as_handled()

func _process(dt: float) -> void:
	if not visible:
		$Paper.stop()
		if _celebration: _celebration.kill()
		return
	if suspended: return
	if not reduced_motion: $Life.advance(dt)
	if _release_pending:
		_release_pending = Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		for key in [KEY_ENTER, KEY_SPACE, KEY_LEFT, KEY_RIGHT]:
			_release_pending = _release_pending or Input.is_physical_key_pressed(key)
	if _opening:
		_time += dt
		animation.advance(dt)
		if _time >= .8:
			_opening = false
			ready_to_start = true
			present()
