extends Control
## Decorative feedback stays separate from the existing button actions.
var active = false
var muted = false
var reduced_motion = false
var window_active = true
var last_hover_sound = -1000
var hovered: Button
var tweens: Dictionary = {}
@onready var buttons: Array[Button] = [$Start, $Culture, $Mute]

func _ready() -> void:
	for button in buttons:
		button.mouse_entered.connect(_enter.bind(button))
		button.mouse_exited.connect(_leave.bind(button))
		button.focus_entered.connect(_focus.bind(button))
		button.focus_exited.connect(_refresh.bind(button))
		button.button_down.connect(_down.bind(button))
		button.button_up.connect(_refresh.bind(button))

func present_state(enabled: bool, silence: bool, reduce: bool, focused: bool) -> void:
	var changed = active != enabled or reduced_motion != reduce or window_active != focused
	active = enabled
	muted = silence
	reduced_motion = reduce
	window_active = focused
	if not active or not focused:
		hovered = null
		$HoverSound.stop()
	if silence or not focused:
		$HoverSound.stop()
		$ConfirmSound.stop()
	if changed:
		for button in buttons: _refresh(button, true)

func _enter(button: Button) -> void:
	if not active or not window_active: return
	hovered = button
	button.grab_focus()
	_refresh(button)
	_hover_sound()

func _leave(button: Button) -> void:
	if hovered == button: hovered = null
	_refresh(button)

func _focus(button: Button) -> void:
	if hovered != null and hovered != button:
		var previous = hovered
		hovered = null
		_refresh(previous)
	_refresh(button)
	_hover_sound()

func _down(button: Button) -> void:
	if not active or not window_active: return
	_refresh(button, false, true)
	if not muted: $ConfirmSound.play()

func _hover_sound() -> void:
	var now = Time.get_ticks_msec()
	if not active or not window_active or muted or now - last_hover_sound < 75: return
	last_hover_sound = now
	$HoverSound.play()

func _refresh(button: Button, instant: bool = false, pressed: bool = false) -> void:
	if tweens.has(button):
		tweens[button].kill()
		tweens.erase(button)
	var selected = active and window_active and (hovered == button or button.has_focus())
	var wash_alpha = (0.36 if pressed else 0.2) if selected else 0.0
	var line_alpha = 1.0 if selected else (0.78 if button == $Start else 0.2)
	var wash: TextureRect = button.get_node("Wash")
	var line: TextureRect = button.get_node("Underline")
	if instant or reduced_motion:
		wash.modulate.a = wash_alpha
		line.modulate.a = line_alpha
	else:
		var tween = create_tween().set_parallel(true)
		tweens[button] = tween
		tween.tween_property(wash, "modulate:a", wash_alpha, 0.12)
		tween.tween_property(line, "modulate:a", line_alpha, 0.12)

func set_controls_visible(showing: bool) -> void:
	for path in ["Title", "Subtitle", "SubtitleStrokeLeft", "SubtitleStrokeRight", "Tagline", "Start", "Culture", "Mute"]:
		get_node(path).visible = showing
