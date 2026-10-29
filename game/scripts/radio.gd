extends Node
## The car radio: made-up stations, each with a playlist, and Off. The stations and their
## tracks come from data/radio.json (tools/add_music.py puts songs there: README, "Adding
## music"); a station with several tracks plays them in a shuffled order, each to its end,
## and one with a single track loops it. R or the RADIO button tunes to the next station;
## a short burst of static covers the switch. Every change emits station_changed, every
## new track track_changed, and announce() puts any line (the radio host's, dialogue.gd)
## on the HUD's now-playing ticker.
##
## Loop radio-playlists: the stations moved from a const with one WAV loop each to
## radio.json with Ogg Vorbis tracks (streamed: the compressed file is decoded as it plays,
## never as a whole in memory) and playlists shuffled by the date.

signal station_changed(index: int, station: Dictionary)
## A line for the now-playing ticker: a station change, a new track, or a host's line with
## its English subtitle (held longer).
signal ticker(text: String, colour: Color, subtitle: String)
## A track has started on the tuned station. `natural` is true when the last one ran out on
## its own (not a tune or a skip): dialogue.gd's host may speak between the two.
signal track_changed(info: Dictionary, track: Dictionary, natural: bool)

const PATH := "res://data/radio.json"
## The built-in stations, used when radio.json is missing or unreadable: names, frequencies
## and colours only (the music lives in radio.json, so these have no tracks and play only the
## tuning static). main.gd's --radio= clamps to this list's size.
const STATIONS := [
	{"id": "nocna_fm", "name": "NOCNA FM", "freq": "87,3", "colour": Color("#ff5fc8")},
	{"id": "rondo_fm", "name": "RONDO FM", "freq": "86,6", "colour": Color("#4ff0ff")},
	{"id": "mordor_fm", "name": "MORDOR FM", "freq": "108,8", "colour": Color("#b98cff")},
]
## Moderate: under the (future) engine and city sounds.
const VOLUME_DB := -9.0

## -1 = off, else an index into `stations`.
var station := -1
## The stations as read from radio.json: {id, name, freq, colour: Color, tracks: [{file,
## title, artist, seconds, gain_db, licence, source}]}.
var stations: Array[Dictionary] = []
## Loop 3g-1: dB under the station's level while a conversation is on (the pull-over: -6).
var duck_db := 0.0:
	set(value):
		duck_db = value
		if _player != null:
			_player.volume_db = VOLUME_DB + duck_db
var _player: AudioStreamPlayer
var _static: AudioStreamPlayer
## Per station: its tracks' indices in the order they play today (a shuffle seeded by the
## date and the station, so a day has its own order and every run of it is the same).
var _orders: Array = []
## Per station: where it is in its order. Tuning back to a station starts that track again.
var _pos: Array[int] = []
## Loaded track streams by file (the resource cache keeps them; this skips the lookup).
var _streams := {}
## Headless runs (tests) have no audio device: the dummy driver never mixes, so a
## playing stream would never be released. The radio keeps its state but stays silent.
var _silent := DisplayServer.get_name() == "headless"


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.volume_db = VOLUME_DB
	# The Music bus (sfx.gd setup_buses); the ambience dips while a station plays.
	_player.bus = &"Music"
	add_child(_player)
	_player.finished.connect(_on_finished)
	_static = AudioStreamPlayer.new()
	_static.volume_db = VOLUME_DB - 4.0
	_static.bus = &"Music"
	if ResourceLoader.exists("res://audio/ui/tune.wav"):
		_static.stream = load("res://audio/ui/tune.wav")
	add_child(_static)
	_load_stations()


func _exit_tree() -> void:
	# Quitting while a stream plays would leave its playback behind.
	_player.stop()
	_player.stream = null
	_static.stop()


# --- the stations ---------------------------------------------------------------------

## Reads data/radio.json into `stations` (the built-in list when it is missing or has no
## stations) and shuffles each station's order.
func _load_stations() -> void:
	stations = []
	var data: Variant = null
	if FileAccess.file_exists(PATH):
		data = JSON.parse_string(FileAccess.get_file_as_string(PATH))
	if data is Dictionary and data.get("stations") is Array:
		for s: Variant in data["stations"]:
			if s is Dictionary and s.has("name") and s.has("freq"):
				stations.append(_station_from(s))
	if stations.is_empty():
		for s: Dictionary in STATIONS:
			var d := s.duplicate(true)
			d["tracks"] = []
			stations.append(d)
	_orders = []
	_pos = []
	for i in stations.size():
		_orders.append(_shuffled(stations[i]["tracks"].size(), i))
		_pos.append(0)


