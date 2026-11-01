extends RefCounted
## Neon shop signs for the night: generic Polish shop words (no brands) in a tiny
## 5×7 pixel font, drawn into one atlas texture at build time, and placed on the
## ground floors of buildings that face a street. Each sign is one quad of a
## MultiMesh (neon.gdshader): the instance colour is the tube colour, the custom
## data picks the word and how it is mounted (on a dark plate or bare on the wall).
## The map builder adds them under a "Neon" node, which the game hides by day.

const WORDS := ["KEBAB 24H", "BAR MLECZNY", "APTEKA", "KWIATY", "HOTEL", "KANTOR", "PIZZA", "KLUB", "NOCNY"]
## The landmarks loop: words only the landmarks wear (never a shop's), after WORDS in the atlas:
## the parody of the brand on Warsaw Spire's crown, the mall by Rondo Radosława's.
const LANDMARK_WORDS := ["SAMSONG", "ARKADKA", "PREZYDENT", "NOWOTEL", "WESTYNKA", "CHILTON", "INTERKONTI", "N", "O", "W", "T", "E", "L", "BANK POLSKA",
		"METROPOLKA", "ENELMEDIK", "ACORN", "HOTELS", "--",
		# First scene item 3: the Eastern Wall's stores (parodies of their roof names).
		"JUNIOREK", "SAWKA", "WARSIK",
		# The stores' printed ad banners (the Mac photo check, 2026-11-01).
		"PROMOCJA", "LODY", "WYPRZEDAZ",
		# The tower and the slab behind the stores (specs C and D): a parody.
		"KOKA-KOLKA"]
## Tube colours (linear, bright): pink, cyan, violet, and a few words' usual colours.
const PINK := Color(1.0, 0.1, 0.55)
const CYAN := Color(0.1, 0.9, 1.0)
const VIOLET := Color(0.62, 0.25, 1.0)
const WORD_COLOURS := {"APTEKA": Color(0.2, 1.0, 0.45), "KANTOR": Color(1.0, 0.72, 0.12), "HOTEL": Color(1.0, 0.22, 0.25)}
## Font pixel size in metres, and the atlas row layout (pixels).
const PIXEL := 0.2
const PAD := 2
const GLYPH_H := 7
const ROW_H := GLYPH_H + 2 * PAD
const ATLAS_W := 72

