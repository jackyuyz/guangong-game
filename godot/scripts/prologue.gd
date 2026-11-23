extends Control
## One clock drives the comic. Voices are preloaded, and blocked audio holds the scene.
signal completed
signal silence_requested
signal narration_requested
const BLEND_SECONDS = 0.45
var scenes: Array = []
var available = false
var active = false
var replay = false
var entry = "culture"
var was_skipped = false
var auto_play = true
var more_open = false
var reduced_motion = false
var suspended = false
var waiting_for_audio = false
var index = 0
var elapsed = 0.0
var _muted = false
var _last_input_frame = -1
var _blend_elapsed = BLEND_SECONDS
var _voices: Array[AudioStream] = []
var _effects: Dictionary = {}
var _audio_bridge: JavaScriptObject
@onready var animation: AnimationPlayer = $AnimationPlayer
@onready var voice: AudioStreamPlayer = $Voice
@onready var ambience: AudioStreamPlayer = $Ambience
@onready var effect: AudioStreamPlayer = $Effect

func _ready() -> void:
	if OS.has_feature("web"):
		_audio_bridge = JavaScriptBridge.get_interface("GuangongAudio")
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/prologue.json"))
	if data is Dictionary:
		scenes = data.get("scenes", [])
	available = scenes.size() == 6
	for scene in scenes:
		if not scene is Dictionary or not scene.has_all(["node", "id", "audio", "caption", "title", "duration"]):
			available = false
			break
		if not has_node("Panels/" + scene.node) or not animation.has_animation(scene.id) or not ResourceLoader.exists(scene.audio):
			available = false
			break
		var stream = load(scene.audio) as AudioStream
		if stream == null or stream.get_length() + 0.3 > float(scene.duration):
			available = false
			break
		_voices.append(stream)
	for picture in $Panels.find_children("*", "TextureRect", true, false):
		available = available and picture.texture != null
	for sound in ["wind", "paper", "seal", "wheels", "gate"]:
		var path = "res://assets/prologue/audio/" + sound + ".wav"
		if ResourceLoader.exists(path):
			_effects[sound] = load(path)
		else:
			available = false
	if not available:
		push_warning("前情资源不完整，将使用精简开场对白。")
	$Previous.pressed.connect(previous)
	$Auto.pressed.connect(toggle_auto)
	$Next.pressed.connect(advance)
	$Skip.pressed.connect(finish)
	$ReplayVoice.pressed.connect(replay_current)
	$More.pressed.connect(toggle_more)
	stop()

func _exit_tree() -> void:
	stop()

func begin(is_replay: bool = false, source: String = "culture") -> bool:
	stop()
	if not available:
		return false
	replay = is_replay
	entry = source
	was_skipped = false
	auto_play = true
	suspended = false
	active = true
	visible = true
	_last_input_frame = Engine.get_process_frames()
	ambience.play()
	_show_scene(0, false)
	return true

func stop() -> void:
	more_open = false
	if is_instance_valid(voice):
		$MorePanel.hide()
		$ReplayVoice.hide()
	active = false
	visible = false
	waiting_for_audio = false
	if is_instance_valid(voice):
		for player in [voice, ambience, effect]:
			player.stream_paused = false
			player.stop()
		animation.stop()
		$Transition.hide()
	if _audio_bridge != null:
		_audio_bridge.setActive(false, _muted)

func _accept_input() -> bool:
	if not active or suspended or _last_input_frame == Engine.get_process_frames():
		return false
	_last_input_frame = Engine.get_process_frames()
	return true

func advance() -> void:
	if not _accept_input():
		return
	if index == scenes.size() - 1:
		_complete()
	else:
		_show_scene(index + 1)

func previous() -> void:
	if _accept_input() and index > 0:
		_show_scene(index - 1)

func toggle_auto() -> void:
	if _accept_input():
		auto_play = not auto_play
		if not auto_play:
			$Transition.hide()
		_refresh_audio()
		_refresh_controls()

func replay_current() -> void:
	if _accept_input():
		_set_more(false)
		narration_requested.emit()
		auto_play = true
		_show_scene(index, false)

func _set_more(value: bool) -> void:
	more_open = value
	$MorePanel.visible = value
	$ReplayVoice.visible = value
	_refresh_audio()
	if active:
		if value: $ReplayVoice.grab_focus()
		else: $More.grab_focus()

func toggle_more() -> void:
	if _accept_input(): _set_more(not more_open)