func _station_from(s: Dictionary) -> Dictionary:
	var tracks: Array = []
	for t: Variant in s.get("tracks", []):
		if not (t is Dictionary) or not t.has("file"):
			continue
		if not ResourceLoader.exists(String(t["file"])):
			push_warning("radio: %s's track file %s is missing" % [s["name"], t["file"]])
			continue
		tracks.append({
			"file": String(t["file"]), "title": String(t.get("title", "")),
			"artist": String(t.get("artist", "")), "seconds": float(t.get("seconds", 0.0)),
			"gain_db": float(t.get("gain_db", 0.0)), "licence": String(t.get("licence", "unknown")),
			"source": String(t.get("source", "")),
		})
	return {"id": String(s.get("id", "")), "name": String(s["name"]), "freq": String(s["freq"]),
			"colour": Color(String(s.get("colour", "#c9c4d8"))), "tracks": tracks}


## A Fisher-Yates shuffle of 0..n-1, seeded by today's date and the station's number.
func _shuffled(n: int, station_index: int) -> Array[int]:
	var order: Array[int] = []
	for i in n:
		order.append(i)
	var rng := RandomNumberGenerator.new()
	var day := Time.get_date_dict_from_system()
	rng.seed = (int(day["year"]) * 10000 + int(day["month"]) * 100 + int(day["day"])) * 31 + station_index * 7919
	for i in range(n - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := order[i]
		order[i] = order[j]
		order[j] = swap
	return order


## The tuned station's order of tracks (indices into its tracks), empty when Off.
func playlist() -> Array[int]:
	var out: Array[int] = []
	if station >= 0:
		out.assign(_orders[station])
	return out


## The track on the air now ({} when Off or the station has none).
func current_track() -> Dictionary:
	if station < 0:
		return {}
	var order: Array = _orders[station]
	if order.is_empty():
		return {}
	return stations[station]["tracks"][order[_pos[station]]]


# --- tuning and playing ---------------------------------------------------------------

## Tunes to a station (-1 = off). `quiet` skips the static and the ticker.
func tune(index: int, quiet := false) -> void:
	station = index if index >= 0 and index < stations.size() else -1
	_play_current(true)
	if not quiet and _static.stream != null and not _silent:
		_static.play()
	var info: Dictionary = stations[station] if station >= 0 else {}
	station_changed.emit(station, info)
	if not quiet:
		if station >= 0:
			ticker.emit(caption(), info["colour"], "")
		else:
			ticker.emit("RADIO OFF", Color("#c9c4d8"), "")
	if station >= 0 and not current_track().is_empty():
		track_changed.emit(info, current_track(), false)


## Starts the current track of the tuned station (or stops the player when Off). A single
## track is a loop and joins in the middle, like switching a real radio on; a playlist
## track starts at its beginning and plays to its end.
func _play_current(join_middle: bool) -> void:
	var track := current_track()
	if station < 0 or track.is_empty():
		_player.stop()
		_player.stream = null
		return
	var stream := _stream_of(track)
	var single: bool = _orders[station].size() == 1
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = single
	_player.stream = stream
	if _silent or stream == null:
		return
	var from := 0.0
	if single and join_middle:
		from = fmod(Time.get_ticks_msec() * 0.001 * 7.3, maxf(stream.get_length() - 1.0, 1.0))
	_player.play(from)


func _stream_of(track: Dictionary) -> AudioStream:
	var file: String = track["file"]
	if not _streams.has(file):
		_streams[file] = load(file)
	return _streams[file]


## The track ran out (never emitted for a looping single track): the next one starts.
func _on_finished() -> void:
	if station >= 0:
		_advance(true)


## Skips to the next track of the tuned station (a single track starts over). A natural end
## is `natural`; the caption goes up and track_changed fires for the host.
func next_track() -> void:
	if station >= 0:
		_advance(false)


func _advance(natural: bool) -> void:
	var order: Array = _orders[station]
	if order.is_empty():
		return
	_pos[station] = (_pos[station] + 1) % order.size()
	_play_current(false)
	var info: Dictionary = stations[station]
	ticker.emit(caption(), info["colour"], "")
	track_changed.emit(info, current_track(), natural)


## "87,3 NOCNA FM  ·  Title (Artist)": the tuned station and the track on the air.
func caption() -> String:
	if station < 0:
		return ""
	var info: Dictionary = stations[station]
	var text := "%s %s" % [info["freq"], info["name"]]
	var track := current_track()
	if track.is_empty():
		return text
	text += "  ·  " + String(track["title"])
	if String(track["artist"]) != "":
		text += " (%s)" % track["artist"]
	return text


## Puts the current station on the ticker (when the game starts).
func now_playing() -> void:
	if station >= 0:
		ticker.emit(caption(), stations[station]["colour"], "")


## The next station, after the last one Off, then the first again.
func next() -> void:
	tune(station + 1 if station + 1 < stations.size() else -1)


## The short name for the HUD button.
func label() -> String:
	return stations[station]["name"] if station >= 0 else "OFF"


## Puts a line on the ticker in the current station's colour, with an optional
## English subtitle: the radio host between the tracks (dialogue.gd).
func announce(text: String, subtitle := "") -> void:
	var info: Dictionary = stations[station] if station >= 0 else {}
	var head := "%s %s:  " % [info["freq"], info["name"]] if station >= 0 else ""
	ticker.emit(head + text, info["colour"] if station >= 0 else Color("#c9c4d8"), subtitle)
