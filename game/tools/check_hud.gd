extends SceneTree
## Loop 2e: the HUD at phone size. Builds the HUD (hud.gd with the speech bubbles and the
## settings panel) in a viewport the size of each screen below, as the game would on that
## phone (screen_points.gd: its points and safe area), and walks it through the states that
## matter: the first screen in each control scheme and in the helicopter, a call coming in, the
## call card, a payment, a rescue with the radio host and an easter egg, a kebab offer and a
## delivery with the customer talking where the radio ticker sits, a race, a rival to
## challenge, a landmark card, the tow toast, the same with the performance overlay on, every
## tab of the settings panel and the bench card; loop 3g-1: a police chase (the pill, the koguty,
## a megaphone bubble), the lizak, and the pull-over card (the pedals away). In each state:
##   - every control the player can press is at least 44 pt each way and inside the safe area;
##   - every text is at least 11 pt, and the body texts (cards, ticker, toasts, hints) 13 pt;
##   - every HUD rect (the fixed controls, the panels, the pedals, the speech bubbles) is inside
##     the safe area and no two of them overlap; no panel was left without room (the passing
##     ones, the ticker, notes, bubbles and the overlay, may wait for room: listed); the passing
##     panels keep off the car's spot in the middle of the screen;
##   - the settings panel and the bench card fit without being shrunk.
## Prints a line per screen and state, then `check_hud: OK` (exit 0) or the problems (exit 1).
##   godot --headless --path game --script res://tools/check_hud.gd [-- --verbose]

const Hud := preload("res://scripts/hud.gd")
const Bubbles := preload("res://scripts/bubbles.gd")
## Loop 3g-1: the pull-over card (police.gd lays it out with the HUD's panels).
const PoliceBalloon := preload("res://scripts/police/police_balloon.gd")
## Loop 2d-1: Podwózka's card words.
const RideRules := preload("res://scripts/ride_rules.gd")
## Width x height in pixels (landscape): the user's 6.9" Pro Max, the 6.1" class, a computer
## window (taken as a phone 390 pt tall), the SE (375 pt tall, no insets).
const SCREENS := [Vector2i(2868, 1320), Vector2i(2532, 1170), Vector2i(1280, 720), Vector2i(1334, 750)]
const MIN_TOUCH := 44.0
const MIN_LABEL := 11.0
const MIN_BODY := 13.0

var problems: Array[String] = []
var verbose := false
var _speakers := {}
## Passing panels (the radio ticker, the note and landmark cards) and the performance overlay
## that waited for room: allowed, they show once there is some.
var _waits: Array[String] = []


func _initialize() -> void:
	verbose = "--verbose" in OS.get_cmdline_user_args()
	_run()


func _run() -> void:
	await process_frame  # the tree is ready for nodes only once the first frame runs
	var states := 0
	for screen in SCREENS:
		states += await _check_screen(screen)
	for w in _waits:
		print("  waits for room: %s" % w)
	if problems.is_empty():
		print("check_hud: OK (%d screens, %d states; a passing panel waited for room %d times)" % [SCREENS.size(), states, _waits.size()])
		quit(0)
	else:
		for p in problems:
			print("  PROBLEM " + p)
		print("check_hud: %d problems" % problems.size())
		quit(1)


