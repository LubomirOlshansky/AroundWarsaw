extends RefCounted
## The main line on the driving screen (docs/design/main-line.md 3, QUESTIONS 2026-10-31 "the
## main line"): after the guide the gold star lived on the minimap and the full map only, so a
## player who finished the first ten minutes had nothing on the screen saying where the story
## goes on. This nudge, looked at with main_line.gd's step (main.gd `_main_line_tick`):
## - a goal line (a toast "★ Znajdź i mrugnij: Słoik z Radomia") TOAST_DELAY s after the step
##   changes to one of LINES, once the player is free (so it never sits on the ladder's own
##   "New rival" toast or a job's card);
## - the screen-edge arrow in the main line's gold ("★ 640 m") for SHOW s when the step changes to
##   one with a place (PLACES: the next rival, the final's start at night), and again after GAP s
##   of free driving, so it comes back now and then instead of standing on the screen for good.
## Free means nothing else is on (no job, race, rescue, ride, quest pin, guide or Spacer hint:
## main.gd `_free_now`); busy pauses the arrow and restarts the free count. `quiet` (the title,
## a camera moment, Spacer, where nothing comes by itself) holds both. Pure state, no nodes:
## check_main_line.gd drives it with made-up steps.

## Seconds the gold arrow shows per nudge (Spacer's soft hint shows 15 s; this one is the story).
const SHOW := 25.0
## Seconds of free driving before the arrow comes back.
const GAP := 150.0
## Seconds after a step change before its goal line (the ladder's own toast lasts 3 s).
const TOAST_DELAY := 4.0
## Steps (main_line.gd ids) whose change brings the arrow: they have a place on the map.
const PLACES := ["rival", "final"]
## Steps whose change brings the goal line (the guide's own ids have the guide's toasts; "done"
## has no line).
const LINES := ["rival", "final", "respect", "wait_night", "jobs"]

var _id := ""
var _show_left := 0.0
var _free_t := 0.0
var _toast_in := -1.0


## One look, `dt` s after the last, with the main line's `step` (main_line.gd `step`). Returns
## {"arrow": bool (draw the gold edge arrow to step.at now), "toast": bool (show the goal line
## now)}.
func tick(dt: float, step: Dictionary, free: bool, quiet: bool) -> Dictionary:
	var id := str(step.get("id", ""))
	if id != _id:
		_id = id
		_free_t = 0.0
		_toast_in = TOAST_DELAY if id in LINES else -1.0
		_show_left = SHOW if id in PLACES else 0.0
	var out := {"arrow": false, "toast": false}
	if not free or quiet:
		_free_t = 0.0
		return out
	if _toast_in >= 0.0:
		_toast_in -= dt
		if _toast_in <= 0.0:
			_toast_in = -1.0
			out["toast"] = true
	var placed: bool = step.get("at", Vector2.INF) != Vector2.INF
	if _show_left > 0.0:
		_show_left -= dt
		out["arrow"] = placed
		return out
	_free_t += dt
	if _free_t >= GAP and id in PLACES:
		_free_t = 0.0
		_show_left = SHOW
		out["arrow"] = placed
	return out


## Seconds the arrow has left (check_main_line.gd).
func show_left() -> float:
	return maxf(_show_left, 0.0)
