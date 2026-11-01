extends SceneTree
## Loop 2a: settings.gd round trip. Saves every setting to a scratch file in user://, loads
## it into a fresh copy and compares; a missing file gives the defaults (Point, Normal
## traffic, High, full volumes, overlay off, 60 fps; loop 2e: Classic's camera following, the
## Sharp style, no VHS; loop G1: quality Auto instead of High); with persistent = false (--nosave)
## nothing is written. Loop G1: a file saved before G1 (no `tiers` key) that says High loads as
## Auto, once (a file saved since keeps High, Medium stays Medium, Ultra round-trips). Loop G1b:
## Auto's image state (`[auto_image]`) round-trips, a file without it starts sharp, hand-edited
## values are cleaned, and --nosave writes none of it either. F's asks (2026-10-30): the
## pedestrian zones' cap (`zone_cap`) is off in a missing file and round-trips on. The real
## user://settings.cfg is never touched. Deletes its scratch files.
##   godot --headless --path game --script res://tools/check_settings.gd

const Settings := preload("res://scripts/settings.gd")
const Tiers := preload("res://scripts/tiers.gd")
const SCRATCH := "user://settings_check.cfg"
const SCRATCH_OFF := "user://settings_check_nosave.cfg"
const SCRATCH_OLD := "user://settings_check_old.cfg"


func _initialize() -> void:
	var ok := true
	var fresh := Settings.new()
	fresh.path = "user://settings_check_missing.cfg"
	fresh.load_file()
	var defaults := fresh.controls == 0 and fresh.traffic == Settings.DEFAULT_TRAFFIC and fresh.quality == Settings.AUTO \
			and fresh.master == 1.0 and fresh.music == 1.0 and fresh.effects == 1.0 and not fresh.perf and fresh.classic_follow \
			and fresh.fps == 60 and fresh.style == 0 and not fresh.vhs and not fresh.zone_cap \
			and not fresh.text_large and not fresh.calm and not fresh.color_safe and fresh.vibration and fresh.stop_assist \
			and not fresh.left_handed
	print("defaults from a missing file: %s (%s)" % ["OK" if defaults else "WRONG", fresh.summary()])
	ok = ok and defaults

	# Loop G1: the quality saved before G1 (a file without the `tiers` key, as loop 2a wrote it).
	var cases := [[2, false, Settings.AUTO], [1, false, 1], [0, false, 0], [2, true, 2], [Settings.ULTRA, true, Settings.ULTRA],
			[Settings.AUTO, true, Settings.AUTO]]
	var migrated := true
	for c in cases:
		var cfg := ConfigFile.new()
		cfg.set_value("world", "quality", c[0])
		if c[1]:
			cfg.set_value("world", "tiers", 1)
		cfg.save(SCRATCH_OLD)
		var s := Settings.new()
		s.path = SCRATCH_OLD
		s.load_file()
		if s.quality != c[2]:
			migrated = false
			print("  quality %d saved %s G1 loads as %d, wanted %d" % [c[0], "after" if c[1] else "before", s.quality, c[2]])
	# Once: loaded as Auto and saved, it stays Auto; a High chosen after that stays High.
	var once := Settings.new()
	once.path = SCRATCH_OLD
	var cfg_old := ConfigFile.new()
	cfg_old.set_value("world", "quality", 2)
	cfg_old.save(SCRATCH_OLD)
	once.load_file()
	once.save()
	once.quality = 2
	once.save()
	var again := Settings.new()
	again.path = SCRATCH_OLD
	again.load_file()
	migrated = migrated and again.quality == 2
	print("quality saved before loop G1: %s (High → Auto once, the rest kept, High chosen since kept: %d)" % [
			"OK" if migrated else "WRONG", again.quality])
	ok = ok and migrated

	var a := Settings.new()
	a.path = SCRATCH
	a.controls = 1
	a.classic_follow = false
	a.traffic = 0
	a.quality = 1
	a.master = 0.7
	a.music = 0.35
	a.effects = 0.0
	a.perf = true
	a.fps = 30
	a.style = 3
	a.vhs = true
	a.zone_cap = true
	a.text_large = true
	a.calm = true
	a.color_safe = true
	a.vibration = false
	a.stop_assist = false
	a.left_handed = true
	a.save()
	var b := Settings.new()
	b.path = SCRATCH
	b.load_file()
	var same := a.summary() == b.summary() and b.classic_follow == a.classic_follow
	print("round trip: %s\n  saved  %s\n  loaded %s" % ["OK" if same else "DIFFERENT", a.summary(), b.summary()])
	ok = ok and same

	# Loop G1b: Auto's image state round-trips; a file without it (from before G1b) or with
	# hand-edited values starts sharp / is cleaned.
	var img := Settings.new()
	img.path = SCRATCH
	img.auto_image = {"fallback": true, "calm": 1, "wait": 4, "trial": -1, "why": "GPU extras down 74 s of 410", "told": false}
	img.save()
	var img_back := Settings.new()
	img_back.path = SCRATCH
	img_back.load_file()
	var cfg_pre := ConfigFile.new()
	cfg_pre.set_value("world", "quality", -1)
	cfg_pre.set_value("world", "tiers", 1)
	cfg_pre.save(SCRATCH_OLD)
	var pre := Settings.new()
	pre.path = SCRATCH_OLD
	pre.load_file()
	var cfg_odd := ConfigFile.new()
	cfg_odd.set_value("auto_image", "fallback", true)
	cfg_odd.set_value("auto_image", "wait", 500)
	cfg_odd.set_value("auto_image", "calm", -2)
	cfg_odd.save(SCRATCH_OLD)
	var odd := Settings.new()
	odd.path = SCRATCH_OLD
	odd.load_file()
	var image_ok: bool = img_back.auto_image == img.auto_image and pre.auto_image == Tiers.sharp_state() \
			and odd.auto_image["fallback"] and int(odd.auto_image["wait"]) == Tiers.SHARP_WAIT_MAX and int(odd.auto_image["calm"]) == 0
	print("Auto's image state: %s (round trip: %s; a file from before G1b: %s; hand-edited: %s)" % ["OK" if image_ok else "WRONG",
			img_back.image_summary(), pre.image_summary(), odd.image_summary()])
	ok = ok and image_ok

	var off := Settings.new()
	off.path = SCRATCH_OFF
	off.persistent = false
	off.traffic = 3
	off.auto_image = Tiers.sharp_struggled(Tiers.sharp_state(), true, "nosave")
	off.save()
	var wrote := FileAccess.file_exists(SCRATCH_OFF)
	print("--nosave writes nothing: %s" % ("OK" if not wrote else "WROTE A FILE"))
	ok = ok and not wrote

	for f in [SCRATCH, SCRATCH_OFF, SCRATCH_OLD]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	ok = _check_tint() and ok
	print("settings: %s" % ("OK" if ok else "PROBLEM"))
	quit(0 if ok else 1)


