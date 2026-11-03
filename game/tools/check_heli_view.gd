extends SceneTree
## The helicopter high up (GAMEPLAY_PLAN 3.1, 2026-11-03): F's playtest saw the helicopter at the
## screen's top edge, flat blue past the city and towers standing on nothing from ~240 m up. This
## checks the three rules that fixed it, from the scripts alone (no map, no window):
##
##  1. Framing: at every height from the ground to Heli.MAX_HEIGHT the helicopter sits in the
##     upper-middle of the view (between FRAME_TOP and FRAME_BOTTOM of the height, from the top):
##     the camera aims `main.gd heli_aim_share` of the height down from it, the view is
##     base * HELI_VIEW + `heli_widen`, and at the camera's 30° pitch a height h shows as
##     h · cos 30° on screen.
##  2. The view's widening never passes main.gd HELI_WIDEN_MAX, and the aim's share only falls
##     with height (no jump).
##  3. The height cap (heli.gd `ceiling_at`): OPEN_CEILING over low roofs, the tallest roof
##     near plus ROOF_CLEAR by a tower, never over MAX_HEIGHT.
##
## Prints `check_heli_view: OK` and exits 0, else the problems and 1. Under a second.
##   godot --headless --path game --script res://tools/check_heli_view.gd

const Main := preload("res://scripts/main.gd")
const Heli := preload("res://scripts/heli.gd")
const FollowCamera := preload("res://scripts/follow_camera.gd")
const PITCH := 30.0
const FRAME_TOP := 0.3
const FRAME_BOTTOM := 0.5


func _init() -> void:
	var problems: Array[String] = []
	var base: float = FollowCamera.DEFAULT_SIZE * Main.HELI_VIEW
	var last_share := 1.0
	var h := 0.0
	while h <= Heli.MAX_HEIGHT:
		var share: float = Main.heli_aim_share(h)
		var widen: float = Main.heli_widen(h)
		if share > last_share + 1e-6:
			problems.append("aim share rises at %.0f m (%.3f after %.3f)" % [h, share, last_share])
		last_share = share
		if widen > Main.HELI_WIDEN_MAX + 1e-3:
			problems.append("view widens %.0f m at %.0f m (cap %.0f)" % [widen, h, Main.HELI_WIDEN_MAX])
		var size := base + widen
		var from_top := 0.5 - share * h * cos(deg_to_rad(PITCH)) / size
		if from_top < FRAME_TOP or from_top > FRAME_BOTTOM:
			problems.append("at %.0f m the helicopter sits %.0f %% from the top" % [h, from_top * 100.0])
		h += 5.0

	var heli = Heli.new()
	var cases := [
		[30.0, Heli.OPEN_CEILING],        # low roofs: the open cap
		[225.0, 225.0 + Heli.ROOF_CLEAR],  # the Palace's spire
		[320.0, Heli.MAX_HEIGHT],          # past MAX_HEIGHT - ROOF_CLEAR: MAX_HEIGHT
	]
	for c: Array in cases:
		var roof: float = c[0]
		heli.tallest_near = func(_x: float, _z: float, _r: float) -> float: return 10.0 + roof
		var got: float = heli.ceiling_at(0.0, 0.0, 10.0)
		if absf(got - float(c[1])) > 1e-3:
			problems.append("ceiling by a %.0f m roof is %.0f m, want %.0f" % [roof, got, c[1]])
	heli.free()

	if problems.is_empty():
		print("check_heli_view: OK")
		quit(0)
	else:
		for p in problems:
			print("check_heli_view: ", p)
		print("check_heli_view: %d problems" % problems.size())
		quit(1)
