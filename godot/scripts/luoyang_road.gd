extends Node2D
## One authored projection drives nodes and gameplay-ground placement.
@export var depth_scale = 18.0
@export var far_lane_width = 0.0
@onready var horizon: Marker2D = $Horizon
@onready var player_line: Marker2D = $PlayerLine
@onready var lane_edge: Marker2D = $LaneEdge

func factor(depth: float) -> float:
	return 1.0 / (1.0 + maxf(-4.0, depth) / depth_scale)

func project(lane: float, depth: float) -> Vector2:
	var t = factor(depth)
	var center = horizon.position.lerp(player_line.position, t)
	var width = lerpf(far_lane_width, lane_edge.position.x - player_line.position.x, t)
	return center + Vector2(lane * width, 0.0)
