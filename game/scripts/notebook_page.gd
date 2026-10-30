extends Control
## Loop MW-1 (docs/design/vision.md 4.1): the MOJA WARSZAWA page, the settings card's fifth tab
## (settings_panel.gd). A row of the 9 chapters (a number for the chapter's icon until the
## PixelLab icons come, and its count k/8), the chapter's name, then its 8 cards in a grid of
## 4 x 2: a found card shows its name (Polish over English), one not found yet only "?" and the
## chapter. Tapping a card opens it: name, fact and joke (Polish over English), the address,
## the hours for a night venue and the day it was found; WRÓĆ goes back to the grid.
##
## Drawn by hand, not as Buttons and Labels: every box is one triangle array (one draw call)
## and the words go after it grouped by size (a font size is a texture of its own), so the
## open page costs a handful of 2D draw calls whatever it shows (the HUD's rule 6, DEVELOPMENT
## "Performance budgets"); nothing is drawn while the panel is closed. Sized in points like
## the panel; every target at least 44 pt.

const INK := Color("#fbf7ee")
const SUB := Color("#c9c2d8")
const ACCENT := Color("#ffd23f")
## Collectibles' gold (the art bible): a complete chapter's number.
const GOLD := Color("#f0b429")
const DIM := Color(1, 1, 1, 0.07)
const EDGE := Color(1, 1, 1, 0.18)
const SHUT := Color(1, 1, 1, 0.03)
const ON := Color(1, 0.82, 0.25, 0.22)
## The card under a box's fill (settings_panel.gd CARD_BG, opaque): a box is its edge colour,
## then this inset, then its fill.
const UNDER := Color(0.07, 0.06, 0.1, 1.0)
const T_BIG := 22.0
const T_BODY := 15.0
const T_SUB := 13.0
const T_LABEL := 11.0
## The page in points (at least; it takes the card's width when that is more): the chapters'
## row, a gap, the area (the grid or one card).
const MIN_W := 476.0
const ROW := 44.0
const GAP := 6.0
const AREA := 204.0
const CHIP_GAP := 4.0
const TITLE_H := 20.0
const BACK_W := 76.0
## Polish day names to English ones, for the hours' gloss.
const DAYS := {"PN": "Mon", "WT": "Tue", "ŚR": "Wed", "CZ": "Thu", "PT": "Fri", "SB": "Sat", "ND": "Sun"}

