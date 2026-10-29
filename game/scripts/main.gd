extends Node
## Sets up the pixel-art view, the daytime world, the city, the car and the
## helicopter, the isometric follow camera, the controls and the rescue missions.
##
## Command-line options (after `--`): --demo drives the car (or circles the
## helicopter) by itself, --shots=60,240 saves screenshots at those frames and
## quits, --out=DIR sets where they go, --style=N picks a style, --yaw=N rotates
## the camera, --heli starts in the helicopter, --mission=N starts rescue call N
## at once, --autopilot flies or drives to the mission targets (for testing; the
## car ghosts through buildings) or drives the race route, --no-traffic leaves the
## city empty, --race=N races rival N at once, --rival=N puts rival N just ahead,
## --bench drives through the traffic and prints the average frame time,
## --time=day|dusk|night sets the time of day, --vhs turns the tape overlay on,
## --radio=0..3 picks the station (0 = off), --notitle skips the title screen and
## --title shows it even with the testing flags. Side jobs and easter eggs (v0.65):
## --kebab=N starts kebab order N, --sloik[=K] the słoiki run (K jars already
## broken), --heat=X the kebab's starting heat, --host-in=S the radio host's first
## line after S seconds, --barriers=YYYYMMDD the day the roadworks are placed for,
## --reset-save wipes the wallet, --nosave neither reads nor writes it, --free
## starts in free roam (no rescue call card). v0.8: --tap=X,Y taps that screen pixel
## at frame 60 (a landmark's info card). v0.9: --weather=clear|rain, --time=live with
## --clock=HH:MM and --date=YYYYMMDD (Warsaw time), --perf shows the performance
## overlay, --quality=low|medium|high. Loop 1: --ghost-debug=1|2 paints or fully cuts the
## occlusion ghost (and prints its ellipse with each screenshot), --lift=M aims the camera
## M metres above the vehicle. Loop 2a: --controls=point|classic|fixed, --traffic=empty|low|
## normal|busy (or 0-3), --settings opens the settings panel, --stick=X,Y holds the stick at
## that deflection and --pedal=gas|brake a pedal (screenshots, replays in the real city),
## --clicks=X:Y:F,... clicks and --drag=X:Y:F:DX:DY:F2 drags a finger through the real input path.
## Loop 10a: --drive-into-water=X,Z starts the car there and drives it flat out into the nearest
## water as if it had jumped the edge (the splash and the tow, printed as `water:` lines).
## Loop 2e: --call-in=S brings the first rescue call after S seconds of play, --settings-tab=N
## opens the settings panel at tab N.
## Camera loop: --cam-log prints the camera every 0.25 s (`cam:` lines), --cam-test=classic_turn|
## point_release|brake drives one camera moment in the real city (frame strips).
## Loop G1: --quality=auto|low|medium|high|ultra (Auto: the level for this device, tiers.gd),
## --model=ID picks as if on that device (iPhone12,1), --governor=on|off, --stress=cpu:N|wait:N
## with --stress-from=S --stress-to=S (load that makes the governor step down and back up).
## Loop G1b: --last-session=struggled|calm starts Auto as if the last session at the sharp image
## struggled (the ×2 fallback) or was calm (the sharp image), and writes nothing of it.

const MapBuilder := preload("res://scripts/map_builder.gd")
const Car := preload("res://scripts/car.gd")
const TunnelXray := preload("res://scripts/tunnel_xray.gd")
const PedZones := preload("res://scripts/ped_zones.gd")
const Heli := preload("res://scripts/heli.gd")
const Hud := preload("res://scripts/hud.gd")
const Missions := preload("res://scripts/missions.gd")
const Skids := preload("res://scripts/skids.gd")
const LaneGraph := preload("res://scripts/lane_graph.gd")
const Traffic := preload("res://scripts/traffic.gd")
const Trams := preload("res://scripts/trams.gd")
const Pedestrians := preload("res://scripts/pedestrians.gd")
const Rivals := preload("res://scripts/rivals.gd")
const Bubbles := preload("res://scripts/bubbles.gd")
const Models := preload("res://scripts/models.gd")
const TimeOfDay := preload("res://scripts/time_of_day.gd")
const Radio := preload("res://scripts/radio.gd")
const Title := preload("res://scripts/title.gd")
const Wallet := preload("res://scripts/wallet.gd")
const Dialogue := preload("res://scripts/dialogue.gd")
const Jobs := preload("res://scripts/jobs.gd")
## Loop 2d-1: Podwózka, the app-taxi side job.
const Rides := preload("res://scripts/rides.gd")
const Eggs := preload("res://scripts/eggs.gd")
const Sfx := preload("res://scripts/sfx.gd")
const Weather := preload("res://scripts/weather.gd")
const Controls := preload("res://scripts/drive_controls.gd")
const FollowCamera := preload("res://scripts/follow_camera.gd")
const CameraShots := preload("res://scripts/camera_shots.gd")
const Settings := preload("res://scripts/settings.gd")
const BenchStats := preload("res://scripts/bench.gd")
const ScreenPoints := preload("res://scripts/screen_points.gd")
const Splash := preload("res://scripts/splash.gd")
const Tiers := preload("res://scripts/tiers.gd")
const Governor := preload("res://scripts/governor.gd")
## Loop 3g-1: the police (police.gd; its block below, "loop 3g-1: the police").
const Police := preload("res://scripts/police.gd")
const MAP_PATH := "res://map/centrum.json"

## Visual styles to compare on the phone. lines = vertical resolution of the pixel image.
const STYLES := [
	{"name": "Sharp", "lines": 480, "outline": 0.5, "levels": 0.0, "saturation": 1.15},
	{"name": "Fine", "lines": 360, "outline": 0.55, "levels": 0.0, "saturation": 1.12},
	{"name": "Clean", "lines": 240, "outline": 0.6, "levels": 0.0, "saturation": 1.1},
	{"name": "Chunky", "lines": 170, "outline": 0.8, "levels": 9.0, "saturation": 1.2},
]
var camera_pitch := -30.0
const CAMERA_DISTANCE := 500.0
## Height of the view in metres (orthographic size): wide enough to read the city.
var base_size := FollowCamera.DEFAULT_SIZE
## The helicopter's view is this much wider than the car's (as before loop 2a: 1.3 × 110 m).
const HELI_VIEW := 1.3 * 110.0 / FollowCamera.DEFAULT_SIZE
const MIN_SIZE := 30.0
const MAX_SIZE := 320.0

var view: SubViewportContainer
var sv: SubViewport
var cam: Camera3D
var car: CharacterBody3D
## Loop 3d-1: the pedestrian zones (ped_zones.gd), where the car is capped at 20 km/h.
var ped_zones: RefCounted
var _zone := ""
## Loop 3b: the car seen through the ground inside a tunnel (tunnel_xray.gd).
var _xray: Node3D
var heli: Node3D
var missions: Node
var hud: CanvasLayer
## The living city (absent with --no-traffic): lane graph, traffic, trams,
## pedestrians, rivals and their speech bubbles.
var graph: LaneGraph
var traffic: Traffic
var trams: Trams
var walkers: Pedestrians
var rivals: Rivals
## Loop 3g-1: the police (null with --no-police or no traffic) and their flags.
var police: Police
var police_opts := {}
var bubbles: Bubbles
var no_traffic := false
var start_race := 0
var start_rival := 0
## --bench: drive a ghost route through the traffic, then print frame times.
var bench := false
var _bench_ghost = null
## Loop 2b: the bench's numbers (bench.gd), frames to settle and to measure (--bench-frames=),
## --probe (stand still where --at puts the car and measure the view there), --exp=a,b
## (switch single costs off to rank them), and main.gd's own share of the frame.
var _stats: BenchStats
var _bench_settle := 300
var _bench_frames := 600
var probe := false
var _exp: PackedStringArray = []
var _main_usec := 0
## Loop 2b: the measured part of a bench or probe ends after this many seconds even if the
## frames aren't done (a slow phone), and settling after SETTLE_SECONDS; --fps=N caps the frame
## rate for this run (0: uncapped; else the setting's 60 or 30).
var _bench_seconds := 30.0
const SETTLE_SECONDS := 8.0
var _bench_t0 := 0
var _measure_t0 := 0
var _flag_fps := -1
## The frame-rate cap in force (0: none).
var _cap := 60
## The result is out (on iOS the app doesn't stop at once after quit()).
var _bench_done := false
## Loop 2b: the BENCH button's run (the overlay or Settings): about a minute on the bench route
## at the current settings, then the result card. What it changes is put back afterwards.
const PHONE_SETTLE := 5.0
const PHONE_SECONDS := 55.0
var _phone_bench := false
var _phone_seconds := PHONE_SECONDS
## --bench-button: press BENCH at frame 60 (testing aid; the same run as the button's).
var bench_button := false
var _phone_saved := {}
var _phone_next_toast := 0
var _spawn := Transform3D.IDENTITY
## The overlay's text is rebuilt twice a second.
const PERF_EVERY := 0.5
## In the helicopter; the car waits, parked, where it was left.
var flying := false
var start_flying := false
var start_mission := 0
var autopilot := false
var _wash_on := false
var building_mat: ShaderMaterial
var post_mat: ShaderMaterial
var map: Node3D

var style_index := 0
var cam_yaw := 45.0
var cam_yaw_target := 45.0
## --yaw= was given (the follow camera then doesn't start behind the vehicle).
var _flag_yaw := false
## Camera loop: the follow camera's laws (follow_camera.gd: the turn, the look-ahead, the dead
## zone, the speed zoom), its view height (cam.size is the host's during a cinematic moment), and
## the cinematic moments on Phantom Camera (camera_shots.gd): the fly-in when the title screen
## goes and a look at a new rescue or delivery target, on in a normal launch, off in test runs
## (show_title false: --notitle and every testing flag), forced on by --cinematic[=flyin|look].
var fcam := FollowCamera.new()
var _view_size := FollowCamera.DEFAULT_SIZE
var moments: CameraShots
var cinematic_flyin := false
var cinematic_look := false
var _flag_cinematic := ""
var _last_target_source := ""
var _last_target := Vector3.INF
## Follow: the camera turns to stay behind the car. Fixed: it turns only with the rotate buttons.
var follow := true
var cam_focus := Vector3.ZERO
var demo := false
var shots: Array[int] = []
var out_dir := "user://"
var frame := 0
var start_at := Vector3.INF
## --heading=deg: the car's heading at the start (0 = north, 90 = east), for testing.
var start_heading := INF
var lines_override := 0
var hide_hud := false
## Desktop: --no-touch (trailer loop, 2026-10-29): the HUD without its touch-only controls (the
## pedals, the stick, the helicopter's pads) and the title without its "tap to drive" prompt,
## for recording on the computer (hud.gd `set_touch_off`, title.gd `touch_off`).
var no_touch := false
var sun_pitch := -50.0
var debug_ao := false
## Loop 3a: --debug-roads draws the decks, approaches, tunnels, lane heights and piers round
## the car (debug_roads.gd, with the Debug Draw add-on).
var debug_roads := false
## Loop 3b: --tunnel starts the car (with --at) on the floor of a tunnel under that point.
var start_in_tunnel := false
## Loop 1: --ghost-debug=N paints the occlusion ghost for measuring (1: the ghosted
## fragments magenta and every other building green; 2: the ghost cut fully, no dither)
## and prints the ghost's ellipse in screen pixels with every screenshot.
var ghost_debug := 0
## --lift=M: aim the camera M metres above the vehicle (close-ups of tall landmarks).
var cam_lift := 0.0
## The ghosted footprint's sunlight: given back in full above GHOST_SUN_HIGH degrees of
## sun, none below GHOST_SUN_LOW; GHOST_SUN_SCALE matches it to the renderer's sun
## (measured: with 1.8 a ghosted footprint behind the Palace read 154.7 against 159.3 for
## the same pixels with no shadows at all, 93.9 with nothing given back).
const GHOST_SUN_LOW := 15.0
const GHOST_SUN_HIGH := 40.0
const GHOST_SUN_SCALE := 1.9
var _ghost_px := Vector4.ZERO
var no_ao := false
## Load the prebuilt sectors like the exported game does (loop 3c: map/sectors/*.scn, index.res,
## proxies.scn; only rebuilt by tools/bake_city.gd), not build them from their files.
var prebuilt := false
var _started := false
## Time of day (N / TIME / --time=), the radio (R / RADIO / --radio=), the VHS
## overlay (V / VHS / --vhs) and the title screen (skipped by the testing flags).
var tod: TimeOfDay
var radio: Radio
var title: Title
var start_time := 0
var start_station := 0
var vhs := false
var _vhs_mat: ShaderMaterial
var show_title := true
var force_title := false
var env: Environment
var sun: DirectionalLight3D
var _blip: AudioStreamPlayer
## v0.65: the wallet (and save), everybody's lines, the side jobs, the easter eggs.
var wallet: Wallet
var dialogue: Dialogue
var jobs: Jobs
var eggs: Eggs
var start_kebab := -1
var start_sloik := -1
var start_heat := -1.0
# --- loop 2d-1: Podwózka (rides.gd) and its testing flags ---
var rides: Rides
## --ride=N: ride N's request, the car by its passenger; --ride-quirk=, --passenger=, --stars=X
## (the live rating's start), --ignore-app (the autopilot drives the shortest road, not the
## app's), --parody-log (`ride:` and `gps:` lines).
var start_ride := -1
var ride_quirk := ""
var ride_passenger := ""
var ride_stars := -1.0
var ignore_app := false
var parody_log := false
## --gps-in=S: the first GPS moment of the app-taxis in traffic from S seconds in (screenshots).
var gps_in := -1.0
# --- end loop 2d-1 ---
var host_in := -1.0
var barrier_day := 0
var reset_save := false
var no_save := false
## --free: free roam (loop 2e: no call card at the start anyway; the first call then comes in
## 90 s into play instead of 60).
var free_roam := false
## Loop 2e: the first rescue call comes in after this many seconds of play (--call-in=S;
## missions.gd FIRST_CALL by default); --style= and --vhs win over the saved settings.
var call_in := -1.0
## Loop 2e: --settings-tab=N opens the settings panel at that tab (0 Driving, 1 World, 2 Picture,
## 3 Sound) for screenshots.
var settings_tab := 0
var _flag_style := -1
var _flag_vhs := false
## --tap=X,Y: tap that screen pixel at frame 60, as if a finger did (landmark cards).
var tap_at := Vector2.INF
## v0.9: sound, weather (RAIN / O / --weather=), the Live clock (--clock= --date=), the
## performance overlay (--perf, P, a three-finger tap) and the quality (--quality=, U,
## the QUALITY button on the overlay).
var sfx: Sfx
var weather: Weather
var start_weather := 0
var live_clock := ""
var live_date := 0
var show_perf := false
## Low, Medium, High, Ultra (loop G1: tiers.gd QUALITY): the pixel size (loop 2b: "step" whole
## screen pixels coarser than High's; the old 0.85 / 0.7 render scales gave Medium High's image
## on a 1170-line phone and Low's on a 1320-line one; G1: and a budget in megapixels), shadows,
## glow, rain, reflection steps, traffic and pedestrians. Loop 2b: the sun's shadow map is 2048
## on High and 1024 on Medium (4096 / 2048 before): the shadow now covers only the view (see
## _camera_far), so 2048 gives finer texels than 4096 did (0.37 m against 0.49). Medium casts
## sun shadows from buildings and trees only (lamps, signals, parked cars, columns and shelters,
## map_builder.gd SMALL_CASTERS, don't), Low none.
const QUALITY := Tiers.QUALITY
## The level in force (Tiers.LOW..ULTRA); loop G1: the player's choice (Tiers.AUTO, the default,
## or a level), the level Auto picks for this device and the model id it read (--model= for tests).
var quality := Tiers.HIGH
var quality_choice := Tiers.AUTO
var auto_quality := Tiers.HIGH
var model_name := ""
var _flag_model := ""
# --- Loop G1b: Auto's sharp image and its fallback (tiers.gd SHARP_*, governor.gd tally) ---
## The back-off state as this launch started it (Tiers.sharp_launch of the saved one), whether
## this launch draws the sharp image where the budget binds, what this session has recorded
## ("", "calm", "struggled": once each, struggled last), whether it may write it (not with
## --last-session=, and settings.gd writes nothing with --nosave), and the quality line last
## printed (the `quality:` line comes again only when it changes).
var auto_image := Tiers.sharp_state()
var auto_sharp := true
var _image_verdict := ""
var _image_write := true
var _flag_last_session := ""
var _quality_line := ""
# --- end loop G1b ---
## Loop G1: the frame governor (governor.gd) and the fixed view rule: in a view wider than
## WIDE_VIEW metres (back under 0.9 of it) or flying, the small things' sun shadows are off
## (lamps, signals, parked cars, columns, shelters: a pixel or two wide there, and a shadow-pass
## draw call per kind and 512 m tile). The governor runs in a normal launch; test runs (headless,
## --shots, --bench, --probe, --autopilot, --demo, the camera and water tests) and the BENCH
## button's minute hold it; --governor=on|off overrides.
const WIDE_VIEW := 150.0
var governor := Governor.new()
var _flag_governor := -1
var _governor_on := true
## --governor=log: on, and a `governor status:` line every GOVERNOR_LOG_EVERY seconds.
const GOVERNOR_LOG_EVERY := 5.0
var _governor_log := false
var _governor_log_next := 0.0
var _wide := false
## What _apply_extras last set (-1: nothing yet).
var _small_cast := -1
## Loop G1 testing aid (--stress=cpu:N|wait:N, --stress-from=S, --stress-to=S): N × 0.5 ms of busy
## work a frame from S to S2 seconds after the city is up: in _process (`cpu`: the CPU's extras go
## first) or in the draw phase (`wait`: what waiting for the GPU looks like to the main thread,
## so the GPU's extras go first).
var _stress_kind := ""
var _stress_n := 0
var _stress_from := 0.0
var _stress_to := INF
var _stress_t0 := 0
## Loop 2a: the driving controls (drive_controls.gd), the saved settings (settings.gd), the
## traffic level, and the command-line values that win over the saved ones (-1: none).
var controls := Controls.new()
var settings := Settings.new()
var traffic_level := Settings.NORMAL_TRAFFIC
## -2: no --quality= (Tiers.AUTO is -1).
var _flag_quality := -2
var _flag_controls := -1
var _flag_traffic := -1
var _flag_fixed := false
var _flag_perf := false
var open_settings_at_start := false
var hold_stick := Vector2.INF
var hold_pedal := ""
## Testing aid (--clicks=X:Y:F,...): a mouse click (a touch, with the project's touch
## emulation) at screen pixel X,Y on frame F, released two frames later.
var clicks: Array[Vector3i] = []
## Testing aid (--drag=X:Y:F:DX:DY:F2): a finger down at X,Y on frame F, moved by DX,DY over
## ten frames, held, and lifted on frame F2 (the stick through the real touch path).
var drags: Array[PackedInt32Array] = []
## The helicopter's stick or keys are held (the follow camera waits, like Point).
var _heli_held := false
var _heli_release := 99.0
var _perf_wait := 0.0
var _clock_minute := -1
## --sound-check: play every sound once and print the bus meters (sfx.gd).
var sound_check := false
var _meters := {"Master": 0.0, "Music": 0.0, "SFX": 0.0, "Ambience": 0.0}
var _meter_top := {"Master": -200.0, "Music": -200.0, "SFX": -200.0, "Ambience": -200.0}
## Loop 10a: the river is off-limits. The car that still gets into the water (a glitch, a gap
## nobody found) splashes, settles, and after TOW_DELAY s the tow puts it back on the nearest
## lane on dry land, with a line from dialogue.json's water_tow; no money taken, whatever was
## running (a rescue, a delivery, a race) carries on.
const TOW_DELAY := 1.0
var splash: Splash
## Seconds left until the tow (< 0: no tow waiting); when the car went in (the clock, s).
var _tow_wait := -1.0
var _splash_at := 0.0
var _clock := 0.0
## Where the car last was on dry land or a deck (the tow goes back to that level), INF: never.
var _last_dry := Vector3.INF
var _last_dry_yaw := 0.0
## --drive-into-water=X,Z (testing aid): 0 off, 1 driving at the water with its collision off
## (as if it had jumped the edge), 2 collision back on past the edge, 3 splashed, 4 towed.
var water_test := 0
var _water_test_at := Vector2.INF
## Loop 2c, --lineup (testing aid): every vehicle model standing round the car, no traffic, for
## close-up screenshots (with --size=25 or so).
var lineup := false
## The river's outlines (water bodies of 20,000 m² or more, as tools/bake_water.py counts it):
## which tow lines fit.
var _rivers: Array[PackedVector2Array] = []
## Camera loop testing aids. --cam-log prints the camera's state every CAM_LOG_EVERY frames
## (`cam:` lines: scheme, finger, speed, the car's and the camera's compass headings, the
## camera's turn rate (the fastest since the last line), the car's place on screen, the view).
## --cam-test=NAME drives one camera moment in the real city with scripted inputs through the
## scheme's own mapping (drive_controls.gd), the car ghosting through walls, no traffic, after
## CAM_TEST_SETTLE s parked with the camera behind it (it implies --cam-log; frame strips are
## --shots= every 15 frames): `classic_turn` (Classic with the camera following: up to 50 km/h,
## a 90° right turn held near 50, then straight on), `point_release` (Point: up to 50 km/h,
## the stick held 90° right for 2.5 s, then let go), `brake` (Classic following: flat out to
## 90 km/h, then braking to a stop).
const CAM_LOG_EVERY := 15
const CAM_TEST_SETTLE := 1.0
var cam_log := false
var cam_test := ""
var _cam_t := 0.0
var _cam_phase := 0
var _cam_phase_t := 0.0
var _cam_aim := 0.0
var _cam_last_yaw := INF
var _cam_turn_max := 0.0


