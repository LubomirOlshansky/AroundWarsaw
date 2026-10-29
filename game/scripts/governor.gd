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
## - Loop G1b: the session's **tally** for Auto's sharp image (below, `track`), which says whether
##   the session struggled (`struggle`) or was calm (`calm`).

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

## Loop G1b: the session's tally for Auto's sharp image and its fallback (tiers.gd SHARP_*,
## main.gd). It counts while `track` (Auto, where the level's budget binds), not held, past
## SETTLE since a (re)start or a gap (loads, pauses, the background) and not in a wide view (no
## raise can come there, so a drop would sit out the flight): the seconds counted (`played_s`),
## those with the GPU's extras dropped by a GPU-bound load while it counted (`gpu_down_s`; not
## the GPU's taken by a CPU-bound load once the CPU's were gone, nor a drop in a wide view or
## before it counted), the refreshes, the missed ones, and those missed by frames whose own CPU
## work was under CPU_SHARE of the interval (`gpu_missed`: the GPU-bound ones; a CPU-bound miss
## can't be helped by a coarser image and doesn't count); and by counted minute (`minutes`), the
## minutes with over STRUGGLE_SHARE of their refreshes missed GPU-bound (`bad_minutes`).
## - **Struggled** (latched for the session) when the GPU's extras were down STRUGGLE_DOWN s in
##   all and at least STRUGGLE_PART of the counted play: one drop that a calm half minute undoes
##   is 30 s (a passing load); a second one, or one that didn't make the frames calm, is the image
##   itself; the share keeps a long session's two or three passing loads from counting (a
##   15-minute drive needs 90 s down). Or when STRUGGLE_MINUTES counted minutes in a row missed
##   over STRUGGLE_SHARE of their refreshes GPU-bound: a steady loss under the governor's 5 %
##   that never drops a level (2 %: a refresh missed every 0.8 s; a cool iPhone 11 at ×1 missed
##   0 in 3 minutes); minutes in a row, so passing bursts (one 10-second burst marks one or two
##   minutes) can't add up to it.
## - **Calm** after CALM_AFTER s counted without that (3 minutes: the G1 soak's length; shorter
##   sessions say nothing either way).
## restart() (the quality changed) starts the tally afresh.
const STRUGGLE_DOWN := 60.0
const STRUGGLE_PART := 0.1
const STRUGGLE_SHARE := 0.02
const STRUGGLE_MINUTES := 3
const CALM_AFTER := 180.0

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
## Loop G1b: the tally (above).
var track := false
var played_s := 0.0
var gpu_down_s := 0.0
var refreshes := 0
var missed := 0
var gpu_missed := 0
var minutes := 0
var bad_minutes := 0
## The last counted minute, for the log (main.gd prints it with --governor=log and clears it):
## "minute 3: 59.9 fps, missed 2 (GPU-bound 2), GPU extras down 0 s, GPU 2/2 · CPU 2/2".
var minute_line := ""
var _gpu_late_n := 0
## Why the session struggled ("": it hasn't), latched; and whether it has been calm long enough.
var _struggle := ""
var _calm := false
## Bad minutes in a row.
var _bad_run := 0
## The minute being counted: seconds, refreshes, missed, GPU-bound missed, GPU extras down.
var _m := [0.0, 0, 0, 0, 0.0]
## Loop G1b: the GPU drops in force that count for the tally: GPU-bound and made while it counts.
## Not one a CPU-bound load made (it takes the GPU's extras once the CPU's are gone) or one made
## in a wide view (it would count in the narrow view after it until it is raised back).
var _gpu_bound := 0

## The drops in force, oldest first: "gpu", "cpu", or (loop G1b) "gpu-x", a GPU drop that doesn't
## count for the tally.
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
	# Loop G1b: the tally too.
	_gpu_bound = 0
	played_s = 0.0
	gpu_down_s = 0.0
	refreshes = 0
	missed = 0
	gpu_missed = 0
	minutes = 0
	bad_minutes = 0
	minute_line = ""
	_struggle = ""
	_calm = false
	_bad_run = 0
	_m = [0.0, 0, 0, 0, 0.0]
	reset(now)


