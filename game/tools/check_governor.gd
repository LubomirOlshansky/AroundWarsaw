extends SceneTree
## Loop G1: the frame governor's rules (scripts/governor.gd, the game's own) on scripted frames
## with a scripted clock, 60 fps cap:
##   - calm frames, and the display's jitter (a 20 ms frame, then a 13.3 ms one, as the iPhone 11
##     showed with every refresh drawn), change nothing in ten minutes; a 61 ms stall misses 3
##     refreshes and steady 20 ms frames one in six (governor.gd miss_step), which drops a level;
##   - a GPU-bound overload (every other frame a missed refresh, the CPU at 4 ms) drops the GPU's
##     level within 3 s, the next drop no sooner than 10 s later, the GPU's to the floor first,
##     then the CPU's; with both at the floor nothing changes;
##   - calm again: no raise before 30 s, then one level at a time, the last drop first, at least
##     30 s apart; never in a wide view (raises wait until the view is narrow);
##   - a CPU-bound overload (14 ms of CPU work) drops the CPU's level first;
##   - held (the bench), nothing changes; after a gap (a pause) nothing changes for 5 s;
##   - a load that comes back every minute (20 s on, 40 s off) for 15 minutes: the waits grow
##     after each raise the load undoes, and the last 5 minutes have no raise (no swinging).
## Loop G1b, the session's tally for Auto's sharp image (tracked sessions from 0 s): 15 calm
## minutes are calm at 185 s and never struggle; a GPU-bound overload struggles a minute after
## its first drop (GPU extras down 60 s); a CPU-bound one never (not even when it takes the GPU's
## extras); one passing 10-second load is calm; two 18 minutes apart are calm (under a tenth of
## the play), two within 3 minutes struggle; a phone that warms up after 8 calm minutes
## struggles a minute after its drop; a steady 2.9 % of refreshes missed GPU-bound (no drop)
## struggles after 3 minutes in a row, 1 % never, CPU-bound never; drops in a wide view don't
## count; gaps and the settle aren't counted; untracked or held, nothing is; restart() clears it.
## Prints `check_governor: OK` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_governor.gd

const Governor := preload("res://scripts/governor.gd")
const CALM := 16.67
const MISS := 33.33

var problems: Array[String] = []


## Runs `g` from `t0` for `seconds` of frames from `frame_fn(t) -> [ms, cpu ms]`, wide from
## `wide_fn(t)`; returns [the clock at the end, the changes: [t, line]].
func _run(g: Governor, t0: float, seconds: float, frame_fn: Callable, wide_fn: Callable = Callable()) -> Array:
	var t := t0
	var changes := []
	var i := 0
	while t < t0 + seconds:
		var f: Array = frame_fn.call(t, i)
		t += f[0] / 1000.0
		i += 1
		g.frame(f[0], f[1])
		var line := g.tick(t, wide_fn.is_valid() and wide_fn.call(t))
		if line != "":
			changes.append([t, line])
	return [t, changes]


## The refreshes a run of frames (ms) misses at 60 fps from no debt (Governor.miss_step).
func _misses(frames: Array) -> int:
	var debt := 0.0
	var n := 0
	for f in frames:
		var s := Governor.miss_step(debt, f, CALM)
		debt = s.x
		n += int(s.y)
	return n


func _expect(ok: bool, what: String) -> void:
	print("  %s %s" % ["ok  " if ok else "FAIL", what])
	if not ok:
		problems.append(what)


