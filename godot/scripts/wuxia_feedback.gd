extends Node
## One sound policy for the shared theme; buttons keep their native hit areas.
var game: Node
var last_hover = -1000
var last_muted = false
var section = ""
var hover_styles: Dictionary = {}
var tweens: Dictionary = {}
var hovered: Button
var selected: Button
var reduced = false

func _ready() -> void:
	var ui = get_parent().get_node("Root")
	for button in ui.find_children("*", "Button", true, false):
		if ui.get_node("MainMenu").is_ancestor_of(button) or ui.get_node("Utility/Settings").is_ancestor_of(button): continue
		var style = button.get_theme_stylebox("hover")
		if style is StyleBoxTexture and button.theme_type_variation != &"WuxiaPrimary":
			var copy = style.duplicate()
			copy.modulate_color.a = 0
			button.add_theme_stylebox_override("hover", copy)
			button.add_theme_stylebox_override("focus", copy)
			hover_styles[button] = copy
		button.mouse_entered.connect(_enter.bind(button))
		button.mouse_exited.connect(_leave.bind(button))
		button.focus_entered.connect(_focus.bind(button))
		button.focus_exited.connect(_leave.bind(button))
		button.button_down.connect(_press.bind(button))

func present(owner_game: Node) -> void:
	game = owner_game
	var next_section = game.state + ":" + game.utility_panel + (":culture" if game.show_culture else "")
	var changed = section != next_section or reduced != game.reduced_motion
	reduced = game.reduced_motion
	if changed or not game.window_active:
		hovered = null
		selected = get_viewport().gui_get_focus_owner() as Button
		for button in hover_styles:
			_paint(button, game.window_active and allowed(button) and button == selected, true)
	if section != next_section or game.muted or not game.window_active:
		$Hover.stop()
	if game.muted or not game.window_active: $Confirm.stop()
	if last_muted and not game.muted and game.window_active and not game.utility_panel == "settings":
		$Confirm.play()
	section = next_section
	last_muted = game.muted

func allowed(button: Button) -> bool:
	if not is_instance_valid(game) or not game.window_active or button.disabled or not button.is_visible_in_tree(): return false
	var ui = get_parent().get_node("Root")
	if not game.utility_panel.is_empty(): return ui.get_node("Utility").is_ancestor_of(button)
	if game.show_culture: return ui.get_node("Culture").is_ancestor_of(button)
	if game.state == "prologue" and game.prologue.more_open:
		return button in [game.prologue.get_node("ReplayVoice"), game.prologue.get_node("More")]
	return true

func _enter(button: Button) -> void:
	if not allowed(button): return
	# Map markers retain their authored selection behavior; hovering does not travel.
	if button.focus_mode != Control.FOCUS_NONE and button.theme_type_variation != &"WuxiaMapStop": button.grab_focus()
	if hovered != null and hovered != button: _paint(hovered, false)
	hovered = button
	_paint(button, true)
	_hover(button)

func _focus(button: Button) -> void:
	if not allowed(button): return
	if selected != null and selected != button: _paint(selected, false)
	if hovered != null and hovered != button:
		_paint(hovered, false)
		hovered = null
	selected = button
	_paint(button, true)
	_hover(button)

func _leave(button: Button) -> void:
	if hovered == button and not button.has_focus(): hovered = null
	_paint(button, allowed(button) and button.has_focus())

func _paint(button: Button, lit: bool, instant: bool = false) -> void:
	if not hover_styles.has(button): return
	var style: StyleBoxTexture = hover_styles[button]
	var alpha = 0.16 if lit else 0.0
	if tweens.has(button):
		if tweens[button].is_valid() and is_equal_approx(tweens[button].get_meta("target"), alpha) and not instant and not reduced: return
		tweens[button].kill()
		tweens.erase(button)
	if reduced or instant: style.modulate_color.a = alpha
	else:
		var tween = create_tween()
		tween.set_meta("target", alpha)
		tween.tween_property(style, "modulate_color:a", alpha, 0.12)
		tweens[button] = tween

func _hover(button: Button) -> void:
	if not allowed(button) or game.muted: return
	var now = Time.get_ticks_msec()
	if now - last_hover < 75: return
	last_hover = now
	$Hover.play()

func _press(button: Button) -> void:
	if not allowed(button) or game.muted: return
	if button.get_meta("action", "") == "mute": return
	$Confirm.play()