func _input(event: InputEvent) -> void:
	if not active or suspended or not more_open: return
	if event is InputEventKey and event.pressed:
		if event.physical_keycode == KEY_ESCAPE or event.keycode == KEY_ESCAPE:
			_set_more(false)
			get_viewport().set_input_as_handled()
		elif event.physical_keycode == KEY_TAB or event.keycode == KEY_TAB:
			if $ReplayVoice.has_focus(): $More.grab_focus()
			else: $ReplayVoice.grab_focus()
			get_viewport().set_input_as_handled()
	if event is InputEventMouseButton and event.pressed:
		if not $MorePanel.get_global_rect().has_point(event.position) and not $More.get_global_rect().has_point(event.position):
			_set_more(false)
			get_viewport().set_input_as_handled()

func finish() -> void:
	if _accept_input():
		was_skipped = true
		_complete()

func _complete() -> void:
	if not active:
		return
	stop()
	completed.emit()

func set_suspended(value: bool) -> void:
	if suspended == value:
		return
	suspended = value
	if active:
		_refresh_audio()

func set_muted(value: bool) -> void:
	if _muted == value:
		return
	_muted = value
	voice.volume_db = -80 if value else 2
	ambience.volume_db = -80 if value else -27
	effect.volume_db = -80 if value else -23
	_refresh_audio()
	if active:
		_refresh_controls()

func request_audio() -> void:
	if _audio_bridge != null:
		_audio_bridge.request()

func _audio_context_ready() -> bool:
	return not OS.has_feature("web") or (_audio_bridge != null and bool(_audio_bridge.isReady()))

func _refresh_audio() -> void:
	waiting_for_audio = active and not _muted and not _audio_context_ready()
	var paused = suspended or more_open or not auto_play or waiting_for_audio
	for player in [voice, ambience, effect]:
		if player.stream_paused != paused:
			player.stream_paused = paused
	if _audio_bridge != null:
		_audio_bridge.setActive(active and auto_play and not suspended and not more_open, _muted)

func _show_scene(next_index: int, blend: bool = true) -> void:
	var old_art: Node2D = get_node("Panels/" + scenes[index].node + "/Art")
	$Transition/Image.texture = old_art.get_node("Illustration").texture
	$Transition.position = old_art.position
	$Transition.scale = old_art.scale
	_blend_elapsed = 0.0
	$Transition.modulate.a = 1.0
	$Transition.visible = blend and auto_play and not reduced_motion
	index = next_index
	elapsed = 0.0
	for panel in $Panels.get_children():
		panel.visible = panel.name == scenes[index].node
	$Title.text = scenes[index].title
	$Context.text = scenes[index].get("context", "")
	$Caption.text = scenes[index].caption
	$Series.visible = index == 0
	voice.stop()
	voice.stream = _voices[index]
	voice.play()
	effect.stop()
	effect.stream = _effects[["wind", "paper", "paper", "seal", "wheels", "gate"][index]]
	effect.play()
	animation.stop()
	animation.play(scenes[index].id)
	animation.advance(0)
	_refresh_audio()
	_refresh_controls()

func _refresh_controls() -> void:
	$Previous.disabled = index == 0
	$Auto.text = "暂停播放" if auto_play else "继续播放"
	$Next.text = ("返回旅图" if entry == "map" else ("返回" if replay else "展开旅图")) if index == scenes.size() - 1 else "继续  ENTER"
	$Skip.text = "返回旅图" if entry == "map" else "跳过前情"
	$Count.text = "%02d / 06" % (index + 1)
	$Sound.text = "开启声音" if waiting_for_audio else ("声音：关" if _muted else "声音：开")
	$AudioHint.text = "声音尚未开启" if waiting_for_audio else ("当前静音" if _muted else "")
	$Progress.value = (index + elapsed / float(scenes[index].duration)) / scenes.size() * 100.0

func _process(dt: float) -> void:
	if not active:
		return
	if _audio_bridge != null and _audio_bridge.consumeSilent():
		silence_requested.emit()
	var was_waiting = waiting_for_audio
	_refresh_audio()
	if waiting_for_audio != was_waiting:
		_refresh_controls()
	if suspended or more_open or not auto_play or waiting_for_audio:
		return
	var step = minf(dt, float(scenes[index].duration) - elapsed)
	elapsed += step
	if not reduced_motion: animation.advance(step)
	else: $Transition.hide()
	_blend_elapsed = minf(_blend_elapsed + step, BLEND_SECONDS)
	$Transition.modulate.a = 1.0 - _blend_elapsed / BLEND_SECONDS
	if _blend_elapsed >= BLEND_SECONDS:
		$Transition.hide()
	$Progress.value = (index + elapsed / float(scenes[index].duration)) / scenes.size() * 100.0
	if elapsed >= float(scenes[index].duration) and index < scenes.size() - 1:
		_show_scene(index + 1)
