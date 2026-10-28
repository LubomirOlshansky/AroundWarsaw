extends RefCounted
## Loop G1: the quality levels, the level Auto picks for a device, and the pixel image's size
## (docs/design/graphics.md section 4). Static, so tools/check_tiers.gd tests the same tables
## and rules the game uses (main.gd applies them).
##
## - Auto (the default since G1) picks a level from the device's model id
##   (`OS.get_model_name()`, e.g. `iPhone12,1`; the number before the comma is the family, not
##   the marketing name: `iPhone11,x` is the XS/XR, the iPhone 11 is `iPhone12,1`).
## - The pixel image: each style has its lines (Sharp 480); the image scales up by the most
##   whole screen pixels that keep at least that many lines (at least 1), `step` coarser for
##   Low and Medium, then coarser again until the image fits the level's **budget** in
##   megapixels. The iPhone 11's 828 lines at Sharp were 1 → 1792×828, 1.48 MP, the most pixels
##   of any phone with half the Pro Max's GPU, and its High stuttered (1 % low 25 fps) from fill;
##   High's budget (the Pro Max's own 1434×660, 0.95 MP, the most a phone has held 60 fps with
##   at High) gives it 2 → 896×414 with High's shadows and effects, and leaves every phone
##   that already scaled by 2 or more as it was.

enum { LOW, MEDIUM, HIGH, ULTRA }
## The player's choice that follows the device (settings.gd quality).
const AUTO := -1
const NAMES := ["Low", "Medium", "High", "Ultra"]

## Low, Medium, High, Ultra. step: whole screen pixels coarser than the style's own scale
## (loop 2b); budget: the most megapixels the pixel image may have (G1); the sun's shadow map
## (loop 2b: 2048 on High and 1024 on Medium cover only the view, finer than 4096 did over
## 2 km; Ultra's 4096 halves the texels again, 0.37 → 0.18 m); glow at night; rain streaks;
## mirror-reflection steps a pixel; the traffic's share and the most pedestrians; whether
## things over a metre that aren't buildings or trees (map_builder.gd SMALL_CASTERS: lamps,
## signals, parked cars, columns, shelters) cast sun shadows. Ultra (A17 Pro and newer by
## Auto) is High plus the 4096 map and 16 reflection steps, with a budget that keeps a
## 1.48 MP ×1 image (the iPhone 11's look before G1, for anyone who picks it).
const QUALITY := [
	{"name": "Low", "step": 1, "budget": 0.5, "shadows": false, "shadow_size": 1024, "glow": false, "rain": 0.4,
		"reflect": 0, "traffic": 0.55, "people": 24, "small_shadows": false},
	{"name": "Medium", "step": 1, "budget": 0.5, "shadows": true, "shadow_size": 1024, "glow": true, "rain": 0.7,
		"reflect": 6, "traffic": 0.8, "people": 40, "small_shadows": false},
	{"name": "High", "step": 0, "budget": 0.96, "shadows": true, "shadow_size": 2048, "glow": true, "rain": 1.0,
		"reflect": 10, "traffic": 1.0, "people": 60, "small_shadows": true},
	{"name": "Ultra", "step": 0, "budget": 1.6, "shadows": true, "shadow_size": 4096, "glow": true, "rain": 1.0,
		"reflect": 16, "traffic": 1.0, "people": 60, "small_shadows": true},
]


## The level Auto picks for a model id (graphics.md 4.1): iPhone 8 / X (`iPhone10,x`, A11) Low,
## XS / XR (`iPhone11,x`, A12) Medium, 11 to 15 and the SE 2 / 3 (`iPhone12,x`–`iPhone15,x`,
## A13–A16) and the 16e (`iPhone17,5`, A18 with a 4-core GPU) High, 15 Pro and newer
## (`iPhone16,x`, `iPhone17,1`–`4`, `iPhone18,x` and up: A17 Pro, A18, A19…) Ultra; anything
## else (an iPad, a Mac, the simulator, an id this doesn't know) High, with the governor.
static func for_model(model: String) -> int:
	if not model.begins_with("iPhone"):
		return HIGH
	var parts := model.trim_prefix("iPhone").split(",")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return HIGH
	var family := int(parts[0])
	var unit := int(parts[1])
	if family <= 10:
		return LOW
	if family == 11:
		return MEDIUM
	if family <= 15:
		return HIGH
	if family == 17 and unit == 5:
		return HIGH
	return ULTRA


## Whole screen pixels per image pixel for a screen `size` (pixels), a style's `lines` and a
## quality level: the style's own scale, the level's step coarser, then coarser until the
## image (the screen's size divided by it, as SubViewportContainer.stretch_shrink rounds it)
## fits the level's budget.
static func image_scale(size: Vector2, lines: float, quality: int) -> int:
	var q: Dictionary = QUALITY[clampi(quality, 0, QUALITY.size() - 1)]
	var k := maxi(1, floori(size.y / lines)) + int(q["step"])
	var budget := float(q["budget"]) * 1e6
	while k < 64 and floorf(size.x / k) * floorf(size.y / k) > budget:
		k += 1
	return k


## A choice (AUTO or a level) by name or number for --quality= (-2: not one).
static func parse(text: String) -> int:
	var t := text.to_lower()
	var named := {"auto": AUTO, "low": LOW, "medium": MEDIUM, "med": MEDIUM, "high": HIGH, "ultra": ULTRA}
	if named.has(t):
		return named[t]
	if t.is_valid_int():
		return clampi(int(t), LOW, ULTRA)
	return -2


## "Auto→High (iPhone12,1)" or "Medium": the choice for the bench card.
static func describe(choice: int, level: int, model: String) -> String:
	if choice == AUTO:
		return "Auto→%s (%s)" % [NAMES[level], model]
	return NAMES[clampi(choice, LOW, ULTRA)]
