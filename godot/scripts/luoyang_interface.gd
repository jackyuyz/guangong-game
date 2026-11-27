extends "res://scripts/wuxia_feedback.gd"
## Chapter controls reuse the first chapter's theme, sound policy and brush feedback.
func _ready() -> void:
	var ui = get_parent().get_node("UI")
	for button in ui.find_children("*", "Button", true, false):
		if ui.get_node("Overlay/Settings").is_ancestor_of(button): continue
		var style = button.get_theme_stylebox("hover")
		if style is StyleBoxTexture and button.theme_type_variation != &"WuxiaPrimary":
			var copy = style.duplicate()
			copy.modulate_color.a = 0.0
			button.add_theme_stylebox_override("hover", copy)
			button.add_theme_stylebox_override("focus", copy)
			hover_styles[button] = copy
		button.mouse_entered.connect(_enter.bind(button))
		button.mouse_exited.connect(_leave.bind(button))
		button.focus_entered.connect(_focus.bind(button))
		button.focus_exited.connect(_leave.bind(button))
		button.button_down.connect(_press.bind(button))

func allowed(button: Button) -> bool:
	if not is_instance_valid(game) or not game.window_active or button.disabled or not button.is_visible_in_tree(): return false
	var ui = game.get_node("UI")
	if game.overlay.visible:
		return not game.settings_open and ui.get_node("Overlay/Panel").is_ancestor_of(button)
	if game.model.state == "culture": return ui.get_node("Culture").is_ancestor_of(button)
	return not ui.get_node("Overlay").is_ancestor_of(button)

func present(owner_game: Node) -> void:
	game = owner_game
	var next_section = "%s:%s:%s:%s" % [game.model.state, game.help_open, game.exit_confirmation, game.settings_open]
	var changed = section != next_section or reduced != game.reduced_motion
	reduced = game.reduced_motion
	if changed or not game.window_active:
		hovered = null
		selected = get_viewport().gui_get_focus_owner() as Button
		for button in hover_styles: _paint(button, allowed(button) and button == selected, true)
	if section != next_section or game.muted or not game.window_active: $Hover.stop()
	if game.muted or not game.window_active: $Confirm.stop()
	section = next_section
	last_muted = game.muted