func _ready() -> void:
	_parse_args()
	_parse_stream_args()  # loop 3c (the sectors block at the end of this file)
	_load_settings()
	# The audio buses first: the radio plays on Music from the title screen on.
	Sfx.setup_buses()
	Sfx.set_levels(settings.master, settings.music, settings.effects)
	# The title screen (or, for test runs, a plain loading card) covers the second
	# or two the city takes to build; the radio already plays.
	var loading: CanvasLayer = null
	if show_title:
		title = Title.new()
		title.touch_off = no_touch  # desktop: --no-touch
		add_child(title)
	else:
		loading = _loading_card()
	radio = Radio.new()
	# Loop 2a: the radio keeps playing under the settings panel (the game is paused).
	radio.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(radio)
	radio.tune(start_station - 1, true)
	wallet = Wallet.new()
	wallet.persistent = not no_save
	add_child(wallet)
	if reset_save:
		wallet.reset()
	print("save: %s (%s)" % [wallet.summary(), ProjectSettings.globalize_path(Wallet.PATH) if not no_save else "not saved"])
	await get_tree().process_frame
	await get_tree().process_frame
	var t0 := Time.get_ticks_msec()
	var no_map := _missing_map()
	if no_map != "":
		# Loop 3d-1: the split and the prebuilt sectors are not committed; a fresh clone makes
		# them once with tools/setup_map.sh. Say so plainly instead of failing deep in the builder.
		push_error(no_map)
		get_tree().quit(1)
		return
	_build_world()
	print("city built in %d ms, %s" % [Time.get_ticks_msec() - t0, _scene_stats()])
	if loading != null:
		loading.queue_free()
	if title != null:
		hud.visible = false
		dialogue.host_on = false
		title.dismissed.connect(_on_title_dismissed)
		title.set_ready()
	else:
		radio.now_playing()
	_started = true


func _exit_tree() -> void:
	if _stats != null:
		_stats.unhook()
	if RenderingServer.frame_pre_draw.is_connected(_stress_wait):
		RenderingServer.frame_pre_draw.disconnect(_stress_wait)


func _on_title_dismissed() -> void:
	hud.visible = not hide_hud
	dialogue.host_on = true
	title = null
	radio.now_playing()
	if cinematic_flyin:
		_fly_in()


## Camera loop: the fly-in from over the city down to the car (camera_shots.gd).
func _fly_in() -> void:
	var vehicle: Node3D = heli if flying else car
	var ahead := -vehicle.global_transform.basis.z
	moments.fly_in(vehicle.global_position, ahead, cam_yaw, camera_pitch, _view_size)


## Camera loop: the car was put somewhere else (a tow): the view goes there at once, and a
## following camera turns behind it at once (not while Point's finger is down: the held direction
## would turn with it).
func _cut_camera() -> void:
	cam_focus = car.global_position
	fcam.reset_lead()
	if follow and not controls.held:
		cam_yaw = rad_to_deg(car.rotation.y)
		cam_yaw_target = cam_yaw
		fcam.stop_turning()


## Camera loop: any touch, click or key skips a cinematic moment.
func _input(event: InputEvent) -> void:
	if moments == null or not moments.playing():
		return
	var go := false
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		go = event.is_pressed()
	elif event is InputEventKey:
		go = event.is_pressed() and not event.is_echo()
	if go:
		moments.skip()