func _initialize() -> void:
	var calm := func(_t: float, _i: int) -> Array: return [CALM, 4.0]
	var jitter := func(_t: float, i: int) -> Array: return [20.0 if i % 2 == 0 else 13.33, 4.0]
	var gpu_over := func(_t: float, i: int) -> Array: return [MISS if i % 2 == 0 else CALM, 4.0]
	var cpu_over := func(_t: float, i: int) -> Array: return [MISS if i % 2 == 0 else CALM, 14.0]

	print("calm and jitter:")
	var g := Governor.new()
	g.restart(0.0)
	var r := _run(g, 0.0, 600.0, calm)
	_expect(r[1].is_empty(), "10 min of calm 60 fps frames: no change (%d)" % r[1].size())
	r = _run(g, r[0], 600.0, jitter)
	_expect(r[1].is_empty() and g.late_share == 0.0, "10 min of the display's jitter (20 / 13.3 ms): no change, 0 missed (%d, %.3f)" % [r[1].size(), g.late_share])
	var steady: Array = []
	steady.resize(30)
	steady.fill(20.0)
	_expect(_misses([61.0]) == 3 and _misses([24.0]) == 0 and _misses([26.0]) == 1 and _misses(steady) == 6
			and _misses([20.0, 13.33, 20.0, 13.33]) == 0,
			"refreshes missed: a 61 ms frame 3, 24 ms none, 26 ms one, 30 frames of 20 ms 6, the jitter none")

	print("GPU-bound overload:")
	g = Governor.new()
	g.restart(0.0)
	r = _run(g, 0.0, 20.0, calm)
	var onset: float = r[0]
	r = _run(g, onset, 120.0, gpu_over)
	var ch: Array = r[1]
	_expect(ch.size() == 4, "4 drops in 2 min of overload (%d)" % ch.size())
	if ch.size() >= 1:
		_expect(ch[0][0] - onset <= 3.0, "the first drop within 3 s (%.2f s)" % (ch[0][0] - onset))
		_expect(String(ch[0][1]).contains("drop GPU"), "the first drop is the GPU's: %s" % ch[0][1])
	for k in range(1, ch.size()):
		_expect(ch[k][0] - ch[k - 1][0] >= Governor.HOLD - 0.05, "drop %d %.1f s after the one before (>= %.0f)" % [k + 1, ch[k][0] - ch[k - 1][0], Governor.HOLD])
	if ch.size() == 4:
		_expect(String(ch[1][1]).contains("drop GPU") and String(ch[2][1]).contains("drop CPU") and String(ch[3][1]).contains("drop CPU"),
				"order: GPU, GPU, CPU, CPU")
	_expect(g.gpu == 0 and g.cpu == 0, "both at the floor (%s)" % g.state())
	var after_floor := _run(g, r[0], 60.0, gpu_over)
	_expect(after_floor[1].is_empty(), "at the floor, more overload changes nothing (%d)" % after_floor[1].size())

	print("calm again, raises (wide for the first 60 s):")
	var calm_t0: float = after_floor[0]
	var wide := func(t: float) -> bool: return t < calm_t0 + 60.0
	r = _run(g, calm_t0, 300.0, calm, wide)
	ch = r[1]
	_expect(ch.size() == 4, "4 raises in 5 min of calm (%d)" % ch.size())
	if ch.size() >= 1:
		_expect(ch[0][0] >= calm_t0 + 60.0, "no raise in the wide view (first at +%.1f s)" % (ch[0][0] - calm_t0))
		_expect(String(ch[0][1]).contains("raise CPU"), "the last drop (CPU) is undone first: %s" % ch[0][1])
	for k in range(1, ch.size()):
		_expect(ch[k][0] - ch[k - 1][0] >= Governor.RAISE_AFTER - 0.05, "raise %d %.1f s after the one before (>= %.0f)" % [k + 1, ch[k][0] - ch[k - 1][0], Governor.RAISE_AFTER])
	_expect(g.gpu == Governor.TOP and g.cpu == Governor.TOP, "back at the top (%s)" % g.state())

	print("CPU-bound overload:")
	g = Governor.new()
	g.restart(0.0)
	r = _run(g, 0.0, 10.0, calm)
	r = _run(g, r[0], 5.0, cpu_over)
	_expect(r[1].size() == 1 and String(r[1][0][1]).contains("drop CPU"), "the CPU's level first: %s" % [r[1]])

	print("steady 50 fps:")
	g = Governor.new()
	g.restart(0.0)
	r = _run(g, 0.0, 10.0, calm)
	r = _run(g, r[0], 5.0, func(_t: float, _i: int) -> Array: return [20.0, 4.0])
	_expect(r[1].size() == 1 and String(r[1][0][1]).contains("drop GPU"), "5 s of 20 ms frames: the GPU's level drops (%s)" % [r[1]])

	print("a load that ends:")
	g = Governor.new()
	g.restart(0.0)
	r = _run(g, 0.0, 20.0, calm)
	r = _run(g, r[0], 9.8, gpu_over)
	var ended := _run(g, r[0], 20.0, calm)
	_expect(r[1].size() == 1 and ended[1].is_empty(), "9.8 s of load: one drop, none once it is over (%d, %d)" % [r[1].size(), ended[1].size()])

	print("held, gaps:")
	g = Governor.new()
	g.restart(0.0)
	g.held = true
	r = _run(g, 0.0, 120.0, gpu_over)
	_expect(r[1].is_empty() and g.state() == "GPU 2/2 · CPU 2/2", "held: 2 min of overload, no change (%d)" % r[1].size())
	g.held = false
	r = _run(g, r[0], 30.0, calm)
	var gap_t: float = r[0] + 20.0
	r = _run(g, gap_t, 4.5, gpu_over)
	_expect(r[1].is_empty(), "overload in the first 4.5 s after a 20 s gap: no change (%d)" % r[1].size())
	r = _run(g, r[0], 2.0, gpu_over)
	_expect(r[1].size() == 1, "then it drops (%d)" % r[1].size())

	print("a load every minute, 15 min:")
	g = Governor.new()
	g.restart(0.0)
	var pulse := func(t: float, i: int) -> Array:
		return [MISS if i % 2 == 0 else CALM, 4.0] if fmod(t, 60.0) >= 10.0 and fmod(t, 60.0) < 30.0 else [CALM, 4.0]
	r = _run(g, 0.0, 900.0, pulse)
	ch = r[1]
	var raises := 0
	var late_raises := 0
	for c in ch:
		if String(c[1]).contains("raise"):
			raises += 1
			if c[0] > 600.0:
				late_raises += 1
	print("  %d changes (%d raises), raise wait now %.0f s, %s" % [ch.size(), raises, g.raise_after, g.state()])
	_expect(late_raises == 0, "no raise in the last 5 minutes (%d)" % late_raises)
	_expect(g.raise_after > Governor.RAISE_AFTER, "the wait grew (%.0f s)" % g.raise_after)
	_expect(ch.size() <= 12, "at most 12 changes in 15 minutes (%d)" % ch.size())

	_check_tally(calm, gpu_over, cpu_over)

	if problems.is_empty():
		print("check_governor: OK")
		quit(0)
	else:
		print("check_governor: %d problems" % problems.size())
		quit(1)


