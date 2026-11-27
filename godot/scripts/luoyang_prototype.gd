extends Node2D
## Isolated blockout: no progress store, no filesystem or browser storage access.
const Model = preload("res://scripts/luoyang_model.gd")
const Barricade = preload("res://scenes/prototypes/luoyang_barricade.tscn")
const Arrow = preload("res://scenes/prototypes/luoyang_arrow.tscn")
var model = Model.new()
var hazard_nodes: Dictionary = {}
var pending_directions: Array[int] = []
var held_keys: Dictionary = {}
var wait_release = false
var overlay_guard = 0.0
var visual_time = 0.0
var reduced_motion = false
var muted = false
var previous_stage = "barricades"
var feedback_time = 0.0
var accessibility_text = ""
var web_document: JavaScriptObject
var web_window: JavaScriptObject
var web_focus_callback: JavaScriptObject
@onready var road = $Road
@onready var rider: Node2D = $World/Rider
@onready var overlay: Control = $UI/Overlay
@onready var buttons = [$UI/Overlay/Panel/First, $UI/Overlay/Panel/Second, $UI/Overlay/Panel/Third]
@onready var title: Label = $UI/Overlay/Panel/Title
@onready var description: Label = $UI/Overlay/Panel/Description
@onready var audio: AudioStreamPlayer = $Cue

func _ready() -> void:
	for i in 3:
		buttons[i].pressed.connect(_overlay_action.bind(i))
	$UI/Pause.pressed.connect(_toggle_pause)
	$UI/Sound.pressed.connect(_toggle_sound)
	$UI/Overlay/Panel/Motion.toggled.connect(_motion_changed)
	if OS.has_feature("web"):
		reduced_motion = bool(JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches"))
		web_document = JavaScriptBridge.get_interface("document")
		web_window = JavaScriptBridge.get_interface("window")
		web_focus_callback = JavaScriptBridge.create_callback(_on_web_focus_change)
		web_document.addEventListener("visibilitychange", web_focus_callback)
		web_window.addEventListener("blur", web_focus_callback)
	$UI/Overlay/Panel/Motion.set_pressed_no_signal(reduced_motion)
	_show_menu()
	_sync_world()

func _notification(what: int) -> void:
	if is_node_ready() and (what == NOTIFICATION_APPLICATION_FOCUS_OUT or (what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and not OS.has_feature("web"))):
		_pause_for_focus_loss()

func _on_web_focus_change(_arguments: Array) -> void:
	if web_document.hidden or not web_document.hasFocus():
		_pause_for_focus_loss()

func _pause_for_focus_loss() -> void:
	if model.state == "running":
		overlay_guard = 0.0
		_toggle_pause()

func _exit_tree() -> void:
	if web_focus_callback != null:
		web_document.removeEventListener("visibilitychange", web_focus_callback)
		web_window.removeEventListener("blur", web_focus_callback)

func _input(event: InputEvent) -> void:
	if not event is InputEventKey:
		return
	var key = event.physical_keycode if event.physical_keycode else event.keycode
	if key in [KEY_A, KEY_D, KEY_LEFT, KEY_RIGHT]:
		if not event.pressed:
			held_keys.erase(key)
		elif not event.echo and not held_keys.has(key):
			held_keys[key] = true
			if model.state == "running" and not wait_release:
				pending_directions.append(-1 if key in [KEY_A, KEY_LEFT] else 1)
		if model.state == "running":
			get_viewport().set_input_as_handled()
	if not event.pressed or event.echo:
		return
	if key in [KEY_ESCAPE, KEY_P] and model.state in ["running", "paused"]:
		_toggle_pause()
		get_viewport().set_input_as_handled()
	elif key == KEY_M:
		_toggle_sound()
		get_viewport().set_input_as_handled()
	elif key == KEY_R and model.state == "running":
		model.pause()
		_retry()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	overlay_guard = maxf(0.0, overlay_guard - delta)
	if wait_release:
		wait_release = Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_RIGHT)
	if model.state == "running":
		if not pending_directions.is_empty():
			var left = -1 in pending_directions
			var right = 1 in pending_directions
			if left != right:
				var opposite_held = _direction_held(1 if left else -1)
				if not opposite_held:
					model.request_lane(-1 if left else 1)
		pending_directions.clear()
		model.step(minf(delta, 0.25))
		visual_time += minf(delta, 0.25)
		feedback_time = maxf(0.0, feedback_time - delta)
		if model.stage != previous_stage:
			previous_stage = model.stage
			_clear_input()
		for event in model.events:
			if event == "hit":
				feedback_time = 0.65
				_cue(125.0, 0.16)
			elif event == "lock":
				_cue(680.0, 0.08)
			elif event == "release":
				_cue(360.0, 0.06)
		model.events.clear()
		_sync_world()
		if model.state in ["failed", "complete"]:
			_show_result()