func _scene_stats() -> String:
	var vertices := 0
	var instances := 0
	for c in _city_nodes():  # loop 3c: the map's own nodes and the loaded sectors'
		if c is MeshInstance3D and c.mesh.get_surface_count() > 0:
			vertices += c.mesh.surface_get_array_len(0)
		elif c is MultiMeshInstance3D:
			instances += c.multimesh.instance_count
			var m: Mesh = c.multimesh.mesh
			var per := 0
			for surface in m.get_surface_count():
				per += (m.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
			vertices += c.multimesh.instance_count * per
	return "%d vertices, %d instances" % [vertices, instances]


func _loading_card() -> CanvasLayer:
	var layer := CanvasLayer.new()
	layer.layer = 10
	var bg := ColorRect.new()
	bg.color = Color("#a8cde6")
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	layer.add_child(bg)
	var label := Label.new()
	label.text = "NOCNA WARSZAWA\nbudujemy miasto…\nbuilding the city…"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Loop 2e: in points like the HUD (screen_points.gd), Polish above English.
	var pt: float = ScreenPoints.measure(get_viewport().get_visible_rect().size)["pt"]
	label.add_theme_font_size_override("font_size", roundi(20.0 * pt))
	label.add_theme_color_override("font_color", Color("#fbf7ee"))
	label.add_theme_color_override("font_outline_color", Color("#2a2622"))
	label.add_theme_constant_override("outline_size", roundi(4.0 * pt))
	layer.add_child(label)
	add_child(layer)
	return layer


func _build_world() -> void:
	view = SubViewportContainer.new()
	view.stretch = true
	view.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	view.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(view)
	sv = SubViewport.new()
	sv.msaa_3d = Viewport.MSAA_DISABLED
	sv.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
	sv.physics_object_picking = false
	# The sound's listener (sfx.gd) lives in this viewport's 3D world.
	sv.audio_listener_enable_3d = true
	view.add_child(sv)

	var world := Node3D.new()
	sv.add_child(world)
	_add_environment(world)

	building_mat = ShaderMaterial.new()
	building_mat.shader = load("res://shaders/building.gdshader")
	var flat_mat := ShaderMaterial.new()
	flat_mat.shader = load("res://shaders/ground.gdshader")
	flat_mat.set_shader_parameter("debug_ao", debug_ao)
	flat_mat.set_shader_parameter("ao_strength", 0.0 if no_ao else 1.0)

	var data: Dictionary
	# Loop 3c: the city in 512 m sectors, streamed round the camera (sector_streamer.gd): the
	# exported game (and --prebuilt) loads the sectors tools/bake_city.gd built on the Mac, the
	# editor builds them from their files. --monolithic builds the whole city at once from
	# centrum.json, as before loop 3c (the pixel diff's reference; city.scn is gone).
	if not monolithic:
		data = _open_streamed_city(world, flat_mat)
		flat_mat = map.flat_material
	else:
		map = MapBuilder.new()
		world.add_child(map)
		data = map.build(MAP_PATH, building_mat, flat_mat)

	for a in data["areas"]:
		if a["k"] == "water":
			var ring := PackedVector2Array()
			var flat: Array = a["p"]
			for k in range(0, flat.size() - 1, 2):
				ring.append(Vector2(flat[k], flat[k + 1]))
			if absf(MapBuilder._ring_area(ring)) >= 20000.0:
				_rivers.append(ring)
	ped_zones = PedZones.new(data.get("ped_zones", []))
	car = Car.new()
	car.ground_height = map.drive_height
	world.add_child(car)
	_xray = TunnelXray.new()
	world.add_child(_xray)
	_xray.setup(car)
	car.stuck.connect(_on_car_stuck)
	car.water_at = map.in_water
	car.kerb_feel = map.kerb_feel  # loop 3b-2: kerbs, islands and medians the car feels
	car.splashed.connect(_on_car_splashed)
	var spawn: Dictionary = data["spawn"]
	car.global_position = Vector3(spawn["x"], 0.0, spawn["z"])
	car.rotation.y = spawn["yaw"]
	_spawn = Transform3D(Basis(Vector3.UP, spawn["yaw"]), Vector3(spawn["x"], map.ground_height(spawn["x"], spawn["z"]), spawn["z"]))
	if start_at != Vector3.INF:
		car.global_position = start_at
		car.global_position.y = map.ground_height(start_at.x, start_at.z)
		if start_in_tunnel and not is_nan(map.tunnel_floor_under(start_at.x, start_at.z)):
			car.global_position.y = map.tunnel_floor_under(start_at.x, start_at.z)
	if start_heading != INF:
		car.rotation.y = -deg_to_rad(start_heading)
	cam_focus = car.global_position

	var skids := Skids.new()
	skids.car = car
	skids.ground_height = func(x: float, z: float) -> float: return map.drive_height(x, z, car.global_position.y)
	skids.material_override = flat_mat
	world.add_child(skids)
	splash = Splash.new()
	world.add_child(splash)

	heli = Heli.new()
	heli.ground_height = map.ground_height
	heli.top_height = map.top_height
	var b: Array = data["bounds"]
	heli.bounds = Rect2(b[0], b[1], b[2] - b[0], b[3] - b[1])
	world.add_child(heli)
	heli.landed.connect(_on_heli_landed)

	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = base_size
	cam.near = 1.0
	cam.far = 1400.0
	cam.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	world.add_child(cam)
	_add_post_pass()
	# After the post pass's quad (the camera's first child, --exp=nopost hides it).
	_view_size = base_size
	moments = CameraShots.new()
	add_child(moments)
	moments.setup(cam, world)

	if map.water_texture != null:
		post_mat.set_shader_parameter("surface_map", map.water_texture)
		post_mat.set_shader_parameter("surface_rect", map.water_rect)
	tod = TimeOfDay.new()
	add_child(tod)
	if live_clock != "":
		tod.clock_start = TimeOfDay.warsaw_to_utc(live_clock, live_date)
	tod.setup(env, sun, post_mat, sun_pitch)
	tod.lights_switched.connect(_show_night_nodes)
	_share_lights()
	weather = Weather.new()
	weather.tod = tod
	weather.post = post_mat
	add_child(weather)

	hud = Hud.new()
	# Loop 2a: the HUD (and the settings panel in it) works while the game is paused.
	hud.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(hud)
	hud.set_scheme(controls.scheme)
	hud.set_touch_off(no_touch)  # desktop: --no-touch
	hud.settings_pressed.connect(_open_settings)
	hud.settings_panel.changed.connect(_on_setting)
	hud.settings_panel.closed.connect(_close_settings)
	# Loop 2e: TIME, VHS, RAIN, STYLE, CAM, QUALITY and the rotate and zoom buttons left the
	# driving screen (Settings has them; the keys stay; zoom is a pinch, a twist turns a fixed
	# camera).
	hud.radio_pressed.connect(radio.next)
	hud.perf_gesture.connect(func(): _set_perf(not show_perf); settings.perf = show_perf; settings.save())
	radio.station_changed.connect(func(_i: int, _s: Dictionary): hud.set_radio_name(radio.label()))
	radio.ticker.connect(hud.ticker)
	hud.set_radio_name(radio.label())
	hud.visible = not hide_hud
	hud.rotate_pressed.connect(func(d: int):
		if not follow:
			_rotate_camera(d))
	hud.pinched.connect(func(ratio: float): _zoom(1.0 / ratio))
	hud.setup_minimap(data)
	hud.vehicle_pressed.connect(_toggle_vehicle)
	hud.tapped.connect(_on_tap)
	_set_flying(false)

	missions = Missions.new()
	add_child(missions)
	missions.setup(map, data, world, hud)
	missions.player = car.global_position
	# Speech bubbles (anyone can talk) and everybody's lines.
	bubbles = Bubbles.new()
	bubbles.pt = hud.pt
	bubbles.project = func(p: Vector3) -> Vector2: return cam.unproject_position(p) * float(view.stretch_shrink)
	hud.add_child(bubbles)
	hud.move_child(bubbles, 1)
	bubbles.process_mode = Node.PROCESS_MODE_PAUSABLE
	dialogue = Dialogue.new()
	dialogue.host_first = host_in
	dialogue.bubbles = bubbles
	dialogue.radio = radio
	add_child(dialogue)
	radio.station_changed.connect(dialogue.on_station_changed)
	missions.wallet = wallet
	missions.dialogue = dialogue
	missions.vehicle_anchor = func() -> Vector3: return _vehicle_position() + Vector3(0, 4.0 if flying else 2.2, 0)
	hud.set_wallet(wallet.zl, wallet.respect)
	wallet.changed.connect(hud.set_wallet)
	if data.has("graph"):
		graph = LaneGraph.new(data["graph"], map)
	if debug_roads:
		var dr: Node3D = load("res://scripts/debug_roads.gd").new()
		world.add_child(dr)
		dr.setup(map, graph, _vehicle_position, data)
	if not no_traffic and graph != null:
		_build_life(data, world)
	if graph != null:
		_build_side_jobs(data, world)
	if lineup:
		_build_lineup(world)
	if start_flying:
		_take_off(Heli.CRUISE)
	# Loop 2e: no call card at the start (docs/DEMO.md 6.1): calls come in during play.
	if start_mission > 0:
		missions.start(start_mission)
	elif demo or start_race > 0 or start_rival > 0 or bench or start_kebab >= 0 or start_sloik >= 0 or free_roam:
		missions.close()
	else:
		missions.quiet_start(call_in)
	if jobs != null and start_kebab >= 0:
		jobs.start_kebab(start_kebab)
		cam_focus = car.global_position
	elif jobs != null and start_sloik >= 0:
		jobs.start_sloik(start_sloik)
		cam_focus = car.global_position
	elif rides != null and start_ride >= 0:
		rides.start_ride(start_ride)  # loop 2d-1
		cam_focus = car.global_position
	if rivals != null and (start_race > 0 or start_rival > 0):
		var i := (maxi(start_race, start_rival) - 1) % Rivals.RIVALS.size()
		rivals.put_ahead(i)
		cam_focus = car.global_position
		if start_race > 0:
			rivals.start_race(i)
		elif autopilot:
			rivals.tail = i

	if _water_test_at != Vector2.INF:
		_start_water_test()
	if cam_test != "":
		_start_cam_test()
	_build_sound(data, world)
	# Loop 3g-1: the police, on the traffic's lane graph (none with --no-police).
	if traffic != null and not police_opts.get("off", false):
		_build_police(data, world)
	_set_quality(quality_choice)
	get_tree().root.size_changed.connect(_apply_style)
	_apply_style()
	_show_night_nodes(false)
	tod.set_mode(start_time, true)
	weather.set_state(start_weather, true)
	_set_vhs(vhs)
	_set_perf(show_perf)
	_blip = AudioStreamPlayer.new()
	_blip.process_mode = Node.PROCESS_MODE_ALWAYS
	_blip.bus = &"SFX"
	_blip.volume_db = -11.0
	if ResourceLoader.exists("res://audio/ui/blip.wav"):
		_blip.stream = load("res://audio/ui/blip.wav")
	add_child(_blip)
	# Camera loop: a following camera starts behind the vehicle (it used to start on the 45°
	# diagonal and, in Classic, swung ~155° round at up to 182°/s as soon as the car moved).
	# Screenshots, the bench and the probe keep the 45° start: their views are the reference
	# pictures (tools/shots.sh) and the performance budgets' (--cinematic screenshots start as a
	# normal launch does).
	if follow and not _flag_yaw and (shots.is_empty() or _flag_cinematic != "") and not bench and not probe:
		var start_yaw := rad_to_deg((heli if flying else car).rotation.y)
		cam_yaw = start_yaw
		cam_yaw_target = start_yaw
	fcam.reset_lead()
	_update_camera(1.0)
	if cinematic_flyin and title == null and cam_test == "":
		_fly_in()
	# Loop 2a: the frame count and screenshots go on while the game is paused (settings).
	get_tree().process_frame.connect(_paused_frame)
	if hold_stick != Vector2.INF:
		var screen := get_viewport().get_visible_rect().size
		hud.hold_stick(Vector2(screen.x * 0.17, screen.y * 0.7), hold_stick)
	if hold_pedal != "":
		hud.hold_pedal(hold_pedal)
	if open_settings_at_start:
		hud.settings_panel.set_tab(settings_tab)
		_open_settings.call_deferred()
	_stats = _make_stats()
	# Loop 3g-1: the police's script time among the bench's lines.
	if police != null:
		_stats.systems["police"] = [police, "spent_usec", true]
	_stats.hook(get_tree())
	# Loop G1, --stress=wait:N: after bench.gd's own frame_pre_draw, so it counts as "draw".
	_stress_t0 = Time.get_ticks_msec()
	if _stress_kind == "wait":
		RenderingServer.frame_pre_draw.connect(_stress_wait)
	_apply_experiments()
	_apply_fps()
	_bench_t0 = Time.get_ticks_msec()
	if bench or probe:
		# The macOS driver may keep vsync on anyway (the frame rate then tops out at
		# the display's refresh), so the bench also prints what the scripts cost and
		# the GPU and render-thread time of the 3D view.
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
		Engine.max_fps = 0
		RenderingServer.viewport_set_measure_render_time(sv.get_viewport_rid(), true)
		if probe:
			_bench_settle = 240


## Traffic, trams, pedestrians and the rivals, all on the lane graph baked into
## the map data; the speech bubbles live in the HUD.
func _build_life(data: Dictionary, world: Node3D) -> void:
	var t0 := Time.get_ticks_msec()
	traffic = Traffic.new()
	world.add_child(traffic)
	traffic.setup(graph, map, cam, data)
	traffic.player_pos = car.global_position
	car.bumped.connect(traffic.on_player_bump)
	trams = Trams.new()
	world.add_child(trams)
	trams.setup(graph, map, data)
	trams.traffic = traffic
	traffic.trams = trams
	walkers = Pedestrians.new()
	world.add_child(walkers)
	walkers.setup(map, cam, traffic, data)
	traffic.bumped_driver.connect(dialogue.on_driver_bumped)
	traffic.blocked_by_player.connect(dialogue.on_driver_blocked)
	rivals = Rivals.new()
	add_child(rivals)
	rivals.autopilot = autopilot
	rivals.wallet = wallet
	rivals.setup(graph, traffic, hud, bubbles, missions, map, world, car, data)
	print("living city: %d lanes, %d trams in %d ms" % [graph.lane_count, trams.trams.size(), Time.get_ticks_msec() - t0])
	if bench:
		var p := Vector2(car.global_position.x, car.global_position.z)
		var hit := graph.snap(p, 60.0, Vector2(-sin(car.rotation.y), -cos(car.rotation.y)), true)
		if not hit.is_empty():
			_bench_ghost = traffic.add_ghost(hit[0], hit[1], hit[2])


## v0.9: the sound (sfx.gd), fed by the car's knocks, the trams' bells, the drivers'
## horns, the pigeons and the jars.
func _build_sound(data: Dictionary, world: Node3D) -> void:
	sfx = Sfx.new()
	sfx.car = car
	sfx.heli = heli
	sfx.tod = tod
	sfx.weather = weather
	sfx.radio = radio
	world.add_child(sfx)
	sfx.setup(data)
	car.impact.connect(sfx.impact)
	if trams != null:
		trams.bell.connect(sfx.tram_bell)
	if traffic != null:
		traffic.blocked_by_player.connect(func(d): sfx.horn(d.pos))
		traffic.bumped_driver.connect(func(d): sfx.horn(d.pos))
	if eggs != null:
		eggs.flushed.connect(sfx.pigeons)
	if jobs != null:
		jobs.jars.connect(sfx.jars)
	if sound_check:
		missions.close()
		sfx.sound_check()


## Quality (U, Settings, --quality=): loop G1: Auto (Tiers.AUTO: the level Auto picked for this
## device) or Low, Medium, High, Ultra. The governor starts again from the top.
func _set_quality(choice: int) -> void:
	quality_choice = clampi(choice, Tiers.AUTO, Tiers.ULTRA)
	quality = auto_quality if quality_choice == Tiers.AUTO else quality_choice
	if settings.quality != quality_choice and _started:
		settings.quality = quality_choice
		settings.save()
	var qs: Dictionary = QUALITY[quality]
	tod.shadows_allowed = qs["shadows"]
	tod.glow_allowed = qs["glow"]
	RenderingServer.directional_shadow_atlas_set_size(qs["shadow_size"], true)
	tod.refresh()
	weather.density = qs["rain"]
	weather.refresh()
	governor.restart(_clock_s())
	_apply_extras()
	if hud != null:
		_apply_style()


## Loop G1: the quality's extras as they are now: the level's own, less what the governor took
## (governor.gd: GPU, mirror-reflection steps and then the small things' sun shadows; CPU,
## traffic and pedestrians), and in a wide view or flying no small things' shadows (the fixed
## view rule, WIDE_VIEW). Never the pixel size, the shadow map, glow, landmarks, the ghost, the
## river or the night lights.
func _apply_extras() -> void:
	var qs: Dictionary = QUALITY[quality]
	post_mat.set_shader_parameter("reflect_steps", ceili(int(qs["reflect"]) * float(Governor.REFLECT[governor.gpu])))
	var cast: bool = qs["small_shadows"] and Governor.SMALL_SHADOWS[governor.gpu] and not _wide
	if int(cast) != _small_cast:
		_small_cast = int(cast)
		get_tree().call_group(MapBuilder.SMALL_CASTERS, "set_cast_shadows_setting",
				GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF)
	_apply_traffic()


## Loop 2a: traffic = the level (Settings → Traffic) × the quality's share; the
## pedestrians follow the level more gently (settings.gd PEOPLE). Loop G1: × what the governor's
## CPU level keeps.
func _apply_traffic() -> void:
	if traffic != null:
		var density := float(Settings.TRAFFIC[traffic_level]) * float(QUALITY[quality]["traffic"]) * float(Governor.TRAFFIC[governor.cpu])
		if not is_equal_approx(traffic.density, density):
			traffic.density = density
	if walkers != null:
		walkers.limit = maxi(4, roundi(float(QUALITY[quality]["people"]) * float(Settings.PEOPLE[traffic_level]) * float(Governor.PEOPLE[governor.cpu])))


## Loop G1: the governor's clock, seconds since the game started.
func _clock_s() -> float:
	return Time.get_ticks_msec() / 1000.0


## Loop G1: once a frame (in the game loop's own time): the fixed view rule and the governor (fed
## the last frame's time and CPU work from bench.gd), held where it should be.
func _govern() -> void:
	var wide := flying or cam.size > (WIDE_VIEW * 0.9 if _wide else WIDE_VIEW)
	if wide != _wide:
		_wide = wide
		print("governor: view %s (%.0f m%s) · small things' sun shadows %s" % ["wide" if wide else "back in",
				cam.size, ", flying" if flying else "", "off" if wide else "as the quality sets them"])
		_apply_extras()
	governor.held = not _governor_on or title != null or _phone_bench or ((bench or probe) and _flag_governor != 1)
	governor.frame(_stats.last_ms, _stats.last_cpu)
	var now := _clock_s()
	var line := governor.tick(now, _wide)
	if line != "":
		print("%s · at %.1f s" % [line, now - _stress_t0 / 1000.0])
		_apply_extras()
	# Loop G1b: the session's verdict on Auto's image (cheap until one is due); with
	# --governor=log the tally's minutes too.
	if governor.track and _image_verdict != "struggled" and (governor.struggled()
			or (_image_verdict == "" and governor.calm())):
		_image_session_verdict()
	if governor.minute_line != "":
		if _governor_log:
			print("governor %s · at %.1f s" % [governor.minute_line, now - _stress_t0 / 1000.0])
		governor.minute_line = ""
	if _governor_log and now >= _governor_log_next:
		_governor_log_next = now + GOVERNOR_LOG_EVERY
		print("governor status: %s · %.1f%% of refreshes missed in the last %.0f s · at %.1f s%s%s%s" % [governor.state(),
				governor.late_share * 100.0, Governor.WINDOW, now - _stress_t0 / 1000.0, " · held" if governor.held else "",
				" · stress on" if _stressing() else "", " · " + governor.tally() if governor.track else ""])


# --- Loop G1b: Auto's sharp image and its fallback ---------------------------------------------
## "sharp" or "fallback" where Auto's rule decides the image (Auto, the level's budget binds at
## this screen and style, no --lines=), else "".
func _image_mode() -> String:
	if quality_choice != Tiers.AUTO or lines_override > 0:
		return ""
	var screen := get_viewport().get_visible_rect().size
	if not Tiers.budget_binds(screen, STYLES[style_index]["lines"], quality):
		return ""
	return "sharp" if auto_sharp else "fallback"


## The session struggled or was calm at Auto's image: the state the next launch starts from
## (computed from this launch's own, so a struggle after a calm verdict replaces it), written
## when this run may (a normal launch without --nosave or --last-session=), and a `quality:` line.
func _image_session_verdict() -> void:
	var sharp := auto_sharp
	var next: Dictionary
	var what := ""
	if governor.struggled():
		_image_verdict = "struggled"
		what = "struggled (%s)" % governor.struggle()
		next = Tiers.sharp_struggled(auto_image, sharp, governor.struggle())
	else:
		_image_verdict = "calm"
		what = "was calm"
		next = Tiers.sharp_calm(auto_image, sharp)
	var saved := _image_write and settings.persistent
	if saved:
		settings.auto_image = next
		settings.save()
	print("quality: this session at %s ×%d %s %s · %s · the next launch: %s%s" % [QUALITY[quality]["name"],
			view.stretch_shrink, "sharp" if sharp else "fallback", what, governor.tally(),
			"sharp" if not Tiers.sharp_launch(next)["fallback"] else "fallback (calm %d of %d before the sharp image again)" % [
			next["calm"], next["wait"]], "" if saved else " (not saved: %s)" % ("--nosave" if not settings.persistent else "a test run or --last-session=")])
# --- end loop G1b --------------------------------------------------------------------------------


## Loop G1, --stress: inside the load's time window (seconds after the city is up).
func _stressing() -> bool:
	var t := (Time.get_ticks_msec() - _stress_t0) / 1000.0
	return _stress_n > 0 and t >= _stress_from and t < _stress_to


func _busy(n: int) -> void:
	var end := Time.get_ticks_usec() + n * 500
	while Time.get_ticks_usec() < end:
		pass


func _stress_wait() -> void:
	if _stressing():
		_busy(_stress_n)


## The performance overlay (P, a three-finger tap, --perf): GPU time needs the
## viewport's render-time measurement on.
func _set_perf(on: bool) -> void:
	show_perf = on
	RenderingServer.viewport_set_measure_render_time(sv.get_viewport_rid(), on or bench or probe or _phone_bench)
	hud.show_perf(on and not _phone_bench)
	_perf_wait = 0.0


## Twice a second (loop 2b; four times before, with a timestamp every frame): fps, frame time
## and the worst frame since the last update, the main thread's split (physics, process, draw;
## bench.gd times them from the engine's frame signals: Godot's own "process" monitor is the
## slowest whole frame of the last second, rendering included), the 3D view's GPU time (not on
## Metal), draw calls by pass (the pixel image's 3D and shadow passes, the 2D one), objects,
## triangles, memory, the image size, time and weather, the frame-rate cap.
func _update_perf(dt: float) -> void:
	_perf_wait -= dt
	if _perf_wait > 0.0:
		return
	_perf_wait = PERF_EVERY
	var live := _stats.take_live()
	var p := _stats.passes()
	var gpu := RenderingServer.viewport_get_measured_render_time_gpu(sv.get_viewport_rid())
	# Loop 2e: four short lines (11 pt on the phone) so the overlay fits beside the HUD's
	# panels; the time of day and the weather are on screen anyway, memory is in the BENCH card.
	# Loop G1: the last line is the quality, its pixel scale and the governor's levels (objects
	# and the shadow pass's triangles are on the BENCH card).
	var lines := PackedStringArray([
		"%.0f fps · %.1f ms · worst %.1f · cap %s" % [1000.0 / maxf(live["ms"], 0.01), live["ms"], live["worst"], _cap_name()],
		"CPU %.1f + %.1f + %.1f ms · GPU %s · %.0f MB" % [live["process"], live["physics"], live["draw"],
				"%.2f" % gpu if gpu > 0.0 else "n/a", Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0],
		"draws %d = %d + %d + %d · %.2f M tris" % [p["all_draws"], p["main_draws"], p["shadow_draws"], p["canvas_draws"],
				p["all_tris"] / 1e6],
		# Loop G1b: "High ×1 sharp" / "High ×2 fallback" where Auto's rule decides the image.
		"%s ×%d%s · gov %s%s" % [QUALITY[quality]["name"], view.stretch_shrink, (" " + _image_mode()).rstrip(" "),
				governor.state(), " · wide" if _wide else ""],
	])
	hud.set_perf("\n".join(lines))


## Loop 2b: the frame-rate cap: Settings (60 or 30, saved), --fps=N for one run, none for the
## bench and probe flags. On iOS project.godot keeps the display at 60 Hz
## (display/window/ios/allow_high_refresh_rate = false: a ProMotion phone would run at 120 and
## warm up), and 60 is left to it: measured on an iPhone 16 Pro Max, Engine.max_fps = 60 on top
## of it paced worse (7.8 % of frames a little late against 4.6 %); 30 uses Engine.max_fps.
func _apply_fps() -> void:
	var cap: int = settings.fps
	if _flag_fps >= 0:
		cap = _flag_fps
	if bench or probe or DisplayServer.get_name() == "headless":
		cap = 0
	_cap = cap
	Engine.max_fps = 0 if cap == 60 and OS.has_feature("ios") else cap
	# Loop G1: a frame is late against the cap's interval (60 fps when uncapped).
	governor.interval_ms = 1000.0 / (cap if cap > 0 else 60)
	governor.reset(_clock_s())


func _cap_name() -> String:
	return "%d fps" % _cap if _cap > 0 else "off"


## The bench's header lines: when, the device, the screen and image, the settings.
func _bench_header(kind: String) -> PackedStringArray:
	var screen := get_viewport().get_visible_rect().size
	var hz := DisplayServer.screen_get_refresh_rate()
	return PackedStringArray([
		"NOCNA WARSZAWA bench (loop 2b) · %s · %s" % [kind, Time.get_datetime_string_from_system(false, true)],
		"device %s · %s %s · %s (%s, %s) · %s" % [OS.get_model_name(), OS.get_name(), OS.get_version(),
				RenderingServer.get_video_adapter_name(), RenderingServer.get_current_rendering_driver_name(),
				RenderingServer.get_current_rendering_method(), OS.get_processor_name()],
		"screen %dx%d @ %.0f Hz · image %dx%d (×%d) · view %.0f m · quality %s · traffic %s · %s · %s · cap %s · %s" % [
				screen.x, screen.y, hz, sv.size.x, sv.size.y, view.stretch_shrink, base_size,
				Tiers.describe(quality_choice, quality, model_name, 0, _image_mode()),
				Settings.TRAFFIC_NAMES[traffic_level], TimeOfDay.NAMES[tod.mode], Weather.NAMES[weather.state],
				_cap_name(), Controls.NAMES[controls.scheme]],
		"thermal state: not readable from Godot; a phone that warms up shows it as falling fps per 10 s",
	])


## Loop 2b: the bench's result also goes to user://bench_result.txt (on the iPhone the app's
## Documents folder), not the save or the settings.
func _write_bench_result(text: String) -> void:
	var f := FileAccess.open("user://bench_result.txt", FileAccess.WRITE)
	if f != null:
		f.store_string(text + "\n")
		f.close()
		print("bench: result written to %s" % ProjectSettings.globalize_path("user://bench_result.txt"))


## Loop G1: the governor's line on the card: its levels, whether it was held for the run (the
## run then measures the quality's own cost), the view rule's state, its changes so far.
func _governor_notes() -> PackedStringArray:
	var how := "held" if governor.held else ("on" if _governor_on else "off")
	return PackedStringArray(["governor %s: %s%s, %d changes" % [how, governor.state(), ", wide" if _wide else "",
			governor.changes]])


## Loop G1: loop 2b's late measure (0.5 ms past the interval), in the log only, so a card from
## before G1 compares.
func _print_old_late(r: Dictionary) -> void:
	print("bench: %.1f%% of frames over %.1f ms (the measure before loop G1)" % [r["old_over"],
			r["budget"] + BenchStats.OLD_MARGIN])
	print("bench: %s" % _stats.late_detail(r["budget"]))


## Loop 2b, the BENCH button: the car rides the bench route's ghost driver from the spawn at
## the default view for PHONE_SETTLE + PHONE_SECONDS, at the current settings and frame-rate
## cap; the wallet is put back as it was and not saved (like --nosave), the car where it was.
func _start_phone_bench() -> void:
	if _phone_bench or not _started or title != null or bench or probe:
		return
	var busy := ""
	if flying:
		busy = "Najpierw wyląduj · Land first"
	elif rivals != null and rivals.racing():
		busy = "Najpierw skończ wyścig · Finish the race first"
	elif jobs != null and jobs.busy():
		busy = "Najpierw skończ zlecenie · Finish the job first"
	elif missions.has_target():
		busy = "Najpierw skończ akcję · Finish the rescue first"
	elif traffic == null or graph == null:
		busy = "Bez ruchu nie ma trasy · No traffic, no route"
	var hit := []
	if busy == "":
		var yaw := _spawn.basis.get_euler().y
		hit = graph.snap(Vector2(_spawn.origin.x, _spawn.origin.z), 60.0, Vector2(-sin(yaw), -cos(yaw)), true)
		if hit.is_empty():
			busy = "Brak trasy · No route"
	if busy != "":
		hud.toast(busy)
		return
	_phone_saved = {"at": car.global_transform, "mask": car.collision_mask, "size": base_size,
			"wallet": [wallet.zl, wallet.respect, wallet.jobs.duplicate(true), wallet.best.duplicate(true),
					wallet.eggs.duplicate(true)], "persistent": wallet.persistent, "calls": missions.paused}
	wallet.persistent = false
	# Loop G1: no rescue call comes in during the minute (its clock waits, as during a race): the
	# first call, 60 s into play, landed inside it and was the card's worst frame (61 ms on the
	# iPhone 11, 100-117 ms on the Pro Max).
	missions.paused = true
	hud.hide_bench_card()
	moments.stop()
	base_size = FollowCamera.DEFAULT_SIZE
	car.global_transform = _spawn
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.reset_physics_interpolation()
	cam_focus = car.global_position
	_bench_ghost = traffic.add_ghost(hit[0], hit[1], hit[2])
	_phone_bench = true
	_set_perf(show_perf)
	_stats.header = _bench_header("BENCH button")
	_bench_t0 = Time.get_ticks_msec()
	_measure_t0 = 0
	_phone_next_toast = _bench_t0
	print("bench: BENCH started (%.0f s settle + %.0f s measured, cap %s)" % [PHONE_SETTLE, _phone_seconds, _cap_name()])


func _phone_bench_frame() -> void:
	var now := Time.get_ticks_msec()
	var elapsed := (now - _bench_t0) / 1000.0
	if _measure_t0 == 0:
		if elapsed >= PHONE_SETTLE:
			_measure_t0 = now
			_stats.start()
	else:
		_stats.sample()
	if now >= _phone_next_toast:
		_phone_next_toast += 1000
		hud.toast("TEST %d s · nie dotykaj, proszę" % ceili(PHONE_SETTLE + _phone_seconds - elapsed), "hands off")
	if elapsed >= PHONE_SETTLE + _phone_seconds:
		_end_phone_bench(true)


func _end_phone_bench(done: bool) -> void:
	_phone_bench = false
	if _bench_ghost != null:
		traffic.remove(_bench_ghost)
		_bench_ghost = null
	car.global_transform = _phone_saved["at"]
	car.collision_mask = _phone_saved["mask"]
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.reset_physics_interpolation()
	cam_focus = car.global_position
	base_size = _phone_saved["size"]
	var w: Array = _phone_saved["wallet"]
	wallet.zl = w[0]
	wallet.respect = w[1]
	wallet.jobs = w[2]
	wallet.best = w[3]
	wallet.eggs = w[4]
	wallet.persistent = _phone_saved["persistent"]
	missions.paused = _phone_saved["calls"]
	hud.set_wallet(wallet.zl, wallet.respect)
	_set_perf(show_perf)
	if not done or _measure_t0 == 0:
		hud.toast("Test przerwany", "Bench cancelled")
		print("bench: BENCH cancelled")
		return
	var r := _stats.report(1000.0 / (_cap if _cap > 0 else 60))
	_stats.notes = _governor_notes()
	var text := _stats.text(r)
	for line in text.split("\n"):
		print("bench detail: %s" % line)
	_print_old_late(r)
	_write_bench_result(text)
	hud.show_bench_card(text)


## The side jobs (kebab stands, the słoiki run) and the easter eggs.
func _build_side_jobs(data: Dictionary, world: Node3D) -> void:
	var nodes := {"hud": hud, "bubbles": bubbles, "dialogue": dialogue, "wallet": wallet, "missions": missions,
			"rivals": rivals, "graph": graph, "traffic": traffic, "map": map, "car": car, "tod": tod}
	jobs = Jobs.new()
	jobs.autopilot = autopilot
	if start_heat >= 0.0:
		jobs.start_heat = start_heat
	add_child(jobs)
	jobs.setup(nodes, data, world)
	if rivals != null:
		rivals.jobs = jobs
	# --- loop 2d-1: Podwózka, the app-taxi side job (and the GPS moments of the app-taxis) ---
	rides = Rides.new()
	rides.autopilot = autopilot
	rides.ignore_app = ignore_app
	rides.log_on = parody_log
	rides.force_quirk = ride_quirk
	rides.force_passenger = ride_passenger
	rides.start_stars = ride_stars
	rides.gps_first = gps_in
	add_child(rides)
	nodes["jobs"] = jobs
	nodes["weather"] = weather
	rides.setup(nodes, data, world)
	jobs.rides = rides
	# --- end loop 2d-1 ---
	eggs = Eggs.new()
	eggs.day = barrier_day
	world.add_child(eggs)
	eggs.setup(nodes, data)


# --- loop 3g-1: the police ---------------------------------------------------------------------

## The police (police.gd, docs/design/police.md): patrol cars in the traffic, the day's speed
## traps, chases that end by themselves and the pull-over. Built after the sound.
func _build_police(data: Dictionary, world: Node3D) -> void:
	police = Police.new()
	police_opts["traffic_level"] = traffic_level
	# --barriers=YYYYMMDD places the day's speed traps too (like the roadworks).
	police_opts["day"] = barrier_day
	var nodes := {"map": map, "graph": graph, "traffic": traffic, "car": car, "cam": cam, "hud": hud,
			"bubbles": bubbles, "dialogue": dialogue, "wallet": wallet, "walkers": walkers, "radio": radio, "sfx": sfx,
			"jobs": jobs, "missions": missions, "tod": tod, "opts": police_opts, "pedal": hold_pedal, "autopilot": autopilot,
			"level_now": func() -> int: return traffic_level,
			"project": func(p: Vector3) -> Vector2: return cam.unproject_position(p) * float(view.stretch_shrink)}
	add_child(police)
	police.setup(nodes, data, world)


## The police's testing flags (README's flags table): --no-police, --police=1|2|3, --trap=N,
## --pullover=routine|trap|kebab|sloik|generic, --police-auto=escape|stop|hold, --police-now,
## --police-log, --police-offence=FRAME:kind,...
func _police_flag(arg: String) -> void:
	if arg == "--no-police":
		police_opts["off"] = true
	elif arg == "--police-now":
		police_opts["now"] = true
	elif arg == "--police-log":
		police_opts["log"] = true
	elif arg.begins_with("--police-auto="):
		police_opts["auto"] = arg.trim_prefix("--police-auto=")
	elif arg.begins_with("--police-offence="):
		police_opts["offences"] = arg.trim_prefix("--police-offence=")
	elif arg.begins_with("--police="):
		police_opts["level"] = clampi(int(arg.trim_prefix("--police=")), 1, 3)
		show_title = false
		free_roam = true
	elif arg.begins_with("--trap="):
		var n := int(arg.trim_prefix("--trap="))
		police_opts["trap"] = n
		var start := Police.trap_start(n)
		if not start.is_empty():
			start_at = start[0]
			start_heading = start[1]
		show_title = false
		free_roam = true
	elif arg.begins_with("--pullover="):
		police_opts["pullover"] = arg.trim_prefix("--pullover=")
		show_title = false
		free_roam = true
	elif arg.begins_with("--pullover-frame="):
		# Loop 2d-1: the --pullover conversation at frame N (default 60), e.g. during a --ride.
		police_opts["pullover_frame"] = maxi(1, int(arg.trim_prefix("--pullover-frame=")))


## The game's own options. Loop 2b: a launcher can swallow the "--" (devicectl on an iPhone):
## then they arrive among the engine's own; ours never share a name with those. Every parser of
## game flags reads this (loop G0+: the streaming flags read only the user args, so on the phone
## --stream-soak and --stream-log did nothing and the soak never ran).
static func game_args() -> PackedStringArray:
	var args := OS.get_cmdline_user_args()
	return args if not args.is_empty() else OS.get_cmdline_args()


func _parse_args() -> void:
	start_station = 1
	for arg in game_args():
		if arg == "--demo":
			demo = true
		elif arg.begins_with("--shots="):
			for s in arg.trim_prefix("--shots=").split(","):
				shots.append(int(s))
		elif arg.begins_with("--out="):
			out_dir = arg.trim_prefix("--out=")
		elif arg.begins_with("--style="):
			_flag_style = posmod(int(arg.trim_prefix("--style=")), STYLES.size())
		elif arg.begins_with("--at="):
			var xz := arg.trim_prefix("--at=").split(",")
			start_at = Vector3(float(xz[0]), 0.0, float(xz[1]))
		elif arg.begins_with("--heading="):
			start_heading = float(arg.trim_prefix("--heading="))
		elif arg.begins_with("--pitch="):
			camera_pitch = float(arg.trim_prefix("--pitch="))
		elif arg.begins_with("--lines="):
			lines_override = int(arg.trim_prefix("--lines="))
		elif arg.begins_with("--sun="):
			sun_pitch = float(arg.trim_prefix("--sun="))
		elif arg == "--debug-ao":
			debug_ao = true
		elif arg == "--tunnel":
			start_in_tunnel = true
		elif arg == "--debug-roads":
			debug_roads = true
		elif arg.begins_with("--lift="):
			cam_lift = float(arg.trim_prefix("--lift="))
		elif arg.begins_with("--ghost-debug="):
			ghost_debug = int(arg.trim_prefix("--ghost-debug="))
		elif arg == "--prebuilt":
			prebuilt = true
		elif arg == "--no-ao":
			no_ao = true
		elif arg == "--nohud":
			hide_hud = true
		elif arg == "--no-touch":
			no_touch = true  # desktop: --no-touch
		elif arg == "--no-input":
			# Loop 3d-1: a test render ignores every key, click and touch (check_streaming's windows
			# take the focus for minutes: keys typed elsewhere toggled the time, the overlay, the radio).
			# The window never takes the focus, so keys typed elsewhere stay there.
			DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS, true)
		elif arg.begins_with("--size="):
			base_size = float(arg.trim_prefix("--size="))
		elif arg == "--fixed":
			_flag_fixed = true
		elif arg.begins_with("--yaw="):
			cam_yaw = float(arg.trim_prefix("--yaw="))
			cam_yaw_target = cam_yaw
			_flag_yaw = true
		elif arg == "--cinematic" or arg.begins_with("--cinematic="):
			_flag_cinematic = arg.trim_prefix("--cinematic=") if arg.contains("=") else "all"
		elif arg == "--heli":
			start_flying = true
		elif arg.begins_with("--mission="):
			start_mission = maxi(1, int(arg.trim_prefix("--mission=")))
		elif arg == "--autopilot":
			autopilot = true
		elif arg == "--no-traffic":
			no_traffic = true
		elif arg == "--lineup":
			lineup = true
			no_traffic = true
			free_roam = true
		elif arg.begins_with("--race="):
			start_race = maxi(1, int(arg.trim_prefix("--race=")))
		elif arg.begins_with("--rival="):
			start_rival = maxi(1, int(arg.trim_prefix("--rival=")))
		elif arg == "--bench":
			bench = true
		elif arg.begins_with("--bench-frames="):
			_bench_frames = maxi(60, int(arg.trim_prefix("--bench-frames=")))
		elif arg.begins_with("--bench-seconds="):
			_bench_seconds = maxf(5.0, float(arg.trim_prefix("--bench-seconds=")))
			_phone_seconds = _bench_seconds
		elif arg == "--bench-button":
			bench_button = true
		elif arg.begins_with("--fps="):
			_flag_fps = maxi(0, int(arg.trim_prefix("--fps=")))
		elif arg == "--probe":
			probe = true
			free_roam = true
		elif arg.begins_with("--exp="):
			_exp = arg.trim_prefix("--exp=").split(",")
		elif arg.begins_with("--time="):
			start_time = TimeOfDay.parse(arg.trim_prefix("--time="))
		elif arg == "--vhs":
			_flag_vhs = true
		elif arg.begins_with("--call-in="):
			call_in = maxf(0.0, float(arg.trim_prefix("--call-in=")))
		elif arg.begins_with("--radio="):
			var v := arg.trim_prefix("--radio=")
			start_station = 0 if v == "off" else clampi(int(v), 0, Radio.STATIONS.size())
		elif arg == "--notitle":
			show_title = false
		elif arg == "--title":
			force_title = true
		elif arg.begins_with("--kebab="):
			start_kebab = maxi(0, int(arg.trim_prefix("--kebab=")))
		elif arg == "--sloik" or arg.begins_with("--sloik="):
			start_sloik = maxi(0, int(arg.trim_prefix("--sloik="))) if arg.contains("=") else 0
		elif arg.begins_with("--heat="):
			start_heat = clampf(float(arg.trim_prefix("--heat=")), 0.0, 1.0)
		# --- loop 2d-1: Podwózka's flags ---
		elif arg.begins_with("--ride="):
			start_ride = maxi(0, int(arg.trim_prefix("--ride=")))
		elif arg.begins_with("--ride-quirk="):
			ride_quirk = arg.trim_prefix("--ride-quirk=").to_lower()
		elif arg.begins_with("--passenger="):
			ride_passenger = arg.trim_prefix("--passenger=").to_lower()
		elif arg.begins_with("--stars="):
			ride_stars = clampf(float(arg.trim_prefix("--stars=")), 1.0, 5.0)
		elif arg == "--ignore-app":
			ignore_app = true
		elif arg == "--parody-log":
			parody_log = true
		elif arg.begins_with("--gps-in="):
			gps_in = maxf(0.0, float(arg.trim_prefix("--gps-in=")))
		# --- end loop 2d-1 ---
		elif arg.begins_with("--host-in="):
			host_in = maxf(0.0, float(arg.trim_prefix("--host-in=")))
		elif arg.begins_with("--barriers="):
			barrier_day = int(arg.trim_prefix("--barriers="))
		elif arg == "--reset-save":
			reset_save = true
		elif arg == "--nosave":
			no_save = true
		elif arg == "--free":
			free_roam = true
		elif arg.begins_with("--tap="):
			var xy := arg.trim_prefix("--tap=").split(",")
			tap_at = Vector2(float(xy[0]), float(xy[1]))
		elif arg.begins_with("--weather="):
			start_weather = Weather.parse(arg.trim_prefix("--weather="))
		elif arg.begins_with("--clock="):
			live_clock = arg.trim_prefix("--clock=")
		elif arg.begins_with("--date="):
			live_date = int(arg.trim_prefix("--date="))
		elif arg == "--perf":
			_flag_perf = true
		elif arg == "--sound-check":
			sound_check = true
		elif arg.begins_with("--quality="):
			_flag_quality = Tiers.parse(arg.trim_prefix("--quality="))
		elif arg.begins_with("--model="):
			_flag_model = arg.trim_prefix("--model=")
		elif arg.begins_with("--last-session="):
			# Loop G1b: Auto as if the last session at the sharp image struggled or was calm.
			_flag_last_session = arg.trim_prefix("--last-session=")
		elif arg.begins_with("--governor="):
			_flag_governor = 0 if arg.trim_prefix("--governor=") in ["off", "0", "no"] else 1
			_governor_log = arg == "--governor=log"
		elif arg.begins_with("--stress="):
			var st := arg.trim_prefix("--stress=").split(":")
			_stress_kind = st[0] if st[0] in ["cpu", "wait"] else ""
			_stress_n = maxi(0, int(st[1])) if st.size() > 1 else 0
		elif arg.begins_with("--stress-from="):
			_stress_from = maxf(0.0, float(arg.trim_prefix("--stress-from=")))
		elif arg.begins_with("--stress-to="):
			_stress_to = maxf(0.0, float(arg.trim_prefix("--stress-to=")))
		elif arg.begins_with("--controls="):
			_flag_controls = Controls.parse(arg.trim_prefix("--controls="))
		elif arg.begins_with("--traffic="):
			_flag_traffic = Settings.parse_traffic(arg.trim_prefix("--traffic="))
		elif arg == "--settings":
			open_settings_at_start = true
		elif arg.begins_with("--settings-tab="):
			open_settings_at_start = true
			settings_tab = int(arg.trim_prefix("--settings-tab="))
		elif arg.begins_with("--stick="):
			var sv2 := arg.trim_prefix("--stick=").split(",")
			hold_stick = Vector2(float(sv2[0]), float(sv2[1])).limit_length(1.0)
		elif arg.begins_with("--pedal="):
			hold_pedal = arg.trim_prefix("--pedal=")
		elif arg.begins_with("--drag="):
			var dv := arg.trim_prefix("--drag=").split(":")
			var d := PackedInt32Array()
			for v in dv:
				d.append(int(v))
			if d.size() == 6:
				drags.append(d)
		elif arg.begins_with("--drive-into-water="):
			var wz := arg.trim_prefix("--drive-into-water=").split(",")
			_water_test_at = Vector2(float(wz[0]), float(wz[1]))
		elif arg == "--cam-log":
			cam_log = true
		elif arg.begins_with("--cam-test="):
			cam_test = arg.trim_prefix("--cam-test=")
			cam_log = true
			no_traffic = true
			free_roam = true
		elif arg.begins_with("--clicks="):
			for c in arg.trim_prefix("--clicks=").split(","):
				var xyf := c.split(":")
				clicks.append(Vector3i(int(xyf[0]), int(xyf[1]), int(xyf[2])))
		# Loop 3g-1: the police's flags (_police_flag, below).
		elif arg == "--no-police" or arg.begins_with("--police") or arg.begins_with("--trap=") or arg.begins_with("--pullover"):
			_police_flag(arg)
	# Test runs go straight to the city (--title brings the title screen back).
	if demo or not shots.is_empty() or autopilot or start_race > 0 or start_mission > 0 or start_rival > 0 or bench or probe \
			or start_kebab >= 0 or start_sloik >= 0 or sound_check or open_settings_at_start or hold_stick != Vector2.INF or bench_button \
			or _water_test_at != Vector2.INF or cam_test != "":
		show_title = false
	if start_ride >= 0:
		show_title = false  # loop 2d-1: --ride is a test run too
	if force_title:
		show_title = true
	# Camera loop: the cinematic moments in a normal launch only (never with screenshots or a bench).
	var normal := show_title and shots.is_empty() and not bench and not probe and not bench_button and not demo
	cinematic_flyin = normal or _flag_cinematic in ["all", "flyin"]
	cinematic_look = normal or _flag_cinematic in ["all", "look"]
	# Loop G1: the governor runs in a normal launch; test runs hold it so they repeat.
	var test_run := DisplayServer.get_name() == "headless" or not shots.is_empty() or bench or probe or autopilot \
			or demo or cam_test != "" or _water_test_at != Vector2.INF
	_governor_on = _flag_governor == 1 if _flag_governor >= 0 else not test_run
	# Loop G1b: test runs (and --last-session=) never write Auto's image state, even with the
	# governor on and without --nosave.
	_image_write = not test_run and _flag_last_session == ""


