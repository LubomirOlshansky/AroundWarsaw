extends SceneTree
## Loop 2a: settings.gd round trip. Saves every setting to a scratch file in user://, loads
## it into a fresh copy and compares; a missing file gives the defaults (Point, Normal
## traffic, High, full volumes, overlay off, 60 fps; loop 2e: Classic's camera following, the
## Sharp style, no VHS; loop G1: quality Auto instead of High); with persistent = false (--nosave)
## nothing is written. Loop G1: a file saved before G1 (no `tiers` key) that says High loads as
## Auto, once (a file saved since keeps High, Medium stays Medium, Ultra round-trips). The real
## user://settings.cfg is never touched. Deletes its scratch files.
##   godot --headless --path game --script res://tools/check_settings.gd

const Settings := preload("res://scripts/settings.gd")
const SCRATCH := "user://settings_check.cfg"
const SCRATCH_OFF := "user://settings_check_nosave.cfg"
const SCRATCH_OLD := "user://settings_check_old.cfg"


func _initialize() -> void:
	var ok := true
	var fresh := Settings.new()
	fresh.path = "user://settings_check_missing.cfg"
	fresh.load_file()
	var defaults := fresh.controls == 0 and fresh.traffic == Settings.NORMAL_TRAFFIC and fresh.quality == Settings.AUTO \
			and fresh.master == 1.0 and fresh.music == 1.0 and fresh.effects == 1.0 and not fresh.perf and fresh.classic_follow \
			and fresh.fps == 60 and fresh.style == 0 and not fresh.vhs
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
	a.save()
	var b := Settings.new()
	b.path = SCRATCH
	b.load_file()
	var same := a.summary() == b.summary() and b.classic_follow == a.classic_follow
	print("round trip: %s\n  saved  %s\n  loaded %s" % ["OK" if same else "DIFFERENT", a.summary(), b.summary()])
	ok = ok and same

	var off := Settings.new()
	off.path = SCRATCH_OFF
	off.persistent = false
	off.traffic = 3
	off.save()
	var wrote := FileAccess.file_exists(SCRATCH_OFF)
	print("--nosave writes nothing: %s" % ("OK" if not wrote else "WROTE A FILE"))
	ok = ok and not wrote

	for f in [SCRATCH, SCRATCH_OFF, SCRATCH_OLD]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	print("settings: %s" % ("OK" if ok else "PROBLEM"))
	quit(0 if ok else 1)
