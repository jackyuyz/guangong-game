extends "res://scripts/main.gd"
## Disposable test instrumentation; excluded from exports.
var writes = 0
func _save() -> void:
	writes += 1
	super._save()
