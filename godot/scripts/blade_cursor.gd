extends Node2D
## The resting tip follows the click position. Animation pivots around the grip.

@onready var _grip: Node2D = $Grip
@onready var _arc: Line2D = $Arc
@onready var _tip_from_grip: Vector2 = -_grip.position
const WINDUP_ANGLE = deg_to_rad(12.0)
const STRIKE_ANGLE = deg_to_rad(-40.0)
var _swing: Tween

func _ready() -> void:
	hide()
	get_window().mouse_exited.connect(_hide_cursor)
	get_window().focus_exited.connect(_hide_cursor)

func _input(event: InputEvent) -> void:
	if not event is InputEventMouse or event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	position = event.position
	if not get_window().has_focus() or not get_viewport_rect().has_point(position):
		_hide_cursor()
	elif not visible and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
		show()

func on_button_input(event: InputEvent, button: Button) -> void:
	if not event is InputEventMouseButton or event.device == InputEvent.DEVICE_ID_EMULATION:
		return
	if event.button_index != MOUSE_BUTTON_LEFT or not event.pressed or button.disabled:
		return
	_reset_swing()
	_swing = create_tween()
	_swing.tween_property(_grip, "rotation", WINDUP_ANGLE, 0.035).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_swing.tween_method(_swing_down, WINDUP_ANGLE, STRIKE_ANGLE, 0.065).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_swing.tween_property(_grip, "rotation", 0.0, 0.10).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_swing.parallel().tween_property(_arc, "self_modulate:a", 0.0, 0.10)

func _swing_down(angle: float) -> void:
	_grip.rotation = angle
	_arc.self_modulate.a = 1.0
	_arc.clear_points()
	for index in range(9):
		var trail_angle := lerpf(WINDUP_ANGLE, angle, float(index) / 8.0)
		_arc.add_point(_tip_from_grip.rotated(trail_angle))

func _reset_swing() -> void:
	if _swing:
		_swing.kill()
	_grip.rotation = 0.0
	_arc.self_modulate.a = 0.0
	_arc.clear_points()

func _hide_cursor() -> void:
	if not visible:
		return
	hide()
	if Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_reset_swing()

func _exit_tree() -> void:
	_hide_cursor()
