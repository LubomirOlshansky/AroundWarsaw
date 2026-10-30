extends RefCounted
## v0.8 "Landmarks": the buildings that make it Warsaw at a glance, built in code
## from the real footprints and heights in centrum.json (OpenStreetMap outlines and
## building parts, which carry `height` / `min_height`) instead of their GUGiK LoD2 or
## OpenStreetMap lumps: the Palace of Culture and Science (stepped tower, attics and
## pinnacles, clock faces, the gilded spire, the Congress Hall and the wings),
## Złote Tarasy's glass wave, the Rotunda, Varso Tower and its spire, Stadion Narodowy,
## Warszawa Centralna's roof and the gate towers of Most Poniatowskiego. The landmarks loop
## (2026-10-30) adds the skyline's towers (TOWERS: Złota 44, Warsaw Spire, Q22, Rondo 1 and
## the rest), each from its mapped parts in its own colour and skin, and Muzeum Narodowe.
##
## map_builder.gd asks `replaces(p)` for every LoD2 building and OpenStreetMap outline
## (whatever stands in a landmark's zone is dropped), then `build(st)` adds the models
## to the city's building meshes. building.gdshader draws them: UV2.x >= 2 is a
## material code (M_*), UV2.y the wall's top above the ground, UV the metres along and
## up a wall (UV.x < 0 on tops). Every triangle also goes into the helicopter's roof
## grid (map_builder._roof_triangle) and the grid the game picks a tapped landmark
## from; the walls at street level stop the car.

const CLOCKWISE_FRONT := true

## Material codes for building.gdshader (UV2.x); the fraction is a parameter.
const M_MONUMENT := 2.0   # stone, tall windows between piers, pilasters (the Palace)
const M_STONE := 3.0      # plain stone: pinnacles, plinths, columns
const M_GOLD := 4.0       # the Palace's spire
const M_DIAL := 5.0       # clock dials: lit at night
const M_WEAVE := 6.0      # Stadion Narodowy's red-and-white skin
const M_GLASS_ROOF := 7.0 # Złote Tarasy's wave
const M_PAVILION := 8.0   # glass lit from inside: + 0 warm (the Rotunda), + 0.5 cool (Varso's crown)
const M_ATTIC := 9.0      # a parapet cut into merlons; fraction = its height / 10 m
const M_LAMP := 10.0      # glows at night
const M_MEMBRANE := 11.0  # the stadium's roof membrane
const M_GLASS := 12.0     # curtain wall with mullions (Varso)
const M_SKIN := 13.0      # a tower's own skin; fraction = style / 16 (S_*, building.gdshader skin())

## The skins (building.gdshader S_*): Złota 44's white exoskeleton, Warsaw Spire's diamonds,
## silver floor bands, vertical fins, a white grid, balcony slabs, dark glass, gold glass,
## and an open frame (its panes cut away).
const S_SAIL := 0
const S_DIAMOND := 1
const S_BANDS := 2
const S_FINS := 3
const S_GRID := 4
const S_RIBBON := 5
const S_DARK := 6
const S_GOLD := 7
const S_FRAME := 8

## The landmarks loop (2026-10-30): the skyline's towers, so each reads as itself and not as one
## more blue box. Each is built from its mapped building parts (the outline `osm` names; what
## else stands in it is dropped) in its skin, glass colour and roof colour; `crest` adds its
## top: "slope" (Złota 44's sail falls away from its high corner), "frame" (Rondo 1's open
## crown); `mapped` keeps the parts' mapped colours. Colours from photographs, kept a step
## paler than life for the game's palette.
const TOWERS := [
	{"key": "zlota44", "osm": "Złota 44", "style": S_SAIL, "glass": "#b4c8d3", "roof": "#e4e8ea", "crest": "slope"},
	{"key": "spire", "osm": "Warsaw Spire", "style": S_DIAMOND, "glass": "#5a8fb8", "roof": "#a3b6c4"},
	{"key": "q22", "osm": "Q22", "style": S_BANDS, "glass": "#8ba2b4", "roof": "#bcc4ca"},
	{"key": "rondo1", "osm": "Rondo 1", "style": S_FINS, "glass": "#6f8ea4", "roof": "#a9b3b9", "crest": "frame"},
	{"key": "plater49", "osm": "InterContinental", "style": S_GRID, "glass": "#5f7f9a", "roof": "#c3c7c9"},
	{"key": "cosmopolitan", "osm": "Cosmopolitan", "style": S_RIBBON, "glass": "#4d6574", "roof": "#dfe2e0"},
	{"key": "wtt", "osm": "Warsaw Trade Tower", "style": S_BANDS, "glass": "#3d6a7a", "roof": "#8d979c"},
	{"key": "skyliner", "osm": "Skyliner", "style": S_FINS, "glass": "#2f6190", "roof": "#9aa6b0"},
	{"key": "unit", "osm": "Warsaw Unit", "style": S_BANDS, "glass": "#4f87ba", "roof": "#8a96a0"},
	{"key": "mennica", "osm": "Mennica Legacy Tower", "style": S_FINS, "glass": "#6d95ba", "roof": "#b5c0c9", "crest": "slope"},
	{"key": "gpy", "osm": "Generation Park Y", "style": S_DARK, "glass": "#46525e", "roof": "#6c747c", "crest": "slope"},
	# The Warsaw HUB's two 130 m towers (unnamed in OpenStreetMap: found by a point, `at`, in
	# the tallest building there), white fins on pale glass, their tops cut on a slope.
	{"key": "hub_b", "at": Vector2(-2677.0, 576.0), "style": S_FINS, "glass": "#8fb2c8", "roof": "#c9d2d8", "crest": "slope"},
	{"key": "hub_c", "at": Vector2(-2677.0, 633.0), "style": S_FINS, "glass": "#8fb2c8", "roof": "#c9d2d8", "crest": "slope"},
	{"key": "skysawa", "osm": "Skysawa", "style": S_BANDS, "glass": "#7e93a3", "roof": "#a7b0b6"},
	{"key": "blekitny", "osm": "Błękitny Wieżowiec", "style": S_GOLD, "glass": "#c9a45c", "roof": "#8e8a80"},
	{"key": "wcf", "osm": "Warszawskie Centrum Finansowe", "style": S_DARK, "glass": "#4d6862", "roof": "#7d8580"},
	{"key": "lim", "osm": "Centrum LIM", "style": S_DARK, "glass": "#6a5442", "roof": "#6e6a66"},
	{"key": "chalubinskiego8", "osm": "Chałubińskiego 8", "style": S_FINS, "glass": "#2f6f8f", "roof": "#c9cfd2", "mapped": true},
	{"key": "spektrum", "osm": "Spektrum Tower", "style": S_BANDS, "glass": "#2f5563", "roof": "#7c878c", "mapped": true},
	{"key": "bridge", "osm": "The Bridge", "style": S_FINS, "glass": "#6d8da6", "roof": "#b0bac2"},
	# The second pass: the rest of the skyline over 80 m (the hotels by their addresses).
	{"key": "grzybowska63", "osm": "Hilton Warsaw City", "style": S_BANDS, "glass": "#4d7590", "roof": "#9aa5ad"},
	{"key": "jp2_21", "osm": "The Westin Warsaw", "style": S_GRID, "glass": "#86aca7", "roof": "#a9b5b3", "mapped": true},
	{"key": "marszalkowska94", "osm": "Novotel Warszawa Centrum", "style": S_RIBBON, "glass": "#3b4a55", "roof": "#c9c9c2"},
	{"key": "central", "osm": "Central Tower", "style": S_DARK, "glass": "#3e5c78", "roof": "#6f7d88"},
	{"key": "ilmet", "osm": "Ilmet", "style": S_BANDS, "glass": "#7d5a48", "roof": "#8c8278"},
	{"key": "platinum_a", "osm": "Platinum Tower A", "style": S_RIBBON, "glass": "#6b7f8e", "roof": "#c4c8c8"},
	{"key": "platinum_b", "osm": "Platinum Tower B", "style": S_RIBBON, "glass": "#6b7f8e", "roof": "#c4c8c8"},
	{"key": "lucka", "osm": "Łucka City", "style": S_RIBBON, "glass": "#7c8c98", "roof": "#bfc3c3"},
	{"key": "widok", "osm": "Widok Towers", "style": S_FINS, "glass": "#4f677b", "roof": "#8d969c"},
]

const SANDSTONE := Color("#d8c49c")   # the Palace (bake_gugik.py LANDMARKS)
const SANDSTONE_LIGHT := Color("#e6d6b2")
const PATINA := Color("#9fbcae")
const GOLD := Color("#e8b632")

## The info cards: name, then Polish and English lines. Facts kept to what is certain.
const INFO := {
	"palace": ["Pałac Kultury i Nauki",
			"237 m razem z iglicą. Otwarty w 1955 roku.",
			"237 m with its spire. Opened in 1955."],
	"tarasy": ["Złote Tarasy",
			"Centrum handlowe pod falującym szklanym dachem. Otwarte w 2007 roku.",
			"A shopping centre under a rolling glass roof. Opened in 2007."],
	"rotunda": ["Rotunda",
			"Okrągły szklany pawilon u zbiegu Marszałkowskiej i Alej Jerozolimskich. Klasyczne miejsce spotkań: „pod Rotundą”.",
			"A round glass pavilion where Marszałkowska meets Al. Jerozolimskie. The classic place to meet: \"under the Rotunda\"."],
	"varso": ["Varso Tower",
			"310 m z iglicą: najwyższy budynek w Unii Europejskiej.",
			"310 m with its spire: the tallest building in the European Union."],
	"stadium": ["Stadion Narodowy",
			"Otwarty w 2012 roku na Euro 2012, w misie dawnego Stadionu Dziesięciolecia. Biało-czerwona plecionka fasady.",
			"Opened in 2012 for Euro 2012, in the bowl of the old Tenth-Anniversary Stadium. A red-and-white woven skin."],
	"centralna": ["Warszawa Centralna",
			"Dworzec otwarty w 1975 roku.",
			"The main station, opened in 1975."],
	"poniatowski": ["Most Poniatowskiego",
			"Most otwarty w 1914 roku. Wieże strzegą wjazdów.",
			"The bridge opened in 1914. Its towers guard the way on."],
	"zlota44": ["Złota 44",
			"192 m. Apartamentowiec Daniela Libeskinda: biały stalowy szkielet jak skrzydło.",
			"192 m. Daniel Libeskind's apartment tower: a white steel frame like a wing."],
	"spire": ["Warsaw Spire",
			"220 m. Szklana tafla w romby. Otwarty w 2016 roku.",
			"220 m. Glass laid in diamonds. Opened in 2016."],
	"q22": ["Q22",
			"155 m. Otwarty w 2016 roku.",
			"155 m. Opened in 2016."],
	"rondo1": ["Rondo 1",
			"192 m razem z ażurową koroną. Otwarty w 2006 roku.",
			"192 m with its open crown. Opened in 2006."],
	"plater49": ["Emilii Plater 49",
			"164 m. Dolne piętra przecina wielki prześwit.",
			"164 m. A great gap cuts through its lower floors."],
	"cosmopolitan": ["Cosmopolitan",
			"160 m. Projekt Helmuta Jahna, białe pasy balkonów.",
			"160 m. Designed by Helmut Jahn: white bands of balconies."],
	"wtt": ["Warsaw Trade Tower",
			"208 m z iglicą. Otwarty w 1999 roku.",
			"208 m with its spire. Opened in 1999."],
	"skyliner": ["Skyliner",
			"195 m przy rondzie Daszyńskiego.",
			"195 m by Rondo Daszyńskiego."],
	"unit": ["Warsaw Unit",
			"202 m przy rondzie Daszyńskiego.",
			"202 m by Rondo Daszyńskiego."],
	"hub_b": ["The Warsaw HUB",
			"Dwie wieże po 130 m nad węzłem przesiadkowym przy rondzie Daszyńskiego.",
			"Two 130 m towers over the interchange at Rondo Daszyńskiego."],
	"hub_c": ["The Warsaw HUB",
			"Dwie wieże po 130 m nad węzłem przesiadkowym przy rondzie Daszyńskiego.",
			"Two 130 m towers over the interchange at Rondo Daszyńskiego."],
	"mennica": ["Mennica Legacy Tower",
			"140 m przy Prostej.",
			"140 m on Prosta."],
	"gpy": ["Generation Park Y",
			"140 m przy rondzie Daszyńskiego.",
			"140 m by Rondo Daszyńskiego."],
	"skysawa": ["Skysawa",
			"155 m przy Świętokrzyskiej.",
			"155 m on Świętokrzyska."],
	"blekitny": ["Błękitny Wieżowiec",
			"120 m przy placu Bankowym. Błękitny z nazwy, złoty ze szkła.",
			"120 m on Plac Bankowy. Blue by name, gold by its glass."],
	"wcf": ["Warszawskie Centrum Finansowe",
			"144 m. Otwarte w 1998 roku.",
			"144 m. Opened in 1998."],
	"lim": ["Centrum LIM",
			"140 m przy Alejach Jerozolimskich. Otwarte w 1989 roku.",
			"140 m on Al. Jerozolimskie. Opened in 1989."],
	"chalubinskiego8": ["Chałubińskiego 8",
			"140 m. Białe żebra na niebieskim szkle.",
			"140 m. White ribs on blue glass."],
	"spektrum": ["Spektrum Tower",
			"Ciemne szkło przy Twardej.",
			"Dark glass on Twarda."],
	"bridge": ["The Bridge",
			"174 m przy Grzybowskiej.",
			"174 m on Grzybowska."],
	"grzybowska63": ["Chilton", "Hotel przy Grzybowskiej 63, 94 m. Na luzie.", "A hotel at Grzybowska 63, 94 m. Chilled."],
	"jp2_21": ["Westynka", "Hotel przy Jana Pawła II 21, 94 m, z rurą szkła na fasadzie.", "A hotel at Jana Pawła II 21, 94 m, with a glass tube up its front."],
	"marszalkowska94": ["Nowotel", "Hotel przy Marszałkowskiej 94/98, 95 m. Nowy od 1974 roku.", "A hotel at Marszałkowska 94/98, 95 m. New since 1974."],
	"central": ["Central Tower", "115 m przy Alejach Jerozolimskich.", "115 m on Al. Jerozolimskie."],
	"ilmet": ["Ilmet", "103 m.", "103 m."],
	"platinum_a": ["Platinum Tower A", "83 m.", "83 m."],
	"platinum_b": ["Platinum Tower B", "83 m.", "83 m."],
	"lucka": ["Łucka City", "103 m przy Łuckiej.", "103 m on Łucka."],
	"widok": ["Widok Towers", "95 m przy Alejach Jerozolimskich.", "95 m on Al. Jerozolimskie."],
	"teatr": ["Teatr Wielki",
			"Opera Narodowa. Gmach Antonia Corazziego z 1833 roku.",
			"The National Opera. Antonio Corazzi's building of 1833."],
	"kopernik": ["Centrum Nauki Kopernik",
			"Centrum nauki otwarte w 2010 roku. Na dachu ogród.",
			"A science centre, opened in 2010. A garden on its roof."],
	"buw": ["Biblioteka Uniwersytecka",
			"Zielona miedź na ścianach, ogród na dachu.",
			"Green copper on its walls, a garden on its roof."],
	"zamek": ["Zamek Królewski",
			"Zniszczony w 1944 roku, odbudowany w latach 1971–1984.",
			"Destroyed in 1944, rebuilt in 1971–1984."],
	"barbakan": ["Barbakan",
			"Ceglana brama dawnych murów miejskich, odbudowana po wojnie.",
			"A brick gate of the old city walls, rebuilt after the war."],
	"archikatedra": ["Archikatedra św. Jana",
			"Gotycki kościół z cegły na Starym Mieście.",
			"A Gothic brick church in the Old Town."],
	"sw_anna": ["Kościół Świętej Anny",
			"Na początku Krakowskiego Przedmieścia.",
			"Where Krakowskie Przedmieście begins."],
	"prezydencki": ["Pałac Prezydencki",
			"Na Krakowskim Przedmieściu.",
			"On Krakowskie Przedmieście."],
	"sw_krzyz": ["Kościół Świętego Krzyża",
			"W filarze kościoła spoczywa serce Chopina.",
			"Chopin's heart rests in one of its pillars."],
	"staszic": ["Pałac Staszica",
			"Przed nim stoi pomnik Kopernika.",
			"Copernicus's statue stands in front of it."],
	"zacheta": ["Zachęta",
			"Galeria sztuki w gmachu z 1900 roku.",
			"An art gallery in a building of 1900."],
	"wszystkich": ["Kościół Wszystkich Świętych",
			"Przy placu Grzybowskim.",
			"On Plac Grzybowski."],
	"aleksander": ["Kościół Świętego Aleksandra",
			"Rotunda na placu Trzech Krzyży.",
			"The rotunda on Plac Trzech Krzyży."],
	"mirowska": ["Hala Mirowska",
			"Ceglana hala targowa.",
			"A brick market hall."],
	"sejm": ["Sejm RP",
			"Przy Wiejskiej.",
			"On Wiejska."],
	"muzeum": ["Muzeum Narodowe",
			"Gmach z lat 1927–1938 przy Alejach Jerozolimskich.",
			"The museum's building of 1927–1938 on Al. Jerozolimskie."],
	"mdm": ["MDM",
			"Marszałkowska Dzielnica Mieszkaniowa, socrealizm z lat 1950–1952.",
			"The socialist-realist housing district of 1950–1952."],
}