const FONT := {
	"A": [".###.", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"B": ["####.", "#...#", "#...#", "####.", "#...#", "#...#", "####."],
	"C": [".###.", "#...#", "#....", "#....", "#....", "#...#", ".###."],
	"D": ["####.", "#...#", "#...#", "#...#", "#...#", "#...#", "####."],
	"E": ["#####", "#....", "#....", "####.", "#....", "#....", "#####"],
	"H": ["#...#", "#...#", "#...#", "#####", "#...#", "#...#", "#...#"],
	"I": [".###.", "..#..", "..#..", "..#..", "..#..", "..#..", ".###."],
	"J": ["..###", "...#.", "...#.", "...#.", "#..#.", "#..#.", ".##.."],
	"K": ["#...#", "#..#.", "#.#..", "##...", "#.#..", "#..#.", "#...#"],
	"L": ["#....", "#....", "#....", "#....", "#....", "#....", "#####"],
	"M": ["#...#", "##.##", "#.#.#", "#.#.#", "#...#", "#...#", "#...#"],
	"N": ["#...#", "##..#", "#.#.#", "#..##", "#...#", "#...#", "#...#"],
	"O": [".###.", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"S": [".####", "#....", "#....", ".###.", "....#", "....#", "####."],
	"G": [".###.", "#...#", "#....", "#.###", "#...#", "#...#", ".####"],
	"P": ["####.", "#...#", "#...#", "####.", "#....", "#....", "#...."],
	"R": ["####.", "#...#", "#...#", "####.", "#.#..", "#..#.", "#...#"],
	"T": ["#####", "..#..", "..#..", "..#..", "..#..", "..#..", "..#.."],
	"U": ["#...#", "#...#", "#...#", "#...#", "#...#", "#...#", ".###."],
	"W": ["#...#", "#...#", "#...#", "#.#.#", "#.#.#", "##.##", "#...#"],
	"Y": ["#...#", "#...#", ".#.#.", "..#..", "..#..", "..#..", "..#.."],
	"Z": ["#####", "....#", "...#.", "..#..", ".#...", "#....", "#####"],
	"-": [".....", ".....", ".....", "#####", ".....", ".....", "....."],
	"2": [".###.", "#...#", "....#", "...#.", "..#..", ".#...", "#####"],
	"4": ["...#.", "..##.", ".#.#.", "#..#.", "#####", "...#.", "...#."],
}


## Width of a word in font pixels (5 per letter, 1 between letters, 3 for a space).
static func word_width(word: String) -> int:
	var w := 0
	for i in word.length():
		if i > 0:
			w += 1
		w += 2 if word[i] == " " else 5
	return w


## The atlas: one row per word, red = the tube, green = its glow (the tube grown by
## a pixel or two and faded), so the shader can draw a pixel-art halo.
static func atlas() -> ImageTexture:
	var all := all_words()
	var h := ROW_H * all.size()
	var img := Image.create_empty(ATLAS_W, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 1))
	for r in all.size():
		var word: String = all[r]
		var x := PAD
		var tube := {}
		for i in word.length():
			if i > 0:
				x += 1
			var ch := word[i]
			if ch == " ":
				x += 2
				continue
			var rows: Array = FONT[ch]
			for gy in GLYPH_H:
				var line: String = rows[gy]
				for gx in 5:
					if line[gx] == "#":
						tube[Vector2i(x + gx, r * ROW_H + PAD + gy)] = true
			x += 5
		for p in tube:
			for dy in range(-2, 3):
				for dx in range(-2, 3):
					var q := Vector2i(p.x + dx, p.y + dy)
					if q.x < 0 or q.y < r * ROW_H or q.x >= ATLAS_W or q.y >= (r + 1) * ROW_H:
						continue
					var g := 1.0 - (absi(dx) + absi(dy)) / 4.0
					var c := img.get_pixelv(q)
					img.set_pixelv(q, Color(c.r, maxf(c.g, g), 0, 1))
		for p in tube:
			img.set_pixelv(p, Color(1, 1, 0, 1))
	return ImageTexture.create_from_image(img)


## The atlas rows: the shop words, then the landmarks' words.
static func all_words() -> Array:
	return WORDS + LANDMARK_WORDS


## The tube colour for a word, varied by a 0..1 pick.
static func colour_for(word: String, pick: float) -> Color:
	if WORD_COLOURS.has(word) and pick < 0.7:
		return WORD_COLOURS[word]
	var choices := [PINK, CYAN, VIOLET]
	return choices[int(pick * 30.0) % 3]


## The quad every sign uses: 1 × 1, facing +Z, UV.y = 0 at the top.
static func quad() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var corners := [Vector3(-0.5, 0.5, 0), Vector3(0.5, 0.5, 0), Vector3(0.5, -0.5, 0), Vector3(-0.5, -0.5, 0)]
	var uvs := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
	for k in [0, 1, 2, 0, 2, 3]:
		st.set_normal(Vector3.BACK)
		st.set_uv(uvs[k])
		st.add_vertex(corners[k])
	return st.commit()


## A sign's transform on a wall: `at` is the middle of its bottom edge on the
## wall face, `out` the wall's outward normal. Text reads left to right from
## outside: the quad's +X is (out.z, 0, -out.x).
static func place(word: String, at: Vector3, out: Vector3) -> Transform3D:
	var length := (word_width(word) + 2 * PAD) * PIXEL
	var height := ROW_H * PIXEL
	var right := Vector3(out.z, 0.0, -out.x).normalized()
	var basis := Basis(right * length, Vector3.UP * height, out.normalized())
	return Transform3D(basis, at + Vector3.UP * height * 0.5 + out.normalized() * 0.14)


static func length_of(word: String) -> float:
	return (word_width(word) + 2 * PAD) * PIXEL
