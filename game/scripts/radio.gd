extends Node
## The car radio: three made-up stations, each playing one of the original loops
## from tools/make_music.py (imported as seamless Forward loops, QOA), and Off.
## R or the RADIO button tunes to the next one; a short burst of static covers
## the switch. Every change emits station_changed, and announce() puts any line
## (the radio host's, dialogue.gd) on the HUD's now-playing ticker.

signal station_changed(index: int, station: Dictionary)
## A line for the now-playing ticker: a station change, or a host's line with its
## English subtitle (held longer).
signal ticker(text: String, colour: Color, subtitle: String)

const STATIONS := [
	{"name": "NOCNA FM", "freq": "87,3", "track": "Palma de Gaulle'a",
		"path": "res://audio/radio/palma_de_gaulle.wav", "colour": Color("#ff5fc8")},
	{"name": "RONDO FM", "freq": "86,6", "track": "Rondo Dmowskiego 3 A.M.",
		"path": "res://audio/radio/rondo_3am.wav", "colour": Color("#4ff0ff")},
	{"name": "MORDOR FM", "freq": "108,8", "track": "Mordor Mall Muzak",
		"path": "res://audio/radio/mordor_mall.wav", "colour": Color("#b98cff")},
]
## Moderate: under the (future) engine and city sounds.
const VOLUME_DB := -9.0

## -1 = off, else an index into STATIONS.
var station := -1
## Loop 3g-1: dB under the station's level while a conversation is on (the pull-over: -6).
var duck_db := 0.0:
	set(value):
		duck_db = value
		if _player != null:
			_player.volume_db = VOLUME_DB + duck_db
var _player: AudioStreamPlayer
var _static: AudioStreamPlayer
var _streams: Array[AudioStream] = []
## Headless runs (tests) have no audio device: the dummy driver never mixes, so a
## playing stream would never be released. The radio keeps its state but stays silent.
var _silent := DisplayServer.get_name() == "headless"


func _ready() -> void:
	_player = AudioStreamPlayer.new()
	_player.volume_db = VOLUME_DB
	# The Music bus (sfx.gd setup_buses); the ambience dips while a station plays.
	_player.bus = &"Music"
	add_child(_player)
	_static = AudioStreamPlayer.new()
	_static.volume_db = VOLUME_DB - 4.0
	_static.bus = &"Music"
	if ResourceLoader.exists("res://audio/ui/tune.wav"):
		_static.stream = load("res://audio/ui/tune.wav")
	add_child(_static)
	for s in STATIONS:
		_streams.append(load(s["path"]))


func _exit_tree() -> void:
	# Quitting while a stream plays would leave its playback behind.
	_player.stop()
	_static.stop()


## Tunes to a station (-1 = off). `quiet` skips the static and the ticker.
func tune(index: int, quiet := false) -> void:
	station = index if index >= 0 and index < STATIONS.size() else -1
	if station < 0 or _silent:
		_player.stop()
	else:
		_player.stream = _streams[station]
		# Join the loop somewhere in the middle, like switching a real radio on.
		var length := _player.stream.get_length()
		_player.play(fmod(Time.get_ticks_msec() * 0.001 * 7.3, maxf(length - 1.0, 1.0)))
	if not quiet and _static.stream != null and not _silent:
		_static.play()
	var info: Dictionary = STATIONS[station] if station >= 0 else {}
	station_changed.emit(station, info)
	if not quiet:
		if station >= 0:
			ticker.emit("%s %s  ·  %s" % [info["freq"], info["name"], info["track"]], info["colour"], "")
		else:
			ticker.emit("RADIO OFF", Color("#c9c4d8"), "")


## Puts the current station on the ticker (when the game starts).
func now_playing() -> void:
	if station >= 0:
		var info: Dictionary = STATIONS[station]
		ticker.emit("%s %s  ·  %s" % [info["freq"], info["name"], info["track"]], info["colour"], "")


## The next station, after the last one Off, then the first again.
func next() -> void:
	tune(station + 1 if station + 1 < STATIONS.size() else -1)


## The short name for the HUD button.
func label() -> String:
	return STATIONS[station]["name"] if station >= 0 else "OFF"


## Puts a line on the ticker in the current station's colour, with an optional
## English subtitle: the radio host between the tracks (dialogue.gd).
func announce(text: String, subtitle := "") -> void:
	var info: Dictionary = STATIONS[station] if station >= 0 else {}
	var head := "%s %s:  " % [info["freq"], info["name"]] if station >= 0 else ""
	ticker.emit(head + text, info["colour"] if station >= 0 else Color("#c9c4d8"), subtitle)