## Colour-safe (access.gd `tint`): off, every colour as it is; on, the game's success green and fail
## red (every script's constant for them) turn blue and vermilion, and other colours stay.
func _check_tint() -> bool:
	var A := preload("res://scripts/access.gd")
	var greens := [A.GREEN, load("res://scripts/missions.gd").DROPOFF_COLOUR, load("res://scripts/rivals.gd").WIN_COLOUR]
	var reds := [A.RED, load("res://scripts/missions.gd").FAIL_COLOUR, load("res://scripts/rivals.gd").LOSE_COLOUR,
			load("res://scripts/jobs.gd").FAIL_COLOUR, load("res://scripts/rides.gd").FAIL_COLOUR,
			load("res://scripts/roundup_job.gd").FAIL_COLOUR, load("res://scripts/trend_job.gd").FAIL_COLOUR]
	var others := [Color("#ffd23f"), Color("#ff8a3d"), Color("#4fd8c4"), Color("#ff4fd8"), Color.WHITE]
	var good := true
	var was: bool = A.color_safe
	A.color_safe = false
	for c in greens + reds + others:
		good = good and A.tint(c) == c
	A.color_safe = true
	for c in greens:
		good = good and A.tint(c) == A.GREEN_SAFE
	for c in reds:
		good = good and A.tint(c) == A.RED_SAFE
	for c in others:
		good = good and A.tint(c) == c
	var faded := Color(A.GREEN, 0.5)
	good = good and is_equal_approx(A.tint(faded).a, 0.5) and A.tint(faded).b > 0.9
	A.color_safe = was
	print("colour-safe tint: %s (%d greens -> blue, %d reds -> vermilion, %d others kept)" % ["OK" if good else "WRONG",
			greens.size(), reds.size(), others.size()])
	return good