## Loop 2a: the saved settings (not with --nosave), then the command-line flags over them.
## Loop G1: the quality the player chose (Auto by default) and the level Auto picks here.
func _load_settings() -> void:
	settings.persistent = not no_save
	settings.load_file()
	model_name = _flag_model if _flag_model != "" else OS.get_model_name()
	auto_quality = Tiers.for_model(model_name)
	quality_choice = _flag_quality if _flag_quality != -2 else settings.quality
	quality = auto_quality if quality_choice == Tiers.AUTO else quality_choice
	print("quality: %s · Auto picks %s for %s" % [Tiers.describe(quality_choice, quality, model_name),
			Tiers.NAMES[auto_quality], model_name])
	# Loop G1b: Auto's sharp image or its fallback, from the saved state (or --last-session=).
	var image := settings.auto_image
	if _flag_last_session == "struggled":
		image = Tiers.sharp_struggled(Tiers.sharp_state(), true, "--last-session=struggled")
	elif _flag_last_session == "calm":
		image = Tiers.sharp_state()
	elif _flag_last_session != "":
		push_warning("--last-session=%s: struggled or calm" % _flag_last_session)
	auto_image = Tiers.sharp_launch(image)
	auto_sharp = not auto_image["fallback"]
	print("quality: Auto's image state (where the budget binds) %s → this launch %s%s" % [settings.image_summary(), "sharp" if auto_sharp else "fallback",
			" (%s)" % ("--last-session=" + _flag_last_session) if _flag_last_session != "" else ""])
	traffic_level = _flag_traffic if _flag_traffic >= 0 else settings.traffic
	show_perf = _flag_perf or settings.perf
	var scheme := _flag_controls if _flag_controls >= 0 else settings.controls
	if _flag_fixed and scheme == Controls.POINT:
		scheme = Controls.FIXED
	controls.scheme = scheme
	follow = scheme == Controls.POINT or (scheme == Controls.CLASSIC and settings.classic_follow and not _flag_fixed)
	style_index = _flag_style if _flag_style >= 0 else settings.style
	vhs = _flag_vhs or settings.vhs
	print("settings: %s (%s)" % [settings.summary(), ProjectSettings.globalize_path(Settings.PATH) if not no_save else "not saved"])


## The day's light; time_of_day.gd changes it for dusk and night.
func _add_environment(world: Node3D) -> void:
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color("#a8cde6")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#b6c6db")
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	var we := WorldEnvironment.new()
	we.environment = env
	world.add_child(we)

	sun = DirectionalLight3D.new()
	sun.light_color = Color("#ffe8c8")
	sun.light_energy = 1.25
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 900.0
	sun.shadow_bias = 0.06
	sun.rotation_degrees = Vector3(sun_pitch, -20.0, 0.0)
	world.add_child(sun)


func _add_post_pass() -> void:
	var quad := MeshInstance3D.new()
	var mesh := QuadMesh.new()
	mesh.size = Vector2(2, 2)
	mesh.flip_faces = true
	quad.mesh = mesh
	quad.extra_cull_margin = 16384.0
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	post_mat = ShaderMaterial.new()
	post_mat.shader = load("res://shaders/post.gdshader")
	quad.material_override = post_mat
	cam.add_child(quad)
	quad.position = Vector3(0, 0, -2)


## Night-only things (neon signs, lamp halos, vehicle light cones, signal halos,
## the helicopter's lights) show only while the city's lights are on, so the day
## renders exactly as before.
func _show_night_nodes(on: bool) -> void:
	for holder in ["Neon", "LampHalos"]:
		var n := map.get_node_or_null(holder) as Node3D
		if n != null:
			n.visible = on
	get_tree().call_group("night_lights", "set_visible", on)


## The vehicles' shader lights them under the street lamps too: it needs the map's
## baked lamp pools.
func _share_lights() -> void:
	if map.light_texture == null:
		return
	var m := Models.material()
	m.set_shader_parameter("light_map", map.light_texture)
	m.set_shader_parameter("light_rect", map.light_rect)


## The VHS overlay runs on the container that scales the pixel image up to the
## screen, so its scanlines are sharp screen pixels.
func _set_vhs(on: bool) -> void:
	vhs = on
	if on:
		if _vhs_mat == null:
			_vhs_mat = ShaderMaterial.new()
			_vhs_mat.shader = load("res://shaders/vhs.gdshader")
		var screen := get_viewport().get_visible_rect().size
		_vhs_mat.set_shader_parameter("line_px", maxf(2.0, roundf(screen.y / 360.0)))
		view.material = _vhs_mat
	else:
		view.material = null


func _blip_sound() -> void:
	if _blip != null and _blip.stream != null:
		_blip.play()


func _rotate_camera(direction: int) -> void:
	if follow:
		_toggle_follow()
	# Fixed mode keeps the classic diagonal views: 45°, 135°, 225°, 315°.
	cam_yaw_target = 45.0 + 90.0 * roundf((cam_yaw - 45.0) / 90.0) + 90.0 * direction


## C (and Settings → Kamera za autem): the camera follows the car or stays put. Loop 2e: a toast
## says which, so it never switches off unnoticed (it did with the old CAM button).
func _toggle_follow() -> void:
	_set_follow(not follow)
	hud.toast("Kamera: za autem" if follow else "Kamera: stała", "Camera: follows the car" if follow else "Camera: fixed")
	# Loop 2a: in the point schemes the camera is the scheme (Point follows, Fixed doesn't).
	if controls.scheme != Controls.CLASSIC:
		_set_scheme(Controls.POINT if follow else Controls.FIXED, false)
	else:
		settings.classic_follow = follow
		settings.save()


func _set_follow(on: bool) -> void:
	follow = on
	if not follow:
		cam_yaw_target = 45.0 + 90.0 * roundf((cam_yaw - 45.0) / 90.0)


## Loop 2a: a control scheme (drive_controls.gd); Point turns the follow camera on, Fixed off,
## Classic takes its saved camera. Saved.
func _set_scheme(scheme: int, set_camera := true) -> void:
	controls.scheme = scheme
	settings.controls = scheme
	settings.save()
	hud.set_scheme(scheme)
	if set_camera:
		_set_follow(scheme == Controls.POINT or (scheme == Controls.CLASSIC and settings.classic_follow))


## Loop 2a: the settings panel (the gear, Esc, --settings). The game pauses under it.
func _open_settings() -> void:
	if not _started or title != null or hud.settings_open():
		return
	if _phone_bench:
		_end_phone_bench(false)
	print("settings panel: open (paused)")
	_blip_sound()
	get_tree().paused = true
	hud.open_settings(_settings_state())


## What the settings panel shows (loop 2e: also the camera, time of day, weather, style, VHS).
func _settings_state() -> Dictionary:
	# Loop G1: the panel's quality row is Auto, then Low..Ultra (the choice + 1).
	# Loop G1b: what Auto draws here: "High ostry" (the sharp image), "High ×2" (the fallback)
	# where its budget binds, else the level.
	var auto_name: String = Tiers.NAMES[auto_quality]
	if lines_override <= 0 and Tiers.budget_binds(get_viewport().get_visible_rect().size, STYLES[style_index]["lines"], auto_quality):
		auto_name += " ostry" if auto_sharp else " ×%d" % Tiers.image_scale(get_viewport().get_visible_rect().size,
				STYLES[style_index]["lines"], auto_quality)
	return {"controls": controls.scheme, "follow": follow, "traffic": traffic_level, "quality": quality_choice + 1,
			"auto": auto_name,
			"master": settings.master, "music": settings.music, "effects": settings.effects, "perf": int(show_perf),
			"fps": maxi(0, Settings.FPS.find(settings.fps)), "style": style_index, "vhs": int(vhs),
			"weather": weather.state, "time": tod.mode}


