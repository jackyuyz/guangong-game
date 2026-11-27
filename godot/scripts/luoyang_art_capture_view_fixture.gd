extends "res://scripts/luoyang_chapter.gd"
## Capture-only: OS focus is nondeterministic when drawing several stages in one frame.
## Production keeps its normal focus pause handler; this fixture never owns a save.
func _pause_for_focus_loss() -> void:
	pass
