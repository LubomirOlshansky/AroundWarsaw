extends RefCounted
## Loop 2a: the player's settings, kept between sessions in user://settings.cfg (a
## ConfigFile beside the wallet's save.cfg, which wallet.gd rewrites whole): the control
## scheme and (for Classic) the camera, the traffic level, quality, three volumes and the
## performance overlay; loop 2b: the frame rate (60, or 30 to save the battery). `--nosave` neither reads nor writes it; command-line flags
## (`--controls= --traffic= --quality= --fixed --perf`) win for that run and are not saved
## unless the player then changes the setting.

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
## main.gd QUALITY: Low, Medium, High.
var quality := 2
## 0..1 each: everything, the radio (Music bus), the effects (SFX and Ambience buses).
var master := 1.0
var music := 1.0
var effects := 1.0
var perf := false
## Loop 2b: frames per second, 60 (the default; ProMotion phones would otherwise run at 120 and
## warm up) or 30 (battery saver).
const FPS := [60, 30]
var fps := 60
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
	quality = clampi(int(cfg.get_value("world", "quality", quality)), 0, 2)
	master = clampf(float(cfg.get_value("sound", "master", master)), 0.0, 1.0)
	music = clampf(float(cfg.get_value("sound", "music", music)), 0.0, 1.0)
	effects = clampf(float(cfg.get_value("sound", "effects", effects)), 0.0, 1.0)
	perf = bool(cfg.get_value("debug", "perf", perf))
	fps = int(cfg.get_value("display", "fps", fps))
	if not fps in FPS:
		fps = FPS[0]


func save() -> void:
	if not persistent:
		return
	var cfg := ConfigFile.new()
	cfg.set_value("controls", "scheme", controls)
	cfg.set_value("controls", "classic_follow", classic_follow)
	cfg.set_value("world", "traffic", traffic)
	cfg.set_value("world", "quality", quality)
	cfg.set_value("sound", "master", snappedf(master, 0.01))
	cfg.set_value("sound", "music", snappedf(music, 0.01))
	cfg.set_value("sound", "effects", snappedf(effects, 0.01))
	cfg.set_value("debug", "perf", perf)
	cfg.set_value("display", "fps", fps)
	cfg.save(path)


func summary() -> String:
	return "controls %d, classic camera %s, traffic %s, quality %d, volume %.0f/%.0f/%.0f %%, perf %s, %d fps" % [
			controls, "follow" if classic_follow else "fixed", TRAFFIC_NAMES[traffic], quality,
			master * 100.0, music * 100.0, effects * 100.0, perf, fps]


static func parse_traffic(v: String) -> int:
	var k := TRAFFIC_KEYS.find(v.to_lower())
	return k if k >= 0 else clampi(int(v), 0, TRAFFIC.size() - 1)
