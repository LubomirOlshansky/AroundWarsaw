extends Node
## The vintage-tram loop (2026-10-31; docs/design/vision.md 8, egg E39 "Zabytkowy tramwaj"): one
## tram in an older Warsaw look runs on the trams' own tracks (trams.gd) on summer weekends.
##
## - **The set**: a rounded 1960s-style two-car set (a motor car with a pantograph and a trailer),
##   carmine red below and cream above, a red line over the windows, a four-piece windscreen, two
##   headlamps and a "T" on the destination plate; our own shape, no operator's name or logo.
##   It is one of trams.gd's eight trams recruited while out of sight (`set_vintage`): the meshes
##   of its own MeshInstance3Ds are swapped and its third car hidden, so it draws one car fewer
##   than a modern tram (-1 draw call in view, never more). It cruises at CRUISE (29 km/h, the
##   modern ones 40): the trams behind it queue, as trams do.
## - **When** (`window`): Saturdays and Sundays from DAY_FROM to DAY_TO by the game clock
##   (time_of_day.gd `local_clock`, the weekday the crowds read); with Live, June to September
##   only. In the window one run an hour (`run_on`): it starts at a minute seeded by the day and
##   the hour (0-RUN_START) and lasts RUN min. A run takes the out-of-sight tram nearest the
##   player; when the run is over the tram turns modern again once it is out of sight.
## - **The sound**: a low creak (sfx `tram_creak`) every CREAK s while it moves within earshot,
##   and its own two-tone hand bell (`old_tram_bell`, trams.gd `old_bell`) where the modern trams
##   ring; both through sfx.gd's positional voices (its cap of six).
## - **E39** (`follow_step`): the car (not the helicopter) within NEAR m of the set's body,
##   behind or beside it (not more than FRONT m past its nose), adds the metres the set moves;
##   farther than RESET m starts again. FOLLOW_M m found: E39 (+30 respect), and the egg's own
##   line over the tram. The then card T13 waits (the cards start in 2010: BACKLOG).
## Nothing runs per frame but a timer: one tick every TICK s.

const Trams := preload("res://scripts/trams.gd")
const Models := preload("res://scripts/models.gd")

const TICK := 0.5
## The window: Saturday and Sunday (6, 7), DAY_FROM-DAY_TO; with Live, these months.
const DAYS := [6, 7]
const DAY_FROM := 9.0
const DAY_TO := 19.0
const MONTHS := [6, 7, 8, 9]
## One run an hour: from a seeded minute in [0, RUN_START) for RUN minutes.
const RUN_START := 30
const RUN := 25.0
## The old set cruises at 8 m/s (29 km/h).
const CRUISE := 8.0
## E39: FOLLOW_M m of the set's travel with the car within NEAR m of it (behind or beside: at most
## FRONT m past its nose); farther than RESET m starts the count again.
const FOLLOW_M := 300.0
const NEAR := 40.0
const RESET := 80.0
const FRONT := 2.0
## A creak every CREAK.x-CREAK.y s while it moves (over 1.5 m/s) within earshot (sfx REACH).
const CREAK := Vector2(6.0, 11.0)
const EARSHOT := 85.0
const BUBBLE := Color("#efe3c2")

## The livery.
const RED := Color("#b3262b")
const CREAM := Color("#efe3c2")
const ROOF := Color("#a39c8e")
const DARK := Color("#2b2c2f")
const DOOR := Color("#5a2a26")
## The T on the destination plate, three by five.
const T_GLYPH := ["###", ".#.", ".#.", ".#.", ".#."]

var trams: Trams
var sfx: Node
var dialogue: Node
var egg_book: Node
## The game clock (time_of_day.gd local_clock) and the calendar (main.gd _crowd_calendar: live,
## month, date); the view's centre; the vehicle: [position, km/h, flying]; the eggs' state.
var clock: Callable
var calendar: Callable
var focus: Callable
var vehicle: Callable
var probe: Callable
## --tram-log: `old tram:` lines.
var log_on := false
## Microseconds spent in the ticks, for --bench.
var spent_usec := 0
## The set out now (null: none), the metres followed this run, runs started.
var tram: Trams.Tram
var followed := 0.0
var runs := 0
## E39 moments seen this session (a find or, found already, the count reached).
var moments := 0