var map  # map_builder.gd: terrain, roof grid, wall faces
var data: Dictionary
var st  # the city's building surface (chunked_surface.gd)
## Replaced zones: {"key", "zone": Array[PackedVector2Array] (drop what stands inside),
## "keep": Array[PackedVector2Array] (but not inside these), "box": Rect2}.
var sites: Array[Dictionary] = []
## What the game shows when a landmark is tapped: [{key, name, pl, en, centre}], in id order.
var info: Array[Dictionary] = []

# Emitter state.
var _mode := M_STONE
## The landmarks loop: big signs on the landmarks for map_builder's _build_landmark_signs:
## [word (neon_signs.gd LANDMARK_WORDS), bottom middle, outward normal, scale, tube colour].
var signs: Array = []
var _g := 0.0          # the landmark's ground height
var _id := 0           # landmark id for the picking grid (0: none)
var _pick := PackedByteArray()
# A landmark's own plan axes (its local u, v in world metres).
var _o := Vector2.ZERO
var _a := Vector2.RIGHT
var _b := Vector2.DOWN


func _init(builder, map_data: Dictionary) -> void:
	map = builder
	data = map_data
	_find_sites()
	# Loop 3c: the info cards (and so the picking ids) for every site up front, in site order,
	# so a sector built alone gives its landmarks the same ids as the whole city.
	for s in sites:
		var card: Array = INFO.get(s["key"], [s["key"], "", ""])
		info.append({"key": s["key"], "name": card[0], "pl": card[1], "en": card[2],
				"centre": (s["box"] as Rect2).get_center(), "box": s["box"]})


## True when a LoD2 building or an OpenStreetMap outline centred at p is replaced.
func replaces(p: Vector2) -> bool:
	for s in sites:
		if s.has("skin") or not (s["box"] as Rect2).has_point(p):
			continue
		var inside := false
		for z: PackedVector2Array in s["zone"]:
			if Geometry2D.is_point_in_polygon(p, z):
				inside = true
				break
		if not inside:
			continue
		for k: PackedVector2Array in s["keep"]:
			if Geometry2D.is_point_in_polygon(p, k):
				inside = false
				break
		if inside:
			return true
	return false


## The landmarks loop: how a kept building whose plan spans `box` is drawn instead of its own
## look (Muzeum Narodowe's stone): {"mode", "wall", "roof"}, or empty. A building counts when
## its centre is inside the site's outline, or its whole box inside the outline's box (the
## museum's LoD2 model is one run round its courtyards: its centre is in one).
func skin_at(box: Rect2) -> Dictionary:
	var p := box.get_center()
	for s in sites:
		if not s.has("skin") or not (s["box"] as Rect2).has_point(p):
			continue
		# One outline round courtyards (the museum): anything in its box. A site of many
		# blocks (MDM): only what has its centre in one of them.
		if s["zone"].size() == 1 and (s["box"] as Rect2).encloses(box):
			return s["skin"]
		for z: PackedVector2Array in s["zone"]:
			if Geometry2D.is_point_in_polygon(p, z):
				return s["skin"]
	return {}


## The landmarks loop: a tower's glass (or a low-rise landmark's wall) for the far skyline
## (sector_proxies.gd).
static func tower_colour(key: String, fallback: Color) -> Color:
	for t: Dictionary in TOWERS:
		if t["key"] == key:
			return Color(t["glass"])
	for t: Dictionary in SKINS:
		if t["key"] == key:
			return Color(t["wall"])
	return fallback


## Whether an OpenStreetMap building of the bake should still be drawn.
func keeps_building(bld: Dictionary) -> bool:
	var poly := _pts(bld["p"])
	if poly.size() < 3:
		return true
	return not replaces(_centre(poly))


func _pts(flat: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in range(0, flat.size() - 1, 2):
		out.append(Vector2(flat[i], flat[i + 1]))
	return out


func _centre(poly: PackedVector2Array) -> Vector2:
	var c := Vector2.ZERO
	for q in poly:
		c += q
	return c / maxf(poly.size(), 1)


## The landmarks loop: the outline of the tallest building (or part) standing on `at`, for a
## tower OpenStreetMap leaves unnamed (The Warsaw HUB).
func _tallest_at(at: Vector2) -> PackedVector2Array:
	var best := PackedVector2Array()
	var top := 0.0
	for b in data.get("buildings", []):
		if float(b["h"]) <= top:
			continue
		var q := _pts(b["p"])
		if q.size() >= 3 and Geometry2D.is_point_in_polygon(at, q):
			best = q
			top = float(b["h"])
	return best


func _landmark(name: String) -> PackedVector2Array:
	for l in data.get("landmarks", []):
		if l["name"] == name:
			return _pts(l["p"])
	return PackedVector2Array()


func _box_of(polys: Array) -> Rect2:
	var box := Rect2()
	var first := true
	for poly: PackedVector2Array in polys:
		for q in poly:
			if first:
				box = Rect2(q, Vector2.ZERO)
				first = false
			else:
				box = box.expand(q)
	return box.grow(2.0)


func _add_site(key: String, zone: Array, keep: Array = []) -> void:
	var z: Array[PackedVector2Array] = []
	for p: PackedVector2Array in zone:
		if p.size() >= 3:
			z.append(p)
	if z.is_empty():
		return
	var k: Array[PackedVector2Array] = []
	for p: PackedVector2Array in keep:
		if p.size() >= 3:
			k.append(p)
	sites.append({"key": key, "zone": z, "keep": k, "box": _box_of(z)})


## OpenStreetMap buildings (or parts) whose centre lies inside `poly` and that `test` accepts.
func _parts_in(poly: PackedVector2Array, test: Callable) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var box := _box_of([poly])
	for bld in data["buildings"]:
		var q := _pts(bld["p"])
		if q.size() < 3:
			continue
		var c := _centre(q)
		if box.has_point(c) and Geometry2D.is_point_in_polygon(c, poly) and test.call(bld):
			out.append(bld)
	return out


## The zones each landmark replaces, from the map data.
func _find_sites() -> void:
	var palace := _landmark("Pałac Kultury i Nauki")
	if palace.size() >= 3:
		_add_site("palace", [palace])
	# Złote Tarasy: the glass wave is mapped as eight glass domes over the mall; the office
	# crescent (Lumen) and Skylight stay as they are.
	var tarasy := _landmark("Złote Tarasy")
	if tarasy.size() >= 3:
		var domes := _parts_in(tarasy, func(b: Dictionary) -> bool:
				return str(b["c"]).to_lower() == "#336699" and float(b["h"]) >= 20.0)
		var zone: Array = []
		for b in domes:
			zone.append(_pts(b["p"]))
		_add_site("tarasy", zone, [_landmark("Lumen"), _landmark("Skylight")])
		if not sites.is_empty() and sites[-1]["key"] == "tarasy":
			sites[-1]["domes"] = domes
	var rotunda := _landmark("Rotunda PKO")
	if rotunda.size() >= 3:
		_add_site("rotunda", [rotunda])
	var varso := _landmark("Varso Tower")
	if varso.size() >= 3:
		_add_site("varso", [varso])
	_find_stadium()
	_find_centralna()
	_find_towers()
	# The landmarks loop: the skyline's towers, then Muzeum Narodowe.
	for t: Dictionary in TOWERS:
		var outline := _landmark(t["osm"]) if t.has("osm") else _tallest_at(t["at"])
		if outline.size() >= 3:
			_add_site(t["key"], [outline])
			if not sites.is_empty() and sites[-1]["key"] == t["key"]:
				sites[-1]["tower"] = t
	_find_muzeum()
	_find_mdm()
	_find_skins()


## Warszawa Centralna: OpenStreetMap maps the station in 3D (its outline sits underground):
## a roof of 140 x 57 m on two rows of pillars along Al. Jerozolimskie, the glass hall
## (71 x 51 m) under it and a canopy round it to 140 x 86 m; the frame below is the roof's.
const CENTRALNA := Vector2(-1420.0, 572.5)
const CENTRALNA_TURN := -19.4
func _find_centralna() -> void:
	var a := Vector2.from_angle(deg_to_rad(CENTRALNA_TURN))
	var b := Vector2(-a.y, a.x)
	var zone := PackedVector2Array()
	for q in [[-73.0, -45.5], [73.0, -45.5], [73.0, 46.5], [-73.0, 46.5]]:
		zone.append(CENTRALNA + a * float(q[0]) + b * float(q[1]))
	_add_site("centralna", [zone])
	var pillars: Array[Vector2] = []
	for bld in _parts_in(zone, func(b2: Dictionary) -> bool: return absf(float(b2["h"]) - 15.0) < 0.5 and float(b2["mh"]) < 0.5):
		var q := _pts(bld["p"])
		var lo := q[0]
		var hi := q[0]
		for v in q:
			lo = lo.min(v)
			hi = hi.max(v)
		if (hi - lo).length() < 3.0:
			pillars.append(_centre(q))
	sites[-1]["pillars"] = pillars


## Most Poniatowskiego's four towers, two at each end of the river span: OpenStreetMap
## maps their outlines (no heights), each twice. Loop 3b (R7): the bake seats them
## (tools/bake_structures.py `towers`: the outline by the deck, trimmed clear of the road
## corridors and lanes, base at the boulevard, deck height from the solved profile, and a
## zone of both outlines grown 6 m, so the second outline is no longer drawn as a building
## fused into the tower); the search below is the fallback for a map baked before that.
func _find_towers() -> void:
	var seated: Array = data.get("towers", [])
	if seated.size() == 4:
		var zones: Array = []
		for t: Dictionary in seated:
			zones.append(_pts(t["zone"]))
		_add_site("poniatowski", zones)
		sites[-1]["towers"] = seated
		return
	var found: Array[PackedVector2Array] = []
	for area in [Rect2(910, -165, 40, 60), Rect2(1398, -332, 45, 65)]:
		for bld in data["buildings"]:
			var q := _pts(bld["p"])
			if q.size() < 3 or not area.has_point(_centre(q)):
				continue
			var lo := q[0]
			var hi := q[0]
			for v in q:
				lo = lo.min(v)
				hi = hi.max(v)
			var span := (hi - lo).length()
			if span < 7.0 or span > 24.0:
				continue
			var same := false
			for f in found:
				if _centre(f).distance_to(_centre(q)) < 9.0:
					same = true
					break
			if not same:
				found.append(q)
	if found.size() == 4:
		var zone: Array = []
		for f in found:
			zone.append(Geometry2D.offset_polygon(f, 3.0)[0])
		_add_site("poniatowski", zone)


## Stadion Narodowy: 72 pairs of masts are mapped round it (columns from the ground to
## 50 m, spikes 44-60 m a few metres further out); they give its outline at every angle.
func _find_stadium() -> void:
	var inner: Array[Vector2] = []
	var outer: Array[Vector2] = []
	var area := Rect2(1250, -820, 450, 450)
	for bld in data["buildings"]:
		var q := _pts(bld["p"])
		if q.size() < 3:
			continue
		var c := _centre(q)
		if not area.has_point(c):
			continue
		var lo := q[0]
		var hi := q[0]
		for v in q:
			lo = lo.min(v)
			hi = hi.max(v)
		if (hi - lo).length() > 2.5:
			continue
		var h := float(bld["h"])
		var mh := float(bld["mh"])
		if absf(h - 50.0) < 0.5 and mh < 0.5:
			inner.append(c)
		elif absf(h - 60.0) < 0.5 and absf(mh - 44.0) < 0.5:
			outer.append(c)
	if inner.size() < 24 or inner.size() != outer.size():
		return
	var centre := Vector2.ZERO
	for v in inner:
		centre += v
	centre /= inner.size()
	var by_angle := func(a: Vector2, b: Vector2) -> bool: return (a - centre).angle() < (b - centre).angle()
	inner.sort_custom(by_angle)
	outer.sort_custom(by_angle)
	var zone := PackedVector2Array()
	for v in outer:
		zone.append(centre + (v - centre) * 1.08)
	_add_site("stadium", [zone])
	sites[-1]["inner"] = inner
	sites[-1]["outer"] = outer
	sites[-1]["centre"] = centre


# --- building -------------------------------------------------------------------------

func build(surface, near := Rect2()) -> void:
	st = surface
	_pick.resize(map._roof_nx * map._roof_nz)
	_pick.fill(0)
	var t0 := Time.get_ticks_msec()
	var built := 0
	for k in sites.size():
		var s: Dictionary = sites[k]
		# Loop 3c: building one sector, only the sites that reach `near` (the sector grown by
		# the split's margin); the builder keeps the triangles that lie in the sector. Every
		# site sets its own frame, ground and material code, so it builds the same alone.
		if near.has_area() and not (s["box"] as Rect2).grow(SITE_REACH).intersects(near):
			continue
		var key: String = s["key"]
		_id = k + 1
		built += 1
		match key:
			"palace":
				_build_palace(s)
			"tarasy":
				_build_tarasy(s)
			"rotunda":
				_build_rotunda(s)
			"varso":
				_build_varso(s)
			"stadium":
				_build_stadium(s)
			"centralna":
				_build_centralna(s)
			"poniatowski":
				_build_towers(s)
			_:
				if s.has("tower"):
					_build_tower(s)
				elif s.has("skin"):
					_mark_zone(s)
	_id = 0
	if not near.has_area():
		print("landmarks: %d built in %d ms" % [built, Time.get_ticks_msec() - t0])


## Loop 3c: how far a landmark's model may reach outside its site's box (slack: the models
## stand inside their zones); a sector builds every site whose box comes this close.
const SITE_REACH := 24.0


## Which landmark covers a roof-grid cell (0: none), for map_builder.landmark_at.
func pick_grid() -> PackedByteArray:
	return _pick


# --- emitting ----------------------------------------------------------------------------

## One triangle into the city mesh, the roof grid and the picking grid. `top` is the
## wall top above the ground (UV2.y), uv the shader's wall coordinates (x < 0 on tops).
func _tri(a: Vector3, b: Vector3, c: Vector3, n: Vector3, col: Color, ua: Vector2, ub: Vector2, uc: Vector2,
		top: float, roof := true) -> void:
	if ((b - a).cross(c - a).dot(n) > 0.0) == CLOCKWISE_FRONT:
		var t := b
		b = c
		c = t
		var tu := ub
		ub = uc
		uc = tu
	var uv2 := Vector2(_mode, top)
	st.set_color(col)
	st.set_normal(n)
	st.set_uv(ua)
	st.set_uv2(uv2)
	st.add_vertex(a)
	st.set_uv(ub)
	st.add_vertex(b)
	st.set_uv(uc)
	st.add_vertex(c)
	if roof:
		map._roof_triangle(a, b, c, absf(n.y) >= 0.3)
	if _id > 0:
		_mark_pick(a, b, c)


func _mark_pick(a: Vector3, b: Vector3, c: Vector3) -> void:
	var cell: float = map.ROOF_CELL
	var i0 := floori((minf(a.x, minf(b.x, c.x)) - map._roof_x0) / cell)
	var i1 := floori((maxf(a.x, maxf(b.x, c.x)) - map._roof_x0) / cell)
	var j0 := floori((minf(a.z, minf(b.z, c.z)) - map._roof_z0) / cell)
	var j1 := floori((maxf(a.z, maxf(b.z, c.z)) - map._roof_z0) / cell)
	if (i1 - i0 + 1) * (j1 - j0 + 1) > 400:
		return  # a long thin piece (a cable): not worth the cells
	for j in range(maxi(j0, 0), mini(j1, map._roof_nz - 1) + 1):
		for i in range(maxi(i0, 0), mini(i1, map._roof_nx - 1) + 1):
			_pick[j * map._roof_nx + i] = _id


## A quad a-b-c-d (in order round its edge).
func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, n: Vector3, col: Color,
		ua := Vector2(-1, -1), ub := Vector2(-1, -1), uc := Vector2(-1, -1), ud := Vector2(-1, -1), top := -1.0) -> void:
	_tri(a, b, c, n, col, ua, ub, uc, top)
	_tri(a, c, d, n, col, ua, uc, ud, top)


