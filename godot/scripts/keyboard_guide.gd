extends Control
## Display-only key animation. It never synthesizes gameplay input.
const CYCLE = 14.6
var clock = 0.0
var opened = false
var reduced = false
var suspended = false
var caps: Array[Control] = []

func _ready() -> void:
 for cap in $Keys.get_children():
  caps.append(cap)
  cap.get_node("AnimationPlayer").play("press")
  cap.get_node("AnimationPlayer").advance(0)

func set_demo_state(showing: bool, reduce_motion: bool, focused: bool, notice: String = "") -> void:
 if showing != opened:
  clock = 0
  _rest()
 opened = showing
 suspended = not focused
 if reduced != reduce_motion:
  reduced = reduce_motion
  _rest()
 $Notice.text = notice
 $Notice.visible = not notice.is_empty()

func _rest() -> void:
 for cap in caps:
  cap.get_node("AnimationPlayer").seek(0, true)

func _process(dt: float) -> void:
 if not opened or reduced or suspended or not is_visible_in_tree(): return
 clock = fmod(clock + dt, CYCLE)
 for cap in caps:
  var phase = 0.0
  for start in cap.get_meta("press_at"):
   if clock >= start and clock < start + .64:
    phase = clock - start
    break
  cap.get_node("AnimationPlayer").seek(phase, true)
