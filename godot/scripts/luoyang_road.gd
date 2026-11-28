extends Node2D
## One authored projection drives nodes and gameplay-ground placement.
@export var depth_scale = 18.0
@export var far_lane_width = 0.0
@export_range(1.5, 4.0, 0.1) var max_near_scale = 3.0
@onready var horizon: Marker2D = $Horizon
@onready var player_line: Marker2D = $PlayerLine
@onready var lane_edge: Marker2D = $LaneEdge

func factor(depth: float) -> float:
	# Continue past the rider until foreground artwork is below the viewport.
	# Cap only the offscreen near plane, before the perspective denominator reaches zero.
	var nearest_depth = depth_scale * (1.0 / max_near_scale - 1.0)
	return 1.0 / (1.0 + maxf(nearest_depth, depth) / depth_scale)

func project(lane: float, depth: float) -> Vector2:
	var t = factor(depth)
	var center = horizon.position.lerp(player_line.position, t)
	var width = lerpf(far_lane_width, lane_edge.position.x - player_line.position.x, t)
	return center + Vector2(lane * width, 0.0)
