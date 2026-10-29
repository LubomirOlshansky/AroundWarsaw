extends RefCounted
## Loop G1: the frame governor (docs/design/graphics.md 4.3). It watches how many frames come
## late and steps the quality's extras down one level when too many do, and back up when the
## frames have been calm for a while. It never touches the pixel size, the shadow map's size
## (reallocating it hitches), the landmarks, the occlusion ghost, the river or the night lights:
## main.gd `_apply_extras` reads its two levels and applies only what they name.
##
## - Fed once a frame with the frame's wall-clock time and the main thread's CPU work (bench.gd:
##   physics + process; the rest of a frame is building it and waiting for the GPU and the
##   display). It counts **missed refreshes** against the display's clock (`miss_step`): each
##   frame adds its time less one frame interval (16.7 ms at the 60 fps cap, 33.3 at 30) to a
##   debt, every whole interval of debt is a refresh missed, and an early frame pays back only
##   what a late one borrowed; the late share is the missed refreshes over all the refreshes the
##   window lasted. Measured on the iPhone 11 (loop G1): with the display pacing the game,
##   1.6–16 % of frames come 1–8 ms past the interval and the next one that much early (59.95 fps
##   over a minute, every refresh drawn): a governor counting frames over the interval + 1 ms
##   would read that jitter as late, never get under RAISE_SHARE and never come back up. A
##   stall (a 61 ms frame: 3 refreshes) counts, and so do steady 20 ms frames (50 fps: one
##   refresh in six), which a per-frame threshold over 1.5 intervals would miss.
## - Decides every EVERY seconds. **Drop**: more than DROP_SHARE of the refreshes in the last
##   WINDOW seconds were missed, and in the last EVERY seconds too (a load that has just ended
##   drops nothing) → one level down: the CPU's extras (traffic and pedestrians) when
##   the late frames' CPU work averaged over CPU_SHARE of the interval (12.5 ms at 60: the main
##   thread itself made them late), else the GPU's (mirror-reflection
##   steps, then the small things' sun shadows); if that one is at the bottom, the other.
##   **Raise**: under RAISE_SHARE missed over the last `raise_after` seconds (RAISE_AFTER, doubled
##   up to RAISE_AFTER_MAX each time a drop came within that long of a raise, so it can't swing
##   back and forth), never in a wide view → the last drop is undone. At most one change every
##   HOLD seconds; nothing in the first SETTLE seconds after a (re)start or a gap (a pause, the
##   app in the background, a load).
## - `held` (the bench, the probe, the BENCH button, test runs): it counts but never changes.
## Every change returns a `governor:` line for the log.

## The top level (what the quality sets); 0 is the floor.
const TOP := 2
const EVERY := 0.5
const WINDOW := 3.0
const DROP_SHARE := 0.05
const RAISE_SHARE := 0.005
const RAISE_AFTER := 30.0
const RAISE_AFTER_MAX := 240.0
const HOLD := 10.0
const SETTLE := 5.0
const CPU_SHARE := 0.75
## A window of fewer refreshes than this decides nothing.
const MIN_FRAMES := 30
## A gap between ticks this long (s) starts the count afresh.
const GAP := 1.0
## What each level keeps of the quality's extras (index = level): the GPU's mirror-reflection
## steps (a share, rounded up) and the small things' sun shadows; the CPU's traffic share and
## pedestrians.
const REFLECT := [0.6, 0.6, 1.0]
const SMALL_SHADOWS := [false, true, true]
const TRAFFIC := [0.6, 0.8, 1.0]
const PEOPLE := [0.5, 0.7, 1.0]

var gpu := TOP
var cpu := TOP
var held := false
## The frame interval (ms) refreshes are counted in (main.gd: 1000 / the cap, 60 when uncapped).
var interval_ms := 1000.0 / 60.0
## Changes since the game started (drops and raises).
var changes := 0
var raise_after := RAISE_AFTER
## The last window's numbers, for the overlay and the logs: the share of refreshes missed
## (0..1) and the late frames' CPU work (ms, averaged by the refreshes they missed; 0: none).
var late_share := 0.0
var cpu_ms := 0.0

var _drops: Array[String] = []
var _start := 0.0
var _last_tick := -1.0
var _bucket_t := 0.0
var _last_change := -1e9
var _last_raise := -1e9
## Half-second buckets, newest last: refreshes, missed refreshes, the late frames' CPU ms
## summed (each × the refreshes it missed).
var _frames := PackedInt32Array()
var _late := PackedInt32Array()
var _cpu := PackedFloat32Array()
var _n := 0
var _late_n := 0
var _cpu_sum := 0.0
## How far the frames are behind one a refresh (ms; miss_step).
var _debt := 0.0