func _close_settings() -> void:
	print("settings panel: closed")
	get_tree().paused = false
	_blip_sound()


func _on_setting(key: String, value: Variant) -> void:
	print("setting: %s = %s" % [key, value])
	match key:
		"controls":
			_set_scheme(int(value))
		"drive":
			# Loop 2e: Point or Classic; Point keeps the camera row's choice (off: Fixed camera).
			if int(value) == 1:
				_set_scheme(Controls.CLASSIC)
			else:
				_set_scheme(Controls.POINT if controls.scheme == Controls.POINT or (controls.scheme == Controls.CLASSIC and follow) else Controls.FIXED)
			hud.settings_panel.sync(_settings_state())
		"camera":
			if (int(value) == 0) != follow:
				_toggle_follow()
			hud.settings_panel.sync(_settings_state())
		"style":
			style_index = clampi(int(value), 0, STYLES.size() - 1)
			settings.style = style_index
			_apply_style()
			# Loop G1b: Auto's button says what it draws with this style.
			hud.settings_panel.sync(_settings_state())
		"vhs":
			_set_vhs(int(value) == 1)
			settings.vhs = vhs
		"weather":
			weather.set_state(int(value))
		"time":
			tod.set_mode(int(value))
		"traffic":
			traffic_level = int(value)
			settings.traffic = traffic_level
			_apply_traffic()
		"quality":
			_set_quality(int(value) - 1)
		"perf":
			settings.perf = int(value) == 1
			_set_perf(settings.perf)
		"fps":
			settings.fps = Settings.FPS[clampi(int(value), 0, Settings.FPS.size() - 1)]
			_apply_fps()
		"bench":
			_start_phone_bench.call_deferred()
			return
		"master", "music", "effects":
			settings.set(key, float(value))
			Sfx.set_levels(settings.master, settings.music, settings.effects)
	settings.save()
	_blip_sound()


## Loop 2a: the car was pinned against something twice in a few seconds (car.gd): put it on
## the nearest free spot.
func _on_car_stuck() -> void:
	if flying or autopilot or car.in_water:
		return
	# Back onto the nearest lane, facing its way (else just the nearest free spot).
	var at := car.global_position
	var yaw := car.rotation.y
	var lane := _lane_spot(at, yaw)
	if not lane.is_empty():
		at = lane[0]
		yaw = lane[1]
	var spot := _free_car_spot(at, yaw)
	car.global_position = spot
	car.rotation.y = yaw
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.reset_physics_interpolation()
	hud.toast("Pomoc drogowa: wyciągnięci!", "Towed free")
	_cut_camera()
	print("car stuck: moved to %.1f, %.1f" % [spot.x, spot.z])


## The nearest lane to `at` on its level (not a deck overhead, nor a road under the bridge it is
## on), a lane the car's way first, then any: [position, yaw], or [] when there is none within
## the lane graph's reach. Loop 2a's tow; loop 10a shares it with the tow out of the water,
## never gives a lane point in the water, and takes "its level" as the ground (any lane on the
## terrain: the river's bank is metres below the roads above it) or, on a deck, within 4 m.
func _lane_spot(at: Vector3, yaw: float) -> Array:
	if graph == null:
		return []
	var p := Vector2(at.x, at.z)
	for heading in [Vector2(-sin(yaw), -cos(yaw)), Vector2.ZERO]:
		var hit := graph.snap(p, 80.0, heading)
		if hit.is_empty():
			continue
		var e: int = hit[0]
		var lane_s: float = hit[2]
		var h := graph.height(e, lane_s)
		var q := graph.point_at(e, lane_s, graph.lane_offset(e, hit[1]))
		if not _same_level(at, q, h) or map.in_water(q.x, q.y, h):
			continue
		var d := graph.direction(e, lane_s)
		return [Vector3(q.x, h, q.y), atan2(-d.x, -d.y)]
	return []


## Loop 10a: the lane nearest to `at` anywhere on the map, on its level and inside the edge
## walls, from the lane graph's junctions (the start of each lane out of one): [position, yaw],
## or [] (no graph). For a tow from far out in the water or a wide beach, where no lane is
## within the lane graph's snapping reach.
func _node_spot(at: Vector3) -> Array:
	if graph == null:
		return []
	var inner: Rect2 = map.bounds.grow(-12.0)
	var best: Array = []
	var best_d := INF
	for n in graph.node_pos.size():
		var d := graph.node_pos[n].distance_squared_to(Vector2(at.x, at.z))
		if d >= best_d or graph.node_scc[n] == 0:
			continue
		for e in graph.node_out[n]:
			var s := graph.e_s0[e]
			var q := graph.point_at(e, s, graph.lane_offset(e, 0))
			var h := graph.height(e, s)
			if not inner.has_point(q) or not _same_level(at, q, h) or map.in_water(q.x, q.y, h):
				continue
			var dir := graph.direction(e, s)
			best = [Vector3(q.x, h, q.y), atan2(-dir.x, -dir.y)]
			best_d = d
			break
	return best


## Loop 10a: a lane point q at height h is on the level of `at`: both on the ground (the
## terrain, however high), or within 4 m of each other on a deck.
func _same_level(at: Vector3, q: Vector2, h: float) -> bool:
	if at.y < map.terrain_height(at.x, at.z) + 0.5:
		return h < map.terrain_height(q.x, q.y) + 1.0
	return absf(h - at.y) <= 4.0


## Loop 10a: keeps where the car last stood on dry land or a deck (the tow goes back to that
## level), and tows it out TOW_DELAY s after a splash.
func _water_frame(dt: float) -> void:
	_clock += dt
	if car.in_water:
		if _tow_wait > 0.0:
			_tow_wait -= dt
			if _tow_wait <= 0.0:
				_tow_out_of_water()
	elif not flying and car.collision_mask != 0:
		_last_dry = car.global_position
		_last_dry_yaw = car.rotation.y


## Loop 10a: the car rolled into the water (car.splashed): the splash, its sound and a buzz,
## and the tow on its way.
func _on_car_splashed(speed: float) -> void:
	var p := car.global_position
	splash.burst(p, speed, car.vel)
	if sfx != null:
		sfx.splash(speed)
	Input.vibrate_handheld(80, clampf(speed / 15.0, 0.4, 1.0))
	_tow_wait = TOW_DELAY
	_splash_at = _clock
	if water_test == 2:
		water_test = 3
	print("water: splash at %.1f, %.1f at %d km/h (%s), frame %d" % [p.x, p.z, roundi(speed * 3.6), _water_kind(p), frame])


## Loop 10a: the tow lifts the car out of the water onto the nearest lane on dry land (back
## on the level it came from), with a line from the tow crew. Nothing else changes: no money,
## no fail; a rescue, a delivery or a race carries on.
func _tow_out_of_water() -> void:
	_tow_wait = -1.0
	var at := car.global_position
	var spot := _water_tow_spot(at, _last_dry, _last_dry_yaw)
	var where: Vector3 = spot[0]
	car.global_position = where
	car.rotation.y = spot[1]
	car.leave_water()
	car.reset_physics_interpolation()
	cam_focus = where
	_cut_camera()
	var kind := _water_kind(at)
	var l: Array = dialogue.line("water_tow", kind) if dialogue != null else []
	if l.size() < 2:
		l = ["Pomoc drogowa: wyciągnięci z wody!", "Roadside assistance: out of the water!"]
	hud.toast(l[0], l[1])
	var lane_off := -1.0
	if graph != null:
		var hit := graph.snap(Vector2(where.x, where.z), 8.0)
		if not hit.is_empty():
			lane_off = graph.point_at(hit[0], hit[2], graph.lane_offset(hit[0], hit[1])).distance_to(Vector2(where.x, where.z))
	print("water: towed after %.2f s from %.0f, %.0f to %.1f, %.1f, %.0f m away, %s from a lane, %s; %s, frame %d · %s" % [
			_clock - _splash_at, at.x, at.z, where.x, where.z, Vector2(at.x, at.z).distance_to(Vector2(where.x, where.z)),
			("%.1f m" % lane_off) if lane_off >= 0.0 else "far", "dry" if map.shore_distance(where.x, where.z) == 0.0 else "WET",
			_activity(), frame, l[0]])
	if water_test == 3:
		water_test = 4


## Loop 10a: where the tow puts a car that is in the water at `at`: the nearest lane to where it
## last was on dry land or a deck (`from`, on that level), else the lane nearest to the nearest
## dry land, else the nearest junction; then the free spot there (never in the water).
## [position, yaw].
func _water_tow_spot(at: Vector3, from: Vector3, yaw: float) -> Array:
	var ref := from
	if ref == Vector3.INF or Vector2(ref.x, ref.z).distance_to(Vector2(at.x, at.z)) > 150.0:
		var dry: Vector2 = map.nearest_dry(at.x, at.z)
		ref = Vector3(dry.x, map.terrain_height(dry.x, dry.y), dry.y)
	var spot := _lane_spot(ref, yaw)
	if spot.is_empty():
		spot = _node_spot(ref)
	if spot.is_empty():
		spot = [ref, yaw]
	return [_free_car_spot(spot[0], spot[1]), spot[1]]


## Loop 10a: "river" or "pond" (which tow lines fit).
func _water_kind(p: Vector3) -> String:
	for r in _rivers:
		if Geometry2D.is_point_in_polygon(Vector2(p.x, p.z), r):
			return "river"
	return "pond"


## Loop 10a: what is running, for the water test's lines.
func _activity() -> String:
	return "job %s, rescue %s, race %s, wallet %d zł" % ["on" if jobs != null and jobs.busy() else "none",
			"on" if missions.has_target() else "none", "on" if rivals != null and rivals.racing() else "none", wallet.zl]


## Loop 2c, --lineup: every vehicle model standing round the car, all facing its way: beside it
## the taxi, Podwózka, the police car, the guards' car and the two vans; a row ahead the cars'
## four shapes; a row behind the six rivals; further back the bus and a tram cab car.
## Family shapes go through a MultiMesh with the shape in the custom alpha, as traffic draws
## them. Prints each model's triangles.
func _build_lineup(parent: Node3D) -> void:
	var b := car.global_transform.basis
	var right := Vector3(b.x.x, 0.0, b.x.z).normalized()
	var ahead := Vector3(-b.z.x, 0.0, -b.z.z).normalized()
	var origin := car.global_position
	var yaw := car.rotation.y
	var spot := func(x: float, z: float, turn: float) -> Transform3D:
		var q := origin + right * x + ahead * z
		q.y = map.ground_height(q.x, q.z)
		return Transform3D(Basis(Vector3.UP, yaw + turn), q)
	var cars := Models.traffic_mesh(0)
	var taxis := Models.traffic_mesh(1)
	var vans := Models.traffic_mesh(2)
	var police := Models.police_mesh()
	# [mesh, shape, paint, x, z, turn, name]
	var rows := [
		[taxis, 0, "#f2f2ee", -10.0, 0.0, 0.0, "taxi"], [taxis, 1, "#2b2c2f", -6.6, 0.0, 0.0, "podwozka"],
		[police, 0, Models.POLICE_WHITE.to_html(false), -3.3, 0.0, 0.0, "police"],
		[police, 1, Models.GUARD_MUSTARD.to_html(false), 3.3, 0.0, 0.0, "guard"],
		[vans, 0, "#e9e9e6", 6.7, 0.0, 0.0, "panel van"], [vans, 1, "#d8d2c2", 10.3, 0.0, 0.0, "box van"],
		[cars, 0, "#b8bcc0", -4.8, 7.5, 0.0, "hatch"], [cars, 1, "#24324a", -1.6, 7.5, 0.0, "saloon"],
		[cars, 2, "#4c6650", 1.6, 7.5, 0.0, "estate"], [cars, 3, "#2b2c2f", 4.8, 7.5, 0.0, "suv"],
		[Models.traffic_mesh(3), 0, "#ffffff", -4.0, -17.5, 0.0, "bus"],
	]
	for r: Array in rows:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = r[0]
		mm.instance_count = 1
		mm.set_instance_transform(0, spot.call(r[3], r[4], r[5]))
		var paint := Color(r[2])
		mm.set_instance_custom_data(0, Color(paint.r, paint.g, paint.b, float(r[1])))
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = Models.material()
		parent.add_child(mmi)
		print("lineup: %s %d triangles" % [r[6], _triangles(r[0])])
	for i in Rivals.RIVALS.size():
		var mi := MeshInstance3D.new()
		mi.mesh = Models.rival_mesh(Rivals.RIVALS[i]["style"])
		mi.material_override = Models.material()
		mi.transform = spot.call(-8.0 + i * 3.2, -8.0, 0.0)
		parent.add_child(mi)
		print("lineup: rival %s %d triangles" % [Rivals.RIVALS[i]["name"], _triangles(mi.mesh)])
	var tram := MeshInstance3D.new()
	tram.mesh = Models.tram_mesh(true)
	tram.material_override = Models.material()
	tram.transform = spot.call(4.0, -17.0, 0.0)
	parent.add_child(tram)
	print("lineup: tram cab car %d triangles" % _triangles(tram.mesh))
	var own := 0
	for c in car.get_children():
		for m in c.get_children():
			if m is MeshInstance3D and (m as MeshInstance3D).mesh is ArrayMesh \
					and (m as MeshInstance3D).material_override != Models.glow_material():
				own += _triangles((m as MeshInstance3D).mesh)
	print("lineup: the player's car %d triangles" % own)


