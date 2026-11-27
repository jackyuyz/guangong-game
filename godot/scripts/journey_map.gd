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
var _name_inks: Array[Color] = []
@onready var nodes: Array[Node] = $ScrollClip/Stops.get_children()
@onready var animation: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/chapters.json"))
	if data is Dictionary:
		chapters = data.get("chapters", [])
	for i in nodes.size():
		_name_inks.append(nodes[i].get_node("Name").get_theme_color("font_color"))
		nodes[i].pressed.connect(select_chapter.bind(i, true))
		nodes[i].focus_entered.connect(select_chapter.bind(i, false))
	$ScrollClip/Details/Start.pressed.connect(confirm_selection)
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
		_opening = false
		ready_to_start = true
		animation.stop()
		$ScrollClip.size.x = 960
		if _celebration: _celebration.kill()
		_celebration_pending = false
		for stop in nodes:
			stop.get_node("Seal").scale = Vector2.ONE
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
	$SaveNotice.text = progress.error_text
	var chapter = chapters[selected]
	var cleared = progress.is_cleared(chapter.id)
	var unlocked = progress.is_unlocked(chapter.id)
	var playable = can_enter(chapter.id)
	for i in nodes.size():
		var complete = progress.is_cleared(chapters[i].id)
		nodes[i].get_node("Name").text = chapters[i].name
		var available = can_enter(chapters[i].id)
		var veiled = not complete and not available
		$ScrollClip/Veils.get_child(i).visible = veiled
		nodes[i].get_node("Name").add_theme_color_override("font_color", Color(0.3, 0.32, 0.27, 1) if veiled else _name_inks[i])
		nodes[i].tooltip_text = str(chapters[i].name) + " · " + ("已通过" if complete else ("可挑战" if available else "未解锁"))
		nodes[i].get_node("Selection").visible = i == selected
		nodes[i].get_node("Seal").visible = complete
	$ScrollClip/Details/Number.text = "第%s关" % ["一", "二", "三", "四", "五"][selected]
	$ScrollClip/Details/Title.text = chapter.name
	$ScrollClip/Details/Description.text = chapter.description
	var second_record: Dictionary = progress.luoyang_record() if chapter.id == "luoyang" else {}
	$ScrollClip/Details/Record.visible = cleared and (chapter.id == "dongling" or not second_record.is_empty())
	$ScrollClip/Details/Record/Caption.text = "最快" if chapter.id == "luoyang" else "最佳"
	$ScrollClip/Details/Record/Caption.add_theme_font_override("font", $ScrollClip/Details/Record/Value.get_theme_font("font") if chapter.id == "luoyang" else preload("res://assets/ui/wuxia-reading-font.ttf"))
	$ScrollClip/Details/Record/Value.add_theme_font_size_override("font_size", 22 if chapter.id == "luoyang" else 30)
	$ScrollClip/Details/Record/Value.text = ("%.1f秒" % second_record.seconds) if not second_record.is_empty() else str(progress.best_score())
	var reason = ""
	if not chapter.released:
		reason = "前置已完成\n此关尚未开放。" if unlocked else "先通过%s\n此关尚未开放。" % chapters[maxi(0, selected - 1)].name
	elif not unlocked:
		reason = "通关%s后开启。" % chapters[maxi(0, selected - 1)].name
	elif not playable:
		reason = "入口资源暂不可用，请稍后再试。"
	$ScrollClip/Details/Reason.text = reason
	$ScrollClip/Details/Start.text = ("再次挑战" if cleared else "开始挑战") if playable else ("未解锁" if not chapter.released or not unlocked else "暂不可用")
	$ScrollClip/Details/Start.disabled = not playable or not ready_to_start
	$ScrollClip/Details/Start.visible = playable or (chapter.released and unlocked)
	var complete_first = progress.is_cleared("dongling")
	$ScrollClip/Caravan.position = $ScrollClip/TravelEnd.position if complete_first else $ScrollClip/TravelStart.position
	if progress.is_cleared("luoyang"):
		$ScrollClip/Caravan.position = $ScrollClip/TravelLuoyangEnd.position
	if _celebration_pending and ready_to_start:
		_celebration_pending = false
		if not reduced_motion and complete_first:
			var destination = $ScrollClip/Caravan.position
			$ScrollClip/Caravan.position = _caravan_origin
			var seal: Control = $ScrollClip/Stops/Pass2/Seal if progress.is_cleared("luoyang") else $ScrollClip/Stops/Pass1/Seal
			seal.scale = Vector2(1.5, 1.5)
			_celebration = create_tween()
			_celebration.tween_property($ScrollClip/Caravan, "position", destination, .8)
			_celebration.parallel().tween_property(seal, "scale", Vector2.ONE, .6).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _input(event: InputEvent) -> void:
	if not visible or suspended: return
	if not event is InputEventKey or not event.pressed or event.echo: return
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
