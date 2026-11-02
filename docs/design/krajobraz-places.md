# Krajobraz places: the newest public spaces, as built (F, 2026-11-02)

F asked to research the projects on RS Architektura Krajobrazu's "wybrane" page
(krajobraz.com.pl/kategoria/wybrane/) that fall inside our map, and to bring each place in the
game up to how it looks now. OpenStreetMap and the GUGiK tree scan (LoD1 2023) can be older than
these places, so each item is checked against the studio's page, the news and photos, and our
own skills: `model-from-photos` (reference photos and the GUGiK orthophoto first, a spec, the
photo check, the art-director's scores), `godot-mobile-perf` and the mesh budgets (detail costs
triangles, not draw calls), `warsaw-tone` for any sign, and `verify-game` / `screenshot-review`.
F also asked (2026-11-02) for sources beyond the studio's own pages: every item lists the news
articles used, and the Mac pass adds the photos (Wikimedia Commons, the orthophoto), which the
cloud cannot reach (403).

One backlog item per place, one fresh thread per item (BACKLOG "Krajobraz places"). ul. Złota
and Zgoda belong to the "Build Skwer Linearny on Złota" thread and are not repeated here.

## The 20 projects and the map

| Project | Where | Year | On our map? |
| --- | --- | --- | --- |
| ul. Złota i Zgoda | Śródmieście | 2024-25 | yes, owned by the Złota thread |
| **ul. Bracka** | Al. Jerozolimskie to Krucza | 2024 | **yes, built (K1)** |
| ul. Chmielna | Nowy Świat to Pasaż Wiecha | 2024 | yes (K2) |
| Varso Place | Chmielna 69-73 | 2022 (deck 2024) | yes (K3) |
| Zielona Świętokrzyska | the whole street | 2018 | yes (K4) |
| Generation Park, Skyliner, Mennica Legacy Tower | Rondo Daszyńskiego, Prosta | 2020-21 | yes (K5) |
| Browary Warszawskie | Grzybowska, Wronia, Chłodna, Krochmalna | 2021 | yes (K6) |
| Fabryka Norblina | Żelazna 51/53 | 2021 | yes (K6) |
| Bulwary Wiślane, stages 1 and 2 | Podzamcze to Most Świętokrzyski | 2015, 2017 | yes (K7) |
| Arkadia playground | Al. Jana Pawła II 82 | 2018 | yes, map north (K8) |
| Stadion Narodowy | Praga | 2012 | yes (K9) |
| Muzeum Historii Polski | ul. Dymińska 13, Cytadela | 2023 | **no**: the Citadel is ~0.7 km north of the map's north edge (K10) |
| Plac Unii | Puławska | 2023 | no: south of the map's edge (52.2183) |
| Izba Pamięci (Cmentarz Powstańców Warszawy) | Wola, Wolska | | no: west of the map |
| Riverview | Gdańsk | 2020 | no |
| Galeria Północna, Business Garden | Białołęka, Żwirki i Wigury | | no |

## K1 ul. Bracka (built 2026-11-02)

**What it is now.** The short Bracka between Al. Jerozolimskie and Krucza, behind CeDeT
(Krucza 50), was a dead end full of parked cars on hot concrete. Since summer 2024 it is a
woonerf ("an urban courtyard"): cars at a minimum, priority for people on foot and bikes, a level
paved street, beds with low planting round each tree's base, benches and bike racks, and a
triangular square under the trees at its end. The studio: "classical compositions", paving strips
along the fronts, a planted functional zone, a free middle strip; tall trees placed so the
historic fronts stay in view.
Trees: 33 replacing a temporary car park (whiteMAD), "nearly 40" (Architektura & Biznes), 38 in
the plan (A&B, Chmielna article): planes, bird cherry, cherries and maples.

**The game before.** OpenStreetMap already has the new layout: the beds (30 `leisure=garden`
pieces of 7-51 m², `areas` kind "park"), 10 benches and 6 bike racks in the zone, the street as a
`living_street`. The 2023 tree scan predates most of the planting: 11 young trees (6.5-7.4 m), all
in the north wedge by Krucza; the triangle by Al. Jerozolimskie had 2.