static func _triangles(mesh: Mesh) -> int:
	var n := 0
	for k in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(k)
		var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX] if arrays[Mesh.ARRAY_INDEX] != null else PackedInt32Array()
		n += (idx.size() if not idx.is_empty() else (arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()) / 3
	return n


## Loop 10a, --drive-into-water=X,Z: the car at X,Z, facing the nearest water at least 4 m past
## its edge (within 120 m), flat out, its collision off as if it had jumped the edge (a ramp, a
## glitch); the collision comes back on 3 m past the edge, and the splash and the tow follow.
func _start_water_test() -> void:
	var p := _water_test_at
	var best := Vector2.ZERO
	var best_r := 120.0
	for k in 72:
		var d := Vector2.from_angle(TAU * k / 72.0)
		var r := 2.0
		while r < best_r:
			var q := p + d * r
			if map.shore_distance(q.x, q.y) >= 4.0:
				best_r = r
				best = d
				break
			r += 1.0
	if best == Vector2.ZERO:
		print("water test: no water within 120 m of %.0f, %.0f" % [p.x, p.y])
		return
	car.global_position = Vector3(p.x, map.drive_height(p.x, p.y, map.terrain_height(p.x, p.y)), p.y)
	car.rotation.y = atan2(-best.x, -best.y)
	car.vel = Vector3.ZERO
	car.reset_physics_interpolation()
	car.collision_mask = 0
	cam_focus = car.global_position
	water_test = 1
	print("water test: from %.0f, %.0f towards the water %.0f m away (heading %03.0f°); %s" % [p.x, p.y, best_r,
			fposmod(rad_to_deg(atan2(best.x, -best.y)), 360.0), _activity()])


## Loop 10a: the water test drives flat out, straight on; collision back on past the edge.
func _water_test_frame() -> void:
	car.target_dir = Vector3.ZERO
	car.steer = 0.0
	car.throttle = 1.0
	car.braking = false
	var p := car.global_position
	if water_test == 1 and map.shore_distance(p.x, p.z) >= 3.0:
		car.collision_mask = 1
		water_test = 2


## Camera loop, --cam-test=NAME: the scheme, the camera behind the car, the car ghosting through
## walls (the camera is what is tested; a building in the way would end the moment early).
func _start_cam_test() -> void:
	if not cam_test in ["classic_turn", "point_release", "brake"]:
		print("cam test: unknown test '%s' (classic_turn, point_release, brake)" % cam_test)
		cam_test = ""
		return
	controls.scheme = Controls.POINT if cam_test == "point_release" else Controls.CLASSIC
	hud.set_scheme(controls.scheme)
	_set_follow(true)
	car.collision_mask = 0
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	cam_yaw = rad_to_deg(car.rotation.y)
	cam_yaw_target = cam_yaw
	cam_focus = car.global_position
	print("cam test: %s, %s, from %.0f, %.0f heading %03.0f°, %.1f s parked first" % [cam_test,
			Controls.NAMES[controls.scheme], car.global_position.x, car.global_position.z, _compass_yaw(car.rotation.y),
			CAM_TEST_SETTLE])


## The camera test's inputs for this frame, through the scheme's own mapping (as a finger on the
## stick or the pedals would give them).
func _cam_test_frame(dt: float) -> void:
	_cam_t += dt
	_cam_phase_t += dt
	var stick := Vector2.ZERO
	var gas := false
	var brake := false
	var kmh := absf(car.forward_speed) * 3.6
	var heading := _compass_yaw(car.rotation.y)
	if _cam_t < CAM_TEST_SETTLE:
		controls.drive(car, stick, false, {}, false, false, cam_yaw, dt)
		return
	var phase := _cam_phase
	match cam_test:
		"classic_turn":
			# Up to 50 km/h straight on, then a 90° right turn (a driver's hands: full lock until
			# 25° short, easing back to the middle), the gas keeping it near 50.
			gas = kmh < 50.0
			if _cam_phase == 0 and kmh >= 50.0:
				_cam_phase = 1
				_cam_aim = heading + 90.0
			if _cam_phase >= 1:
				var err := wrapf(_cam_aim - heading, -180.0, 180.0)
				stick = Vector2(clampf(err / 25.0, -1.0, 1.0), 0.0)
				if _cam_phase == 1 and absf(err) < 3.0:
					_cam_phase = 2
		"point_release":
			# Up to 50 km/h pointing straight up the screen, then the stick held to the screen's right
			# (90° right of the car: the camera is behind it) for 2.5 s, then let go.
			if _cam_phase == 0:
				stick = Vector2(0.0, -1.0)
				if kmh >= 50.0:
					_cam_phase = 1
			if _cam_phase == 1:
				stick = Vector2(1.0, 0.0)
				if _cam_phase_t >= 2.5:
					_cam_phase = 2
		"brake":
			# Flat out to 90 km/h, then the brake to a stop.
			if _cam_phase == 0:
				gas = true
				if kmh >= 90.0:
					_cam_phase = 1
			if _cam_phase == 1:
				# (Held on at a standstill the brake would reverse: let go once stopped.)
				brake = true
				if kmh < 0.5:
					_cam_phase = 2
					brake = false
	if _cam_phase != phase:
		_cam_phase_t = 0.0
		print("cam test: phase %d at %.2f s (frame %d), %.0f km/h, heading %03.0f°" % [_cam_phase, _cam_t - CAM_TEST_SETTLE,
				frame, kmh, heading])
	controls.drive(car, stick, stick != Vector2.ZERO, {}, gas, brake, cam_yaw, dt)


## Camera loop, --cam-log: one `cam:` line every CAM_LOG_EVERY frames (the turn rate is the
## fastest since the last line).
func _cam_log_frame(dt: float) -> void:
	if _cam_last_yaw != INF and dt > 0.0:
		_cam_turn_max = maxf(_cam_turn_max, absf(wrapf(cam_yaw - _cam_last_yaw, -180.0, 180.0)) / dt)
	_cam_last_yaw = cam_yaw
	# This frame's number as the screenshots count it (frame is counted up after the camera).
	var f := frame + 1
	if f % CAM_LOG_EVERY != 0:
		return
	var vehicle: Node3D = heli if flying else car
	var pos := vehicle.get_global_transform_interpolated().origin
	var screen := get_viewport().get_visible_rect().size
	var on := cam.unproject_position(pos) * float(view.stretch_shrink)
	var kmh: float = (heli.speed() if flying else absf(car.forward_speed)) * 3.6
	var held: bool = _heli_held if flying else controls.held or hud.stick_active()
	print("cam: frame %d %s %s%s finger %s | %3.0f km/h heading %05.1f° camera %05.1f° (off %+5.1f°) turning %3.0f°/s | car on screen %4.0f,%4.0f px (%+4.0f,%+4.0f from the middle) | view %5.1f m" % [
			f, "heli" if flying else Controls.KEYS[controls.scheme], "follow" if follow else "fixed",
			" test %s/%d" % [cam_test, _cam_phase] if cam_test != "" else "", "down" if held else "up", kmh,
			_compass_yaw(vehicle.rotation.y), _compass_yaw(deg_to_rad(cam_yaw)),
			wrapf(_compass_yaw(deg_to_rad(cam_yaw)) - _compass_yaw(vehicle.rotation.y), -180.0, 180.0), _cam_turn_max,
			on.x, on.y, on.x - screen.x * 0.5, on.y - screen.y * 0.5, cam.size])
	_cam_turn_max = 0.0


## A yaw (radians, rotation.y) as a compass heading in degrees (0 north, 90 east).
static func _compass_yaw(yaw: float) -> float:
	return fposmod(-rad_to_deg(yaw), 360.0)


## While the game is paused (settings) main.gd doesn't process: the frame count and the
## screenshots carry on here.
func _paused_frame() -> void:
	if not get_tree().paused or not _started:
		return
	frame += 1
	_inject_clicks()
	if frame in shots:
		_capture(frame)


## --clicks: press on frame F, release on F + 2 (through Input, as a real click would come).
func _inject_clicks() -> void:
	for c in clicks:
		if frame != c.z and frame != c.z + 2:
			continue
		var e := InputEventMouseButton.new()
		e.button_index = MOUSE_BUTTON_LEFT
		e.position = Vector2(c.x, c.y)
		e.global_position = e.position
		e.pressed = frame == c.z
		e.button_mask = MOUSE_BUTTON_MASK_LEFT if e.pressed else 0
		Input.parse_input_event(e)
		print("click %s at %d,%d (frame %d)" % ["down" if e.pressed else "up", c.x, c.y, frame])
	for d in drags:
		var at := Vector2(d[0], d[1])
		var step := frame - d[2]
		if step < 0 or frame > d[5]:
			continue
		if step == 0 or frame == d[5]:
			var b := InputEventMouseButton.new()
			b.button_index = MOUSE_BUTTON_LEFT
			b.pressed = step == 0
			b.position = at + (Vector2(d[3], d[4]) if frame == d[5] else Vector2.ZERO)
			b.global_position = b.position
			b.button_mask = MOUSE_BUTTON_MASK_LEFT if b.pressed else 0
			Input.parse_input_event(b)
		elif step <= 10:
			var m := InputEventMouseMotion.new()
			m.button_mask = MOUSE_BUTTON_MASK_LEFT
			m.position = at + Vector2(d[3], d[4]) * (step / 10.0)
			m.global_position = m.position
			m.relative = Vector2(d[3], d[4]) / 10.0
			Input.parse_input_event(m)


func _next_style() -> void:
	style_index = (style_index + 1) % STYLES.size()
	settings.style = style_index
	settings.save()
	_apply_style()


func _apply_style() -> void:
	var style: Dictionary = STYLES[style_index]
	var screen := get_viewport().get_visible_rect().size
	# Loop G1: the quality's step and budget (tiers.gd image_scale); --lines= is exact.
	if lines_override > 0:
		view.stretch_shrink = maxi(1, floori(screen.y / lines_override))
	elif quality_choice == Tiers.AUTO:
		# Loop G1b: Auto draws the style's own scale where the budget binds, unless this launch
		# is the fallback.
		view.stretch_shrink = Tiers.auto_scale(screen, style["lines"], quality, auto_sharp)
	else:
		view.stretch_shrink = Tiers.image_scale(screen, style["lines"], quality)
	post_mat.set_shader_parameter("outline_strength", style["outline"])
	post_mat.set_shader_parameter("levels", style["levels"])
	post_mat.set_shader_parameter("saturation", style["saturation"])
	# Loop G1b: the governor's tally counts only at Auto's image; the `quality:` line when it changes.
	var mode := _image_mode()
	governor.track = mode != ""
	var line := Tiers.describe(quality_choice, quality, model_name, view.stretch_shrink, mode)
	if mode == "fallback":
		line = line.replace("(%s)" % model_name, "(last session: %s) · %s · the sharp image again after %d calm sessions (%d so far)" % [
				auto_image["why"], model_name, auto_image["wait"], auto_image["calm"]])
	elif mode == "sharp" and int(auto_image["trial"]) >= 0:
		line += " · on trial: calm %d of %d (a struggle first doubles the wait)" % [auto_image["trial"], auto_image["wait"]]
	line += " · image %dx%d" % [int(screen.x) / view.stretch_shrink, int(screen.y) / view.stretch_shrink]
	if line != _quality_line:
		_quality_line = line
		print("quality: " + line)


func _process(dt: float) -> void:
	if not _started:
		return
	var t_main := Time.get_ticks_usec()
	if bench or probe:
		_bench_frame()
	_read_input(dt)
	_water_frame(dt)
	if autopilot or _bench_ghost != null:
		_autopilot(dt)
	_update_camera(dt)
	_stream_frame(dt)  # loop 3c: the sectors round the camera
	if cam_log:
		_cam_log_frame(dt)
	var pos := _vehicle_position()
	_xray.show_through(not flying and map.in_tunnel(pos.x, pos.z, pos.y))
	# Loop 3d-1: the pedestrian zones cap the player's car (police.md 5.6); the log says when.
	var zone: String = ped_zones.at(car.global_position.x, car.global_position.z) if ped_zones != null and not flying else ""
	car.zone_cap = PedZones.CAP if zone != "" else INF
	if zone != _zone:
		print("zone: %s at %.0f km/h" % [(zone + " (20 km/h)") if zone != "" else "left " + _zone, absf(car.forward_speed) * 3.6])
		_zone = zone
	_feed_life(pos)
	if police != null:
		police.flying = flying  # loop 3g-1: the police ignore the helicopter
	if jobs != null:
		# Loop 2b: no side job starts on the bench route (the ghost stops at red lights).
		jobs.flying = flying or _bench_ghost != null
		# Loop 2d-1: no ride is offered from the helicopter, on the title screen or the bench.
		rides.flying = flying
		rides.away = title != null or _bench_ghost != null or _phone_bench
		eggs.player = pos
		eggs.player_vel = heli.vel if flying else car.vel
		eggs.flying = flying
	car.lights = tod.lights_on
	heli.lights = tod.lights_on
	car.wet = weather.wet
	if sfx != null:
		sfx.flying = flying
		sfx.focus = cam_focus
		sfx.yaw = cam_yaw
	if weather.amount > 0.0:
		# The rain streaks drift with the view a little (parallax), in image pixels.
		var px := float(maxi(sv.size.y, 1)) / cam.size
		var b := cam.global_transform.basis
		post_mat.set_shader_parameter("rain_shift", Vector2(cam_focus.dot(b.x), -cam_focus.dot(b.y)) * px)
	var minute := int(tod.now_utc() / 60.0)
	if minute != _clock_minute:
		_clock_minute = minute
		_set_palace_clock()
	# Loop 2e: the minimap's night palette follows the lamps (dusk is half way).
	hud.set_night(tod.lights_on)
	if _phone_bench:
		_phone_bench_frame()
	if show_perf:
		_update_perf(dt)
	# Loop 2e: the speed beside the gear (the "prototype" label is gone).
	if flying:
		hud.set_speed(roundi(heli.speed() * 3.6), roundi(heli.height_above))
		missions.tick(dt, pos, heli.speed(), true)
	else:
		hud.set_speed(roundi(absf(car.forward_speed) * 3.6))
		missions.tick(dt, pos, car.vel.length(), false)
	_show_target()
	var heading: float = heli.rotation.y if flying else car.rotation.y
	hud.update_minimap(Vector2(pos.x, pos.z), heading, deg_to_rad(cam_yaw))
	# The see-through hole: aimed at the cabin and smaller for the helicopter, which is
	# rarely hidden; a full-size one cuts into the roof edge it has landed on.
	var car_view := cam.global_transform.affine_inverse() * (pos + Vector3(0, 3.5 if flying else 1.0, 0))
	var hole := clampf(cam.size * 0.11, 7.0, 20.0) * (0.55 if flying else 1.0)
	building_mat.set_shader_parameter("fade_radius", hole)
	_update_ghost(pos, car_view)
	for m in map.fade_materials:
		m.set_shader_parameter("car_view", car_view)
		m.set_shader_parameter("fade_radius", hole * 0.8)
	_rotor_wash()
	_fine_detail()
	# A small marker over the vehicle once the view is wide enough to lose it.
	var marker := cam.unproject_position(pos + Vector3(0, 4.5 if flying else 2.0, 0)) * float(view.stretch_shrink)
	hud.set_car_marker(marker, cam.size > 55.0)

	frame += 1
	_inject_clicks()
	if frame == 60 and tap_at != Vector2.INF:
		_on_tap(tap_at)
	if frame == 60 and bench_button:
		_start_phone_bench()
	if frame in shots:
		_capture(frame)
	_govern()
	_main_usec = Time.get_ticks_usec() - t_main
	# Loop G1, --stress=cpu: after the game loop's own time is taken (the load isn't the game's).
	if _stress_kind == "cpu" and _stressing():
		_busy(_stress_n)


## The occlusion ghost (ghost.gdshaderinc, loop 1): what stands on the camera's side of
## the vehicle and covers it and its surroundings on screen keeps only a thin dither
## (building.gdshader); the ground lifts the buildings' baked shade there and gives a
## ghosted footprint the sunlight its building takes (ground.gdshader); the post pass
## leaves the ghost's pixels without outlines. The same values go to all three.
func _update_ghost(pos: Vector3, car_view: Vector3) -> void:
	var ahead := -cam.global_transform.basis.z
	var ahead_xz := Vector2(ahead.x, ahead.z).normalized()
	var occ := Vector4(pos.x, pos.z, ahead_xz.x, ahead_xz.y)
	var ghost_r := clampf(cam.size * 0.22, 14.0, 50.0) * (0.6 if flying else 1.0)
	for m: ShaderMaterial in [building_mat, map.flat_material, post_mat] + _neon_materials():  # sweep 2: + neon
		m.set_shader_parameter("car_view", car_view)
		m.set_shader_parameter("occluder", occ)
		m.set_shader_parameter("occlusion_radius", ghost_r)
	# The sun a ghosted footprint gets back: none without shadows (the night's moon, Low
	# quality: it is lit already), all of it with a high sun, less when it is low (the
	# streets round it lie in long shadows then).
	var to_sun := sun.global_transform.basis.z
	var elevation := rad_to_deg(asin(clampf(to_sun.y, -1.0, 1.0)))
	var give := 0.0
	if sun.visible and sun.shadow_enabled:
		give = sun.shadow_opacity * smoothstep(GHOST_SUN_LOW, GHOST_SUN_HIGH, elevation)
	var lc := sun.light_color.srgb_to_linear()
	map.flat_material.set_shader_parameter("ghost_sun", Vector3(lc.r, lc.g, lc.b) * sun.light_energy * give * GHOST_SUN_SCALE)
	map.flat_material.set_shader_parameter("ghost_sun_dir", to_sun)
	if ghost_debug > 0:
		building_mat.set_shader_parameter("ghost_debug", ghost_debug)
		var ppm := float(sv.size.y) / cam.size * float(view.stretch_shrink)
		var c := cam.unproject_position(pos + Vector3(0, 3.5 if flying else 1.0, 0)) * float(view.stretch_shrink)
		_ghost_px = Vector4(c.x, c.y - 0.2 * ghost_r * ppm, ghost_r / 0.78 * ppm, ghost_r * ppm)


# --- sweep 2: the neon signs are ghosted too ------------------------------------------------
## The neon signs' material (neon.gdshader, shared by the map node "Neon"'s tiles), found on
## the first ghost update on either city path; empty when the map has no signs.
var _neon_mats: Array[ShaderMaterial] = []
var _neon_found := false


func _neon_materials() -> Array[ShaderMaterial]:
	if not _neon_found:
		_neon_found = true
		var holder := map.get_node_or_null("Neon")
		if holder != null:
			for c in holder.get_children():
				var g := c as GeometryInstance3D
				var m := g.material_override as ShaderMaterial if g != null else null
				if m != null and not _neon_mats.has(m):
					_neon_mats.append(m)
	return _neon_mats
# --- end sweep 2 ---------------------------------------------------------------------------


## Loop 1: the Palace of Culture's four dials show the time in Warsaw (the device's clock,
## or --clock= / --date=), drawn by building.gdshader; called when the minute changes.
func _set_palace_clock() -> void:
	var t := tod.now_utc()
	var local := Time.get_datetime_dict_from_unix_time(int(t) + TimeOfDay.warsaw_offset(t))
	var minutes := float(local["minute"])
	var hours := float(int(local["hour"]) % 12) + minutes / 60.0
	building_mat.set_shader_parameter("clock_hands", Vector2(TAU * hours / 12.0, TAU * minutes / 60.0))


## Where the player is, for traffic (obstacle, spawn band), trams and rivals.
func _feed_life(pos: Vector3) -> void:
	if traffic == null:
		return
	var ground: Vector3 = car.global_position if not flying else Vector3(pos.x, map.ground_height(pos.x, pos.z), pos.z)
	traffic.player_pos = ground
	traffic.player_vel = car.vel if not flying else Vector3.ZERO
	traffic.player_on_road = not flying
	trams.player_pos = ground
	trams.player_on_road = not flying
	rivals.flying = flying


## --bench: 300 frames to settle (traffic fills in), then the average of 600 (--bench-frames=)
## on the ghost route; --probe: the same where the car stands. Wall-clock time between frames,
## not dt (delta smoothing snaps dt to the display's refresh interval). The first line keeps
## the format of the bench before loop 2b, so old and new code compare like with like.
func _bench_frame() -> void:
	if _bench_done:
		return
	if _measure_t0 == 0:
		if frame < _bench_settle and Time.get_ticks_msec() - _bench_t0 < SETTLE_SECONDS * 1000.0:
			return
		_measure_t0 = Time.get_ticks_msec()
		_stats.start()
		return
	_stats.sample()
	if sfx != null:
		var peaks := Sfx.bus_peaks()
		for bus in _meters:
			_meters[bus] += peaks[bus]
			_meter_top[bus] = maxf(_meter_top[bus], peaks[bus])
	if _stats.frames.size() < _bench_frames and Time.get_ticks_msec() - _measure_t0 < _bench_seconds * 1000.0:
		return
	_bench_done = true
	var r := _stats.report()
	var n := float(_stats.frames.size())
	var us := func(k: String) -> float: return r.get("us:" + k, 0.0) / 1000.0
	var what := "probe" if probe else "bench"
	print("%s: %.2f ms/frame (%.0f fps, worst %.1f ms) over %d frames · scripts: traffic %.2f + trams %.2f + people %.2f = %.2f ms, side jobs + eggs %.3f ms, sound %.3f ms · 3D view: GPU %.2f ms, render CPU %.2f ms · %.0f cars on screen, %.0f driving · %s · %s · %s · quality %s" % [
			what, r["ms"], r["fps"], r["worst"], r["frames"],
			us.call("traffic"), us.call("trams"), us.call("people"), us.call("traffic") + us.call("trams") + us.call("people"),
			us.call("jobs+eggs"), us.call("sound"), r["gpu"], r["render_cpu"],
			r.get("n:cars on screen", 0.0), r.get("n:driving", 0.0), "no traffic" if traffic == null else "traffic on", TimeOfDay.NAMES[tod.mode],
			Weather.NAMES[weather.state], QUALITY[quality]["name"] + " · traffic " + Settings.TRAFFIC_NAMES[traffic_level]])
	_stats.header = _bench_header("probe" if probe else "bench route (--bench)")
	_stats.notes = _governor_notes()
	var text := _stats.text(r)
	for line in text.split("\n"):
		print("%s detail: %s" % [what, line])
	_print_old_late(r)
	if probe:
		print("probe view: %s" % _view_census())
	_write_bench_result(text)
	print("bench audio peaks, mean / loudest dBFS (-200 = silent or no audio device): Master %.1f / %.1f · Music (radio) %.1f / %.1f · SFX %.1f / %.1f · Ambience %.1f / %.1f" % [
			_meters["Master"] / n, _meter_top["Master"], _meters["Music"] / n, _meter_top["Music"],
			_meters["SFX"] / n, _meter_top["SFX"], _meters["Ambience"] / n, _meter_top["Ambience"]])
	get_tree().quit()


## Loop 2b: the bench's sources: what each system's script costs a frame, how many cars and
## people there are.
func _make_stats() -> BenchStats:
	var b := BenchStats.new()
	b.view_rid = sv.get_viewport_rid()
	b.screen_rid = get_viewport().get_viewport_rid()
	if traffic != null:
		b.systems["traffic"] = [traffic, "last_usec", false]
		b.systems["traffic bodies"] = [traffic, "spent_usec", true]
		b.systems["trams"] = [trams, "last_usec", false]
		b.systems["people"] = [walkers, "last_usec", false]
		b.systems["rivals"] = [rivals, "spent_usec", true]
		b.counts["cars on screen"] = func() -> int: return traffic.visible_count
		b.counts["driving"] = func() -> int: return traffic.drivers().size()
		b.counts["people"] = func() -> int: return walkers.alive_count()
	if jobs != null:
		b.systems["jobs+eggs"] = [self, "_jobs_usec", false]
		b.systems["jobs physics"] = [jobs, "spent_usec", true]
		b.systems["rides physics"] = [rides, "spent_usec", true]  # loop 2d-1
	b.systems["sound"] = [sfx, "last_usec", false]
	b.systems["hud+minimap"] = [hud, "spent_usec", true]
	b.systems["bubbles"] = [bubbles, "spent_usec", true]
	b.systems["dialogue"] = [dialogue, "spent_usec", true]
	b.systems["weather+time"] = [self, "_sky_usec", false]
	b.systems["car physics"] = [car, "spent_usec", true]
	b.systems["heli"] = [heli, "spent_usec", true]
	b.systems["game loop"] = [self, "_main_usec", false]
	return b


## jobs.gd and eggs.gd, weather.gd and time_of_day.gd, read as one each.
var _jobs_usec: int:
	get:
		return (jobs.last_usec + eggs.last_usec + (rides.last_usec if rides != null else 0)) if jobs != null else 0
var _sky_usec: int:
	get:
		var t: int = weather.spent_usec + tod.spent_usec
		weather.spent_usec = 0
		tod.spent_usec = 0
		return t


## Loop 2b, --exp=a,b: switch one cost off to see what it costs (ranking the frame).
func _apply_experiments() -> void:
	for e in _exp:
		match e:
			"nohud":
				hud.visible = false
			"nominimap":
				hud.get("_minimap").visible = false
			"nobubbles":
				bubbles.visible = false
			"noshadow":
				tod.shadows_allowed = false
				tod.refresh()
			"nopost":
				cam.get_child(0).visible = false
			"notrees", "noprops", "nosmallcasters":
				for c in map.get_children():
					var mmi := c as MultiMeshInstance3D
					if mmi == null:
						continue
					var leaf: bool = mmi.material_override == map.leaf_material
					if e == "notrees" and leaf:
						mmi.visible = false
					elif e == "noprops" and not leaf:
						mmi.visible = false
					elif e == "nosmallcasters":
						mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			"nocasters":
				for c in map.get_children():
					if c is GeometryInstance3D:
						(c as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			_:
				if e.begins_with("shadowdist="):
					sun.directional_shadow_max_distance = float(e.trim_prefix("shadowdist="))
				elif e.begins_with("shadowsize="):
					RenderingServer.directional_shadow_atlas_set_size(int(e.trim_prefix("shadowsize=")), true)
		print("experiment: ", e)


## Loop 2b, --probe: what stands in the camera's view: nodes and instances, shadow casters,
## distinct materials and shaders (each shader brings its own pipelines).
func _view_census() -> String:
	var planes := cam.get_frustum()
	var mats := {}
	var shaders := {}
	var nodes := 0
	var instances := 0
	var casters := 0
	var caster_instances := 0
	var kinds := {}
	var stack: Array[Node] = [sv]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children():
			stack.append(c)
		var g := n as GeometryInstance3D
		if g == null or not g.is_visible_in_tree():
			continue
		var box: AABB = g.global_transform * g.get_aabb()
		var inside := true
		for pl: Plane in planes:
			# Outside when every corner lies in front of one of the frustum's planes.
			var out := true
			for k in 8:
				if not pl.is_point_over(box.get_endpoint(k)):
					out = false
					break
			if out:
				inside = false
				break
		if not inside:
			continue
		nodes += 1
		var count := 1
		var mesh: Mesh = (g as MeshInstance3D).mesh if g is MeshInstance3D else null
		if g is MultiMeshInstance3D:
			var mm := (g as MultiMeshInstance3D).multimesh
			count = mm.visible_instance_count if mm.visible_instance_count >= 0 else mm.instance_count
			mesh = mm.mesh
		var mat_name := "-"
		if g.material_override is ShaderMaterial:
			mat_name = (g.material_override as ShaderMaterial).shader.resource_path.get_file().get_basename()
		elif g.material_override != null:
			mat_name = g.material_override.get_class()
		var kind := "%s %s %s %d" % ["MMI" if g is MultiMeshInstance3D else g.get_class(), mat_name,
				g.get_parent().name.left(12), mesh.get_surface_count() if mesh != null else 0]
		if mesh is ArrayMesh and mesh.get_surface_count() > 0 and g is MultiMeshInstance3D:
			kind += " v%d" % mesh.surface_get_array_len(0)
		kinds[kind] = kinds.get(kind, 0) + 1
		instances += count
		if g.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF:
			casters += 1
			caster_instances += count
		var list: Array[Material] = []
		if g.material_override != null:
			list.append(g.material_override)
		elif g is MeshInstance3D and (g as MeshInstance3D).mesh != null:
			var mi := g as MeshInstance3D
			for k in mi.mesh.get_surface_count():
				var m := mi.get_active_material(k)
				if m != null:
					list.append(m)
		for m in list:
			mats[m.get_instance_id()] = true
			shaders[(m as ShaderMaterial).shader.resource_path.get_file() if m is ShaderMaterial else m.get_class()] = true
	var parts := PackedStringArray()
	for k in kinds:
		parts.append("%s ×%d" % [k, kinds[k]])
	return "%d nodes (%d instances) in view, %d shadow-casting nodes (%d instances), %d materials, %d shaders: %s\nprobe kinds: %s" % [
			nodes, instances, casters, caster_instances, mats.size(), shaders.size(), ", ".join(PackedStringArray(shaders.keys())),
			" | ".join(parts)]


func _vehicle_position() -> Vector3:
	return heli.global_position if flying else car.global_position


## The arrow and minimap dot for the mission target.
func _show_target() -> void:
	if rivals != null and rivals.has_target():
		var f: Vector3 = rivals.target_position()
		var p := _vehicle_position()
		var m := roundi(Vector2(f.x - p.x, f.z - p.z).length())
		var on := cam.unproject_position(f + Vector3(0, 3.5, 0)) * float(view.stretch_shrink)
		hud.set_target(on, "%d m" % m, rivals.target_colour(), m > 12)
		hud.set_minimap_target(Vector2(f.x, f.z), rivals.target_colour())
		_new_target("race", f)
		return
	# Loop 2d-1: a Podwózka ride's pin, passenger or door.
	if rides != null and rides.has_target():
		var rp: Vector3 = rides.target_position()
		var at_r := _vehicle_position()
		var mr := roundi(Vector2(rp.x - at_r.x, rp.z - at_r.z).length())
		var on_r := cam.unproject_position(rp + Vector3(0, 3.5, 0)) * float(view.stretch_shrink)
		hud.set_target(on_r, "%d m" % mr, rides.target_colour(), mr > 12)
		hud.set_minimap_target(Vector2(rp.x, rp.z), rides.target_colour())
		_new_target("job", rp)
		return
	if jobs != null and jobs.has_target():
		var j: Vector3 = jobs.target_position()
		var at_j := _vehicle_position()
		var mj := roundi(Vector2(j.x - at_j.x, j.z - at_j.z).length())
		var on_j := cam.unproject_position(j + Vector3(0, 3.5, 0)) * float(view.stretch_shrink)
		hud.set_target(on_j, "%d m" % mj, jobs.target_colour(), mj > 12)
		hud.set_minimap_target(Vector2(j.x, j.z), jobs.target_colour())
		_new_target("job", j)
		return
	if not missions.has_target():
		hud.set_target(Vector2.ZERO, "", Color.WHITE, false)
		hud.set_minimap_target(Vector2.INF, Color.WHITE)
		_last_target_source = ""
		return
	var t: Vector3 = missions.target_position()
	var colour: Color = missions.target_colour()
	var pos := _vehicle_position()
	var metres := roundi(Vector2(t.x - pos.x, t.z - pos.z).length())
	var at := cam.unproject_position(t + Vector3(0, 3.5, 0)) * float(view.stretch_shrink)
	# Up close the ring says enough, and the pointer would sit on the vehicle's own marker.
	hud.set_target(at, "%d m" % metres, colour, metres > 12)
	hud.set_minimap_target(Vector2(t.x, t.z), colour)
	_new_target("rescue", t)


## Camera loop: a new rescue or delivery target (not a race's: they come one after another) gets a
## short look and back (camera_shots.gd), when the vehicle is slow (under LOOK_SPEED) and no
## finger or pedal is down (a held stick keeps the camera on the car), and not straight after
## the fly-in or another look.
const LOOK_SPEED := 30.0 / 3.6


func _new_target(source: String, t: Vector3) -> void:
	var fresh := source != _last_target_source or _last_target == Vector3.INF \
			or Vector2(t.x - _last_target.x, t.z - _last_target.z).length() > 30.0
	_last_target_source = source
	_last_target = t
	if not fresh or not cinematic_look or source == "race" or moments == null or moments.playing():
		return
	if title != null or _phone_bench or cam_test != "":
		return
	var p := _vehicle_position()
	var speed: float = heli.speed() if flying else absf(car.forward_speed)
	var busy: bool = hud.stick_active() or controls.held or hud.gas or hud.brake or _heli_held
	if speed > LOOK_SPEED or busy or Vector2(t.x - p.x, t.z - p.z).length() < CameraShots.NEAR:
		return
	var ground := Vector3(p.x, map.ground_height(p.x, p.z), p.z) if flying else p
	var screen := get_viewport().get_visible_rect().size
	moments.look_at_target(ground, t, cam_yaw, camera_pitch, _view_size, screen.x / maxf(screen.y, 1.0))


## Loop 2b: benches, bins and bike racks (map_builder.gd FINE_GROUP) hide in a view wider than
## FINE_VIEW metres (a bin is under two pixels there), back below 0.9 of it.
const FINE_VIEW := 170.0
var _fine_shown := true


func _fine_detail() -> void:
	var show := cam.size < (FINE_VIEW if _fine_shown else FINE_VIEW * 0.9)
	if show != _fine_shown:
		_fine_shown = show
		get_tree().call_group(MapBuilder.FINE_GROUP, "set_visible", show)


## Tree crowns near a low helicopter shake in the downwash.
func _rotor_wash() -> void:
	var strength := 0.0
	if flying:
		strength = clampf(1.0 - heli.height_above / 30.0, 0.0, 1.0)
	if strength > 0.0 or _wash_on:
		var p := heli.global_position
		map.leaf_material.set_shader_parameter("wash", Vector3(p.x, p.z, strength))
		_wash_on = strength > 0.0


func _read_input(dt: float) -> void:
	if title != null:
		# The title screen is up: the car waits, parked (loop 2b: it no longer reverses).
		car.target_dir = Vector3.ZERO
		car.steer = 0.0
		car.throttle = 0.0
		car.braking = true
		car.parked = true
		controls.release()
		return
	car.parked = flying
	var left := Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)
	var right := Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)
	var gas := Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)
	var down := Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)
	var space := Input.is_physical_key_pressed(KEY_SPACE)
	if Input.is_action_just_pressed("ui_page_up"):
		cam_yaw_target -= 90.0

	if flying:
		# The car waits where it was left.
		car.target_dir = Vector3.ZERO
		car.steer = 0.0
		car.throttle = 0.0
		car.braking = true
		controls.release()
		_read_heli_input(left, right, gas, down, dt)
		return

	if cam_test != "":
		_cam_test_frame(dt)
		return
	# Loop 2a: the scheme maps the stick, keys and pedals (drive_controls.gd): Point / Fixed
	# point in screen space (the camera waits while held), Classic steers car-relative.
	var keys := {"left": left, "right": right, "up": gas, "down": down, "brake": space}
	controls.drive(car, hud.stick, hud.stick_active(), keys, hud.gas, hud.brake, cam_yaw, dt)
	# Loop 3g-1: a pull-over holds the car; the police's test drivers (--police-auto, --trap with
	# --pedal=gas, the soak's roaming autopilot) drive it.
	if police != null and police.control_car(car, dt):
		return

	if demo:
		car.target_dir = Vector3.ZERO
		car.throttle = 0.8
		car.steer = 0.0 if frame < 200 else 0.5 * sin(frame * 0.02)
	if water_test == 1 or water_test == 2:
		_water_test_frame()


