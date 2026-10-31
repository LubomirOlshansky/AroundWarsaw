extends SceneTree
## Loop 3h slice 1: save v2 (wallet.gd, settings.gd). Builds an old-format (version 1, no
## `[save]` section) save.cfg in a scratch file with every section the game wrote before loop 3h
## (wallet, jobs, best, eggs, one saved as `true` as v0.65 did, police, keep with an array,
## notes, chapters, PÓŁNOC FM, tapes, Kadr and its photos, the garage) plus a section from "a
## newer build", and checks that:
## - loading it keeps every value, reports version 1 migrated to 2, and copies the old file beside
##   it unchanged (save.v1.cfg);
## - the next save writes version 2, keeps the unknown section, and a fresh load of it gives the
##   same record (and the v2 additions: districts, their jobs, the Syrenki round-trip; loop 3h
##   slice 4: the [intro] section too);
## - a job paid in a district counts there; reset() clears the v2 sections too;
## - a file of a newer version is read but never overwritten;
## - with persistent = false (--nosave) nothing is read or written (no file appears);
## - a missing file gives the defaults and version 0;
## - settings.cfg: a file without `[meta]` loads as version 1 and the next save writes 2; a newer
##   one is never overwritten; --nosave writes nothing.
## Never touches the real user://save.cfg or settings.cfg; deletes its scratch files.
##   godot --headless --path game --script res://tools/check_save.gd

const Wallet := preload("res://scripts/wallet.gd")
const Settings := preload("res://scripts/settings.gd")
const SCRATCH := "user://check_save.cfg"
const SCRATCH_NEW := "user://check_save_newer.cfg"
const SCRATCH_OFF := "user://check_save_nosave.cfg"
const SCRATCH_SET := "user://check_save_settings.cfg"

var _problems := 0


func _initialize() -> void:
	_clean()
	_old_save()
	_round_trip()
	_newer()
	_nosave()
	_missing()
	_settings()
	_clean()
	if _problems == 0:
		print("check_save: OK")
		quit(0)
	else:
		print("check_save: %d problem(s)" % _problems)
		quit(1)


func _expect(ok: bool, what: String) -> void:
	if not ok:
		_problems += 1
		print("  WRONG: %s" % what)


## The version-1 fixture: what wallet.gd wrote before loop 3h, section by section.
func _v1_fixture() -> ConfigFile:
	var cfg := ConfigFile.new()
	cfg.set_value("wallet", "zl", 1240)
	cfg.set_value("wallet", "respect", 87)
	cfg.set_value("jobs", "kebab", 4)
	cfg.set_value("jobs", "race", 2)
	cfg.set_value("best", "race_0", 61.4)
	cfg.set_value("eggs", "palma", true)
	cfg.set_value("eggs", "e03", 20261030)
	cfg.set_value("police", "cautions_today", 2)
	cfg.set_value("police", "cautions_day", 20261031)
	cfg.set_value("police", "escapes_total", 3)
	cfg.set_value("keep", "podwozka_ratings", [5, 4, 5])
	cfg.set_value("keep", "podwozka_streak", 2)
	cfg.set_value("notes", "patelnia", 20261029)
	cfg.set_value("notes", "bulwary", 20261030)
	cfg.set_value("notes_chapters", "schodki", 20261030)
	cfg.set_value("polnoc", "track_3", 20261030)
	cfg.set_value("polnoc", "chapters", 1)
	cfg.set_value("tapes", "t01", 20261030)
	cfg.set_value("kadr", "k02", 20261030)
	cfg.set_value("kadr_photos", "k02", "user://photos/k02.png")
	cfg.set_value("garage", "paint", "teal")
	cfg.set_value("garage", "own_teal", 20261031)
	cfg.set_value("from_the_future", "thing", 42)
	return cfg


