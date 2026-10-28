extends Node
## Weather, separate from the time of day: Clear or Rain (RAIN button, O, --weather=).
## Rain sets in and clears over a few seconds; the streets get wet as it starts and
## dry more slowly after it stops. Two numbers drive everything:
##   amount  0..1, how hard it rains: the streaks in the post pass, the rain bed, the
##           overcast light (time_of_day.gd set_weather)
##   wet     0..1, how wet the streets are: the shader global `wetness` (darker asphalt,
##           sheen, puddles with ripples, the lights' reflections in post.gdshader),
##           less grip (car.gd), the tyres' hiss (sfx.gd)

## Loop 2b: time spent in this script's per-frame work since the bench last read it (µs).
var spent_usec := 0

signal changed(state: int)

enum { CLEAR, RAIN }
const NAMES := ["Clear", "Rain"]
## Seconds for the rain to start or stop; the streets dry three times slower.
const BLEND := 4.0

var state := CLEAR
var amount := 0.0
var wet := 0.0
## Quality: how many streaks (1 = all).
var density := 1.0
var tod: Node
var post: ShaderMaterial


static func parse(text: String) -> int:
	return RAIN if text.to_lower() in ["rain", "wet", "deszcz", "1"] else CLEAR


func set_state(s: int, instant := false) -> void:
	state = s % NAMES.size()
	if instant:
		amount = 1.0 if state == RAIN else 0.0
		wet = amount
	_apply()
	changed.emit(state)


func toggle() -> void:
	set_state(RAIN if state == CLEAR else CLEAR)


func _process(dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	_frame(dt)
	spent_usec += Time.get_ticks_usec() - t0


func _frame(dt: float) -> void:
	var target := 1.0 if state == RAIN else 0.0
	if amount == target and wet == target:
		return
	amount = move_toward(amount, target, dt / BLEND)
	wet = move_toward(wet, target, dt / (BLEND * (1.0 if target > wet else 3.0)))
	_apply()


func _apply() -> void:
	RenderingServer.global_shader_parameter_set("wetness", wet)
	RenderingServer.global_shader_parameter_set("rain", amount)
	if post != null:
		post.set_shader_parameter("rain", amount * density)
	if tod != null:
		tod.set_weather(amount)


## Re-applies the current state (after the quality changed the streaks' density).
func refresh() -> void:
	_apply()
