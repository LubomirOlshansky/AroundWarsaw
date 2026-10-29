extends Node
## The player's wallet and record, shared by every activity and kept between
## sessions in user://save.cfg (a ConfigFile): złoty and respect, jobs done by kind,
## best times, and the easter eggs found. Races pay the rival's stake, rescues and
## side jobs pay their fares and tips. No shop yet: the money is for bragging.

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
## Egg id -> true once found.
var eggs := {}
## Loop 3g-1 (police.md section 8.4): the joke notebook ("Zeszyt pouczeń"): cautions written
## today and the day they belong to (yyyymmdd; a new day starts it again), and escapes ever (for
## a later achievement). Never money: nothing the police do takes złoty or respect.
var cautions_today := 0
var cautions_day := 0
var escapes_total := 0
## False with --nosave: nothing is read or written.
var persistent := true


func _ready() -> void:
	load_save()


func load_save() -> void:
	if not persistent:
		return
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	zl = int(cfg.get_value("wallet", "zl", 0))
	respect = int(cfg.get_value("wallet", "respect", 0))
	for key in (cfg.get_section_keys("jobs") if cfg.has_section("jobs") else PackedStringArray()):
		jobs[key] = int(cfg.get_value("jobs", key, 0))
	for key in (cfg.get_section_keys("best") if cfg.has_section("best") else PackedStringArray()):
		best[key] = float(cfg.get_value("best", key, 0.0))
	for key in (cfg.get_section_keys("eggs") if cfg.has_section("eggs") else PackedStringArray()):
		if bool(cfg.get_value("eggs", key, false)):
			eggs[key] = true
	cautions_today = int(cfg.get_value("police", "cautions_today", 0))
	cautions_day = int(cfg.get_value("police", "cautions_day", 0))
	escapes_total = int(cfg.get_value("police", "escapes_total", 0))


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
		cfg.set_value("eggs", key, true)
	cfg.set_value("police", "cautions_today", cautions_today)
	cfg.set_value("police", "cautions_day", cautions_day)
	cfg.set_value("police", "escapes_total", escapes_total)
	cfg.save(PATH)


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


## Marks an easter egg found; true the first time.
func find_egg(id: String) -> bool:
	if eggs.has(id):
		return false
	eggs[id] = true
	save()
	return true


func eggs_found() -> int:
	var n := 0
	for id in EGGS:
		if eggs.has(id):
			n += 1
	return n


func summary() -> String:
	return "%d zł, respect %d, jobs %s, best %s, eggs %d/%d" % [zl, respect, jobs, best, eggs_found(), EGGS.size()]


## "1 240 zł": thousands apart with a space, the Polish way.
static func money(amount: int) -> String:
	var digits := str(absi(amount))
	var out := ""
	while digits.length() > 3:
		out = " " + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if amount < 0 else "") + digits + out + " zł"