func _check_screen(screen: Vector2i) -> int:
	var vp := SubViewport.new()
	vp.size = screen
	vp.disable_3d = true
	root.add_child(vp)
	var hud: CanvasLayer = Hud.new()
	vp.add_child(hud)
	hud.setup_minimap({"areas": [], "roads": [{"p": [-200.0, 0.0, 200.0, 0.0], "k": "primary", "w": 12.0}],
			"bounds": [-900.0, -600.0, 900.0, 600.0], "landmarks": []})
	var bubbles: Control = Bubbles.new()
	bubbles.pt = hud.pt
	bubbles.project = func(p: Vector3) -> Vector2: return Vector2(p.x, p.y)
	hud.add_child(bubbles)
	hud.move_child(bubbles, 1)
	var talk: Control = PoliceBalloon.new()
	talk.pt = hud.pt
	hud.add_panel(talk, "bottom")
	await process_frame
	var pt: float = hud.pt
	var safe: Rect2 = hud.safe_rect()
	var tag := "%dx%d (%.0fx%.0f pt)" % [screen.x, screen.y, screen.x / pt, screen.y / pt]
	print("%s: %.2f px a point, safe area %.0f..%.0f x %.0f..%.0f pt" % [tag, pt, safe.position.x / pt, safe.end.x / pt,
			safe.position.y / pt, safe.end.y / pt])
	var count := 0
	var at := func(fx: float, fy: float) -> Vector2: return Vector2(screen.x * fx, screen.y * fy)
	# The longest call the map gives (the longest hospital name), Polish over English as in missions.gd.
	var call_pl := "Ranny rowerzysta: Aleksandra Krywulta. Wystarczy auto albo helikopter.\nSzpital: Samodzielny Szpital Kliniczny im. prof. Witolda Orłowskiego · czas 3:40"
	var call_en := "A cyclist is hurt: the car or the helicopter will do. Get them to the hospital in 3:40."
	# Loop G1: the last line is the quality, its pixel scale and the governor (the longest one;
	# loop G1b: with "fallback", and the longest level name).
	var perf_text := "60 fps · 16.7 ms · worst 18.2 · cap 60 fps\nCPU 11.2 + 0.3 + 14.1 ms · GPU n/a · 670 MB\ndraws 153 = 53 + 35 + 65 · 0.45 M tris\nMedium ×3 fallback · gov GPU 2/2 · CPU 2/2 · wide"
	for perf in [false, true]:
		for state in ["car, Point", "car, Classic", "helicopter", "call came in", "call card", "rescued, paid",
				"rescue, host, egg", "kebab offer", "kebab delivery", "race", "rival ahead", "landmark card", "tow toast",
				"police chase", "lizak", "pull-over",
				"ride offer", "ride", "ride result", "ride result, police"]:
			if perf and not state in ["car, Point", "call card", "rescue, host, egg", "kebab offer", "kebab delivery", "landmark card"]:
				continue
			hud.clear_all()
			bubbles.clear()
			hud.set_scheme(1 if state == "car, Classic" else 0)
			hud.set_flying(state == "helicopter")
			if state == "helicopter":
				hud.set_speed(88, 45)
			else:
				hud.set_speed(142)
			hud.set_wallet(12345, 1234)
			hud.show_perf(perf)
			hud.set_perf(perf_text)
			match state:
				"call came in":
					hud.show_pill("WEZWANIE", "rescue call")
					hud.toast("Wezwanie ratunkowe!", "A rescue call came in: tap WEZWANIE")
				"call card":
					hud.show_card("WEZWANIE 1 · RATUNEK NA ULICY", call_pl, PackedStringArray(["ACCEPT", "SKIP", "LATER"]),
							Color("#ffc23a"), false, "Call 1 · street rescue", call_en)
				"rescued, paid":
					hud.show_card("URATOWANI", "Cali i zdrowi: Szpital Praski.\nCzas 2:10 z 3:40 · punkty +1210 (razem 1210) · +97 zł",
							PackedStringArray(["NEXT CALL", "FREE ROAM"]), Color("#56d68a"), false, "Rescued",
							"Safe and sound at the hospital: time, score and pay above.")
					hud.set_wallet(12442, 1274, 97)
				"rescue, host, egg":
					hud.show_status("DO SZPITALA · Samodzielny Szpital Kliniczny im. prof. Witolda Orłowskiego", "2:31", "640 m",
							"Pacjent na pokładzie: do zielonego światła", 0.3, Color("#ffc23a"), "", {}, "Patient on board: head for the green beacon")
					hud.ticker("87,3 NOCNA FM:  Jest trzecia w nocy, a Rondo Dmowskiego wciąż stoi. Szacunek.", Color("#ff5fc8"),
							"It's 3 a.m. and Rondo Dmowskiego is still jammed. Respect.")
					hud.show_note("SEKRET 2/5 · EASTER EGG", "Gołębie na placu Defilad\nPigeons on Plac Defilad", Color("#ff4fd8"))
					_say(bubbles, "Ania", at.call(0.2, 0.86), "Szybciej, proszę!", "Faster, please!")
				"kebab offer":
					hud.show_card("ZAMÓWIENIE · KEBAB · 840 m", "Dla: Kasia, Wspólna 47/49. Za rzeką: „w sumie to centrum”. Im cieplejszy dojedzie, tym większy napiwek. Nocą ×1,5.",
							PackedStringArray(["GO!", "NOT NOW"]), Color("#ff9a3c"), true, "Kebab order · 840 m",
							"It cools on the way: the hotter, the bigger the tip. Across the river (\"basically the centre\"). Night pays ×1.5.")
					hud.ticker("87,3 NOCNA FM  ·  Palma de Gaulle'a", Color("#ff5fc8"))
					hud.toast("Jedziemy! Kasia czeka", "Go! Kasia is waiting")
					_say(bubbles, "Marek", at.call(0.12, 0.82), "Z ostrym czy łagodnym?", "Hot sauce or mild?")
					# The vendor over the stand, mid-right, where shots/loop2e_kebab_offer_* see it.
					_say(bubbles, "Kebab 24h", at.call(0.62, 0.52), "Mięso z rożna, sos z serca. Dowieź, zanim wystygnie.",
							"Meat off the spit, sauce from the heart. Get it there before it cools.")
				"kebab delivery":
					hud.show_status("KEBAB → Wspólna 47/49", "GORĄCY 92%", "410 m", "Jedź do pomarańczowego światła", 0.0, Color("#ff9a3c"),
							"", {"heat": 0.9}, "Head for the orange beacon")
					hud.ticker("87,3 NOCNA FM  ·  Palma de Gaulle'a", Color("#ff5fc8"))
					# The case the user saw: the stand's bubble right where the ticker sits.
					_say(bubbles, "Kebab 24h", at.call(0.1, 0.9), "KEBAB 24H: najlepszy w mieście!", "The best in town!")
					_say(bubbles, "Kasia", at.call(0.55, 0.45), "Już jedziesz? Głodna jestem.", "On your way? I'm starving.")
				"race":
					hud.show_status("WYŚCIG · Seba z Pragi → Palma", "0:42", "620 m", "Seba z Pragi: 40 m za tobą", 0.0, Color("#b45cff"),
							"1ST", {}, "Seba z Pragi is 40 m behind")
					hud.show_banner("WYŚCIG DO PALMY", Color("#b45cff"))
					_say(bubbles, "Seba z Pragi", at.call(0.5, 0.42), "Ej, kierowniku! Do Palmy!", "Hey, boss! To the Palm!")
				"rival ahead":
					hud.show_challenge("MRUGNIJ ŚWIATŁAMI · SEBA Z PRAGI", Color("#b45cff"))
					hud.toast("Najpierw dokończ kurs: zamówienie jedzie autem", "Finish the job first: it rides in the car")
				"landmark card":
					hud.show_info("Pałac Kultury i Nauki", "Najwyższy budynek w Polsce do 2022 roku: 237 m z iglicą.",
							"Poland's tallest building until 2022: 237 m with the spire.")
					hud.ticker("87,3 NOCNA FM:  Pałac widać z każdego miejsca. Dlatego go lubimy.", Color("#ff5fc8"),
							"You can see the Palace from everywhere. That's why we like it.")
				"tow toast":
					hud.toast("Pomoc drogowa: wyciągnięci!", "Towed free")
					hud.ticker("87,3 NOCNA FM  ·  Palma de Gaulle'a", Color("#ff5fc8"))
				# Loop 3g-1: a koguty 2 chase (the pill and its countdown, the koguty, a megaphone
				# bubble, the edge rooster), the lizak's pill, and the pull-over card with two replies.
				"police chase":
					hud.set_koguty(2, 1)
					hud.police_pill("SZUKAJĄ CIĘ · KONIEC ZMIANY ZA 0:27", "SEARCHING · END OF SHIFT IN 0:27")
					hud.police_fx(1.0, PackedVector2Array([at.call(0.5, 1.3)]), Vector2.INF)
					_say(bubbles, "Policja", at.call(0.5, 0.72), "Proszę się zatrzymać! Albo chociaż zwolnić, będzie miło.",
							"Please stop! Or at least slow down, that would be nice.")
					hud.ticker("87,3 NOCNA FM  ·  Palma de Gaulle'a", Color("#ff5fc8"))
				"lizak":
					hud.set_koguty(0, 3)
					hud.police_pill("ZATRZYMAJ SIĘ PRZY POLICJANCIE", "PULL OVER BY THE OFFICER")
					hud.police_fx(0.0, PackedVector2Array(), at.call(0.56, 0.36))
					hud.toast("UCIECZKA!  +15", "ESCAPED!  +15 RESPECT")
				"pull-over":
					hud.set_koguty(1, 1)
					hud.set_pedals_hidden(true)
					# The longest opener with the longest English (the caution's) and the two widest replies.
					talk.show_line("Posterunkowy Kacper", "Kontrola drogowa. Wie pan, czemu pana zatrzymałem? Ja tak średnio.",
							"Consider yourself cautioned. Kacper, put it in the notebook. Neatly, not like last time.",
							[["Przepraszam, już nie będę.", "Sorry, won't happen again."], ["Suszarka? Mam krótkie włosy.", "Hair dryer? But I've got short hair."]])
					hud.show_panel(talk, true)
					hud.ticker("87,3 NOCNA FM  ·  Palma de Gaulle'a", Color("#ff5fc8"))
				# Loop 2d-1: Podwózka at its longest: the longest note, the MNOŻNIK for night and rain,
				# the longest destination; the result with every star note and a streak.
				"ride offer":
					var offer := RideRules.offer_text({"name": "Krzysiek", "away": 588.0, "road": 2496.0, "their": 4.9,
							"note": ["Uwagi: „jestem tam, gdzie pinezka, tylko po drugiej stronie”.",
							"Note: \"I'm where the pin is, just on the other side.\""], "night": true, "rain": true, "rating": 4.87})
					hud.show_side_card(offer[0], offer[1], PackedStringArray(["ACCEPT", "SKIP"]), Color("#4fd8c4"), offer[2], offer[3])
					hud.show_pill("PODWÓZKA", "ride app", "ride")
					hud.ticker("87,3 NOCNA FM  ·  Palma de Gaulle'a", Color("#ff5fc8"))
				"ride":
					hud.show_status("PODWÓZKA → Plac Trzech Krzyży", RideRules.stars_text(4.5), "1840 m",
							"Cel to turkusowe światło. Kropki to pomysł aplikacji.", 0.4, Color("#4fd8c4"), "", {},
							"The goal is the teal beacon. The dots are the app's idea.")
					hud.toast("−½ ★ · hamowanie", "−½ star · harsh braking")
					_say(bubbles, "Nawigacja", at.call(0.55, 0.42), "Za dwieście metrów skręć w prawo. W Wisłę.",
							"In two hundred metres, turn right. Into the Vistula.")
					_say(bubbles, "Krzysiek", at.call(0.2, 0.8), "GPS mówi przez Wisłę. Może jest prom? Nie ma promu?",
							"The GPS says across the Vistula. Maybe there's a ferry? No ferry?")
				"ride result":
					# The longest a 5-star card gets: night and rain, in a hurry, a full streak, three notes.
					var pay := RideRules.pay(2496.0, 5.0, true, true, true, 5)
					var done := RideRules.result_text({"stars": 5.0, "name": "Krzysiek", "comment": ["Pięć gwiazdek i serduszko. Serduszko jest rzadkie.",
							"Five stars and a heart. The heart is rare."], "pay": pay, "rating": 4.88,
							"why": ["jazda −1, przed czasem +½, za aplikacją +½", "driving −1, early +½, followed the app +½"]})
					hud.show_side_card(done[0], done[1], PackedStringArray(), Color("#4fd8c4"), done[2], done[3])
					hud.set_wallet(12442, 1259, 97)
				"ride result, police":
					# The longest comment (pulled over), with the most a 4-star ride can lose and win back.
					var pay4 := RideRules.pay(2496.0, 4.0, true, true, false, 0)
					var done4 := RideRules.result_text({"stars": 4.0, "name": "Krzysiek", "comment": ["Policja w trakcie kursu? Gwiazdkę zabieram, anegdotę zostawiam.",
							"Police mid-ride? I'm taking a star, but keeping the anecdote."], "pay": pay4, "rating": 4.83,
							"why": ["jazda −½, policja −1, za aplikacją +½", "driving −½, police −1, followed the app +½"]})
					hud.show_side_card(done4[0], done4[1], PackedStringArray(), Color("#4fd8c4"), done4[2], done4[3])
			await process_frame
			await process_frame
			bubbles.layout()
			_check_state(hud, bubbles, "%s %s%s" % [tag, state, " + perf" if perf else ""])
			count += 1
	# The settings panel, every tab, and the bench card.
	hud.clear_all()
	bubbles.clear()
	hud.open_settings({"controls": 1, "follow": false, "traffic": 2, "quality": 0, "auto": "Medium ostry", "master": 1.0, "music": 0.5,
			"effects": 1.0, "perf": 0, "fps": 0, "style": 0, "vhs": 0, "weather": 0, "time": 0})
	var panel: Control = hud.settings_panel
	for t in 4:
		panel.set_tab(t)
		await process_frame
		await process_frame
		var where := "%s settings tab %d" % [tag, t]
		if not is_equal_approx(panel.card_scale(), 1.0):
			problems.append("%s: the panel is shrunk to %.2f to fit" % [where, panel.card_scale()])
		var card: Rect2 = panel.card_rect()
		if not safe.grow(0.5).encloses(card):
			problems.append("%s: the panel %s sticks out of the safe area %s" % [where, _pts(card, pt), _pts(safe, pt)])
		var buttons: Dictionary = panel.button_rects()
		for b in buttons:
			_check_touch(where + " " + b, buttons[b], pt, safe)
		_check_fonts(panel, where, pt)
		if verbose:
			print("  %s: %d buttons, panel %s" % [where, buttons.size(), _pts(card, pt)])
		count += 1
	panel.close()
	var bench := "NOCNA WARSZAWA bench (loop 2b) · BENCH · 2026-10-28 16:42:59\ndevice iPhone17,2 · iOS 26.0 · Apple A18 Pro GPU (metal, mobile) · Apple A18 Pro\nscreen 2868x1320 @ 120 Hz · image 1434x660 (×2) · view 80 m · quality Auto→High fallback (iPhone17,2) · traffic Normal · Day · Clear · cap 60 fps · Point\nthermal state: not readable from Godot; a phone that warms up shows it as falling fps per 10 s\nfps 59.9 avg · 1% low 55.3 · worst frame 25.0 ms · late 0.4% (over 17.7 ms) · missed refreshes 12 (0.4%) · 3300 frames in 55 s\nfps per 10 s: 60 60 60 60 60 60 · governor held: GPU 2/2 · CPU 2/2, wide, 12 changes\nframe 16.69 ms · main thread: process 2.10, physics 0.40, draw 13.90 · 3D view: render CPU 0.60, GPU n/a (Metal)\ndraw calls 141 · objects 410 · triangles 0.42 M (all passes, as the overlay counts them)\nmain pass: 50 draws, 50 objects, 0.24 M tris · shadow pass: 33 draws, 33 objects, 0.13 M tris · 2D: 58 draws\nscripts 1.90 ms: traffic 0.70 · traffic bodies 0.05 · trams 0.25 · people 0.30 · rivals 0.05 · jobs+eggs 0.10\n  jobs physics 0.01 · sound 0.04 · hud+minimap 0.20 · bubbles 0.05 · dialogue 0.01\ncars on screen 15 · driving 31 · people 48\nmemory: static 640 MB · video 310 MB (textures 120, buffers 150) · 3 pipeline compilations"
	hud.show_bench_card(bench)
	await process_frame
	await process_frame
	var bw := "%s bench card" % tag
	var bcard: PanelContainer = hud.get("_bench_card")
	if not is_equal_approx(bcard.scale.x, 1.0):
		problems.append("%s: shrunk to %.2f to fit" % [bw, bcard.scale.x])
	if not safe.grow(0.5).encloses(bcard.get_global_rect()):
		problems.append("%s: %s sticks out of the safe area" % [bw, _pts(bcard.get_global_rect(), pt)])
	var targets: Dictionary = hud.touch_targets()
	for k in targets:
		if String(k).begins_with("bench"):
			_check_touch(bw + " " + k, targets[k], pt, safe)
	_check_fonts(bcard, bw, pt)
	count += 1
	vp.queue_free()
	await process_frame
	return count