**Built.** `tools/planted_trees.py`: 22 young trees in the empty beds (one per bed of 7 m² or
more, two in a bed of 35 m² or more, 3.5 m apart, clear of benches, racks, poles, buildings and
the carriageway), species mix plane / maple / cherry / bird cherry at 2-3 years' size (5.2-8.2 m,
crown 1.8-2.4 m), 33 young trees in all, as the article counts. They are ordinary `trees3d`
entries: the trees' existing MultiMesh draws them, no new draw call, material or node; their
ground shade comes from `bake_ao.py`. `bake_osm.py` calls the module after `snap_props`, so a
re-bake keeps them; the second run adds nothing.

**Not done, for the Mac pass (QUESTIONS):** the paving (granite slabs as on Chmielna is a guess;
the woonerf is drawn as the minor-road grey), the bed planting's colour, whether the old service
ways across the north wedge are still drivable, and a matched shot against a street photo.

## K2 ul. Chmielna (Nowy Świat to Pasaż Wiecha)

Done 2024 (first stretch by Kino Atlantic and Pasaż Wiecha, then to Nowy Świat; ZTP, RS
Architektura Krajobrazu, Balzola). Concrete cubes replaced by **granite slabs**; **95 trees**
both sides, **elms in two rows** on the narrow stretch before Plac Pięciu Rogów; 9,500 shrubs and
8,500 perennials; **64 pieces of furniture** (urban chairs, benches, long benches with flowing
shapes), restored walls, pots and posts; a **small fountain** on the square by Kino Atlantic;
skwer named after August Agbola Brown ("Ali", jazz musician and Uprising fighter) on 1 Aug 2024;
lighting on poles, on brackets and in the ground; the old pedestrian zone stays pedestrian.
Sources: krajobraz.com.pl, whiteMAD (2024-04-26, 2024-08-06), Architektura & Biznes ("Green
Chmielna", "ugliest pathway"), Eurobuild ("Nowe oblicze Chmielnej", 2024-12-30).
**Game:** the pedestrian Chmielna is an unnamed pedestrian path in the map data; count its
scanned trees, then plant the missing ones with `planted_trees.py` (a new PLACE), add the
fountain and Ali's square (a plate), and a granite paving tint. Opus spec (map), Sonnet build.

**More facts (2026-11-02):** Super Express lists 88 trees from Pasaż Wiecha to Nowy Świat: 57
elms, 24 planes, 5 cherries, a linden and a black locust, with 32 large shrubs and 7,500 plants;
the trees placed so the fronts stay in view and the café gardens fit, rain kept for their roots.
Ali's memorial stone (2019) stands "at the corner of Pasaż Wiecha and Chmielna" (dzieje.pl).

**The game before.** OpenStreetMap already has the new layout: 72 beds in the band (`areas`
kind "park"), most of them 2.4-8 m² tree pits along both sides every 8-10 m, and the bigger
fenced beds of the two squares (Kino Atlantic's, 20-62 m², and the one at Pasaż Wiecha); the
fountain by Kino Atlantic (an OSM `amenity=fountain` node, a 2.8 m pool); the two pedestrian
areas drawn as the ordinary warm paving. The 2023 scan has 20 trees in the band, most of them
the Atlantic square's old ones (10-15 m).

**Built (2026-11-02).** `planted_trees.py` place `chmielna`, given by the street's centre line
and a 13 m half-width: one young tree per tree pit of 2.4 m² or more, two in a square's bed of
20 m² or more, the beds' low fences allowed; species by the distance along the street (planes
and a cherry on Ali's square, planes with a linden and a cherry on Atlantic's, elms only from
there to Plac Pięciu Rogów, elms with the odd plane, cherry and black locust east of it). 65
trees, 85 in the band (the pits next to Plac Pięciu Rogów's carriageway and a passage stay
empty); the street's two pedestrian areas re-tagged `granite` (map_builder.gd SURFACE_STYLE
`#c9c7c1`, no new material or draw call). At the Pasaż Wiecha corner, in first_scene.gd: Ali's
memorial stone (props.gd `add_memorial_stone`, a granite boulder with a bronze plaque) and two
plate posts, PASAŻ WIECHA / CHMIELNA and SKWER BROWNE'A.