var _t := 0.0
var _forced := false
var _last_head := Vector2.INF
var _creak_wait := 3.0
var _rng := RandomNumberGenerator.new()
var _meshes: Array = []
var _logged_m := 0.0


func setup() -> void:
	_rng.seed = 1965
	_meshes = vintage_meshes()


## --old-tram: the set now, on the track nearest `at` (the player), whatever the time; it stays.
func force(at: Vector2) -> void:
	_forced = true
	if trams == null or trams.trams.is_empty():
		return
	if tram == null:
		# The tram farthest from the player (the ones nearby keep running).
		var pick: Trams.Tram = trams.trams[0]
		var far := -1.0
		for t in trams.trams:
			var d := trams.body_point(t, 0.0).distance_to(at)
			if d > far:
				far = d
				pick = t
		_take(pick)
	trams.place_near(tram, at)
	_last_head = Vector2.INF
	if log_on:
		var h := trams.body_point(tram, 0.0)
		print("old tram: --old-tram: the set at %.0f, %.0f (tram %d)" % [h.x, h.y, trams.trams.find(tram)])


# --- the rules (static: check_old_tram.gd runs them) ------------------------------------------

## The set may run at `hour` on `weekday` (1 Monday .. 7 Sunday); with Live only in MONTHS.
static func window(live: bool, month: int, weekday: int, hour: float) -> bool:
	if not weekday in DAYS or hour < DAY_FROM or hour >= DAY_TO:
		return false
	return not live or month in MONTHS


## The minute (0..RUN_START) the run of hour `h` (0-23) starts on day `key` (Live: yyyymmdd; the
## fixed looks: the weekday).
static func run_start(key: int, h: int) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(key * 100 + h) + 1965
	return rng.randi_range(0, RUN_START - 1)


## A run is on at `hour` of day `key` (in the window: check `window` too).
static func run_on(key: int, hour: float) -> bool:
	var h := floori(hour)
	var m := (hour - h) * 60.0
	var start := run_start(key, h)
	return m >= start and m < start + RUN


## E39's count after one tick: `progress` m so far, the car `gap` m from the set's body and
## `ahead` m past its nose (negative: behind it), the set moved `moved` m since the last tick.
static func follow_step(progress: float, gap: float, ahead: float, moved: float, flying: bool) -> float:
	if gap > RESET:
		return 0.0
	if flying or gap > NEAR or ahead > FRONT:
		return progress
	return progress + maxf(moved, 0.0)


## The distance from `p` to the polyline head -> mid -> rear (the set's body on its rails).
static func body_gap(p: Vector2, pts: PackedVector2Array) -> float:
	var best := INF
	for k in pts.size() - 1:
		var a := pts[k]
		var ab := pts[k + 1] - a
		var l2 := ab.length_squared()
		var t := clampf((p - a).dot(ab) / l2, 0.0, 1.0) if l2 > 0.0001 else 0.0
		best = minf(best, p.distance_to(a + ab * t))
	return best


# --- the tick ---------------------------------------------------------------------------------

func _process(dt: float) -> void:
	if trams == null:
		return
	_t += dt
	if _t < TICK:
		return
	var t0 := Time.get_ticks_usec()
	tick(_t)
	_t = 0.0
	spent_usec += Time.get_ticks_usec() - t0


func tick(dt: float) -> void:
	var v: Array = vehicle.call() if vehicle.is_valid() else [Vector3.ZERO, 0.0, false]
	var car3: Vector3 = v[0]
	var car := Vector2(car3.x, car3.z)
	var want := _forced or scheduled()
	if want and tram == null:
		var free := trams.out_of_sight(car)
		if not free.is_empty():
			_take(free[0])
			if log_on:
				var h := trams.body_point(tram, 0.0)
				print("old tram: run %d starts out of sight at %.0f, %.0f (%.0f m from the car)" % [runs, h.x, h.y, h.distance_to(car)])
	elif not want and tram != null and not trams.in_sight(tram):
		if log_on:
			print("old tram: run over, the set out of sight turns modern (%.0f m followed)" % followed)
		_drop()
	if tram == null:
		return
	_follow(car, bool(v[2]), dt)
	_creak(dt)