## A speech bubble from a speaker standing at screen point `p`.
func _say(bubbles: Control, who: String, p: Vector2, pl: String, en: String) -> void:
	var anchor := func() -> Vector3: return Vector3(p.x, p.y, 0.0)
	_speakers[who] = anchor
	bubbles.say(anchor, who, pl, en, 4.0, Color("#ff9a3c"), 0.0)


func _check_state(hud: CanvasLayer, bubbles: Control, where: String) -> void:
	var pt: float = hud.pt
	var safe: Rect2 = hud.safe_rect()
	var targets: Dictionary = hud.touch_targets()
	for k in targets:
		_check_touch("%s %s" % [where, k], targets[k], pt, safe)
	var rects: Dictionary = hud.named_rects()
	var i := 0
	for r in bubbles.rects:
		rects["bubble%d" % i] = r
		i += 1
	var names := rects.keys()
	for a in names.size():
		var ra: Rect2 = rects[names[a]]
		if not safe.grow(0.5).encloses(ra):
			problems.append("%s: %s %s is outside the safe area %s" % [where, names[a], _pts(ra, pt), _pts(safe, pt)])
		for b in range(a + 1, names.size()):
			var rb: Rect2 = rects[names[b]]
			if ra.intersection(rb).get_area() > pt * pt:
				problems.append("%s: %s %s overlaps %s %s" % [where, names[a], _pts(ra, pt), names[b], _pts(rb, pt)])
	# The passing panels keep clear of the player's car (the middle of the screen); loop 2d-1: so
	# does a Podwózka card (the side card).
	var keep_clear := ["ticker", "toast", "note", "info", "perf", "banner"]
	if where.contains(" ride"):
		keep_clear.append("card")
	for n in keep_clear:
		if rects.has(n) and (rects[n] as Rect2).intersects(hud.car_zone()):
			problems.append("%s: %s %s covers the car's spot %s" % [where, n, _pts(rects[n], pt), _pts(hud.car_zone(), pt)])
	var unplaced: Array = hud.unplaced()
	if not unplaced.is_empty():
		problems.append("%s: no room for %s" % [where, ", ".join(unplaced)])
		if "card" in unplaced:
			# Loop 2d-1: how big the card wanted to be, in points.
			problems.append("%s:   (the card %s pt)" % [where, hud._card.get_combined_minimum_size() / pt])
	for n in hud.waiting():
		_waits.append("%s in %s" % [n, where])
	if bubbles.overlaps > 0:
		_waits.append("%d speech bubble(s) in %s" % [bubbles.overlaps, where])
	_check_fonts(hud, where, pt)
	for body in ["_card_body", "_card_body_en", "_ticker_label", "_ticker_sub", "_toast", "_toast_gloss", "_status_hint",
			"_status_hint_en", "_info_pl", "_info_en", "_note_body", "_police_pl", "_police_en"]:
		var l: Label = hud.get(body)
		if l.is_visible_in_tree() and l.get_theme_font_size("font_size") < MIN_BODY * pt - 0.5:
			problems.append("%s: %s is %.1f pt (body text needs %.0f)" % [where, body, l.get_theme_font_size("font_size") / pt, MIN_BODY])
	for s in [bubbles.LINE_SIZE, bubbles.SUB_SIZE]:
		if s < MIN_BODY:
			problems.append("%s: a speech bubble's text is %.0f pt" % [where, s])
	for s in [bubbles.NAME_SIZE, hud.T_LABEL]:
		if s < MIN_LABEL:
			problems.append("%s: a label is %.0f pt" % [where, s])
	if verbose:
		var parts := PackedStringArray()
		for k in rects:
			parts.append("%s %s" % [k, _pts(rects[k], pt)])
		print("  %s: %d targets · %s" % [where, targets.size(), " · ".join(parts)])


