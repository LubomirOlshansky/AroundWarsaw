extends Node3D
## The game's sound (v0.9), all from tools/make_sfx.py (original synthesis, no samples):
## the car's engine (three loops at 850, 2400 and 4500 rpm, crossfaded and pitched by a
## five-speed gearbox, with a short dip at every upshift), the tyres (rolling on dry
## asphalt, hissing on a wet road, squealing in a slide or under hard braking), the
## helicopter's rotor, collisions (thumps, a crash, a guard rail's clang), the słoiki
## run's jars, the city's day and night beds, rain, and positional one-shots: trams'
## bells, the AI cars' horns, the pigeons. Birds now and then by day; a far siren or a
## dog, rarely, at night.
##
## Buses (setup_buses, before the radio is made): Master, Music (the radio), SFX and
## Ambience; the ambience dips while the radio plays, so the radio keeps priority.
## Positional sounds go through a pool of AudioStreamPlayer3D (a hard cap on voices)
## heard by a listener that follows the camera's focus a few metres up, with a short
## reach so the map isn't a wall of noise. Per frame this only sets a few volumes and
## pitches. Headless runs (tests) have no audio device and play nothing.

const DIR := "res://audio/sfx/"
## The rpm each engine loop was recorded at (tools/make_sfx.py prints them).
const ENGINE_RPM := [850.0, 2397.0, 4500.0]
## Gearbox: the speed (m/s) where each gear tops out; first gear starts at rest.
const GEAR_TOP := [0.0, 6.5, 12.5, 19.0, 25.5, 40.0]
const RPM_IDLE := 850.0
const RPM_SHIFTED := 1900.0
const RPM_TOP := 4600.0
## Bus levels (dB). The radio player sits at -9 dB on Music (radio.gd).
const BUSES := {"Music": 0.0, "SFX": -3.0, "Ambience": -9.0}
const AMBIENCE_DUCK := -4.0
## Loops: name, bus, level (dB) at full.
const LOOPS := {
	"engine_idle": ["SFX", -10.0], "engine_mid": ["SFX", -10.0], "engine_high": ["SFX", -10.0],
	"tyre_roll": ["SFX", -14.0], "tyre_wet": ["SFX", -11.5], "tyre_squeal": ["SFX", -15.0],
	"rotor": ["SFX", -3.0],
	"city_day": ["Ambience", -7.0], "city_night": ["Ambience", -14.0], "rain": ["Ambience", -7.0],
}
## One-shots: level (dB).
const SHOTS := {
	"thump_soft": -8.0, "thump_hard": -6.0, "crash": -4.0, "clang": -9.0, "jar_clink": -12.0, "jar_break": -6.0,
	"tram_bell": -8.0, "horn": -16.0, "horn_double": -16.0, "pigeons": -6.0,
	"birds_a": -13.0, "birds_b": -15.0, "siren_far": -20.0, "dog_far": -10.0,
}
const VOICES_3D := 6
const VOICES_2D := 4
## Positional sounds: full level within UNIT metres of the listener, gone past REACH.
const UNIT := 14.0
const REACH := 85.0
const LISTENER_UP := 12.0

var car: CharacterBody3D
var heli: Node3D
var tod: Node
var weather: Node
var radio: Node
var flying := false
## The camera's focus and yaw (degrees), set by the game each frame.
var focus := Vector3.ZERO
var yaw := 45.0
## How long the last update took, for --bench.
var last_usec := 0

var _silent := DisplayServer.get_name() == "headless"
var _streams := {}
var _loops := {}
var _level := {}
var _quiet := {}
var _pool2: Array[AudioStreamPlayer] = []
var _pool3: Array[AudioStreamPlayer3D] = []
var _next2 := 0
var _listener: AudioListener3D
var _gear := 1
var _rpm := RPM_IDLE
var _dip := 0.0
var _last_v := 0.0
var _load := 0.0
var _rotor := 0.0
var _hit_wait := 0.0
var _horn_wait := 0.0
var _jar_wait := 0.0
var _event_wait := 12.0
var _t := 0.0
var _duck := 0.0
var _rng := RandomNumberGenerator.new()
## Guard rails on a 4 m grid (data["guards"]): a hit there clangs.
var _rails := {}


## Loop 2a: the player's volumes (Settings → Sound) as dB on top of the bus levels.
static var user_db := {"Master": 0.0, "Music": 0.0, "SFX": 0.0, "Ambience": 0.0}


## Master, Music, SFX and Ambience; safe to call more than once.
static func setup_buses() -> void:
	for bus in BUSES:
		var i := AudioServer.get_bus_index(bus)
		if i < 0:
			AudioServer.add_bus()
			i = AudioServer.bus_count - 1
			AudioServer.set_bus_name(i, bus)
			AudioServer.set_bus_send(i, &"Master")
		AudioServer.set_bus_volume_db(i, BUSES[bus] + user_db[bus])