func _direction_held(direction: int) -> bool:
	if direction < 0:
		return held_keys.has(KEY_A) or held_keys.has(KEY_LEFT)
	return held_keys.has(KEY_D) or held_keys.has(KEY_RIGHT)

func _clear_input() -> void:
	pending_directions.clear()
	held_keys.clear()
	model.queued_direction = 0
	wait_release = Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_physical_key_pressed(KEY_RIGHT)

func _sync_world() -> void:
	rider.position = road.project(model.lane, 0.0)
	rider.get_node("Body").position.y = 0.0 if reduced_motion or model.state != "running" else sin(visual_time * 15.0) * 2.2
	var body: Node2D = rider.get_node("Body")
	body.rotation = 0.0 if reduced_motion else (float(model.target_lane) - model.lane) * 0.075
	body.modulate = Color(1.0, 0.62, 0.48) if model.invulnerable > 0.0 else Color.WHITE
	for i in $Road/Marks.get_child_count():
		var mark: Line2D = $Road/Marks.get_child(i)
		var depth = fposmod(float(i / 2) * 10.0 - model.distance, 90.0)
		var lane_divider = -0.5 if i % 2 == 0 else 0.5
		mark.points = PackedVector2Array([road.project(lane_divider, depth), road.project(lane_divider, depth + 3.2)])
	for i in $Road/Flags.get_child_count():
		var flag: Node2D = $Road/Flags.get_child(i)
		var depth = fposmod(float(i / 2) * 22.5 - model.distance, 90.0)
		flag.position = road.project(-1.9 if i % 2 == 0 else 1.9, depth)
		flag.scale = Vector2.ONE * road.factor(depth)
		flag.z_index = int(100.0 - depth)
	var active_ids: Array[int] = []
	var warning = ""
	for hazard in model.hazards:
		var id: int = hazard.id
		active_ids.append(id)
		if not hazard_nodes.has(id):
			var node = _make_hazard(hazard.kind)
			$World.add_child(node)
			hazard_nodes[id] = node
		var view: Node2D = hazard_nodes[id]
		var depth: float = hazard.distance
		view.z_index = int(110.0 - depth)
		view.position = road.project(float(hazard.lane), depth)
		view.scale = Vector2.ONE * road.factor(depth)
		if hazard.kind == "arrow":
			var flying: bool = hazard.phase == "flying"
			view.get_node("Shaft").visible = flying
			view.get_node("Head").visible = flying
			view.get_node("Ground").visible = flying
			view.get_node("Target").visible = not hazard.resolved
			view.get_node("Target").global_position = $Road.to_global(road.project(float(hazard.lane), 0.0))
			view.get_node("Target").global_scale = Vector2.ONE
			view.get_node("Target").modulate = Color(0.96, 0.72, 0.28, 0.65) if hazard.phase == "aim" else Color(1.0, 0.30, 0.18, 0.88)
			if not hazard.resolved:
				warning = "瞄准中" if hazard.phase == "aim" else "箭路已定 · 换道"
	for id in hazard_nodes.keys():
		if id not in active_ids:
			hazard_nodes[id].queue_free()
			hazard_nodes.erase(id)
	$UI/Health.text = "气血  " + "● ".repeat(model.hp) + "○ ".repeat(4 - model.hp)
	$UI/Stage.text = "拒马 · 看路换道" if model.stage == "barricades" else "箭矢 · 锁定后闪开"
	$UI/Progress.value = clampf(model.elapsed / Model.STAGE_SECONDS * 100.0, 0.0, 100.0)
	$UI/Warning.text = "撞到拒马" if feedback_time > 0.0 and model.stage == "barricades" else ("中箭" if feedback_time > 0.0 else warning)
	$UI/WarningBacking.visible = not $UI/Warning.text.is_empty()
	$UI/HitFlash.color.a = 0.10 * feedback_time / 0.65 if not reduced_motion else 0.0
	$World/Archer.visible = model.stage == "arrows"
	$World/Archer.modulate = Color(1.0, 0.60, 0.35) if warning != "" else Color.WHITE
	$UI/Pause.disabled = model.state not in ["running", "paused"]
	$UI/Pause.text = "继续" if model.state == "paused" else "暂停"
	if OS.has_feature("web"):
		var lane_name: String = ["左道", "中道", "右道"][clampi(roundi(model.lane), -1, 1) + 1]
		var state_name: String = {"ready": "选择练习", "running": "试跑中", "paused": "已暂停", "failed": "气血耗尽", "complete": "试跑完成"}.get(model.state, "")
		var summary = "洛阳操作原型。%s。%s。气血%d。%s。%s" % [state_name, $UI/Stage.text, model.hp, lane_name, $UI/Warning.text]
		if summary != accessibility_text:
			accessibility_text = summary
			JavaScriptBridge.eval("document.getElementById('canvas').setAttribute('aria-label', %s)" % JSON.stringify(summary))