**K2b (2026-11-02):** `planted_trees.py furnish` brings the band to 64 benches (OSM had 4): a seat
every 7.5 m along the street, alternate sides, the first spot 2.6-8 m off the middle that is off
the beds, 2.3 m from trees, 1.8 m from POIs, 3.6 m from another bench and 16 m from Nowy Świat
(whose benches are the Chopin ones), facing the street. One bench model, so chairs and long
benches are benches. The Atlantic fountain's 2.8 m pool already has the stone edge every
fountain gets (map_builder `_build_banks`), so no new rim.

**Not done:** the shrub and perennial planting's colour in the beds, the lighting in the ground.
For the Mac pass (QUESTIONS): the orthophoto against the trees, the granite's tone, the stone's
spot and the square's official name on the plate.

## K3 Varso Place (built 2026-11-02)

**Built** (spec `docs/landmarks/specs/varso_place.md`, from HB Reavis', ZinCo's and Eurobuild's
pages; no photo reachable from the cloud): the sky garden on the tower's 205 m roof (16 round
hawthorns, the number HB Reavis gives, dwarf pines, benches, a glass balustrade), planted terraces
on Varso 1 (71 m) and Varso 2 (80 and 72 m) in the new site `varso_place`, the VERSO PLACE name
stone and the 60 t erratic on the corner plaza by Al. Jana Pawła II, and 6 young trees in the
beds the scan left bare (`planted_trees.py` PLACE `varso`). Mac photo check in QUESTIONS.

The plan as written:

Chmielna 69-73 (HB Reavis; Foster + Partners, HRA, Benoy, Epstein), 2022, the deck 2024. The
studio's garden "in the clouds" on Varso Tower's roof at ~230 m (large nursery trees on a
technical deck), 12 *Bucida buceras* (black olive) trees ~9 m tall in the tower's lobby (the
street's green carried inside), and nearly every planting, Chmielna's included, on garage slabs
and the lower roofs. **Game:** Varso Tower is hand-built (`_build_varso`), Varso I and II are
OSM extrusions; no ground plaza or street trees on Chmielna's side, no roof garden (BACKLOG
"Varso's deck" already asks about the deck), no name sign. Build: the plaza's planting along
Chmielna, terraces on Varso 1/2's roofs, a few trees on the crown's deck (triangles in the site's
mesh), and a parody name sign at the plaza (default **VERSO PLACE**, warsaw-tone; never the real
mark). Opus spec from photos (model-from-photos), Sonnet build.

## K4 Zielona Świętokrzyska (built 2026-11-02)

**Built:** the scan has 166 trees within 14 m of ul. Świętokrzyska (x -1665 to -280), against the 194
planted in 2018, so about 28 are missing (or merged into one crown). Trees stay as scanned; no tree is invented.
`zielona_planters` in tools/bake_street_details.py walks the Marszałkowska to Nowy Świat stretch (x -1100 to -275)
every 8 m on both sides, takes the first clear pavement point and puts a `planter` there unless a trunk is within
5 m or another planter within 10 m: 17 planters (street_details.json 422 to 439 items). Not rendered in the cloud
(no Godot there); the check_street_details gates pass.

The original plan text follows.

2018: 194 trees along the whole street, greenery in big planters where trees could not go,
structural soil over the utilities, the carriageway narrowed and parking removed. **Game:** 166
scanned trees within 14 m of the street (2023 scan, so most should be there): count them per
stretch against the 194 and add the planters (the street-details kit has `planter`).
Sonnet, small.

## K5 Rondo Daszyńskiego: Generation Park, Skyliner, Mennica Legacy Tower