func _check_v1_values(w: Node, label: String) -> void:
	_expect(w.zl == 1240 and w.respect == 87, "%s: wallet %d zł, respect %d" % [label, w.zl, w.respect])
	_expect(w.jobs == {"kebab": 4, "race": 2}, "%s: jobs %s" % [label, w.jobs])
	_expect(is_equal_approx(float(w.best.get("race_0", 0.0)), 61.4), "%s: best %s" % [label, w.best])
	_expect(w.eggs == {"palma": 1, "e03": 20261030}, "%s: eggs %s" % [label, w.eggs])
	_expect(w.cautions_today == 2 and w.cautions_day == 20261031 and w.escapes_total == 3, "%s: police %d %d %d" % [label,
			w.cautions_today, w.cautions_day, w.escapes_total])
	_expect(w.keep.get("podwozka_ratings") == [5, 4, 5] and int(w.keep.get("podwozka_streak", 0)) == 2, "%s: keep %s" % [label, w.keep])
	_expect(w.notes == {"patelnia": 20261029, "bulwary": 20261030}, "%s: notes %s" % [label, w.notes])
	_expect(w.chapters_done == {"schodki": 20261030}, "%s: chapters %s" % [label, w.chapters_done])
	_expect(w.tracks == {3: 20261030} and w.track_chapters == 1, "%s: polnoc %s %d" % [label, w.tracks, w.track_chapters])
	_expect(w.tapes == {"t01": 20261030} and w.kadr == {"k02": 20261030}, "%s: tapes %s kadr %s" % [label, w.tapes, w.kadr])
	_expect(w.kadr_photos == {"k02": "user://photos/k02.png"}, "%s: kadr photos %s" % [label, w.kadr_photos])
	_expect(w.paint == "teal" and w.paints == {"teal": 20261031}, "%s: garage %s %s" % [label, w.paint, w.paints])


func _old_save() -> void:
	_v1_fixture().save(SCRATCH)
	var before := FileAccess.get_file_as_string(SCRATCH)
	var w := Wallet.new()
	w.path = SCRATCH
	w.load_save()
	_check_v1_values(w, "v1 loaded")
	_expect(w.loaded_version == 1 and w.migrated_from == 1 and not w.newer, "v1: version %d, migrated from %d" % [
			w.loaded_version, w.migrated_from])
	_expect(w.districts.is_empty() and w.district_jobs.is_empty() and w.syrenki.is_empty(), "v1: v2 sections not empty")
	var backup := w.backup_path(1)
	_expect(FileAccess.file_exists(backup) and FileAccess.get_file_as_string(backup) == before, "v1: the old file kept as %s" % backup)
	# The next save writes v2 and keeps the section this build does not know.
	w.save()
	var cfg := ConfigFile.new()
	_expect(cfg.load(SCRATCH) == OK, "v1 -> v2: the file reads")
	_expect(int(cfg.get_value("save", "version", 0)) == Wallet.VERSION, "v1 -> v2: version %s" % cfg.get_value("save", "version", "-"))
	_expect(int(cfg.get_value("from_the_future", "thing", 0)) == 42, "v1 -> v2: the unknown section dropped")
	_expect(cfg.get_value("eggs", "palma") is int, "v1 -> v2: the egg saved as true is still a bool")
	var again := Wallet.new()
	again.path = SCRATCH
	again.load_save()
	_check_v1_values(again, "v2 reloaded")
	_expect(again.loaded_version == 2 and again.migrated_from == 0, "v2 reloaded: version %d, migrated from %d" % [
			again.loaded_version, again.migrated_from])
	w.free()
	again.free()
	# migrate() on its own: a false egg is dropped, true becomes 1, the version is set.
	var m := ConfigFile.new()
	m.set_value("eggs", "a", true)
	m.set_value("eggs", "b", false)
	_expect(Wallet.migrate(m, 1) == 2 and m.get_value("eggs", "a") == 1 and not m.has_section_key("eggs", "b")
			and int(m.get_value("save", "version", 0)) == 2, "migrate(1): %s" % m.encode_to_text())


func _round_trip() -> void:
	var w := Wallet.new()
	w.path = SCRATCH
	w.load_save()
	w.districts = {"powisle": 20261031, "srodmiescie": 20261030}
	w.syrenki = {"s01": 20261031}
	w.intro = {"finger": 20261031, "end_seen": 20261031}  # loop 3h slice 4
	w.district = "powisle"
	w.pay(25, 1, "kebab")
	w.pay(10, 0)  # no kind: not a job
	_expect(w.district_jobs == {"powisle": 1}, "a job paid in Powiśle: %s" % w.district_jobs)
	_expect(int(w.jobs.get("kebab", 0)) == 5, "the job counted by kind too: %s" % w.jobs)
	var b := Wallet.new()
	b.path = SCRATCH
	b.load_save()
	_expect(b.districts == w.districts and b.district_jobs == w.district_jobs and b.syrenki == w.syrenki,
			"round trip of the v2 sections: %s %s %s" % [b.districts, b.district_jobs, b.syrenki])
	_expect(b.zl == 1275 and b.respect == 88 and b.notes == w.notes and b.eggs == w.eggs and b.paints == w.paints
			and b.keep == w.keep and b.tracks == w.tracks, "round trip of the v1 sections: %s" % b.summary())
	_expect(b.district == "", "the district now is not saved: %s" % b.district)
	_expect(b.intro == w.intro, "round trip of [intro] (loop 3h slice 4): %s" % b.intro)
	b.reset()
	_expect(b.districts.is_empty() and b.district_jobs.is_empty() and b.syrenki.is_empty() and b.intro.is_empty() and b.zl == 0, "reset() left %s" % b.summary())
	w.free()
	b.free()


