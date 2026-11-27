extends RefCounted
## Authored beats: singles, lane-reading pairs, then a breath before the next group.
## Times are stage seconds, not wall-clock timers. Suppressed beats are consumed.
const ROWS = [
	[1.4, [0]], [4.8, [-1]], [8.2, [1]],
	[12.3, [-1, 0]], [15.1, [0]], [17.9, [0, 1]],
	[21.9, [-1, 1]], [24.5, [1]], [26.7, [-1, 0]],
	[30.8, [0, 1]], [33.4, [0]], [36.0, [-1, 1]],
	[40.0, [-1]], [42.6, [0, 1]], [45.2, [-1, 0]],
	[49.2, [0]], [51.8, [-1, 1]], [54.4, [1]]]
const SHOTS = [1.8, 6.3, 10.6, 14.5, 17.8, 21.1, 24.4, 27.6]
const FIRST_SHOT = {"aim_seconds": 1.35, "lock_seconds": 0.75, "speed": 64.0}
const REGULAR_SHOT = {"aim_seconds": 1.0, "lock_seconds": 0.55, "speed": 76.0}
const LATE_SHOT = {"aim_seconds": 0.9, "lock_seconds": 0.45, "speed": 82.0}
const READABLE_DEPTH = 55.0
const GAP_IMPACT = 3.0
const GAP_RECOIL_SECONDS = 0.6

static func shot_profile(index: int) -> Dictionary:
	return FIRST_SHOT if index == 0 else (REGULAR_SHOT if index < 4 else LATE_SHOT)