var pt := 1.0
## The notebook (notebook.gd): chapters, places, the record.
var book: Node
## The chapter shown (its index) and the card open ("" for the grid).
var chapter := 0
var card := ""
## The page's width in points (settings_panel.gd sets it to the card's inner width).
var W := MIN_W
## What a tap hits: [Rect2, "chapter" | "card" | "back", value], rebuilt by each draw.
var _hits: Array = []
var _pts := PackedVector2Array()
var _cols := PackedColorArray()
var _idx := PackedInt32Array()
## Words to draw after the boxes, by size: size -> [[pos, text, colour, width, align, lines]].
var _words := {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(MIN_W, ROW + GAP + AREA) * pt
	gui_input.connect(_on_input)


func _px(points: float) -> int:
	return maxi(1, roundi(points * pt))


## Shows a chapter (index, id or number "1"-"9") or a place's card (its id): --notebook=.
func show_target(target: String) -> void:
	card = ""
	if book == null or target == "":
		queue_redraw()
		return
	if book.by_id.has(target):
		var place: Dictionary = book.places[book.by_id[target]]
		chapter = int(place["chapter_i"])
		card = target
	else:
		for i in book.chapters.size():
			if str(book.chapters[i]["id"]) == target or str(i + 1) == target:
				chapter = i
	queue_redraw()


## The touch targets in global pixels, by name (tools/check_hud.gd: 44 pt each way).
func hit_rects() -> Dictionary:
	var out := {}
	for h: Array in _hits:
		var r: Rect2 = h[0]
		out["notebook_%s_%s" % [h[1], h[2]]] = Rect2(get_global_transform() * r.position, r.size * get_global_transform().get_scale())
	return out


func _on_input(e: InputEvent) -> void:
	var mb := e as InputEventMouseButton
	if mb == null or not mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	for h: Array in _hits:
		if (h[0] as Rect2).has_point(mb.position):
			match str(h[1]):
				"chapter":
					chapter = int(h[2])
					card = ""
				"card":
					card = str(h[2])
				"back":
					card = ""
			accept_event()
			queue_redraw()
			return


# --- drawing -------------------------------------------------------------------------------

func _draw() -> void:
	W = maxf(MIN_W, size.x / pt)
	_hits.clear()
	_pts.clear()
	_cols.clear()
	_words.clear()
	if book == null or book.chapters.is_empty():
		_word(Vector2.ZERO, "Zeszyt pusty", T_BODY, SUB)
		_flush()
		return
	chapter = clampi(chapter, 0, book.chapters.size() - 1)
	_chapters_row()
	if card != "" and book.by_id.has(card):
		_card_view(book.places[book.by_id[card]])
	else:
		_grid_view()
	_flush()


func _chapters_row() -> void:
	var n: int = book.chapters.size()
	var w := (W - CHIP_GAP * (n - 1)) / n
	for i in n:
		var r := Rect2(Vector2(i * (w + CHIP_GAP), 0.0) * pt, Vector2(w, ROW) * pt)
		var k: int = book.found_in(i)
		var total: int = book.chapter_places(i).size()
		_box(r, ON if i == chapter else DIM, ACCENT if i == chapter else EDGE, 1.0 if i == chapter else 0.5)
		var done := total > 0 and k >= total
		_word(r.position + Vector2(0, 4.0 * pt), str(i + 1), T_BODY, GOLD if done else INK, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		_word(r.position + Vector2(0, 24.0 * pt), "%d/%d" % [k, total], T_LABEL, GOLD if done else SUB, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
		_hits.append([r, "chapter", i])


func _grid_view() -> void:
	var c: Dictionary = book.chapters[chapter]
	var top := (ROW + GAP) * pt
	var title := str(c["name_pl"]).to_upper()
	_word(Vector2(0, top), title, T_SUB, ACCENT)
	var font := ThemeDB.fallback_font
	var tw := font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, _px(T_SUB)).x
	var list: Array = book.chapter_places(chapter)
	_word(Vector2(tw + 8.0 * pt, top + 2.0 * pt), "%s · %d/%d" % [c["name_en"], book.found_in(chapter), list.size()], T_LABEL, SUB)
	var cols := 4
	var cw := (W - GAP * (cols - 1)) / cols
	var ch := (AREA - TITLE_H - GAP) / 2.0
	for k in list.size():
		var place: Dictionary = list[k]
		var at := Vector2((k % cols) * (cw + GAP), ROW + GAP + TITLE_H + (k / cols) * (ch + GAP))
		var r := Rect2(at * pt, Vector2(cw, ch - GAP * 0.5) * pt)
		var id := str(place["id"])
		_hits.append([r, "card", id])
		var inner := r.size.x - 12.0 * pt
		if book.is_found(id):
			_box(r, DIM, EDGE, 0.5)
			var y := r.position.y + 8.0 * pt
			var pl := str(place["name_pl"])
			var lines := _lines(pl, T_SUB, inner, 3)
			_word(Vector2(r.position.x + 6.0 * pt, y), pl, T_SUB, INK, inner, HORIZONTAL_ALIGNMENT_LEFT, 3)
			y += lines * _line_h(T_SUB)
			# The foot: the night venue's hours over the day it was found.
			var foot := PackedStringArray()
			if place.has("hours"):
				foot.append(str(place["hours"]))
			var day := int(book.wallet.notes.get(id, 0)) if book.wallet != null else 0
			if day > 0:
				foot.append("%02d.%02d.%04d" % [day % 100, (day / 100) % 100, day / 10000])
			var foot_y := r.end.y - 5.0 * pt - foot.size() * _line_h(T_LABEL)
			for f in foot.size():
				_word(Vector2(r.position.x + 6.0 * pt, foot_y + f * _line_h(T_LABEL)), foot[f], T_LABEL,
						ACCENT if f == 0 and place.has("hours") else SUB, inner)
			var en := str(place["name_en"])
			if en != pl and y + _line_h(T_LABEL) < foot_y:
				_word(Vector2(r.position.x + 6.0 * pt, y), en, T_LABEL, SUB, inner, HORIZONTAL_ALIGNMENT_LEFT,
						maxi(1, int((foot_y - y) / _line_h(T_LABEL))))
		else:
			_box(r, SHUT, EDGE, 0.5)
			_word(Vector2(r.position.x, r.position.y + r.size.y * 0.5 - _line_h(T_BIG) * 0.75), "?", T_BIG, SUB,
					r.size.x, HORIZONTAL_ALIGNMENT_CENTER)
			_word(Vector2(r.position.x, r.end.y - _line_h(T_LABEL) - 5.0 * pt), "rozdz. %d · ch. %d" % [chapter + 1, chapter + 1],
					T_LABEL, SUB, r.size.x, HORIZONTAL_ALIGNMENT_CENTER)


func _card_view(place: Dictionary) -> void:
	var c: Dictionary = book.chapters[chapter]
	var top := (ROW + GAP) * pt
	var back := Rect2(Vector2(0, top), Vector2(BACK_W, ROW) * pt)
	_box(back, DIM, EDGE, 0.5)
	_word(back.position + Vector2(0, 4.0 * pt), "WRÓĆ", T_BODY, INK, back.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_word(back.position + Vector2(0, 24.0 * pt), "back", T_LABEL, SUB, back.size.x, HORIZONTAL_ALIGNMENT_CENTER)
	_hits.append([back, "back", 0])
	var x := (BACK_W + 10.0) * pt
	var wide := W * pt - x
	var id := str(place["id"])
	var list: Array = book.chapter_places(chapter)
	var where := "%d/%d · %s · %s" % [list.find(place) + 1, list.size(), c["name_pl"], c["name_en"]]
	if not book.is_found(id):
		_word(Vector2(x, top + 2.0 * pt), "?", T_BIG, ACCENT, wide)
		_word(Vector2(x, top + 28.0 * pt), where, T_LABEL, SUB, wide)
		var y := top + (ROW + 14.0) * pt
		_word(Vector2(0, y), "Jeszcze nie w zeszycie. Szukaj „?” na minimapie.", T_SUB, INK, W * pt)
		_word(Vector2(0, y + _line_h(T_SUB)), "Not in the notebook yet. Look for the ? on the minimap.", T_LABEL, SUB, W * pt)
		return
	_word(Vector2(x, top + 2.0 * pt), str(place["name_pl"]), T_BODY, ACCENT, wide, HORIZONTAL_ALIGNMENT_LEFT, 1)
	var en := str(place["name_en"])
	_word(Vector2(x, top + 24.0 * pt), (en + " · " if en != str(place["name_pl"]) else "") + where, T_LABEL, SUB, wide,
			HORIZONTAL_ALIGNMENT_LEFT, 1)
	var y := top + (ROW + 12.0) * pt
	var full := W * pt
	for pair in [place.get("fact", ["", ""]), place.get("joke", ["", ""])]:
		var a: Array = pair
		_word(Vector2(0, y), str(a[0]), T_SUB, INK, full, HORIZONTAL_ALIGNMENT_LEFT, 2)
		y += _lines(str(a[0]), T_SUB, full, 2) * _line_h(T_SUB)
		_word(Vector2(0, y), str(a[1]), T_LABEL, SUB, full, HORIZONTAL_ALIGNMENT_LEFT, 2)
		y += _lines(str(a[1]), T_LABEL, full, 2) * _line_h(T_LABEL) + 8.0 * pt
	var meta := meta_lines(place, int(book.wallet.notes.get(id, 0)) if book.wallet != null else 0)
	_word(Vector2(0, y), meta[0], T_LABEL, ACCENT, full, HORIZONTAL_ALIGNMENT_LEFT, 1)
	_word(Vector2(0, y + _line_h(T_LABEL)), meta[1], T_LABEL, SUB, full, HORIZONTAL_ALIGNMENT_LEFT, 1)


## A card's last two lines, Polish over English: the address of a place that is not a venue
## (without the anchor's notes in brackets), the hours of a night venue, the day it was found.
static func meta_lines(place: Dictionary, found: int) -> Array[String]:
	var pl := PackedStringArray()
	var en := PackedStringArray()
	# Never a venue's address: it can name the real business there ("Jasna 1": brand_denylist.json).
	if place.has("address") and not "venue" in place.get("tags", []):
		var a := str(place["address"])
		if a.contains("("):
			a = a.substr(0, a.find("(")).strip_edges()
		pl.append(a)
	if place.has("hours"):
		var h := str(place["hours"])
		pl.append("otwarte %s" % h)
		var g := h
		for d: String in DAYS:
			g = g.replace(d, DAYS[d])
		en.append("open %s" % g)
	if found > 0:
		var date := "%02d.%02d.%04d" % [found % 100, (found / 100) % 100, found / 10000]
		pl.append("wpis z %s" % date)
		en.append("found %s" % date)
	return [" · ".join(pl), " · ".join(en)]


# --- pieces --------------------------------------------------------------------------------

func _line_h(points: float) -> float:
	return ThemeDB.fallback_font.get_height(_px(points))


## How many lines `text` takes at `width` pixels (at most `most`).
func _lines(text: String, points: float, width: float, most: int) -> int:
	if text == "":
		return 0
	var font := ThemeDB.fallback_font
	var h := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, _px(points), most).y
	return clampi(roundi(h / font.get_height(_px(points))), 1, most)


## Queues words: `at` is the top left of their first line.
func _word(at: Vector2, text: String, points: float, colour: Color, width := -1.0,
		align := HORIZONTAL_ALIGNMENT_LEFT, lines := 1) -> void:
	if text == "":
		return
	if not _words.has(points):
		_words[points] = []
	_words[points].append([at, text, colour, width, align, lines])


## A box: its edge (`ew` pt), the card's colour inside it, then its fill; round corners.
func _box(r: Rect2, fill: Color, edge: Color, ew: float) -> void:
	var e := maxf(1.0, ew * pt)
	_round(r, 8.0 * pt, edge)
	_round(r.grow(-e), 8.0 * pt - e, UNDER)
	_round(r.grow(-e), 8.0 * pt - e, fill)


func _rect(r: Rect2, col: Color) -> void:
	var b := Vector2(r.end.x, r.position.y)
	var d := Vector2(r.position.x, r.end.y)
	_pts.append_array(PackedVector2Array([r.position, b, r.end, r.position, r.end, d]))
	for i in 6:
		_cols.append(col)


func _round(r: Rect2, radius: float, col: Color) -> void:
	var k := clampf(radius, 0.0, minf(r.size.x, r.size.y) * 0.5)
	_rect(r.grow_individual(0.0, -k, 0.0, -k), col)
	_rect(Rect2(r.position + Vector2(k, 0.0), Vector2(r.size.x - 2.0 * k, k)), col)
	_rect(Rect2(Vector2(r.position.x + k, r.end.y - k), Vector2(r.size.x - 2.0 * k, k)), col)
	var corners := [[r.position + Vector2(k, k), PI], [Vector2(r.end.x - k, r.position.y + k), PI * 1.5],
			[r.end - Vector2(k, k), 0.0], [Vector2(r.position.x + k, r.end.y - k), PI * 0.5]]
	for cn: Array in corners:
		var c: Vector2 = cn[0]
		var a0: float = cn[1]
		for s in 4:
			var u := a0 + PI * 0.5 * s / 4.0
			var v := a0 + PI * 0.5 * (s + 1) / 4.0
			_pts.append_array(PackedVector2Array([c, c + Vector2(cos(u), sin(u)) * k, c + Vector2(cos(v), sin(v)) * k]))
			for i in 3:
				_cols.append(col)


## The boxes in one call, then the words size by size.
func _flush() -> void:
	var n := _pts.size()
	if n > 0:
		if _idx.size() < n:
			for i in range(_idx.size(), n):
				_idx.append(i)
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), _idx.slice(0, n), _pts, _cols)
	var font := ThemeDB.fallback_font
	for points: float in [T_BIG, T_BODY, T_SUB, T_LABEL]:
		var fs := _px(points)
		var ascent := font.get_ascent(fs)
		for w: Array in _words.get(points, []):
			var at: Vector2 = w[0] + Vector2(0, ascent)
			if int(w[5]) > 1:
				draw_multiline_string(font, at, w[1], w[4], w[3], fs, int(w[5]), w[2])
			else:
				draw_string(font, at, w[1], w[4], w[3], fs, w[2])