## One frame of `ms` against the display's clock: `debt` (ms) is how far the frames have fallen
## behind one per `interval`; the frame adds its time less an interval, the debt never goes
## below half an interval in credit (an early frame pays back only what jitter borrowed), and
## from half an interval on each whole interval of it is a refresh missed. Returns
## (the new debt, the refreshes this frame missed): (0, 3) for a 61 ms frame from no debt; one
## in five steady 20 ms frames misses one; a 20 ms frame and a 13.3 ms one miss none.
static func miss_step(debt: float, ms: float, interval: float) -> Vector2:
	debt = maxf(debt + ms - interval, -0.5 * interval)
	var m := 0.0
	if debt >= 0.5 * interval:
		m = floorf(debt / interval + 0.5)
		debt -= m * interval
	return Vector2(debt, m)


## Back to the top levels (the quality changed), counting afresh from `now` (s).
func restart(now: float) -> void:
	gpu = TOP
	cpu = TOP
	_drops.clear()
	raise_after = RAISE_AFTER
	_last_change = -1e9
	_last_raise = -1e9
	reset(now)


## Count afresh from `now` (after a pause or a gap), keeping the levels.
func reset(now: float) -> void:
	_frames.clear()
	_late.clear()
	_cpu.clear()
	_n = 0
	_late_n = 0
	_cpu_sum = 0.0
	_debt = 0.0
	_start = now
	_bucket_t = now
	_last_tick = now


## One frame: its wall-clock time and the main thread's CPU work, in ms.
func frame(ms: float, work_ms: float) -> void:
	var step := miss_step(_debt, ms, interval_ms)
	_debt = step.x
	var m := int(step.y)
	_n += 1 + m
	_late_n += m
	_cpu_sum += work_ms * m


## Call every frame with the clock (s) and whether the view is wide (or flying); returns a
## `governor:` line when a level changed, else "".
func tick(now: float, wide: bool) -> String:
	if _last_tick < 0.0 or now - _last_tick > GAP:
		reset(now)
		return ""
	_last_tick = now
	if now - _bucket_t < EVERY:
		return ""
	_bucket_t = now
	_frames.append(_n)
	_late.append(_late_n)
	_cpu.append(_cpu_sum)
	_n = 0
	_late_n = 0
	_cpu_sum = 0.0
	var keep := int(ceilf(RAISE_AFTER_MAX / EVERY)) + 1
	if _frames.size() > keep:
		_frames = _frames.slice(_frames.size() - keep)
		_late = _late.slice(_late.size() - keep)
		_cpu = _cpu.slice(_cpu.size() - keep)
	var w := _window(WINDOW)
	late_share = w[1] / maxf(w[0], 1.0)
	cpu_ms = w[2] / maxf(w[1], 1.0)
	if held or now - _start < SETTLE:
		return ""
	# The newest half second must still be late too: a load that just ended drops nothing.
	var still := _late[_late.size() - 1] > DROP_SHARE * _frames[_frames.size() - 1]
	if w[0] >= MIN_FRAMES and late_share > DROP_SHARE and still and now - _last_change >= HOLD:
		var cpu_bound := cpu_ms > CPU_SHARE * interval_ms
		var which := ""
		if cpu_bound and cpu > 0:
			which = "cpu"
		elif gpu > 0:
			which = "gpu"
		elif cpu > 0:
			which = "cpu"
		if which == "":
			return ""
		if now - _last_raise < raise_after:
			raise_after = minf(raise_after * 2.0, RAISE_AFTER_MAX)
		if which == "cpu":
			cpu -= 1
		else:
			gpu -= 1
		_drops.append(which)
		_last_change = now
		changes += 1
		return "governor: drop %s → %s · %.1f%% of refreshes missed in the last %.0f s, the late frames' CPU work %.1f ms%s" % [
				which.to_upper(), state(), late_share * 100.0, WINDOW, cpu_ms, " (CPU-bound)" if cpu_bound else ""]
	if _drops.is_empty() or wide or now - _last_change < raise_after:
		return ""
	var r := _window(raise_after)
	if r[0] < MIN_FRAMES or r[1] >= RAISE_SHARE * r[0] or (r[3] as float) < raise_after - EVERY:
		return ""
	var up: String = _drops.pop_back()
	if up == "cpu":
		cpu += 1
	else:
		gpu += 1
	_last_change = now
	_last_raise = now
	changes += 1
	return "governor: raise %s → %s · %.2f%% of refreshes missed in the last %.0f s" % [up.to_upper(), state(),
			100.0 * r[1] / r[0], raise_after]


## "GPU 2/2 · CPU 2/2".
func state() -> String:
	return "GPU %d/%d · CPU %d/%d" % [gpu, TOP, cpu, TOP]


## The last `seconds` of buckets: [refreshes, missed, the late frames' CPU ms, seconds covered].
func _window(seconds: float) -> Array:
	var want := int(ceilf(seconds / EVERY))
	var f := 0
	var l := 0
	var c := 0.0
	var i := _frames.size() - 1
	var got := 0
	while i >= 0 and got < want:
		f += _frames[i]
		l += _late[i]
		c += _cpu[i]
		i -= 1
		got += 1
	return [float(f), float(l), c, got * EVERY]