## Loop G1b: a tracked session from 0 s: [the parts [seconds, frame_fn, wide] run in turn], with
## a gap of `gap` seconds before part `gap_at` (-1: none); returns [the governor, when it first
## said struggled (-1: never), when it first said calm (-1: never)].
func _session(parts: Array, gap_at := -1, gap := 0.0) -> Array:
	var g := Governor.new()
	g.track = true
	g.restart(0.0)
	var t := 0.0
	var first_struggle := -1.0
	var first_calm := -1.0
	var i := 0
	for p in parts.size():
		if p == gap_at:
			t += gap
		var part: Array = parts[p]
		var end: float = t + part[0]
		while t < end:
			var f: Array = (part[1] as Callable).call(t, i)
			t += f[0] / 1000.0
			i += 1
			g.frame(f[0], f[1])
			g.tick(t, part[2])
			if first_struggle < 0.0 and g.struggled():
				first_struggle = t
			if first_calm < 0.0 and g.calm():
				first_calm = t
	return [g, first_struggle, first_calm]


func _check_tally(calm: Callable, gpu_over: Callable, cpu_over: Callable) -> void:
	print("the session's tally (loop G1b):")
	var r := _session([[900.0, calm, false]])
	var g: Governor = r[0]
	_expect(r[1] < 0.0 and absf(r[2] - (Governor.SETTLE + Governor.CALM_AFTER)) < 1.0 and absf(g.played_s - 895.0) < 1.0,
			"15 min calm: never struggled, calm at %.1f s (%.0f + %.0f), %.0f s counted" % [r[2], Governor.SETTLE, Governor.CALM_AFTER, g.played_s])
	r = _session([[20.0, calm, false], [300.0, gpu_over, false]])
	g = r[0]
	_expect(r[1] > 0.0 and r[1] - 20.0 <= 3.0 + Governor.STRUGGLE_DOWN + 1.0 and g.struggle().begins_with("GPU extras down"),
			"a GPU-bound overload from 20 s: struggled at %.1f s (%s)" % [r[1], g.struggle()])
	r = _session([[20.0, calm, false], [300.0, cpu_over, false]])
	g = r[0]
	_expect(r[1] < 0.0 and g.gpu_down_s == 0.0 and g.gpu_missed == 0 and g.missed > 0 and g.gpu == 0,
			"a CPU-bound overload (it takes the GPU's extras too): no struggle (%s, %s)" % [g.tally(), g.state()])
	r = _session([[20.0, calm, false], [9.8, gpu_over, false], [600.0, calm, false]])
	g = r[0]
	_expect(r[1] < 0.0 and r[2] > 0.0 and g.gpu_down_s >= 29.0 and g.gpu_down_s < Governor.STRUGGLE_DOWN and g.gpu == Governor.TOP
			and g.bad_minutes == 1,
			"a passing GPU load (9.8 s: one drop, raised after 30 s, one bad minute): calm, not struggled (%s)" % g.tally())
	r = _session([[120.0, calm, false], [9.8, gpu_over, false], [1080.0, calm, false], [9.8, gpu_over, false], [300.0, calm, false]])
	g = r[0]
	_expect(r[1] < 0.0 and r[2] > 0.0 and g.gpu_down_s >= Governor.STRUGGLE_DOWN,
			"two passing loads 18 minutes apart (%.0f s down, under a tenth of the play): calm, not struggled" % g.gpu_down_s)
	r = _session([[60.0, calm, false], [9.8, gpu_over, false], [120.0, calm, false], [9.8, gpu_over, false], [300.0, calm, false]])
	_expect(r[1] > 0.0, "two within 3 minutes (the image near its edge): struggled at %.0f s (%s)" % [r[1], (r[0] as Governor).struggle()])
	r = _session([[480.0, calm, false], [300.0, gpu_over, false]])
	_expect(r[1] > 480.0 and r[1] < 480.0 + 3.0 + Governor.STRUGGLE_DOWN + 1.0 and r[2] > 0.0,
			"a phone that warms up: calm at %.0f s, then a GPU-bound overload from 480 s struggles at %.1f s (%s)" % [r[2], r[1],
			(r[0] as Governor).struggle()])
	var every := func(n: int) -> Callable:
		return func(_t: float, i: int) -> Array: return [MISS if i % n == 0 else CALM, 4.0]
	r = _session([[300.0, every.call(34), false]])
	g = r[0]
	_expect(g.changes == 0 and r[1] > 0.0 and absf(r[1] - (Governor.SETTLE + 60.0 * Governor.STRUGGLE_MINUTES)) < 1.0
			and g.struggle().contains("GPU-bound") and r[2] < 0.0,
			"2.9 %% of refreshes missed GPU-bound (under the 5 %% drop): no drop, struggled at %.1f s, never calm (%s)" % [r[1], g.struggle()])
	r = _session([[900.0, every.call(100), false]])
	g = r[0]
	_expect(r[1] < 0.0 and r[2] > 0.0, "1 %% of refreshes missed: calm (%s)" % g.tally())
	var cpu_every := func(_t: float, i: int) -> Array: return [MISS if i % 34 == 0 else CALM, 14.0]
	r = _session([[300.0, cpu_every, false]])
	_expect(r[1] < 0.0, "2.9 %% missed, CPU-bound: no struggle (%s)" % (r[0] as Governor).tally())
	r = _session([[20.0, calm, false], [180.0, gpu_over, true], [300.0, calm, false]])
	g = r[0]
	_expect(r[1] < 0.0 and g.gpu_down_s == 0.0 and g.gpu == Governor.TOP,
			"a GPU overload in a wide view, then calm narrow: the wide drops don't count (%s)" % g.tally())
	r = _session([[100.0, calm, false], [100.0, calm, false]], 1, 20.0)
	g = r[0]
	_expect(absf(g.played_s - (200.0 - 2.0 * Governor.SETTLE)) < 1.0, "a 20 s gap: not counted, settled again (%.1f s)" % g.played_s)
	g = Governor.new()
	g.restart(0.0)
	_run(g, 0.0, 300.0, gpu_over)
	_expect(g.played_s == 0.0 and g.refreshes == 0, "not tracked: nothing counted (%s)" % g.tally())
	g = Governor.new()
	g.track = true
	g.held = true
	g.restart(0.0)
	_run(g, 0.0, 300.0, gpu_over)
	_expect(g.played_s == 0.0 and not g.struggled(), "held: nothing counted (%s)" % g.tally())
	g.held = false
	var t: float = _run(g, 400.0, 100.0, gpu_over)[0]
	_expect(g.struggled(), "then overloaded: struggled (%s)" % g.tally())
	g.restart(t)
	_expect(g.played_s == 0.0 and g.gpu_down_s == 0.0 and not g.struggled(), "restart (the quality changed): the tally afresh")
