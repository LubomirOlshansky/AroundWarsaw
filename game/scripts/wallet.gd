extends Node
## The player's wallet and record, shared by every activity and kept between
## sessions in user://save.cfg (a ConfigFile): złoty and respect, jobs done by kind,
## best times, and the easter eggs found. Races pay the rival's stake, rescues and
## side jobs pay their fares and tips. The garage loop: the złoty buy paint jobs at Warsztat u
## Mirka (garage.gd: `spend`, `paint`, `paints`; the save's [garage] section).

signal changed(zl: int, respect: int, gained: int)

const PATH := "user://save.cfg"
## The easter eggs that count towards "found x/5".
const EGGS := {"palma": "The Palm on Rondo de Gaulle'a", "pigeons": "Pigeons on Plac Defilad",
		"barriers": "The wandering roadworks", "patelnia": "Patelnia by Metro Centrum",
		"syrenka": "The Mermaid on the boulevard"}

var zl := 0
var respect := 0
## Kind ("kebab", "sloik", "rescue", "race") -> how many done.
var jobs := {}
## Key -> best time in seconds.
var best := {}
## Egg id -> true once found (v0.65); loop MW-6: the day it was found (yyyymmdd), or 1 for a find
## saved before MW-6 (its day unknown). Every egg card of data/eggs.json (egg_book.gd) counts.
var eggs := {}
## Loop 3g-1 (police.md section 8.4): the joke notebook ("Zeszyt pouczeń"): cautions written
## today and the day they belong to (yyyymmdd; a new day starts it again), and escapes ever (for
## a later achievement). Never money: nothing the police do takes złoty or respect.
var cautions_today := 0
var cautions_day := 0
var escapes_total := 0
## Loop 2d-1: other things kept by name (rides.gd: "podwozka_ratings", the last 20 rides' stars,
## and "podwozka_streak", the 5-star rides in a row).
var keep := {}
## Loop MW-1: the MOJA WARSZAWA notebook (notebook.gd): place id -> the day it was first found
## (yyyymmdd), and chapter id -> the day it was completed (its reward paid; MW-5's track unlock
## reads it).
var notes := {}
var chapters_done := {}
## Loop MW-5: PÓŁNOC FM's unlocked tracks (radio.gd): track number (1 = the first) -> the day it
## opened (yyyymmdd; the free ones are not listed), and how many finished chapters have been
## turned into tracks already (radio.gd `sync_chapters`).
var tracks := {}
var track_chapters := 0
## Loop MW-6: KASETA's then cards played (tape.gd): card id -> the day (yyyymmdd); and Fotka's Kadr
## spots shot (fotka.gd): spot id -> the day, with the photo's file under user://photos/ in
## `kadr_photos` (spot id -> path).
var tapes := {}
var kadr := {}
var kadr_photos := {}
## Loop MW-6: the egg cards in all (egg_book.gd sets it from data/eggs.json; the five of v0.65 alone
## without it).
var eggs_total := 0
## The garage loop: the paint on the car (garage.gd PAINTS id; "red", the factory paint, by
## default) and the paints bought (id -> the day, yyyymmdd; the factory red is never listed).
var paint := "red"
var paints := {}
## False with --nosave: nothing is read or written.
var persistent := true
## Loop MW-5: the save's file (check_radio.gd points it at a scratch file of its own).
var path := PATH


func _ready() -> void:
	load_save()


func load_save() -> void:
	if not persistent:
		return
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	zl = int(cfg.get_value("wallet", "zl", 0))
	respect = int(cfg.get_value("wallet", "respect", 0))
	for key in (cfg.get_section_keys("jobs") if cfg.has_section("jobs") else PackedStringArray()):
		jobs[key] = int(cfg.get_value("jobs", key, 0))
	for key in (cfg.get_section_keys("best") if cfg.has_section("best") else PackedStringArray()):
		best[key] = float(cfg.get_value("best", key, 0.0))
	for key in (cfg.get_section_keys("eggs") if cfg.has_section("eggs") else PackedStringArray()):
		var v: Variant = cfg.get_value("eggs", key, false)
		if v is int and int(v) > 0:
			eggs[key] = int(v)
		elif v is bool and v:
			eggs[key] = 1
	cautions_today = int(cfg.get_value("police", "cautions_today", 0))
	cautions_day = int(cfg.get_value("police", "cautions_day", 0))
	escapes_total = int(cfg.get_value("police", "escapes_total", 0))
	for key in (cfg.get_section_keys("keep") if cfg.has_section("keep") else PackedStringArray()):
		keep[key] = cfg.get_value("keep", key)
	for key in (cfg.get_section_keys("notes") if cfg.has_section("notes") else PackedStringArray()):
		notes[key] = int(cfg.get_value("notes", key, 0))
	for key in (cfg.get_section_keys("notes_chapters") if cfg.has_section("notes_chapters") else PackedStringArray()):
		chapters_done[key] = int(cfg.get_value("notes_chapters", key, 0))
	for key in (cfg.get_section_keys("polnoc") if cfg.has_section("polnoc") else PackedStringArray()):
		if key.begins_with("track_"):
			tracks[int(key.trim_prefix("track_"))] = int(cfg.get_value("polnoc", key, 0))
	track_chapters = int(cfg.get_value("polnoc", "chapters", 0))
	for key in (cfg.get_section_keys("tapes") if cfg.has_section("tapes") else PackedStringArray()):
		tapes[key] = int(cfg.get_value("tapes", key, 0))
	for key in (cfg.get_section_keys("kadr") if cfg.has_section("kadr") else PackedStringArray()):
		kadr[key] = int(cfg.get_value("kadr", key, 0))
	for key in (cfg.get_section_keys("kadr_photos") if cfg.has_section("kadr_photos") else PackedStringArray()):
		kadr_photos[key] = str(cfg.get_value("kadr_photos", key, ""))
	paint = str(cfg.get_value("garage", "paint", "red"))
	for key in (cfg.get_section_keys("garage") if cfg.has_section("garage") else PackedStringArray()):
		if key.begins_with("own_"):
			paints[key.trim_prefix("own_")] = int(cfg.get_value("garage", key, 1))


