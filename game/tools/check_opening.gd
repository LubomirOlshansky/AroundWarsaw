extends SceneTree
## The opening flyover (camera_shots.gd `open_view`, docs/design/opening-flyover.md), without the
## map. Samples the flight at 60 frames a second for a car at the guide's start (First10.START,
## facing START_HEADING, the follow camera at -30°, 80 m) and checks that:
## - it is short: OPEN_TIME between 5 and 10 s, the caption inside it;
## - it starts on the first key (the Palace, its size) and ends exactly on the follow view (the
##   same transform and size: no cut at the hand-off);
## - it is smooth: no frame moves the view's centre more than MAX_STEP m, turns it more than
##   MAX_TURN degrees or zooms it more than MAX_ZOOM; the first and last frames barely move
##   (eased at both ends);
## - the zoom only goes in (the size never grows), and the view's centre never dips under the
##   ground;
## - a start facing the other way still turns the short way round (no spin).
##   godot --headless --path game --script res://tools/check_opening.gd

const Shots := preload("res://scripts/camera_shots.gd")
const First10 := preload("res://scripts/first10.gd")
const FPS := 60.0
const MAX_STEP := 6.0
const MAX_TURN := 1.5
const MAX_ZOOM := 0.03

var _problems := 0


func _init() -> void:
	if Shots.OPEN_TIME < 5.0 or Shots.OPEN_TIME > 10.0:
		_fail("OPEN_TIME %.1f s is outside 5-10 s" % Shots.OPEN_TIME)
	if Shots.CAPTION_IN < 0.0 or Shots.CAPTION_OUT > Shots.OPEN_TIME - 1.0 or Shots.CAPTION_IN >= Shots.CAPTION_OUT:
		_fail("the caption (%.1f-%.1f s) must sit inside the flight and go a second before it ends"
				% [Shots.CAPTION_IN, Shots.CAPTION_OUT])
	_fly(First10.START_HEADING, "the guide's start")
	_fly(First10.START_HEADING + 180.0, "a start facing south")
	_fly(First10.START_HEADING - 360.0, "the same heading a turn round")
	if _problems == 0:
		print("opening: OK (%.1f s, %d frames, %.0f m → 80 m)" % [Shots.OPEN_TIME,
				int(Shots.OPEN_TIME * FPS), float(Shots.OPEN_KEYS[0]["size"])])
		quit(0)
	else:
		print("opening: %d problem(s)" % _problems)
		quit(1)


func _fly(heading: float, label: String) -> void:
	var ground := 2.0
	var car := Vector3(First10.START.x, ground, First10.START.y)
	var follow_size := 80.0
	var basis := Basis.from_euler(Vector3(deg_to_rad(-30.0), deg_to_rad(heading), 0.0))
	var follow_xf := Transform3D(basis, car + basis.z * Shots._distance(follow_size))
	var frames := int(ceil(Shots.OPEN_TIME * FPS))
	var first: Dictionary = Shots.open_view(0.0, ground, heading, follow_xf, follow_size)
	var key: Dictionary = Shots.OPEN_KEYS[0]
	var at: Vector2 = key["at"]
	var f0: Vector3 = first["focus"]
	if Vector2(f0.x, f0.z).distance_to(at) > 0.01 or absf(float(first["size"]) - float(key["size"])) > 0.01:
		_fail("%s: the first frame is not on the first key (%s, %.1f m)" % [label, f0, first["size"]])
	var last: Dictionary = Shots.open_view(1.0, ground, heading, follow_xf, follow_size)
	var lxf: Transform3D = last["xf"]
	if lxf.origin.distance_to(follow_xf.origin) > 0.01 or absf(float(last["size"]) - follow_size) > 0.01 \
			or not _same_basis(lxf.basis, follow_xf.basis):
		_fail("%s: the last frame is not the follow view (a cut at the hand-off)" % label)
	var prev := first
	var worst_step := 0.0
	var worst_turn := 0.0
	var worst_zoom := 0.0
	for i in range(1, frames + 1):
		var v: Dictionary = Shots.open_view(float(i) / frames, ground, heading, follow_xf, follow_size)
		var pf: Vector3 = prev["focus"]
		var vf: Vector3 = v["focus"]
		var step := pf.distance_to(vf)
		var pxf: Transform3D = prev["xf"]
		var vxf: Transform3D = v["xf"]
		var turn := rad_to_deg((-pxf.basis.z).angle_to(-vxf.basis.z))
		var zoom := absf(log(float(v["size"]) / float(prev["size"])))
		worst_step = maxf(worst_step, step)
		worst_turn = maxf(worst_turn, turn)
		worst_zoom = maxf(worst_zoom, zoom)
		if float(v["size"]) > float(prev["size"]) + 0.001:
			_fail("%s: frame %d zooms out (%.1f → %.1f m)" % [label, i, prev["size"], v["size"]])
		if vf.y < ground - 0.5:
			_fail("%s: frame %d's centre is under the ground (%.1f)" % [label, i, vf.y])
		if (i == 1 or i == frames) and step > 0.5:
			_fail("%s: frame %d moves %.2f m (not eased at the ends)" % [label, i, step])
		prev = v
	if worst_step > MAX_STEP:
		_fail("%s: a frame moves the view %.1f m (at most %.1f)" % [label, worst_step, MAX_STEP])
	if worst_turn > MAX_TURN:
		_fail("%s: a frame turns the view %.2f° (at most %.1f)" % [label, worst_turn, MAX_TURN])
	if worst_zoom > MAX_ZOOM:
		_fail("%s: a frame zooms %.1f%% (at most %.0f%%)" % [label, worst_zoom * 100.0, MAX_ZOOM * 100.0])
	print("opening: %s: at most %.2f m, %.2f°, %.1f%% a frame" % [label, worst_step, worst_turn, worst_zoom * 100.0])


func _same_basis(a: Basis, b: Basis) -> bool:
	return a.x.distance_to(b.x) < 0.001 and a.y.distance_to(b.y) < 0.001 and a.z.distance_to(b.z) < 0.001


func _fail(why: String) -> void:
	_problems += 1
	print("opening: " + why)