## A vertical wall along a→b (plan) from y0 to y1 (absolute), facing `out`. `run` is the
## distance along the facade already covered (keeps the window rhythm continuous).
func _wall(a: Vector2, b: Vector2, y0: float, y1: float, out: Vector2, col: Color, run := 0.0) -> void:
	var length := a.distance_to(b)
	if length < 0.02 or y1 <= y0:
		return
	var n := Vector3(out.x, 0.0, out.y).normalized()
	var h0 := y0 - _g
	var h1 := y1 - _g
	_quad(Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y), n, col,
			Vector2(run, h0), Vector2(run + length, h0), Vector2(run + length, h1), Vector2(run, h1), h1)


## The outward normal of edge a→b of a polygon (plan).
func _out(poly: PackedVector2Array, a: Vector2, b: Vector2) -> Vector2:
	var e := (b - a).normalized()
	var n := Vector2(e.y, -e.x)
	return -n if Geometry2D.is_polygon_clockwise(poly) else n


## Walls round a polygon from y0 to y1, then (if roof_col.a > 0) its flat top.
func _prism(poly: PackedVector2Array, y0: float, y1: float, wall: Color, roof: Color, wall_mode := -1.0, roof_mode := -1.0) -> void:
	if poly.size() < 3:
		return
	var keep := _mode
	if wall_mode >= 0.0:
		_mode = wall_mode
	var run := 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		_wall(a, b, y0, y1, _out(poly, a, b), wall, run)
		run += a.distance_to(b)
	_mode = roof_mode if roof_mode >= 0.0 else keep
	if roof.a > 0.0:
		_cap(poly, y1, roof)
	_mode = keep


## A flat top over a polygon.
func _cap(poly: PackedVector2Array, y: float, col: Color) -> void:
	var idx := Geometry2D.triangulate_polygon(poly)
	if idx.is_empty():
		idx = Geometry2D.triangulate_delaunay(poly)
	for i in range(0, idx.size(), 3):
		var a := poly[idx[i]]
		var b := poly[idx[i + 1]]
		var c := poly[idx[i + 2]]
		_tri(Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y), Vector3.UP, col,
				Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)


## A flat top over a polygon with holes: cut into vertical slabs through every hole,
## so no piece holds a hole, then each piece is filled on its own.
func _cap_holes(outer: PackedVector2Array, holes: Array, y: float, col: Color) -> void:
	if holes.is_empty():
		_cap(outer, y, col)
		return
	var lo := outer[0]
	var hi := outer[0]
	for q in outer:
		lo = lo.min(q)
		hi = hi.max(q)
	var cuts: Array[float] = [lo.x - 1.0]
	for h: PackedVector2Array in holes:
		cuts.append(_centre(h).x)
	cuts.append(hi.x + 1.0)
	cuts.sort()
	for k in cuts.size() - 1:
		var slab := PackedVector2Array([Vector2(cuts[k], lo.y - 1.0), Vector2(cuts[k + 1], lo.y - 1.0),
				Vector2(cuts[k + 1], hi.y + 1.0), Vector2(cuts[k], hi.y + 1.0)])
		for piece in Geometry2D.intersect_polygons(outer, slab):
			var parts: Array = [piece]
			for h: PackedVector2Array in holes:
				var next: Array = []
				for p: PackedVector2Array in parts:
					next.append_array(Geometry2D.clip_polygons(p, h))
				parts = next
			for p: PackedVector2Array in parts:
				if p.size() >= 3:
					_cap(p, y, col)


## Sides from ring0 (at y0) to ring1 (at y1), same number of corners, then a top.
func _frustum(ring0: PackedVector2Array, y0: float, ring1: PackedVector2Array, y1: float, col: Color, top_col := Color(0, 0, 0, 0)) -> void:
	var n := ring0.size()
	var c0 := _centre(ring0)
	for i in n:
		var a0 := ring0[i]
		var b0 := ring0[(i + 1) % n]
		var a1 := ring1[i]
		var b1 := ring1[(i + 1) % n]
		var p0 := Vector3(a0.x, y0, a0.y)
		var p1 := Vector3(b0.x, y0, b0.y)
		var p2 := Vector3(b1.x, y1, b1.y)
		var p3 := Vector3(a1.x, y1, a1.y)
		var nrm := (p1 - p0).cross(p3 - p0).normalized()
		var mid := (a0 + b0) * 0.5 - c0
		if Vector2(nrm.x, nrm.z).dot(mid) < 0.0:
			nrm = -nrm
		var h0 := y0 - _g
		var h1 := y1 - _g
		var l := a0.distance_to(b0)
		_quad(p0, p1, p2, p3, nrm, col, Vector2(0, h0), Vector2(l, h0), Vector2(l, h1), Vector2(0, h1), h1)
	if top_col.a > 0.0:
		_cap(ring1, y1, top_col)


## A pyramid over a ring, to an apex above its centre.
func _pyramid(ring: PackedVector2Array, y0: float, apex_y: float, col: Color) -> void:
	var c := _centre(ring)
	var apex := Vector3(c.x, apex_y, c.y)
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var pa := Vector3(a.x, y0, a.y)
		var pb := Vector3(b.x, y0, b.y)
		var nrm := (pb - pa).cross(apex - pa).normalized()
		if Vector2(nrm.x, nrm.z).dot((a + b) * 0.5 - c) < 0.0:
			nrm = -nrm
		_tri(pa, pb, apex, nrm, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)


## A crenellated parapet (zero thickness, seen from both sides) round a ring.
func _attic(ring: PackedVector2Array, y: float, height: float, col: Color, closed := true) -> void:
	var keep := _mode
	_mode = M_ATTIC + clampf(height / 10.0, 0.0, 0.99)
	var run := 0.0
	var n := ring.size()
	for i in (n if closed else n - 1):
		var a := ring[i]
		var b := ring[(i + 1) % n]
		_wall(a, b, y, y + height, _out(ring, a, b), col, run)
		run += a.distance_to(b)
	_mode = keep


## A rectangle in a landmark's local plan (centre, half sizes, turned by `turn`).
func _rect(cu: float, cv: float, hu: float, hv: float) -> PackedVector2Array:
	return PackedVector2Array([_w(cu - hu, cv - hv), _w(cu + hu, cv - hv), _w(cu + hu, cv + hv), _w(cu - hu, cv + hv)])


func _w(u: float, v: float) -> Vector2:
	return _o + _a * u + _b * v


func _wl(p: Vector2) -> Vector2:
	return _o + _a * p.x + _b * p.y


func _local(p: Vector2) -> Vector2:
	var d := p - _o
	return Vector2(d.dot(_a), d.dot(_b))


## A box in the local plan: walls and a top.
func _lbox(cu: float, cv: float, hu: float, hv: float, y0: float, y1: float, col: Color, mode := M_STONE, top_col := Color(0, 0, 0, 0)) -> void:
	_prism(_rect(cu, cv, hu, hv), y0, y1, col, top_col if top_col.a > 0.0 else col.darkened(0.1), mode, M_STONE)


## A pinnacle: a square shaft with a pointed cap, on a local spot.
func _pinnacle(cu: float, cv: float, w: float, y: float, h: float, col: Color) -> void:
	var r := w * 0.5
	_prism(_rect(cu, cv, r, r), y, y + h * 0.62, col, Color(0, 0, 0, 0), M_STONE)
	_mode = M_STONE
	_pyramid(_rect(cu, cv, r * 1.15, r * 1.15), y + h * 0.62, y + h, col.lightened(0.08))


## Car collision along a ring at street level (like map_builder's buildings).
func _collide(ring: PackedVector2Array) -> void:
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var ga: float = map.terrain_height(a.x, a.y) - 1.0
		var gb: float = map.terrain_height(b.x, b.y) - 1.0
		map._wall_faces.append_array([Vector3(a.x, ga, a.y), Vector3(b.x, gb, b.y), Vector3(b.x, gb + 6.0, b.y),
				Vector3(a.x, ga, a.y), Vector3(b.x, gb + 6.0, b.y), Vector3(a.x, ga + 6.0, a.y)])


## Loop 3b: car collision along a ring between two heights.
func _collide_span(ring: PackedVector2Array, y0: float, y1: float) -> void:
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		map._wall_faces.append_array([Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y),
				Vector3(a.x, y0, a.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y)])


func _ground_under(poly: PackedVector2Array) -> float:
	var g := INF
	for q in poly:
		g = minf(g, map.terrain_height(q.x, q.y))
	return g if g < INF else 0.0


# --- the Palace of Culture and Science ------------------------------------------------------