## The stick and W A S D both point in screen space (W is up the screen); Space /
## Shift (or F) or the ▲ ▼ pads climb and sink.
func _read_heli_input(left: bool, right: bool, up: bool, down: bool, dt: float) -> void:
	var stick: Vector2 = hud.stick
	var aim := Vector2(float(right) - float(left), float(down) - float(up))
	# Loop 2a: while the stick or a key is held the follow camera waits (as in Point), so a
	# held direction doesn't turn with the view.
	_heli_held = hud.stick_active() or aim != Vector2.ZERO
	_heli_release = 0.0 if _heli_held else _heli_release + dt
	if stick.length() > 0.2:
		aim = stick.normalized() * clampf((stick.length() - 0.2) / 0.8, 0.0, 1.0)
	elif aim != Vector2.ZERO:
		aim = aim.normalized()
	heli.input_dir = _screen_to_world(aim)
	var climb := float(Input.is_physical_key_pressed(KEY_SPACE)) \
			- float(Input.is_physical_key_pressed(KEY_SHIFT) or Input.is_physical_key_pressed(KEY_F))
	heli.climb = clampf(climb + hud.climb, -1.0, 1.0)
	if demo and not autopilot:
		# A slow circle at cruise height, for screenshots.
		var a := frame * 0.0035
		heli.input_dir = Vector3(cos(a), 0.0, sin(a)) * 0.55
		heli.climb = 0.0


## Testing aid (--autopilot): heads for the mission target. The helicopter climbs
## over whatever blocks it and comes straight down onto the target; the car slides
## there in a straight line, ignoring walls.
func _autopilot(dt: float) -> void:
	if _bench_ghost != null:
		_follow(_bench_ghost)
		return
	if rivals != null and rivals.drive_player():
		return
	if rides != null and rides.drive_player():
		return  # loop 2d-1
	if jobs != null and jobs.drive_player():
		return
	if not missions.has_target():
		if flying:
			heli.input_dir = Vector3.ZERO
		return
	if missions.needs_heli() and not flying:
		_take_off(Heli.CRUISE)
	var t: Vector3 = missions.target_position()
	var pos := _vehicle_position()
	var to := Vector3(t.x - pos.x, 0.0, t.z - pos.z)
	var d := to.length()
	if flying:
		heli.input_dir = to / maxf(d, 0.001) * clampf(d / 80.0, 0.0, 1.0)
		var ground: float = map.ground_height(pos.x, pos.z)
		var cruise := maxf(Heli.CRUISE, t.y - ground + 20.0)
		if heli.blocked or (d > 6.0 and heli.alt_target < cruise - 1.0):
			heli.climb = 1.0
		elif d < 6.0:
			heli.climb = -1.0
		else:
			heli.climb = 0.0
		return
	car.collision_mask = 0
	car.vel = Vector3.ZERO
	car.throttle = 0.0
	if d > 0.5:
		var step := minf(d, 22.0 * dt)
		car.global_position += to / d * step
		car.rotation.y = atan2(-to.x, -to.z)


## The player's car rides on a ghost driver (the bench route).
func _follow(d) -> void:
	car.collision_mask = 0
	car.global_position = d.pos
	car.rotation.y = d.yaw
	car.vel = Vector3(-sin(d.yaw), 0.0, -cos(d.yaw)) * d.v
	car.throttle = 0.0
	car.braking = false
	car.target_dir = Vector3.ZERO
	car.reset_physics_interpolation()


## H or the HELI / CAR button: take off from the car, or land and take the car back.
func _toggle_vehicle() -> void:
	if _phone_bench:
		return
	if rivals != null and rivals.racing():
		hud.toast("Najpierw dokończ wyścig", "Finish the race first")
		return
	if jobs != null and jobs.busy() and not flying:
		hud.toast("Najpierw dokończ kurs: zamówienie jedzie autem", "Finish the job first: it rides in the car")
		return
	if not flying and car.in_water:
		return  # loop 10a: the tow is on its way
	if not flying:
		_take_off(Heli.CRUISE)
		hud.toast("Helikopter: kieruj palcem, ▲ ▼ to wysokość", "Helicopter: steer with the stick, ▲ ▼ (Space / Shift) for height")
		return
	if heli.landing:
		heli.landing = false
		hud.toast("Lądowanie odwołane", "Landing cancelled")
		return
	var why := _landing_problem(heli.global_position)
	if not why.is_empty():
		hud.toast(why[0], why[1])
		return
	heli.landing = true
	hud.toast("Lądujemy…", "Landing…")


## Why the helicopter can't come down at `p` to give the car back: [] if it can, else the toast
## [text, gloss, "roof" | "water"]. Over a roof (v0.5), or, loop 10a, over the water (the car would come back in
## the river; a bridge deck over it is fine, and so is the shallow first metres by the bank:
## the car is put on dry ground next to it).
func _landing_problem(p: Vector3) -> Array:
	if map.top_height(p.x, p.z, Heli.RADIUS) > map.ground_height(p.x, p.z) + 1.0:
		return ["Wyląduj na otwartym terenie, żeby wziąć auto.", "Land on open ground to take the car.", "roof"]
	if map.in_water(p.x, p.z, map.ground_height(p.x, p.z)):
		return ["Tu nie wylądujesz: to woda. Szukaj brzegu.", "No landing on the water: find the bank.", "water"]
	return []


## The helicopter starts just above the car and rises to `height` above the ground.
func _take_off(height: float) -> void:
	var p := car.global_position
	# From the ground, not the car's y: with --at the car hasn't been set down yet.
	var ground: float = map.ground_height(p.x, p.z)
	heli.place(Vector3(p.x, ground + minf(height, 6.0), p.z), car.rotation.y, height)
	_set_flying(true)


## Touched down: the car comes back on a free spot next to the helicopter.
func _on_heli_landed() -> void:
	var p: Vector3 = heli.global_position
	var spot := _free_car_spot(p, heli.rotation.y)
	car.global_position = spot
	car.rotation.y = heli.rotation.y
	car.vel = Vector3.ZERO
	car.forward_speed = 0.0
	car.reset_physics_interpolation()
	_set_flying(false)


func _set_flying(on: bool) -> void:
	flying = on
	heli.visible = on
	heli.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	heli.input_dir = Vector3.ZERO
	heli.climb = 0.0
	hud.set_flying(on)


## The nearest spot to `p` where the car's box touches no wall, parked car or
## prop: rings of candidates 4 m apart, checked with one shape query each. Loop 10a: on the
## level of `p` (it was the top deck over each candidate: a tow under a bridge put the car up
## on it), and never in the water.
func _free_car_spot(p: Vector3, yaw: float) -> Vector3:
	var space := car.get_world_3d().direct_space_state
	var query := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.2, 1.0, 4.4)
	query.shape = box
	query.exclude = [car.get_rid()]
	var r := 0.0
	while r <= 24.0:
		var steps := 1 if r == 0.0 else 12
		for k in steps:
			var a := TAU * k / steps
			var x := p.x + cos(a) * r
			var z := p.z + sin(a) * r
			var y: float = map.drive_height(x, z, p.y + 0.5)
			if map.in_water(x, z, y):
				continue
			query.transform = Transform3D(Basis(Vector3.UP, yaw), Vector3(x, y + 0.9, z))
			if space.intersect_shape(query, 1).is_empty():
				return Vector3(x, y, z)
		r += 4.0
	# Nothing free and dry within 24 m (out in the water): once more round the nearest dry ground.
	var dry: Vector2 = map.nearest_dry(p.x, p.z)
	if dry != Vector2(p.x, p.z):
		return _free_car_spot(Vector3(dry.x, map.terrain_height(dry.x, dry.y), dry.y), yaw)
	return Vector3(p.x, map.drive_height(p.x, p.z, p.y + 0.5), p.z)


## v0.8: a tap (or click) on a landmark shows its info card. The ray from the tapped
## pixel walks the roof grid (map_builder.pick_landmark) until it meets something
## standing; only a landmark answers.
func _on_tap(at: Vector2) -> void:
	if not _started or title != null:
		return
	var p := at / float(view.stretch_shrink)
	var k: int = _pick_unghosted(cam.project_ray_origin(p), cam.project_ray_normal(p))  # sweep 2
	if k < 0 or k >= map.landmark_info.size():
		return
	print("landmark tapped: ", map.landmark_info[k]["name"])
	var card: Dictionary = map.landmark_info[k]
	hud.show_info(card["name"], card["pl"], card["en"])


# --- sweep 2: a tap sees through the ghost --------------------------------------------------
## A roof-grid cell counts as see-through for a tap where the ghost takes at least this share
## of its pixels (building.gdshader keeps ghost_keep, 19 %, in the core).
const GHOST_PICK := 0.5


## Sweep 2: map_builder.pick_landmark's walk (1 m steps against the roof grid and the
## ground), stepping on through whatever the occlusion ghost has made see-through, so a tap
## on the cut-away part of a tower in front of the car picks what shows through the cut, not
## the tower. The ghost's test is ghost.gdshaderinc's, on the values _update_ghost gave
## building_mat; the camera is orthographic, so every point of the ray has the tapped
## pixel's view x, y and only the side of the car changes along it.
func _pick_unghosted(origin: Vector3, dir: Vector3) -> int:
	var radius := float(_shader_value(building_mat, "occlusion_radius", 0.0))
	var region := 0.0
	if radius > 0.0:
		var v := cam.global_transform.affine_inverse() * origin
		var car_v: Vector3 = _shader_value(building_mat, "car_view", Vector3(0, 0, -100000))
		var dv := (Vector2(v.x, v.y) - Vector2(car_v.x, car_v.y)) / radius \
				- Vector2(0.0, float(_shader_value(building_mat, "occlusion_lift", 0.2)))
		dv.x *= 0.78
		if dv.y > 0.0:
			dv.y /= float(_shader_value(building_mat, "occlusion_up", 1.35))
		region = 1.0 - smoothstep(0.65, 0.9, dv.length())
	if region < GHOST_PICK or dir.y > -0.01:
		return map.pick_landmark(origin, dir)
	var occ: Vector4 = _shader_value(building_mat, "occluder", Vector4(0, 0, 0, -1))
	var t := maxf(0.0, (origin.y - 340.0) / -dir.y)
	var end := t + 2600.0
	while t < end:
		var q := origin + dir * t
		var top: float = map.roof_height(q.x, q.z)
		if top != MapBuilder.NO_ROOF and q.y <= top:
			var side := (Vector2(q.x, q.z) - Vector2(occ.x, occ.y)).dot(Vector2(occ.z, occ.w))
			if region * smoothstep(1.0, 4.0, -side) < GHOST_PICK:
				return map.landmark_at(q.x, q.z)
		if q.y < map.terrain_height(q.x, q.z) - 0.5:
			return -1
		t += 1.0
	return -1


## A shader parameter's value on a material, or its shader's default when it was never set.
static func _shader_value(m: ShaderMaterial, key: String, fallback: Variant) -> Variant:
	var v: Variant = m.get_shader_parameter(key)
	if v == null and m.shader != null:
		v = RenderingServer.shader_get_parameter_default(m.shader.get_rid(), key)
	return fallback if v == null else v
# --- end sweep 2 ---------------------------------------------------------------------------


func _zoom(factor: float) -> void:
	base_size = clampf(base_size * factor, MIN_SIZE, MAX_SIZE)