Skyliner's green passage (2021): forest-like three-tier planting (tall trees with open crowns,
solitary shrubs, low shrubs and perennials) carrying on the trees of the roundabout's square,
wooden benches on terraces, sheltering the wind. Generation Park (2021) and Mennica Legacy Tower
(2020): the studio shows photos only (plazas between the towers). **Game:** the towers are in
`TOWERS`; their plazas are OSM ground. Build: trees and planters on the plazas from the
orthophoto, benches. Sonnet with a short Opus spec.

## K6 Browary Warszawskie and Fabryka Norblina

Browary (2021): entrance plazas, a two-level plaza by the old Leżakownia with the green Central
Garden over it, trees on slabs and over the restored vaults, the restored line of Krochmalna.
Norblin (2021): big multi-stem planes trained as candelabras (the site's landmark), climbers on
the walls, garden terraces upstairs. **Game:** both are L2 sites (BACKLOG "Norblin, Browary");
add the candelabra planes and the Central Garden, and fold in that section's Mac checks.
Sonnet.

**Done 2026-11-02:** `tools/planted_trees.py` places 5 candelabra planes (15.5 m) in Norblin's court and 12
trees (lindens, hornbeams, planes) in a staggered grid over Browary's mapped garden bed. Left: wall climbers,
upstairs terraces, slab levels (Mac photo check).

## K7 Bulwary Wiślane, stages 1 and 2

Stage 1 (2015): 1 km from Podzamcze to Most Śląsko-Dąbrowski. Stage 2 (2017): Śląsko-Dąbrowski to
Świętokrzyski: 6 pavilions (2 double) on floating platforms that rise with floods (bars, shops),
a splash pool, an urban beach with a pavilion, a children's corner with Vistula fish sculptures,
trampolines, an amphitheatre, the "living river" garden, a tree line that lets floods through,
the underpass under Wisłostrada to the Royal Route. **Game:** the boulevards have their crowds,
riders and barges (BACKLOG "Vistula boulevards: life", "The river's barges"); check the pavilions,
the splash pool, the fish and the steps against the orthophoto. Sonnet.

## K8 Arkadia playground

Al. Jana Pawła II 82, 2018: a ribbon-like rope course joining the zones (slide, climbing frame,
swings), trampolines, a rope bridge, water play for the youngest, shade trees, a big wooden
bench-sculpture with sockets, lamps strung on cables. **Game:** Arkadka is a hand-built site; the
playground is not there. Build it from the kit (`park_details` has `playground`). Sonnet, small.

**Built 2026-11-02.** A new park piece `ropecourse` (`park_props_play.gd`): rubber floor, ribbon loops, three trampolines, bench-sculpture, three cable lamps; anchored in the green strip west of Arkadka (park "arkadia"). The mall keeps its parody name Arkadka.

## K9 Stadion Narodowy grounds

2012: wide entrance avenues cut through the old groves, tree rows guiding the crowds round the
stadium, shrub belts at angles, pollarded willows in groups (the Mazovian landscape). **Game:**
the stadium is an L3 site with its promenade; check the avenues and willows against the
orthophoto. Sonnet, small.

## K10 Muzeum Historii Polski (outside the map)

ul. Dymińska 13 in the Citadel, 2023 (WXCA): an education zone of shaped hedges and perennial
beds, a park zone with dirt paths, benches and a natural playground under trees, a green wall
inside, and a ~6,500 m² green roof looking at the skyline; ~130 trees, 30,000+ shrubs, 1.5 ha of
lawn. **Game:** the Citadel is north of the map's north edge, so nothing can be built there
without growing the map (F's call, QUESTIONS). Until then it could stand on the far skyline as a
long low block with a green roof. Parked.

## Sources

- krajobraz.com.pl/kategoria/wybrane/ and each project page linked from it (2026-11-02).
- whiteMAD: Bracka's tree planting (2024-04-26); "New Chmielna, first stage completed" (2024-08-06).
- Architektura & Biznes: "Woonerf Bracka", "Green Chmielna", "Ugliest pathway of the capital".
- Eurobuild CEE: "Nowe oblicze Chmielnej" (2024-12-30), "Konkurs na nową Chmielną rozstrzygnięty".
- Photos for the Mac pass: Wikimedia Commons and the GUGiK orthophoto (model-from-photos skill).
