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
const Neon := preload("res://scripts/neon_signs.gd")  # the dusk loop: sign sizes
const M_PAVILION := 8.0   # glass lit from inside: + 0 warm (the Rotunda), + 0.5 cool (Varso's crown)
const M_ATTIC := 9.0      # a parapet cut into merlons; fraction = its height / 10 m
const M_LAMP := 10.0      # glows at night
const M_MEMBRANE := 11.0  # the stadium's roof membrane
const M_GLASS := 12.0     # curtain wall with mullions (Varso)
const M_SKIN := 13.0      # a tower's own skin; fraction = style / 16 (S_*, building.gdshader skin())
const M_GOTHIC := 14.0    # brick Gothic: buttresses and pointed lancets (the Cathedral, the Barbican)

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
const S_TILE := 9   # Novotel's white tiled shaft (the Rondo photos, 2026-10-31)

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
	{"key": "rondo1", "osm": "Rondo 1", "style": S_FINS, "glass": "#6f8ea4", "roof": "#a9b3b9", "crest": "frame",
			"base_sign": "ENELMEDIK"},
	{"key": "plater49", "osm": "InterContinental", "style": S_GRID, "glass": "#5f7f9a", "roof": "#c3c7c9", "sign": "INTERKONTI"},
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
	# The dusk loop (2026-10-31): Centrum LIM holds the Marriott (the 140 m tower at about
	# (-1308, 697)), so the one site is dressed as it: dark green-black glass in a fine grid,
	# dark bands, a lattice mast and the names (_marriott).
	{"key": "lim", "osm": "Centrum LIM", "style": S_GRID, "glass": "#24343a", "roof": "#6f777b", "sign": "PREZYDENT", "marriott": true},
	{"key": "chalubinskiego8", "osm": "Chałubińskiego 8", "style": S_FINS, "glass": "#2f6f8f", "roof": "#c9cfd2", "mapped": true},
	{"key": "spektrum", "osm": "Spektrum Tower", "style": S_BANDS, "glass": "#2f5563", "roof": "#7c878c", "mapped": true},
	{"key": "bridge", "osm": "The Bridge", "style": S_FINS, "glass": "#6d8da6", "roof": "#b0bac2"},
	# The second pass: the rest of the skyline over 80 m (the hotels by their addresses).
	{"key": "grzybowska63", "osm": "Hilton Warsaw City", "style": S_BANDS, "glass": "#4d7590", "roof": "#9aa5ad", "sign": "CHILTON"},
	{"key": "jp2_21", "osm": "The Westin Warsaw", "style": S_GRID, "glass": "#86aca7", "roof": "#a9b5b3", "mapped": true, "sign": "WESTYNKA"},
	{"key": "marszalkowska94", "osm": "Novotel Warszawa Centrum", "style": S_TILE, "glass": "#d9dcdf", "roof": "#c9c9c2", "vsign": "NOWOTEL", "chamfer": true},
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
			"Centrum handlowe pod falującym szklanym dachem, obok biurowce Lumen i Skylight. Otwarte w 2007 roku.",
			"A shopping centre under a rolling glass roof, with the Lumen and Skylight office buildings. Opened in 2007."],
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
			"Dworzec otwarty w 1975 roku: szklana hala pod płaskim, wysuniętym dachem na paraboloidach hiperbolicznych.",
			"The main station, opened in 1975: a glass hall under a flat overhanging roof on hyperbolic paraboloid shells."],
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
			"Hotel Prezydent nad Dworcem Centralnym, 140 m, od 1989 roku.",
			"Hotel Prezydent over the Central Station, 140 m, since 1989."],
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
			"Otwarte w 2010 roku. Na dachu ogród, obok czarne planetarium.",
			"Opened in 2010. A garden on the roof, the black planetarium beside it."],
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
			"Przed nim książę Józef Poniatowski na koniu i cztery kamienne lwy.",
			"Prince Józef Poniatowski on horseback and four stone lions before it."],
	"sw_krzyz": ["Kościół Świętego Krzyża",
			"W filarze kościoła spoczywa serce Chopina.",
			"Chopin's heart rests in one of its pillars."],
	"staszic": ["Pałac Staszica",
			"Przed nim stoi pomnik Kopernika.",
			"Copernicus's statue stands in front of it."],
	"zacheta": ["Zachęta",
			"Galeria sztuki w gmachu z 1900 roku.",
			"An art gallery in a building of 1900."],
	"trojca": ["Kościół Świętej Trójcy",
			"Luterańska rotunda Zuga z 1781 roku przy placu Małachowskiego.",
			"Zug's Lutheran rotunda of 1781 on Plac Małachowskiego."],
	"wszystkich": ["Kościół Wszystkich Świętych",
			"Przy placu Grzybowskim.",
			"On Plac Grzybowski."],
	"aleksander": ["Kościół Świętego Aleksandra",
			"Rotunda na placu Trzech Krzyży.",
			"The rotunda on Plac Trzech Krzyży."],
	"mirowska": ["Hala Mirowska",
			"Ceglana hala targowa.",
			"A brick market hall."],
	"arkadia": ["Arkadka",
			"Największe centrum handlowe w mieście, przy rondzie Radosława.",
			"The city's biggest mall, by Rondo Radosława."],
	"forest": ["Forest",
			"Biurowiec z zielonymi tarasami i 120-metrową wieżą.",
			"An office block of planted terraces and a 120 m tower."],
	"flaga": ["Flaga na rondzie Radosława",
			"Biało-czerwona na maszcie wysokim na prawie 58 m.",
			"The white-and-red on a mast almost 58 m tall."],
	"swieto": ["Most Świętokrzyski",
			"Most wantowy z 2000 roku: jeden pylon, wanty w jednej płaszczyźnie.",
			"A cable-stayed bridge of 2000: one pylon, its stays in one plane."],
	"zygmunt": ["Kolumna Zygmunta",
			"Najstarszy świecki pomnik Warszawy, z 1644 roku.",
			"Warsaw's oldest secular monument, of 1644."],
	"metropolitan": ["Metropolitan",
			"Biurowiec Normana Fostera przy placu Piłsudskiego, z 2003 roku.",
			"Norman Foster's office building on Plac Piłsudskiego, of 2003."],
	"sejm": ["Sejm RP",
			"Przy Wiejskiej.",
			"On Wiejska."],
	"muzeum": ["Muzeum Narodowe",
			"Gmach z lat 1927–1938 przy Alejach Jerozolimskich.",
			"The museum's building of 1927–1938 on Al. Jerozolimskie."],
	"wiktoria": ["Hotel Wiktoria",
			"Hotel z 1976 roku przy Królewskiej, z widokiem na plac Piłsudskiego.",
			"A hotel of 1976 on Królewska, looking out over Plac Piłsudskiego."],
	"bez_kantow": ["Dom bez Kantów",
			"Modernizm z zaokrąglonymi narożnikami. Kantów tu nie ma.",
			"Modernism with rounded corners: no kanty (edges, or swindles)."],
	"departament": ["Departament Wojskowej Służby Zdrowia",
			"Przy Królewskiej, na skraju placu Piłsudskiego.",
			"On Królewska, at the edge of Plac Piłsudskiego."],
	"europejski": ["Hotel Europejski",
			"Klasycystyczny hotel z lat 1857–1877 przy Krakowskim Przedmieściu.",
			"A classical hotel of 1857–1877 on Krakowskie Przedmieście."],
	"msn": ["Muzeum Sztuki Nowoczesnej",
			"Biały gmach Thomasa Phifera przy Placu Defilad. Otwarty w 2024 roku.",
			"Thomas Phifer's white museum on Plac Defilad. Opened in 2024."],
	"tr": ["Plac budowy TR Warszawa",
			"Ogrodzony plac pod nowy gmach teatru TR Warszawa, obok białego muzeum.",
			"The fenced plot for TR Warszawa's new theatre, next to the white museum."],
	"grob": ["Grób Nieznanego Żołnierza",
			"Trzy łuki ocalałe z Pałacu Saskiego. Wieczny ogień i warta.",
			"Three arches left of the Saxon Palace. An eternal flame, a guard."],
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
## Walls already drawn by the current site, to cut a later coplanar wall back to what shows
## (z-fighting fix, 2026-10-31): [ax, az, bx, bz, y0, y1, nx, nz] per wall.
var _walls: Array[PackedFloat32Array] = []
## Flat tops already drawn by the current site: [height, outline] (same fix, see _cap).
var _caps: Array = []
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
	# Plac Piłsudskiego, part 2: the square's models and skins.
	if PLAC_WALLS.has(key):
		return Color(PLAC_WALLS[key])
	if MALACHOWSKI_WALLS.has(key):
		return Color(MALACHOWSKI_WALLS[key])
	if key == "kopernik":
		return KOP_WALL
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
	# Złote Tarasy (spec docs/landmarks/specs/tarasy.md, 2026-10-31): the whole complex inside
	# its outline is the landmark, built from its mapped parts. The glass wave is mapped as
	# eight glass domes over the mall; the rest is the terraced mall, Lumen and Skylight.
	var tarasy := _landmark("Złote Tarasy")
	if tarasy.size() >= 3:
		var parts := _parts_in(tarasy, func(b: Dictionary) -> bool:
				return float(b["h"]) > float(b["mh"]) and not b.get("br", false))
		var domes: Array[Dictionary] = []
		for b in parts:
			if _tarasy_dome(b):
				domes.append(b)
		_add_site("tarasy", [tarasy])
		if not sites.is_empty() and sites[-1]["key"] == "tarasy":
			sites[-1]["domes"] = domes
			sites[-1]["parts"] = parts
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
	_find_zygmunt()
	_find_arkadia()
	_find_forest()
	_find_flag()
	_find_swieto()
	# The museum and Plac Piłsudskiego loop (2026-10-31): the square's edges.
	_find_plac()
	var metropol := _landmark("Hotel Metropol")
	if metropol.size() >= 3:
		# A 0.2 m zone at the roof's south-east corner: a site's zone drops what stands in it,
		# and the hotel itself stays the map's.
		var e := _box_of([metropol]).end
		_add_site("metropolsign", [PackedVector2Array([e, e + Vector2(0.2, 0), e + Vector2(0.2, 0.2), e + Vector2(0, 0.2)])])
	# First scene item 1 (2026-10-31): the Museum of Modern Art on Plac Defilad.
	_find_msn()
	_find_tr()
	# Plac Małachowskiego and the Presidential Palace (2026-10-31): models instead of skins.
	_find_trojca()
	_find_zacheta()
	_find_prezydencki()
	# The Copernicus Science Centre and its planetarium (2026-11-01): a model instead of a skin.
	_find_kopernik()


## Warszawa Centralna (spec docs/landmarks/specs/centralna.md, 2026-10-31): OpenStreetMap maps
## the station in 3D, and the model is built from those parts: the glass hall (71 x 51 m, its
## mapped storey under it drawn as the hall's own ground floor), the lower side wings with
## their roof boxes, the entrance vestibules, the 28 pillars (two rows, 10 m apart) and the
## roof in two mapped tiers: the shell zone over the pillars (140 x 57 m, 15 to 16.5 m) and
## the flat slab over it, overhanging both long sides to 140 x 86 m (16.5 to 18 m).
const CENTRALNA := Vector2(-1420.0, 572.5)
const CENTRALNA_TURN := -19.4
func _find_centralna() -> void:
	var a := Vector2.from_angle(deg_to_rad(CENTRALNA_TURN))
	var b := Vector2(-a.y, a.x)
	var zone := PackedVector2Array()
	for q in [[-73.0, -45.5], [73.0, -45.5], [73.0, 46.5], [-73.0, 46.5]]:
		zone.append(CENTRALNA + a * float(q[0]) + b * float(q[1]))
	_add_site("centralna", [zone])
	if sites.is_empty() or sites[-1]["key"] != "centralna":
		return
	var site: Dictionary = sites[-1]
	var pillars: Array[Vector2] = []
	var hall: Array[PackedVector2Array] = []
	var wings: Array[Dictionary] = []
	var boxes: Array[Dictionary] = []
	var small: Array[PackedVector2Array] = []
	for bld in _parts_in(zone, func(b2: Dictionary) -> bool: return float(b2["h"]) > float(b2["mh"])):
		var q := _pts(bld["p"])
		var h := float(bld["h"])
		var mh := float(bld["mh"])
		var lo := q[0]
		var hi := q[0]
		for v in q:
			lo = lo.min(v)
			hi = hi.max(v)
		var area := absf(_area(q))
		if absf(h - 15.0) < 0.5 and mh < 0.5 and (hi - lo).length() < 3.0:
			pillars.append(_centre(q))
		elif mh >= 14.9:
			site["slab" if mh >= 16.4 else "shells"] = q  # the roof's two tiers
		elif mh >= 11.0:
			boxes.append(bld)  # the boxes on the wings' roofs
		elif h >= 14.5 and area > 1000.0:
			hall.append(q)
		elif h >= 11.0 and area > 300.0:
			wings.append(bld)
		elif h <= 3.5 and area < 500.0:
			small.append(q)  # the vestibules (the 87-point storey under the hall is the hall's)
	# The vestibules and pillars that stand clear of the hall and the wings (the rest are inside).
	var vest: Array[PackedVector2Array] = []
	for q in small:
		if not _in_any(_centre(q), hall, wings):
			vest.append(q)
	var free: Array[Vector2] = []
	for p in pillars:
		if not _in_any(p, hall, wings):
			free.append(p)
	site["pillars"] = free
	site["hall"] = hall
	site["wings"] = wings
	site["boxes"] = boxes
	site["vest"] = vest


func _in_any(p: Vector2, hall: Array[PackedVector2Array], wings: Array[Dictionary]) -> bool:
	for q in hall:
		if Geometry2D.is_point_in_polygon(p, q):
			return true
	for w in wings:
		if Geometry2D.is_point_in_polygon(p, _pts(w["p"])):
			return true
	return false


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

## `only` (the mesh-quality check, loop 0.1): build just the site with this key.
func build(surface, near := Rect2(), only := "") -> void:
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
		if only != "" and key != only:
			continue
		_id = k + 1
		_walls.clear()
		_caps.clear()
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
			"zygmunt":
				_build_zygmunt(s)
			"arkadia":
				_build_arkadia(s)
			"forest":
				_build_forest(s)
			"flaga":
				_build_flag(s)
			"swieto":
				_build_swieto(s)
			"muzeum":
				_build_muzeum(s)
			"europejski":
				_build_europejski(s)
			"grob":
				_build_grob(s)
			"metropolitan":
				_build_metropolitan(s)
			"wiktoria":
				_build_wiktoria(s)
			"metropolsign":
				_build_metropol_sign(s)
			"msn":
				_build_msn(s)
			"tr":
				_build_tr(s)
			"trojca":
				_build_trojca(s)
			"zacheta":
				_build_zacheta(s)
			"prezydencki":
				_build_prezydencki(s)
			"kopernik":
				_build_kopernik(s)
			"krolewska":
				pass  # a skin with no card: drawn by the builder, not on the picking grid
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
	# Cut away what an earlier wall of this site already covers in the same plane, facing the
	# same way: two coplanar faces z-fight (flicker) on the phone. Pieces are (t0, t1, y0, y1)
	# in metres along a→b and absolute height.
	var d := (b - a) / length
	var pieces: Array[Vector4] = [Vector4(0.0, length, y0, y1)]
	for w in _walls:
		if w[6] * n.x + w[7] * n.z < 0.9995:
			continue
		var wa := Vector2(w[0], w[1])
		var wb := Vector2(w[2], w[3])
		if absf((wa - a).dot(Vector2(-d.y, d.x))) > 0.03 or absf((wb - a).dot(Vector2(-d.y, d.x))) > 0.03:
			continue
		var e0 := (wa - a).dot(d)
		var e1 := (wb - a).dot(d)
		var t_lo := minf(e0, e1)
		var t_hi := maxf(e0, e1)
		var next: Array[Vector4] = []
		for pc in pieces:
			if t_hi <= pc.x + 0.01 or t_lo >= pc.y - 0.01 or w[5] <= pc.z + 0.01 or w[4] >= pc.w - 0.01:
				next.append(pc)
				continue
			if t_lo > pc.x + 0.01:
				next.append(Vector4(pc.x, t_lo, pc.z, pc.w))
			if t_hi < pc.y - 0.01:
				next.append(Vector4(t_hi, pc.y, pc.z, pc.w))
			var m0 := maxf(pc.x, t_lo)
			var m1 := minf(pc.y, t_hi)
			if w[4] > pc.z + 0.01:
				next.append(Vector4(m0, m1, pc.z, w[4]))
			if w[5] < pc.w - 0.01:
				next.append(Vector4(m0, m1, w[5], pc.w))
		pieces = next
	_walls.append(PackedFloat32Array([a.x, a.y, b.x, b.y, y0, y1, n.x, n.z]))
	for pc in pieces:
		var pa := a + d * pc.x
		var pb := a + d * pc.y
		var h0 := pc.z - _g
		var h1 := pc.w - _g
		var r0 := run + pc.x
		var r1 := run + pc.y
		_quad(Vector3(pa.x, pc.z, pa.y), Vector3(pb.x, pc.z, pb.y), Vector3(pb.x, pc.w, pb.y), Vector3(pa.x, pc.w, pa.y), n, col,
				Vector2(r0, h0), Vector2(r1, h0), Vector2(r1, h1), Vector2(r0, h1), h1)


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
	# Two flat tops at the same height that overlap z-fight: the later one keeps only what the
	# earlier ones leave bare.
	var pieces: Array[PackedVector2Array] = [poly]
	for c in _caps:
		if absf(float(c[0]) - y) > 0.03:
			continue
		var next: Array[PackedVector2Array] = []
		for pc in pieces:
			var cut := Geometry2D.clip_polygons(pc, c[1])
			for q in cut:
				if q.size() >= 3 and not Geometry2D.is_polygon_clockwise(q):
					next.append(q)
		pieces = next
	_caps.append([y, poly])
	for pc in pieces:
		# Mapped outlines that double back on themselves triangulate into overlapping
		# triangles; Clipper's union untangles them (a hole comes back clockwise: skipped).
		for q in Geometry2D.merge_polygons(pc, PackedVector2Array()):
			if q.size() >= 3 and not Geometry2D.is_polygon_clockwise(q):
				_cap_piece(q, y, col)


func _cap_piece(poly: PackedVector2Array, y: float, col: Color) -> void:
	var idx := Geometry2D.triangulate_polygon(poly)
	if idx.is_empty():
		idx = Geometry2D.triangulate_delaunay(poly)
	for i in range(0, idx.size(), 3):
		var a := poly[idx[i]]
		var b := poly[idx[i + 1]]
		var c := poly[idx[i + 2]]
		if absf((b - a).cross(c - a)) < 0.001:
			continue  # a sliver with a repeated corner: no area, nothing to draw
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
	# (Once per side: the loop above drew each of these twice, a z-fighting duplicate.)
	for sd in [-1.0, 1.0]:
		_pinnacle(sd * 19.5, 0.0, 2.0, g + 139.0, 8.0, light)
		_pinnacle(0.0, sd * 19.5, 2.0, g + 139.0, 8.0, light)
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

## Złote Tarasy (Jerde Partnership, 2007), rebuilt 2026-10-31 to its spec
## docs/landmarks/specs/tarasy.md from the complex's OpenStreetMap parts: the glass wave over
## the mall, the mall's terraced sandstone podium under it, the Lumen office crescent wrapping
## it on Złota and Jana Pawła II, the Skylight tower on Emilii Plater with its lit glass crown,
## the round glass drum on the station side. Every part keeps its mapped outline and heights;
## what the part is decides its look (TARASY_*).
const TARASY_SAND := Color("#d9c7a0")      # the podium's sandstone walls
const TARASY_SHOP := Color("#c8b27e")      # the podium's golden shop glass (S_GRID)
const TARASY_TERRACE := Color("#8a9a72")   # the planted terraces (mapped #6EBE9F)
const TARASY_DECK := Color("#a49d90")      # the podium's plain roofs
const TARASY_LUMEN := Color("#9fb0b8")     # Lumen's silver-blue glass between white ribbons
const TARASY_LUMEN_ROOF := Color("#8e9497")
const TARASY_SKY := Color("#6f9cb0")       # Skylight's blue-green curtain wall
const TARASY_SKY_ROOF := Color("#a7b3b8")
const TARASY_CROWN := Color("#b9d2dc")     # Skylight's glass crown, lit cool white at night
const TARASY_DRUM := Color("#c9b98f")      # the drum: golden glass lit warm
const TARASY_RED := Color("#c0624c")       # the red entrance boxes on Jana Pawła II (mapped tomato)
const TARASY_RIM := Color("#b9a983")       # the wave's glass walls: the terraces' shopfronts
const TARASY_WAVE := Color("#d4b066")      # the landmarks loop: golden glass (was #8fb6c6, ice)
## How far Skylight's crown leans in (fraction of the way to the centre) and how high it is.
const TARASY_CROWN_IN := 0.18
const TARASY_CROWN_H := 8.0


func _tarasy_dome(b: Dictionary) -> bool:
	return str(b["c"]).to_lower() == "#336699" and float(b["h"]) >= 20.0


func _build_tarasy(site: Dictionary) -> void:
	_g = _ground_under(site["zone"][0])
	var g := _g
	var none := Color(0, 0, 0, 0)
	var shop := M_SKIN + float(S_GRID) / 16.0
	for b: Dictionary in site.get("parts", []):
		if _tarasy_dome(b):
			continue
		var poly := _pts(b["p"])
		if poly.size() < 3:
			continue
		var h := float(b["h"])
		var mh := float(b["mh"])
		var y0 := _ground_under(poly) - 0.4 if mh < 0.5 else g + mh
		var y1 := g + h
		var nm := str(b.get("name", ""))
		var col := str(b["c"]).to_lower()
		if nm == "Lumen":
			# The office crescent: white ribbons between silver-blue glass, on the podium.
			_prism(poly, y0, y1, TARASY_LUMEN, TARASY_LUMEN_ROOF, M_SKIN + float(S_RIBBON) / 16.0, M_SKIN)
		elif nm == "Skylight":
			_prism(poly, y0, y1, TARASY_SKY, TARASY_SKY_ROOF, M_SKIN + float(S_BANDS) / 16.0, M_SKIN)
			# The crown: the curtain wall carried up past the roof and leaning in, lit at night.
			var c := _centre(poly)
			var top := PackedVector2Array()
			for q in poly:
				top.append(q + (c - q) * TARASY_CROWN_IN)
			_mode = M_PAVILION + 0.5
			_frustum(poly, y1, top, y1 + TARASY_CROWN_H, TARASY_CROWN, TARASY_SKY_ROOF)
		elif col == "#336699":
			# The glass floor under the wave's low south sweep: the wave carried down to the plaza.
			_prism(poly, y0, y1, TARASY_RIM, TARASY_WAVE, M_PAVILION, M_GLASS_ROOF)
		elif h >= 29.5 and h - mh < 1.0:
			_prism(poly, y0, y1, TARASY_SAND, TARASY_SAND.darkened(0.08), M_STONE, M_STONE)  # the drum's rim
		elif h >= 29.5 and mh < 0.5 and poly.size() >= 16:
			_prism(poly, y0, y1, TARASY_DRUM, TARASY_DECK, M_PAVILION, M_STONE)  # the drum
		elif col == "tomato":
			_prism(poly, y0, y1, TARASY_RED, TARASY_RED.darkened(0.15), M_STONE, M_STONE)
		elif col == "#6ebe9f":
			_prism(poly, y0, y1, TARASY_SAND, TARASY_TERRACE, shop, M_STONE)
		else:
			_prism(poly, y0, y1, TARASY_SAND, TARASY_DECK, shop, M_STONE)
		if mh < 0.5:
			_collide(poly)
	_tarasy_wave(site)
	_mode = M_STONE


