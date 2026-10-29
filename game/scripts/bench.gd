extends RefCounted
## Loop 2b: what a frame costs, for the `--bench` and `--probe` flags and the BENCH button
## on the performance overlay (the phone's own numbers). main.gd calls `sample()` once a
## frame while measuring; `report()` sums it up and `text()` writes it as plain lines (the
## console, the result card and the clipboard).
##
## Measured: wall-clock frame times (average, 1 % low = the slowest 1 % of frames, worst,
## late frames: loop G1, more than 1 ms over the frame interval; the refreshes missed, what the
## governor reads; fps in 10 s pieces for throttling); the main thread's
## frame split from the engine's own signals: physics (physics_frame -> process_frame:
## the scripts' _physics_process and the physics step), process (process_frame ->
## frame_pre_draw: every _process, the 2D redraws) and draw (frame_pre_draw ->
## frame_post_draw: building and submitting the frame; it grows when the GPU is behind,
## the only GPU hint on Metal); the 3D view's render CPU and GPU time (GPU only on Vulkan:
## Metal has no timestamps in Godot 4.7); draw calls / objects / triangles of the pixel
## image's main pass and its shadow pass and the 2D pass, the scripts' time by system,
## memory and the pipeline compilations during the run.

const Governor := preload("res://scripts/governor.gd")
const MB := 1048576.0

## The pixel image's viewport (main and shadow pass) and the screen's (the 2D pass).
var view_rid: RID
var screen_rid: RID
## label -> [object, property, reset]: per-frame script costs in µs (reset: an accumulator
## the bench zeroes after reading; else the value of the last frame).
var systems := {}
## Extra per-frame counts to average: label -> Callable returning a number.
var counts := {}
## Free text for the card's header lines (settings, device).
var header := PackedStringArray()
## Loop G1: lines for the card after the frame-time lines (the governor's state).
var notes := PackedStringArray()
## Loop G1: the last frame's wall-clock time and the main thread's CPU work in it (physics +
## process), in ms, for the governor (main.gd reads them once a frame).
var last_ms := 0.0
var last_cpu := 0.0
## Loop G1: a frame is late when it is more than this past the frame interval (loop 2b counted
## 0.5 ms past it). The card also counts the refreshes the run missed against the display's
## clock (governor.gd miss_step), what the governor reads: on the iPhone 11 1.6–16 % of frames
## came 1–8 ms late and the next as much early, with every refresh drawn.
const LATE_MARGIN := 1.0
## Loop 2b's measure, still printed beside the new one so old cards compare.
const OLD_MARGIN := 0.5

var frames := PackedFloat32Array()
var _last_usec := 0
var _sum := {}
var _n := 0
var _t0 := 0
var _pipelines0 := 0
## The frame's phases on the main thread (µs ticks) and their sums while measuring.
var _phys0 := 0
var _proc0 := 0
var _pre := 0
var _last_post := 0
var _phase := {"physics": 0.0, "process": 0.0, "draw": 0.0}
var _measuring := false
## The same split summed for the performance overlay since it last read it (`take_live`).
var _live := {"frames": 0, "ms": 0.0, "worst": 0.0, "physics": 0.0, "process": 0.0, "draw": 0.0}


var _tree: SceneTree


## Listen to the engine's frame signals (once); `unhook()` before the game quits (the
## RenderingServer outlives this object).
func hook(tree: SceneTree) -> void:
	_tree = tree
	tree.physics_frame.connect(_on_physics)
	tree.process_frame.connect(_on_process)
	RenderingServer.frame_pre_draw.connect(_on_pre_draw)
	RenderingServer.frame_post_draw.connect(_on_post_draw)


func unhook() -> void:
	if _tree == null:
		return
	_tree.physics_frame.disconnect(_on_physics)
	_tree.process_frame.disconnect(_on_process)
	RenderingServer.frame_pre_draw.disconnect(_on_pre_draw)
	RenderingServer.frame_post_draw.disconnect(_on_post_draw)
	_tree = null


func _on_physics() -> void:
	if _phys0 <= _last_post:
		_phys0 = Time.get_ticks_usec()


