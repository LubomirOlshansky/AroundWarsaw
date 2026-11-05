extends Node
## The opening's sound (F, 2026-11-03): the announcer's line ("Opening_line_a") plays once with the
## opening flyover, over the radio turned right down as a quiet music bed; when the flyover is over
## and the line has finished, the radio swells to its normal level. A tap that skips the flyover
## cuts the line short and brings the radio up at once. Without the file nothing plays and the
## radio is left alone.
##
## Levels: the line at LINE_DB on the SFX bus; the radio BED_DB under its normal level (-20 dB is
## about a tenth of the loudness: heard, not listened to), back to 0 over SWELL_S s.

const CameraShots := preload("res://scripts/camera_shots.gd")
const LINE_FILE := "res://audio/opening/opening_line.ogg"
## The opening theme (ElevenLabs, F picked take B, 2026-11-05): plays under the line on the Music
## bus, and fades out as the radio swells in. A missing file is skipped.
const THEME_FILE := "res://audio/opening/opening_theme.ogg"
const THEME_DB := -8.0
const LINE_DB := 0.0
const BED_DB := -20.0
const DIP_S := 0.6
const SWELL_S := 3.0

var _t0 := 0.0
var _radio: Node
var _voice: AudioStreamPlayer
var _theme: AudioStreamPlayer
var _tween: Tween
var _flight_over := false
var _line_over := true


## Starts the line and the dip. `radio` is the radio.gd node (its `bed_db` is what moves).
func start(radio: Node) -> void:
	_radio = radio
	_t0 = Time.get_ticks_msec() * 0.001
	_flight_over = false
	_line_over = true
	_dip()
	var silent := DisplayServer.get_name() == "headless"
	if not silent and ResourceLoader.exists(THEME_FILE):
		_theme = AudioStreamPlayer.new()
		_theme.stream = load(THEME_FILE)
		_theme.volume_db = THEME_DB
		_theme.bus = &"Music"
		add_child(_theme)
		_theme.play()
	if silent or not ResourceLoader.exists(LINE_FILE):
		_line_over = true
		return
	_voice = AudioStreamPlayer.new()
	_voice.stream = load(LINE_FILE)
	_voice.volume_db = LINE_DB
	_voice.bus = &"SFX"
	add_child(_voice)
	_voice.finished.connect(_on_line_finished, CONNECT_ONE_SHOT)
	_line_over = false
	_voice.play()


## The flyover ended (done or skipped by a tap).
func flight_ended() -> void:
	_flight_over = true
	# A flight that ends well before its length was skipped by a tap (the signal does not say).
	var skipped := (Time.get_ticks_msec() * 0.001 - _t0) < CameraShots.OPEN_TIME - 0.8
	if skipped and _voice != null and _voice.playing:
		var t := create_tween()
		t.tween_property(_voice, "volume_db", -40.0, 0.3)
		t.tween_callback(_voice.stop)
		t.tween_callback(_on_line_finished)
		return
	_maybe_swell()


func _on_line_finished() -> void:
	_line_over = true
	_maybe_swell()


func _dip() -> void:
	if _radio == null:
		return
	_kill_tween()
	_tween = create_tween()
	_tween.tween_property(_radio, "bed_db", BED_DB, DIP_S)


func _maybe_swell() -> void:
	if not (_flight_over and _line_over) or _radio == null:
		return
	_kill_tween()
	_tween = create_tween()
	_tween.set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	_tween.tween_property(_radio, "bed_db", 0.0, SWELL_S)
	if _theme != null and _theme.playing:
		_tween.parallel().tween_property(_theme, "volume_db", -60.0, SWELL_S)
		_tween.tween_callback(_theme.stop)


func _kill_tween() -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