## The Palace's own axes run with the Śródmieście grid: u towards Marszałkowska (the
## main front, ENE), v towards Al. Jerozolimskie (SSE). Its tiers come from the
## OpenStreetMap building parts (base 18 m, tower to 67, shaft to 139, clock tier to 168,
## lantern to 188, crown to 204, the gilded spire to 237 m); the plan below is those
## parts' outlines in the Palace's frame (metres from the clock tier's centre).
const P_WINGS := [
	# u0, v0, u1, v1, top: the four corner pavilions, the north and south annexes,
	# the east entrance block (from the parts of 22.5 and 30 m).
	[-79.5, 68.7, -53.0, 119.7, 24.0], [-81.0, -120.9, -53.7, -70.5, 24.0],
	[53.9, -121.0, 80.4, -69.8, 24.0], [55.5, 68.3, 82.1, 119.4, 24.0],
	[-17.7, 44.5, 17.3, 64.7, 30.0], [-17.6, -68.1, 16.5, -50.2, 30.0],
	[28.0, -10.6, 46.4, 12.1, 25.0],
]
## The courtyards (the relation's inner rings).
const P_COURTS := [
	[[-68.4, 40.7], [-67.6, 40.7], [-67.6, 36.1], [-48.8, 36.2], [-48.8, 32.8], [-34.4, 32.9], [-34.4, 65.1],
			[-48.2, 65.1], [-48.2, 63.9], [-68.4, 63.9]],
	[[-69.2, -41.8], [-69.2, -64.4], [-49.4, -64.3], [-49.4, -65.4], [-34.8, -65.4], [-34.7, -33.5],
			[-49.1, -33.5], [-49.1, -37.4], [-67.9, -37.4], [-67.9, -41.8]],
]
## The Congress Hall: its block (west end) and the drum's centre and radius.
const P_HALL := [[-89.3, 25.3], [-80.2, 25.3], [-80.2, 33.3], [-65.0, 33.4], [-65.0, 20.9], [-55.4, 18.8],
		[-55.3, -20.0], [-65.8, -22.5], [-65.8, -34.2], [-80.5, -34.2], [-80.5, -26.7], [-89.0, -26.8]]


func _palace_frame() -> void:
	# The clock tier (139-168 m) is a square: its centre and edges give the frame.
	var outline := _landmark("Pałac Kultury i Nauki")
	var box := _box_of([outline])
	for bld in data["buildings"]:
		if absf(float(bld["h"]) - 168.0) < 0.5 and absf(float(bld["mh"]) - 139.0) < 0.5:
			var sq := _pts(bld["p"])
			if sq.size() >= 4 and box.has_point(_centre(sq)):
				_o = _centre(sq)
				# The edge closest to the grid's east-west direction is the u axis.
				for i in sq.size():
					var e := sq[(i + 1) % sq.size()] - sq[i]
					if e.length() > 5.0 and absf(e.normalized().x) > 0.7:
						_a = e.normalized() * signf(e.x)
						_b = Vector2(-_a.y, _a.x)
						return
	# Fallback: measured from the 2026 data.
	_o = Vector2(-1214.25, 247.3)
	_a = Vector2(0.9403, -0.3404)
	_b = Vector2(0.3404, 0.9403)