## Whether a run is on now by the clock and the calendar.
func scheduled() -> bool:
	var c: Dictionary = clock.call() if clock.is_valid() else {"hour": 14.0, "weekday": 5}
	var cal: Dictionary = calendar.call() if calendar.is_valid() else {"live": false, "month": 7, "date": 0}
	var hour := float(c["hour"])
	var day := int(c["weekday"])
	var live := bool(cal.get("live", false))
	if not window(live, int(cal.get("month", 7)), day, hour):
		return false
	var key := int(cal.get("date", 0)) if live and int(cal.get("date", 0)) > 0 else day
	return run_on(key, hour)


func _take(t: Trams.Tram) -> void:
	tram = t
	trams.set_vintage(t, true, _meshes, CRUISE)
	followed = 0.0
	runs += 1
	_last_head = Vector2.INF


func _drop() -> void:
	trams.set_vintage(tram, false)
	tram = null
	followed = 0.0


func _follow(car: Vector2, flying: bool, dt: float) -> void:
	var head := trams.body_point(tram, 0.0)
	var moved := 0.0
	if _last_head != Vector2.INF:
		# A jump (the set came back in elsewhere, or --old-tram put it down) is no travel.
		moved = head.distance_to(_last_head)
		if moved > CRUISE * dt * 2.0 + 1.0:
			moved = 0.0
	_last_head = head
	var length := Trams.length_of(tram)
	var pts := PackedVector2Array([head, trams.body_point(tram, length * 0.5), trams.body_point(tram, length)])
	var gap := body_gap(car, pts)
	var ahead := (car - head).dot(tram.dir)
	var was := followed
	followed = follow_step(followed, gap, ahead, moved, flying)
	if log_on:
		if followed == 0.0 and was > 0.0:
			print("old tram: dropped back (%.0f m from the set): the count starts again (was %.0f m)" % [gap, was])
		elif floorf(followed / 50.0) > floorf(_logged_m / 50.0):
			print("old tram: followed %.0f m (the car %.0f m from it)" % [followed, gap])
	_logged_m = followed
	if followed >= FOLLOW_M and was < FOLLOW_M:
		_moment()


## E39: followed FOLLOW_M m. The egg's own line over the set on the find.
func _moment() -> void:
	moments += 1
	var found := false
	if egg_book != null and probe.is_valid():
		found = egg_book.fire("e39", probe.call())
	if found and dialogue != null and dialogue.get("bubbles") != null and egg_book.by_id.has("e39"):
		var line: Array = egg_book.line_of(egg_book.eggs[egg_book.by_id["e39"]])
		if line.size() >= 2:
			var t := tram
			var anchor := func() -> Vector3:
				return t.pos + Vector3.UP * 0.5 if t != null else Vector3.ZERO
			dialogue.bubbles.say(anchor, "", str(line[0]), str(line[1]), 5.0, BUBBLE, 4.2)
	if log_on:
		print("old tram: followed %.0f m: E39 %s" % [followed, "found" if found else "(found already)"])


func _creak(dt: float) -> void:
	_creak_wait -= dt
	if _creak_wait > 0.0 or sfx == null:
		return
	_creak_wait = _rng.randf_range(CREAK.x, CREAK.y)
	if tram.v < 1.5:
		return
	var f3: Vector3 = focus.call() if focus.is_valid() else Vector3.ZERO
	var mid := trams.body_point(tram, Trams.length_of(tram) * 0.5)
	if mid.distance_to(Vector2(f3.x, f3.z)) > EARSHOT:
		return
	sfx.play_at("tram_creak", Vector3(mid.x, tram.pos.y + 0.6, mid.y), _rng.randf_range(-3.0, 0.0))