func _on_process() -> void:
	_proc0 = Time.get_ticks_usec()


func _on_pre_draw() -> void:
	_pre = Time.get_ticks_usec()


func _on_post_draw() -> void:
	var post := Time.get_ticks_usec()
	if _proc0 > _last_post:
		var phys := (_proc0 - _phys0) / 1000.0 if _phys0 > _last_post else 0.0
		var proc := (_pre - _proc0) / 1000.0
		var draw := (post - _pre) / 1000.0
		if _measuring:
			_phase["physics"] += phys
			_phase["process"] += proc
			_phase["draw"] += draw
		var frame := (post - _last_post) / 1000.0
		last_ms = frame
		last_cpu = phys + proc
		_live["frames"] += 1
		_live["ms"] += frame
		_live["worst"] = maxf(_live["worst"], frame)
		_live["physics"] += phys
		_live["process"] += proc
		_live["draw"] += draw
	_last_post = post


## The overlay's numbers since it last asked: frames, average and worst frame (ms), and the
## main thread's physics / process / draw (ms a frame).
func take_live() -> Dictionary:
	var n := maxf(_live["frames"], 1)
	var out := {"frames": _live["frames"], "ms": _live["ms"] / n, "worst": _live["worst"],
			"physics": _live["physics"] / n, "process": _live["process"] / n, "draw": _live["draw"] / n}
	_live = {"frames": 0, "ms": 0.0, "worst": 0.0, "physics": 0.0, "process": 0.0, "draw": 0.0}
	return out