func _check_touch(where: String, r: Rect2, pt: float, safe: Rect2) -> void:
	if r.size.x < MIN_TOUCH * pt - 0.5 or r.size.y < MIN_TOUCH * pt - 0.5:
		problems.append("%s: %.0f x %.0f pt, under %.0f pt" % [where, r.size.x / pt, r.size.y / pt, MIN_TOUCH])
	if not safe.grow(0.5).encloses(r):
		problems.append("%s: %s is outside the safe area %s" % [where, _pts(r, pt), _pts(safe, pt)])


## Every visible label and button text under `node` is at least 11 pt.
func _check_fonts(node: Node, where: String, pt: float) -> void:
	for c in node.find_children("*", "Control", true, false):
		var ctl := c as Control
		if not ctl.is_visible_in_tree():
			continue
		if (ctl is Label and (ctl as Label).text != "") or (ctl is Button and (ctl as Button).text != ""):
			var fs := ctl.get_theme_font_size("font_size")
			if fs < MIN_LABEL * pt - 0.5:
				problems.append("%s: '%s' is %.1f pt" % [where, ctl.get("text"), fs / pt])
			# The words on a button fit inside it (a label that isn't cut short on purpose).
			var button := _button_of(ctl)
			if ctl is Label and button != null and not (ctl as Label).clip_text:
				var w := ctl.get_theme_font("font").get_string_size((ctl as Label).text, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
				if w > button.size.x - 2.0:
					problems.append("%s: '%s' (%.0f pt) is wider than its button (%.0f pt)" % [where, (ctl as Label).text, w / pt, button.size.x / pt])


## The button a label sits on (two levels up: Button > words > Label), if any.
static func _button_of(c: Control) -> Button:
	var p := c.get_parent()
	if p != null and p.get_parent() is Button:
		return p.get_parent() as Button
	return null


static func _pts(r: Rect2, pt: float) -> String:
	return "(%.0f,%.0f %.0fx%.0f pt)" % [r.position.x / pt, r.position.y / pt, r.size.x / pt, r.size.y / pt]