## Count afresh from `now` (after a pause or a gap), keeping the levels.
func reset(now: float) -> void:
	_frames.clear()
	_late.clear()
	_cpu.clear()
	_n = 0
	_late_n = 0
	_gpu_late_n = 0
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
	# Loop G1b: the GPU-bound ones, for the tally.
	if m > 0 and work_ms <= CPU_SHARE * interval_ms:
		_gpu_late_n += m


## Call every frame with the clock (s) and whether the view is wide (or flying); returns a
## `governor:` line when a level changed, else "".
func tick(now: float, wide: bool) -> String:
	if _last_tick < 0.0 or now - _last_tick > GAP:
		reset(now)
		return ""
	# Loop G1b: the tally counts the time since the last tick, and the refreshes by the bucket.
	var counting := track and not held and not wide and now - _start >= SETTLE
	if counting:
		var dt := now - _last_tick
		played_s += dt
		_m[0] += dt
		if _gpu_bound > 0:
			gpu_down_s += dt
			_m[4] += dt
	_last_tick = now
	if now - _bucket_t < EVERY:
		return ""
	_bucket_t = now
	if counting:
		refreshes += _n
		missed += _late_n
		gpu_missed += _gpu_late_n
		_m[1] += _n
		_m[2] += _late_n
		_m[3] += _gpu_late_n
		_tally_bucket()
	_gpu_late_n = 0
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
			_drops.append("cpu")
		elif cpu_bound or not counting:
			gpu -= 1
			_drops.append("gpu-x")
		else:
			gpu -= 1
			_drops.append("gpu")
			_gpu_bound += 1
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
		if up == "gpu":
			_gpu_bound -= 1
	_last_change = now
	_last_raise = now
	changes += 1
	return "governor: raise %s → %s · %.2f%% of refreshes missed in the last %.0f s" % ["CPU" if up == "cpu" else "GPU",
			state(), 100.0 * r[1] / r[0], raise_after]


## "GPU 2/2 · CPU 2/2".
func state() -> String:
	return "GPU %d/%d · CPU %d/%d" % [gpu, TOP, cpu, TOP]


## Loop G1b: after a counted bucket: the minute closes every 60 s counted, and the struggle rule.
func _tally_bucket() -> void:
	if _m[0] >= 60.0:
		minutes += 1
		var bad: bool = _m[3] > STRUGGLE_SHARE * _m[1]
		if bad:
			bad_minutes += 1
			_bad_run += 1
		else:
			_bad_run = 0
		minute_line = "minute %d: %.1f fps, missed %d of %d (GPU-bound %d%s), GPU extras down %.0f s, %s" % [minutes,
				(_m[1] - _m[2]) / _m[0], _m[2], _m[1], _m[3], ", over %.0f %%" % (STRUGGLE_SHARE * 100.0) if bad else "",
				_m[4], state()]
		_m = [0.0, 0, 0, 0, 0.0]
	if _struggle != "":
		return
	if gpu_down_s >= maxf(STRUGGLE_DOWN, STRUGGLE_PART * played_s):
		_struggle = "GPU extras down %.0f s of %.0f" % [gpu_down_s, played_s]
	elif _bad_run >= STRUGGLE_MINUTES:
		_struggle = "%d minutes in a row missed over %.0f%% of refreshes, GPU-bound" % [_bad_run, STRUGGLE_SHARE * 100.0]
	elif played_s >= CALM_AFTER:
		_calm = true


## Loop G1b: whether the session struggled (latched; cheap, main.gd asks every frame).
func struggled() -> bool:
	return _struggle != ""


## Loop G1b: why it struggled ("GPU extras down 74 s of 410", "3 of 5 minutes missed over 2% of
## refreshes, GPU-bound"), or "".
func struggle() -> String:
	return _struggle


## Loop G1b: the session was calm (CALM_AFTER s counted, no struggle; a struggle after it wins).
func calm() -> bool:
	return _calm and _struggle == ""


## Loop G1b: the tally for the log: "tally 912 s, GPU extras down 0 s, missed 3 of 54720 (GPU-bound 3)".
func tally() -> String:
	return "tally %.0f s, GPU extras down %.0f s, missed %d of %d (GPU-bound %d)" % [played_s, gpu_down_s, missed,
			refreshes, gpu_missed]


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