func _unhandled_input(event: InputEvent) -> void:
	if not _started or title != null:
		return
	var wheel := event as InputEventMouseButton
	if wheel and wheel.pressed:
		if wheel.button_index == MOUSE_BUTTON_WHEEL_UP:
			_zoom(1.0 / 1.12)
		elif wheel.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_zoom(1.12)


func _unhandled_key_input(event: InputEvent) -> void:
	if not _started or title != null:
		return
	var key := event as InputEventKey
	if key and key.pressed and not key.echo:
		match key.physical_keycode:
			KEY_Q:
				_rotate_camera(-1)
			KEY_E:
				_rotate_camera(1)
			KEY_C:
				_toggle_follow()
			KEY_T:
				_next_style()
			KEY_H:
				_toggle_vehicle()
			KEY_M:
				# Loop 2d-1: a Podwózka request or result first.
				if (rides == null or not rides.primary()) and (jobs == null or not jobs.primary()):
					missions.primary()
			KEY_K:
				if (rides == null or not rides.secondary()) and (jobs == null or not jobs.secondary()):
					missions.secondary()
			KEY_N:
				_blip_sound()
				tod.next()
			KEY_R:
				radio.next()
			KEY_V:
				_blip_sound()
				_set_vhs(not vhs)
				settings.vhs = vhs
				settings.save()
			KEY_O:
				_blip_sound()
				weather.toggle()
			KEY_P:
				_set_perf(not show_perf)
				settings.perf = show_perf
				settings.save()
			KEY_ESCAPE:
				_open_settings()
			KEY_U:
				# Loop G1: Auto → Low → Medium → High → Ultra → Auto.
				_blip_sound()
				_set_quality(Tiers.AUTO if quality_choice >= Tiers.ULTRA else quality_choice + 1)
			KEY_L:
				if rivals != null:
					rivals.flash()
			KEY_MINUS:
				_zoom(1.3)
			KEY_EQUAL:
				_zoom(1.0 / 1.3)


func _screen_to_world(s: Vector2) -> Vector3:
	var right := cam.global_transform.basis.x
	right.y = 0.0
	var ahead := -cam.global_transform.basis.z
	ahead.y = 0.0
	return right.normalized() * s.x + ahead.normalized() * -s.y


func _update_camera(dt: float) -> void:
	var vehicle: Node3D = heli if flying else car
	var speed: float = heli.speed() if flying else absf(car.forward_speed)
	if follow:
		# Camera loop (follow_camera.gd): Point and the helicopter wait while the stick is held and
		# 0.6 s after, then ease round; Classic turns with the car; never faster than 64°/s.
		var heading := rad_to_deg(vehicle.rotation.y)
		if flying:
			cam_yaw = fcam.follow_yaw(cam_yaw, heading, speed, true, _heli_held, _heli_release,
					FollowCamera.FULL_SPEED_HELI, dt)
		else:
			var waits := controls.scheme != Controls.CLASSIC
			cam_yaw = fcam.follow_yaw(cam_yaw, heading, speed, waits, controls.held, controls.since_release,
					FollowCamera.FULL_SPEED_POINT if waits else FollowCamera.FULL_SPEED, dt)
		cam_yaw_target = cam_yaw
	else:
		fcam.stop_turning()
		cam_yaw = lerpf(cam_yaw, cam_yaw_target, 1.0 - exp(-8.0 * dt))
	var basis := Basis.from_euler(Vector3(deg_to_rad(camera_pitch), deg_to_rad(cam_yaw), 0.0))
	var focus := vehicle.get_global_transform_interpolated().origin
	focus.y += cam_lift
	var size: float
	var focus_rate := FollowCamera.FOCUS_RATE
	if flying:
		# Aim halfway down to the shadow so both stay in view, and widen the view
		# a little, more when flying above the usual height.
		focus.y -= heli.height_above * 0.5
		var heli_view := base_size * HELI_VIEW + maxf(heli.height_above - Heli.CRUISE, 0.0) * 0.8
		var heli_zoom := base_size * HELI_VIEW * 0.2 * clampf(speed / Heli.MAX_SPEED, 0.0, 1.0)
		size = heli_view + heli_zoom
		_view_size = fcam.zoom_step(_view_size, heli_view, heli_zoom, dt)
		focus_rate = 3.5
	else:
		var zoom := base_size * FollowCamera.SPEED_ZOOM * clampf(speed / car.max_speed, 0.0, 1.0)
		size = base_size + zoom
		_view_size = fcam.zoom_step(_view_size, base_size, zoom, dt)
	# The look-ahead along the way it goes, and the dead zone's window (follow_camera.gd).
	var forward := Vector3(-basis.z.x, 0.0, -basis.z.z).normalized() \
			if follow and not flying and controls.scheme == Controls.CLASSIC else Vector3.ZERO
	var lead := fcam.lead_step(heli.vel if flying else car.vel, Heli.MAX_SPEED if flying else car.max_speed,
			_view_size, dt, forward)
	cam_focus = fcam.focus_step(cam_focus, focus + lead, basis, _view_size, focus_rate, dt)

	var distance := maxf(CAMERA_DISTANCE, _view_size * 1.6)
	var view_xf := Transform3D(basis, _snap_to_pixels(cam_focus, basis, _view_size) + basis.z * distance)
	if moments != null and moments.frame(view_xf, _view_size, dt):
		# A cinematic moment (camera_shots.gd) placed the camera: snap where it put it.
		var b := cam.global_transform.basis
		cam.global_transform = Transform3D(b, _snap_to_pixels(cam.global_transform.origin, b, cam.size))
	else:
		cam.size = _view_size
		cam.global_transform = view_xf
	cam.far = _camera_far(maxf(CAMERA_DISTANCE, cam.size * 1.6), size)


## A point moved onto the pixel grid of a view `size` m tall turned `basis` (across and up the
## screen), so the city doesn't shimmer while the camera moves.
func _snap_to_pixels(p: Vector3, basis: Basis, size: float) -> Vector3:
	var texel := size / float(maxi(sv.size.y, 1))
	var r := p.dot(basis.x)
	var u := p.dot(basis.y)
	return p - basis.x * (r - snappedf(r, texel)) - basis.y * (u - snappedf(u, texel))


## Loop 2b: the camera's far plane, just past the lowest ground the view can show (the
## slab's walls, the river below the city: FAR_MARGIN). Godot's sun shadow covers an
## orthographic camera's whole depth, near to far (it ignores the light's max distance for
## them), so this sizes the shadow: far was 1,500 m past the view, a shadow map ~2 km across
## drawing every caster in it (the shadow pass had twice the main pass's draw calls) at
## ~0.5 m a texel. The depth is also chosen so the shadow's bounding sphere (Godot fits the
## near-far box's diagonal) keeps one size while the view widens with speed: texels that
## change size make the shadows' pixel edges crawl. It changes only when the player zooms.
const FAR_MARGIN := 130.0


func _camera_far(distance: float, size: float) -> float:
	var t := 1.0 / tan(deg_to_rad(maxf(absf(camera_pitch), 5.0)))
	var aspect := float(sv.size.x) / float(maxi(sv.size.y, 1))
	var low: float = FAR_MARGIN + (heli.height_above if flying else 0.0)
	# The widest this zoom gets: the car's view at top speed, the helicopter's as it is.
	var widest := maxf(cam.size, size if flying else base_size * (1.0 + FollowCamera.SPEED_ZOOM))
	var reach: float = maxf(CAMERA_DISTANCE, widest * 1.6) + 0.5 * widest * t + low
	var diagonal := reach * reach + widest * widest * (aspect * aspect + 1.0)
	var need: float = distance + 0.5 * cam.size * t + low
	var depth := sqrt(maxf(diagonal - cam.size * cam.size * (aspect * aspect + 1.0), need * need))
	return cam.near + depth


func _capture(n: int) -> void:
	await RenderingServer.frame_post_draw
	if ghost_debug > 0:
		print("ghost: frame %d centre %.1f %.1f radii %.1f %.1f (screen px)" % [n, _ghost_px.x, _ghost_px.y, _ghost_px.z, _ghost_px.w])
	var img := get_viewport().get_texture().get_image()
	img.save_png(out_dir.path_join("shot_%04d.png" % n))
	if n == shots.max():
		_quit_quietly()  # sweep 2: was get_tree().quit()


# --- sweep 2: a shots run quits without leaking its sounds ---------------------------------
## Real milliseconds the audio server gets to let the stopped sounds go before the quit.
const QUIET_QUIT_MS := 150


## Sweep 2: windowed `--shots` runs sometimes ended with "8 ObjectDB instances were leaked at
## exit" / "4 resources still in use": the sounds playing at the quit (an AudioStreamWAV and
## its playback each: the radio's station, the engine's idle and mid loops, the city bed),
## still held by the audio server because the tree went before its mixing thread let them
## go (headless runs have no audio device, so they never showed it). The game stops updating
## (sfx.gd would start a loop again), every player is stopped, and the server gets
## QUIET_QUIT_MS of real time before the quit.
func _quit_quietly() -> void:
	process_mode = Node.PROCESS_MODE_DISABLED
	for kind: String in ["AudioStreamPlayer", "AudioStreamPlayer2D", "AudioStreamPlayer3D"]:
		for p: Node in get_tree().root.find_children("*", kind, true, false):
			p.call("stop")
	var until := Time.get_ticks_msec() + QUIET_QUIT_MS
	while Time.get_ticks_msec() < until:
		await get_tree().process_frame
	get_tree().quit()
# --- end sweep 2 ---------------------------------------------------------------------------


# --- Loop 3c: the city in sectors ---------------------------------------------------------
# Kept in one block so other loops' changes to this file merge cleanly. The streamer
# (sector_streamer.gd) owns the map node and the sectors; this block opens it, feeds it the
# camera every frame, gives new sectors the game's state (the time of day, the quality's
# shadows, the fine detail, --exp) and runs the streaming test aids: --monolithic (the whole
# city built at once from centrum.json, as before loop 3c: the pixel diff's reference),
# --sectors=all (every sector loaded and kept), --sectors=proxies (only the sectors the car stands
# in, everything else as its proxy, to look at them), --stream-log (each load and unload with its
# frame and main-thread ms), --spots=X,Z,H/X,Z,H/... with --shots=F1,F2,... (spot k: the car
# jumps there, heading H degrees, 90 frames before shot k, and the sectors the view needs are
# finished 30 frames before it; tools/check_streaming.gd), --stream-soak=MINUTES (the car on
# autopilot over the whole map, the view widening and narrowing, the helicopter for the last
# third; then the streaming numbers, and the game quits).

const SectorStreamer := preload("res://scripts/sector_streamer.gd")
var streamer: SectorStreamer
var monolithic := false
var _sectors_all := false
var _sectors_proxies := false
var _stream_log := false
var _spots: Array[Vector3] = []
var _soak_minutes := 0.0
var _soak_route: Array[Vector2] = []
var _soak_leg := 0
var _soak_t := 0.0


func _parse_stream_args() -> void:
	for arg in game_args():
		if arg == "--monolithic":
			monolithic = true
		elif arg == "--sectors=all":
			_sectors_all = true
		elif arg == "--sectors=proxies":
			_sectors_proxies = true
		elif arg == "--stream-log":
			_stream_log = true
		elif arg.begins_with("--spots="):
			for s in arg.trim_prefix("--spots=").split("/"):
				var v := s.split(",")
				if v.size() >= 3:
					_spots.append(Vector3(float(v[0]), float(v[1]), float(v[2])))
		elif arg.begins_with("--stream-soak="):
			_soak_minutes = float(arg.trim_prefix("--stream-soak="))
			no_traffic = true
			free_roam = true
			show_title = false


## Loop 3d-1: "" when the city this run needs is there, else what is missing and how to make it
## (the sector split and the prebuilt sectors are derived, not committed: tools/setup_map.sh).
func _missing_map() -> String:
	if monolithic:
		return "" if FileAccess.file_exists(MAP_PATH) else "map: no %s (the committed map data)" % MAP_PATH
	var use_prebuilt := prebuilt or not OS.has_feature("editor")
	if use_prebuilt and not ResourceLoader.exists("res://map/index.res"):
		return "map: the prebuilt sectors are missing (map/index.res, sectors/*.scn): run tools/setup_map.sh once (README \"Map data\")"
	if not use_prebuilt and not FileAccess.file_exists("res://map/index.json"):
		return "map: the sector split is missing (map/index.json, sectors/*.json): run tools/setup_map.sh once (README \"Map data\")"
	return ""


func _open_streamed_city(world: Node3D, flat_mat: ShaderMaterial) -> Dictionary:
	streamer = SectorStreamer.new()
	streamer.name = "SectorStreamer"
	streamer.load_all = _sectors_all
	streamer.proxies_only = _sectors_proxies
	streamer.log = _stream_log
	add_child(streamer)
	streamer.sector_ready.connect(_on_sector_ready)
	var use_prebuilt := prebuilt or not OS.has_feature("editor")
	var data := streamer.open(world, use_prebuilt, building_mat, flat_mat, start_at)
	map = streamer.map
	building_mat = map.building_material
	# The ground's AO flags (--debug-ao, --no-ao) on either path's material.
	map.flat_material.set_shader_parameter("debug_ao", debug_ao)
	map.flat_material.set_shader_parameter("ao_strength", 0.0 if no_ao else 1.0)
	if _soak_minutes > 0.0:
		_soak_route = _soak_tour(data)
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://stream_soak_result.txt"))
	return data


## The map's own nodes and every loaded sector's (not the proxies).
func _city_nodes() -> Array[Node]:
	var out: Array[Node] = []
	for c in map.get_children():
		if c.name == "Sectors":
			for s in c.get_children():
				out.append_array(s.get_children())
		elif c.name != "Proxies":
			out.append(c)
	return out


## A sector's nodes take what the rest of the city has: the night-only ones shown with the
## lights, small casters' shadows as _apply_extras last set them (the quality, the governor's
## GPU level, the wide view; loop G1), fine detail by the view's width, --exp.
func _on_sector_ready(root: Node3D) -> void:
	var lit := tod != null and tod.lights_on > 0.001
	var small: bool = _small_cast == 1 if _small_cast >= 0 else bool(QUALITY[quality]["small_shadows"])
	var cast := GeometryInstance3D.SHADOW_CASTING_SETTING_ON if small else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Sweep 2 x loop 3c: each sector holds its own "Neon" node (not the map's root, where
	# _neon_materials looks), so its signs' shared material joins the ghost's list here.
	var neon := root.get_node_or_null("Neon")
	if neon != null:
		for c in neon.get_children():
			var ng := c as GeometryInstance3D
			var nm := ng.material_override as ShaderMaterial if ng != null else null
			if nm != null and not _neon_mats.has(nm):
				_neon_mats.append(nm)
	for n in root.find_children("*", "", true, false):
		if n.is_in_group("night_lights"):
			(n as Node3D).visible = lit
		if n.is_in_group(MapBuilder.SMALL_CASTERS):
			(n as GeometryInstance3D).cast_shadow = cast
		if n.is_in_group(MapBuilder.FINE_GROUP):
			(n as Node3D).visible = _fine_shown
		var g := n as GeometryInstance3D
		if g == null:
			continue
		for e in _exp:
			var mmi := n as MultiMeshInstance3D
			var leaf: bool = mmi != null and mmi.material_override == map.leaf_material
			if (e == "notrees" and leaf) or (e == "noprops" and mmi != null and not leaf):
				g.visible = false
			elif (e == "nosmallcasters" and mmi != null) or e == "nocasters":
				g.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _stream_frame(dt: float) -> void:
	if streamer != null:
		if _soak_minutes > 0.0:
			_soak_frame(dt)
		var forced := streamer.forced
		streamer.update(cam_focus, _vehicle_position(), cam)
		# A sector loaded at once (a jump: a tow, a race start) stalls this frame: the governor
		# (loop G1) counts afresh rather than read it as the frames running late. Streamed loads
		# stay inside the frame's budget and count as any other work.
		if streamer.forced > forced:
			governor.reset(_clock_s())
	if _spots.is_empty() or shots.is_empty():
		return
	var sorted := shots.duplicate()
	sorted.sort()
	for k in mini(_spots.size(), sorted.size()):
		if frame == sorted[k] - 90:
			_jump_to_spot(_spots[k])
		elif frame == sorted[k] - 30 and streamer != null:
			streamer.finish_view(cam_focus, cam)


## --spots: the car to a spot (x, z, heading in degrees), standing, the view on it.
func _jump_to_spot(s: Vector3) -> void:
	car.global_position = Vector3(s.x, map.ground_height(s.x, s.y), s.y)
	car.rotation.y = -deg_to_rad(s.z)
	car.vel = Vector3.ZERO
	car.reset_physics_interpolation()
	_cut_camera()
	# The sectors round the spot in at once, colliders and all, as the whole city has them.
	if streamer != null:
		streamer.finish_view(cam_focus, cam)
	print("spot: %.1f, %.1f heading %.0f at frame %d" % [s.x, s.y, s.z, frame])


## --stream-soak: a serpentine over every sector's middle (row by row), inside the map.
func _soak_tour(data: Dictionary) -> Array[Vector2]:
	var b: Array = data["bounds"]
	var inner := Rect2(b[0], b[1], b[2] - b[0], b[3] - b[1]).grow(-60.0)
	var rows := {}
	for key in streamer.keys:
		var c := (Vector2(key) + Vector2(0.5, 0.5)) * SectorStreamer.SECTOR
		c = c.clamp(inner.position, inner.end)
		if not rows.has(key.y):
			rows[key.y] = []
		rows[key.y].append(c)
	var route: Array[Vector2] = []
	var ys := rows.keys()
	ys.sort()
	for r in ys.size():
		var row: Array = rows[ys[r]]
		row.sort_custom(func(a: Vector2, c: Vector2) -> bool: return a.x < c.x if r % 2 == 0 else a.x > c.x)
		for p: Vector2 in row:
			route.append(p)
	return route


## --stream-soak, each frame: the car (then the helicopter) along the tour at 22 m/s, through
## buildings like the mission autopilot; the view 1x, then wide (220 m), every 20 s.
func _soak_frame(dt: float) -> void:
	_soak_t += dt
	if _soak_t >= _soak_minutes * 60.0:
		print("stream soak: %.0f s over %d sectors: %s" % [_soak_t, streamer.keys.size(), streamer.summary()])
		var numbers := streamer.stats()
		numbers["governor"] = "%s, %d changes%s" % [governor.state(), governor.changes, ", held" if governor.held else ""]
		print("stream soak stats: " + JSON.stringify(numbers))
		# Loop G0+: the numbers also go to a file (as the bench's card does), written and closed
		# here: on the iPhone get_tree().quit() does nothing and the app is stopped from outside,
		# so the log's tail is never certain; tools/device_run.sh copies this file back.
		var f := FileAccess.open("user://stream_soak_result.txt", FileAccess.WRITE)
		if f != null:
			f.store_string("stream soak: %.0f s over %d sectors: %s\nstream soak stats: %s\n" % [
					_soak_t, streamer.keys.size(), streamer.summary(), JSON.stringify(numbers)])
			f.close()
		_soak_minutes = 0.0
		get_tree().quit()
		return
	if _soak_route.is_empty():
		return
	base_size = FollowCamera.DEFAULT_SIZE if int(_soak_t / 20.0) % 2 == 0 else 220.0
	if not flying and _soak_t > _soak_minutes * 40.0:
		_take_off(Heli.CRUISE)
	var target: Vector2 = _soak_route[_soak_leg % _soak_route.size()]
	var pos := _vehicle_position()
	var to := Vector2(target.x - pos.x, target.y - pos.z)
	if to.length() < 25.0:
		_soak_leg += 1
		return
	if flying:
		heli.input_dir = Vector3(to.x, 0.0, to.y).normalized()
		heli.climb = 1.0 if heli.blocked else 0.0
		return
	var step := to.normalized() * 22.0 * dt
	car.collision_mask = 0
	car.vel = Vector3.ZERO
	car.global_position = Vector3(pos.x + step.x, map.drive_height(pos.x + step.x, pos.z + step.y, pos.y), pos.z + step.y)
	car.rotation.y = atan2(-to.x, -to.y)
