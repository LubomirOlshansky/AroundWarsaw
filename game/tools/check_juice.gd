extends SceneTree
## v1.0 juice (2026-11-01): the crash sparks and dust (crash_fx.gd) and the phone's buzzes
## (haptics.gd), without the map.
##   J1 every buzz in scripts/ goes through access.gd / haptics.gd (no other Input.vibrate_handheld);
##   J2 a buzz is raised to the floor a hand feels and capped; a weaker one inside the gap or
##      while one plays is dropped, a stronger one goes; Settings' switch off sends nothing;
##      a scrape (under 4 m/s) doesn't buzz, a hard crash buzzes long and full;
##   J3 a crash throws sparks out of the wall (along the normal) and dust, shows both pools,
##      and everything is gone and hidden (no draw call, no script) within 2 s;
##   J4 a slow knock throws nothing; a long scrape reuses the ring (no growth);
##   J5 the sparks bounce on the road, never under it.
##   godot --headless --path game --script res://tools/check_juice.gd

const Haptics := preload("res://scripts/haptics.gd")
const Access := preload("res://scripts/access.gd")
const CrashFx := preload("res://scripts/crash_fx.gd")


func _initialize() -> void:
	var fails: Array[String] = []

	# J1: one path for buzzes.
	var dir := DirAccess.open("res://scripts")
	for f in dir.get_files():
		if f.ends_with(".gd") and not f in ["haptics.gd", "access.gd"]:
			var text := FileAccess.get_file_as_string("res://scripts/" + f)
			for line in text.split("\n"):
				if line.contains("Input.vibrate_handheld(") and not line.strip_edges().begins_with("#"):
					fails.append("J1 %s calls Input.vibrate_handheld directly" % f)

	# J2: the floor, the cap, the gap, the switch.
	Access.vibration = true
	var n0 := Haptics.count
	Haptics.buzz(25, 0.3)
	if Haptics.count != n0 + 1 or Haptics.last_ms != Haptics.FLOOR_MS or not is_equal_approx(Haptics.last_amp, Haptics.FLOOR_AMP):
		fails.append("J2 a 25 ms / 0.3 buzz went out as %d ms / %.2f (floor %d / %.2f)" % [Haptics.last_ms, Haptics.last_amp, Haptics.FLOOR_MS, Haptics.FLOOR_AMP])
	Haptics.buzz(40, 0.4)
	if Haptics.count != n0 + 1:
		fails.append("J2 a weaker buzz right after one was not dropped")
	Haptics.buzz(5000, 1.0)
	if Haptics.count != n0 + 2 or Haptics.last_ms != Haptics.CEIL_MS:
		fails.append("J2 a stronger buzz was dropped or not capped (%d ms)" % Haptics.last_ms)
	Access.vibration = false
	Haptics.buzz(200, 1.0)
	Haptics.knock(20.0)
	if Haptics.count != n0 + 2:
		fails.append("J2 buzzes went out with Vibration off")
	Access.vibration = true
	var n1 := Haptics.count
	Haptics.knock(3.0)
	if Haptics.count != n1:
		fails.append("J2 a 3 m/s scrape buzzed")
	Haptics._last_end_usec = 0
	Haptics._last_usec = -Haptics.GAP_USEC
	Haptics.last_amp = 0.0
	Haptics.knock(18.0)
	if Haptics.count != n1 + 1 or Haptics.last_ms < 150 or Haptics.last_amp < 0.99:
		fails.append("J2 a hard crash buzzed %d ms / %.2f" % [Haptics.last_ms, Haptics.last_amp])
	print("haptics: floor %d ms / %.2f, cap %d ms, a hard crash %d ms / %.2f" % [
			Haptics.FLOOR_MS, Haptics.FLOOR_AMP, Haptics.CEIL_MS, Haptics.last_ms, Haptics.last_amp])

	# J3: a crash into a wall facing +X, at 14 m/s, the road at y = 0.
	var fx := CrashFx.new()
	root.add_child.call_deferred(fx)
	await process_frame
	var at := Vector3(10.0, 0.6, -5.0)
	var normal := Vector3(1.0, 0.0, 0.0)
	fx.crash(at, normal, Vector3(-8.0, 0.0, -11.0), 14.0, 0.0, false)
	var sparks := 0
	for k in CrashFx.SPARKS:
		if fx._sp_age[k] < fx._sp_life[k]:
			sparks += 1
	var dust := 0
	for k in CrashFx.DUST:
		if fx._du_age[k] < fx._du_life[k]:
			dust += 1
	if fx.bursts != 1 or sparks < 6 or dust < 3:
		fails.append("J3 a 14 m/s crash threw %d sparks and %d dust" % [sparks, dust])
	if not (fx._sparks.visible and fx._dust.visible and fx.is_processing()):
		fails.append("J3 the pools didn't show")
	var out := 0.0
	var lowest := INF
	var frames := 0
	for i in 8:
		fx._process(1.0 / 60.0)
		frames += 1
	for k in CrashFx.SPARKS:
		if fx._sp_age[k] < fx._sp_life[k]:
			out += (fx._sp_pos[k] - at).dot(normal)
	if out <= 0.0:
		fails.append("J3 the sparks didn't fly out of the wall (%.2f)" % out)
	while fx.is_processing() and frames < 240:
		fx._process(1.0 / 60.0)
		frames += 1
		for k in CrashFx.SPARKS:
			if fx._sp_age[k] < fx._sp_life[k]:
				lowest = minf(lowest, fx._sp_pos[k].y)
	if fx.is_processing() or fx._sparks.visible or fx._dust.visible or frames > 120:
		fails.append("J3 still showing after %d frames" % frames)
	print("crash fx: %d sparks, %d dust at 14 m/s, gone after %d frames (%.2f s)" % [sparks, dust, frames, frames / 60.0])

	# J5: never under the road.
	if lowest < -0.001:
		fails.append("J5 a spark went %.2f m under the road" % lowest)

	# J4: a knock under 3 m/s throws nothing; 200 scrapes keep the ring's size.
	fx.crash(at, normal, Vector3.ZERO, 2.5, 0.0, true)
	if fx.bursts != 1 or fx.is_processing():
		fails.append("J4 a 2.5 m/s knock threw something")
	var thrown := fx.sparks_thrown
	for i in 200:
		fx.scrape(at + Vector3(0.0, 0.0, -0.5 * i), normal, Vector3(0.0, 0.0, -12.0), 12.0, 0.0)
		fx._process(1.0 / 60.0)
	if fx._sp_pos.size() != CrashFx.SPARKS or fx._sp_buf.size() != CrashFx.SPARKS * 16 or fx.sparks_thrown - thrown < 400:
		fails.append("J4 the scrape ring grew or threw too few (%d, %d)" % [fx._sp_pos.size(), fx.sparks_thrown - thrown])
	fx.scrape(at, normal, Vector3.ZERO, 3.0, 0.0)
	# The cost of a frame with every slot alive (the worst case: a hard crash during a scrape).
	fx.crash(at, normal, Vector3(0.0, 0.0, -20.0), 20.0, 0.0, true)
	fx.crash(at, normal, Vector3(0.0, 0.0, -20.0), 20.0, 0.0, false)
	var t0 := Time.get_ticks_usec()
	for i in 10:
		fx._process(1.0 / 600.0)
	print("crash fx frame, all %d slots alive: %.0f µs of script" % [CrashFx.SPARKS + CrashFx.DUST, (Time.get_ticks_usec() - t0) / 10.0])
	print("scrape: %d sparks over 200 calls, ring %d" % [fx.sparks_thrown - thrown, fx._sp_pos.size()])
	fx.queue_free()

	for f in fails:
		print("  " + f)
	print("check_juice: %s" % ("OK" if fails.is_empty() else "%d FAILED" % fails.size()))
	quit(0 if fails.is_empty() else 1)