func _lpoly(pts: Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	for q in pts:
		out.append(_w(q[0], q[1]))
	return out


func _build_palace(site: Dictionary) -> void:
	_palace_frame()
	var outer: PackedVector2Array = site["zone"][0]
	_g = _ground_under(outer)
	var g := _g
	var stone := SANDSTONE
	var light := SANDSTONE_LIGHT
	var roof := Color("#8f877a")
	var courts: Array = []
	for c in P_COURTS:
		courts.append(_lpoly(c))

	# The base: four storeys round the courtyards, a crenellated attic on top.
	_mode = M_MONUMENT
	var run := 0.0
	for i in outer.size():
		var a := outer[i]
		var b := outer[(i + 1) % outer.size()]
		_wall(a, b, g - 0.4, g + 18.0, _out(outer, a, b), stone, run)
		run += a.distance_to(b)
	for ring: PackedVector2Array in courts:
		for i in ring.size():
			var a := ring[i]
			var b := ring[(i + 1) % ring.size()]
			_wall(a, b, g + 4.0, g + 18.0, -_out(ring, a, b), stone.darkened(0.08))
		_mode = M_STONE
		_cap(ring, g + 4.0, Color("#a39c90"))
		_mode = M_MONUMENT
	_mode = M_STONE
	_cap_holes(outer, courts, g + 18.0, roof)
	_attic(outer, g + 18.0, 1.6, light)
	_collide(outer)

	# Wings: corner pavilions, the annexes beside the tower, the entrance block.
	for w in P_WINGS:
		var poly := _lpoly([[w[0], w[1]], [w[2], w[1]], [w[2], w[3]], [w[0], w[3]]])
		_prism(poly, g + 17.0, g + w[4], stone, roof, M_MONUMENT, M_STONE)
		_attic(poly, g + w[4], 1.4, light)
		# Small pinnacles on the pavilions' corners.
		for k in 4:
			var cu: float = w[0] if k % 2 == 0 else w[2]
			var cv: float = w[1] if k < 2 else w[3]
			_pinnacle(cu, cv, 1.4, g + w[4], 4.2, light)

	# The Congress Hall: its block and the drum round the auditorium, a shallow roof.
	var hall := _lpoly(P_HALL)
	_prism(hall, g + 17.0, g + 23.0, stone, roof, M_MONUMENT, M_STONE)
	_attic(hall, g + 23.0, 1.2, light, false)
	var drum := PackedVector2Array()
	var drum_top := PackedVector2Array()
	for k in 24:
		var t := -PI * 0.5 + PI * k / 23.0
		drum.append(_w(-89.0 - cos(t) * 31.0, sin(t) * 31.0))
		drum_top.append(_w(-89.0 - cos(t) * 22.0, sin(t) * 22.0))
	_mode = M_MONUMENT
	_frustum(drum, g + 18.0, drum_top, g + 23.0, stone)
	_mode = M_STONE
	var dome := PackedVector2Array()
	var dome_top := PackedVector2Array()
	for k in 16:
		var t := TAU * k / 16.0
		dome.append(_w(-86.0 + cos(t) * 21.0, sin(t) * 24.0))
		dome_top.append(_w(-86.0 + cos(t) * 10.0, sin(t) * 12.0))
	_frustum(dome, g + 23.0, dome_top, g + 29.0, Color("#9a9283"), Color("#a59d8e"))

	# The east portico: columns before the entrance block, an entablature on them.
	for k in 8:
		var cv := -9.6 + k * 2.74
		_lbox(53.4, cv, 0.55, 0.55, g, g + 13.5, light, M_STONE)
	_lbox(53.4, 0.0, 1.4, 10.6, g + 13.5, g + 15.6, stone, M_STONE, light)

	# The tower. Tier one: the core and its four corner towers to 67 m.
	var core := _rect(-0.25, -0.15, 21.45, 21.75)
	_prism(core, g + 17.0, g + 139.0, stone, roof, M_MONUMENT, M_STONE)
	for k in 4:
		var su := -1.0 if k % 2 == 0 else 1.0
		var sv := -1.0 if k < 2 else 1.0
		var cu := su * 22.9
		var cv := sv * 26.0
		var corner := _rect(cu, cv, 9.0, 9.0)
		_prism(corner, g + 17.0, g + 67.0, stone, roof, M_MONUMENT, M_STONE)
		_attic(corner, g + 67.0, 2.2, light)
		for q in 4:
			_pinnacle(cu + (-7.6 if q % 2 == 0 else 7.6), cv + (-7.6 if q < 2 else 7.6), 1.8, g + 67.0, 7.0, light)
		# A small stepped crown on each corner tower.
		_prism(_rect(cu, cv, 4.5, 4.5), g + 67.0, g + 73.0, light, roof, M_STONE, M_STONE)
		_pinnacle(cu, cv, 2.2, g + 73.0, 9.0, light)
	# Vertical ribs up the shaft, so it reads as the Palace's ribbed stone.
	for side in 4:
		for k in 7:
			var t := -15.0 + k * 5.0
			var ru := 0.0
			var rv := 0.0
			var hu := 0.45
			var hv := 0.45
			match side:
				0:
					ru = 21.6
					rv = t
					hu = 0.5
				1:
					ru = -22.1
					rv = t
					hu = 0.5
				2:
					ru = t
					rv = 21.9
					hv = 0.5
				3:
					ru = t
					rv = -22.3
					hv = 0.5
			_lbox(ru, rv, hu, hv, g + 67.0, g + 136.0, light, M_STONE)
	# The shaft's top: an attic, big corner pinnacles, smaller ones between.
	_attic(core, g + 139.0, 3.0, light)
	for k in 4:
		var su := -1.0 if k % 2 == 0 else 1.0
		var sv := -1.0 if k < 2 else 1.0
		_pinnacle(su * 19.5, sv * 19.5, 3.4, g + 139.0, 14.0, light)
		_pinnacle(su * 19.5, 0.0, 2.0, g + 139.0, 8.0, light)
		_pinnacle(0.0, sv * 19.5, 2.0, g + 139.0, 8.0, light)
	# A stepped plinth for the clock tier.
	_prism(_rect(0.0, 0.0, 12.5, 12.5), g + 139.0, g + 143.0, stone, roof, M_STONE, M_STONE)
	_attic(_rect(0.0, 0.0, 12.5, 12.5), g + 143.0, 1.6, light)

	# The clock tier (139-168 m): a dial on every face, an attic and pinnacles on top.
	var clock := _rect(0.0, 0.0, 8.5, 8.5)
	_prism(clock, g + 143.0, g + 168.0, stone, roof, M_MONUMENT, M_STONE)
	for f in 4:
		var nu: float = [1.0, -1.0, 0.0, 0.0][f]
		var nv: float = [0.0, 0.0, 1.0, -1.0][f]
		_dial(_w(nu * 8.62, nv * 8.62), g + 156.0, Vector2(_a * nu + _b * nv), 3.15)
	_attic(clock, g + 168.0, 2.0, light)
	for k in 4:
		_pinnacle(-7.4 if k % 2 == 0 else 7.4, -7.4 if k < 2 else 7.4, 1.8, g + 168.0, 9.0, light)

	# The lantern (168-188 m): tall dark arches between stone piers.
	var lantern := _rect(0.0, 0.0, 6.3, 6.3)
	_prism(lantern, g + 168.0, g + 188.0, stone, Color(0, 0, 0, 0), M_STONE)
	for f in 4:
		var nu: float = [1.0, -1.0, 0.0, 0.0][f]
		var nv: float = [0.0, 0.0, 1.0, -1.0][f]
		var n2: Vector2 = _a * nu + _b * nv
		var side := Vector2(-n2.y, n2.x)
		for k in 3:
			var c := _w(nu * 6.36, nv * 6.36) + side * (-3.6 + k * 3.6)
			_mode = M_STONE
			_quad(Vector3(c.x - side.x * 0.8, g + 171.0, c.y - side.y * 0.8), Vector3(c.x + side.x * 0.8, g + 171.0, c.y + side.y * 0.8),
					Vector3(c.x + side.x * 0.8, g + 185.0, c.y + side.y * 0.8), Vector3(c.x - side.x * 0.8, g + 185.0, c.y - side.y * 0.8),
					Vector3(n2.x, 0, n2.y), Color("#3a3640"))
	_attic(lantern, g + 188.0, 1.4, light)

	# The crown: a patina pyramid, then the gilded spire to 237 m.
	_mode = M_STONE
	_frustum(_rect(0.0, 0.0, 6.0, 6.0), g + 188.0, _rect(0.0, 0.0, 2.4, 2.4), g + 203.0, PATINA)
	_mode = M_GOLD
	_prism(_rect(0.0, 0.0, 1.8, 1.8), g + 200.5, g + 208.0, GOLD, GOLD, M_GOLD, M_GOLD)
	_frustum(_rect(0.0, 0.0, 1.6, 1.6), g + 208.0, _rect(0.0, 0.0, 0.9, 0.9), g + 222.0, GOLD)
	_frustum(_rect(0.0, 0.0, 0.9, 0.9), g + 222.0, _rect(0.0, 0.0, 0.15, 0.15), g + 237.0, GOLD)
	# Two rings on the spire.
	_prism(_rect(0.0, 0.0, 1.3, 1.3), g + 214.0, g + 215.0, GOLD, GOLD, M_GOLD, M_GOLD)
	_prism(_rect(0.0, 0.0, 1.0, 1.0), g + 225.0, g + 225.8, GOLD, GOLD, M_GOLD, M_GOLD)


## A clock dial facing `n` (plan, unit) centred at plan point c, height y: a cream disc
## with a gold rim and hour marks (it lights up at night). Loop 1: the hands are drawn by
## building.gdshader from the disc's UV (the point on the dial in radii, x to the right as
## seen from outside, y up, both minus 10 so the shader takes it for a roof) and show the
## time in Warsaw (main.gd sets `clock_hands` once a minute).
func _dial(c: Vector2, y: float, n: Vector2, r: float) -> void:
	var side := Vector2(-n.y, n.x)
	var n3 := Vector3(n.x, 0.0, n.y)
	var centre := Vector3(c.x, y, c.y) + n3 * 0.05
	var seg := 20
	_mode = M_GOLD
	for k in seg:
		var t0 := TAU * k / seg
		var t1 := TAU * (k + 1) / seg
		var e0 := Vector3(side.x * cos(t0), sin(t0), side.y * cos(t0))
		var e1 := Vector3(side.x * cos(t1), sin(t1), side.y * cos(t1))
		_quad(centre + e0 * r * 1.12, centre + e1 * r * 1.12, centre + e1 * r, centre + e0 * r, n3, GOLD)
	_mode = M_DIAL
	var face := centre + n3 * 0.04
	# `side` points to the left of someone looking at the dial from outside.
	for k in seg:
		var t0 := TAU * k / seg
		var t1 := TAU * (k + 1) / seg
		_tri(face, face + Vector3(side.x * cos(t0), sin(t0), side.y * cos(t0)) * r,
				face + Vector3(side.x * cos(t1), sin(t1), side.y * cos(t1)) * r, n3, Color("#f4ecd6"),
				Vector2(-10, -10), Vector2(-cos(t0) - 10.0, sin(t0) - 10.0), Vector2(-cos(t1) - 10.0, sin(t1) - 10.0), -1.0)
	_mode = M_STONE
	var ink := Color("#26232a")
	var front := face + n3 * 0.05
	for k in 12:
		var t := TAU * k / 12.0
		var dir := Vector3(side.x * cos(t), sin(t), side.y * cos(t))
		var across := Vector3(side.x * -sin(t), cos(t), side.y * -sin(t)) * (0.16 if k % 3 == 0 else 0.09)
		var p0 := front + dir * r * 0.78
		var p1 := front + dir * r * 0.93
		_quad(p0 - across, p1 - across, p1 + across, p0 + across, n3, ink)


# --- Złote Tarasy -----------------------------------------------------------------------------

## The glass wave: one surface over the mapped domes (each a cap rising to its mapped
## height, 35 m by the offices, 22 m towards the station), blended where they meet so
## the roof rolls instead of creasing, laid on the ground's slope, with glass walls
## round its rim where it stands clear of the ground.
func _build_tarasy(site: Dictionary) -> void:
	var domes: Array = []
	for b in site.get("domes", []):
		var poly := _pts(b["p"])
		var c := _centre(poly)
		var r := 0.0
		for q in poly:
			r += q.distance_to(c)
		domes.append([c, r / poly.size() + 1.0, float(b["h"])])
	if domes.is_empty():
		return
	var lo := Vector2(INF, INF)
	var hi := -lo
	for d in domes:
		lo = lo.min(d[0] - Vector2.ONE * d[1])
		hi = hi.max(d[0] + Vector2.ONE * d[1])
	_g = _ground_under(PackedVector2Array([lo, hi, Vector2(lo.x, hi.y), Vector2(hi.x, lo.y)]))
	var glass := Color("#d4b066")  # the landmarks loop: golden glass (was #8fb6c6, read as ice)
	var step := 3.0
	var nx := ceili((hi.x - lo.x) / step)
	var nz := ceili((hi.y - lo.y) / step)
	# Every grid corner: inside the domes (or moved onto the nearest rim) and its height.
	var corner := PackedVector3Array()
	var inside := PackedByteArray()
	for j in nz + 1:
		for i in nx + 1:
			var p := lo + Vector2(i, j) * step
			var best := INF
			var rim := p
			var any := false
			for d in domes:
				var dist := p.distance_to(d[0])
				if dist <= d[1]:
					any = true
				if dist - d[1] < best:
					best = dist - d[1]
					rim = d[0] + (p - d[0]).normalized() * d[1] * 0.999
			if not any:
				p = rim
			corner.append(Vector3(p.x, _wave(p, domes), p.y))
			inside.append(1 if any else 0)
	_mode = M_GLASS_ROOF
	for j in nz:
		for i in nx:
			var k00 := j * (nx + 1) + i
			var k10 := k00 + 1
			var k01 := k00 + nx + 1
			var k11 := k01 + 1
			if inside[k00] + inside[k10] + inside[k01] + inside[k11] == 0:
				continue
			for tri in [[k00, k10, k11], [k00, k11, k01]]:
				var a := corner[tri[0]]
				var b := corner[tri[1]]
				var c := corner[tri[2]]
				if (b - a).cross(c - a).length() < 0.05:
					continue
				var n := (b - a).cross(c - a).normalized()
				if n.y < 0.0:
					n = -n
				_tri(a, b, c, n, glass, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	# The rim: glass walls where the wave stands clear of the ground.
	_mode = M_GLASS
	var ring := PackedVector2Array()
	for d in domes:
		var seg := 40
		for k in seg:
			var a: Vector2 = d[0] + Vector2.from_angle(TAU * k / seg) * d[1]
			var b: Vector2 = d[0] + Vector2.from_angle(TAU * (k + 1) / seg) * d[1]
			var m := (a + b) * 0.5
			var covered := false
			for e in domes:
				if e != d and m.distance_to(e[0]) < e[1] - 0.3:
					covered = true
					break
			if covered:
				continue
			ring.append(m)
			var ya := _wave(a, domes)
			var yb := _wave(b, domes)
			var ga: float = map.terrain_height(a.x, a.y) - 0.3
			var gb: float = map.terrain_height(b.x, b.y) - 0.3
			if ya - ga < 0.6 and yb - gb < 0.6:
				continue
			var n: Vector2 = (m - (d[0] as Vector2)).normalized()
			_quad(Vector3(a.x, ga, a.y), Vector3(b.x, gb, b.y), Vector3(b.x, yb, b.y), Vector3(a.x, ya, a.y),
					Vector3(n.x, 0, n.y), Color("#a99f7e"), Vector2(0, ga - _g), Vector2(a.distance_to(b), gb - _g),
					Vector2(a.distance_to(b), yb - _g), Vector2(0, ya - _g), maxf(ya, yb) - _g)
			map._wall_faces.append_array([Vector3(a.x, ga - 1.0, a.y), Vector3(b.x, gb - 1.0, b.y), Vector3(b.x, gb + 5.0, b.y),
					Vector3(a.x, ga - 1.0, a.y), Vector3(b.x, gb + 5.0, b.y), Vector3(a.x, ga + 5.0, a.y)])


## The wave's height at a point: each dome a cap (its rim a seventh of its height), the
## caps blended smoothly where they overlap; on the ground's slope.
func _wave(p: Vector2, domes: Array) -> float:
	var k := 2.6
	var sum := 0.0
	var any := false
	for d in domes:
		var t: float = p.distance_to(d[0]) / d[1]
		if t <= 1.0:
			var v: float = d[2] * (0.14 + 0.86 * sqrt(maxf(1.0 - t * t, 0.0)))
			sum += exp(v / k)
			any = true
	var h := k * log(sum) if any else 0.0
	return map.terrain_height(p.x, p.y) + h


# --- the Rotunda ------------------------------------------------------------------------------

## A round glass pavilion on the corner of Marszałkowska and Al. Jerozolimskie: a granite
## plinth, two storeys of glass lit from inside, a white roof that overhangs, rises gently
## and opens in a glass oculus, ribbed like the old one.
func _build_rotunda(site: Dictionary) -> void:
	var poly: PackedVector2Array = site["zone"][0]
	var c := _centre(poly)
	var r := 0.0
	for q in poly:
		r += q.distance_to(c)
	r /= poly.size()
	_g = _ground_under(poly)
	var g := _g
	var seg := 48
	var ring := func(radius: float) -> PackedVector2Array:
		var out := PackedVector2Array()
		for k in seg:
			out.append(c + Vector2.from_angle(TAU * k / seg) * radius)
		return out
	# Plinth, glass drum, the band under the roof's edge (a lit strip at night).
	_prism(ring.call(r + 0.25), g - 0.4, g + 0.7, Color("#56565c"), Color(0, 0, 0, 0), M_STONE)
	_prism(ring.call(r), g + 0.7, g + 10.6, Color("#9cc4d4"), Color(0, 0, 0, 0), M_PAVILION)
	_prism(ring.call(r + 0.05), g + 10.6, g + 11.0, Color("#fff2d6"), Color(0, 0, 0, 0), M_LAMP)
	# The roof: an overhanging white edge, then a shallow cone up to the oculus, in ribs.
	var edge := r + 2.2
	_prism(ring.call(edge), g + 11.0, g + 12.2, Color("#eceae4"), Color(0, 0, 0, 0), M_STONE)
	_mode = M_STONE
	var under: PackedVector2Array = ring.call(edge)
	var inner: PackedVector2Array = ring.call(r)
	for k in seg:
		var a := under[k]
		var b := under[(k + 1) % seg]
		var ai := inner[k]
		var bi := inner[(k + 1) % seg]
		_quad(Vector3(a.x, g + 11.0, a.y), Vector3(b.x, g + 11.0, b.y), Vector3(bi.x, g + 11.0, bi.y), Vector3(ai.x, g + 11.0, ai.y),
				Vector3.DOWN, Color("#c9c7c0"))
	var cone_out: PackedVector2Array = ring.call(edge)
	var cone_in: PackedVector2Array = ring.call(5.2)
	for k in seg:
		var a := cone_out[k]
		var b := cone_out[(k + 1) % seg]
		var ai := cone_in[k]
		var bi := cone_in[(k + 1) % seg]
		var p0 := Vector3(a.x, g + 12.2, a.y)
		var p1 := Vector3(b.x, g + 12.2, b.y)
		var p2 := Vector3(bi.x, g + 13.6, bi.y)
		var p3 := Vector3(ai.x, g + 13.6, ai.y)
		var n := (p1 - p0).cross(p3 - p0).normalized()
		if n.y < 0.0:
			n = -n
		_quad(p0, p1, p2, p3, n, Color("#f3f1ea") if k % 2 == 0 else Color("#dcdad3"))
	# The oculus: a raised glass ring with a shallow glass cap.
	_prism(ring.call(5.2), g + 13.6, g + 14.5, Color("#8fb6c6"), Color(0, 0, 0, 0), M_PAVILION)
	_mode = M_GLASS_ROOF
	_pyramid(ring.call(5.2), g + 14.5, g + 15.6, Color("#86aebf"))
	_collide(ring.call(r + 0.25))


# --- Varso Tower ------------------------------------------------------------------------------

## Built from its mapped parts: the glass slabs (177 and 205 m, the south part to 230 m),
## the dark spines at both ends, the glass crown (193-234 m, lit at night); the thin parts
## of the spire are replaced by one mast to 310 m with its five rings and a beacon.
func _build_varso(site: Dictionary) -> void:
	var zone: PackedVector2Array = site["zone"][0]
	_g = _ground_under(zone)
	var g := _g
	var spire := Vector2.INF
	var spire_h := 0.0
	var parts := _parts_in(zone, func(_b: Dictionary) -> bool: return true)
	for b in parts:
		var poly := _pts(b["p"])
		var lo := poly[0]
		var hi := poly[0]
		for q in poly:
			lo = lo.min(q)
			hi = hi.max(q)
		var h := float(b["h"])
		var mh := float(b["mh"])
		if (hi - lo).length() < 8.0 and h >= 230.0:
			# A piece of the spire or one of its rings: the tallest one marks where it stands.
			if h > spire_h:
				spire_h = h
				spire = _centre(poly)
			continue
		if h < 3.0:
			continue
		var col := _osm(b["c"], Color("#334e6b"))
		var dark := str(b["c"]).to_lower() == "#3f4140"
		var crown := mh >= 190.0 and h > 220.0
		var top_col := col.darkened(0.25)
		if dark:
			_prism(poly, g + mh - (0.4 if mh < 0.5 else 0.0), g + h, col, top_col, M_STONE, M_STONE)
		elif crown:
			# The crown: an open glass lantern round the top floors, lit at night.
			_prism(poly, g + mh, g + h, col.lightened(0.18), Color(0, 0, 0, 0), M_PAVILION + 0.5)
		else:
			_prism(poly, g + mh - (0.4 if mh < 0.5 else 0.0), g + h, col, top_col, M_GLASS, M_STONE)
		if mh < 0.5 and h > 30.0:
			_collide(poly)
	if spire == Vector2.INF:
		return
	# The spire: a slender mast tapering to 310 m, its rings, a beacon on top.
	var steel := Color("#b8c0cc")
	_mode = M_STONE
	var sq := func(radius: float) -> PackedVector2Array:
		var out := PackedVector2Array()
		for k in 8:
			out.append(spire + Vector2.from_angle(TAU * k / 8.0) * radius)
		return out
	_frustum(sq.call(1.6), g + 193.0, sq.call(1.2), g + 260.0, steel)
	_frustum(sq.call(1.2), g + 260.0, sq.call(0.35), g + 309.0, steel)
	for h in [240.0, 250.0, 260.0, 274.0, 294.0]:
		var rr: float = 2.7 if h < 290.0 else 1.2
		_prism(sq.call(rr), g + h - 0.6, g + h, Color("#7689a9"), Color("#8fa0bb"), M_STONE, M_STONE)
	_prism(sq.call(0.5), g + 309.0, g + 310.5, Color("#ff3b30"), Color("#ff6a5c"), M_LAMP, M_LAMP)


func _osm(value, fallback: Color) -> Color:
	var s := str(value).strip_edges().to_lower()
	if s == "":
		return fallback
	var c := Color.from_string(s, Color(0, 0, 0, 0))
	return fallback if c.a == 0.0 else c


# --- the skyline's towers (the landmarks loop) ------------------------------------------------

## A tower from its mapped parts, in its skin (TOWERS). The outline itself (named like the
## tower, or the one part that holds all the others) is left out when parts are mapped; a part
## that starts in the air with nothing mapped under it stands on the ground.
func _build_tower(site: Dictionary) -> void:
	var spec: Dictionary = site["tower"]
	var zone: PackedVector2Array = site["zone"][0]
	_g = _ground_under(zone)
	var g := _g
	var glass := Color(spec["glass"])
	var roof := Color(spec["roof"])
	var skin := M_SKIN + float(spec["style"]) / 16.0
	var parts := _parts_in(zone, func(b: Dictionary) -> bool: return float(b["h"]) > float(b["mh"]) + 0.5)
	if parts.size() > 1:
		parts = parts.filter(func(b: Dictionary) -> bool: return str(b.get("name", "")) != spec.get("osm", ""))
	var boxes: Array[Rect2] = []
	var top_h := 0.0
	for b in parts:
		boxes.append(_box_of([_pts(b["p"])]))
		top_h = maxf(top_h, float(b["h"]))
	if spec["key"] == "zlota44":
		# Złota 44: the tower is lofted (_zlota_sail); only the podium is built from its parts.
		_zlota_sail(g, glass, roof, skin)
	elif spec["key"] == "spire":
		# Warsaw Spire: the leaf-shaped tower lofted and tapering (_spire); the two lower
		# office buildings beside it are built from their parts.
		_spire(zone, g, glass, roof, skin)
	for k in parts.size():
		var b: Dictionary = parts[k]
		var poly := _pts(b["p"])
		var h := float(b["h"])
		var mh := float(b["mh"])
		if spec["key"] == "zlota44" and h > 40.0 or spec["key"] == "spire" and h > 100.0:
			continue
		if mh > 0.5:
			var held := false
			for j in parts.size():
				if j != k and float(parts[j]["mh"]) < mh - 0.5 and float(parts[j]["h"]) >= mh - 1.5 \
						and boxes[j].grow(-0.5).intersects(boxes[k].grow(-0.5)):
					held = true
					break
			if not held:
				mh = 0.0
		var small := boxes[k].size.length() < 9.0
		var base := g + mh - (0.4 if mh < 0.5 else 0.0)
		if small:
			# A mast, a spire's piece or a ring: plain painted steel in its mapped colour.
			var c := _osm(b["c"], roof)
			_prism(poly, base, g + h, c, c.lightened(0.1), M_STONE, M_STONE)
			continue
		var wall := glass
		if spec.get("mapped", false):
			wall = _osm(b["c"], glass)  # mapped in its own colours (Chałubińskiego 8's white ribs)
		elif h < top_h * 0.3 and h < 40.0:
			# The podium: the tower's glass, a step warmer and darker.
			wall = glass.darkened(0.12).lerp(Color("#b8a88c"), 0.15)
		if spec.get("crest", "") == "slope" and h >= top_h - 0.5:
			_sloped(poly, base, g + h, g + h - 24.0, wall, roof, skin)
		else:
			_prism(poly, base, g + h, wall, roof, skin, M_SKIN)
			if spec.get("crest", "") == "frame" and h >= top_h - 0.5:
				# Rondo 1: an open frame round the top, from the roof to 192 m.
				_prism(poly, g + h, g + 192.0, wall, Color(0, 0, 0, 0), M_SKIN + float(S_FRAME) / 16.0)
		if mh < 2.0:
			_collide(poly)


## Złota 44 (the landmarks loop, after the user's phone look: "like a rectangle, not curvy").
## Its plan, from the mapped core: a straight west front, soft corners, and the east front a
## curve that swells as it climbs (the "sail", 4 m out at the foot, 14 m at the crown), lofted
## through ZLOTA_RINGS rings so it reads curved from the driving camera; the crown is cut on a
## slope from ZLOTA_HI at its north end to ZLOTA_LO at the south, under the white exoskeleton
## skin (S_SAIL).
const ZLOTA_NE := Vector2(-1469.5, 291.8)
const ZLOTA_SE := Vector2(-1462.1, 325.6)
const ZLOTA_SW := Vector2(-1488.5, 334.8)
const ZLOTA_NW := Vector2(-1501.1, 298.5)
const ZLOTA_HI := 192.0
const ZLOTA_LO := 158.0
const ZLOTA_RINGS := 8
const ZLOTA_ARC := 12   # segments of the curved east front
func _zlota_ring(t: float) -> PackedVector2Array:
	var ring := PackedVector2Array()
	var bulge := lerpf(4.0, 14.0, pow(t, 1.3))
	var east := (ZLOTA_SE - ZLOTA_NE).normalized()
	var out := Vector2(-east.y, east.x)
	if out.dot(ZLOTA_NE - ZLOTA_NW) < 0.0:
		out = -out
	# The east front from north to south, swelling most a little south of its middle.
	for i in ZLOTA_ARC + 1:
		var u := float(i) / float(ZLOTA_ARC)
		var swell := sin(PI * pow(u, 0.85))
		ring.append(ZLOTA_NE.lerp(ZLOTA_SE, u) + out * bulge * swell)
	# The soft south-west and north-west corners (three points each), the west front straight.
	for corner: Array in [[ZLOTA_SE, ZLOTA_SW, ZLOTA_NW], [ZLOTA_SW, ZLOTA_NW, ZLOTA_NE]]:
		var a: Vector2 = corner[0]
		var c: Vector2 = corner[1]
		var b: Vector2 = corner[2]
		var r := 4.0
		var p0 := c + (a - c).normalized() * r
		var p1 := c + (b - c).normalized() * r
		ring.append(p0)
		ring.append(p0.lerp(c, 0.5).lerp(p1.lerp(c, 0.5), 0.5))
		ring.append(p1)
	return ring


func _zlota_sail(g: float, glass: Color, roof: Color, skin: float) -> void:
	var base := _zlota_ring(0.0)
	var n := base.size()
	var axis := Vector2(0, -1)  # the crown highest at the north
	var lo_d := INF
	var hi_d := -INF
	for t in [0.0, 1.0]:
		for q in _zlota_ring(t):
			lo_d = minf(lo_d, q.dot(axis))
			hi_d = maxf(hi_d, q.dot(axis))
	var top := func(q: Vector2) -> float:
		return g + lerpf(ZLOTA_LO, ZLOTA_HI, inverse_lerp(lo_d, hi_d, q.dot(axis)))
	var y0 := g - 0.4
	var rings: Array[PackedVector2Array] = []
	for k in ZLOTA_RINGS + 1:
		rings.append(_zlota_ring(float(k) / float(ZLOTA_RINGS)))
	var keep := _mode
	_mode = skin
	var cw := Geometry2D.is_polygon_clockwise(base)
	for k in ZLOTA_RINGS:
		var r0 := rings[k]
		var r1 := rings[k + 1]
		var f0 := float(k) / float(ZLOTA_RINGS)
		var f1 := float(k + 1) / float(ZLOTA_RINGS)
		var run := 0.0
		for i in n:
			var j := (i + 1) % n
			var a0 := r0[i]
			var b0 := r0[j]
			var a1 := r1[i]
			var b1 := r1[j]
			var length := a0.distance_to(b0)
			var e := (b0 - a0).normalized()
			var o := Vector2(e.y, -e.x)
			if not cw:
				o = -o
			var ya0 := lerpf(y0, top.call(rings[ZLOTA_RINGS][i]), f0)
			var yb0 := lerpf(y0, top.call(rings[ZLOTA_RINGS][j]), f0)
			var ya1 := lerpf(y0, top.call(rings[ZLOTA_RINGS][i]), f1)
			var yb1 := lerpf(y0, top.call(rings[ZLOTA_RINGS][j]), f1)
			var hi := maxf(top.call(rings[ZLOTA_RINGS][i]), top.call(rings[ZLOTA_RINGS][j])) - _g
			_quad(Vector3(a0.x, ya0, a0.y), Vector3(b0.x, yb0, b0.y), Vector3(b1.x, yb1, b1.y), Vector3(a1.x, ya1, a1.y),
					Vector3(o.x, 0.0, o.y), glass, Vector2(run, ya0 - _g), Vector2(run + length, yb0 - _g),
					Vector2(run + length, yb1 - _g), Vector2(run, ya1 - _g), hi)
			run += length
	_mode = M_SKIN
	var crown := rings[ZLOTA_RINGS]
	var idx := Geometry2D.triangulate_polygon(crown)
	if idx.is_empty():
		idx = Geometry2D.triangulate_delaunay(crown)
	var up := Vector3(-axis.x * (ZLOTA_HI - ZLOTA_LO), absf(hi_d - lo_d), -axis.y * (ZLOTA_HI - ZLOTA_LO)).normalized()
	for i in range(0, idx.size(), 3):
		var a := crown[idx[i]]
		var b := crown[idx[i + 1]]
		var d := crown[idx[i + 2]]
		# The sloped crown is glazed like the walls (a white slab facing the camera blew out).
		_tri(Vector3(a.x, top.call(a), a.y), Vector3(b.x, top.call(b), b.y), Vector3(d.x, top.call(d), d.y), up,
				glass.lerp(roof, 0.3), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	_mode = keep
	_collide(base)


## Warsaw Spire (the landmarks loop, after the user's phone look: "not recognisable at all").
## OpenStreetMap maps the 180 m tower only as its outline, with the crown and masts as parts
## floating from 180 m, so it stood as a lump. Here the leaf-shaped outline is lofted through
## SPIRE_RINGS rings, narrowing to SPIRE_TAPER at 180 m; an open frame of fins carries the
## crown to 196 m and a mast to 220 m; the brand's parody (SAMSONG, neon_signs.gd) glows on
## its east and west faces near the top, as the real sign does.
const SPIRE_TOP := 180.0
const SPIRE_TAPER := 0.84
const SPIRE_RINGS := 6
const SPIRE_BLUE := Color(0.2, 0.42, 1.0)
func _spire(outline: PackedVector2Array, g: float, glass: Color, roof: Color, skin: float) -> void:
	var base := PackedVector2Array()
	for q in outline:
		if base.is_empty() or (q.distance_to(base[-1]) > 1.2 and q.distance_to(base[0]) > 1.2):
			base.append(q)
	if base.size() < 3:
		return
	var c := _centre(base)
	var ring := func(t: float) -> PackedVector2Array:
		var k := 1.0 - (1.0 - SPIRE_TAPER) * pow(t, 1.5)
		var out := PackedVector2Array()
		for q in base:
			out.append(c + (q - c) * k)
		return out
	var y0 := g - 0.4
	var keep := _mode
	_mode = skin
	var cw := Geometry2D.is_polygon_clockwise(base)
	for k in SPIRE_RINGS:
		var f0 := float(k) / SPIRE_RINGS
		var f1 := float(k + 1) / SPIRE_RINGS
		var r0: PackedVector2Array = ring.call(f0)
		var r1: PackedVector2Array = ring.call(f1)
		var ya := lerpf(y0, g + SPIRE_TOP, f0)
		var yb := lerpf(y0, g + SPIRE_TOP, f1)
		var run := 0.0
		for i in base.size():
			var j := (i + 1) % base.size()
			var e := (r0[j] - r0[i]).normalized()
			var o := Vector2(e.y, -e.x) if cw else Vector2(-e.y, e.x)
			var length := r0[i].distance_to(r0[j])
			_quad(Vector3(r0[i].x, ya, r0[i].y), Vector3(r0[j].x, ya, r0[j].y), Vector3(r1[j].x, yb, r1[j].y),
					Vector3(r1[i].x, yb, r1[i].y), Vector3(o.x, 0.0, o.y), glass, Vector2(run, ya - _g),
					Vector2(run + length, ya - _g), Vector2(run + length, yb - _g), Vector2(run, yb - _g), SPIRE_TOP)
			run += length
	_mode = keep
	var top: PackedVector2Array = ring.call(1.0)
	_prism(top, g + SPIRE_TOP - 0.5, g + SPIRE_TOP, glass, roof, skin, M_SKIN)
	_prism(top, g + SPIRE_TOP, g + 196.0, glass, Color(0, 0, 0, 0), M_SKIN + float(S_FRAME) / 16.0)
	var mast := PackedVector2Array([c + Vector2(-0.8, -0.8), c + Vector2(0.8, -0.8), c + Vector2(0.8, 0.8), c + Vector2(-0.8, 0.8)])
	_prism(mast, g + SPIRE_TOP, g + 220.0, Color("#d5dade"), Color("#e8ecef"), M_STONE, M_STONE)
	_collide(base)
	# The signs, on the wide east and west faces 14 m under the roof.
	var t := (SPIRE_TOP - 14.0) / SPIRE_TOP
	var face: PackedVector2Array = ring.call(t)
	for d: Vector2 in [Vector2(1, 0), Vector2(-1, 0)]:
		var reach := 0.0
		for q in face:
			reach = maxf(reach, (q - c).dot(d))
		var at := c + d * reach
		signs.append(["SAMSONG", Vector3(at.x, g + SPIRE_TOP - 18.0, at.y), Vector3(d.x, 0.0, d.y), 2.6, SPIRE_BLUE])


## A tower's top cut on a slope: the walls rise to `hi` at the outline's far end (its longest
## axis, towards the north) and fall to `lo` at the other, and a sloping roof closes it.
func _sloped(poly: PackedVector2Array, y0: float, hi: float, lo: float, wall: Color, roof: Color, skin: float) -> void:
	var c := _centre(poly)
	var axis := Vector2.ZERO
	var reach := 0.0
	for q in poly:
		if (q - c).length() > reach:
			reach = (q - c).length()
			axis = (q - c).normalized()
	if axis.y > 0.0:
		axis = -axis  # the high end towards the north (-z)
	var lo_d := INF
	var hi_d := -INF
	for q in poly:
		lo_d = minf(lo_d, (q - c).dot(axis))
		hi_d = maxf(hi_d, (q - c).dot(axis))
	var top := func(q: Vector2) -> float:
		return lerpf(lo, hi, inverse_lerp(lo_d, hi_d, (q - c).dot(axis)))
	var keep := _mode
	_mode = skin
	var run := 0.0
	for i in poly.size():
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var length := a.distance_to(b)
		if length < 0.02:
			continue
		var o := _out(poly, a, b)
		var n := Vector3(o.x, 0.0, o.y).normalized()
		var ta: float = top.call(a)
		var tb: float = top.call(b)
		_quad(Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, tb, b.y), Vector3(a.x, ta, a.y), n, wall,
				Vector2(run, y0 - _g), Vector2(run + length, y0 - _g), Vector2(run + length, tb - _g),
				Vector2(run, ta - _g), maxf(ta, tb) - _g)
		run += length
	_mode = M_SKIN
	var idx := Geometry2D.triangulate_polygon(poly)
	if idx.is_empty():
		idx = Geometry2D.triangulate_delaunay(poly)
	var up := Vector3(-axis.x * (hi - lo), absf(hi_d - lo_d), -axis.y * (hi - lo)).normalized()
	for i in range(0, idx.size(), 3):
		var a := poly[idx[i]]
		var b := poly[idx[i + 1]]
		var d := poly[idx[i + 2]]
		# Glazed like the walls: a pale slab tilted to the camera blew out (the landmarks loop).
		_tri(Vector3(a.x, top.call(a), a.y), Vector3(b.x, top.call(b), b.y), Vector3(d.x, top.call(d), d.y), up,
				wall.lerp(roof, 0.3), Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	_mode = keep


# --- the low-rise landmarks (the landmarks loop) -----------------------------------------------

## Buildings kept as LoD2 draws them (their real massing) but in their own stone, brick and roof
## colours (like the museum, `skin_at`), each with a card: what a player passes most, from the
## theatre and the castle to the churches on the royal route. `mode` M_MONUMENT draws tall
## windows between piers (plastered and stone fronts), M_STONE a plain wall (brick, the science
## centre's dark slabs). Colours from photographs, a step paler than life.
const SKINS := [
	{"key": "teatr", "osm": "Teatr Wielki", "mode": M_MONUMENT, "wall": "#ddd2b6", "roof": "#7fa894"},
	{"key": "kopernik", "osm": "Centrum Nauki Kopernik", "mode": M_STONE, "wall": "#5f5a54", "roof": "#6f9a4c"},
	{"key": "buw", "osm": "Biblioteka Uniwersytecka", "mode": M_STONE, "wall": "#7f9e8a", "roof": "#6a9a52"},
	{"key": "zamek", "osm": "Zamek Królewski", "mode": M_MONUMENT, "wall": "#c87560", "roof": "#6e5a4e"},
	{"key": "barbakan", "osm": "Barbakan", "mode": M_STONE, "wall": "#ab5a42", "roof": "#6b4a3c"},
	{"key": "archikatedra", "osm": "Archikatedra pw. Świętego Jana Chrzciciela", "mode": M_STONE, "wall": "#a2503c", "roof": "#7a3d30"},
	{"key": "sw_anna", "osm": "Kościół pw. Świętej Anny", "mode": M_MONUMENT, "wall": "#e6dcc4", "roof": "#8a5a44"},
	{"key": "prezydencki", "osm": "Pałac Prezydencki", "mode": M_MONUMENT, "wall": "#ece3cc", "roof": "#6a7a77"},
	{"key": "sw_krzyz", "osm": "Kościół pw. Świętego Krzyża", "mode": M_MONUMENT, "wall": "#e3d9c0", "roof": "#5d6e64"},
	{"key": "staszic", "osm": "Pałac Staszica", "mode": M_MONUMENT, "wall": "#e2d6b8", "roof": "#5f6f6a"},
	{"key": "zacheta", "osm": "Zachęta", "mode": M_MONUMENT, "wall": "#d9b98c", "roof": "#7d7466"},
	{"key": "wszystkich", "osm": "Kościół Wszystkich Świętych", "mode": M_MONUMENT, "wall": "#ddcfaa", "roof": "#6e7f6e"},
	{"key": "aleksander", "osm": "Kościół Świętego Aleksandra", "mode": M_MONUMENT, "wall": "#ebe4d2", "roof": "#7f8f88"},
	{"key": "mirowska", "osm": "Hala Mirowska", "mode": M_STONE, "wall": "#a85c40", "roof": "#6d7470"},
	{"key": "sejm", "osm": "Sejm RP", "mode": M_MONUMENT, "wall": "#e2e0d8", "roof": "#8d8f8c"},
]


func _find_skins() -> void:
	for t: Dictionary in SKINS:
		var outline := _landmark(t["osm"])
		if outline.size() < 3:
			continue
		_add_site(t["key"], [outline])
		if not sites.is_empty() and sites[-1]["key"] == t["key"]:
			sites[-1]["skin"] = {"mode": t["mode"], "wall": Color(t["wall"]), "roof": Color(t["roof"])}


# --- Muzeum Narodowe (the landmarks loop) ------------------------------------------------------

## The museum's building (1927-1938) at the east end of Al. Jerozolimskie, mapped as one
## outline round the courtyards (with the army museum in its wings): kept as the LoD2 or
## OpenStreetMap model draws it, but in its pale stone with tall windows between piers
## (map_builder asks `skin_at`), and on the picking grid for its card.
const MUZEUM := Vector2(24.0, 251.0)  # inside its wings (its outline's centre is a courtyard)
const MUZEUM_STONE := Color("#c9bfa9")
const MUZEUM_ROOF := Color("#8f8b84")
func _find_muzeum() -> void:
	for bld in data["buildings"]:
		var q := _pts(bld["p"])
		if q.size() < 20 or float(bld["h"]) < 10.0 or not _box_of([q]).has_point(MUZEUM):
			continue
		if Geometry2D.is_point_in_polygon(MUZEUM, q):
			_add_site("muzeum", [q])
			if not sites.is_empty() and sites[-1]["key"] == "muzeum":
				sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": MUZEUM_STONE, "roof": MUZEUM_ROOF}
			return


# --- MDM (the landmarks loop, street furniture) --------------------------------------------------

## Marszałkowska Dzielnica Mieszkaniowa: the tall blocks round Plac Konstytucji (MDM_SQUARE,
## within MDM_SQUARE_R) and along Marszałkowska to Plac Zbawiciela (within MDM_REACH of the
## axis), kept as LoD2 draws them but in their pale sandstone with tall windows between piers
## and grey sheet roofs; one card for the lot. The square's candelabras are map_builder's.
const MDM_SQUARE := Vector2(-533.8, 1282.4)
const MDM_SOUTH := Vector2(-413.9, 1565.2)
const MDM_SQUARE_R := 95.0
const MDM_REACH := 50.0
const MDM_STONE := Color("#cdbfa3")
const MDM_ROOF := Color("#7f7b74")
func _find_mdm() -> void:
	var zone: Array = []
	for bld in data["buildings"]:
		if float(bld["h"]) < 15.0 or str(bld.get("name", "")) != "":
			continue
		var q := _pts(bld["p"])
		if q.size() < 4:
			continue
		var c := _box_of([q]).get_center()
		var axis := Geometry2D.get_closest_point_to_segment(c, MDM_SQUARE, MDM_SOUTH)
		if c.distance_to(MDM_SQUARE) < MDM_SQUARE_R or c.distance_to(axis) < MDM_REACH:
			zone.append(q)
	if zone.is_empty():
		return
	_add_site("mdm", zone)
	if not sites.is_empty() and sites[-1]["key"] == "mdm":
		sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": MDM_STONE, "roof": MDM_ROOF}


## A kept building's site (the museum) on the picking grid: every cell whose centre is inside.
func _mark_zone(site: Dictionary) -> void:
	var cell: float = map.ROOF_CELL
	var box: Rect2 = site["box"]
	var i0 := maxi(floori((box.position.x - map._roof_x0) / cell), 0)
	var i1 := mini(floori((box.end.x - map._roof_x0) / cell), map._roof_nx - 1)
	var j0 := maxi(floori((box.position.y - map._roof_z0) / cell), 0)
	var j1 := mini(floori((box.end.y - map._roof_z0) / cell), map._roof_nz - 1)
	for j in range(j0, j1 + 1):
		for i in range(i0, i1 + 1):
			var p := Vector2(map._roof_x0 + (i + 0.5) * cell, map._roof_z0 + (j + 0.5) * cell)
			for z: PackedVector2Array in site["zone"]:
				if Geometry2D.is_point_in_polygon(p, z):
					_pick[j * map._roof_nx + i] = _id
					break


# --- Stadion Narodowy -------------------------------------------------------------------------

## The bowl in the old stadium's embankment: a woven red-and-white skin leaning out like a
## basket from the embankment's crest to the roof's edge, 72 masts leaning with it and
## spiking above the roof, a white membrane roof ringing the open middle, the stands
## (red seats) falling to the pitch, and the needle hanging over the centre on its cables.
## The outline at every angle comes from the mapped masts; heights from the mapped parts
## (roof edge 44 m, mast tips 60 m, needle 30-100 m, over the street round it).
func _build_stadium(site: Dictionary) -> void:
	var inner: Array = site["inner"]
	var outer: Array = site["outer"]
	var c: Vector2 = site["centre"]
	var n := inner.size()
	var street := INF
	for v in outer:
		var q: Vector2 = c + ((v as Vector2) - c) * 1.25
		street = minf(street, map.terrain_height(q.x, q.y))
	_g = street
	var pitch: float = map.terrain_height(c.x, c.y)
	var roof_y := street + 44.0
	var skin_top := street + 41.0
	# Rings at every mast angle.
	var base := PackedVector2Array()   # the skin's foot, on the crest
	var mid := PackedVector2Array()    # the basket's belly
	var top := PackedVector2Array()    # the skin's top, under the roof edge
	var edge := PackedVector2Array()   # the roof's outer edge
	var hole := PackedVector2Array()   # the roof's inner edge
	var foot := PackedFloat32Array()
	for k in n:
		var vi: Vector2 = inner[k]
		var vo: Vector2 = outer[k]
		var d := vi - c
		base.append(c + d * 0.965)
		mid.append(vi + (vo - vi) * 0.25)
		top.append(vi + (vo - vi) * 0.62)
		edge.append(vo + (vo - c).normalized() * 1.5)
		hole.append(c + d * 0.47)
		foot.append(map.terrain_height(vi.x, vi.y) - 1.0)
	# The skin: two bands, its weave continuous all the way round.
	_mode = M_WEAVE
	var run := 0.0
	for k in n:
		var k1 := (k + 1) % n
		var len0 := base[k].distance_to(base[k1])
		var out := (base[k] + base[k1]) * 0.5 - c
		var nrm := Vector3(out.x, 0.0, out.y).normalized()
		var ym := lerpf(foot[k], skin_top, 0.45)
		var ym1 := lerpf(foot[k1], skin_top, 0.45)
		var p0 := Vector3(base[k].x, foot[k], base[k].y)
		var p1 := Vector3(base[k1].x, foot[k1], base[k1].y)
		var m0 := Vector3(mid[k].x, ym, mid[k].y)
		var m1 := Vector3(mid[k1].x, ym1, mid[k1].y)
		var t0 := Vector3(top[k].x, skin_top, top[k].y)
		var t1 := Vector3(top[k1].x, skin_top, top[k1].y)
		_quad(p0, p1, m1, m0, nrm, Color.WHITE, Vector2(run, foot[k] - street), Vector2(run + len0, foot[k1] - street),
				Vector2(run + len0, ym1 - street), Vector2(run, ym - street), skin_top - street)
		_quad(m0, m1, t1, t0, (nrm + Vector3(0, -0.25, 0)).normalized(), Color.WHITE, Vector2(run, ym - street),
				Vector2(run + len0, ym1 - street), Vector2(run + len0, skin_top - street), Vector2(run, skin_top - street), skin_top - street)
		run += len0
	_collide(base)
	# The promenade on the old embankment's crest, round the skin's foot.
	_mode = M_STONE
	for k in n:
		var k1 := (k + 1) % n
		var rings := [0.96, 1.03, 1.1, 1.17]
		for q in rings.size() - 1:
			var s0: float = rings[q]
			var s1: float = rings[q + 1]
			var a0: Vector2 = c + ((inner[k] as Vector2) - c) * s0
			var b0: Vector2 = c + ((inner[k1] as Vector2) - c) * s0
			var a1: Vector2 = c + ((inner[k] as Vector2) - c) * s1
			var b1: Vector2 = c + ((inner[k1] as Vector2) - c) * s1
			var pts := [a0, b0, b1, a1]
			var v3: Array[Vector3] = []
			for v: Vector2 in pts:
				v3.append(Vector3(v.x, maxf(map.terrain_height(v.x, v.y), foot[k] - 1.5) + 0.25, v.y))
			_quad(v3[0], v3[1], v3[2], v3[3], Vector3.UP, Color("#cbc6ba") if (k / 3) % 2 == 0 else Color("#c3beb2"))
	# The roof: an edge band, then the membrane down to the open middle, in panels.
	_mode = M_STONE
	for k in n:
		var k1 := (k + 1) % n
		var o := (edge[k] + edge[k1]) * 0.5 - c
		_quad(Vector3(edge[k].x, roof_y - 1.6, edge[k].y), Vector3(edge[k1].x, roof_y - 1.6, edge[k1].y),
				Vector3(edge[k1].x, roof_y, edge[k1].y), Vector3(edge[k].x, roof_y, edge[k].y),
				Vector3(o.x, 0, o.y).normalized(), Color("#d9dbdf"))
		_quad(Vector3(edge[k].x, roof_y - 1.6, edge[k].y), Vector3(edge[k1].x, roof_y - 1.6, edge[k1].y),
				Vector3(top[k1].x, skin_top, top[k1].y), Vector3(top[k].x, skin_top, top[k].y), Vector3.DOWN, Color("#9da1a8"))
	_mode = M_MEMBRANE
	var hole_y := roof_y - 3.5
	for k in n:
		var k1 := (k + 1) % n
		var p0 := Vector3(edge[k].x, roof_y, edge[k].y)
		var p1 := Vector3(edge[k1].x, roof_y, edge[k1].y)
		var p2 := Vector3(hole[k1].x, hole_y, hole[k1].y)
		var p3 := Vector3(hole[k].x, hole_y, hole[k].y)
		var nr := (p1 - p0).cross(p3 - p0).normalized()
		if nr.y < 0.0:
			nr = -nr
		_quad(p0, p1, p2, p3, nr, Color("#f4f4f1") if k % 2 == 0 else Color("#eaebe8"))
	# The stands, falling from under the roof's inner edge to the pitch: red seats with
	# grey gangway rings.
	_mode = M_STONE
	var tiers := [[0.5, hole_y - 2.0, Color("#b4232c")], [0.43, street + 22.0, Color("#8e8a88")],
			[0.41, street + 21.0, Color("#c42a31")], [0.33, pitch + 4.0, Color("#8e8a88")],
			[0.315, pitch + 3.0, Color("#c42a31")], [0.25, pitch + 0.4, Color("#4f8a3a")]]
	var prev_s := 0.5
	var prev_y: float = hole_y - 2.0
	for t in range(1, tiers.size()):
		var s: float = tiers[t][0]
		var y: float = tiers[t][1]
		var col: Color = tiers[t - 1][2]
		for k in n:
			var k1 := (k + 1) % n
			var a0: Vector2 = c + ((inner[k] as Vector2) - c) * prev_s
			var b0: Vector2 = c + ((inner[k1] as Vector2) - c) * prev_s
			var a1: Vector2 = c + ((inner[k] as Vector2) - c) * s
			var b1: Vector2 = c + ((inner[k1] as Vector2) - c) * s
			var p0 := Vector3(a0.x, prev_y, a0.y)
			var p1 := Vector3(b0.x, prev_y, b0.y)
			var p2 := Vector3(b1.x, y, b1.y)
			var p3 := Vector3(a1.x, y, a1.y)
			var nr := (p1 - p0).cross(p3 - p0).normalized()
			if nr.y < 0.0:
				nr = -nr
			_quad(p0, p1, p2, p3, nr, col if k % 6 != 0 else col.lightened(0.25))
		prev_s = s
		prev_y = y
	# The pitch: grass in stripes, inside the last tier, and its white lines.
	var field := PackedVector2Array()
	for k in n:
		field.append(c + ((inner[k] as Vector2) - c) * 0.25)
	_cap(field, pitch + 0.4, Color("#4f8a3a"))
	var axis := Vector2.RIGHT
	var far := 0.0
	for v in inner:
		var dd := (v as Vector2) - c
		if dd.length() > far:
			far = dd.length()
			axis = dd.normalized()
	var across := Vector2(-axis.y, axis.x)
	var line := Color("#f2f2ee")
	var y_line := pitch + 0.45
	for seg in [[-52.0, -34.0, 52.0, -34.0], [-52.0, 34.0, 52.0, 34.0], [-52.0, -34.0, -52.0, 34.0], [52.0, -34.0, 52.0, 34.0], [0.0, -34.0, 0.0, 34.0]]:
		var a := c + axis * float(seg[0]) + across * float(seg[1])
		var b := c + axis * float(seg[2]) + across * float(seg[3])
		var w := (b - a).normalized().orthogonal() * 0.35
		_quad(Vector3(a.x - w.x, y_line, a.y - w.y), Vector3(b.x - w.x, y_line, b.y - w.y), Vector3(b.x + w.x, y_line, b.y + w.y),
				Vector3(a.x + w.x, y_line, a.y + w.y), Vector3.UP, line)
	# The masts: from the foot of the skin, leaning out with it, spiking over the roof.
	for k in n:
		var vi: Vector2 = inner[k]
		var vo: Vector2 = outer[k]
		var a := Vector3(vi.x, foot[k], vi.y)
		var b := Vector3(vo.x, street + 60.0, vo.y)
		_beam(a, b, 0.55, Color("#e4e6ea"))
	# The needle: a white spindle hanging over the centre, a dark hub ring where the
	# cables meet, a red light on its tip; cables to the roof's inner edge.
	var steel := Color("#f1f1ee")
	var ring8 := func(radius: float) -> PackedVector2Array:
		var out := PackedVector2Array()
		for k in 10:
			out.append(c + Vector2.from_angle(TAU * k / 10.0) * radius)
		return out
	_frustum(ring8.call(0.6), street + 30.0, ring8.call(1.6), street + 37.0, steel)
	_prism(ring8.call(5.0), street + 37.0, street + 43.0, Color("#2c2d31"), Color("#3a3b40"), M_STONE, M_STONE)
	_frustum(ring8.call(1.6), street + 43.0, ring8.call(9.0), street + 55.0, steel)
	_frustum(ring8.call(9.0), street + 55.0, ring8.call(1.2), street + 66.0, steel)
	_frustum(ring8.call(1.2), street + 66.0, ring8.call(0.3), street + 99.0, steel)
	_prism(ring8.call(0.45), street + 99.0, street + 100.5, Color("#ff3b30"), Color("#ff6a5c"), M_LAMP, M_LAMP)
	var hub := Vector3(c.x, street + 40.0, c.y)
	var keep_id := _id
	_id = 0
	for k in range(0, n, 3):
		var h: Vector2 = hole[k]
		_beam(hub, Vector3(h.x, hole_y, h.y), 0.18, Color("#c8cbd0"), false)
	for k in range(0, n, n / 4):
		var e: Vector2 = edge[k]
		_beam(hub + Vector3(0, 2.0, 0), Vector3(e.x, roof_y, e.y), 0.25, Color("#2c2d31"), false)
	_id = keep_id


## A square beam from a to b, `w` wide (masts, cables). Cables stay out of the roof grid.
func _beam(a: Vector3, b: Vector3, w: float, col: Color, solid := true) -> void:
	var z := (b - a).normalized()
	var x := Vector3.UP.cross(z)
	if x.length_squared() < 0.001:
		x = Vector3.RIGHT
	x = x.normalized() * w * 0.5
	var y := z.cross(x).normalized() * w * 0.5
	var keep := _mode
	_mode = M_STONE
	var corners := [x + y, -x + y, -x - y, x - y]
	for k in 4:
		var c0: Vector3 = corners[k]
		var c1: Vector3 = corners[(k + 1) % 4]
		var nrm := (c0 + c1).normalized()
		var p0 := a + c0
		var p1 := a + c1
		var p2 := b + c1
		var p3 := b + c0
		_tri(p0, p1, p2, nrm, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, solid)
		_tri(p0, p2, p3, nrm, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, solid)
	_mode = keep


# --- Warszawa Centralna -----------------------------------------------------------------------

## The roof: a grid of hyperbolic-paraboloid shells (saddles whose corners rise and
## fall in turn, so the eaves zigzag along every side) on the mapped pillars; the glass
## hall under it; a flat canopy round it, just under the shells' low corners.
func _build_centralna(site: Dictionary) -> void:
	_o = CENTRALNA
	_a = Vector2.from_angle(deg_to_rad(CENTRALNA_TURN))
	_b = Vector2(-_a.y, _a.x)
	_g = _ground_under(_rect(0.0, 0.0, 70.0, 43.0))
	var g := _g
	var u0 := -70.0
	var v0 := -28.5
	var bu := 10.0
	var bv := 19.0
	var nu := 14
	var nv := 3
	var low := 15.4
	var high := 18.6
	var corner_h := func(i: int, j: int) -> float: return g + (high if (i + j) % 2 == 0 else low)
	# The canopy, under the shells' low corners: the strips beyond the roof on both long sides.
	var slab := Color("#a9adb0")
	for side in [-1.0, 1.0]:
		var cv: float = side * 35.75
		_prism(_rect(0.0, cv, 70.0, 7.25), g + 14.6, g + 15.3, Color("#55595e"), slab, M_STONE, M_STONE)
	# The shells, each in 3 x 3 facets.
	var conc := Color("#d2cdc1")
	_mode = M_STONE
	for j in nv:
		for i in nu:
			var hs := [corner_h.call(i, j), corner_h.call(i + 1, j), corner_h.call(i + 1, j + 1), corner_h.call(i, j + 1)]
			var m := 3
			for b in m:
				for a in m:
					var pts: Array[Vector3] = []
					for c in [[a, b], [a + 1, b], [a + 1, b + 1], [a, b + 1]]:
						var s := float(c[0]) / m
						var t := float(c[1]) / m
						var y: float = lerpf(lerpf(hs[0], hs[1], s), lerpf(hs[3], hs[2], s), t)
						var p := _w(u0 + (i + s) * bu, v0 + (j + t) * bv)
						pts.append(Vector3(p.x, y, p.y))
					var n := (pts[1] - pts[0]).cross(pts[3] - pts[0]).normalized()
					if n.y < 0.0:
						n = -n
					_quad(pts[0], pts[1], pts[2], pts[3], n, conc if (i + j) % 2 == 0 else conc.darkened(0.07))
	# The shells' edge all round: a dark fascia that zigzags with them.
	var edges := []
	for i in nu:
		edges.append([Vector2(u0 + i * bu, v0), Vector2(u0 + (i + 1) * bu, v0), corner_h.call(i, 0), corner_h.call(i + 1, 0), -_b])
		edges.append([Vector2(u0 + i * bu, v0 + nv * bv), Vector2(u0 + (i + 1) * bu, v0 + nv * bv), corner_h.call(i, nv), corner_h.call(i + 1, nv), _b])
	for j in nv:
		edges.append([Vector2(u0, v0 + j * bv), Vector2(u0, v0 + (j + 1) * bv), corner_h.call(0, j), corner_h.call(0, j + 1), -_a])
		edges.append([Vector2(u0 + nu * bu, v0 + j * bv), Vector2(u0 + nu * bu, v0 + (j + 1) * bv), corner_h.call(nu, j), corner_h.call(nu, j + 1), _a])
	for e in edges:
		var a: Vector2 = _wl(e[0])
		var b: Vector2 = _wl(e[1])
		var out: Vector2 = e[4]
		_quad(Vector3(a.x, float(e[2]) - 0.9, a.y), Vector3(b.x, float(e[3]) - 0.9, b.y),
				Vector3(b.x, float(e[3]) + 0.05, b.y), Vector3(a.x, float(e[2]) + 0.05, a.y), Vector3(out.x, 0, out.y), Color("#4a4d52"))
	# The glass hall under the roof.
	_prism(_rect(-1.9, 0.4, 35.5, 25.6), g - 0.4, g + 14.6, Color("#7f9fb2"), Color(0, 0, 0, 0), M_GLASS)
	_collide(_rect(-1.9, 0.4, 35.5, 25.6))
	# The pillars that carry the shells (mapped), solid for the car too.
	for p: Vector2 in site.get("pillars", []):
		var l := _local(p)
		_lbox(l.x, l.y, 0.6, 0.6, g - 0.4, g + low, Color("#bdb8ad"), M_STONE)
		_collide(_rect(l.x, l.y, 0.6, 0.6))


# --- Most Poniatowskiego's towers ---------------------------------------------------------------

## Four stone towers at the ends of the river span, from the bank to well over the deck:
## a plinth, a shaft with a cornice, an open arcade on top, a pointed roof and a finial.
func _build_towers(site: Dictionary) -> void:
	var stone := Color("#cbbfa6")
	var dark := Color("#3a3640")
	var seats: Array = site.get("towers", [])
	for n in (seats.size() if not seats.is_empty() else (site["zone"] as Array).size()):
		var c: Vector2
		var hu := 0.0
		var hv := 0.0
		var deck := 0.0
		var g := 0.0
		if not seats.is_empty():
			# Loop 3b (R7): the bake's seat.
			var t: Dictionary = seats[n]
			c = Vector2(float(t["c"][0]), float(t["c"][1]))
			_a = Vector2(float(t["a"][0]), float(t["a"][1]))
			_b = Vector2(-_a.y, _a.x)
			_o = c
			hu = float(t["hu"])
			hv = float(t["hv"])
			g = float(t["base"])
			deck = float(t["deck"])
			_g = g
		else:
			var poly: PackedVector2Array = Geometry2D.offset_polygon(site["zone"][n], -3.0)[0]
			c = _centre(poly)
			# The tower's own axes, from its longest edge.
			var best := 0.0
			for i in poly.size():
				var e := poly[(i + 1) % poly.size()] - poly[i]
				if e.length() > best:
					best = e.length()
					_a = e.normalized()
			_b = Vector2(-_a.y, _a.x)
			_o = c
			for q in poly:
				var l := _local(q)
				hu = maxf(hu, absf(l.x))
				hv = maxf(hv, absf(l.y))
			hu = minf(hu, 8.0)
			hv = minf(hv, 6.0)
			_g = map.terrain_height(c.x, c.y)
			deck = _g
			for d in [Vector2(14, 0), Vector2(-14, 0), Vector2(0, 14), Vector2(0, -14)]:
				deck = maxf(deck, map.ground_height(c.x + d.x, c.y + d.y))
			g = _g
		var top := deck + 15.0
		_lbox(0.0, 0.0, hu + 0.6, hv + 0.6, g - 0.5, deck + 1.2, stone.darkened(0.12), M_STONE)
		_lbox(0.0, 0.0, hu, hv, deck + 1.2, top - 4.5, stone, M_STONE)
		_lbox(0.0, 0.0, hu + 0.5, hv + 0.5, top - 4.5, top - 3.8, stone.lightened(0.1), M_STONE)
		_lbox(0.0, 0.0, hu - 0.3, hv - 0.3, top - 3.8, top, stone, M_STONE)
		# The arcade: dark arched openings on all four faces.
		for f2 in 4:
			var nu: float = [1.0, -1.0, 0.0, 0.0][f2]
			var nv: float = [0.0, 0.0, 1.0, -1.0][f2]
			var n2: Vector2 = _a * nu + _b * nv
			var side := Vector2(-n2.y, n2.x)
			var half := (hv if nu != 0.0 else hu) - 0.3
			var face := (hu if nu != 0.0 else hv) - 0.3 + 0.05
			for k in 2:
				var cpos := c + n2 * face + side * (half * (-0.45 if k == 0 else 0.45))
				var w := side * half * 0.28
				_mode = M_STONE
				_quad(Vector3(cpos.x - w.x, top - 3.3, cpos.y - w.y), Vector3(cpos.x + w.x, top - 3.3, cpos.y + w.y),
						Vector3(cpos.x + w.x, top - 0.6, cpos.y + w.y), Vector3(cpos.x - w.x, top - 0.6, cpos.y - w.y),
						Vector3(n2.x, 0, n2.y), dark)
		_attic(_rect(0.0, 0.0, hu - 0.3, hv - 0.3), top, 1.0, stone.lightened(0.1))
		_mode = M_STONE
		_pyramid(_rect(0.0, 0.0, hu - 0.8, hv - 0.8), top, top + 6.0, Color("#6f7d78"))
		_prism(_rect(0.0, 0.0, 0.35, 0.35), top + 5.5, top + 8.5, GOLD, GOLD, M_GOLD, M_GOLD)
		if seats.is_empty():
			_collide(_rect(0.0, 0.0, hu + 0.6, hv + 0.6))
		else:
			# Solid from the boulevard to over the deck (a car on either level stops at it).
			_collide_span(_rect(0.0, 0.0, hu + 0.6, hv + 0.6), g - 1.0, deck + 6.0)