## The glass wave: one surface over the mapped domes (each a cap rising to its mapped
## height, 35 m by the offices, 22 m towards the station), blended where they meet so
## the roof rolls instead of creasing, laid on the ground's slope, with glass walls
## round its rim where it stands clear of the ground: the terraces' shopfronts, lit warm
## floor by floor at night.
func _tarasy_wave(site: Dictionary) -> void:
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
	var glass := TARASY_WAVE
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
	_mode = M_PAVILION
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
					Vector3(n.x, 0, n.y), TARASY_RIM, Vector2(0, ga - _g), Vector2(a.distance_to(b), gb - _g),
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
	_rotunda_night(c, r, g)


## The Rondo photos (2026-10-31): the Rotunda's white zigzag crown (24 teeth, 3 m, standing on
## the roof's rim), red and blue light glowing in the glass under it (every sixth and every
## sixth-plus-three bay) and the bank's name, a parody (BANK POLSKA), lit white on the glass at
## the south and east faces.
func _rotunda_night(c: Vector2, r: float, g: float) -> void:
	var teeth := 24
	var edge := r + 2.2
	var white := Color("#ffffff")
	_mode = M_STONE
	for k in teeth:
		var a0 := TAU * k / teeth
		var a1 := TAU * (k + 1) / teeth
		var pa := c + Vector2.from_angle(a0) * edge
		var pb := c + Vector2.from_angle(a1) * edge
		var pm := c + Vector2.from_angle((a0 + a1) * 0.5) * edge
		var va := Vector3(pa.x, g + 12.2, pa.y)
		var vb := Vector3(pb.x, g + 12.2, pb.y)
		var vt := Vector3(pm.x, g + 15.2, pm.y)
		var n := (vb - va).cross(vt - va).normalized()
		if n.dot(Vector3(pm.x - c.x, 0.0, pm.y - c.y)) < 0.0:
			n = -n
		var none := Vector2(-1, -1)
		_tri(va, vb, vt, n, white, none, none, none, -1.0)
		_tri(vb, va, vt, -n, white.darkened(0.15), none, none, none, -1.0)
	for k in teeth:
		if k % 6 != 1 and k % 6 != 4:
			continue
		var a0 := TAU * k / teeth
		var a1 := TAU * (k + 1) / teeth
		var tint := Color("#3b63d8") if k % 12 < 6 else Color("#d8433a")
		var wedge := PackedVector2Array([c + Vector2.from_angle(a0) * (r - 0.4), c + Vector2.from_angle(a1) * (r - 0.4),
				c + Vector2.from_angle(a1) * (r + 0.06), c + Vector2.from_angle(a0) * (r + 0.06)])
		_prism(wedge, g + 6.0, g + 10.4, tint, Color(0, 0, 0, 0), M_LAMP)
	for d: Vector2 in [Vector2(0, 1), Vector2(1, 0)]:
		var at := c + d * (r + 0.3)
		signs.append(["BANK POLSKA", Vector3(at.x, g + 2.4, at.y), Vector3(d.x, 0.0, d.y), 0.9, Color(0.95, 0.97, 1.0)])


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
	# The dusk loop: the aviation light on the spire's very top.
	_prism(_square(spire, 0.35), g + 310.5, g + 311.2, DUSK_RED, DUSK_RED, M_LAMP, M_LAMP)


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
	var top_poly := PackedVector2Array()
	for b in parts:
		boxes.append(_box_of([_pts(b["p"])]))
		if float(b["h"]) > top_h:
			top_h = float(b["h"])
			top_poly = _pts(b["p"])
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
			if spec.get("chamfer", false) and h >= top_h - 0.5:
				_chamfered_top(poly, g + h, wall)
		if mh < 2.0:
			_collide(poly)
	_dusk_details(spec, top_poly, g, top_h)


## Novotel's cut-off top (the Rondo photos): the shaft ends in two setbacks, 1.4 m in and 2.8 m
## in, each 2.2 m tall, so the corners read chamfered from the street, in the shaft's white.
func _chamfered_top(poly: PackedVector2Array, roof_y: float, wall: Color) -> void:
	var y := roof_y
	for inset: float in [1.4, 2.8]:
		var shrunk := Geometry2D.offset_polygon(poly, -inset)
		if shrunk.is_empty():
			return
		_prism(shrunk[0], y, y + 2.2, wall, wall.darkened(0.1), M_SKIN + float(S_TILE) / 16.0, M_STONE)
		y += 2.2


## The dusk loop (2026-10-31): what lights up a tower's crown after dark. The tallest part
## `poly` (roof at g + top_h): the Marriott's bands and mast, a hotel's name, and red
## aviation lights on a roof of 100 m or more (the Spire and Złota 44 do theirs in their own
## builders).
func _dusk_details(spec: Dictionary, poly: PackedVector2Array, g: float, top_h: float) -> void:
	if poly.size() < 3:
		return
	if spec.get("marriott", false):
		_marriott(poly, g, top_h)
	if spec.has("sign"):
		_crown_signs(poly, g + top_h, str(spec["sign"]), DUSK_WARM, 3.0,
				0.75 if spec.get("marriott", false) else 0.7)
	if spec.has("base_sign"):
		# A shop's name over the ground floor on the south and east faces (Rondo 1's clinic).
		_crown_signs(poly, g + 5.2, str(spec["base_sign"]), Color(0.75, 1.0, 0.95), 0.0, 0.3)
	if spec.has("vsign"):
		_crown_signs(poly, g + top_h, str(spec["vsign"]), VSIGN_BLUE, 5.0, 0.5, true)
		_vsign_tail(poly, g + top_h - 5.0 - 7.04 * str(spec["vsign"]).length())
	if top_h >= 100.0 and spec["key"] != "zlota44" and spec["key"] != "spire":
		var roof_y := func(_q: Vector2) -> float: return g + top_h
		if spec.get("crest", "") == "slope":
			roof_y = _slope_roof(poly, g + top_h, g + top_h - 24.0)
		_aviation(poly, roof_y)


const DUSK_WARM := Color(1.0, 0.95, 0.86)
const DUSK_RED := Color(1.0, 0.12, 0.1)
## NOWOTEL's name: blue neon, letter over letter down the shaft (the Rondo photos).
const VSIGN_BLUE := Color(0.18, 0.42, 1.0)


## The Nowotel's tail under its stacked name (the Rondo night photos): an orange rule, the
## chain's parody line (ACORN over HOTELS) in the same blue, on the faces the name is on.
func _vsign_tail(poly: PackedVector2Array, y: float) -> void:
	_crown_signs(poly, y - 1.0, "--", Color(1.0, 0.5, 0.15), 0.0, 0.3)
	_crown_signs(poly, y - 3.5, "ACORN", VSIGN_BLUE, 0.0, 0.3)
	_crown_signs(poly, y - 6.5, "HOTELS", VSIGN_BLUE, 0.0, 0.26)


## The Marriott (the dusk loop): a dark band round the crown (top 7 m) and one two thirds up
## (4 m), each 0.15 m proud of the glass, a lattice mast on the roof (shaft, platform, a red
## lamp on top) and the brand's parody (SAMSONG) lit on the mid band, on the south and east
## faces. The name on the crown goes up with the `sign` key (_dusk_details).
func _marriott(poly: PackedVector2Array, g: float, h: float) -> void:
	var band := Color("#14191c")
	var mode := M_SKIN + float(S_DARK) / 16.0
	var wide := Geometry2D.offset_polygon(poly, 0.15)
	if wide.is_empty():
		return
	var out: PackedVector2Array = wide[0]
	var mid := g + 0.62 * h
	_prism(out, g + h - 7.0, g + h, band, Color(0, 0, 0, 0), mode)
	_prism(out, mid - 2.0, mid + 2.0, band, Color(0, 0, 0, 0), mode)
	var c := _centre(poly)
	var roof := g + h
	var steel := Color("#b8b2a8")
	_prism(_square(c, 1.2), roof, roof + 26.0, steel, steel.lightened(0.1), M_STONE, M_STONE)
	_prism(_square(c, 3.0), roof + 14.0, roof + 14.6, steel.darkened(0.15), steel, M_STONE, M_STONE)
	_prism(_square(c, 0.4), roof + 26.0, roof + 26.8, DUSK_RED, DUSK_RED, M_LAMP, M_LAMP)
	_crown_signs(poly, mid, "SAMSONG", DUSK_WARM, 0.0, 0.75)


## An axis-aligned square round `c`, half-width `r`.
func _square(c: Vector2, r: float) -> PackedVector2Array:
	return PackedVector2Array([c + Vector2(-r, -r), c + Vector2(r, -r), c + Vector2(r, r), c + Vector2(-r, r)])


## The dusk loop: a lit name on the two faces of `poly` that face the camera most, south and
## east, centred `drop` m under `top_y`, the word spanning `share` of the face's width. Only
## the long faces count (at least half the longest edge), so a corner chamfer never carries one.
func _crown_signs(poly: PackedVector2Array, top_y: float, word: String, colour: Color, drop := 3.0, share := 0.7,
		vertical := false) -> void:
	var longest := 0.0
	for i in poly.size():
		longest = maxf(longest, poly[i].distance_to(poly[(i + 1) % poly.size()]))
	var picked: Array[int] = []
	for d: Vector2 in [Vector2(0, 1), Vector2(1, 0)]:
		var best := -1
		var best_dot := 0.3
		for i in poly.size():
			var a := poly[i]
			var b := poly[(i + 1) % poly.size()]
			if a.distance_to(b) < longest * 0.5:
				continue
			var dot := _out(poly, a, b).dot(d)
			if dot > best_dot:
				best_dot = dot
				best = i
		if best >= 0 and not picked.has(best):
			picked.append(best)
	for i in picked:
		var a := poly[i]
		var b := poly[(i + 1) % poly.size()]
		var o := _out(poly, a, b)
		var mid := (a + b) * 0.5
		if vertical:
			# One letter per sign, stacked: each 1.8 m glyph box grown by k, `drop` under the top.
			var kv := 3.2
			var step := Neon.ROW_H * Neon.PIXEL * kv
			for n in word.length():
				var top := top_y - drop - step * n
				signs.append([word[n], Vector3(mid.x, top - step, mid.y), Vector3(o.x, 0.0, o.y), kv, colour])
			continue
		var k := share * a.distance_to(b) / Neon.length_of(word)
		var base_y := top_y - drop - Neon.ROW_H * Neon.PIXEL * k * 0.5
		signs.append([word, Vector3(mid.x, base_y, mid.y), Vector3(o.x, 0.0, o.y), k, colour])


## The dusk loop: red aviation lights, 0.7 m lamp boxes, on a roof's outline at the south-west,
## south-east and north-east corners of its bounding box (each clamped into the outline, then
## drawn in a little); three, to keep to 30 triangles. `roof_y` gives the roof's height at a point.
func _aviation(poly: PackedVector2Array, roof_y: Callable) -> void:
	var lo := poly[0]
	var hi := poly[0]
	for q in poly:
		lo = lo.min(q)
		hi = hi.max(q)
	var c := _centre(poly)
	for corner: Vector2 in [Vector2(lo.x, hi.y), hi, Vector2(hi.x, lo.y)]:
		var p := corner
		if not Geometry2D.is_point_in_polygon(p, poly):
			var near := p
			var best := INF
			for i in poly.size():
				var q := Geometry2D.get_closest_point_to_segment(p, poly[i], poly[(i + 1) % poly.size()])
				if q.distance_to(p) < best:
					best = q.distance_to(p)
					near = q
			p = near
		p += (c - p).normalized() * minf(0.8, p.distance_to(c))
		var y: float = roof_y.call(p)
		_prism(_square(p, 0.35), y, y + 0.7, DUSK_RED, DUSK_RED, M_LAMP, M_LAMP)


## The roof height of a part cut on a slope (_sloped): `hi` at the north end of its longest
## axis, `lo` at the other.
func _slope_roof(poly: PackedVector2Array, hi: float, lo: float) -> Callable:
	var c := _centre(poly)
	var axis := Vector2.ZERO
	var reach := 0.0
	for q in poly:
		if (q - c).length() > reach:
			reach = (q - c).length()
			axis = (q - c).normalized()
	if axis.y > 0.0:
		axis = -axis
	var lo_d := INF
	var hi_d := -INF
	for q in poly:
		lo_d = minf(lo_d, (q - c).dot(axis))
		hi_d = maxf(hi_d, (q - c).dot(axis))
	return func(q: Vector2) -> float: return lerpf(lo, hi, inverse_lerp(lo_d, hi_d, (q - c).dot(axis)))


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
	_aviation(crown, func(q: Vector2) -> float: return top.call(q))


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
	_aviation(top, func(_q: Vector2) -> float: return g + 196.0)  # on the frame's rim (the dusk loop)
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
		# The rectangle up to the lower end goes through _wall (so a podium wall flush with it
		# is cut back, not drawn over it); the wedge above it is a triangle.
		var lowest := minf(ta, tb)
		_wall(a, b, y0, lowest, o, wall, run)
		if absf(ta - tb) > 0.01:
			var a_high := ta > tb
			var p_hi := (a if a_high else b)
			var p_lo := (b if a_high else a)
			var t_hi := maxf(ta, tb)
			var r_hi := run if a_high else run + length
			var r_lo := run + length if a_high else run
			_tri(Vector3(p_lo.x, lowest, p_lo.y), Vector3(p_hi.x, lowest, p_hi.y), Vector3(p_hi.x, t_hi, p_hi.y), n, wall,
					Vector2(r_lo, lowest - _g), Vector2(r_hi, lowest - _g), Vector2(r_hi, t_hi - _g), t_hi - _g)
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
	{"key": "buw", "osm": "Biblioteka Uniwersytecka", "mode": M_STONE, "wall": "#7f9e8a", "roof": "#6a9a52"},
	{"key": "zamek", "osm": "Zamek Królewski", "mode": M_MONUMENT, "wall": "#c87560", "roof": "#6e5a4e"},
	{"key": "barbakan", "osm": "Barbakan", "mode": M_GOTHIC, "wall": "#ab5a42", "roof": "#6b4a3c"},
	{"key": "archikatedra", "osm": "Archikatedra pw. Świętego Jana Chrzciciela", "mode": M_GOTHIC, "wall": "#9a4b38", "roof": "#6e3a2e"},
	{"key": "sw_anna", "osm": "Kościół pw. Świętej Anny", "mode": M_MONUMENT, "wall": "#e6dcc4", "roof": "#8a5a44"},
	{"key": "sw_krzyz", "osm": "Kościół pw. Świętego Krzyża", "mode": M_MONUMENT, "wall": "#e3d9c0", "roof": "#5d6e64"},
	{"key": "staszic", "osm": "Pałac Staszica", "mode": M_MONUMENT, "wall": "#e2d6b8", "roof": "#5f6f6a"},
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


# --- Muzeum Narodowe (the landmarks loop; a real model since the museum and Plac loop) ----------

## The museum's building (1927-1938) at the east end of Al. Jerozolimskie, mapped as one
## outline round the courtyards (with the army museum in its wings). The landmarks loop kept the
## LoD2 or OpenStreetMap model in its stone (`skin_at`); the museum and Plac Piłsudskiego loop
## (2026-10-31) builds it (`_build_muzeum`): the outline straightened (`_simplify`), and its
## courtyards (the hull's pieces outside it, over MUZEUM_COURT m²) join the zone, since the LoD2
## model's centre falls in one.
const MUZEUM := Vector2(24.0, 251.0)  # inside its wings (its outline's centre is a courtyard)
const MUZEUM_STONE := Color("#c9bfa9")
const MUZEUM_ROOF := Color("#8f8b84")
const MUZEUM_COURT := 1000.0
func _find_muzeum() -> void:
	for bld in data["buildings"]:
		var q := _pts(bld["p"])
		if q.size() < 20 or float(bld["h"]) < 10.0 or not _box_of([q]).has_point(MUZEUM):
			continue
		if Geometry2D.is_point_in_polygon(MUZEUM, q):
			var ring := _simplify(q, 1.0)
			var zone: Array = [q]
			var courts: Array[PackedVector2Array] = []
			for piece in Geometry2D.clip_polygons(Geometry2D.convex_hull(ring), ring):
				if absf(_area(piece)) > MUZEUM_COURT:
					courts.append(piece)
					zone.append(piece)
			_add_site("muzeum", zone)
			if not sites.is_empty() and sites[-1]["key"] == "muzeum":
				sites[-1]["ring"] = ring
				sites[-1]["h"] = maxf(float(bld["h"]), MUZEUM_WINGS)
				sites[-1]["courts"] = courts
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


# --- Kolumna Zygmunta (the landmarks loop, Old Town) ---------------------------------------------

## Sigismund's Column on Plac Zamkowy (1644, rebuilt 1949): OpenStreetMap maps it in a dozen
## tiny 3D parts the builder drops as specks, so the square had a dark cube. Built here: the
## stepped granite base, the pedestal, the 12 m shaft, the capital and the king in bronze with
## his cross raised and his sabre. A circle zone round it; the same on both city paths.
const ZYGMUNT := Vector2(-724.2, -1465.4)
const ZYGMUNT_GRANITE := Color("#8d8a86")
const ZYGMUNT_STONE := Color("#d2c4ad")
const ZYGMUNT_BRONZE := Color("#4f4a40")
func _find_zygmunt() -> void:
	_add_site("zygmunt", [_circle(ZYGMUNT, 4.0, 16)])