## The `old tram:` summary line (--tram-log).
func summary() -> String:
	if tram == null:
		return "old tram: none out (%d runs)" % runs
	var h := trams.body_point(tram, 0.0)
	return "old tram: at %.0f, %.0f, %.1f m/s, %.0f m followed (%d runs)" % [h.x, h.y, tram.v, followed, runs]


# --- the look ---------------------------------------------------------------------------------

## The two cars: [motor car (a cab at -Z, the pantograph), trailer (the tail lamps at +Z)], each
## one surface on the one actor material (made once).
static var _made: Array = []


static func vintage_meshes() -> Array:
	if _made.is_empty():
		_made = [_car(true), _car(false)]
	return _made


## One car, 10.5 m (trams.gd CAR) by 2.4 m, its front at -Z. `motor`: the driver's end in front
## (a four-piece windscreen, two headlamps, the T plate) and the pantograph; else the trailer, whose
## back (+Z) shows the tail lamps. Doors on the right (+X) only: a single-ended set.
static func _car(motor: bool) -> ArrayMesh:
	var s := Models.Shape.new()
	var red := Models.fin(RED)
	var cream := Models.fin(CREAM)
	var roof := Models.fin(ROOF)
	var dark := Models.fin(DARK)
	var glass := Models.fin(Models.GLASS, Models.LIT_WINDOW)
	var W := 1.2
	var hl := 5.25
	var rf := 1.3 if motor else 0.8
	var rb := 0.8 if motor else 1.2
	var ol := _outline(W, hl, rf, rb, 8)
	# The body in bands: a tucked-in skirt, the red lower body, the cream upper with a red line
	# over the windows, and a roof rounded at the edges and ends.
	_band(s, _inset(ol, 0.06), ol, 0.3, 0.45, red)
	_band(s, ol, ol, 0.45, 1.25, red)
	_band(s, ol, ol, 1.25, 2.3, cream)
	_band(s, ol, ol, 2.3, 2.44, red)
	_band(s, ol, ol, 2.44, 2.62, cream)
	var r1 := _inset(ol, 0.14)
	var r2 := _inset(ol, 0.42)
	_band(s, ol, r1, 2.62, 2.8, roof)
	_band(s, r1, r2, 2.8, 2.9, roof)
	_cap(s, r2, 2.9, roof)
	# The windows: down both sides between the ends' curves, the right side (+X) round its doors.
	var z0 := -hl + rf + 0.1
	var z1 := hl - rb - 0.1
	var doors := [-hl + rf + 0.75, 0.3, hl - rb - 0.75] if motor else [-hl + rf + 0.75, hl - rb - 0.75]
	for sgn: float in [-1.0, 1.0]:
		var x := sgn * (W + 0.012)
		var spans: Array = [Vector2(z0, z1)]
		if sgn > 0.0:
			spans = []
			var from := z0
			for dz: float in doors:
				if dz - 0.62 - from > 0.5:
					spans.append(Vector2(from, dz - 0.62))
				from = dz + 0.62
				s.side_rect(x, sgn, 0.42, 2.26, dz - 0.55, dz + 0.55, Models.fin(DOOR))
				for half: float in [-1.0, 1.0]:
					var zc := dz + half * 0.27
					s.side_rect(x + sgn * 0.006, sgn, 1.32, 2.18, zc - 0.21, zc + 0.21, glass)
			if z1 - from > 0.5:
				spans.append(Vector2(from, z1))
		for sp: Vector2 in spans:
			var n := maxi(1, roundi((sp.y - sp.x) / 1.05))
			var step := (sp.y - sp.x) / n
			for k in n:
				s.side_rect(x, sgn, 1.34, 2.2, sp.x + k * step + 0.07, sp.x + (k + 1) * step - 0.07, glass)
	# The ends: the windows round each curve; the motor car's front the windscreen, the headlamp,
	# the bumper and the T plate; the trailer's back two tail lamps.
	var n_arc := 8
	for k in n_arc:
		var front_a := ol[1 + k]
		var front_b := ol[2 + k]
		if k >= 2 and k <= 5:
			_seg_pane(s, front_a, front_b, 1.3 if motor else 1.34, 2.24 if motor else 2.2, glass, 0.08)
		var back_a := ol[n_arc + 2 + k]
		var back_b := ol[(n_arc + 3 + k) % ol.size()]
		if k >= 2 and k <= 5:
			_seg_pane(s, back_a, back_b, 1.34, 2.2, glass, 0.08)
		if not motor and (k == 1 or k == 6):
			_seg_pane(s, back_a, back_b, 0.72, 0.9, Models.fin(Models.TAIL, Models.TAIL_LAMP), 0.2)
	if motor:
		var mid_a := ol[1 + n_arc / 2 - 1]
		var mid_b := ol[1 + n_arc / 2]
		var mid_c := ol[2 + n_arc / 2]
		# Two headlamps low on the nose, either side of its middle.
		_seg_pane(s, mid_a, mid_b, 0.7, 0.92, Models.fin(Models.HEADLIGHT, Models.HEAD_LAMP), 0.3)
		_seg_pane(s, mid_b, mid_c, 0.7, 0.92, Models.fin(Models.HEADLIGHT, Models.HEAD_LAMP), 0.3)
		s.box(Vector3(0.0, 0.4, -hl - 0.02), Vector3(1.5, 0.12, 0.14), dark)
		# The destination plate, lit, with a dark T (the tourist line's letter).
		var plate_l := ol[1 + n_arc / 2 - 1]
		var plate_r := ol[2 + n_arc / 2]
		var c := Vector3((plate_l.x + plate_r.x) * 0.5, 2.37, -hl - 0.03)
		var pw := absf(plate_r.x - plate_l.x) * 0.9
		var out := Vector3.FORWARD
		s.quad(c + Vector3(-pw * 0.5, -0.11, 0), c + Vector3(pw * 0.5, -0.11, 0), c + Vector3(pw * 0.5, 0.11, 0),
				c + Vector3(-pw * 0.5, 0.11, 0), Models.fin(Color("#f0e6c8"), Models.LIT_SIGN), out)
		var px := 0.036
		var o := c + Vector3(px * 1.5, px * 2.5, -0.006)
		for r in T_GLYPH.size():
			var row: String = T_GLYPH[r]
			for col in row.length():
				if row[col] != "#":
					continue
				# Seen from the front (-Z), +X is on the viewer's left.
				var a := o + Vector3(-px * col, -px * r, 0)
				s.quad(a, a + Vector3(-px, 0, 0), a + Vector3(-px, -px, 0), a + Vector3(0, -px, 0), dark, out)
		# The pantograph: a diamond each side on a base frame, the pan across its top.
		var zp := -1.2
		s.box(Vector3(0.0, 2.96, zp), Vector3(1.2, 0.08, 1.1), dark)
		for xs: float in [-0.3, 0.3]:
			var b := Vector3(xs, 3.0, zp)
			var f := Vector3(xs, 3.38, zp - 0.45)
			var t := Vector3(xs, 3.76, zp)
			var r := Vector3(xs, 3.38, zp + 0.45)
			for pair: Array in [[b, f], [f, t], [t, r], [r, b]]:
				_strut(s, pair[0], pair[1], 0.05, dark)
		s.box(Vector3(0.0, 3.79, zp), Vector3(1.3, 0.05, 0.1), dark)
		for zk: float in [zp - 0.45, zp + 0.45]:
			s.box(Vector3(0.0, 3.38, zk), Vector3(0.62, 0.04, 0.04), dark)
	else:
		# A roof vent on the trailer.
		s.box(Vector3(0.0, 2.95, 0.0), Vector3(0.7, 0.1, 0.9), roof)
	# The roof vents, the coupler and the bogies.
	for z: float in [-2.6, 2.6]:
		s.box(Vector3(0.0, 2.95, z), Vector3(0.5, 0.1, 0.6), roof)
		s.box(Vector3(0, 0.22, z * 1.15), Vector3(2.0, 0.36, 1.8), Models.fin(Color("#1c1c1e")))
	s.box(Vector3(0.0, 0.5, hl + 0.15 if motor else -hl - 0.15), Vector3(0.3, 0.18, 0.4), dark)
	return s.mesh()