## The draw calls, objects and triangles of the last frame: the pixel image's main and shadow
## passes, the 2D pass, and the totals the engine counts.
func passes() -> Dictionary:
	var out := {}
	for pass_name in ["main", "shadow"]:
		var type := RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE if pass_name == "main" \
				else RenderingServer.VIEWPORT_RENDER_INFO_TYPE_SHADOW
		out[pass_name + "_draws"] = RenderingServer.viewport_get_render_info(view_rid, type,
				RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
		out[pass_name + "_tris"] = RenderingServer.viewport_get_render_info(view_rid, type,
				RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME)
	out["canvas_draws"] = RenderingServer.viewport_get_render_info(screen_rid,
			RenderingServer.VIEWPORT_RENDER_INFO_TYPE_CANVAS, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME)
	out["all_draws"] = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	out["all_objects"] = int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	out["all_tris"] = int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	return out


func start() -> void:
	frames = PackedFloat32Array()
	_sum = {}
	_n = 0
	_last_usec = Time.get_ticks_usec()
	_t0 = _last_usec
	_pipelines0 = _pipelines()
	_phase = {"physics": 0.0, "process": 0.0, "draw": 0.0}
	_measuring = true
	for k in systems:
		var s: Array = systems[k]
		if s[2] and is_instance_valid(s[0]):
			s[0].set(s[1], 0)


## Call once a frame (at the start of main.gd's _process) while measuring.
func sample() -> void:
	var now := Time.get_ticks_usec()
	frames.append((now - _last_usec) / 1000.0)
	_last_usec = now
	_n += 1
	_add("gpu", RenderingServer.viewport_get_measured_render_time_gpu(view_rid))
	_add("render_cpu", RenderingServer.viewport_get_measured_render_time_cpu(view_rid)
			+ RenderingServer.get_frame_setup_time_cpu())
	for pass_name in ["main", "shadow"]:
		var type := RenderingServer.VIEWPORT_RENDER_INFO_TYPE_VISIBLE if pass_name == "main" \
				else RenderingServer.VIEWPORT_RENDER_INFO_TYPE_SHADOW
		_add(pass_name + "_draws", RenderingServer.viewport_get_render_info(view_rid, type,
				RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME))
		_add(pass_name + "_objects", RenderingServer.viewport_get_render_info(view_rid, type,
				RenderingServer.VIEWPORT_RENDER_INFO_OBJECTS_IN_FRAME))
		_add(pass_name + "_tris", RenderingServer.viewport_get_render_info(view_rid, type,
				RenderingServer.VIEWPORT_RENDER_INFO_PRIMITIVES_IN_FRAME))
	_add("canvas_draws", RenderingServer.viewport_get_render_info(screen_rid,
			RenderingServer.VIEWPORT_RENDER_INFO_TYPE_CANVAS, RenderingServer.VIEWPORT_RENDER_INFO_DRAW_CALLS_IN_FRAME))
	# The totals the performance overlay shows (every viewport and pass, the 2D one too).
	_add("all_draws", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
	_add("all_objects", Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME))
	_add("all_tris", Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
	for k in systems:
		var s: Array = systems[k]
		if not is_instance_valid(s[0]):
			continue
		_add("us:" + k, float(s[0].get(s[1])))
		if s[2]:
			s[0].set(s[1], 0)
	for k in counts:
		_add("n:" + k, float((counts[k] as Callable).call()))


func _add(key: String, v: float) -> void:
	_sum[key] = _sum.get(key, 0.0) + v


func _avg(key: String) -> float:
	return _sum.get(key, 0.0) / maxf(_n, 1)


static func _pipelines() -> int:
	var n := 0
	for m in [Performance.PIPELINE_COMPILATIONS_CANVAS, Performance.PIPELINE_COMPILATIONS_MESH,
			Performance.PIPELINE_COMPILATIONS_SURFACE, Performance.PIPELINE_COMPILATIONS_DRAW,
			Performance.PIPELINE_COMPILATIONS_SPECIALIZATION]:
		n += int(Performance.get_monitor(m))
	return n


## The run summed up (times in ms, memory in MB).
func report(budget_ms := 1000.0 / 60.0) -> Dictionary:
	var r := {}
	var n := frames.size()
	var total := 0.0
	for f in frames:
		total += f
	var sorted := frames.duplicate()
	sorted.sort()
	var worst_n := maxi(1, n / 100)
	var slow := 0.0
	for i in worst_n:
		slow += sorted[n - 1 - i] if n > 0 else 0.0
	var over := 0
	var old_over := 0
	var missed := 0
	var debt := 0.0
	for f in frames:
		if f > budget_ms + LATE_MARGIN:
			over += 1
		if f > budget_ms + OLD_MARGIN:
			old_over += 1
		var step := Governor.miss_step(debt, f, budget_ms)
		debt = step.x
		missed += int(step.y)
	_measuring = false
	r["frames"] = n
	for k in _phase:
		r[k] = _phase[k] / maxf(n, 1)
	r["seconds"] = total / 1000.0
	r["ms"] = total / maxf(n, 1)
	r["fps"] = 1000.0 * n / maxf(total, 0.001)
	r["low1"] = 1000.0 / maxf(slow / worst_n, 0.001)
	r["worst"] = sorted[n - 1] if n > 0 else 0.0
	r["budget"] = budget_ms
	r["over"] = 100.0 * over / maxf(n, 1)
	r["old_over"] = 100.0 * old_over / maxf(n, 1)
	r["missed"] = missed
	r["missed_share"] = 100.0 * missed / maxf(n + missed, 1)
	# fps in 10 s pieces: a phone that warms up slows down over the run.
	var pieces := PackedFloat32Array()
	var acc := 0.0
	var count := 0
	for f in frames:
		acc += f
		count += 1
		if acc >= 10000.0:
			pieces.append(1000.0 * count / acc)
			acc = 0.0
			count = 0
	if count > 30:
		pieces.append(1000.0 * count / acc)
	r["pieces"] = pieces
	for key in _sum:
		r[key] = _avg(key)
	r["pipelines"] = _pipelines() - _pipelines0
	r["mem_static"] = Performance.get_monitor(Performance.MEMORY_STATIC) / MB
	r["mem_video"] = Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED) / MB
	r["mem_texture"] = Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED) / MB
	r["mem_buffer"] = Performance.get_monitor(Performance.RENDER_BUFFER_MEM_USED) / MB
	var scripts := 0.0
	for k in systems:
		scripts += _avg("us:" + k) / 1000.0
	r["scripts"] = scripts
	return r