## A ring of `n` points round `c`.
func _circle(c: Vector2, r: float, n: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	for k in n:
		out.append(c + Vector2.from_angle(TAU * (k + 0.5) / n) * r)
	return out


func _build_zygmunt(_site: Dictionary) -> void:
	var c := ZYGMUNT
	_g = _ground_under(_circle(c, 3.4, 8))
	var g := _g
	var none := Color(0, 0, 0, 0)
	# Three octagonal steps, the pedestal (a dark plinth, pale stone, a cornice).
	for k in 3:
		_prism(_circle(c, 3.4 - k * 0.4, 8), g - 0.4 + k * 0.4, g + 0.4 + k * 0.4, ZYGMUNT_GRANITE, ZYGMUNT_GRANITE, M_STONE, M_STONE)
	_prism(_circle(c, 1.75, 4), g + 1.2, g + 2.5, ZYGMUNT_GRANITE, none, M_STONE)
	_prism(_circle(c, 1.4, 4), g + 2.5, g + 4.8, ZYGMUNT_STONE, none, M_STONE)
	_prism(_circle(c, 1.6, 4), g + 4.8, g + 5.2, ZYGMUNT_GRANITE, ZYGMUNT_GRANITE, M_STONE, M_STONE)
	# The shaft, tapering a little, then the capital and the block the king stands on.
	_mode = M_STONE
	_frustum(_circle(c, 0.5, 16), g + 5.2, _circle(c, 0.4, 16), g + 17.4, ZYGMUNT_STONE)
	_prism(_circle(c, 0.75, 4), g + 17.4, g + 18.0, ZYGMUNT_BRONZE, none, M_STONE)
	_prism(_circle(c, 0.95, 4), g + 18.0, g + 18.6, ZYGMUNT_STONE, ZYGMUNT_STONE, M_STONE, M_STONE)
	# The king (facing south, down Krakowskie Przedmieście): robe, body, head; the cross held
	# high in his left hand, the sabre in his right.
	_prism(_circle(c, 0.42, 8), g + 18.6, g + 19.9, ZYGMUNT_BRONZE, none, M_STONE)
	_prism(_circle(c, 0.3, 8), g + 19.9, g + 20.9, ZYGMUNT_BRONZE, ZYGMUNT_BRONZE, M_STONE, M_STONE)
	_prism(_circle(c, 0.16, 6), g + 20.9, g + 21.3, ZYGMUNT_BRONZE, ZYGMUNT_BRONZE, M_STONE, M_STONE)
	var hand := c + Vector2(0.38, 0.05)
	_prism(_circle(hand, 0.07, 4), g + 20.2, g + 22.9, ZYGMUNT_BRONZE, ZYGMUNT_BRONZE, M_STONE, M_STONE)
	var bar := PackedVector2Array([hand + Vector2(-0.36, -0.05), hand + Vector2(0.36, -0.05), hand + Vector2(0.36, 0.05), hand + Vector2(-0.36, 0.05)])
	_prism(bar, g + 22.25, g + 22.39, ZYGMUNT_BRONZE, ZYGMUNT_BRONZE, M_STONE, M_STONE)
	var sabre := PackedVector2Array([c + Vector2(-0.34, 0.1), c + Vector2(-0.3, 0.1), c + Vector2(-0.3, 0.95), c + Vector2(-0.34, 0.95)])
	_prism(sabre, g + 19.55, g + 19.65, ZYGMUNT_BRONZE, ZYGMUNT_BRONZE, M_STONE, M_STONE)
	_collide(_circle(c, 3.4, 8))

# --- Map north: Arkadia, the Forest tower, Rondo Radosława's flag (the landmarks loop) -----------

## Arkadia (2004), the city's biggest mall, by Rondo Radosława (docs/DEMO.md 2.1 "Hand-over"):
## its OpenStreetMap outline lifted as one block, a glass storey lit from inside under pale
## panels to 21 m, the grey roof deck of its car park, and the 37 m tower over the west
## entrance with the parody of its name, ARKADKA, on both faces. One card.
const ARKADIA_TOWER := Vector2(-2778.0, -2470.0)
const ARKADIA_TOP := 21.0
const ARKADIA_WALL := Color("#dcd9d2")
const ARKADIA_ROOF := Color("#77797a")
const ARKADIA_RED := Color(1.0, 0.18, 0.22)
func _find_arkadia() -> void:
	var outline := _landmark("Westfield Arkadia")
	if outline.size() >= 3:
		_add_site("arkadia", [outline])


func _build_arkadia(site: Dictionary) -> void:
	var poly: PackedVector2Array = site["zone"][0]
	_g = _ground_under(poly)
	var g := _g
	var none := Color(0, 0, 0, 0)
	_prism(poly, g - 0.5, g + 5.0, Color("#a9c6d2"), none, M_PAVILION)
	_prism(poly, g + 5.0, g + ARKADIA_TOP - 1.0, ARKADIA_WALL, none, M_STONE)
	_prism(poly, g + ARKADIA_TOP - 1.0, g + ARKADIA_TOP, Color("#9ea2a4"), ARKADIA_ROOF, M_STONE, M_STONE)
	# The malls' glass roofs: three long skylights along the block's long axis over the deck.
	var c := _centre(poly)
	var sxx := 0.0
	var szz := 0.0
	var sxz := 0.0
	for q in poly:
		sxx += (q.x - c.x) * (q.x - c.x)
		szz += (q.y - c.y) * (q.y - c.y)
		sxz += (q.x - c.x) * (q.y - c.y)
	var axis := Vector2.from_angle(0.5 * atan2(2.0 * sxz, sxx - szz))
	var across := Vector2(-axis.y, axis.x)
	for k: int in [-1, 0, 1]:
		var m := c + across * (k * 70.0)
		var strip := PackedVector2Array([m - axis * 200.0 - across * 5.0, m + axis * 200.0 - across * 5.0,
				m + axis * 200.0 + across * 5.0, m - axis * 200.0 + across * 5.0])
		for piece: PackedVector2Array in Geometry2D.intersect_polygons(strip, poly):
			var inner := PackedVector2Array()
			var pc := _centre(piece)
			for q in piece:
				inner.append(q + (pc - q).normalized() * 6.0)  # off the deck's edge
			_prism(inner, g + ARKADIA_TOP, g + ARKADIA_TOP + 1.6, Color("#9fc0cf"), Color("#8fb3c4"), M_PAVILION, M_GLASS_ROOF)
	# The entrance tower: glass below, a white box above with the sign; a little proud of the block.
	var t := _circle(ARKADIA_TOWER, 9.9, 4)
	_prism(t, g + ARKADIA_TOP, g + 30.0, Color("#9fc0cf"), none, M_PAVILION)
	_prism(t, g + 30.0, g + 37.0, Color("#f1efe9"), Color("#d8d6d0"), M_STONE, M_STONE)
	for d: Vector2 in [Vector2(0.0, 1.0), Vector2(0.0, -1.0)]:
		var at := ARKADIA_TOWER + d * 7.0
		signs.append(["ARKADKA", Vector3(at.x, g + 31.4, at.y), Vector3(d.x, 0.0, d.y), 1.15, ARKADIA_RED])
	_collide(poly)


## The Forest (2023): an office block of stepped wings whose roofs are planted terraces, and
## its 120 m glass tower. Built from its mapped parts (bake_sectors.py SITE_AREAS has the box):
## the tallest is the tower, in dark green glass with fins; the rest in paler glass bands,
## each roof a garden.
const FOREST_BOX := Rect2(-3105.0, -2455.0, 185.0, 120.0)
const FOREST_GLASS := Color("#5f7d74")
const FOREST_LOW := Color("#8fa9a0")
const FOREST_GREEN := Color("#5d8f45")
func _find_forest() -> void:
	var zone: Array = []
	var parts: Array = []
	for bld in data["buildings"]:
		var q := _pts(bld["p"])
		if q.size() >= 3 and FOREST_BOX.has_point(_centre(q)) and float(bld["h"]) >= 25.0:
			zone.append(q)
			parts.append(bld)
	_add_site("forest", zone)
	if not sites.is_empty() and sites[-1]["key"] == "forest":
		sites[-1]["parts"] = parts


func _build_forest(site: Dictionary) -> void:
	var parts: Array = site["parts"]
	var tallest := 0.0
	for bld in parts:
		tallest = maxf(tallest, float(bld["h"]))
	_g = INF
	for bld in parts:
		_g = minf(_g, _ground_under(_pts(bld["p"])))
	var g := _g
	for bld in parts:
		var poly := _pts(bld["p"])
		var h := float(bld["h"])
		var mh := float(bld["mh"])
		if h >= tallest - 0.5:
			_prism(poly, g + mh, g + h, FOREST_GLASS, Color("#4f5a58"), M_SKIN + S_FINS / 16.0, M_STONE)
			# A dark crown band.
			_prism(poly, g + h, g + h + 1.2, Color("#3d4645"), Color(0, 0, 0, 0), M_STONE)
		else:
			_prism(poly, g + mh, g + h, FOREST_LOW, FOREST_GREEN, M_SKIN + S_BANDS / 16.0, M_STONE)
			# The planted edge: a hedge round each terrace.
			var c := _centre(poly)
			var hedge := PackedVector2Array()
			for q in poly:
				hedge.append(q + (c - q).normalized() * 0.6)
			_prism(hedge, g + h, g + h + 0.9, FOREST_GREEN.darkened(0.15), FOREST_GREEN.lightened(0.08), M_STONE, M_STONE)
		_collide(poly)


## Rondo Radosława's flag (not in OpenStreetMap; the surface model's 57.8 m column in the
## island's west part): a steel mast and a big white-and-red flag in a light wind.
const FLAG_MAST := Vector2(-2850.0, -2295.0)
const FLAG_HEIGHT := 57.8
const FLAG_W := 16.0
const FLAG_H := 10.0
func _find_flag() -> void:
	_add_site("flaga", [_circle(FLAG_MAST, 2.5, 8)])


func _build_flag(_site: Dictionary) -> void:
	var c := FLAG_MAST
	_g = _ground_under(_circle(c, 1.5, 6))
	var g := _g
	var steel := Color("#c9cdd0")
	_prism(_circle(c, 1.6, 8), g - 0.3, g + 0.6, Color("#8d8a86"), Color("#8d8a86"), M_STONE, M_STONE)
	_mode = M_STONE
	_frustum(_circle(c, 0.42, 10), g + 0.6, _circle(c, 0.2, 10), g + FLAG_HEIGHT, steel, steel)
	_prism(_circle(c, 0.32, 8), g + FLAG_HEIGHT, g + FLAG_HEIGHT + 0.5, Color("#d9b24a"), Color("#d9b24a"), M_STONE, M_STONE)
	# The flag flies east from the mast in folds: strips across, each turned a little.
	var top := g + FLAG_HEIGHT - 0.6
	var strips := 8
	for k in strips:
		var x0 := 0.25 + FLAG_W * k / strips
		var x1 := 0.25 + FLAG_W * (k + 1) / strips
		var z0 := sin(k * 1.1) * 0.9 * k / strips
		var z1 := sin((k + 1) * 1.1) * 0.9 * (k + 1) / strips
		var a := Vector2(c.x + x0, c.y + z0)
		var b := Vector2(c.x + x1, c.y + z1)
		var droop0 := 0.35 * k / strips
		var droop1 := 0.35 * (k + 1) / strips
		var n := Vector3(-(b - a).y, 0.0, (b - a).x).normalized()
		for side: Vector3 in [n, -n]:
			_quad(Vector3(a.x, top - FLAG_H * 0.5 - droop0, a.y), Vector3(b.x, top - FLAG_H * 0.5 - droop1, b.y),
					Vector3(b.x, top - droop1, b.y), Vector3(a.x, top - droop0, a.y), side, Color("#f4f4f2"))
			_quad(Vector3(a.x, top - FLAG_H - droop0, a.y), Vector3(b.x, top - FLAG_H - droop1, b.y),
					Vector3(b.x, top - FLAG_H * 0.5 - droop1, b.y), Vector3(a.x, top - FLAG_H * 0.5 - droop0, a.y), side, Color("#d4213d"))
	_collide(_circle(c, 1.6, 8))

# --- Most Świętokrzyski (the landmarks loop, the user's ask 2026-10-31) --------------------------

## The cable-stayed bridge (2000): one concrete pylon on the Praga bank, in the 2.6 m median
## between the carriageways, leaning back east, and its stays in one plane along the median: a
## fan of 12 over the main span west across the river and 9 back to the east. The decks are
## map_builder's; the deck's height along the axis is its profile from the bake (a parabola
## through its crown, within about a metre). The site is the median strip under the stays, so
## every sector they cross builds them.
const SWIETO_PYLON := Vector2(737.5, -898.4)
const SWIETO_WEST := Vector2(-0.8142, 0.5806)  # along the deck, towards the Old Town bank
const SWIETO_TOP := 70.0                       # the pylon's top (map y)
const SWIETO_LEAN := 7.0                       # its top stands this far back east
const SWIETO_GREY := Color("#cfcdc6")
const SWIETO_STAY := Color("#eef0f0")
func _find_swieto() -> void:
	var across := Vector2(-SWIETO_WEST.y, SWIETO_WEST.x)
	var a := SWIETO_PYLON - SWIETO_WEST * 120.0
	var b := SWIETO_PYLON + SWIETO_WEST * 175.0
	_add_site("swieto", [PackedVector2Array([a - across * 1.2, b - across * 1.2, b + across * 1.2, a + across * 1.2])])


## The deck's top on the median at `s` metres west of the pylon.
func _swieto_deck(s: float) -> float:
	return -7.89 - 0.00007 * (s - 72.0) * (s - 72.0)


func _build_swieto(_site: Dictionary) -> void:
	var w := SWIETO_WEST
	var across := Vector2(-w.y, w.x)
	var deck := _swieto_deck(0.0)
	_g = _ground_under(_circle(SWIETO_PYLON, 2.0, 6))
	# The pylon: a tapering shaft from the ground through the deck to its top, leaning east.
	var ring := func(at: Vector2, half_along: float, half_across: float) -> PackedVector2Array:
		return PackedVector2Array([at - w * half_along - across * half_across, at + w * half_along - across * half_across,
				at + w * half_along + across * half_across, at - w * half_along + across * half_across])
	var foot: PackedVector2Array = ring.call(SWIETO_PYLON, 3.6, 1.15)
	_prism(foot, _g - 1.0, deck, SWIETO_GREY, Color(0, 0, 0, 0), M_STONE)
	var top_at := SWIETO_PYLON - w * SWIETO_LEAN
	_mode = M_STONE
	_frustum(foot, deck, ring.call(top_at, 2.0, 0.85), SWIETO_TOP, SWIETO_GREY, SWIETO_GREY.darkened(0.1))
	# The aviation light on its top, red at night.
	_prism(_circle(top_at, 0.35, 6), SWIETO_TOP, SWIETO_TOP + 0.6, Color(1.0, 0.15, 0.1), Color(1.0, 0.15, 0.1), M_LAMP, M_LAMP)
	# Solid from the ground to the top for the car under the deck, on it and the helicopter: one
	# column round the foot and the leaning top together.
	_collide_span(ring.call(SWIETO_PYLON.lerp(top_at, 0.5), 3.6 + SWIETO_LEAN * 0.5, 1.15), _g - 1.0, SWIETO_TOP)
	# The stays: anchored up the pylon's top 30 m, landing along the median.
	var shaft := func(y: float) -> Vector3:
		var t := (y - deck) / (SWIETO_TOP - deck)
		var p := SWIETO_PYLON.lerp(top_at, t)
		return Vector3(p.x, y, p.y)
	for k in 12:
		var s := 30.0 + k * 11.5
		var land := SWIETO_PYLON + w * s
		# Each stay sits a few cm to the side of the others (z-fighting fix: stays in one plane
		# share their side faces where they cross near the top).
		var off := Vector3(across.x, 0.0, across.y) * (((k * 5) % 13 - 6) * 0.035)
		_beam(shaft.call(SWIETO_TOP - 3.0 - k * 2.3) + off, Vector3(land.x, _swieto_deck(s) + 1.0, land.y) + off, 0.22, SWIETO_STAY, false)
	for k in 9:
		var s := -(22.0 + k * 10.5)
		var land := SWIETO_PYLON + w * s
		var off := Vector3(across.x, 0.0, across.y) * (((k * 5 + 4) % 13 - 6) * 0.035)
		_beam(shaft.call(SWIETO_TOP - 4.0 - k * 2.6) + off, Vector3(land.x, _swieto_deck(s) + 1.0, land.y) + off, 0.26, SWIETO_STAY, false)

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

## The bowl in the old stadium's embankment (spec docs/landmarks/specs/stadium.md): a woven
## skin leaning out like a basket from the embankment's crest to the roof's edge, red below
## and white above like the flag, 72 masts leaning with it and spiking above the roof, a
## raised white rim and a membrane roof ringing the open middle, two tiers of red seats round
## a striped pitch, and the needle with the folded roof hanging over the centre on its cables.
## The outline at every angle comes from the mapped masts; heights from the mapped parts
## (roof rim 44-46.2 m, mast tips 60 m, upper tier 19-38.5 m, hub 37-43 m, folded roof
## 55-63 m, needle 30-100 m, over the street round it).
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
	var rim_y := street + 46.2
	var skin_top := street + 41.0
	# The pitch's long axis: the masts' principal axis (the outline is an oval round it).
	var sxx := 0.0
	var sxy := 0.0
	var syy := 0.0
	for v in inner:
		var dd := (v as Vector2) - c
		sxx += dd.x * dd.x
		sxy += dd.x * dd.y
		syy += dd.y * dd.y
	var axis := Vector2.from_angle(0.5 * atan2(2.0 * sxy, sxx - syy))
	var across := Vector2(-axis.y, axis.x)
	var dirs: Array[Vector2] = []
	for v in inner:
		dirs.append(((v as Vector2) - c).normalized())
	# A rounded rectangle round the pitch (half-sizes along and across the axis), sampled at
	# the masts' angles so every ring of the bowl meets the next one quad by quad.
	var oblong := func(half_a: float, half_b: float, power: float) -> PackedVector2Array:
		var ring := PackedVector2Array()
		for d: Vector2 in dirs:
			var x := absf(d.dot(axis)) / half_a
			var y := absf(d.dot(across)) / half_b
			ring.append(c + d * pow(pow(x, power) + pow(y, power), -1.0 / power))
		return ring
	var scaled := func(s: float) -> PackedVector2Array:
		var ring := PackedVector2Array()
		for v in inner:
			ring.append(c + ((v as Vector2) - c) * s)
		return ring
	# Rings at every mast angle.
	var base := PackedVector2Array()   # the skin's foot, on the crest
	var mid := PackedVector2Array()    # the basket's belly
	var top := PackedVector2Array()    # the skin's top, under the roof edge
	var edge := PackedVector2Array()   # the roof's outer edge
	var inset := PackedVector2Array()  # the rim's inner foot, where the membrane starts
	var foot := PackedFloat32Array()
	for k in n:
		var vi: Vector2 = inner[k]
		var vo: Vector2 = outer[k]
		var d := vi - c
		base.append(c + d * 0.965)
		mid.append(vi + (vo - vi) * 0.25)
		top.append(vi + (vo - vi) * 0.62)
		edge.append(vo + (vo - c).normalized() * 1.5)
		inset.append(vo - (vo - c).normalized() * 1.5)
		foot.append(map.terrain_height(vi.x, vi.y) - 1.0)
	var hole: PackedVector2Array = oblong.call(70.0, 54.0, 4.0)
	# The concourse: a dark glass curtain wall set back behind the masts' feet, from the
	# crest to 7.5 m (the Mac photo check, 2026-11-01); the skin starts over it.
	_mode = M_GLASS
	var glass := PackedVector2Array()
	for k in n:
		glass.append(c + ((inner[k] as Vector2) - c) * 0.935)
	var grun := 0.0
	for k in n:
		var k1 := (k + 1) % n
		var gl := glass[k].distance_to(glass[k1])
		var go := (glass[k] + glass[k1]) * 0.5 - c
		var y0 := minf(foot[k], foot[k1]) - 0.5
		var y1 := maxf(foot[k], foot[k1]) + 7.5
		_quad(Vector3(glass[k].x, y0, glass[k].y), Vector3(glass[k1].x, y0, glass[k1].y),
				Vector3(glass[k1].x, y1, glass[k1].y), Vector3(glass[k].x, y1, glass[k].y),
				Vector3(go.x, 0.0, go.y).normalized(), Color("#2b3440"),
				Vector2(grun, y0 - street), Vector2(grun + gl, y0 - street), Vector2(grun + gl, y1 - street),
				Vector2(grun, y1 - street), y1 - street)
		grun += gl
	for k in n:
		foot[k] += 7.0
	# The skin: two bands, its panels continuous all the way round (the shader turns them
	# from red to silver with the height).
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
	# The roof: the raised rim (its outer face over the skin, its inner face sloping to the
	# membrane), its soffit back to the skin's top, then the membrane down to the open middle
	# in panels.
	for k in n:
		var k1 := (k + 1) % n
		var o := (edge[k] + edge[k1]) * 0.5 - c
		var on := Vector3(o.x, 0, o.y).normalized()
		_quad(Vector3(edge[k].x, roof_y - 1.6, edge[k].y), Vector3(edge[k1].x, roof_y - 1.6, edge[k1].y),
				Vector3(edge[k1].x, rim_y, edge[k1].y), Vector3(edge[k].x, rim_y, edge[k].y), on, Color("#dcdee2"))
		_quad(Vector3(edge[k].x, rim_y, edge[k].y), Vector3(edge[k1].x, rim_y, edge[k1].y),
				Vector3(inset[k1].x, roof_y, inset[k1].y), Vector3(inset[k].x, roof_y, inset[k].y),
				(Vector3.UP * 1.5 - on * 2.2).normalized(), Color("#c9ccd1"))
		_quad(Vector3(edge[k].x, roof_y - 1.6, edge[k].y), Vector3(edge[k1].x, roof_y - 1.6, edge[k1].y),
				Vector3(top[k1].x, skin_top, top[k1].y), Vector3(top[k].x, skin_top, top[k].y), Vector3.DOWN, Color("#9da1a8"))
	_mode = M_MEMBRANE
	var hole_y := roof_y - 3.5
	for k in n:
		var k1 := (k + 1) % n
		var p0 := Vector3(inset[k].x, roof_y, inset[k].y)
		var p1 := Vector3(inset[k1].x, roof_y, inset[k1].y)
		var p2 := Vector3(hole[k1].x, hole_y, hole[k1].y)
		var p3 := Vector3(hole[k].x, hole_y, hole[k].y)
		# The last 7 m before the opening are grey-blue polycarbonate (the Mac photo check).
		var g0 := p3 + (p0 - p3) * (7.0 / p0.distance_to(p3))
		var g1 := p2 + (p1 - p2) * (7.0 / p1.distance_to(p2))
		var nr := (p1 - p0).cross(p3 - p0).normalized()
		if nr.y < 0.0:
			nr = -nr
		_quad(p0, p1, g1, g0, nr, Color("#f4f4f1") if k % 2 == 0 else Color("#eaebe8"))
		_quad(g0, g1, p2, p3, nr, Color("#8f9aa3") if k % 2 == 0 else Color("#98a2aa"))
	# The bowl, from the pitch out: advertising boards, the lower tier of red seats, a grey
	# gangway, the dark glass of the boxes, then the upper tier up under the roof. Every
	# sixth wedge is a lighter aisle.
	_mode = M_STONE
	var seat := Color("#c42a31")
	var bowl := [
		[oblong.call(61.0, 42.0, 8.0), pitch + 0.4, Color("#2d3138")],
		[oblong.call(61.0, 42.0, 8.0), pitch + 1.4, seat],
		[oblong.call(78.0, 59.0, 6.0), pitch + 13.0, Color("#8e8a88")],
		[oblong.call(81.0, 62.0, 6.0), pitch + 13.0, Color("#3d4652")],
		[oblong.call(81.0, 62.0, 6.0), pitch + 19.0, seat],
		[scaled.call(0.86), street + 38.5, Color()]]
	for t in range(1, bowl.size()):
		var r0: PackedVector2Array = bowl[t - 1][0]
		var y0: float = bowl[t - 1][1]
		var col: Color = bowl[t - 1][2]
		var r1: PackedVector2Array = bowl[t][0]
		var y1: float = bowl[t][1]
		for k in n:
			var k1 := (k + 1) % n
			var p0 := Vector3(r0[k].x, y0, r0[k].y)
			var p1 := Vector3(r0[k1].x, y0, r0[k1].y)
			var p2 := Vector3(r1[k1].x, y1, r1[k1].y)
			var p3 := Vector3(r1[k].x, y1, r1[k].y)
			var nr := (p1 - p0).cross(p3 - p0).normalized()
			if absf(nr.y) < 0.2:
				# A wall (the boards, the boxes): faces the pitch.
				var mid2 := (r0[k] + r0[k1]) * 0.5 - c
				if Vector2(nr.x, nr.z).dot(mid2) > 0.0:
					nr = -nr
			elif nr.y < 0.0:
				nr = -nr
			var aisle := k % 6 == 0 and col == seat
			_quad(p0, p1, p2, p3, nr, col.lightened(0.25) if aisle else col)
	# The pitch: grass out to the boards, mown in stripes across it, and its white lines.
	var rim0: PackedVector2Array = bowl[0][0]
	_cap(rim0, pitch + 0.4, Color("#4f8a3a"))
	var flat := func(a: Vector2, b: Vector2, w: float, y: float, col: Color) -> void:
		var s := (b - a).normalized().orthogonal() * w * 0.5
		_quad(Vector3(a.x - s.x, y, a.y - s.y), Vector3(b.x - s.x, y, b.y - s.y), Vector3(b.x + s.x, y, b.y + s.y),
				Vector3(a.x + s.x, y, a.y + s.y), Vector3.UP, col)
	var at := func(x: float, y: float) -> Vector2: return c + axis * x + across * y
	for b in 12:
		if b % 2 == 0:
			var x0 := -52.5 + b * 8.75
			flat.call(at.call(x0, 0.0), at.call(x0 + 8.75, 0.0), 68.0, pitch + 0.43, Color("#5a9643"))
	# Lines at three heights 3 cm apart, so lines that cross never share a plane.
	var line := Color("#f2f2ee")
	var y_long := pitch + 0.47
	var y_short := pitch + 0.50
	var y_box := pitch + 0.53
	for side: float in [-1.0, 1.0]:
		flat.call(at.call(-52.5, side * 34.0), at.call(52.5, side * 34.0), 0.6, y_long, line)
		flat.call(at.call(side * 52.5, -34.3), at.call(side * 52.5, 34.3), 0.6, y_short, line)
		# The penalty area: 16.5 m deep, 40.3 m wide; its front at the third height.
		flat.call(at.call(side * 52.2, -20.15), at.call(side * 36.0, -20.15), 0.6, y_long, line)
		flat.call(at.call(side * 52.2, 20.15), at.call(side * 36.0, 20.15), 0.6, y_long, line)
		flat.call(at.call(side * 36.0, -20.45), at.call(side * 36.0, 20.45), 0.6, y_box, line)
	flat.call(at.call(0.0, -34.3), at.call(0.0, 34.3), 0.6, y_short, line)
	for k in 16:
		var a0: float = TAU * k / 16.0
		var a1: float = TAU * (k + 1) / 16.0
		# Neighbouring arcs overlap at their joints: every other one 3 cm higher.
		flat.call(at.call(cos(a0) * 9.15, sin(a0) * 9.15), at.call(cos(a1) * 9.15, sin(a1) * 9.15), 0.6,
				y_box + (k % 2) * 0.03, line)
	# The masts: from the foot of the skin, leaning out with it, spiking over the roof.
	for k in n:
		var vi: Vector2 = inner[k]
		var vo: Vector2 = outer[k]
		var a := Vector3(vi.x, foot[k], vi.y)
		var b := Vector3(vo.x, street + 60.0, vo.y)
		_beam(a, b, 0.55, Color("#e4e6ea"))
		# The spike over the rim, thicker: the stadium's silhouette from the street.
		var s0 := a.lerp(b, (rim_y - 1.0 - a.y) / (b.y - a.y))
		_beam(s0, b + (b - a).normalized() * 0.4, 1.0, Color("#f2f3f5"))
	# The needle (mapped 30-100 m): a white spindle through a dark hub ring where the cables
	# meet (37-43 m, 15.6 m across), the folded roof stored in a white drum above it (55-63 m,
	# 21 m across), and a red light on its tip; a cable from the hub to every third mast's
	# angle on the roof's inner edge.
	var steel := Color("#f1f1ee")
	var ring10 := func(radius: float) -> PackedVector2Array:
		var ring := PackedVector2Array()
		for k in 10:
			ring.append(c + Vector2.from_angle(TAU * k / 10.0) * radius)
		return ring
	_frustum(ring10.call(0.6), street + 30.0, ring10.call(1.0), street + 37.0, steel)
	_prism(ring10.call(7.8), street + 37.0, street + 43.0, Color("#2c2d31"), Color("#3a3b40"), M_STONE, M_STONE)
	_frustum(ring10.call(1.0), street + 43.0, ring10.call(1.2), street + 51.5, steel)
	_frustum(ring10.call(1.2), street + 51.5, ring10.call(10.5), street + 55.0, steel)
	_frustum(ring10.call(10.5), street + 55.0, ring10.call(10.5), street + 61.0, Color("#e6e7e4"))
	_frustum(ring10.call(10.5), street + 61.0, ring10.call(1.6), street + 63.5, steel, steel)
	_frustum(ring10.call(1.0), street + 63.5, ring10.call(0.3), street + 99.0, steel)
	_prism(ring10.call(0.45), street + 99.0, street + 100.5, Color("#ff3b30"), Color("#ff6a5c"), M_LAMP, M_LAMP)
	var hub := Vector3(c.x, street + 40.0, c.y)
	var keep_id := _id
	_id = 0
	for k in range(0, n, 3):
		var h: Vector2 = hole[k]
		# A few cm of height apart at the hub, so neighbours' flat tops don't z-fight there.
		var lift := Vector3(0.0, (k / 3 % 5) * 0.03, 0.0)
		_beam(hub + lift, Vector3(h.x, hole_y, h.y), 0.18, Color("#c8cbd0"), false)
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

## Colours (spec centralna.md section 5).
const CEN_GLASS := Color("#7f9fb2")     # the hall's curtain wall, lit cool white at night
const CEN_WING := Color("#8d9aa2")      # the wings' glass in a light concrete grid
const CEN_STONE := Color("#bcbaab")     # mapped: the wings and their roof boxes
const CEN_DECK := Color("#9c9a90")      # the wings' and boxes' roofs
const CEN_DOOR := Color("#3f4c55")      # the vestibules' dark glass
const CEN_FASCIA := Color("#e4e2dc")    # mapped white: the slab's edge and the shells' fascia
const CEN_ROOF := Color("#638898")      # mapped roof colour
const CEN_SOFFIT := Color("#9a968c")    # the shells' underside: the ceiling, lit at night
const CEN_PILLAR := Color("#bdb8ad")
## The shells' grid (local metres): the pillars stand on every other node along u (10 m apart
## from -65.4) on the rows v -20.5 and 21.2; the ends are the shell tier's mapped edges.
const CEN_SHELL_U0 := -65.4
const CEN_SHELL_V := [-28.0, -20.5, -13.55, -6.6, 0.35, 7.3, 14.25, 21.2, 28.9]
const CEN_SHELL_ENDS := Vector2(-68.5, 68.7)
const CEN_LOW := 15.0    # a shell's low corners: the pillars' heads
const CEN_HIGH := 16.5   # its high corners: the slab's underside
const CEN_TOP := 18.0

## The station hall's glass box under the flat overhanging slab, and between them the roof's
## shells: hyperbolic paraboloids (saddles whose corners fall to the pillars' heads and rise
## to the slab in turn), so the shell tier's fascia zigzags under the straight slab wherever
## its edge shows (the two ends). At night the hall glows cool white floor by floor, the
## shells' underside is lit, and lamps line the slab's edge.
func _build_centralna(site: Dictionary) -> void:
	_o = CENTRALNA
	_a = Vector2.from_angle(deg_to_rad(CENTRALNA_TURN))
	_b = Vector2(-_a.y, _a.x)
	_g = _ground_under(_rect(0.0, 0.0, 70.0, 43.0))
	var g := _g
	var none := Color(0, 0, 0, 0)
	# The glass hall, from the ground (the mapped storey under it is its ground floor) to the
	# slab: the shells meet its walls.
	for q: PackedVector2Array in site.get("hall", []):
		_prism(q, _ground_under(q) - 0.4, g + CEN_HIGH, CEN_GLASS, none, M_PAVILION + 0.5)
		_collide(q)
	# The lower wings either side, from the ground, and the boxes on their roofs.
	for w: Dictionary in site.get("wings", []):
		var q := _pts(w["p"])
		_prism(q, _ground_under(q) - 0.4, g + float(w["h"]), CEN_WING, CEN_DECK, M_SKIN + float(S_GRID) / 16.0, M_STONE)
		_collide(q)
	for bx: Dictionary in site.get("boxes", []):
		_prism(_pts(bx["p"]), g + float(bx["mh"]), g + float(bx["h"]), CEN_STONE, CEN_DECK, M_STONE, M_STONE)
	for q: PackedVector2Array in site.get("vest", []):
		_prism(q, _ground_under(q) - 0.4, g + 3.3, CEN_DOOR, CEN_DOOR.darkened(0.2), M_GLASS, M_STONE)
		_collide(q)
	# The pillars that stand clear of the hall and the wings (the ends), solid for the car too.
	for p: Vector2 in site.get("pillars", []):
		var l := _local(p)
		_lbox(l.x, l.y, 0.55, 0.55, g - 0.4, g + CEN_LOW, CEN_PILLAR, M_STONE)
		_collide(_rect(l.x, l.y, 0.55, 0.55))
	_centralna_shells(g, site.get("shells", PackedVector2Array()))
	# The slab: straight white edges, the mapped roof colour on top in a faint checker of panels
	# over the shells' bays (every panel cut to the slab's outline; the end ones reach past it).
	var slab: PackedVector2Array = site.get("slab", _rect(0.0, 0.0, 70.0, 43.0))
	_prism(slab, g + CEN_HIGH, g + CEN_TOP, CEN_FASCIA, none, M_STONE)
	_mode = M_STONE
	var vb := [-44.0]
	vb.append_array(CEN_SHELL_V.slice(0, 9, 2))
	vb.append(45.0)
	for j in vb.size() - 1:
		for i in 14:
			var u0 := -80.0 if i == 0 else CEN_SHELL_U0 - 5.0 + i * 10.0
			var u1 := 80.0 if i == 13 else CEN_SHELL_U0 + 5.0 + i * 10.0
			var cell := PackedVector2Array([_w(u0, vb[j]), _w(u1, vb[j]), _w(u1, vb[j + 1]), _w(u0, vb[j + 1])])
			for piece in Geometry2D.intersect_polygons(cell, slab):
				if piece.size() >= 3 and not Geometry2D.is_polygon_clockwise(piece):
					_cap(piece, g + CEN_TOP, CEN_ROOF.darkened(0.03) if (i + j) % 2 == 1 else CEN_ROOF)
	# The dusk loop (2026-10-31): small warm-white lamps along the slab's edge, every ~5 m,
	# 0.6 m under its top, 0.08 m proud of it (0.8 m: smaller ones were under a pixel from
	# the driving camera).
	_mode = M_LAMP
	var lamp := Color(1.0, 0.93, 0.78)
	for k in slab.size():
		var ea := slab[k]
		var eb := slab[(k + 1) % slab.size()]
		var eo := _out(slab, ea, eb)
		var along := (eb - ea).normalized()
		var count := roundi(ea.distance_to(eb) / 5.0)
		for n in count:
			var t := (float(n) + 0.5) / float(count)
			var p := ea.lerp(eb, t) + eo * 0.08
			var y := g + CEN_TOP - 0.6
			var l := along * 0.4
			_quad(Vector3(p.x - l.x, y - 0.4, p.y - l.y), Vector3(p.x + l.x, y - 0.4, p.y + l.y),
					Vector3(p.x + l.x, y + 0.4, p.y + l.y), Vector3(p.x - l.x, y + 0.4, p.y - l.y),
					Vector3(eo.x, 0.0, eo.y), lamp)
	_mode = M_STONE


## The shell tier: a grid of hyperbolic paraboloids, each bay's corners alternately at the
## pillars' heads (15 m) and the slab (16.5 m); every bay's underside (lit at night) folds once, and the tier's edge a white fascia from the zigzag up to
## the slab (triangles: one end of every segment already touches the slab).
func _centralna_shells(g: float, tier: PackedVector2Array) -> void:
	var us: Array[float] = [CEN_SHELL_ENDS.x]
	for k in 27:
		us.append(CEN_SHELL_U0 + 5.0 * k)
	us.append(CEN_SHELL_ENDS.y)
	var vs: Array = CEN_SHELL_V
	# The ends follow the tier's mapped outline (its ends bow out by up to 1.7 m), so the
	# zigzag stands flush under the slab's end edge, where it shows.
	var ends: Array[Vector2] = []
	for v in vs:
		# The corners: a metre in, where the line still crosses both ends.
		ends.append(_tier_ends(tier, clampf(float(v), float(vs[0]) + 1.0, float(vs[-1]) - 1.0)))
	var ni := us.size() - 1
	var corner := func(i: int, j: int) -> Vector3:
		var u: float = ends[j].x if i == 0 else (ends[j].y if i == ni else us[i])
		var p := _w(u, float(vs[j]))
		return Vector3(p.x, g + (CEN_LOW if (i + j) % 2 == 0 else CEN_HIGH), p.y)
	_mode = M_LAMP
	for j in vs.size() - 1:
		for i in us.size() - 1:
			var c00: Vector3 = corner.call(i, j)
			var c10: Vector3 = corner.call(i + 1, j)
			var c01: Vector3 = corner.call(i, j + 1)
			var c11: Vector3 = corner.call(i + 1, j + 1)
			# One fold along the diagonal joining the two low corners (the valley the pillars
			# carry): seen only from under the slab, so no finer than that.
			var lows := (i + j) % 2 == 0
			var tris := [[c00, c10, c11], [c00, c11, c01]] if lows else [[c00, c10, c01], [c10, c11, c01]]
			for tr in tris:
				var n: Vector3 = (tr[1] - tr[0]).cross(tr[2] - tr[0]).normalized()
				if n.y > 0.0:
					n = -n
				_tri(tr[0], tr[1], tr[2], n, CEN_SOFFIT, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)
	# The fascia round the tier: along each side, triangles from the zigzag up to the slab.
	_mode = M_STONE
	var nj := vs.size() - 1
	var edges: Array = []  # [i0, j0, i1, j1, outward]
	for k in ni:
		edges.append([k, 0, k + 1, 0, -_b])
		edges.append([k, nj, k + 1, nj, _b])
	for k in nj:
		edges.append([0, k, 0, k + 1, -_a])
		edges.append([ni, k, ni, k + 1, _a])
	for e in edges:
		var out: Vector2 = e[4]
		var p0: Vector3 = corner.call(e[0], e[1])
		var p1: Vector3 = corner.call(e[2], e[3])
		var length := Vector2(p0.x, p0.z).distance_to(Vector2(p1.x, p1.z))
		var low_end := p0 if p0.y < p1.y else p1
		var top := Vector3(low_end.x, g + CEN_HIGH, low_end.z)
		_tri(p0, p1, top, Vector3(out.x, 0.0, out.y), CEN_FASCIA, Vector2(0.0, p0.y - g),
				Vector2(length, p1.y - g), Vector2(0.0 if p0.y < p1.y else length, CEN_HIGH), CEN_HIGH)


## Where the line v (the shell tier's local plan) crosses the tier's outline: its west and
## east ends (CEN_SHELL_ENDS when the outline is missing or the line misses it).
func _tier_ends(tier: PackedVector2Array, v: float) -> Vector2:
	var lo := INF
	var hi := -INF
	for k in tier.size():
		var a := _local(tier[k])
		var b := _local(tier[(k + 1) % tier.size()])
		if (a.y - v) * (b.y - v) > 0.0 or is_equal_approx(a.y, b.y):
			continue
		var u := lerpf(a.x, b.x, (v - a.y) / (b.y - a.y))
		lo = minf(lo, u)
		hi = maxf(hi, u)
	return Vector2(lo, hi) if hi > lo else CEN_SHELL_ENDS


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


# --- Muzeum Narodowe and Plac Piłsudskiego (the museum and Plac loop, 2026-10-31) ----------------

## The museum's raised entrance block stands at the back of its forecourt (Dziedziniec im.
## Stanisława Lorentza, the courtyard open to Al. Jerozolimskie): the middle of that wall and the
## building's own axis along the avenue (east); its back is MUZEUM_AXIS turned a quarter (south).
const MUZEUM_DOOR := Vector2(-2.95, 276.7)
const MUZEUM_AXIS := Vector2(0.964, -0.267)
## The army museum's tank and field gun: on the east courtyard's lawn between its pool and the
## east block (map areas), lined up with that wall.
const MUZEUM_TANK := Vector2(53.8, 211.0)
const MUZEUM_GUN := Vector2(56.5, 233.0)
const MUZEUM_YARD_DIR := Vector2(-0.276, -0.961)
## Plac part 2: the heights are estimates (OpenStreetMap tags the wings building:levels=4,
## which the bake turns into 14.2 m at 3.3 m a storey; the museum's galleries are taller storeys).
const MUZEUM_TOP := 25.0           # the entrance block's parapet (estimate; was 20 m)
const MUZEUM_WINGS := 18.5         # the wings' parapet (estimate: four storeys of about 4.4 m)
const MUZEUM_PLINTH := Color("#a99f8b")
const MUZEUM_GLASS := Color("#3b424b")
const ARMY_OLIVE := Color("#5a6141")
const ARMY_TRACK := Color("#2f302b")
const ARMY_PAD := Color("#9a968d")


## A closed outline with the steps under `tol` metres dropped (Douglas-Peucker), so walls run
## straight between the mapped corners (the museum's outline has 481 points: every pier).
func _simplify(ring: PackedVector2Array, tol: float) -> PackedVector2Array:
	var far := 0
	for i in ring.size():
		if ring[i].distance_squared_to(ring[0]) > ring[far].distance_squared_to(ring[0]):
			far = i
	if far == 0:
		return ring
	var back := ring.slice(far)
	back.append(ring[0])
	var out := _dp(ring.slice(0, far + 1), tol)
	out.resize(out.size() - 1)
	var rest := _dp(back, tol)
	rest.resize(rest.size() - 1)
	out.append_array(rest)
	return out if out.size() >= 3 else ring


func _dp(pts: PackedVector2Array, tol: float) -> PackedVector2Array:
	var best := -1.0
	var at := 0
	for i in range(1, pts.size() - 1):
		var d := pts[i].distance_to(Geometry2D.get_closest_point_to_segment(pts[i], pts[0], pts[-1]))
		if d > best:
			best = d
			at = i
	if best <= tol:
		return PackedVector2Array([pts[0], pts[-1]])
	var out := _dp(pts.slice(0, at + 1), tol)
	out.resize(out.size() - 1)
	out.append_array(_dp(pts.slice(at), tol))
	return out


func _area(poly: PackedVector2Array) -> float:
	var a := 0.0
	for i in poly.size():
		var p := poly[i]
		var q := poly[(i + 1) % poly.size()]
		a += p.x * q.y - q.x * p.y
	return a * 0.5


## Tall window bays along a ring's walls: a pane `w` wide every `step` metres (the walls'
## piers between them), from h0 to h1 over the ground, 0.07 m proud of the wall, in the
## curtain-wall glass (M_GLASS: a transom every 4 m, some lit at night); none where a bay's
## foot falls in `skip` (a block standing in front of that wall).
func _bays(ring: PackedVector2Array, h0: float, h1: float, step: float, w: float, col: Color,
		skip := PackedVector2Array()) -> void:
	var keep := _mode
	_mode = M_GLASS
	var along := 0.0
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		along += length
		var n := floori((length - 1.5) / step)
		if n < 1:
			continue
		var e := (b - a) / length
		var out := _out(ring, a, b)
		var t0 := (length - n * step) * 0.5 + step * 0.5
		for k in n:
			var p := a + e * (t0 + k * step) + out * 0.07
			if skip.size() >= 3 and Geometry2D.is_point_in_polygon(p, skip):
				continue
			# UV.x centred on a pane of the shader's 1.5 m grid (so its mullions frame the bay), at
			# the bay's distance round the ring (so each bay draws its own lit rooms at night).
			var pane := floorf((along + t0 + k * step) / 1.5) * 1.5
			_wall(p - e * w * 0.5, p + e * w * 0.5, _g + h0, _g + h1, out, col, pane + 0.75 - w * 0.5)
	_mode = keep


## A thin parapet (zero thickness, both sides drawn) round a ring, from y up `height`.
func _parapet(ring: PackedVector2Array, y: float, height: float, col: Color) -> void:
	var keep := _mode
	_mode = M_STONE
	var run := 0.0
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		_wall(a, b, y, y + height, _out(ring, a, b), col, run)
		run += a.distance_to(b)
	_mode = keep


## Muzeum Narodowe: Tadeusz Tołwiński's stripped-classical block in pale stone. The mapped
## outline straightened, on a darker plinth, to its wings' height (MUZEUM_WINGS) with a parapet; tall narrow
## window bays in a steady rhythm on every front; at the back of the forecourt the raised
## entrance block (MUZEUM_TOP) with its recessed glazed portal behind four square piers under a
## lintel, two tall bays either side, and steps; on the east courtyard's lawn the army museum's
## hardware: a tank and a field gun on concrete pads.
func _build_muzeum(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	var h: float = site["h"]
	var light := MUZEUM_STONE.lightened(0.07)
	var base := Geometry2D.offset_polygon(ring, 0.35, Geometry2D.JOIN_MITER)
	if not base.is_empty():
		_prism(base[0], g - 0.6, g + 1.3, MUZEUM_PLINTH, MUZEUM_PLINTH, M_STONE, M_STONE)
	_prism(ring, g - 0.6, g + h, MUZEUM_STONE, MUZEUM_ROOF, M_STONE, M_STONE)
	_parapet(ring, g + h, 1.0, light)
	# The entrance block, in the forecourt's frame (u east along the avenue, v to the back).
	_o = MUZEUM_DOOR
	_a = MUZEUM_AXIS
	_b = Vector2(-_a.y, _a.x)
	var block := _rect(0.0, 7.0, 12.0, 9.5)
	_bays(ring, 2.0, h - 2.2, 4.4, 1.3, MUZEUM_GLASS, _rect(0.0, 7.0, 12.5, 10.0))
	_prism(block, g - 0.6, g + MUZEUM_TOP, MUZEUM_STONE, MUZEUM_ROOF, M_STONE, M_STONE)
	_parapet(block, g + MUZEUM_TOP, 1.0, light)
	var front := -_b
	_mode = M_GLASS
	_wall(_w(-6.5, -2.56), _w(6.5, -2.56), g, g + 12.5, front, MUZEUM_GLASS)
	for u in [-9.6, 9.6]:
		_wall(_w(u - 0.65, -2.56), _w(u + 0.65, -2.56), g + 2.0, g + MUZEUM_TOP - 2.5, front, MUZEUM_GLASS, 0.1)
	for u in [-4.875, -1.625, 1.625, 4.875]:
		_lbox(u, -3.5, 0.55, 0.55, g, g + 12.5, light, M_STONE, light)
	_lbox(0.0, -3.4, 7.0, 0.95, g + 12.5, g + 13.6, light, M_STONE, light)
	_lbox(0.0, -6.0, 8.5, 3.5, g - 0.6, g + 0.4, MUZEUM_PLINTH, M_STONE, MUZEUM_PLINTH)
	_collide(ring)
	_collide(_rect(0.0, -2.5, 7.0, 1.6))
	# The army museum's hardware on the lawn of the east courtyard, beside its pool, noses north.
	_tank(MUZEUM_TANK, MUZEUM_YARD_DIR)
	_field_gun(MUZEUM_GUN, MUZEUM_YARD_DIR.rotated(-0.5))


## A tank on show (a hull on its tracks, an eight-sided turret, the gun), on a pad; `dir` its nose.
func _tank(c: Vector2, dir: Vector2) -> void:
	var g: float = map.terrain_height(c.x, c.y)
	_o = c
	_a = dir
	_b = Vector2(-dir.y, dir.x)
	_lbox(0.0, 0.0, 4.0, 2.4, g - 0.3, g + 0.15, ARMY_PAD, M_STONE, ARMY_PAD)
	for v in [-1.45, 1.45]:
		_lbox(0.0, v, 3.4, 0.4, g + 0.15, g + 1.1, ARMY_TRACK, M_STONE, ARMY_TRACK)
	_lbox(-0.1, 0.0, 3.1, 1.1, g + 0.5, g + 1.55, ARMY_OLIVE, M_STONE, ARMY_OLIVE.darkened(0.08))
	var turret := _circle(_w(-0.4, 0.0), 1.15, 8)
	_prism(turret, g + 1.55, g + 2.3, ARMY_OLIVE.lightened(0.04), ARMY_OLIVE, M_STONE, M_STONE)
	var muzzle := _w(4.3, 0.0)
	var root := _w(0.6, 0.0)
	_beam(Vector3(root.x, g + 1.9, root.y), Vector3(muzzle.x, g + 2.0, muzzle.y), 0.2, ARMY_OLIVE.darkened(0.25))
	_collide(_rect(0.0, 0.0, 3.4, 1.9))


## A field gun on show: the carriage and its shield, two wheels, the barrel raised, the split trail.
func _field_gun(c: Vector2, dir: Vector2) -> void:
	var g: float = map.terrain_height(c.x, c.y)
	_o = c
	_a = dir
	_b = Vector2(-dir.y, dir.x)
	_lbox(-0.6, 0.0, 3.0, 1.7, g - 0.3, g + 0.15, ARMY_PAD, M_STONE, ARMY_PAD)
	_lbox(0.0, 0.0, 0.7, 0.6, g + 0.6, g + 1.1, ARMY_OLIVE, M_STONE, ARMY_OLIVE)
	_lbox(0.45, 0.0, 0.06, 0.95, g + 0.7, g + 1.9, ARMY_OLIVE.darkened(0.1), M_STONE, ARMY_OLIVE)
	for v in [-0.95, 0.95]:
		_lbox(0.0, v, 0.6, 0.1, g + 0.15, g + 1.35, ARMY_TRACK, M_STONE, ARMY_TRACK)
	var root := _w(0.2, 0.0)
	var muzzle := _w(3.4, 0.0)
	_beam(Vector3(root.x, g + 1.05, root.y), Vector3(muzzle.x, g + 2.0, muzzle.y), 0.17, ARMY_OLIVE.darkened(0.25))
	for v in [-1.0, 1.0]:
		var p0 := _w(-0.4, v * 0.3)
		var p1 := _w(-3.2, v * 1.0)
		_beam(Vector3(p0.x, g + 0.75, p0.y), Vector3(p1.x, g + 0.25, p1.y), 0.16, ARMY_OLIVE.darkened(0.15))


## Plac Piłsudskiego's edges: Hotel Europejski (its mapped outline) and the Tomb of the Unknown
## Soldier (built at its place, like Sigismund's Column; its zone the mapped outline, which
## drops the hundred tiny 3D parts it is mapped in).
const EUROPEJSKI_WALL := Color("#e7ddc5")
const EUROPEJSKI_BASE := Color("#d2c5a7")
const EUROPEJSKI_ROOF := Color("#6f7b76")
const EUROPEJSKI_GLASS := Color("#3a3f47")
const EUROPEJSKI_H := 19.0        # the main cornice
const EUROPEJSKI_BASE_H := 6.0    # the rusticated ground floor and mezzanine
## The Tomb: the middle of its arcade, the arcade's long axis (south), its piers along it.
const GROB := Vector2(-865.75, -768.7)
const GROB_AXIS := Vector2(-0.2425, -0.970)
const GROB_PIERS := [-5.55, -1.85, 1.85, 5.55]
const GROB_ROW := 2.98            # each row of piers this far from the axis
const GROB_STONE := Color("#ddd3bf")
const GROB_GRANITE := Color("#7f7c78")
const GROB_BRONZE := Color("#4f4a40")
const GROB_FLAME := Color("#ffb04a")
func _find_plac() -> void:
	var euro := _landmark("Hotel Europejski")
	if euro.size() >= 3:
		_add_site("europejski", [euro])
		if not sites.is_empty() and sites[-1]["key"] == "europejski":
			sites[-1]["ring"] = _simplify(euro, 0.8)
	var grob := _landmark("Grób Nieznanego Żołnierza")
	if grob.size() >= 3:
		var grown := Geometry2D.offset_polygon(grob, 1.0, Geometry2D.JOIN_MITER)
		_add_site("grob", [grown[0] if not grown.is_empty() else grob])
	_find_plac2()


## Hotel Europejski (1857-1877, Enrico Marconi): a long cream classical block. A rusticated
## ground floor and mezzanine (stone courses, each with its light edge) with tall dark openings,
## three floors of windows between pilasters above (M_MONUMENT), a projecting cornice, a low
## hipped roof in grey-green sheet; a central bay stepping forward on the Krakowskie
## Przedmieście front and on the square's, each with an attic and a tall entrance.
func _build_europejski(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var courses := 5
	for k in courses:
		var y0 := g - 0.6 + (EUROPEJSKI_BASE_H + 0.6) * k / courses
		var y1 := g - 0.6 + (EUROPEJSKI_BASE_H + 0.6) * (k + 1) / courses
		var col := EUROPEJSKI_BASE.darkened(0.12 if k == 0 else (0.0 if k % 2 == 1 else 0.05))
		_prism(ring, y0, y1, col, none, M_STONE)
	_bays(ring, 0.7, 4.7, 4.6, 1.9, EUROPEJSKI_GLASS)
	_prism(ring, g + EUROPEJSKI_BASE_H, g + EUROPEJSKI_H, EUROPEJSKI_WALL, none, M_MONUMENT)
	var lip := EUROPEJSKI_WALL.lightened(0.08)
	var eave := Geometry2D.offset_polygon(ring, 0.45, Geometry2D.JOIN_MITER)
	_prism(eave[0] if not eave.is_empty() else ring, g + EUROPEJSKI_H - 0.1, g + EUROPEJSKI_H + 0.6, lip, lip, M_STONE, M_STONE)
	# The roof: hipped over the plan's inner rectangle (its axes from the longest front).
	var longest := 0.0
	for i in ring.size():
		var e := ring[(i + 1) % ring.size()] - ring[i]
		if e.length() > longest:
			longest = e.length()
			_a = e.normalized()
	_b = Vector2(-_a.y, _a.x)
	_o = _centre(ring)
	var lo := Vector2(INF, INF)
	var hi := -lo
	for q in ring:
		lo = lo.min(_local(q))
		hi = hi.max(_local(q))
	_o = _wl((lo + hi) * 0.5)
	var hu := (hi.x - lo.x) * 0.5 - 4.0
	var hv := (hi.y - lo.y) * 0.5 - 4.0
	_mode = M_STONE
	_frustum(_rect(0.0, 0.0, hu, hv), g + EUROPEJSKI_H + 0.6, _rect(0.0, 0.0, hu - 6.0, hv - 6.0),
			g + EUROPEJSKI_H + 4.2, EUROPEJSKI_ROOF, EUROPEJSKI_ROOF.darkened(0.08))
	# The central bays: on the two longest fronts that face east and west (the street, the square).
	var compass := Vector2(1, 0)
	for side: float in [1.0, -1.0]:
		var best := -1
		var best_len := 0.0
		for i in ring.size():
			var a := ring[i]
			var b := ring[(i + 1) % ring.size()]
			if _out(ring, a, b).dot(compass * side) > 0.8 and a.distance_to(b) > best_len:
				best_len = a.distance_to(b)
				best = i
		if best < 0 or best_len < 24.0:
			continue
		var a := ring[best]
		var b := ring[(best + 1) % ring.size()]
		_o = (a + b) * 0.5
		_a = (b - a).normalized()
		_b = _out(ring, a, b)
		_lbox(0.0, 0.0, 9.0, 0.8, g - 0.6, g + EUROPEJSKI_BASE_H, EUROPEJSKI_BASE.darkened(0.03), M_STONE, EUROPEJSKI_BASE)
		_lbox(0.0, 0.0, 9.0, 0.8, g + EUROPEJSKI_BASE_H, g + EUROPEJSKI_H + 0.6, EUROPEJSKI_WALL, M_MONUMENT, lip)
		_lbox(0.0, 0.0, 6.0, 0.6, g + EUROPEJSKI_H + 0.6, g + EUROPEJSKI_H + 2.6, lip, M_STONE, lip)
		_mode = M_GLASS
		_wall(_w(-1.6, 0.86), _w(1.6, 0.86), g, g + 4.9, _b, EUROPEJSKI_GLASS, -0.85)
	_collide(ring)


# --- Muzeum Sztuki Nowoczesnej ------------------------------------------------------------

## The Museum of Modern Art (Thomas Phifer, 2024), first scene item 1 (2026-10-31), built to its
## spec docs/landmarks/specs/msn.md from the museum's OpenStreetMap parts: one long white box on
## a glazed ground floor behind deep white fins, a thin dark slot all round where the upper box
## sits back, two "city room" windows, long skylights on the flat roof. Its plan frame: u along
## the long side (north-north-west end at u < 0), +v towards the Palace, -v Marszałkowska.
const MSN := Vector2(-1022.4, 100.15)
const MSN_AXIS := Vector2(0.3445, 0.9388)
const MSN_HU := 51.85          # the box's half length and half width (the outline)
const MSN_HV := 19.9
const MSN_INSET := 0.7         # the slot band sits this far in
const MSN_CORE := Vector2(45.8, 13.95)  # the glazed ground floor's half plan
const MSN_BASE := 5.0          # the soffit
const MSN_SLOT := Vector2(12.5, 13.8)
const MSN_H := 26.0
## The fins' centres (u) on the Marszałkowska face (v -17.4) and the Plac Defilad face (v +17.35).
const MSN_FINS_EAST := [-50.4, -39.4, -26.4, -18.4, -10.4, 0.4, 7.4, 15.3, 26.4, 33.8, 40.8, 50.4]
const MSN_FINS_WEST := [-50.4, -39.5, -32.5, -26.5, -18.5, -10.6, 0.4, 7.3, 15.2, 26.2, 33.7, 40.7, 50.3]
## The ends' fins, turned along u: [u, v].
const MSN_FINS_END := [[-49.4, 3.95], [-49.4, -8.5], [49.4, 6.3], [49.4, -8.55]]
## The glazed roof panels [u, v, half u, half v] and the light well [u, v, half side] (F's night
## photo, 2026-10-31: big lit fields round an open square court; the layout is an estimate).
const MSN_SKY := [[-38.5, -6.0, 8.5, 10.0], [-14.0, -11.0, 10.0, 5.0], [-14.0, 9.0, 10.0, 7.0],
		[29.0, -10.0, 15.0, 6.0], [29.0, 10.0, 15.0, 6.0]]
const MSN_WELL := Vector3(6.0, 0.0, 4.0)
## The north-west corner block (OSM: u -64.3..-53.8, v 16.5..27, 26 m on an 8 m base).
const MSN_CORNER_U := -64.3
const MSN_CORNER_V := Vector2(16.5, 27.0)
const MSN_WHITE := Color("#ebe9e3")
const MSN_ROOF := Color("#d9d8d2")
const MSN_LOBBY := Color("#a9c3cd")
const MSN_SLOT_GLASS := Color("#4a5960")
const MSN_WINDOW := Color("#8fa9b6")
const MSN_SKY_GLASS := Color("#cfd8dc")
func _find_msn() -> void:
	var outline := _landmark("Muzeum Sztuki Nowoczesnej")
	if outline.size() < 3:
		return
	# Grown a metre so the fins and the mapped parts on the edge go with it.
	var grown := Geometry2D.offset_polygon(outline, 1.0, Geometry2D.JOIN_MITER)
	_o = MSN
	_a = MSN_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	var corner := _rect((MSN_CORNER_U - MSN_HU) * 0.5, (MSN_CORNER_V.x + MSN_CORNER_V.y) * 0.5,
			(MSN_HU + MSN_CORNER_U) * -0.5 + 1.0, (MSN_CORNER_V.y - MSN_CORNER_V.x) * 0.5 + 1.0)
	_add_site("msn", [grown[0] if not grown.is_empty() else outline, corner])


func _build_msn(_site: Dictionary) -> void:
	_o = MSN
	_a = MSN_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	var box := _rect(0.0, 0.0, MSN_HU, MSN_HV)
	_g = _ground_under(box)
	var g := _g
	var none := Color(0, 0, 0, 0)
	# The windows first, flush, so the walls are cut round them (F's night photo, 2026-10-31):
	# w1 and w3 on the Plac Defilad face, w4 and w5 on the north end, w2 on Marszałkowska.
	_mode = M_PAVILION
	_wall(_w(0.0, MSN_HV), _w(14.0, MSN_HV), g + 16.5, g + 22.5, _b, MSN_WINDOW)
	_wall(_w(-1.0, MSN_HV), _w(5.0, MSN_HV), g + 7.0, g + 10.5, _b, MSN_WINDOW)
	_wall(_w(-30.0, -MSN_HV), _w(-12.0, -MSN_HV), g + 16.5, g + 22.0, -_b, MSN_WINDOW)
	_wall(_w(-MSN_HU, -9.0), _w(-MSN_HU, -15.0), g + 15.5, g + 22.0, -_a, MSN_WINDOW)
	_wall(_w(-MSN_HU, -11.5), _w(-MSN_HU, -14.0), g + 7.0, g + 9.5, -_a, MSN_WINDOW)
	# corner: the full-height block standing out at the north-west corner (OSM's part at
	# (-1062, 54), closed up to the box), solid to the ground, a glazed top a metre under the roof.
	var corner := PackedVector2Array([_w(MSN_CORNER_U, MSN_CORNER_V.x), _w(-MSN_HU, MSN_CORNER_V.x),
			_w(-MSN_HU, MSN_CORNER_V.y), _w(MSN_CORNER_U, MSN_CORNER_V.y)])
	_prism(corner, g - 0.4, g + MSN_H - 1.0, MSN_WHITE, MSN_SKY_GLASS, M_STONE, M_GLASS_ROOF)
	# core: the glazed lobby, lit warm at night.
	_prism(_rect(0.0, 0.0, MSN_CORE.x, MSN_CORE.y), g - 0.4, g + MSN_BASE, MSN_LOBBY, none, M_PAVILION)
	# fins
	for u: float in MSN_FINS_EAST:
		_prism(_rect(u, -17.4, 0.5, 1.5), g - 0.4, g + MSN_BASE, MSN_WHITE, none, M_STONE)
	for u: float in MSN_FINS_WEST:
		_prism(_rect(u, 17.35, 0.5, 1.5), g - 0.4, g + MSN_BASE, MSN_WHITE, none, M_STONE)
	for f: Array in MSN_FINS_END:
		_prism(_rect(f[0], f[1], 1.5, 0.5), g - 0.4, g + MSN_BASE, MSN_WHITE, none, M_STONE)
	_mode = M_STONE
	# soffit
	_msn_ring(MSN_HU, MSN_HV, MSN_CORE.x, MSN_CORE.y, g + MSN_BASE, Vector3.DOWN, MSN_WHITE.darkened(0.12))
	# lower
	_prism(box, g + MSN_BASE, g + MSN_SLOT.x, MSN_WHITE, none, M_STONE)
	# ledge, slot, under
	var hu := MSN_HU - MSN_INSET
	var hv := MSN_HV - MSN_INSET
	_msn_ring(MSN_HU, MSN_HV, hu, hv, g + MSN_SLOT.x, Vector3.UP, MSN_WHITE)
	_prism(_rect(0.0, 0.0, hu, hv), g + MSN_SLOT.x, g + MSN_SLOT.y, MSN_SLOT_GLASS, none, M_GLASS)
	_mode = M_STONE
	_msn_ring(MSN_HU, MSN_HV, hu, hv, g + MSN_SLOT.y, Vector3.DOWN, MSN_WHITE.darkened(0.15))
	# upper, its roof round the light well
	_prism(box, g + MSN_SLOT.y, g + MSN_H, MSN_WHITE, none, M_STONE)
	var well := _rect(MSN_WELL.x, MSN_WELL.y, MSN_WELL.z, MSN_WELL.z)
	_mode = M_STONE
	_cap_holes(box, [well], g + MSN_H, MSN_ROOF)
	# well: an open court cut into the roof, 4 m deep, its floor in shade.
	for i in 4:
		var a := well[i]
		var b := well[(i + 1) % 4]
		_wall(a, b, g + MSN_H - 4.0, g + MSN_H, -_out(well, a, b), MSN_WHITE.darkened(0.2))
	_cap(well, g + MSN_H - 4.0, MSN_ROOF.darkened(0.35))
	# sky: the big glazed roof panels over the top galleries, lit from inside at night.
	for r: Array in MSN_SKY:
		_prism(_rect(r[0], r[1], r[2], r[3]), g + MSN_H, g + MSN_H + 0.35, MSN_WHITE, MSN_SKY_GLASS, M_STONE, M_GLASS_ROOF)
	_mode = M_STONE
	_collide(box)


## A flat ring in the museum's frame between the half plans (hu, hv) and (iu, iv) at y, facing
## `n` (up for a ledge, down for a soffit): four quads.
func _msn_ring(hu: float, hv: float, iu: float, iv: float, y: float, n: Vector3, col: Color) -> void:
	for r: Array in [[-hu, -hv, -iu, hv], [iu, -hv, hu, hv], [-iu, -hv, iu, -iv], [-iu, iv, iu, hv]]:
		var p0 := _w(r[0], r[1])
		var p1 := _w(r[2], r[1])
		var p2 := _w(r[2], r[3])
		var p3 := _w(r[0], r[3])
		_quad(Vector3(p0.x, y, p0.y), Vector3(p1.x, y, p1.y), Vector3(p2.x, y, p2.y), Vector3(p3.x, y, p3.y), n, col)


# --- TR Warszawa's building site ----------------------------------------------------------

## F's ask (2026-10-31): the empty plot west of the museum, between its tree court and the
## Palace, fenced for TR Warszawa's theatre, as a messy building site and nothing built yet
## (F's night photo: a hoarding with black tarps, dug-up ground with old foundations, rubble,
## cabins): a hoarding with a gate, the dug-up ground, spoil heaps, the grid of old foundation
## walls, stacked cabins, a skip, pallets and steel, a small digger and one tower crane (a red
## lamp on its top, lit at night). In the museum's frame (MSN, MSN_AXIS): u -62..16, v 46..100.
const TR_U := Vector2(-62.0, 16.0)   # the plot along u
const TR_V := Vector2(46.0, 100.0)   # and across (towards the Palace)
const TR_HOARD := Color("#3f5a4a")   # dark green hoarding boards
const TR_TARP := Color("#232527")    # black tarp on the fence
const TR_DIRT := Color("#7d6a55")
const TR_SPOIL := Color("#8b7760")
const TR_CONCRETE := Color("#a7a49d")
const TR_STEEL := Color("#4a4d52")
const TR_CRANE := Color("#e2b33a")
const TR_CABIN := Color("#e8ebee")
const TR_CABIN_B := Color("#3d6fa3")
## The crane: [u, v, mast height, jib angle (deg, from +u), jib length, counter-jib length].
const TR_CRANES := [[-6.0, 90.0, 40.0, 200.0, 44.0, 12.0]]
## Spoil heaps: [u, v, half u, half v, height].
const TR_HEAPS := [[-48.0, 88.0, 7.0, 5.0, 3.2], [-30.0, 92.0, 5.0, 4.0, 2.4], [6.0, 56.0, 4.0, 3.5, 2.0]]
## The old foundations: walls [u0, v0, u1, v1, height] (a grid with gaps, as dug up).
const TR_RUINS := [[-40.0, 58.0, -18.0, 58.0, 0.9], [-40.0, 58.0, -40.0, 78.0, 0.7], [-29.0, 62.0, -29.0, 80.0, 1.1],
		[-36.0, 70.0, -14.0, 70.0, 0.6], [-18.0, 58.0, -18.0, 66.0, 1.0], [-22.0, 80.0, -8.0, 80.0, 0.8]]
func _find_tr() -> void:
	_o = MSN
	_a = MSN_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	_add_site("tr", [_tr_rect(0.5)])


## The plot's rectangle in the museum's frame, grown by `grow` metres.
func _tr_rect(grow: float) -> PackedVector2Array:
	return _rect((TR_U.x + TR_U.y) * 0.5, (TR_V.x + TR_V.y) * 0.5,
			(TR_U.y - TR_U.x) * 0.5 + grow, (TR_V.y - TR_V.x) * 0.5 + grow)


func _build_tr(_site: Dictionary) -> void:
	_o = MSN
	_a = MSN_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	var u0 := TR_U.x
	var u1 := TR_U.y
	var v0 := TR_V.x
	var v1 := TR_V.y
	var cu := (u0 + u1) * 0.5
	var cv := (v0 + v1) * 0.5
	var hu := (u1 - u0) * 0.5
	var hv := (v1 - v0) * 0.5
	var plot := _tr_rect(0.0)
	_g = _ground_under(plot)
	var g := _g
	var none := Color(0, 0, 0, 0)
	# hoarding: 2.4 m boards, 0.2 m thick, black tarp on the long run by the tree court and a
	# 10 m gate in it; green boards on the other three runs.
	var t := 0.1
	var gate := Vector2(-8.0, 2.0)
	_lbox((u0 + gate.x) * 0.5, v0 + t, (gate.x - u0) * 0.5, t, g - 0.3, g + 2.4, TR_TARP, M_STONE)
	_lbox((gate.y + u1) * 0.5, v0 + t, (u1 - gate.y) * 0.5, t, g - 0.3, g + 2.4, TR_TARP, M_STONE)
	_lbox(cu, v1 - t, hu, t, g - 0.3, g + 2.4, TR_HOARD, M_STONE)
	_lbox(u0 + t, cv, t, hv - 2.0 * t, g - 0.3, g + 2.4, TR_HOARD, M_STONE)
	_lbox(u1 - t, cv, t, hv - 2.0 * t, g - 0.3, g + 2.4, TR_HOARD, M_STONE)
	# ground: the dug-up dirt inside the hoarding.
	_lbox(cu, cv, hu - 0.4, hv - 0.4, g - 0.3, g + 0.15, TR_DIRT, M_STONE, TR_DIRT)
	# heaps: spoil heaps of dug soil and rubble.
	_mode = M_STONE
	for h: Array in TR_HEAPS:
		_frustum(_rect(h[0], h[1], h[2], h[3]), g + 0.15, _rect(h[0], h[1], h[2] * 0.3, h[3] * 0.3), g + 0.15 + h[4],
				TR_SPOIL, TR_SPOIL.lightened(0.06))
	# ruins: the old foundation walls, broken off at different heights.
	for w: Array in TR_RUINS:
		var along := Vector2(w[2] - w[0], w[3] - w[1])
		var mid := Vector2(w[0] + w[2], w[1] + w[3]) * 0.5
		var half_u := maxf(absf(along.x) * 0.5, 0.25)
		var half_v := maxf(absf(along.y) * 0.5, 0.25)
		_lbox(mid.x, mid.y, half_u, half_v, g + 0.15, g + 0.15 + w[4], TR_CONCRETE.darkened(0.12), M_STONE, TR_CONCRETE)
	# cabins: two stacks of site cabins inside the gate, white and blue.
	for i in 2:
		var su := u1 - 4.0 - i * 2.7
		_lbox(su, v0 + 5.0, 1.2, 3.0, g + 0.15, g + 2.75, TR_CABIN, M_STONE, TR_CABIN.darkened(0.08))
		_lbox(su, v0 + 5.0, 1.2, 3.0, g + 2.75, g + 5.35, TR_CABIN_B if i == 0 else TR_CABIN, M_STONE, TR_CABIN.darkened(0.12))
	# skip: an open steel skip by the gate (walls only, rubble inside).
	_prism(_rect(-14.0, v0 + 4.0, 2.8, 1.2), g + 0.15, g + 1.6, Color("#c8552f"), none, M_STONE)
	_lbox(-14.0, v0 + 4.0, 2.6, 1.0, g + 0.15, g + 1.2, TR_SPOIL.darkened(0.1), M_STONE, TR_SPOIL.darkened(0.1))
	# stacks: pallets of blocks and bundles of steel along the far board.
	for i in 5:
		var su := u1 - 6.0 - i * 3.4
		_lbox(su, v1 - 3.0, 1.1, 0.9, g + 0.15, g + 1.1 + 0.25 * (i % 2), Color("#9a7b5c") if i % 2 == 0 else TR_STEEL, M_STONE)
	# digger: a small yellow excavator by the heaps, its arm down into the ground.
	_tr_digger(Vector2(-38.0, 84.0), 30.0)
	for c: Array in TR_CRANES:
		_tr_crane(c)
	_o = MSN
	_a = MSN_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	_collide(plot)


## digger: tracks, the turning body, the cab and the boom, at `at` (museum frame), turned `deg`.
func _tr_digger(at: Vector2, deg: float) -> void:
	var g := _g
	var p := _w(at.x, at.y)
	_o = p
	_a = Vector2.from_angle(deg_to_rad(deg) + MSN_AXIS.angle())
	_b = Vector2(-_a.y, _a.x)
	for side: float in [-1.1, 1.1]:
		_lbox(0.0, side, 1.9, 0.4, g + 0.15, g + 0.85, Color("#2f3033"), M_STONE)
	_lbox(-0.2, 0.0, 1.5, 1.2, g + 0.85, g + 1.9, TR_CRANE, M_STONE)
	_lbox(0.6, 0.6, 0.6, 0.55, g + 1.9, g + 3.1, TR_CRANE.darkened(0.1), M_STONE, Color("#3a4046"))
	_lbox(2.6, -0.4, 1.4, 0.2, g + 1.6, g + 2.2, TR_CRANE, M_STONE)
	_lbox(4.0, -0.4, 0.2, 0.2, g + 0.15, g + 2.2, TR_STEEL, M_STONE)
	_o = MSN
	_a = MSN_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)


## crane: a square mast on a concrete foot, the slewing deck, the operator's cab, the jib and
## the counter-jib with its counterweight, the A-frame with its two ties, a red lamp on top.
func _tr_crane(c: Array) -> void:
	var g := _g
	var base := _w(c[0], c[1])
	var h: float = c[2]
	_o = base
	_a = Vector2.from_angle(deg_to_rad(c[3]) + MSN_AXIS.angle())
	_b = Vector2(-_a.y, _a.x)
	var none := Color(0, 0, 0, 0)
	_lbox(0.0, 0.0, 2.2, 2.2, g - 0.3, g + 1.2, TR_CONCRETE, M_STONE)
	_prism(_rect(0.0, 0.0, 0.8, 0.8), g + 1.2, g + h, TR_CRANE, none, M_STONE)
	_lbox(0.0, 0.0, 1.3, 1.3, g + h, g + h + 1.0, TR_CRANE.darkened(0.15), M_STONE)
	_lbox(1.6, -1.6, 0.9, 0.8, g + h - 1.2, g + h + 1.0, TR_CABIN, M_STONE)
	var jl: float = c[4]
	var cl: float = c[5]
	_lbox(jl * 0.5, 0.0, jl * 0.5, 0.5, g + h + 1.0, g + h + 2.2, TR_CRANE, M_STONE)
	_lbox(-cl * 0.5 - 0.0, 0.0, cl * 0.5, 0.6, g + h + 1.0, g + h + 1.8, TR_CRANE, M_STONE)
	_lbox(-cl + 1.6, 0.0, 1.5, 1.1, g + h - 0.6, g + h + 1.0, TR_CONCRETE.darkened(0.15), M_STONE)
	# the A-frame: a tapered tower over the mast, the ties as thin slanted boxes.
	_mode = M_STONE
	_frustum(_rect(0.0, 0.0, 0.7, 0.7), g + h + 2.2, _rect(0.0, 0.0, 0.25, 0.25), g + h + 8.0, TR_CRANE, TR_CRANE)
	for tie: Vector2 in [Vector2(jl * 0.7, g + h + 2.2), Vector2(-cl + 0.5, g + h + 1.8)]:
		var top := _w(0.0, 0.0)
		var end := _w(tie.x, 0.0)
		var side := _b * 0.12
		var y_top := g + h + 7.6
		var n := Vector3(end.x - top.x, tie.y - y_top, end.y - top.y).cross(Vector3(side.x, 0.0, side.y)).normalized()
		_quad(Vector3(top.x - side.x, y_top, top.y - side.y), Vector3(top.x + side.x, y_top, top.y + side.y),
				Vector3(end.x + side.x, tie.y, end.y + side.y), Vector3(end.x - side.x, tie.y, end.y - side.y),
				n if n.y > 0.0 else -n, TR_CRANE.darkened(0.1))
	_prism(_rect(0.0, 0.0, 0.25, 0.25), g + h + 8.0, g + h + 8.6, DUSK_RED, DUSK_RED, M_LAMP, M_LAMP)
	_mode = M_STONE


## The Tomb of the Unknown Soldier: the three arches left of the Saxon Palace's colonnade (blown
## up in 1944). A granite platform, two rows of four stone piers, round arches on both long
## faces, the entablature and its cornice over them; under the middle arch the tomb slab with
## wreaths and the eternal flame (it glows at night) on the square's side.
func _build_grob(_site: Dictionary) -> void:
	_o = GROB
	_a = GROB_AXIS
	_b = Vector2(-_a.y, _a.x)
	_g = map.terrain_height(GROB.x, GROB.y)
	var g := _g
	var light := GROB_STONE.lightened(0.06)
	_lbox(0.0, 0.0, 7.6, 4.4, g - 0.5, g + 0.3, GROB_GRANITE, M_STONE, GROB_GRANITE)
	for v: float in [-GROB_ROW, GROB_ROW]:
		for u: float in GROB_PIERS:
			_lbox(u, v, 0.65, 0.65, g + 0.3, g + 5.0, GROB_STONE, M_STONE, GROB_STONE)
			_lbox(u, v, 0.8, 0.8, g + 5.0, g + 5.35, light, M_STONE, light)
		# The arches between the piers, on the row's outer face.
		var face := v + signf(v) * 0.65
		for k in GROB_PIERS.size() - 1:
			_arch(float(GROB_PIERS[k]) + 0.65, float(GROB_PIERS[k + 1]) - 0.65, face, g + 3.6, g + 5.35, GROB_STONE)
	_lbox(0.0, 0.0, 6.3, 3.75, g + 5.35, g + 7.3, GROB_STONE, M_STONE, GROB_STONE.darkened(0.08))
	_lbox(0.0, 0.0, 6.55, 4.0, g + 7.3, g + 7.65, light, M_STONE, light.darkened(0.1))
	# The tomb, its wreaths, the flame in its bronze bowl.
	_lbox(0.0, 0.0, 1.2, 0.8, g + 0.3, g + 0.55, GROB_GRANITE.darkened(0.3), M_STONE, GROB_GRANITE.darkened(0.3))
	_lbox(-0.75, -0.95, 0.3, 0.3, g + 0.3, g + 0.6, Color("#c8323a"), M_STONE, Color("#c8323a"))
	_lbox(0.75, -0.95, 0.3, 0.3, g + 0.3, g + 0.6, Color("#f1efe8"), M_STONE, Color("#f1efe8"))
	var bowl := _w(0.0, -1.9)
	_prism(_circle(bowl, 0.35, 6), g + 0.3, g + 1.0, GROB_BRONZE, GROB_BRONZE, M_STONE, M_STONE)
	_mode = M_LAMP
	_pyramid(_circle(bowl, 0.26, 4), g + 1.0, g + 1.75, GROB_FLAME)
	_mode = M_STONE
	_collide(_rect(0.0, 0.0, 6.3, 3.7))


## A round arch's spandrel in the plane v = `v` of the local frame: the wall between y_spring
## and y_top from u0 to u1, less a half circle over the opening (six steps).
func _arch(u0: float, u1: float, v: float, y_spring: float, y_top: float, col: Color) -> void:
	var keep := _mode
	_mode = M_STONE
	var r := (u1 - u0) * 0.5
	var cu := (u0 + u1) * 0.5
	var n2 := _b * signf(v)
	var n := Vector3(n2.x, 0.0, n2.y)
	var steps := 6
	var at := func(u: float, y: float) -> Vector3:
		var p := _w(u, v)
		return Vector3(p.x, y, p.y)
	var uv := func(u: float, y: float) -> Vector2: return Vector2(u - u0, y - _g)
	var top := y_top - _g
	var prev := Vector2(u0, y_spring)
	for k in range(1, steps + 1):
		var ang := PI - PI * k / steps
		var cur := Vector2(cu + cos(ang) * r, y_spring + sin(ang) * r)
		var corner := Vector2(u0 if k * 2 <= steps else u1, y_top)
		_tri(at.call(corner.x, corner.y), at.call(prev.x, prev.y), at.call(cur.x, cur.y), n, col,
				uv.call(corner.x, corner.y), uv.call(prev.x, prev.y), uv.call(cur.x, cur.y), top)
		prev = cur
	_tri(at.call(u0, y_top), at.call(cu, y_spring + r), at.call(u1, y_top), n, col,
			uv.call(u0, y_top), uv.call(cu, y_spring + r), uv.call(u1, y_top), top)
	_mode = keep


# --- Plac Piłsudskiego, part 2 (2026-10-31) ---------------------------------------------------

## The square's other edges. The Metropolitan (its mapped outline; it wore the towers' fin skin
## since the landmarks loop) and Hotel Wiktoria (the parody name of the 1976 hotel on Królewska,
## mapped as an outline only: GUGiK's LoD2 draws it, OpenStreetMap has no building there) are
## models; the Królewska edge's blocks keep their LoD2 or OpenStreetMap shapes in their own
## stone (`skin_at`). Heights: the Metropolitan's are the mapped parts' (building:levels);
## the hotel's are estimates (docs/DEVELOPMENT.md says which).
##
## The Metropolitan (Foster + Partners, 2003): three seven-storey blocks round a circular
## courtyard, joined over three passages; the curved fronts are glass behind close vertical
## granite fins; the seventh storey stands back; a round fountain in the courtyard's floor.
const METRO_COURT := Vector2(-800.3, -932.0)   # the courtyard's centre (the blocks' inner arcs)
const METRO_COURT_R := 25.4
## The three passages into the courtyard: the middles of the bridges mapped over them (6.6 m up).
const METRO_GATES := [Vector2(-806.8, -900.0), Vector2(-826.5, -949.5), Vector2(-775.2, -947.6)]
## The three blocks' plant rooms (the mapped 23.1-27.4 m parts), by their middles.
const METRO_BLOCKS := [Vector2(-832.6, -921.6), Vector2(-804.6, -963.0), Vector2(-775.4, -909.0)]
const METRO_H := 20.8          # the fin walls' top (mapped: six storeys)
const METRO_RING_H := 24.1     # the seventh storey (mapped), METRO_SETBACK behind the fins
const METRO_TOP_H := 27.4      # the plant rooms (mapped)
const METRO_SETBACK := 2.0
const METRO_GATE_H := 6.6
const METRO_GATE_W := 6.0
const METRO_FIN_STEP := 1.8    # the fins: one every 1.8 m round the fronts, 0.34 m thick, 0.9 m deep
const METRO_FIN_W := 0.34
const METRO_FIN_D := 0.9
const METRO_GRANITE := Color("#bfb8ac")
const METRO_GLASS := Color("#5d6c73")
const METRO_ROOF := Color("#9a9a96")
const METRO_PAVING := Color("#aaa59c")
const METRO_GATE := Color("#2a2d30")
const METRO_POOL := Color("#47606c")
const METRO_JET := Color("#e4eff2")
## Hotel Wiktoria: a 1970s slab on a podium. The slab runs along the Królewska front (the north
## edge of its outline) WIKTORIA_SLAB_D deep, in ribbon windows of bronze-tinted glass between
## pale spandrel bands (S_BANDS); the podium fills the outline in dark glass (S_DARK, its lobby
## lit at night) under a stone fascia; a plant room on the slab.
const WIKTORIA_H := 30.0          # the slab's roof: an estimate (nine storeys over the podium's two)
const WIKTORIA_PODIUM_H := 8.0    # the podium's fascia: an estimate
const WIKTORIA_SLAB_D := 18.0     # the slab's depth: an estimate (a double-loaded hotel floor)
const WIKTORIA_GLASS := Color("#4c4640")
const WIKTORIA_DARK := Color("#3c3b3a")
const WIKTORIA_STONE := Color("#cdc9c0")
const WIKTORIA_ROOF := Color("#8d8c88")
## The Królewska edge, kept as LoD2 (or OpenStreetMap) draws it but in its own stone: by name
## (the landmark outlines), and the unnamed block on the square's south-east corner by a point in
## its west wing (`bake_sectors.py` SITE_AREAS carries it; no card, so not on the picking grid).
## `mode` M_MONUMENT draws tall windows between piers, a value under 1 the city's plain windows
## with that seed (Dom bez Kantów's modernist rows).
const PLAC_SKINS := [
	{"key": "bez_kantow", "osm": "Dom Bez Kantów", "mode": 0.37, "wall": "#d3cec2", "roof": "#85837e"},
	{"key": "departament", "osm": "Departament Wojskowej Służby Zdrowia", "mode": M_MONUMENT, "wall": "#dccfb2", "roof": "#7c7871"},
]
const KROLEWSKA_BLOCK := Vector2(-660.0, -790.0)
const KROLEWSKA_WALL := Color("#d9d0bb")
const KROLEWSKA_ROOF := Color("#7f7c76")
## The far skyline's colour of each (sector_proxies.gd, through `tower_colour`).
const PLAC_WALLS := {"metropolitan": "#8a979c", "wiktoria": "#6f6b66", "europejski": "#e7ddc5",
		"grob": "#ddd3bf", "bez_kantow": "#d3cec2", "departament": "#dccfb2", "krolewska": "#d9d0bb"}


func _find_plac2() -> void:
	var metro := _landmark("Metropolitan")
	if metro.size() >= 3:
		_add_site("metropolitan", [metro])
		if not sites.is_empty() and sites[-1]["key"] == "metropolitan":
			sites[-1]["ring"] = _simplify(metro, 0.4)
	var hotel := _landmark("Sofitel Victoria")
	if hotel.size() >= 3:
		_add_site("wiktoria", [hotel])
		if not sites.is_empty() and sites[-1]["key"] == "wiktoria":
			sites[-1]["ring"] = _simplify(hotel, 0.8)
	for t: Dictionary in PLAC_SKINS:
		var outline := _landmark(t["osm"])
		if outline.size() < 3:
			continue
		_add_site(t["key"], [outline])
		if not sites.is_empty() and sites[-1]["key"] == t["key"]:
			sites[-1]["skin"] = {"mode": t["mode"], "wall": Color(t["wall"]), "roof": Color(t["roof"])}
	for bld in data["buildings"]:
		var q := _pts(bld["p"])
		if q.size() >= 4 and float(bld["h"]) >= 8.0 and _box_of([q]).has_point(KROLEWSKA_BLOCK) \
				and Geometry2D.is_point_in_polygon(KROLEWSKA_BLOCK, q):
			_add_site("krolewska", [q])
			if not sites.is_empty() and sites[-1]["key"] == "krolewska":
				sites[-1]["skin"] = {"mode": M_MONUMENT, "wall": KROLEWSKA_WALL, "roof": KROLEWSKA_ROOF}
			return


## Hotel Metropol (the Rondo night photos, 2026-10-31): the building stays the map's own; its
## roof carries a green neon name, a parody (METROPOLKA), on the south and east faces. A site
## with no card, so it is not on the picking grid.
func _build_metropol_sign(_site: Dictionary) -> void:
	var outline := _box_poly(_box_of([_landmark("Hotel Metropol")]))
	var g := _ground_under(outline)
	var top := 0.0
	for bld in _parts_in(outline, func(_b: Dictionary) -> bool: return true):
		top = maxf(top, float(bld["h"]))
	if top < 20.0:
		return
	_crown_signs(outline, g + top + 3.0, "METROPOLKA", Color(0.18, 1.0, 0.36), 0.0, 0.7)


func _box_poly(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


## The Metropolitan: the outline's fronts in glass (M_GLASS) behind granite fins standing out
## from the ground to the parapet; the courtyard's wall in glass with painted fins (S_FINS: seen
## only from above); dark openings where the three passages go through, under a granite lintel;
## a flat roof with a parapet; the seventh storey set back, the three plant rooms on top; in the
## courtyard the paving and the round fountain with its jets.
func _build_metropolitan(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var court := _circle(METRO_COURT, METRO_COURT_R, 40)
	_prism(ring, g - 0.6, g + METRO_H, METRO_GLASS, none, M_GLASS)
	_inside_wall(court, g - 0.6, g + METRO_H, METRO_GLASS, M_SKIN + S_FINS / 16.0)
	_mode = M_STONE
	_cap_holes(ring, [court], g + METRO_H, METRO_ROOF)
	_parapet(ring, g + METRO_H, 0.9, METRO_GRANITE)
	_parapet(court, g + METRO_H, 0.9, METRO_GRANITE)
	# The passages: where each meets the outer front and the courtyard.
	var doors := PackedVector2Array()
	for gate: Vector2 in METRO_GATES:
		var d := (gate - METRO_COURT).normalized()
		var t := Vector2(-d.y, d.x)
		var p := _exit_point(ring, METRO_COURT, d, 120.0)
		doors.append(p)
		var half := METRO_GATE_W * 0.5
		_mode = M_STONE
		_wall(p + d * 0.45 - t * half, p + d * 0.45 + t * half, g - 0.6, g + METRO_GATE_H, d, METRO_GATE)
		_wall(p + d * 0.95 - t * (half + 0.6), p + d * 0.95 + t * (half + 0.6), g + METRO_GATE_H, g + METRO_GATE_H + 0.9, d, METRO_GRANITE)
		var q := METRO_COURT + d * (METRO_COURT_R - 0.3)
		_wall(q - t * half, q + t * half, g - 0.6, g + METRO_GATE_H, -d, METRO_GATE)
	_fins(ring, g - 0.6, g + METRO_H + 0.9, METRO_FIN_STEP, METRO_FIN_W, METRO_FIN_D, METRO_GRANITE, doors,
			METRO_GATE_W * 0.5 + 0.8)
	# The seventh storey, set back from the fins and from the courtyard.
	var upper := _largest(Geometry2D.offset_polygon(ring, -METRO_SETBACK, Geometry2D.JOIN_MITER))
	var court2 := _circle(METRO_COURT, METRO_COURT_R + METRO_SETBACK, 40)
	var light := METRO_GLASS.lightened(0.1)
	if upper.size() >= 3:
		_prism(upper, g + METRO_H, g + METRO_RING_H, light, none, M_GLASS)
		_inside_wall(court2, g + METRO_H, g + METRO_RING_H, light, M_GLASS)
		_mode = M_STONE
		_cap_holes(upper, [court2], g + METRO_RING_H, METRO_ROOF.lightened(0.05))
		_parapet(upper, g + METRO_RING_H, 0.6, METRO_GRANITE)
		# The plant rooms: each block's outer part, inside a wedge round its middle.
		var inner := _largest(Geometry2D.offset_polygon(ring, -6.0, Geometry2D.JOIN_MITER))
		var core := _circle(METRO_COURT, METRO_COURT_R + 10.0, 24)
		for mid: Vector2 in METRO_BLOCKS:
			var d := (mid - METRO_COURT).normalized()
			var wedge := PackedVector2Array([METRO_COURT, METRO_COURT + d.rotated(-0.45) * 120.0,
					METRO_COURT + d * 120.0, METRO_COURT + d.rotated(0.45) * 120.0])
			for piece in Geometry2D.intersect_polygons(inner, wedge):
				for part in Geometry2D.clip_polygons(piece, core):
					if absf(_area(part)) > 40.0:
						_prism(_simplify(part, 0.4), g + METRO_RING_H, g + METRO_TOP_H, light.lightened(0.08), METRO_ROOF,
								M_GLASS, M_STONE)
	# The courtyard: its paving, the round fountain and its jets.
	var gc: float = map.terrain_height(METRO_COURT.x, METRO_COURT.y)
	_mode = M_STONE
	_cap(court, gc + 0.04, METRO_PAVING)
	_prism(_circle(METRO_COURT, 7.0, 24), gc - 0.2, gc + 0.22, METRO_GRANITE, METRO_POOL, M_STONE, M_STONE)
	for k in 8:
		var j := METRO_COURT + Vector2.from_angle(TAU * k / 8.0) * 4.2
		_beam(Vector3(j.x, gc + 0.22, j.y), Vector3(j.x, gc + 1.7, j.y), 0.14, METRO_JET)
	_collide(ring)


## A wall round the inside of a ring (a courtyard), facing its middle, in `mode`.
func _inside_wall(ring: PackedVector2Array, y0: float, y1: float, col: Color, mode: float) -> void:
	var keep := _mode
	_mode = mode
	var run := 0.0
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		_wall(a, b, y0, y1, -_out(ring, a, b), col, run)
		run += a.distance_to(b)
	_mode = keep


## Where a ray from `c` along `d` last crosses a ring (its outer front), within `reach`.
func _exit_point(ring: PackedVector2Array, c: Vector2, d: Vector2, reach: float) -> Vector2:
	var best := c + d * reach
	var far := -1.0
	for i in ring.size():
		var hit: Variant = Geometry2D.segment_intersects_segment(c, c + d * reach, ring[i], ring[(i + 1) % ring.size()])
		if hit != null and (hit as Vector2).distance_to(c) > far:
			far = (hit as Vector2).distance_to(c)
			best = hit
	return best


## The biggest of some polygons (an offset ring can break into pieces).
func _largest(polys: Array) -> PackedVector2Array:
	var best := PackedVector2Array()
	var size := 0.0
	for p: PackedVector2Array in polys:
		if absf(_area(p)) > size:
			size = absf(_area(p))
			best = p
	return best


## Vertical fins standing `depth` out from a ring's walls, one every `step` metres along it,
## `w` thick, from y0 to y1, with a top; none within `gap` of a point in `skip` (a doorway).
func _fins(ring: PackedVector2Array, y0: float, y1: float, step: float, w: float, depth: float, col: Color,
		skip: PackedVector2Array, gap: float) -> void:
	var keep := _mode
	_mode = M_STONE
	var next := step * 0.5   # where the next fin stands, from the start of the current edge
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		var length := a.distance_to(b)
		if length < 0.01:
			continue
		var e := (b - a) / length
		var out := _out(ring, a, b)
		while next <= length:
			var p := a + e * next
			next += step
			var clear := true
			for s in skip:
				if p.distance_to(s) < gap:
					clear = false
					break
			if not clear:
				continue
			var p0 := p - e * w * 0.5
			var p1 := p + e * w * 0.5
			var q0 := p0 + out * depth
			var q1 := p1 + out * depth
			_wall(p0, q0, y0, y1, -e, col)
			_wall(q0, q1, y0, y1, out, col)
			_wall(q1, p1, y0, y1, e, col)
			_quad(Vector3(p0.x, y1, p0.y), Vector3(q0.x, y1, q0.y), Vector3(q1.x, y1, q1.y), Vector3(p1.x, y1, p1.y),
					Vector3.UP, col.lightened(0.06))
		next -= length
	_mode = keep


## Hotel Wiktoria: the podium over the whole outline in dark glass under a stone fascia, the
## slab along the Królewska front in ribbon windows, a parapet and a plant room on it.
func _build_wiktoria(site: Dictionary) -> void:
	var ring: PackedVector2Array = site["ring"]
	_g = _ground_under(ring)
	var g := _g
	var none := Color(0, 0, 0, 0)
	# The frame: u east along the longest front facing north (Królewska), v south into the plot.
	_a = Vector2.RIGHT
	var longest := 0.0
	for i in ring.size():
		var a := ring[i]
		var b := ring[(i + 1) % ring.size()]
		if _out(ring, a, b).y < -0.7 and a.distance_to(b) > longest:
			longest = a.distance_to(b)
			_a = (b - a).normalized() * (1.0 if b.x >= a.x else -1.0)
	_b = Vector2(-_a.y, _a.x)
	_o = _centre(ring)
	var lo := Vector2(INF, INF)
	var hi := -lo
	for q in ring:
		lo = lo.min(_local(q))
		hi = hi.max(_local(q))
	# The podium and its fascia.
	_prism(ring, g - 0.6, g + WIKTORIA_PODIUM_H, WIKTORIA_DARK, none, M_SKIN + S_DARK / 16.0)
	var eave := _largest(Geometry2D.offset_polygon(ring, 0.4, Geometry2D.JOIN_MITER))
	_prism(eave if eave.size() >= 3 else ring, g + WIKTORIA_PODIUM_H, g + WIKTORIA_PODIUM_H + 0.9,
			WIKTORIA_STONE, WIKTORIA_ROOF, M_STONE, M_STONE)
	# The slab: the outline's northern strip, a little in from its fronts.
	var y0 := g + WIKTORIA_PODIUM_H + 0.9
	var strip := PackedVector2Array([_wl(Vector2(lo.x - 1.0, lo.y - 1.0)), _wl(Vector2(hi.x + 1.0, lo.y - 1.0)),
			_wl(Vector2(hi.x + 1.0, lo.y + WIKTORIA_SLAB_D)), _wl(Vector2(lo.x - 1.0, lo.y + WIKTORIA_SLAB_D))])
	var inner := _largest(Geometry2D.offset_polygon(ring, -1.5, Geometry2D.JOIN_MITER))
	for piece in Geometry2D.intersect_polygons(inner, strip):
		if absf(_area(piece)) < 300.0:
			continue
		var slab := _simplify(piece, 0.8)
		_prism(slab, y0, g + WIKTORIA_H, WIKTORIA_GLASS, WIKTORIA_ROOF, M_SKIN + S_BANDS / 16.0, M_STONE)
		_parapet(slab, g + WIKTORIA_H, 1.0, WIKTORIA_STONE)
		var c := _local(_centre(slab))
		_prism(_rect(c.x, c.y, 9.0, 4.0), g + WIKTORIA_H, g + WIKTORIA_H + 3.2, WIKTORIA_ROOF.lightened(0.08),
				WIKTORIA_ROOF, M_STONE, M_STONE)
	_collide(ring)


# --- Plac Małachowskiego and the Presidential Palace (2026-10-31) ------------------------------

## Three named buildings brought from skins (or LoD2 alone) to models, each to its spec in
## docs/landmarks/specs/ (trojca.md, zacheta.md, prezydencki.md). Measured in a cloud thread from
## the OpenStreetMap outlines, GUGiK's LoD2 heights and the user's photo of Zachęta (with the
## church's dome beside it); the values the specs mark *(photo check)* wait for the Mac's photos.
##
## Holy Trinity (Kościół Ewangelicko-Augsburski Świętej Trójcy, Szymon Bogumił Zug, 1777-1781):
## a white rotunda on a Greek-cross plan, a Tuscan portico of four columns under a pediment on
## each arm, a low copper dome and a tall columned lantern with a cross. The drum's centre and
## radius are a circle fitted to its mapped outline; the arms' faces are the outline's.
const TROJCA := Vector2(-854.6, -508.6)
const TROJCA_TURN := -24.6      # degrees: the arm towards the square (ENE)
const TROJCA_R := 16.7
## Each arm: its turn from TROJCA_TURN and how far its portico's front stands from the centre.
const TROJCA_ARMS := [[0.0, 21.8], [90.0, 24.1], [180.0, 21.7], [270.0, 21.3]]
## The dome's profile over the drum's attic: [radius, height above ground] (LoD2: 28.6 m at r 14.5,
## 36 m at r 8, the lantern from 37 m to 49 m, its cap to 52 m; 58 m to the cross's top).
const TROJCA_DOME := [[16.4, 26.5], [15.3, 28.8], [13.4, 31.3], [10.9, 33.6], [8.0, 35.6], [5.7, 36.7]]
const TROJCA_WHITE := Color("#e9e7e1")
const TROJCA_PLINTH := Color("#a9a59d")
const TROJCA_COPPER := Color("#6f9f8f")
const TROJCA_COPPER_DARK := Color("#4f7d70")
const TROJCA_GLASS := Color("#3c4a52")
const TROJCA_GOLD := Color("#c9a24a")


func _find_trojca() -> void:
	_add_site("trojca", [_circle(TROJCA, 25.5, 24)])


func _build_trojca(_site: Dictionary) -> void:
	var c := TROJCA
	var r := TROJCA_R
	_g = _ground_under(_circle(c, r, 8))
	var g := _g
	var none := Color(0, 0, 0, 0)
	var light := TROJCA_WHITE.lightened(0.06)
	# plinth, drum_low, band, drum_high, cornice, attic
	_prism(_circle(c, r + 0.3, 32), g - 0.5, g + 1.2, TROJCA_PLINTH, TROJCA_PLINTH, M_STONE, M_STONE)
	_prism(_circle(c, r, 32), g + 1.2, g + 15.0, TROJCA_WHITE, none, M_MONUMENT)
	_prism(_circle(c, r + 0.35, 32), g + 15.0, g + 15.8, light, light, M_STONE, M_STONE)
	_prism(_circle(c, r, 32), g + 15.8, g + 24.5, TROJCA_WHITE, none, M_STONE)
	_prism(_circle(c, r + 0.45, 32), g + 24.5, g + 25.3, light, light, M_STONE, M_STONE)
	_prism(_circle(c, r, 32), g + 25.3, g + 26.5, TROJCA_WHITE, TROJCA_WHITE.darkened(0.1), M_STONE, M_STONE)
	# oculi: one round window on every other facet of the upper drum
	for k in range(0, 32, 2):
		var mid := (TAU * (k + 0.5) / 32.0 + TAU * (k + 1.5) / 32.0) * 0.5
		var d := Vector2.from_angle(mid)
		var inset := r * cos(PI / 32.0) + 0.06
		var p := c + d * inset
		_disc(Vector3(p.x, g + 20.0, p.y), Vector3(d.x, 0.0, d.y), 1.1, 8, TROJCA_GLASS)
	# dome
	_mode = M_STONE
	for k in TROJCA_DOME.size() - 1:
		var a: Array = TROJCA_DOME[k]
		var b: Array = TROJCA_DOME[k + 1]
		var col := TROJCA_COPPER.lerp(TROJCA_COPPER.lightened(0.12), float(k) / TROJCA_DOME.size())
		_frustum(_circle(c, a[0], 32), g + float(a[1]), _circle(c, b[0], 32), g + float(b[1]), col)
	# lantern: its balustrade, the columned drum, a cornice, the cap, ball and cross
	_prism(_circle(c, 5.9, 16), g + 36.6, g + 37.6, TROJCA_COPPER_DARK, TROJCA_COPPER_DARK, M_STONE, M_STONE)
	_prism(_circle(c, 4.6, 16), g + 37.6, g + 46.0, TROJCA_COPPER, none, M_MONUMENT)
	_prism(_circle(c, 5.1, 16), g + 46.0, g + 46.7, TROJCA_COPPER_DARK, none, M_STONE)
	_mode = M_STONE
	_frustum(_circle(c, 5.1, 16), g + 46.7, _circle(c, 3.8, 16), g + 48.6, TROJCA_COPPER)
	_frustum(_circle(c, 3.8, 16), g + 48.6, _circle(c, 1.7, 16), g + 49.9, TROJCA_COPPER.lightened(0.06))
	_frustum(_circle(c, 1.7, 16), g + 49.9, _circle(c, 0.3, 16), g + 50.4, TROJCA_COPPER.lightened(0.1), TROJCA_COPPER)
	_prism(_circle(c, 0.4, 6), g + 50.4, g + 51.1, TROJCA_GOLD, TROJCA_GOLD, M_STONE, M_STONE)
	_o = c
	_a = Vector2.from_angle(deg_to_rad(TROJCA_TURN))
	_b = Vector2(-_a.y, _a.x)
	_lbox(0.0, 0.0, 0.11, 0.11, g + 51.1, g + 55.6, TROJCA_GOLD, M_STONE, TROJCA_GOLD)
	_lbox(0.0, 0.0, 0.11, 0.75, g + 54.0, g + 54.24, TROJCA_GOLD, M_STONE, TROJCA_GOLD)
	# arms: a vestibule, the stylobate, four Tuscan columns, the entablature and the pediment
	var ring := _circle(c, r + 0.3, 32)
	for arm: Array in TROJCA_ARMS:
		_o = c
		_a = Vector2.from_angle(deg_to_rad(TROJCA_TURN + float(arm[0])))
		_b = Vector2(-_a.y, _a.x)
		var face: float = arm[1]
		var back := face - 4.4
		_lbox((r - 2.0 + back) * 0.5, 0.0, (back - r + 2.0) * 0.5, 6.0, g - 0.5, g + 12.5, TROJCA_WHITE, M_MONUMENT, TROJCA_WHITE.darkened(0.1))
		_lbox(back + 2.2, 0.0, 2.2, 6.8, g - 0.5, g + 0.6, TROJCA_PLINTH, M_STONE, TROJCA_PLINTH.lightened(0.1))
		for v: float in [-4.6, -1.55, 1.55, 4.6]:
			_column(face - 1.0, v, 0.55, g + 0.6, g + 10.7, TROJCA_WHITE)
		_lbox(back + 2.25, 0.0, 2.25, 6.6, g + 10.7, g + 12.5, light, M_STONE, TROJCA_WHITE.darkened(0.1))
		_gable(face + 0.05, r - 2.0, 0.0, 6.7, g + 12.5, 3.4, TROJCA_WHITE, TROJCA_COPPER_DARK, false)
		var arm_ring := _rect((r - 2.0 + face) * 0.5, 0.0, (face - r + 2.0) * 0.5, 6.8)
		var merged := Geometry2D.merge_polygons(ring, arm_ring)
		if not merged.is_empty():
			ring = _largest(merged)
	_collide(ring)


## A column on a local spot: a square plinth, an octagonal shaft and a square capital (Tuscan).
func _column(cu: float, cv: float, r: float, y0: float, y1: float, col: Color) -> void:
	var none := Color(0, 0, 0, 0)
	var base := minf(0.45, (y1 - y0) * 0.05)
	_prism(_rect(cu, cv, r * 1.35, r * 1.35), y0, y0 + base, col.darkened(0.04), col.darkened(0.08), M_STONE, M_STONE)
	_prism(_circle(_w(cu, cv), r, 8), y0 + base, y1 - base, col, none, M_STONE)
	_prism(_rect(cu, cv, r * 1.4, r * 1.4), y1 - base, y1, col.lightened(0.05), none, M_STONE)


## A gable in the local frame: the pediment's triangle on the plane u = uf (facing away from
## ub), from v = cv - hv to cv + hv, base y, apex y + h, and its two roof slopes back to u = ub,
## closed there by a second triangle when `back` (none when it ends inside a wall).
func _gable(uf: float, ub: float, cv: float, hv: float, y: float, h: float, face: Color, roof: Color, back := true) -> void:
	var keep := _mode
	_mode = M_STONE
	var s := signf(uf - ub)
	var at := func(u: float, v: float, yy: float) -> Vector3:
		var p := _w(u, v)
		return Vector3(p.x, yy, p.y)
	var front := Vector3(_a.x * s, 0.0, _a.y * s)
	var top := y + h - _g
	var y0 := y - _g
	var l: Vector3 = at.call(uf, cv - hv, y)
	var rr: Vector3 = at.call(uf, cv + hv, y)
	var apex: Vector3 = at.call(uf, cv, y + h)
	var lb: Vector3 = at.call(ub, cv - hv, y)
	var rb: Vector3 = at.call(ub, cv + hv, y)
	var apex_b: Vector3 = at.call(ub, cv, y + h)
	_tri(l, rr, apex, front, face, Vector2(0, y0), Vector2(hv * 2.0, y0), Vector2(hv, top), top)
	if back:
		_tri(lb, rb, apex_b, -front, face, Vector2(0, y0), Vector2(hv * 2.0, y0), Vector2(hv, top), top)
	for side: float in [-1.0, 1.0]:
		var e: Vector3 = l if side < 0.0 else rr
		var eb: Vector3 = lb if side < 0.0 else rb
		var n := (Vector3(_b.x, 0.0, _b.y) * side * h + Vector3.UP * hv).normalized()
		_quad(e, eb, apex_b, apex, n, roof)
	_mode = keep


## A flat round (n-sided) disc at c facing n: an oculus, a clock face.
func _disc(c: Vector3, n: Vector3, r: float, sides: int, col: Color) -> void:
	var side := Vector3.UP.cross(n).normalized()
	var top := c.y + r - _g
	for k in sides:
		var a0 := TAU * k / sides
		var a1 := TAU * (k + 1) / sides
		var p0 := c + (side * cos(a0) + Vector3.UP * sin(a0)) * r
		var p1 := c + (side * cos(a1) + Vector3.UP * sin(a1)) * r
		_tri(c, p0, p1, n, col, Vector2(r, c.y - _g), Vector2(r + cos(a0) * r, p0.y - _g),
				Vector2(r + cos(a1) * r, p1.y - _g), top)


## A hipped roof over a local rectangle: from the eaves at y up `rise` to a ridge along the
## longer side.
func _hip(cu: float, cv: float, hu: float, hv: float, y: float, rise: float, col: Color) -> void:
	var keep := _mode
	_mode = M_STONE
	var short := minf(hu, hv) - 0.15
	_frustum(_rect(cu, cv, hu, hv), y, _rect(cu, cv, hu - short, hv - short), y + rise, col, col.darkened(0.06))
	_mode = keep


## Zachęta (Stefan Szyller, 1898-1900): the white gallery on Plac Małachowskiego, its front to the
## east. A rusticated ground floor over a basement band, the upper floor of tall windows, a cornice
## and a balustrade; the end pavilions stand forward under acroteria; in the middle two pylons
## frame two giant columns before three doors, the attic with ARTIBVS over them and a pediment
## full of sculpture; steps between two candelabra. Behind, the top-lit halls under glass.
## Frame: u along the front from its north end (u < 0) to the church's side, +v out of the front.
const ZACHETA := Vector2(-833.4, -593.3)
const ZACHETA_AXIS := Vector2(0.3339, 0.9426)
const ZACHETA_BACK := -45.0
const ZACHETA_HU := Vector2(-24.0, 23.0)   # the front's ends (u)
const ZACHETA_WIN := [-20.4, -17.0, -13.4, -9.8, 9.8, 13.4, 17.0, 20.4]
const ZACHETA_DOORS := [-4.2, 0.0, 4.1]
const ZACHETA_WHITE := Color("#ebeae4")
const ZACHETA_BASE := Color("#d4d3cd")
const ZACHETA_COLUMN := Color("#b9bab5")
const ZACHETA_GLASS := Color("#3d4850")
const ZACHETA_DOOR := Color("#4a3328")
const ZACHETA_ROOF := Color("#8d9092")
const ZACHETA_SKY := Color("#9fb0b8")
const ZACHETA_SCULPT := Color("#f4f3ee")
const ZACHETA_IRON := Color("#2f3331")


func _find_zacheta() -> void:
	var outline := _landmark("Zachęta")
	if outline.size() >= 3:
		_add_site("zacheta", [outline])
		if not sites.is_empty() and sites[-1]["key"] == "zacheta":
			sites[-1]["ring"] = outline


func _build_zacheta(site: Dictionary) -> void:
	_o = ZACHETA
	_a = ZACHETA_AXIS.normalized()
	_b = Vector2(_a.y, -_a.x)
	var u0 := ZACHETA_HU.x
	var u1 := ZACHETA_HU.y
	var body := _rect((u0 + u1) * 0.5, ZACHETA_BACK * 0.5, (u1 - u0) * 0.5, -ZACHETA_BACK * 0.5)
	_g = _ground_under(body)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var light := ZACHETA_WHITE.lightened(0.05)
	# windows and doors first, so the walls behind them stay whole (they stand 7 cm proud)
	_mode = M_GLASS
	for u: float in ZACHETA_WIN:
		# the outer pair sit in the end pavilions, which stand 0.5 m forward
		var f := 0.57 if absf(u) > 20.0 else 0.07
		_wall(_w(u - 0.75, f), _w(u + 0.75, f), g + 4.2, g + 7.2, _b, ZACHETA_GLASS)
		_wall(_w(u - 0.8, f), _w(u + 0.8, f), g + 9.6, g + 13.0, _b, ZACHETA_GLASS)
		_wall(_w(u - 0.55, f), _w(u + 0.55, f), g + 0.7, g + 1.9, _b, ZACHETA_GLASS)
	for u: float in ZACHETA_DOORS:
		_wall(_w(u - 0.8, 0.07), _w(u + 0.8, 0.07), g + 9.6, g + 13.0, _b, ZACHETA_GLASS)
	_mode = M_STONE
	for u: float in ZACHETA_DOORS:
		_wall(_w(u - 0.95, 0.07), _w(u + 0.95, 0.07), g + 1.8, g + 6.8, _b, ZACHETA_DOOR)
	# body: the front in plain stone (its windows are its own), the other faces in M_MONUMENT
	var corners := [_w(u0, ZACHETA_BACK), _w(u1, ZACHETA_BACK), _w(u1, 0.0), _w(u0, 0.0)]
	var outs := [-_b, _a, _b, -_a]
	for i in 4:
		var a: Vector2 = corners[i]
		var b: Vector2 = corners[(i + 1) % 4]
		_wall(a, b, g - 0.5, g + 3.0, outs[i], ZACHETA_BASE.darkened(0.06))
		_wall(a, b, g + 3.0, g + 8.2, outs[i], ZACHETA_BASE)
		_mode = M_STONE if i == 2 else M_MONUMENT
		_wall(a, b, g + 8.2, g + 15.3, outs[i], ZACHETA_WHITE)
		_mode = M_STONE
	var band := _largest(Geometry2D.offset_polygon(body, 0.18, Geometry2D.JOIN_MITER))
	_prism(band, g + 8.2, g + 8.8, light, light, M_STONE, M_STONE)
	var eave := _largest(Geometry2D.offset_polygon(body, 0.5, Geometry2D.JOIN_MITER))
	_prism(eave, g + 14.6, g + 15.3, light, ZACHETA_ROOF, M_STONE, M_STONE)
	_parapet(body, g + 15.3, 1.3, ZACHETA_WHITE)
	# end pavilions: forward 0.5 m, an attic, an acroterion
	for p: Vector2 in [Vector2(u0 + 2.9, 0.0), Vector2(u1 - 2.9, 0.0)]:
		_lbox(p.x, 0.25, 2.9, 0.25, g - 0.5, g + 3.0, ZACHETA_BASE.darkened(0.06), M_STONE, ZACHETA_BASE)
		_lbox(p.x, 0.25, 2.9, 0.25, g + 3.0, g + 15.3, ZACHETA_WHITE, M_STONE, light)
		_lbox(p.x, -0.6, 2.4, 1.1, g + 15.3, g + 17.4, ZACHETA_WHITE, M_STONE, light)
		_pyramid(_rect(p.x, -0.6, 1.0, 0.7), g + 17.4, g + 19.2, ZACHETA_SCULPT)
	# pylons, columns on pedestals, the entablature, the ARTIBVS attic, the pediment
	for s: float in [-1.0, 1.0]:
		_lbox(s * 7.0, 0.6, 1.6, 0.6, g - 0.5, g + 17.0, ZACHETA_WHITE, M_STONE, light)
		_lbox(s * 2.2, 1.6, 0.9, 0.9, g - 0.5, g + 3.4, ZACHETA_BASE, M_STONE, ZACHETA_BASE.lightened(0.05))
		_column(s * 2.2, 1.6, 0.62, g + 3.4, g + 15.2, ZACHETA_COLUMN)
		# a candelabrum on its pedestal before each pylon
		_lbox(s * 7.0, 3.0, 0.7, 0.7, g - 0.5, g + 2.2, ZACHETA_BASE, M_STONE, ZACHETA_BASE)
		_lbox(s * 7.0, 3.0, 0.14, 0.14, g + 2.2, g + 5.6, ZACHETA_IRON, M_STONE, ZACHETA_IRON)
		_lbox(s * 7.0, 3.0, 0.7, 0.12, g + 5.0, g + 5.2, ZACHETA_IRON, M_STONE, ZACHETA_IRON)
		for k: float in [-0.7, 0.0, 0.7]:
			_mode = M_LAMP
			_prism(_rect(s * 7.0 + k, 3.0, 0.16, 0.16), g + 5.2 if k != 0.0 else g + 5.6, g + 5.6 if k != 0.0 else g + 6.0,
					Color("#f3e3b0"), Color("#f3e3b0"), M_LAMP, M_LAMP)
			_mode = M_STONE
	_lbox(0.0, 1.0, 8.6, 1.5, g + 15.2, g + 16.4, light, M_STONE, light)
	_lbox(0.0, 0.9, 8.6, 1.3, g + 16.4, g + 18.4, ZACHETA_WHITE, M_STONE, light)
	_lbox(0.0, 1.0, 9.6, 1.5, g + 18.4, g + 18.8, light, M_STONE, light)
	var keep_a := _a
	var keep_b := _b
	# The pediment faces +v: swap the frame so _gable's u runs out of the front.
	_a = keep_b
	_b = -keep_a
	_gable(2.5, -6.0, 0.0, 9.6, g + 18.8, 4.2, ZACHETA_WHITE, ZACHETA_ROOF)
	_a = keep_a
	_b = keep_b
	# the tympanum's sculpture: a tall group in the middle, lower groups to the corners
	for grp: Array in [[0.0, 1.3, 3.1], [-2.8, 1.2, 1.9], [2.8, 1.2, 1.9], [-5.6, 1.1, 0.9], [5.6, 1.1, 0.9]]:
		_lbox(grp[0], 2.65, grp[1], 0.2, g + 18.8, g + 18.8 + float(grp[2]), ZACHETA_SCULPT, M_STONE, ZACHETA_SCULPT)
	_beam(Vector3(_w(-9.8, 2.85).x, g + 18.75, _w(-9.8, 2.85).y), Vector3(_w(0.0, 2.85).x, g + 23.1, _w(0.0, 2.85).y), 0.45, light)
	# (the right one 6 cm further out: the two meet at the apex, and coplanar faces flicker)
	_beam(Vector3(_w(9.8, 2.91).x, g + 18.75, _w(9.8, 2.91).y), Vector3(_w(0.0, 2.91).x, g + 23.1, _w(0.0, 2.91).y), 0.45, light)
	# steps
	for k in 4:
		_lbox(0.0, (4.0 - k) * 0.5, 6.0, (4.0 - k) * 0.5, g - 0.5, g + 0.45 * (k + 1), ZACHETA_BASE, M_STONE,
				ZACHETA_BASE.lightened(0.04))
	# the halls behind: a raised block and its glass roof
	_lbox(-1.0, -22.0, 10.0, 14.0, g + 15.3, g + 19.0, ZACHETA_WHITE, M_STONE, none)
	_mode = M_GLASS_ROOF
	_frustum(_rect(-1.0, -22.0, 10.0, 14.0), g + 19.0, _rect(-1.0, -22.0, 0.3, 4.3), g + 23.8, ZACHETA_SKY, ZACHETA_SKY)
	_mode = M_STONE
	_collide(site["ring"])
	# the steps, the columns and the candelabra stand in front of the mapped outline
	_collide(_rect(0.0, 2.0, 7.8, 2.0))
	for s: float in [-1.0, 1.0]:
		_collide(_rect(s * 7.0, 3.0, 0.7, 0.7))


## The Presidential Palace (Pałac Prezydencki; Aigner's classical rebuilding, 1818-1819) on
## Krakowskie Przedmieście: the main block across the back of the forecourt with a portico of
## four giant columns under a pediment, two long wings to the street ending in pavilions with
## pediments, the iron fence with its gate between four stone lions on pedestals and two
## guardhouses, and Thorvaldsen's Prince Józef Poniatowski on horseback in the forecourt.
## Frame: u from the main block's front towards the street (WNW), v across (v < 0 north).
## The far skyline's colour of each (sector_proxies.gd, through `tower_colour`).
const MALACHOWSKI_WALLS := {"trojca": "#e9e7e1", "zacheta": "#ebeae4", "prezydencki": "#efe9da"}
const PREZ := Vector2(-514.0, -1005.5)
const PREZ_AXIS := Vector2(-0.9089, 0.4170)
const PREZ_WALL := Color("#efe9da")
const PREZ_BASE := Color("#ddd6c4")
const PREZ_ROOF := Color("#7d8a87")
const PREZ_BRONZE := Color("#3f4a45")
const PREZ_GRANITE := Color("#8d8a86")
const PREZ_LION := Color("#d8d2c4")
const PREZ_IRON := Color("#2f3432")
## Blocks: [cu, cv, hu, hv, eaves, roof rise] (from the outline in the frame above).
const PREZ_BLOCKS := [
	[-12.5, 0.5, 12.5, 41.5, 15.5, 5.0],   # main block
	[-19.5, 46.0, 5.5, 4.0, 12.0, 3.0],    # garden annex, south
	[42.0, -33.0, 42.0, 7.5, 10.5, 3.6],   # north wing
	[44.0, 31.5, 44.0, 8.5, 10.5, 3.6],    # south wing
]
## The wings' street pavilions: [cu, cv, hu, hv].
const PREZ_PAVILIONS := [[88.0, -33.0, 4.5, 8.1], [92.0, 31.5, 4.5, 9.1]]
const PREZ_FENCE_U := 94.0
const PREZ_STATUE := Vector2(66.0, -0.5)


func _find_prezydencki() -> void:
	var outline := _landmark("Pałac Prezydencki")
	if outline.size() < 3:
		return
	# The zone is the hull: the LoD2 model is one run round the forecourt, its centre in it.
	_add_site("prezydencki", [Geometry2D.convex_hull(outline)])
	if not sites.is_empty() and sites[-1]["key"] == "prezydencki":
		sites[-1]["ring"] = outline


func _build_prezydencki(site: Dictionary) -> void:
	_o = PREZ
	_a = PREZ_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	_g = map.terrain_height(_w(40.0, 0.0).x, _w(40.0, 0.0).y)
	var g := _g
	var none := Color(0, 0, 0, 0)
	var light := PREZ_WALL.lightened(0.05)
	for blk: Array in PREZ_BLOCKS:
		var cu: float = blk[0]
		var cv: float = blk[1]
		var hu: float = blk[2]
		var hv: float = blk[3]
		var top: float = blk[4]
		_lbox(cu, cv, hu, hv, g - 0.6, g + 4.0, PREZ_BASE, M_STONE, none)
		_lbox(cu, cv, hu, hv, g + 4.0, g + top, PREZ_WALL, M_MONUMENT, none)
		_prism(_largest(Geometry2D.offset_polygon(_rect(cu, cv, hu, hv), 0.4, Geometry2D.JOIN_MITER)),
				g + top - 0.2, g + top + 0.5, light, PREZ_ROOF.lightened(0.1), M_STONE, M_STONE)
		_hip(cu, cv, hu - 0.3, hv - 0.3, g + top + 0.5, blk[5], PREZ_ROOF)
	# the street pavilions: a storey higher than the wings, a pediment to the street
	for p: Array in PREZ_PAVILIONS:
		var cu: float = p[0]
		var cv: float = p[1]
		var hu: float = p[2]
		var hv: float = p[3]
		_lbox(cu, cv, hu, hv, g - 0.6, g + 4.0, PREZ_BASE, M_STONE, none)
		_lbox(cu, cv, hu, hv, g + 4.0, g + 12.0, PREZ_WALL, M_MONUMENT, none)
		_lbox(cu, cv, hu + 0.3, hv + 0.3, g + 12.0, g + 12.7, light, M_STONE, PREZ_ROOF.lightened(0.1))
		_gable(cu + hu + 0.3, cu - hu - 0.3, cv, hv + 0.3, g + 12.7, 3.2, PREZ_WALL, PREZ_ROOF)
	# the portico: a rusticated base, four giant columns, the entablature and the pediment
	_lbox(2.0, 0.0, 2.0, 9.5, g - 0.6, g + 4.0, PREZ_BASE, M_STONE, PREZ_BASE.lightened(0.05))
	for v: float in [-6.9, -2.3, 2.3, 6.9]:
		_column(3.0, v, 0.6, g + 4.0, g + 15.5, PREZ_WALL)
	_lbox(2.1, 0.0, 2.1, 9.6, g + 15.5, g + 16.7, light, M_STONE, PREZ_ROOF.lightened(0.1))
	_gable(4.2, -3.0, 0.0, 9.6, g + 16.7, 3.8, PREZ_WALL, PREZ_ROOF)
	# the fence along the street with the gate open in the middle, posts every few metres
	for span: Vector2 in [Vector2(-25.0, -6.0), Vector2(6.0, 22.5)]:
		var a := _w(PREZ_FENCE_U, span.x)
		var b := _w(PREZ_FENCE_U, span.y)
		for y: float in [0.35, 1.95]:
			_beam(Vector3(a.x, g + y, a.y), Vector3(b.x, g + y, b.y), 0.08, PREZ_IRON)
		var n := ceili((span.y - span.x) / 3.2)
		for k in n + 1:
			var v := lerpf(span.x, span.y, float(k) / n)
			_lbox(PREZ_FENCE_U, v, 0.04, 0.04, g - 0.3, g + 2.1, PREZ_IRON, M_STONE, PREZ_IRON)
		_collide(_rect(PREZ_FENCE_U, (span.x + span.y) * 0.5, 0.15, (span.y - span.x) * 0.5))
	# the lions on their pedestals by the gate, looking out to the street
	for v: float in [-9.4, -6.0, 6.0, 9.4]:
		_lbox(PREZ_FENCE_U, v, 0.9, 0.6, g - 0.4, g + 2.2, PREZ_BASE, M_STONE, PREZ_BASE.lightened(0.05))
		_lbox(PREZ_FENCE_U - 0.15, v, 0.75, 0.32, g + 2.2, g + 2.75, PREZ_LION, M_STONE, PREZ_LION)
		_lbox(PREZ_FENCE_U + 0.5, v, 0.28, 0.3, g + 2.75, g + 3.25, PREZ_LION, M_STONE, PREZ_LION.lightened(0.05))
		_collide(_rect(PREZ_FENCE_U, v, 0.9, 0.6))
	# the guardhouses inside the gate
	for v: float in [-15.5, 14.0]:
		_lbox(88.5, v, 2.2, 2.2, g - 0.5, g + 4.2, PREZ_WALL, M_MONUMENT, none)
		_lbox(88.5, v, 2.45, 2.45, g + 4.2, g + 4.6, light, M_STONE, PREZ_ROOF)
		_mode = M_STONE
		_pyramid(_rect(88.5, v, 2.3, 2.3), g + 4.6, g + 6.2, PREZ_ROOF)
		_collide(_rect(88.5, v, 2.2, 2.2))
	# Poniatowski: the granite pedestal, the horse stepping towards the street, the rider
	var su := PREZ_STATUE.x
	var sv := PREZ_STATUE.y
	_lbox(su, sv, 3.0, 1.6, g - 0.4, g + 0.6, PREZ_GRANITE, M_STONE, PREZ_GRANITE.lightened(0.05))
	_lbox(su, sv, 2.5, 1.15, g + 0.6, g + 3.6, PREZ_GRANITE.lightened(0.12), M_STONE, none)
	_lbox(su, sv, 2.7, 1.3, g + 3.6, g + 3.95, PREZ_GRANITE, M_STONE, PREZ_GRANITE.lightened(0.05))
	for leg: Vector2 in [Vector2(-0.95, -0.25), Vector2(-0.95, 0.25), Vector2(0.85, -0.25), Vector2(0.95, 0.25)]:
		_lbox(su + leg.x, sv + leg.y, 0.09, 0.09, g + 3.95, g + 5.15, PREZ_BRONZE, M_STONE, none)
	_lbox(su, sv, 1.15, 0.38, g + 5.0, g + 6.0, PREZ_BRONZE, M_STONE, PREZ_BRONZE.lightened(0.06))
	var neck0 := _w(su + 0.95, sv)
	var neck1 := _w(su + 1.55, sv)
	_beam(Vector3(neck0.x, g + 5.75, neck0.y), Vector3(neck1.x, g + 6.75, neck1.y), 0.36, PREZ_BRONZE)
	_lbox(su + 1.75, sv, 0.32, 0.14, g + 6.35, g + 6.75, PREZ_BRONZE, M_STONE, PREZ_BRONZE)
	_lbox(su - 0.1, sv, 0.26, 0.3, g + 6.0, g + 7.15, PREZ_BRONZE, M_STONE, PREZ_BRONZE)
	_lbox(su - 0.1, sv, 0.13, 0.13, g + 7.15, g + 7.5, PREZ_BRONZE, M_STONE, PREZ_BRONZE)
	var arm0 := _w(su + 0.05, sv - 0.32)
	var arm1 := _w(su + 1.2, sv - 0.4)
	_beam(Vector3(arm0.x, g + 6.95, arm0.y), Vector3(arm1.x, g + 7.7, arm1.y), 0.09, PREZ_BRONZE)
	_collide(_rect(su, sv, 3.0, 1.6))
	_collide(site["ring"])


# --- Centrum Nauki Kopernik ---------------------------------------------------------------------

## The Copernicus Science Centre on Wybrzeże Kościuszkowskie (RAr-2, opened 2010; spec
## docs/landmarks/specs/kopernik.md, 2026-11-01): one long dark block over the Wisłostrada
## tunnel, as big as its outline and as tall as GUGiK's LoD2 roof (13 m over the street; OSM
## says 7.6), its walls dark grey-brown panels with windows scattered over them like pixels,
## lit warm at night. The river corner hangs over a glazed ground floor (OSM's part from 3.3 m),
## the west corner and the link to the planetarium are low glass wings, and the flat roof is a
## garden: raised lawns between paved paths. Beside it the planetarium (2011): a black faceted
## boulder, lower than the centre's roof.
const KOP_ROOF := 13.0           # the roof over the street on the city side (LoD2)
const KOP_LIFT := 5.0            # the river corner's soffit over its own ground (OSM 3.3 of 7.6, scaled)
const KOP_LOW := 4.5             # the low glass wings over the street
const KOP_PLANET_WALL := 6.5     # the planetarium's upright walls, then its facets
const KOP_PLANET_TOP := 11.5     # its apex over its own ground (photo check)
const KOP_PATH_AXIS := Vector2(0.6248, 0.7810)  # the long city front, to the south-east
const KOP_WALL := Color("#5f5a54")
const KOP_PANEL := Color("#57524c")  # the parapet's darker band
const KOP_WINDOW := Color("#3b4347")
const KOP_LIT := Color("#8fa3a8")    # the glazed wings and the ground floor under the overhang
const KOP_DECK := Color("#a49e92")   # the roof's paths
const KOP_KERB := Color("#7d786e")
const KOP_LAWN := Color("#6f9a4c")
const KOP_MEADOW := Color("#87a659")
const KOP_PLANET := Color("#24272b")
const KOP_PLANET_FACET := Color("#30343a")


func _find_kopernik() -> void:
	var outline := _landmark("Centrum Nauki Kopernik")
	if outline.size() < 3:
		return
	var planet := _landmark("Planetarium Niebo Kopernika")
	_add_site("kopernik", [outline, planet])
	if sites.is_empty() or sites[-1]["key"] != "kopernik":
		return
	var site: Dictionary = sites[-1]
	site["ring"] = outline
	site["planet"] = planet
	var low: Array[PackedVector2Array] = []
	for bld in _parts_in(outline, func(b2: Dictionary) -> bool: return float(b2["h"]) > float(b2["mh"])):
		var q := _pts(bld["p"])
		if float(bld["h"]) < 5.0:
			low.append(q)  # the west corner's wing, the link to the planetarium
		elif float(bld["mh"]) > 1.0:
			site["lifted"] = q  # the river corner, on its glazed ground floor
	site["low"] = low


func _build_kopernik(site: Dictionary) -> void:
	var outline: PackedVector2Array = site["ring"]
	_g = _ground_under(outline)
	var g := _g
	var street := -INF
	for q in outline:
		street = maxf(street, map.terrain_height(q.x, q.y))
	var top := street + KOP_ROOF
	# The block: the outline less its low wings, straightened.
	var body := outline
	for q: PackedVector2Array in site.get("low", []):
		var cut := _largest(Geometry2D.clip_polygons(body, q))
		if cut.size() >= 3:
			body = cut
	body = _simplify(body, 0.8)
	# The river corner hangs over its ground floor: `under` stands on the ground, `hang` is the
	# corner over the soffit (the two split the block's fronts between them exactly).
	var lifted: PackedVector2Array = site.get("lifted", PackedVector2Array())
	var under := body
	var hang := PackedVector2Array()
	var soffit := top
	if lifted.size() >= 3:
		var rest := _largest(Geometry2D.clip_polygons(body, lifted))
		var over := _largest(Geometry2D.clip_polygons(body, rest)) if rest.size() >= 3 else PackedVector2Array()
		if rest.size() >= 3 and over.size() >= 3 and absf(_area(over)) > 50.0:
			under = rest
			hang = over
			soffit = minf(_ground_under(lifted) + KOP_LIFT, top - 4.0)
	_mode = M_STONE
	for i in under.size():
		var a := under[i]
		var b := under[(i + 1) % under.size()]
		var mid := (a + b) * 0.5
		var out := _out(under, a, b)
		if _kop_edge_dist(body, mid) < 0.3:
			_kop_windows(a, b, out, map.terrain_height(mid.x, mid.y) + 1.4, top - 1.0, i)
			_wall(a, b, g - 0.4, top, out, KOP_WALL)
		else:
			# set back under the overhang: the glazed ground floor, lit at night
			_mode = M_PAVILION
			_wall(a, b, g - 0.4, soffit, out, KOP_LIT)
			_mode = M_STONE
	for i in hang.size():
		var a := hang[i]
		var b := hang[(i + 1) % hang.size()]
		var mid := (a + b) * 0.5
		if _kop_edge_dist(body, mid) < 0.3:
			var out := _out(hang, a, b)
			_kop_windows(a, b, out, soffit + 1.4, top - 1.0, 100 + i)
			_wall(a, b, soffit, top, out, KOP_WALL)
	if hang.size() >= 3:
		_kop_soffit(hang, soffit, KOP_PANEL)
	# The low glass wings (lit at night), their roofs paved.
	for q: PackedVector2Array in site.get("low", []):
		var wing := _simplify(q, 0.4)
		_prism(wing, g - 0.4, street + KOP_LOW, KOP_LIT, KOP_DECK, M_PAVILION, M_STONE)
	_collide(outline)
	_kop_roof(body, top)
	var planet: PackedVector2Array = site.get("planet", PackedVector2Array())
	if planet.size() >= 3:
		_kop_planet(planet)


## A front's windows: dark panes 7 cm out of the wall, two to six metres wide, scattered over
## the panels by a steady hash so no two fronts repeat (the facade's "pixels"); lit warm at
## night (M_PAVILION).
func _kop_windows(a: Vector2, b: Vector2, out: Vector2, y0: float, y1: float, edge: int) -> void:
	var length := a.distance_to(b)
	if length < 4.0:
		return
	var e := (b - a) / length
	var p0 := a + out * 0.07
	_mode = M_PAVILION
	var row := 0
	var y := y0
	while y + 1.6 <= y1:
		var t := 1.0 + fposmod(_kop_hash(float(edge), float(row)) * 7.0, 2.0)
		while t < length - 2.0:
			var cells := 1 + floori(_kop_hash(float(edge) + t, float(row) + 0.5) * 3.0)
			var w := minf(2.0 * cells, length - 1.0 - t)
			if _kop_hash(t * 0.37 + float(row), float(edge) * 1.3) < 0.42 and w >= 1.5:
				_wall(p0 + e * t, p0 + e * (t + w), y, y + 1.6, out, KOP_WINDOW)
			t += w + 2.0
		y += 2.6
		row += 1
	_mode = M_STONE


## The distance from p to a ring's edges.
func _kop_edge_dist(ring: PackedVector2Array, p: Vector2) -> float:
	var best := INF
	for i in ring.size():
		var c := Geometry2D.get_closest_point_to_segment(p, ring[i], ring[(i + 1) % ring.size()])
		best = minf(best, c.distance_to(p))
	return best


## A flat ceiling (faces down) over a polygon: the overhang's underside.
func _kop_soffit(poly: PackedVector2Array, y: float, col: Color) -> void:
	for q in Geometry2D.merge_polygons(poly, PackedVector2Array()):
		if q.size() < 3 or Geometry2D.is_polygon_clockwise(q):
			continue
		var idx := Geometry2D.triangulate_polygon(q)
		for i in range(0, idx.size(), 3):
			var a := q[idx[i]]
			var b := q[idx[i + 1]]
			var c := q[idx[i + 2]]
			if absf((b - a).cross(c - a)) < 0.001:
				continue
			_tri(Vector3(a.x, y, a.y), Vector3(b.x, y, b.y), Vector3(c.x, y, c.y), Vector3.DOWN, col,
					Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0, false)


## The roof garden: the deck paved, a parapet, and raised lawns between a path along the
## block and four across it.
func _kop_roof(body: PackedVector2Array, top: float) -> void:
	_cap(body, top, KOP_DECK)
	_parapet(body, top, 0.9, KOP_PANEL)
	var inner := _largest(Geometry2D.offset_polygon(body, -3.0, Geometry2D.JOIN_MITER))
	if inner.size() < 3:
		return
	_o = _centre(body)
	_a = KOP_PATH_AXIS.normalized()
	_b = Vector2(-_a.y, _a.x)
	var beds: Array[PackedVector2Array] = [_simplify(inner, 0.8)]
	var paths: Array[PackedVector2Array] = [_rect(0.0, 2.0, 120.0, 1.6)]
	for u: float in [-44.0, -14.0, 14.0, 40.0]:
		paths.append(_rect(u, 0.0, 1.4, 120.0))
	for path in paths:
		var next: Array[PackedVector2Array] = []
		for bed in beds:
			for piece in Geometry2D.clip_polygons(bed, path):
				if piece.size() >= 3 and not Geometry2D.is_polygon_clockwise(piece):
					next.append(piece)
		beds = next
	var k := 0
	for bed in beds:
		if absf(_area(bed)) < 20.0:
			continue
		var lawn := KOP_LAWN if k % 2 == 0 else KOP_MEADOW
		_prism(_simplify(bed, 0.5), top, top + 0.45, KOP_KERB, lawn, M_STONE, M_STONE)
		k += 1


## The planetarium: a black boulder, upright walls on its outline (straightened, convex), then
## facets of different heights leaning in to an apex towards the river.
func _kop_planet(planet: PackedVector2Array) -> void:
	var ring := _kop_convex(_simplify(planet, 1.2))
	_g = _ground_under(planet)
	var g := _g
	_prism(ring, g - 0.4, g + KOP_PLANET_WALL, KOP_PLANET, Color(0, 0, 0, 0), M_STONE)
	var c := _centre(ring)
	var apex := Vector3(c.x + 3.0, g + KOP_PLANET_TOP, c.y - 2.0)
	var n := ring.size()
	var mids := PackedVector3Array()
	for i in n:
		var p := ring[i].lerp(c, 0.45)
		mids.append(Vector3(p.x, g + KOP_PLANET_WALL + 1.8 + 1.6 * _kop_hash(float(i), 7.0), p.y))
	_mode = M_STONE
	for i in n:
		var j := (i + 1) % n
		var a := Vector3(ring[i].x, g + KOP_PLANET_WALL, ring[i].y)
		var b := Vector3(ring[j].x, g + KOP_PLANET_WALL, ring[j].y)
		var tint := KOP_PLANET_FACET.lightened(0.06 * _kop_hash(float(i), 2.0))
		_kop_face(a, b, mids[j], tint)
		_kop_face(a, mids[j], mids[i], tint.darkened(0.05))
		_kop_face(mids[i], mids[j], apex, KOP_PLANET_FACET)
	_collide(planet)


## A triangle of the boulder's top, facing up.
func _kop_face(a: Vector3, b: Vector3, d: Vector3, col: Color) -> void:
	var nrm := (b - a).cross(d - a).normalized()
	if nrm.y < 0.0:
		nrm = -nrm  # every facet of the top faces the sky
	_tri(a, b, d, nrm, col, Vector2(-1, -1), Vector2(-1, -1), Vector2(-1, -1), -1.0)


## A ring's convex hull, open and counter-clockwise like the outlines.
func _kop_convex(q: PackedVector2Array) -> PackedVector2Array:
	var h := Geometry2D.convex_hull(q)
	if h.size() > 1 and h[0].is_equal_approx(h[-1]):
		h.resize(h.size() - 1)
	return h


## A steady pseudo-random number in [0, 1) (the windows, the facets).
func _kop_hash(a: float, b: float) -> float:
	return fposmod(sin(a * 12.9898 + b * 78.233) * 43758.5453, 1.0)