## The car's plan (x, z) going round it, its front at -Z: the right side, the front's curve (n
## pieces, a superellipse `rf` m deep), the left side and the back's curve (`rb` m).
static func _outline(w: float, hl: float, rf: float, rb: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	out.append(Vector2(w, hl - rb))
	for k in n + 1:
		var a := PI * k / n
		out.append(Vector2(w * _se(cos(a)), -(hl - rf) - rf * _se(sin(a))))
	for k in n:
		var a := PI + PI * k / n
		out.append(Vector2(w * _se(cos(a)), (hl - rb) - rb * _se(sin(a))))
	return out


## A superellipse's (exponent 3) blunter curve: |c|^(2/3) with c's sign.
static func _se(c: float) -> float:
	return signf(c) * pow(absf(c), 2.0 / 3.0)


## `ol` moved in by `d` m at every point (along the mean of its two sides' normals).
static func _inset(ol: PackedVector2Array, d: float) -> PackedVector2Array:
	var n := ol.size()
	var out := PackedVector2Array()
	for i in n:
		var a := ol[(i + n - 1) % n]
		var b := ol[i]
		var c := ol[(i + 1) % n]
		var n1 := _normal(a, b)
		var n2 := _normal(b, c)
		var m := (n1 + n2).normalized()
		out.append(b - m * d / maxf(m.dot(n1), 0.3))
	return out


## The outward normal of side a -> b of a plan going round its centre (at the origin).
static func _normal(a: Vector2, b: Vector2) -> Vector2:
	var e := (b - a).normalized()
	var n := Vector2(e.y, -e.x)
	return n if n.dot((a + b) * 0.5) >= 0.0 else -n


## A band of wall from plan `lo` at y0 up to plan `hi` at y1 (the same points, moved).
static func _band(s: Models.Shape, lo: PackedVector2Array, hi: PackedVector2Array, y0: float, y1: float, f: Array) -> void:
	var n := lo.size()
	for i in n:
		var j := (i + 1) % n
		var m := (lo[i] + lo[j]) * 0.5
		s.quad(Vector3(lo[i].x, y0, lo[i].y), Vector3(lo[j].x, y0, lo[j].y), Vector3(hi[j].x, y1, hi[j].y),
				Vector3(hi[i].x, y1, hi[i].y), f, Vector3(m.x, (y1 - y0) * 0.1, m.y))


## The flat top over plan `ol` at y.
static func _cap(s: Models.Shape, ol: PackedVector2Array, y: float, f: Array) -> void:
	var c := Vector3.ZERO
	for p in ol:
		c += Vector3(p.x, y, p.y)
	c /= ol.size()
	for i in ol.size():
		var j := (i + 1) % ol.size()
		s.tri(c, Vector3(ol[i].x, y, ol[i].y), Vector3(ol[j].x, y, ol[j].y), f, Vector3.UP)


## A pane on the wall piece a -> b (plan points) from y0 to y1, `margin` of its width in from
## each end, just off the wall.
static func _seg_pane(s: Models.Shape, a: Vector2, b: Vector2, y0: float, y1: float, f: Array, margin: float) -> void:
	var n := _normal(a, b) * 0.014
	var p := a.lerp(b, margin) + n
	var q := b.lerp(a, margin) + n
	s.quad(Vector3(p.x, y0, p.y), Vector3(q.x, y0, q.y), Vector3(q.x, y1, q.y), Vector3(p.x, y1, p.y), f, Vector3(n.x, 0, n.y))


## A thin bar from a to b, `t` m square.
static func _strut(s: Models.Shape, a: Vector3, b: Vector3, t: float, f: Array) -> void:
	var d := b - a
	s.xform = Transform3D(Basis.looking_at(d.normalized(), Vector3.RIGHT), (a + b) * 0.5)
	s.box(Vector3.ZERO, Vector3(t, t, d.length()), f)
	s.xform = Transform3D.IDENTITY
