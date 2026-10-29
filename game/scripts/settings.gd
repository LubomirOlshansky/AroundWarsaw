extends RefCounted
## Loop 2a: the player's settings, kept between sessions in user://settings.cfg (a
## ConfigFile beside the wallet's save.cfg, which wallet.gd rewrites whole): the control
## scheme and (for Classic) the camera, the traffic level, quality, three volumes and the
## performance overlay; loop 2b: the frame rate (60, or 30 to save the battery); loop 2e: the
## picture style and the VHS tape (they moved off the driving screen into Settings; the time of
## day and the rain are the world's state and start by day and dry). `--nosave` neither reads
## nor writes it; command-line flags (`--controls= --traffic= --quality= --fixed --perf
## --style= --vhs`) win for that run and are not saved unless the player then changes the setting.
## Loop G1b: Auto's sharp image and its fallback (`[auto_image]`, tiers.gd SHARP_*), written only
## by a normal launch's own sessions (main.gd: never by --nosave, test runs, benches or
## --last-session=); a file without it (from before G1b) starts sharp.

const Tiers := preload("res://scripts/tiers.gd")
const PATH := "user://settings.cfg"
## Traffic levels: traffic.gd's density (Busy = 1.0, the level before loop 2a) and the
## share of the pedestrians. Busy's target is more than the spawner can place in the band
## round the view (about 44 cars at the default view, wanted 70), so the densities are set
## from the cars that really appear (bench, default view): Busy 26 on screen, Normal ~17
## (0.65 of it, the new default: the player asked for a little less), Low ~10 (0.4),
## Almost empty ~5. Pedestrians follow more gently (about the square root of those shares).
const TRAFFIC := [0.1, 0.22, 0.38, 1.0]
const PEOPLE := [0.45, 0.65, 0.8, 1.0]
const TRAFFIC_NAMES := ["Almost empty", "Low", "Normal", "Busy"]
const TRAFFIC_KEYS := ["empty", "low", "normal", "busy"]
const NORMAL_TRAFFIC := 2

## drive_controls.gd: POINT, CLASSIC, FIXED.
var controls := 0
## Classic only: the camera follows the car (CAM toggles it); Point always follows, Fixed never.
var classic_follow := true
var traffic := NORMAL_TRAFFIC
## tiers.gd: AUTO (-1, the default since loop G1: the level Auto picks for the device) or
## Low, Medium, High, Ultra (0-3). A file saved before G1 (no `tiers` key) that says High
## loads as Auto, once: High was the default then, not a choice; the next save marks the file.
const AUTO := -1
const HIGH := 2
const ULTRA := 3
var quality := AUTO
## 0..1 each: everything, the radio (Music bus), the effects (SFX and Ambience buses).
var master := 1.0
var music := 1.0
var effects := 1.0
var perf := false
## Loop 2b: frames per second, 60 (the default; ProMotion phones would otherwise run at 120 and
## warm up) or 30 (battery saver).
const FPS := [60, 30]
var fps := 60
## Loop 2e: main.gd STYLES (Sharp, Fine, Clean, Chunky) and the VHS overlay.
var style := 0
var vhs := false
## Loop G1b: Auto's sharp-image state (tiers.gd sharp_state: fallback, calm, wait, trial, why).
var auto_image := Tiers.sharp_state()
## False with --nosave: nothing is read or written.
var persistent := true
## Where it is kept (tools/check_settings.gd points it at a scratch file).
var path := PATH


func load_file() -> void:
	if not persistent:
		return
	var cfg := ConfigFile.new()
	if cfg.load(path) != OK:
		return
	controls = clampi(int(cfg.get_value("controls", "scheme", controls)), 0, 2)
	classic_follow = bool(cfg.get_value("controls", "classic_follow", classic_follow))
	traffic = clampi(int(cfg.get_value("world", "traffic", traffic)), 0, TRAFFIC.size() - 1)
	quality = clampi(int(cfg.get_value("world", "quality", quality)), AUTO, ULTRA)
	if quality == HIGH and not cfg.has_section_key("world", "tiers"):
		quality = AUTO
	master = clampf(float(cfg.get_value("sound", "master", master)), 0.0, 1.0)
	music = clampf(float(cfg.get_value("sound", "music", music)), 0.0, 1.0)
	effects = clampf(float(cfg.get_value("sound", "effects", effects)), 0.0, 1.0)
	perf = bool(cfg.get_value("debug", "perf", perf))
	fps = int(cfg.get_value("display", "fps", fps))
	if not fps in FPS:
		fps = FPS[0]
	style = clampi(int(cfg.get_value("display", "style", style)), 0, 3)
	vhs = bool(cfg.get_value("display", "vhs", vhs))
	var image := {}
	for key in auto_image:
		image[key] = cfg.get_value("auto_image", key, auto_image[key])
	auto_image = Tiers.sharp_clean(image)


func save() -> void:
	if not persistent:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("controls", "scheme", controls)
	cfg.set_value("controls", "classic_follow", classic_follow)
	cfg.set_value("world", "traffic", traffic)
	cfg.set_value("world", "quality", quality)
	cfg.set_value("world", "tiers", 1)
	cfg.set_value("sound", "master", snappedf(master, 0.01))
	cfg.set_value("sound", "music", snappedf(music, 0.01))
	cfg.set_value("sound", "effects", snappedf(effects, 0.01))
	cfg.set_value("debug", "perf", perf)
	cfg.set_value("display", "fps", fps)
	cfg.set_value("display", "style", style)
	cfg.set_value("display", "vhs", vhs)
	for key in auto_image:
		cfg.set_value("auto_image", key, auto_image[key])
	cfg.save(path)


func summary() -> String:
	return "controls %d, classic camera %s, traffic %s, quality %s, volume %.0f/%.0f/%.0f %%, perf %s, %d fps, style %d, vhs %s, auto image %s" % [
			controls, "follow" if classic_follow else "fixed", TRAFFIC_NAMES[traffic], "auto" if quality == AUTO else str(quality),
			master * 100.0, music * 100.0, effects * 100.0, perf, fps, style, vhs, image_summary()]


## Loop G1b: "sharp", "sharp, on trial 1/4" or "fallback, calm 1/2 (GPU extras down 74 s)".
func image_summary() -> String:
	var s := auto_image
	if s["fallback"]:
		return "fallback, calm %d/%d (%s)" % [s["calm"], s["wait"], s["why"]]
	if int(s["trial"]) >= 0:
		return "sharp, on trial %d/%d" % [s["trial"], s["wait"]]
	return "sharp"


static func parse_traffic(v: String) -> int:
	var k := TRAFFIC_KEYS.find(v.to_lower())
	return k if k >= 0 else clampi(int(v), 0, TRAFFIC.size() - 1)
