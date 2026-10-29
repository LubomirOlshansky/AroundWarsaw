extends Node
## Everybody's lines: the original Polish lines with English subtitles from
## data/dialogue.json, by group (radio_host, kebab_vendor, passenger, traffic...).
## line() picks one without repeating a group's lines until they have all been
## used; a line can carry notes that limit it to a situation ({"only": "roof"}).
## say() speaks one through the speech bubbles (bubbles.gd).
##
## It also runs the city's chatter: an AI driver the player hits, or holds up for a
## while, sometimes shouts a "traffic" line from its car; and the radio host reads
## a "radio_host" line on the radio's ticker every minute or two on a station.

## Loop 2b: time spent in this script's per-frame work since the bench last read it (µs).
var spent_usec := 0

const PATH := "res://data/dialogue.json"
const SHOUT_GAP := 9.0          # seconds between two drivers' shouts
const HOST_GAP := Vector2(60.0, 120.0)
const DRIVERS := ["Kierowca", "Taksówkarz", "Dostawca", "Kierowca autobusu"]

var lines := {}
var bubbles: Control
var radio: Node
## The radio host waits while this is false (the title screen).
var host_on := true
## Loop 2d-1: a Podwózka card is up: the host's next line waits until it goes (then comes at once).
var host_hold := false
## Seconds to the first host line on a station (--host-in=, for screenshots).
var host_first := -1.0

var _bags := {}
var _last := {}
var _rng := RandomNumberGenerator.new()
var _shout_wait := 0.0
var _host_t := 0.0
var _host_next := 90.0


func _ready() -> void:
	_rng.randomize()
	var text := FileAccess.get_file_as_string(PATH)
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		for key in parsed:
			if not String(key).begins_with("_"):
				lines[key] = parsed[key]
	_host_next = host_first if host_first >= 0.0 else _rng.randf_range(HOST_GAP.x, HOST_GAP.y)


## A line of `group` as [Polish, English] (plus its notes, if any), or [] if the
## group has none. Lines with {"only": ...} notes are left out unless `tag` is one
## of them; with `prefer`, a line made for `tag` is picked when there is one.
func line(group: String, tag := "", prefer := false) -> Array:
	var all: Array = lines.get(group, [])
	var fits: Array[int] = []
	var made_for: Array[int] = []
	for i in all.size():
		var only = notes(all[i]).get("only", null)
		if only == null:
			fits.append(i)
		elif (only is String and only == tag) or (only is Array and tag in only):
			fits.append(i)
			made_for.append(i)
	if prefer and not made_for.is_empty():
		fits = made_for
	if fits.is_empty():
		return []
	# A shuffled bag per group and situation: every line once before any repeats,
	# and never the same line twice in a row.
	var key := "%s|%s|%s" % [group, tag, prefer]
	var bag: Array = _bags.get(key, [])
	bag = bag.filter(func(i: int) -> bool: return i in fits)
	if bag.is_empty():
		bag = fits.duplicate()
		for k in range(bag.size() - 1, 0, -1):
			var j := _rng.randi() % (k + 1)
			var t = bag[k]
			bag[k] = bag[j]
			bag[j] = t
		if bag.size() > 1 and bag[bag.size() - 1] == _last.get(group, -1):
			bag.reverse()
	var pick: int = bag.pop_back()
	_bags[key] = bag
	_last[group] = pick
	return all[pick]


func notes(l: Array) -> Dictionary:
	return l[2] if l.size() > 2 and l[2] is Dictionary else {}


## Speaks a line of `group` over `anchor` (a Node3D or a Callable giving a world
## position); returns the line, or [] if there was none.
func say(anchor: Variant, speaker: String, group: String, tag := "", seconds := 4.0,
		accent := Color("#ffd23f"), height := 2.6, prefer := false) -> Array:
	var l := line(group, tag, prefer)
	if l.is_empty() or bubbles == null:
		return l
	bubbles.say(anchor, speaker, l[0], l[1], seconds, accent, height)
	return l


# --- drivers' shouts ------------------------------------------------------------------

## The player's car hit an AI car (traffic.bumped_driver).
func on_driver_bumped(d) -> void:
	if d.node == null and not d.ghost and _rng.randf() < 0.7:
		_shout(d)


## An AI car has been held up behind the stopped player (traffic.blocked_by_player).
func on_driver_blocked(d) -> void:
	if _rng.randf() < 0.6:
		_shout(d)


func _shout(d) -> void:
	if _shout_wait > 0.0 or bubbles == null:
		return
	_shout_wait = SHOUT_GAP
	# The bubble follows this car while it lives; a pooled car reused for another
	# one later has a new slot or kind, and the bubble then stays put out of sight.
	var slot: int = d.slot
	var kind: int = d.kind
	var anchor := func() -> Vector3:
		if not d.active or d.slot != slot or d.kind != kind:
			return Vector3.INF
		return d.pos + Vector3(0, d.size.y + 0.4, 0)
	say(anchor, DRIVERS[clampi(kind, 0, DRIVERS.size() - 1)], "traffic", "", 3.0, Color("#e2574c"))


# --- the radio host -------------------------------------------------------------------

func on_station_changed(_index: int, _station: Dictionary) -> void:
	_host_t = 0.0
	if host_first < 0.0:
		_host_next = _rng.randf_range(HOST_GAP.x, HOST_GAP.y)


func _process(dt: float) -> void:
	var t0 := Time.get_ticks_usec()
	_frame(dt)
	spent_usec += Time.get_ticks_usec() - t0


func _frame(dt: float) -> void:
	_shout_wait = maxf(0.0, _shout_wait - dt)
	if radio == null or radio.station < 0 or not host_on:
		return
	_host_t += dt
	if _host_t >= _host_next:
		if host_hold:
			return  # loop 2d-1
		_host_t = 0.0
		host_first = -1.0
		_host_next = _rng.randf_range(HOST_GAP.x, HOST_GAP.y)
		var l := line("radio_host")
		if not l.is_empty():
			radio.announce(l[0], l[1])
