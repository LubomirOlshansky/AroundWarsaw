extends SceneTree
## Loop 2a: settings.gd round trip. Saves every setting to a scratch file in user://, loads
## it into a fresh copy and compares; a missing file gives the defaults (Point, Normal
## traffic, High, full volumes, overlay off, 60 fps); with persistent = false (--nosave) nothing
## is written. The real user://settings.cfg is never touched. Deletes its scratch files.
##   godot --headless --path game --script res://tools/check_settings.gd

const Settings := preload("res://scripts/settings.gd")
const SCRATCH := "user://settings_check.cfg"
const SCRATCH_OFF := "user://settings_check_nosave.cfg"


func _initialize() -> void:
	var ok := true
	var fresh := Settings.new()
	fresh.path = "user://settings_check_missing.cfg"
	fresh.load_file()
	var defaults := fresh.controls == 0 and fresh.traffic == Settings.NORMAL_TRAFFIC and fresh.quality == 2 \
			and fresh.master == 1.0 and fresh.music == 1.0 and fresh.effects == 1.0 and not fresh.perf and fresh.classic_follow \
			and fresh.fps == 60
	print("defaults from a missing file: %s (%s)" % ["OK" if defaults else "WRONG", fresh.summary()])
	ok = ok and defaults

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

	for f in [SCRATCH, SCRATCH_OFF]:
		if FileAccess.file_exists(f):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(f))
	print("settings: %s" % ("OK" if ok else "PROBLEM"))
	quit(0 if ok else 1)