func _make_hazard(kind: String) -> Node2D:
	return (Barricade if kind == "barricade" else Arrow).instantiate()

func _show_menu() -> void:
	model.state = "ready"
	_clear_input()
	overlay.visible = true
	overlay_guard = 0.15
	title.text = "洛阳 · 三车道试跑"
	description.text = "左右换道，绕开拒马。\n箭路锁定后，再换道闪开。"
	buttons[0].text = "连续试跑"
	buttons[1].text = "拒马练习"
	buttons[2].text = "箭矢练习"
	buttons[2].show()
	buttons[0].grab_focus()
	_sync_world()

func _overlay_action(index: int) -> void:
	if overlay_guard > 0.0:
		return
	if model.state == "ready":
		model.start(["course", "barricades", "arrows"][index])
		previous_stage = model.stage
		_close_overlay()
	elif model.state == "paused":
		if index == 0:
			_toggle_pause()
		elif index == 1:
			_retry()
		else:
			_show_menu()
	elif model.state in ["failed", "complete"]:
		if index == 0:
			_retry()
		else:
			_show_menu()

func _close_overlay() -> void:
	overlay.hide()
	buttons[2].show()
	_clear_input()
	feedback_time = 0.0
	audio.stream_paused = false
	_sync_world()

func _toggle_pause() -> void:
	if overlay_guard > 0.0:
		return
	if model.state == "running":
		model.pause()
		_clear_input()
		overlay.show()
		title.text = "已暂停"
		description.text = "路面、换道与箭矢均已停下。"
		buttons[0].text = "继续试跑"
		buttons[1].text = "重试本段"
		buttons[2].text = "选择练习"
		buttons[2].show()
		buttons[0].grab_focus()
		audio.stream_paused = true
		overlay_guard = 0.15
	elif model.state == "paused":
		model.resume()
		_close_overlay()
	_sync_world()

func _retry() -> void:
	model.retry()
	_close_overlay()

func _show_result() -> void:
	_clear_input()
	overlay.show()
	overlay_guard = 0.25
	title.text = "试跑完成" if model.state == "complete" else "气血耗尽"
	description.text = "受击 %d 次  ·  换道 %d 次\n重试 %d 次  ·  不计旅程进度" % [model.hits, model.switches, model.retries]
	buttons[0].text = "再试本段"
	buttons[1].text = "选择练习"
	buttons[2].hide()
	buttons[0].grab_focus()

func _motion_changed(enabled: bool) -> void:
	reduced_motion = enabled
	_sync_world()

func _toggle_sound() -> void:
	muted = not muted
	$UI/Sound.text = "声音 关" if muted else "声音 开"
	if muted:
		audio.stop()

func _cue(frequency: float, seconds: float) -> void:
	if muted:
		return
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = 22050
	var count = int(seconds * stream.mix_rate)
	var data = PackedByteArray()
	data.resize(count * 2)
	for i in count:
		var envelope = sin(PI * float(i) / count)
		data.encode_s16(i * 2, int(sin(TAU * frequency * i / stream.mix_rate) * envelope * 2800.0))
	stream.data = data
	audio.stream = stream
	audio.play()
