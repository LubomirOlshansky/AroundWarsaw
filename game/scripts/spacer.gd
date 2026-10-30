extends Node
## Loop MW-6 (docs/design/vision.md 4.3): Spacer, wander mode (Settings → Jazda → Tryb: Miasto /
## Spacer; Miasto stays the default, Spacer is offered once after the first pause: Open Question
## 7). In Spacer nothing comes by itself: no rescue calls (missions.gd `calls_off`), no Podwózka
## request unless the PODWÓZKA button is tapped (rides.gd `quiet`), the rivals don't call out
## their challenge (rivals.gd `quiet`; flashing the lights still starts a race), the police's
## speed traps give the warning only and never chase (police.gd `gentle`), and a rescue started
## by hand runs without its clock. The radio already prefers PÓŁNOC FM at night and KEBAB FM by
## day and at dusk (radio.gd, loop MW-5). Every HINT_GAP s (3-5 min, seeded) a soft hint: the
## screen-edge arrow (hud.gd `set_target`, main.gd `_show_target`) points at the nearest
## notebook place not found yet, for HINT_SHOW s or until the city is tapped.
##
## Checked twice a second (one pass over the notebook's 72 places when a hint is due); nothing
## per frame.

signal changed(on: bool)

const CHECK_EVERY := 0.5
## Seconds between two hints (a seeded pick in this range) and how long one shows.
const HINT_GAP := Vector2(180.0, 300.0)
const HINT_SHOW := 15.0
## The hint's colour (the notebook's gold) and how far a place may be (m).
const HINT_COLOUR := Color("#f0b429")
const HINT_REACH := 1500.0

var on := false
## notebook.gd: its places and the record.
var notebook: Node
## [position Vector3, away (the title, the bench)] (main.gd).
var probe: Callable
var log_on := true
var spent_usec := 0
## The hint shown now: the place's id ("" for none), its point and the seconds it has left.
var hint_id := ""
var hint_at := Vector2.INF
var hints := 0
var _left := 0.0
var _next := 0.0
var _t := 0.0
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 4300


## Spacer on or off; `first_hint` s to the first hint (-1: a seeded 3-5 min).
func set_on(v: bool, first_hint := -1.0) -> void:
	var was := on
	on = v
	dismiss()
	_next = first_hint if first_hint >= 0.0 else _rng.randf_range(HINT_GAP.x, HINT_GAP.y)
	if was != v:
		print("spacer: %s" % ("on (wander: nothing comes by itself)" if v else "off (Miasto)"))
		changed.emit(v)


func _process(dt: float) -> void:
	if not on or not probe.is_valid():
		return
	_t += dt
	if _t < CHECK_EVERY:
		return
	var step := _t
	_t = 0.0
	var t0 := Time.get_ticks_usec()
	var s: Array = probe.call()
	tick(s[0], bool(s[1]), step)
	spent_usec += Time.get_ticks_usec() - t0


## One check: the hint's time runs out, or the next is due.
func tick(pos: Vector3, away: bool, dt: float) -> void:
	if away:
		return
	if hint_id != "":
		_left -= dt
		if _left <= 0.0:
			if log_on:
				print("spacer: hint to %s gone" % hint_id)
			dismiss()
		return
	_next -= dt
	if _next > 0.0:
		return
	_next = _rng.randf_range(HINT_GAP.x, HINT_GAP.y)
	var best := nearest_unfound(Vector2(pos.x, pos.z))
	if best.is_empty():
		return
	hint_id = str(best["id"])
	hint_at = best["at"]
	_left = HINT_SHOW
	hints += 1
	if log_on:
		print("spacer: hint %d -> %s (%s), %.0f m; next in %.0f s" % [hints, hint_id, best["name_pl"],
				hint_at.distance_to(Vector2(pos.x, pos.z)), _next])


## The nearest notebook place not found yet within HINT_REACH m of `p` ({} if none).
func nearest_unfound(p: Vector2) -> Dictionary:
	if notebook == null:
		return {}
	var best: Dictionary = {}
	var best_d := HINT_REACH
	for place: Dictionary in notebook.places:
		if notebook.is_found(str(place["id"])):
			continue
		var at: Vector2 = place["at"]
		var d := p.distance_to(at)
		if d < best_d:
			best_d = d
			best = place
	return best


## The hint away (its time ran out, the city was tapped, or the place was found).
func dismiss() -> void:
	hint_id = ""
	hint_at = Vector2.INF
	_left = 0.0


func hint_shown() -> bool:
	return on and hint_id != ""