## Loop 2a: the player's volumes, 0..1 each: everything, the radio, the effects (engine,
## tyres, knocks, the city's beds). Zero mutes the bus.
static func set_levels(master: float, music: float, effects: float) -> void:
	var levels := {"Master": master, "Music": music, "SFX": effects, "Ambience": effects}
	for bus in levels:
		var v: float = levels[bus]
		user_db[bus] = linear_to_db(maxf(v, 0.001))
		var i := AudioServer.get_bus_index(bus)
		if i < 0:
			continue
		AudioServer.set_bus_mute(i, v <= 0.001)
		AudioServer.set_bus_volume_db(i, BUSES.get(bus, 0.0) + user_db[bus])


func setup(data: Dictionary) -> void:
	_rng.seed = 909
	for g in data.get("guards", []):
		var p: Array = g["p"]
		for k in range(0, p.size() - 3, 2):
			var a := Vector2(p[k], p[k + 1])
			var b := Vector2(p[k + 2], p[k + 3])
			var steps := maxi(1, ceili(a.distance_to(b) / 2.0))
			for s in steps + 1:
				var q := a.lerp(b, float(s) / steps)
				_rails[Vector2i(floori(q.x / 4.0), floori(q.y / 4.0))] = true
	# By name, not by listing the folder: an exported game holds only the imports.
	for n in LOOPS.keys() + SHOTS.keys():
		_streams[n] = load(DIR + n + ".wav")
	for n in LOOPS:
		var p := AudioStreamPlayer.new()
		p.stream = _streams.get(n)
		p.bus = LOOPS[n][0]
		p.volume_db = -80.0
		add_child(p)
		_loops[n] = p
		_level[n] = 0.0
		_quiet[n] = 0.0
	for k in VOICES_2D:
		var p := AudioStreamPlayer.new()
		p.bus = &"SFX"
		add_child(p)
		_pool2.append(p)
	for k in VOICES_3D:
		var p := AudioStreamPlayer3D.new()
		p.bus = &"SFX"
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p.unit_size = UNIT
		p.max_distance = REACH
		p.panning_strength = 0.7
		p.doppler_tracking = AudioStreamPlayer3D.DOPPLER_TRACKING_DISABLED
		add_child(p)
		_pool3.append(p)
	_listener = AudioListener3D.new()
	add_child(_listener)
	_listener.make_current()


func _exit_tree() -> void:
	for p in _loops.values():
		p.stop()
	for p in _pool2:
		p.stop()
	for p in _pool3:
		p.stop()


func _process(dt: float) -> void:
	if dt <= 0.0 or car == null:
		return
	var t0 := Time.get_ticks_usec()
	_t += dt
	_hit_wait -= dt
	_horn_wait -= dt
	_jar_wait -= dt
	_listener.global_transform = Transform3D(Basis(Vector3.UP, deg_to_rad(yaw)), focus + Vector3.UP * LISTENER_UP)
	var wet: float = weather.wet if weather != null else 0.0
	var raining: float = weather.amount if weather != null else 0.0
	_engine(dt, wet)
	# The rotor winds up with the blades and down again after landing.
	var spin: float = heli.rotor_speed() if flying else 0.0
	_rotor = move_toward(_rotor, spin, dt / (1.0 if flying else 2.5))
	var climb := clampf(float(heli.vy) / 8.0, -1.0, 1.0) if flying else 0.0
	var fast := clampf(heli.speed() / 35.0, 0.0, 1.0) if flying else 0.0
	_drive("rotor", _rotor, 0.55 + 0.45 * _rotor + 0.05 * fast + 0.04 * climb, dt, 4.0)
	# Ambience: day and night beds by the light, rain on top; dips under the radio.
	var daylight: float = tod.daylight if tod != null else 1.0
	_drive("city_day", daylight * (1.0 - 0.5 * raining), 1.0, dt, 1.5)
	_drive("city_night", (1.0 - daylight) * (1.0 - 0.4 * raining), 1.0, dt, 1.5)
	_drive("rain", raining, 1.0, dt, 1.5)
	var duck := AMBIENCE_DUCK if radio != null and radio.station >= 0 else 0.0
	_duck = move_toward(_duck, duck, dt * 6.0)
	if not _silent:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(&"Ambience"), BUSES["Ambience"] + _duck + user_db["Ambience"])
	_events(dt, daylight, raining)
	last_usec = Time.get_ticks_usec() - t0