func save() -> void:
	if not persistent:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("wallet", "zl", zl)
	cfg.set_value("wallet", "respect", respect)
	for key in jobs:
		cfg.set_value("jobs", key, jobs[key])
	for key in best:
		cfg.set_value("best", key, best[key])
	for key in eggs:
		cfg.set_value("eggs", key, int(eggs[key]))
	cfg.set_value("police", "cautions_today", cautions_today)
	cfg.set_value("police", "cautions_day", cautions_day)
	cfg.set_value("police", "escapes_total", escapes_total)
	for key in keep:
		cfg.set_value("keep", key, keep[key])
	for key in notes:
		cfg.set_value("notes", key, notes[key])
	for key in chapters_done:
		cfg.set_value("notes_chapters", key, chapters_done[key])
	for n in tracks:
		cfg.set_value("polnoc", "track_%d" % n, tracks[n])
	cfg.set_value("polnoc", "chapters", track_chapters)
	for key in tapes:
		cfg.set_value("tapes", key, tapes[key])
	for key in kadr:
		cfg.set_value("kadr", key, kadr[key])
	for key in kadr_photos:
		cfg.set_value("kadr_photos", key, kadr_photos[key])
	cfg.set_value("garage", "paint", paint)
	for key in paints:
		cfg.set_value("garage", "own_" + str(key), int(paints[key]))
	cfg.save(path)


## Wipes the record (--reset-save).
func reset() -> void:
	zl = 0
	respect = 0
	jobs.clear()
	best.clear()
	eggs.clear()
	cautions_today = 0
	cautions_day = 0
	escapes_total = 0
	keep.clear()
	notes.clear()
	chapters_done.clear()
	tracks.clear()
	track_chapters = 0
	tapes.clear()
	kadr.clear()
	kadr_photos.clear()
	paint = "red"
	paints.clear()
	save()
	changed.emit(zl, respect, 0)


## Pays `amount` złoty and `gain` respect, counts a finished job of `kind` (if any)
## and saves.
func pay(amount: int, gain := 0, kind := "") -> void:
	zl += amount
	respect += gain
	if kind != "":
		jobs[kind] = int(jobs.get(kind, 0)) + 1
	save()
	changed.emit(zl, respect, amount)
	print("wallet: +%d zł, +%d respect (%s) -> %d zł, respect %d" % [amount, gain, kind if kind != "" else "-", zl, respect])


## The garage loop: pays `amount` złoty out of the wallet (a paint job) and saves; false (nothing
## paid) when there are not that many.
func spend(amount: int) -> bool:
	if amount < 0 or amount > zl:
		return false
	zl -= amount
	save()
	changed.emit(zl, respect, -amount)
	print("wallet: -%d zł (garage) -> %d zł, respect %d" % [amount, zl, respect])
	return true


## Loop 3g-1: respect only (an escape from the police, +15); the złoty are never touched.
func add_respect(gain: int) -> void:
	respect += gain
	save()
	changed.emit(zl, respect, 0)
	print("wallet: +%d respect (police) -> %d zł, respect %d" % [gain, zl, respect])


## Loop 3g-1: a caution in the joke notebook on day `today` (yyyymmdd); returns today's count.
func add_caution(today: int) -> int:
	if cautions_day != today:
		cautions_day = today
		cautions_today = 0
	cautions_today += 1
	save()
	return cautions_today


## Loop 3g-1: the notebook's count for `today` (0 if the last caution was on another day).
func cautions_on(today: int) -> int:
	return cautions_today if cautions_day == today else 0


## Loop 3g-1: an escape counted (never money).
func add_escape() -> void:
	escapes_total += 1
	save()


## Records a time under `key`; true if it beats the best (or is the first).
func record(key: String, seconds: float) -> bool:
	if best.has(key) and float(best[key]) <= seconds:
		return false
	best[key] = snappedf(seconds, 0.1)
	save()
	return true


func best_time(key: String) -> float:
	return float(best.get(key, -1.0))


## Marks an easter egg found (loop MW-6: on day `date`, yyyymmdd); true the first time.
func find_egg(id: String, date := 1) -> bool:
	if eggs.has(id):
		return false
	eggs[id] = maxi(1, date)
	save()
	return true


## Loop MW-6: every egg card found (the save's ids; the five of v0.65 are cards too).
func eggs_found() -> int:
	return eggs.size()


## Loop MW-6: the egg cards in all (EGGS' five until egg_book.gd says).
func egg_count() -> int:
	return eggs_total if eggs_total > 0 else EGGS.size()


func summary() -> String:
	return "%d zł, respect %d, jobs %s, best %s, eggs %d/%d, notebook %d, tapes %d, kadr %d, paint %s (%d bought)" % [zl, respect,
			jobs, best, eggs_found(), egg_count(), notes.size(), tapes.size(), kadr.size(), paint, paints.size()]


## "1 240 zł": thousands apart with a space, the Polish way.
static func money(amount: int) -> String:
	var digits := str(absi(amount))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if amount < 0 else "") + digits + out + " zł"