## Loop G1, for the log: the late frames by how late (over the interval + LATE_MARGIN, a second
## interval, two more) and the slowest ones with when they came (s into the run), so a stutter
## can be told from a few hitches.
func late_detail(budget_ms: float) -> String:
	var edges := [budget_ms + LATE_MARGIN, budget_ms * 1.5, budget_ms * 2.0 + LATE_MARGIN, budget_ms * 3.0 + LATE_MARGIN]
	var counts := [0, 0, 0, 0]
	var slow: Array = []
	var t := 0.0
	for f in frames:
		t += f
		for k in range(edges.size() - 1, -1, -1):
			if f > edges[k]:
				counts[k] += 1
				break
		if f > budget_ms * 1.5:
			slow.append([f, t / 1000.0])
	slow.sort_custom(func(a: Array, b: Array) -> bool: return a[0] > b[0])
	var worst := PackedStringArray()
	for s in slow.slice(0, 12):
		worst.append("%.0f ms at %.1f s" % [s[0], s[1]])
	return "late frames of %d: %.1f-%.1f ms %d · %.1f-%.1f ms %d · %.1f-%.1f ms %d · over %.1f ms %d · slowest: %s" % [
			frames.size(), edges[0], edges[1], counts[0], edges[1], edges[2], counts[1], edges[2], edges[3], counts[2],
			edges[3], counts[3], ", ".join(worst) if not worst.is_empty() else "none"]


## Plain lines: the console, the BENCH card and the clipboard.
func text(r: Dictionary) -> String:
	var out := PackedStringArray(header)
	out.append("fps %.1f avg · 1%% low %.1f · worst frame %.1f ms · late %.1f%% (over %.1f ms) · missed refreshes %d (%.1f%%) · %d frames in %.0f s" % [
			r["fps"], r["low1"], r["worst"], r["over"], r["budget"] + LATE_MARGIN, r["missed"], r["missed_share"],
			r["frames"], r["seconds"]])
	var pieces := PackedStringArray()
	for p in r["pieces"]:
		pieces.append("%.0f" % p)
	# Loop G1: the notes (the governor) share the fps-per-10-s line, so the card fits the SE.
	var tail := " · ".join(notes)
	if pieces.size() > 1:
		out.append("fps per 10 s: " + " ".join(pieces) + (" · " + tail if tail != "" else ""))
	elif tail != "":
		out.append(tail)
	var gpu := "%.2f ms" % r["gpu"] if r["gpu"] > 0.0 else "n/a (Metal)"
	out.append("frame %.2f ms · main thread: process %.2f, physics %.2f, draw %.2f · 3D view: render CPU %.2f, GPU %s" % [
			r["ms"], r["process"], r["physics"], r["draw"], r["render_cpu"], gpu])
	out.append("draw calls %.0f · objects %.0f · triangles %.2f M (all passes, as the overlay counts them)" % [
			r["all_draws"], r["all_objects"], r["all_tris"] / 1e6])
	out.append("main pass: %.0f draws, %.0f objects, %.2f M tris · shadow pass: %.0f draws, %.0f objects, %.2f M tris · 2D: %.0f draws" % [
			r["main_draws"], r["main_objects"], r["main_tris"] / 1e6, r["shadow_draws"], r["shadow_objects"],
			r["shadow_tris"] / 1e6, r["canvas_draws"]])
	var parts := PackedStringArray()
	for k in systems:
		parts.append("%s %.2f" % [k, _avg("us:" + k) / 1000.0])
	# Wrapped at ~100 characters, so the card stays readable on a phone.
	var line := "scripts %.2f ms:" % r["scripts"]
	for part in parts:
		if line.length() + part.length() > 100:
			out.append(line)
			line = "  "
		line += (" " if line.ends_with(":") or line == "  " else " · ") + part
	out.append(line)
	if not counts.is_empty():
		var c := PackedStringArray()
		for k in counts:
			c.append("%s %.0f" % [k, _avg("n:" + k)])
		out.append(" · ".join(c))
	out.append("memory: static %.0f MB · video %.0f MB (textures %.0f, buffers %.0f) · %d pipeline compilations" % [
			r["mem_static"], r["mem_video"], r["mem_texture"], r["mem_buffer"], r["pipelines"]])
	return "\n".join(out)
