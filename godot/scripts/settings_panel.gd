extends Control
## Native grouped choices; game state and saving remain owned by main.gd.
var active = false
var muted = false
var reduced = false
var focused = true
var hover: Button
var last_focus: Button
var last_sound = -1000
var tweens: Dictionary = {}
@onready var buttons: Array[Button] = [$Sound/On, $Sound/Off, $Motion/On, $Motion/Off, $Help, $Close]

func _ready() -> void:
	for button in buttons:
		button.mouse_entered.connect(_enter.bind(button))
		button.mouse_exited.connect(_leave.bind(button))
		button.focus_entered.connect(_focus.bind(button))
		button.focus_exited.connect(_refresh.bind(button))
		button.button_down.connect(_down.bind(button))
		button.button_up.connect(_refresh.bind(button))

func present_preferences(silence: bool, reduce_motion: bool, window_focused: bool, enabled: bool, notice: String) -> void:
	var changed = muted != silence or reduced != reduce_motion or focused != window_focused or active != enabled
	var enabled_sound = active and muted and not silence and enabled and window_focused
	muted = silence
	reduced = reduce_motion
	focused = window_focused
	active = enabled
	$Sound/On.set_pressed_no_signal(not muted)
	$Sound/Off.set_pressed_no_signal(muted)
	$Motion/On.set_pressed_no_signal(reduced)
	$Motion/Off.set_pressed_no_signal(not reduced)
	for pair in [[$Sound/On, $Sound/Off], [$Motion/On, $Motion/Off]]:
		for button in pair:
			button.focus_mode = Control.FOCUS_ALL if button.button_pressed else Control.FOCUS_CLICK
	$Notice.text = notice
	$Notice.visible = not notice.is_empty()
	if not active or not focused:
		hover = null
		$HoverSound.stop()
	if muted or not focused:
		$HoverSound.stop()
		$ConfirmSound.stop()
	if changed:
		for button in buttons: _refresh(button, true)
	if enabled_sound: $ConfirmSound.play()

func selected_sound() -> Button:
	return $Sound/Off if muted else $Sound/On

func selected_motion() -> Button:
	return $Motion/On if reduced else $Motion/Off

func focus_initial() -> void:
	var target = last_focus if is_instance_valid(last_focus) else selected_sound()
	if target in [$Sound/On, $Sound/Off]: target = selected_sound()
	if target in [$Motion/On, $Motion/Off]: target = selected_motion()
	target.grab_focus()

func handle_key(event: InputEventKey) -> bool:
	if not active or not focused: return false
	var code = event.physical_keycode if event.physical_keycode != 0 else event.keycode
	var entries: Array[Button] = [selected_sound(), selected_motion(), $Help, $Close]
	var owner = get_viewport().gui_get_focus_owner()
	var index = entries.find(owner)
	if owner in [$Sound/On, $Sound/Off]: index = 0
	if owner in [$Motion/On, $Motion/Off]: index = 1
	if code in [KEY_TAB, KEY_UP, KEY_DOWN]:
		var step = -1 if event.shift_pressed or code == KEY_UP else 1
		var next = posmod(index + step, entries.size()) if index >= 0 else (0 if step > 0 else entries.size() - 1)
		entries[next].grab_focus()
		return true
	if code in [KEY_LEFT, KEY_RIGHT]:
		if index in [0, 1] and not event.echo:
			var pair = [$Sound/On, $Sound/Off] if index == 0 else [$Motion/On, $Motion/Off]
			_activate(pair[0 if code == KEY_LEFT else 1])
		return true
	if code in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
		if event.echo: return true
		if index == 0: _activate($Sound/On if muted else $Sound/Off)
		elif index == 1: _activate($Motion/Off if reduced else $Motion/On)
		else: _activate(entries[maxi(index, 0)])
		return true
	return false

func _activate(button: Button) -> void:
	button.grab_focus()
	button.button_down.emit()
	button.pressed.emit()
	button.button_up.emit()

func _enter(button: Button) -> void:
	if not active or not focused: return
	hover = button
	button.grab_focus()
	_refresh(button)
	_hover_sound()

func _leave(button: Button) -> void:
	if hover == button: hover = null
	_refresh(button)

func _focus(button: Button) -> void:
	last_focus = button
	if hover != null and hover != button:
		var previous = hover
		hover = null
		_refresh(previous)
	_refresh(button)
	_hover_sound()

func _hover_sound() -> void:
	var now = Time.get_ticks_msec()
	if not active or not focused or muted or now - last_sound < 75: return
	last_sound = now
	$HoverSound.play()

func _down(button: Button) -> void:
	if not active or not focused: return
	_refresh(button, false, true)
	if muted or button == $Sound/Off or (button.toggle_mode and button.button_pressed): return
	$ConfirmSound.play()

func _refresh(button: Button, instant: bool = false, pressed: bool = false) -> void:
	if tweens.has(button):
		tweens[button].kill()
		tweens.erase(button)
	var lit = active and focused and (hover == button or button.has_focus())
	var wash_alpha = (0.3 if pressed else 0.15) if lit else 0.0
	var line_alpha = 1.0 if lit else (0.85 if button.button_pressed else 0.0)
	if button == $Help: line_alpha = 0.9 if lit else 0.0
	var wash = button.get_node("Wash")
	var line = button.get_node("Underline")
	if instant or reduced:
		wash.modulate.a = wash_alpha
		line.modulate.a = line_alpha
	else:
		var tween = create_tween().set_parallel(true)
		tweens[button] = tween
		tween.tween_property(wash, "modulate:a", wash_alpha, 0.12)
		tween.tween_property(line, "modulate:a", line_alpha, 0.12)
	if button == $Close:
		$Close/Fill.modulate = Color(0.86, 0.8, 0.67, 1) if pressed else Color(1, 1, 1, 1 if lit else 0.88)