## Engine and tyres. The rpm comes from the speed through a five-speed box (a launch
## slips the clutch up to ~2400 rpm); load from the throttle or, for the autopilot,
## how hard the car is speeding up.
func _engine(dt: float, wet: float) -> void:
	var on := not flying
	var v := absf(car.forward_speed)
	var accel := (v - _last_v) / dt
	_last_v = v
	_load = lerpf(_load, clampf(maxf(car.throttle, accel / 3.0), 0.0, 1.0), 1.0 - exp(-6.0 * dt))
	if _gear < 5 and v > GEAR_TOP[_gear] + 0.3:
		_gear += 1
		_dip = 0.22
	elif _gear > 1 and v < GEAR_TOP[_gear - 1] - 1.5:
		_gear -= 1
	var lo: float = GEAR_TOP[_gear - 1]
	var hi: float = GEAR_TOP[_gear]
	var target := lerpf(RPM_IDLE if _gear == 1 else RPM_SHIFTED, RPM_TOP, clampf((v - lo) / (hi - lo), 0.0, 1.0))
	if _gear == 1 and v < 4.0:
		target = maxf(target, RPM_IDLE + 1550.0 * _load)
	if v < 0.6 and _load < 0.05:
		target = RPM_IDLE + 35.0 * sin(_t * 4.3) + 20.0 * sin(_t * 1.7)  # a tired idle hunts a little
	_dip -= dt
	_rpm = lerpf(_rpm, target, 1.0 - exp(-(16.0 if _dip > 0.0 else 7.0) * dt))
	var w_idle := clampf((1500.0 - _rpm) / 650.0, 0.0, 1.0)
	var w_high := clampf((_rpm - 3100.0) / 1100.0, 0.0, 1.0)
	var w_mid := clampf(1.0 - w_idle - w_high, 0.0, 1.0)
	var level := (0.5 + 0.5 * _load) * (0.45 if _dip > 0.0 else 1.0) * float(on)
	var names := ["engine_idle", "engine_mid", "engine_high"]
	var weights := [w_idle, w_mid, w_high]
	for k in 3:
		_drive(names[k], level * sqrt(weights[k]), clampf(_rpm / ENGINE_RPM[k], 0.5, 2.2), dt, 14.0)
	var fast := clampf(v / 28.0, 0.0, 1.0)
	_drive("tyre_roll", pow(fast, 0.8) * (1.0 - 0.6 * wet) * float(on), 0.75 + 0.5 * fast, dt, 6.0)
	_drive("tyre_wet", pow(fast, 0.9) * wet * float(on), 0.85 + 0.35 * fast, dt, 6.0)
	var slide := clampf((car.slip - 2.5) / 5.0, 0.0, 1.0)
	if car.brakes_on and car.forward_speed > 9.0:
		slide = maxf(slide, 0.55 * clampf((v - 9.0) / 10.0, 0.0, 1.0))
	slide *= (1.0 - 0.6 * wet) * float(on)
	_drive("tyre_squeal", slide, 0.92 + 0.15 * slide + 0.05 * fast, dt, 12.0)


## Eases a loop towards `level` (0..1, `rate` per second) and pitch; starts it when it
## is needed and stops it after half a second of silence.
func _drive(n: String, level: float, pitch: float, dt: float, rate: float) -> void:
	var cur: float = _level[n]
	cur = lerpf(cur, level, 1.0 - exp(-rate * dt))
	_level[n] = cur
	var p: AudioStreamPlayer = _loops[n]
	if _silent or p.stream == null:
		return
	if cur > 0.003:
		p.volume_db = LOOPS[n][1] + linear_to_db(cur)
		p.pitch_scale = pitch
		_quiet[n] = 0.0
		if not p.playing:
			p.play(_rng.randf() * p.stream.get_length() * 0.9)
	elif p.playing:
		p.volume_db = -80.0
		_quiet[n] += dt
		if _quiet[n] > 0.5:
			p.stop()


## Birds now and then by day (not in the rain); at night, rarely, a far siren or a dog.
func _events(dt: float, daylight: float, raining: float) -> void:
	_event_wait -= dt
	if _event_wait > 0.0:
		return
	if daylight > 0.55 and raining < 0.3:
		_play2("birds_a" if _rng.randf() < 0.6 else "birds_b", _rng.randf_range(-4.0, 0.0), &"Ambience")
		_event_wait = _rng.randf_range(7.0, 16.0)
	elif daylight < 0.3:
		_play2("siren_far" if _rng.randf() < 0.45 else "dog_far", _rng.randf_range(-3.0, 0.0), &"Ambience")
		_event_wait = _rng.randf_range(45.0, 110.0)
	else:
		_event_wait = 10.0


## The player's car hit something at `speed` m/s (car.gd, where the haptics are).
func impact(collider: Object, speed: float) -> void:
	if _hit_wait > 0.0:
		return
	_hit_wait = 0.3
	var gain := linear_to_db(clampf(speed / 12.0, 0.35, 1.0))
	if not collider is AnimatableBody3D and _near_rail(car.global_position):
		_play2("clang", gain)
		if speed > 6.0:
			_play2("thump_soft", gain - 4.0)
		return
	if speed < 5.0:
		_play2("thump_soft", gain)
	elif speed < 10.5:
		_play2("thump_hard", gain)
	else:
		_play2("crash", gain)


