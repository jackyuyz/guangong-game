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
var auto_play = true
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
	stop()

func _exit_tree() -> void:
	stop()

func begin(is_replay: bool = false) -> bool:
	stop()
	if not available:
		return false
	replay = is_replay
	auto_play = true
	suspended = false
	active = true
	visible = true
	_last_input_frame = Engine.get_process_frames()
	ambience.play()
	_show_scene(0, false)
	return true

func stop() -> void:
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
		narration_requested.emit()
		auto_play = true
		_show_scene(index, false)

func finish() -> void:
	if _accept_input():
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
	var paused = suspended or not auto_play or waiting_for_audio
	for player in [voice, ambience, effect]:
		if player.stream_paused != paused:
			player.stream_paused = paused
	if _audio_bridge != null:
		_audio_bridge.setActive(active and auto_play and not suspended, _muted)

func _show_scene(next_index: int, blend: bool = true) -> void:
	var old_art: Node2D = get_node("Panels/" + scenes[index].node + "/Art")
	$Transition/Image.texture = old_art.get_node("Illustration").texture
	$Transition.position = old_art.position
	$Transition.scale = old_art.scale
	_blend_elapsed = 0.0
	$Transition.modulate.a = 1.0
	$Transition.visible = blend and auto_play
	index = next_index
	elapsed = 0.0
	for panel in $Panels.get_children():
		panel.visible = panel.name == scenes[index].node
	$Title.text = scenes[index].title
	$Context.text = scenes[index].get("context", "")
	$Caption.text = scenes[index].caption
	$Speaker.text = scenes[index].get("speaker", "中文说书")
	$Adaptation.visible = index == 0
	$Mission.visible = index == 5
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
	$Auto.text = "暂停播放" if auto_play else "自动播放"
	$Next.text = ("返回" if replay else "启程") if index == scenes.size() - 1 else "继续  ENTER"
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
	if suspended or not auto_play or waiting_for_audio:
		return
	var step = minf(dt, float(scenes[index].duration) - elapsed)
	elapsed += step
	animation.advance(step)
	_blend_elapsed = minf(_blend_elapsed + step, BLEND_SECONDS)
	$Transition.modulate.a = 1.0 - _blend_elapsed / BLEND_SECONDS
	if _blend_elapsed >= BLEND_SECONDS:
		$Transition.hide()
	$Progress.value = (index + elapsed / float(scenes[index].duration)) / scenes.size() * 100.0
	if elapsed >= float(scenes[index].duration) and index < scenes.size() - 1:
		_show_scene(index + 1)
