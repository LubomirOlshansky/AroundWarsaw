extends SceneTree
## Loop G1: the device tiers and the pixel image's size (scripts/tiers.gd, what the game uses).
##   - every model id in MODELS gets its tier (docs/design/graphics.md 4.1; unknown → High);
##   - the image at the three phone sizes the loop was measured on (the iPhone 11's 1792x828, the
##     6.1" 2532x1170, the Pro Max's 2868x1320) and the SE's 1334x750, at each level and style:
##     whole-pixel scaling, inside the level's budget, the sizes in IMAGES;
##   - nothing else moved: every size, style and level gives loop 2b's scale (the style's lines,
##     Low and Medium one step coarser) except High at a scale of 1 over High's budget;
##   - Auto on the two phones: the iPhone 11 High at 896x414, the Pro Max Ultra at 1434x660.
## Prints `check_tiers: OK` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_tiers.gd

const Tiers := preload("res://scripts/tiers.gd")

## Model id -> the level Auto picks.
const MODELS := {
	"iPhone10,1": Tiers.LOW, "iPhone10,3": Tiers.LOW, "iPhone10,6": Tiers.LOW,
	"iPhone11,2": Tiers.MEDIUM, "iPhone11,6": Tiers.MEDIUM, "iPhone11,8": Tiers.MEDIUM,
	"iPhone12,1": Tiers.HIGH, "iPhone12,3": Tiers.HIGH, "iPhone12,5": Tiers.HIGH, "iPhone12,8": Tiers.HIGH,
	"iPhone13,2": Tiers.HIGH, "iPhone14,5": Tiers.HIGH, "iPhone14,6": Tiers.HIGH, "iPhone14,7": Tiers.HIGH,
	"iPhone15,2": Tiers.HIGH, "iPhone15,4": Tiers.HIGH, "iPhone15,5": Tiers.HIGH,
	"iPhone16,1": Tiers.ULTRA, "iPhone16,2": Tiers.ULTRA,
	"iPhone17,1": Tiers.ULTRA, "iPhone17,2": Tiers.ULTRA, "iPhone17,3": Tiers.ULTRA, "iPhone17,4": Tiers.ULTRA,
	"iPhone17,5": Tiers.HIGH,
	"iPhone18,1": Tiers.ULTRA, "iPhone18,3": Tiers.ULTRA, "iPhone19,4": Tiers.ULTRA,
	"iPad13,1": Tiers.HIGH, "iPad16,3": Tiers.HIGH, "Mac16,7": Tiers.HIGH, "MacBookPro18,3": Tiers.HIGH,
	"arm64": Tiers.HIGH, "x86_64": Tiers.HIGH, "GenericDevice": Tiers.HIGH, "": Tiers.HIGH,
	"iPhone": Tiers.HIGH, "iPhone12": Tiers.HIGH, "iPhoneX,1": Tiers.HIGH,
}
## Screen -> the Sharp image at Low, Medium, High, Ultra.
const IMAGES := {
	Vector2i(1792, 828): [Vector2i(896, 414), Vector2i(896, 414), Vector2i(896, 414), Vector2i(1792, 828)],
	Vector2i(2532, 1170): [Vector2i(844, 390), Vector2i(844, 390), Vector2i(1266, 585), Vector2i(1266, 585)],
	Vector2i(2868, 1320): [Vector2i(956, 440), Vector2i(956, 440), Vector2i(1434, 660), Vector2i(1434, 660)],
	Vector2i(1334, 750): [Vector2i(667, 375), Vector2i(667, 375), Vector2i(667, 375), Vector2i(1334, 750)],
}
## main.gd STYLES' lines: Sharp, Fine, Clean, Chunky.
const LINES := [480.0, 360.0, 240.0, 170.0]

var problems: Array[String] = []


func _initialize() -> void:
	for model in MODELS:
		var got := Tiers.for_model(model)
		if got != MODELS[model]:
			problems.append("model %s: %s, wanted %s" % [model, Tiers.NAMES[got], Tiers.NAMES[MODELS[model]]])
	print("tiers: %d model ids checked" % MODELS.size())

	for screen: Vector2i in IMAGES:
		var row := PackedStringArray()
		for q in Tiers.QUALITY.size():
			var k := Tiers.image_scale(Vector2(screen), LINES[0], q)
			var img := Vector2i(screen.x / k, screen.y / k)
			row.append("%s %dx%d (x%d)" % [Tiers.NAMES[q], img.x, img.y, k])
			if img != IMAGES[screen][q]:
				problems.append("%dx%d %s: %dx%d, wanted %dx%d" % [screen.x, screen.y, Tiers.NAMES[q], img.x, img.y,
						IMAGES[screen][q].x, IMAGES[screen][q].y])
		print("image %dx%d, Sharp: %s" % [screen.x, screen.y, ", ".join(row)])

	var compared := 0
	for screen: Vector2i in IMAGES:
		for lines in LINES:
			for q in Tiers.QUALITY.size():
				var qs: Dictionary = Tiers.QUALITY[q]
				var k := Tiers.image_scale(Vector2(screen), lines, q)
				var pixels := float(screen.x / k) * float(screen.y / k)
				if k < 1 or pixels > float(qs["budget"]) * 1e6:
					problems.append("%dx%d %s at %.0f lines: x%d, %.2f MP over the budget %.2f" % [screen.x, screen.y,
							qs["name"], lines, k, pixels / 1e6, qs["budget"]])
				if q == Tiers.ULTRA:
					continue
				# Loop 2b's rule: the style's scale, Low and Medium one step coarser.
				var old := maxi(1, floori(screen.y / lines)) + int(qs["step"])
				var one := float(screen.x) * float(screen.y)
				var expected := old
				if q == Tiers.HIGH and old == 1 and one > float(qs["budget"]) * 1e6:
					expected = 2
				compared += 1
				if k != expected:
					problems.append("%dx%d %s at %.0f lines: x%d, loop 2b gave x%d (only High at x1 over its budget may change)" % [
							screen.x, screen.y, qs["name"], lines, k, old])
	print("against loop 2b's rule: %d sizes x styles x levels" % compared)

	for pair in [["iPhone12,1", Vector2i(1792, 828), Vector2i(896, 414)], ["iPhone17,2", Vector2i(2868, 1320), Vector2i(1434, 660)]]:
		var level := Tiers.for_model(pair[0])
		var k := Tiers.image_scale(Vector2(pair[1]), LINES[0], level)
		var img := Vector2i(pair[1].x / k, pair[1].y / k)
		print("Auto on %s: %s, image %dx%d" % [pair[0], Tiers.NAMES[level], img.x, img.y])
		if img != pair[2]:
			problems.append("Auto on %s: %dx%d, wanted %dx%d" % [pair[0], img.x, img.y, pair[2].x, pair[2].y])

	for t in [["auto", Tiers.AUTO], ["Ultra", Tiers.ULTRA], ["med", Tiers.MEDIUM], ["2", Tiers.HIGH], ["9", Tiers.ULTRA], ["fast", -2]]:
		if Tiers.parse(t[0]) != t[1]:
			problems.append("--quality=%s parsed as %d, wanted %d" % [t[0], Tiers.parse(t[0]), t[1]])

	if problems.is_empty():
		print("check_tiers: OK (%d model ids, %d screens, %d comparisons with loop 2b)" % [MODELS.size(), IMAGES.size(), compared])
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_tiers: %d problems" % problems.size())
		quit(1)