func _newer() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("save", "version", Wallet.VERSION + 1)
	cfg.set_value("wallet", "zl", 500)
	cfg.set_value("next_thing", "x", 1)
	cfg.save(SCRATCH_NEW)
	var before := FileAccess.get_file_as_string(SCRATCH_NEW)
	var w := Wallet.new()
	w.path = SCRATCH_NEW
	w.load_save()
	_expect(w.newer and w.zl == 500, "a newer save: newer %s, %d zł" % [w.newer, w.zl])
	w.pay(100, 1, "kebab")
	_expect(FileAccess.get_file_as_string(SCRATCH_NEW) == before, "a newer save was overwritten")
	_expect(not FileAccess.file_exists(w.backup_path(Wallet.VERSION + 1)), "a newer save got a backup")
	w.free()


func _nosave() -> void:
	var w := Wallet.new()
	w.persistent = false
	w.path = SCRATCH_OFF
	w.load_save()
	w.district = "praga"
	w.pay(50, 2, "race")
	w.find_egg("palma", 20261031)
	w.districts["praga"] = 20261031
	w.save()
	w.reset()
	_expect(not FileAccess.file_exists(SCRATCH_OFF), "--nosave wrote %s" % SCRATCH_OFF)
	# A v1 file under --nosave: not read, not migrated, no backup.
	_v1_fixture().save(SCRATCH_OFF)
	var off := Wallet.new()
	off.persistent = false
	off.path = SCRATCH_OFF
	off.load_save()
	_expect(off.zl == 0 and off.loaded_version == 0 and not FileAccess.file_exists(off.backup_path(1)), "--nosave read or backed up a v1 file")
	w.free()
	off.free()


func _missing() -> void:
	var w := Wallet.new()
	w.path = "user://check_save_missing.cfg"
	w.load_save()
	_expect(w.zl == 0 and w.loaded_version == 0 and w.migrated_from == 0 and w.paint == "red" and w.districts.is_empty(),
			"a missing file: %s" % w.summary())
	w.free()


func _settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("controls", "scheme", 1)
	cfg.set_value("world", "traffic", 3)
	cfg.set_value("world", "quality", 2)  # High before loop G1: Auto, once
	cfg.save(SCRATCH_SET)
	var s := Settings.new()
	s.path = SCRATCH_SET
	s.load_file()
	_expect(s.loaded_version == 1 and s.controls == 1 and s.traffic == 3 and s.quality == Settings.AUTO,
			"settings v1: version %d, %s" % [s.loaded_version, s.summary()])
	s.save()
	var out := ConfigFile.new()
	out.load(SCRATCH_SET)
	_expect(int(out.get_value("meta", "version", 0)) == Settings.VERSION, "settings: the save wrote version %s" % out.get_value("meta", "version", "-"))
	var t := Settings.new()
	t.path = SCRATCH_SET
	t.load_file()
	_expect(t.loaded_version == Settings.VERSION and t.controls == 1 and t.traffic == 3 and t.quality == Settings.AUTO,
			"settings v2 reloaded: version %d, %s" % [t.loaded_version, t.summary()])
	out.set_value("meta", "version", Settings.VERSION + 1)
	out.save(SCRATCH_SET)
	var before := FileAccess.get_file_as_string(SCRATCH_SET)
	var n := Settings.new()
	n.path = SCRATCH_SET
	n.load_file()
	n.controls = 2
	n.save()
	_expect(n.newer and FileAccess.get_file_as_string(SCRATCH_SET) == before, "settings: a newer file was overwritten")
	var off := Settings.new()
	off.persistent = false
	off.path = "user://check_save_settings_off.cfg"
	off.save()
	_expect(not FileAccess.file_exists(off.path), "settings: --nosave wrote a file")


func _clean() -> void:
	for p in [SCRATCH, SCRATCH_NEW, SCRATCH_OFF, SCRATCH_SET, "user://check_save.v1.cfg", "user://check_save_nosave.v1.cfg",
			"user://check_save_newer.v3.cfg", "user://check_save_settings_off.cfg", "user://check_save_missing.cfg"]:
		if FileAccess.file_exists(p):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(p))