func _near_rail(p: Vector3) -> bool:
	var c := Vector2i(floori(p.x / 4.0), floori(p.z / 4.0))
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			if _rails.has(c + Vector2i(dx, dz)):
				return true
	return false


## The słoiki run: 0 = the jars clink (a bump, a warning), 1 = one broke.
func jars(kind: int) -> void:
	if _jar_wait > 0.0 and kind == 0:
		return
	_jar_wait = 0.45
	_play2("jar_break" if kind == 1 else "jar_clink", _rng.randf_range(-3.0, 0.0))


## A tram rings as it leaves a stop or at a car on its track.
func tram_bell(at: Vector3) -> void:
	_play3("tram_bell", at, 0.0)


## An AI car held up by (or hit by) the player sounds its horn, sometimes.
func horn(at: Vector3) -> void:
	if _horn_wait > 0.0 or _rng.randf() > 0.7:
		return
	_horn_wait = 2.5
	_play3("horn_double" if _rng.randf() < 0.5 else "horn", at, _rng.randf_range(-3.0, 0.0))


func pigeons(at: Vector3) -> void:
	_play3("pigeons", at, 0.0)


func _play2(n: String, gain_db: float, bus := &"SFX") -> void:
	if _silent or not _streams.has(n):
		return
	var p := _pool2[_next2]
	_next2 = (_next2 + 1) % _pool2.size()
	p.stream = _streams[n]
	p.bus = bus
	p.volume_db = SHOTS.get(n, -10.0) + gain_db
	p.play()


## A positional one-shot: skipped out of reach; a free voice, or the farthest busy
## one if the new sound is nearer (the cap on voices).
func _play3(n: String, at: Vector3, gain_db: float) -> void:
	if _silent or not _streams.has(n):
		return
	var ear := focus + Vector3.UP * LISTENER_UP
	var d := at.distance_to(ear)
	if d > REACH * 0.95:
		return
	var pick: AudioStreamPlayer3D = null
	var far := d
	for p in _pool3:
		if not p.playing:
			pick = p
			break
		var dp := p.global_position.distance_to(ear)
		if dp > far:
			far = dp
			pick = p
	if pick == null:
		return
	pick.stop()
	pick.stream = _streams[n]
	pick.global_position = at
	pick.volume_db = SHOTS.get(n, -10.0) + gain_db
	pick.play()


## The loudest peak (dBFS) of each bus in the last mix, for the meters (--bench,
## --sound-check). Needs an audio device: headless runs read -200.
static func bus_peaks() -> Dictionary:
	var out := {}
	for bus in ["Master", "Music", "SFX", "Ambience"]:
		var i := AudioServer.get_bus_index(bus)
		out[bus] = maxf(AudioServer.get_bus_peak_volume_left_db(i, 0), AudioServer.get_bus_peak_volume_right_db(i, 0))
	return out


## --sound-check: plays every one-shot in turn (the positional ones 15 m from the
## listener's spot, as a horn across the street) and prints the loudest peak per bus
## while it sounds, over whatever the beds and the radio are doing. Then quits.
func sound_check() -> void:
	var tree := get_tree()
	await tree.create_timer(2.0).timeout
	print("sound check: the beds alone, then each one-shot; peaks in dBFS (radio on Music, beds on Ambience)")
	await _meter("(beds and engine idling)", 2.0)
	for n in SHOTS:
		var at := focus + Vector3(15.0, 0.0, 0.0)
		if n in ["tram_bell", "horn", "horn_double", "pigeons"]:
			_play3(n, at, 0.0)
		elif n in ["birds_a", "birds_b", "siren_far", "dog_far"]:
			_play2(n, 0.0, &"Ambience")
		else:
			_play2(n, 0.0)
		await _meter(n, minf(_streams[n].get_length() + 0.2, 3.0))
	tree.quit()


func _meter(label: String, seconds: float) -> void:
	var top := {"Master": -200.0, "Music": -200.0, "SFX": -200.0, "Ambience": -200.0}
	var t := 0.0
	while t < seconds:
		await get_tree().process_frame
		t += get_process_delta_time()
		var p := bus_peaks()
		for bus in top:
			top[bus] = maxf(top[bus], p[bus])
	print("  %-26s Master %6.1f  Music %6.1f  SFX %6.1f  Ambience %6.1f" % [label, top["Master"], top["Music"], top["SFX"], top["Ambience"]])


## Voices playing now (loops and one-shots), for the perf overlay.
func voices() -> int:
	var n := 0
	for p in _loops.values():
		n += int(p.playing)
	for p in _pool2:
		n += int(p.playing)
	for p in _pool3:
		n += int(p.playing)
	return n
