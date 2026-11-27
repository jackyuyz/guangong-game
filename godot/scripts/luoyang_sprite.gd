extends Node2D
## Explicitly sampled by the chapter clock: no independent timer can outlive pause.
@export var frames: Array[AtlasTexture] = []
var pose_index = 0

func pose(index: int) -> void:
	pose_index = clampi(index, 0, frames.size() - 1)
	$Body/Sprite.texture = frames[pose_index]
	$Body/Sprite.offset = -Vector2(frames[pose_index].get_meta("ground_pivot"))
