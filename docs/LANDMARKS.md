# Landmarks and buildings: what is done, how, and the plan

The user asked (2026-10-31) for one document listing every landmark and building in the game:
what is done and how, and what is left, by priority. **Part 1** is the plan (keep it current: a
thread that lands an item ticks it here and in its log `docs/landmarks/<slug>.md`). **Part 2** is
the inventory taken from the code on 2026-10-31. How a model is made: the model-from-photos skill
(reference photos and the orthophoto in `refs/<slug>/`, an Opus spec, `object-modeler` builds,
`art-director` scores against the photos, the user picks last).

**Detail levels** (model-from-photos skill): L1 silhouette and colour · L2 facade articulation
(base/middle/top, window rhythm, cornices, roof shape) · L3 every identity feature in 3D.

## Part 1. The plan, by priority

Photos (2026-10-31): `refs/` on the Mac holds 51 buildings, 154 free photos and 50 GUGiK
orthophotos (`refs/INDEX.md` lists them). No usable free photo: Skyliner, Chilton, Westynka,
Ilmet, Platinum Towers, Spektrum, BUW (interiors only), The Bridge, the flag on Rondo
Radosława, Hotel Wiktoria; none collected yet for Chałubińskiego 8, Forest, MDM, the
Departament. The Museum of Modern Art has no photo of its Marszałkowska front yet. The second
batch's captions (towers, churches) come from Commons titles: check the angle before a spec.

### P0. The tools first (they make every model after them better)

| # | Item | Who | Why first |
| --- | --- | --- | --- |
| 0.1 | DONE 2026-10-31: `check_mesh_quality.gd`: z-fighting, zero-area and flipped triangles, floating parts, per site, in `verify.sh` | gameplay-dev (Opus brief, Sonnet build) | the defects a judge misses; BACKLOG "Model checks from the research" |
| 0.2 | DONE 2026-10-31 (in `check_mesh_quality.gd`'s BUDGET, all 46 sites): triangle budgets for every hand-built site | object-modeler | detail without a limit can't be accepted |
| 0.3 | DONE 2026-10-31: `--solo=KEY --solo-look=flat\|sil\|lit` renders one landmark alone, unlit or as a silhouette (`solo.gdshader`, runtime path only), and `tools/shots.sh --set=first` (Palace, Rotunda, Tarasy, flat + sil) | gameplay-dev | the judge's shots (skill section 5) |
| 0.4 | DONE 2026-10-31 (checker): `tools/check_spec.py` (step `spec` in `verify.sh`, specs in `docs/landmarks/specs/`); the skill's evals (Palace, Rotunda, MSN) are planned in the skill, section 7, not run (need photos, a GPU run and the Mac) | main session | no build from an open spec |

### P1. Heroes to L3 (the first minute, the skyline, the postcards)

| # | Object | Today | To do | Photos |
| --- | --- | --- | --- | --- |
| 1.1 | Muzeum Sztuki Nowoczesnej | DONE 2026-10-31 (L3, site `msn`, spec `docs/landmarks/specs/msn.md`, 336 tris): white box on the glazed ground floor and its 29 fins, the slot, two city-room windows, three skylights, card | photo check on the Mac: the city-room windows (face, size) and the skylights against `ortho.jpg`; next door TR Warszawa is a building site with cranes (site `tr`, 2026-10-31) | 4 + ortho (no Marszałkowska front yet) |
| 1.2 | Pałac Kultury i Nauki | DONE 2026-11-01 (L3, site `palace`, spec `docs/landmarks/specs/palace.md`, 3632 tris; Mac photo check applied 2026-11-01): re-pass from the OSM 3D parts: the 30 m north and south blocks built whole up to the tower, the first tier and the shaft on their mapped plans (corner piers, set-back ribbed middle bays), the Congress Hall on its mapped outline with the dome inside it, wing heights as mapped, the shaft's cornice band, the 30th-floor terrace (114 m: a 1.9 m ledge and balustrade round the shaft with up to 16 visitors, `crowds.gd` DECKS `pkin_terrace`; Mac look check parked), the hall's flat stepped metal roof, a 25 m six-column portico, a deeper gold spire on a bronze foot; the tower's heights unchanged (the opening flight, the landing shot) | the stone's colour (QUESTIONS); the portico's 17 m depth (inside the mapped base) | yes |
| 1.3 | Rotunda + Domy Towarowe Centrum (the Eastern Wall) | Rotunda DONE 2026-11-01 (L3, spec `docs/landmarks/specs/rotunda.md`, 1144 tris, from the Mac photo check): green-grey glass between 52 silver mullions, the folded-plate crown (48 folds, a ring of downward teeth), the raised oculus with its kerb and 4 x 4 glazed top, the south and plaza canopies, two roof plates, BANK POLSKA either side of the south door; Widok Towers a green glass grid; the stores DONE 2026-11-01 (L2, site `dtc`, spec `docs/landmarks/specs/dtc.md`, 1267 tris): Junior, Sawa and Wars from their OSM parts, the glazed shop floor under the cantilevered curtain wall, a set-back top storey with roof lights, the parody names lit on the roofs; Mac photo check applied 2026-11-01 (1439 tris): dark blue-grey glass in a vertical grid, the dark shop floor 4.5 m deep, light aluminium soffit, top storey 8 m off the ends, skylight clusters, vents and plant, Junior's stepped roof, printed ad banners; behind them the 75 m tower DONE 2026-11-01 (site `tower75`, spec `tower75.md`, 180 tris, unnamed: re-clad cladding with punched windows, dark glass podium, KOKA-KOLKA letters on the roof) and the four 37 m slabs behind Junior DONE 2026-11-01 (site `slabs`, spec `slabs.md`, 225 tris, unnamed: cream-ochre plaster, loggia bands, ochre ends, lift houses, an ORANZADA billboard behind Sawa) | the pavilions; photo check on the Mac (the top storey, the signs' faces) | yes |
| 1.4 | Złote Tarasy | DONE 2026-10-31 (L3, site `tarasy`, spec `docs/landmarks/specs/tarasy.md`, 4762 tris): the wave, the terraced podium, Lumen, Skylight and its lit crown, the drum, from the OSM parts | photo check on the Mac: Lumen's ribbons, Skylight's crown, the wave against the orthophoto | yes |
| 1.5 | Varso, Złota 44, Warsaw Spire, Rondo 1, Q22 | Varso, Złota 44 and Spire own geometry; Rondo 1 and Q22 from the tower table | re-pass of the skyline against photos, crowns first | Varso, Złota 44, Spire, Rondo 1 yes |
| 1.6 | Zamek Królewski + Plac Zamkowy | skin only (colour) | model: the clock tower, the facade's bays, the roof; the square's paving round the Column | yes |
| 1.7 | Stadion Narodowy | DONE 2026-11-01 (L3, site `stadium`, spec `docs/landmarks/specs/stadium.md`, 3814 tris; Mac photo check applied 2026-11-01; the grass embankment 2026-11-01): the skin's staggered red and silver panels, silver more often higher, over a dark glass concourse, a real-size striped pitch in two tiers of red seats with the boxes between, the raised roof rim, a rounded opening, the needle with the folded roof's drum, from the OSM parts; the outer slope of the old embankment is grass (found on the terrain, under the mapped plaza, lawns and stairs) and the promenade sits on the crest | photo check on the Mac: the bank's grass against the orthophoto | yes |
| 1.8 | Most Poniatowskiego | towers model, heights guessed | towers from photos; the deck's arches and balustrades | yes |
| 1.9 | Warszawa Centralna | DONE 2026-10-31 (L2, site `centralna`, spec `docs/landmarks/specs/centralna.md`, 1370 tris): the glass hall, the wings, the flat slab overhanging to 140 x 86 m, the hyperbolic paraboloid shells under it on the mapped pillars, from the OSM parts | photo check on the Mac: how much of the shells shows outside, the wings' walls; the canopy's AO | yes |

### P2. Named landmarks to L2 (today skins: colour only on LoD2)

| # | Object | To do |
| --- | --- | --- |
| 2.1 | Kościół św. Anny | DONE 2026-11-01 (L3 front with four-column portico, pediment, flanking wings, and the bell tower's trim on the kept skin, spec `anna.md`, 586 tris, heights estimated, Mac photo check parked: column count, door, tower cap). The bell tower's observation terrace DONE 2026-11-01: a stone balustrade round the cornice at 25 m and up to 8 visitors on it (`crowds.gd` DECKS `anna_deck`); Mac check parked: the real terrace's height (about 40 m) and its railing |
| 2.2 | Teatr Wielki | the colonnade and the portico on Plac Teatralny |
| 2.3 | Old Town and New Town tenements | dormers and chimneys DONE 2026-11-01; stepped attic gables on the market square's east side DONE 2026-11-01 (`OldTownRoofs.gable`); the New Town and the other sides stay open (map lane: `_tenement_facades`, the LoD2 roofs); Mariensztat joined the dress 2026-11-01 (`MARIENSZTAT` polygon, Mac look check parked) |
| 2.4 | Archikatedra, Barbakan | the Cathedral's stepped gable; the Barbican's towers and walls |
| 2.5 | Pałac Prezydencki | DONE 2026-10-31 (model, spec `docs/landmarks/specs/prezydencki.md`, 868 tris): wings round the forecourt, portico, Poniatowski's statue, lions, gate, guardhouses; photo check on the Mac |
| 2.6 | Kościół Świętego Krzyża, Wszystkich Świętych, św. Aleksandra | Holy Cross DONE 2026-11-01 (L3 front and towers on the kept skin, spec `docs/landmarks/specs/krzyz.md`, 934 tris; Mac photo check parked: column and door count, helm shape, the crossing's dome). St Alexander DONE 2026-11-01 (L2 model replacing the skin: drum, windows, dome, lantern, two six-column porticoes, spec `aleksander.md`, 1218 tris, heights estimated, Mac photo check parked: which end has the portico, column count, the bell towers). All Saints DONE 2026-11-01 (L3 front and twin copper-domed towers on the kept skin, spec `wszystkich.md`, 788 tris, heights estimated, Mac photo check parked: tower height and dome shape, portal count) |
| 2.6c | Kościół Wizytek (Krakowskie Przedmieście) | DONE 2026-11-01 (L3 facade, stepped wing and crossing turret on the kept skin, spec `wizytki.md`, 566 tris, heights estimated, Mac photo check parked: gable shape, towers or none, turret) |
| 2.6b | Kościół Świętej Trójcy (Lutheran, Plac Małachowskiego) | DONE 2026-10-31 (L3 model, spec `trojca.md`, 1901 tris): drum with oculi, four Tuscan porticoes, copper dome, columned lantern and cross |
| 2.7 | Sejm (DONE 2026-11-01: hall colonnade, spec `sejm.md`, Mac photo check parked), Pałac Staszica (DONE 2026-11-01: portico, cornice, Copernicus statue, spec `staszic.md`, Mac photo check parked), Kopernik, BUW, Hala Mirowska (DONE 2026-11-01: L2 model, spec `mirowska.md`, from the mapped parts, Mac photo check parked; Hala Gwardii DONE 2026-11-01: L2 twin model, spec `gwardii.md`, bays from the outline, Mac photo check parked) | facades and roofs from the photos (Zachęta DONE 2026-10-31: model, spec `zacheta.md`, from the user's photo; Kopernik DONE 2026-11-01: L2 model, spec `kopernik.md`, log `docs/landmarks/kopernik.md`, from OSM and LoD2, then the Mac's photo check: warm strip facade with slits and bays, the copper-red planetarium drum and dome, roof craters and paths, the cantilever; BUW DONE 2026-10-31: L2 model, spec `buw.md`, log `docs/landmarks/buw.md`, from OSM: copper pages, philosophers; the roof from the orthophoto on 2026-11-01: glass field and tail, oculus, mound and pyramid, formal beds, the green band; photo check of the height and the philosophers) |
| 2.8 | MDM and Plac Konstytucji | the blocks' arcades, reliefs, the corner towers |
| 2.9 | Towers missing from the table | PZU Tower, JM Tower, Pekao Tower, Warsaw Towers, Atlas, Prosta |
| 2.11 | Railway stations (F, 2026-11-01; plan `docs/design/railway.md`) | Warszawa Ochota DONE 2026-11-01 (S1, L3, site `ochota`, spec `ochota.md`, 1178 tris: the hypar shell striped underneath over the glass hall on its deck over the cutting, struts, column, stairs, kiosk; Mac photo check parked: stripes, supports, stairs), Warszawa Powiśle DONE 2026-11-01 (S2, L3, site `powisle`, spec `powisle.md`, 1470 tris: the kite roof between two arches over the tunnel's mouth, the round drum under the saucer with WARSZAWA POWIŚLE in neon, X canopies on both platforms; Mac photo check parked: arches, saucer profile, canopy length), Warszawa Stadion DONE 2026-11-01 (S3a, L3, site `stadion_pkp`, spec `stadion_pkp.md`, 1294 tris: the white hall with the sail at its platform end, STADION in neon, red-and-white mosaic wind walls under metal canopies on both platforms, stair heads; Mac photo check parked), Warszawa Śródmieście DONE 2026-11-01 (S3b, L2, site `srodmiescie`, spec `srodmiescie.md`, 476 tris: the two glass stair pavilions under a deep stone fascia, ŚRÓDMIEŚCIE in blue neon; Mac photo check parked), then Wschodnia, Gdańska, the WKD entrances (S3c-e, Mac first); Centralna is 1.9 |
| 2.12 | Wola and Powiśle's old industry (F, 2026-11-01) | Fabryka Norblina DONE 2026-11-01 (L2, site `norblin`, spec `norblin.md`, 1234 tris: brick halls with two rows of arches under three glazed storeys, the 43.9 m wing two storeys higher, a chimney in the court; the outline is OSM's landmark `Modsen`; Mac photo check parked: which wings are historic, the chimney). Browary Warszawskie DONE 2026-11-01 (L2, site `browary`, spec `browary.md`, 3002 tris: Warzelnia, Laboratorium and Willa Schielego in dark brick, the three office blocks in warm grey with glass bays, the brewery chimney; Mac photo check parked: roofs, the Brama's arch, the chimney). People chilling in all four yards and KROWA 2.0 (`crowds.gd` CHILL, MILK) |
| 2.15 | The grand hotels (F, 2026-11-01) | DONE 2026-11-01 (L2, sites `bristol` and `polonia`, specs `bristol.md` section 9 and `polonia.md`, 2013 and 1202 tris; shared builder `_palace_hotel`): Bristol keeps its kept skin and the dome and gains a rusticated plinth, balcony band, string course, cornice, slate mansard with a dormer every 4.4 m and, on Krakowskie Przedmieście, a forward bay with a lit door, copper canopy, a BRISTOL board in gold neon and a pediment; Polonia Palace is built whole (mapped outline is a 4.3 m shed) with a red canopy on Al. Jerozolimskie. Already models: Europejski, Wiktoria, the Marriott (Centrum LIM), Novotel, Westin, InterContinental. Colours, storeys and doors are estimates, Mac look check parked |
| 2.14 | Old Town hotels (F, 2026-11-01) | DONE 2026-11-01 (L2, sites `hotel_kasztel`, `hotel_canaletto`, `hotel_starowka`, ~150 tris each; `HOTELS` in landmarks.gd): OSM has no Old Town hotel building (rooms in tenements), so each is a front on the street-facing facade of the tenement nearest a published spot: portal with warm night-lit door, canopy, dark fascia board with a HOTEL line and the name in neon, two flag arms, two lanterns, a card; parody names for Castle Inn, Hotel Bellotto and a Rynek aparthotel; Le Régina/Mamaison is in the New Town, which the map data does not cover yet. Spots are estimates, Mac look check parked |
| 2.13 | Rynek Starego Miasta and the Syrenka (F, 2026-11-01) | DONE 2026-11-01 (L2 square + L3 statue, sites `rynek` and `syrenka`, spec `rynek.md`, 2562 + 394 tris): cobbled paving with a border band and a disc round the fountain, 58 café umbrellas in nine restaurant colours along all four sides, the fountain's rim wall and the Syrenka in bronze on an octagonal pedestal with sword and shield, two cards; no photo reachable from the cloud, Mac photo check parked (paving pattern, umbrella colours, the statue's pose and pedestal) |
| 2.10 | Dom bez Kantów, Departament, the Królewska block | colours from photos (guesses today); a name for the block |

### P3. Still generic (L1 from LoD2), by how often a player sees them

| # | Group | Objects |
| --- | --- | --- |
| 3.1 | On the demo's routes | Krakowskie Przedmieście's missing pieces (review 2026-11-01, BACKLOG "Mariensztat and Krakowskie Przedmieście"): DONE 2026-11-01 from the OSM outlines, no photos (specs `karmelici`, `mickiewicz`, `brama_uw`, `potocki`, `kordegarda`, `bristol`; `kazimierzowski` a kept skin; `mariensztat` M2): the Carmelite church's front, Mickiewicz's monument, the University gate, Pałac Potockich and its guardhouse, Bristol's corner dome, Mariensztat's relief panels; Mac photo checks parked (QUESTIONS); K6 done (specs `prus`, `wyszynski` as code comments, `czapski` a kept skin with a card); still open: Pałac Czapskich's own model; Teatr Narodowy, Polonia Palace, Poczta Główna, NBP, Filharmonia, Hala Koszyki, Pałac Krasińskich, Arsenał |
| 3.2 | Churches and religious | Kościół Najświętszego Zbawiciela DONE 2026-11-01 (L3, site `zbawiciela`, spec `zbawiciela.md`, 1029 tris: the two 76 m posts and the box became a basilica with a porch and pediment, square towers through octagonal belfries to copper spires, and a dome with drum and lantern over the crossing; shapes and heights below the towers estimated, Mac photo check parked: plaster and roof colours, belfry and spire shape, dome height, porch). Left: Praga cathedral, Wizytek, Synagoga Nożyków, Katedra polowa, Cerkiew, the rest |
| 3.3 | Stations and halls | the stations moved to 2.11; Torwar. Hala Koszyki and Elektrownia Powiśle DONE 2026-11-01 (L2 models, specs `koszyki.md`, `elektrownia.md`, 1142 and 1626 tris: brick, tall arches, the hall's glass lantern, two chimneys; Mac photo check parked: brick shade, roof shapes, number and place of the chimneys) |
| 3.4 | Culture and civic | POLIN, Planetarium, Politechnika's main hall, Zamek Ujazdowski, the palaces (about 40) |
| 3.5 | Other bridges | Śląsko-Dąbrowski, Gdański, Łazienkowski: generic decks today |
| 3.6 | Street furniture | kiosks, tram stop platforms, Warsaw's green bins (BACKLOG "next candidates") |
| 3.7 | The river's barges | DONE 2026-11-01 (L2, sites `barka_wieczor`, `barka_biala`, `barka_marina`, `barka_kaskada`, `houseboats`, spec `barki.md`): the four bar barges OSM maps on the boulevards (were 14 m boxes in the water) as moored barges with raked hulls, glazed deckhouses, sun terraces with umbrellas and bars, festoons of bulbs, gangways to the bank and parody neon names; the nine houseboats with cabins. Mac photo check parked; the barges OSM lacks and the boathouses in BACKLOG "The river's barges" |

**How to run it:** one item per fresh thread (CLAUDE.md "Model routing"), P0 before P1;
inside P1 by the order above; each item's thread writes its log in `docs/landmarks/<slug>.md`
and ticks the row here.

## Part 2. The inventory (from the code, 2026-10-31)

Source: `game/scripts/landmarks.gd` (3214 lines; INFO 64 cards, TOWERS 29, SKINS 15, PLAC_SKINS 2), `map_builder.gd`, `props.gd`, `models.gd`, `storefronts.gd`, `neon_signs.gd`, `game/tools/check_sites.gd`, `check_landmarks.gd`, `docs/BACKLOG.md`, `docs/ROADMAP.md`, `game/map/centrum.json`.
Material codes (landmarks.gd 23-36): M_MONUMENT 2 (tall windows between piers), M_STONE 3, M_GOLD 4, M_DIAL 5 (lit clock), M_WEAVE 6 (stadium), M_GLASS_ROOF 7, M_PAVILION 8 (lit glass), M_ATTIC 9 (merlons), M_LAMP 10, M_MEMBRANE 11, M_GLASS 12 (mullions), M_SKIN 13 (tower skin, style S_*), M_GOTHIC 14. Skins S_SAIL 0, DIAMOND 1, BANDS 2, FINS 3, GRID 4, RIBBON 5, DARK 6, GOLD 7, FRAME 8.
Checks: `check_landmarks.gd` runs on the full map for EVERY site that has a card (tallest cell, tap picks it, 10/12 car rays stopped, heli blocked/lands); it has no triangle budget. `check_sites.gd` (headless, committed data only) builds a site alone and holds a triangle BUDGET: muzeum 2500, europejski 1500, grob 600, metropolitan 3200, wiktoria 900 (also card text <=70 chars, no "sofitel"/"victoria"); also checks skins bez_kantow, departament, krolewska. All other sites have NO triangle budget.
"Card" = entry in `INFO` (PL + EN). Tower generic builder = `_build_tower` (mapped parts in a skin, glass and roof colour, optional crest, sign, `_aviation` red lights >=100 m).

### 1. Objects

#### 1a. Hero hand-built landmark models
| Name (game / real) | Area | Category | Built how | Card | Check / budget | Open issues |
|---|---|---|---|---|---|---|
| Pałac Kultury i Nauki | Śródmieście | landmark model | `_build_palace` (spec palace.md): tiers from OSM parts (P_WINGS, P_BLOCKS, P_TIER, P_SHAFT, P_COURTS, P_HALL), M_MONUMENT, M_STONE pinnacles, M_GOLD spire to 237 m, `_dial` clocks (M_DIAL, hands from shader, Warsaw time), M_ATTIC; Congress Hall drum | yes | check_landmarks (+ roof-rescue / spire-cell probe), check_mesh_quality | Roof rescue lands on the 30 m block; photo check on the Mac |
| Złote Tarasy | Śródmieście | landmark model | `_build_tarasy` + `_tarasy_wave`: the whole complex from its OSM parts (spec tarasy.md): the wave, lit rim walls, podium, Lumen, Skylight + crown, drum | yes | check_landmarks, check_mesh_quality | photo check on the Mac |
| Rotunda (Rotunda PKO) | Marszałkowska x Al. Jerozolimskie | landmark model | `_build_rotunda` (spec rotunda.md, Mac photo check 2026-11-01): green-grey glass drum (M_PAVILION + 0.75) between 52 silver fins, folded-plate crown of 48 folds whose ends hang as teeth, oculus kerb and gridded glass top, south and north-west canopies, two triangular roof plates, BANK POLSKA (parody) either side of the south door | yes | check_landmarks, check_mesh_quality | the drum keeps the mapped Ø 34 m (photos 35-37 m) |
| Rynek Starego Miasta | Stare Miasto | square model | `_build_rynek` (spec rynek.md, 2026-11-01): cobbled paving (border, field, disc), 58 café umbrellas by restaurant colour, built `_no_roof`; the houses are `_tenement_facades` and `OldTownRoofs` | yes | check_mesh_quality (3100) | photo check on the Mac |
| Varso Tower | Chmielna / Rondo ONZ side | tower (hand-built) | `_build_varso`: M_GLASS slabs 177/205/230 m, dark spines, lit glass crown 193-234 m (M_PAVILION cool), one mast to 310 m, 5 rings, beacon | yes | check_landmarks | Antenna lattice unlit (dusk); Varso I/II OSM extrusions elsewhere |
| Stadion Narodowy (PGE Narodowy) | Praga, Saska Kępa side | stadium | `_find_stadium` (72 mast pairs give outline) + `_build_stadium` (spec stadium.md): M_WEAVE skin leaning out, red low and white high, 72 masts, raised rim, M_MEMBRANE roof to a rounded opening, pitch along the masts' principal axis in two tiers with boxes, needle with hub and folded-roof drum on cables; `_beam` | yes | check_landmarks, check_mesh_quality | Embankment bare terrain; AO/lamp maps still on LoD2 footprint; photo check on the Mac |
| Warszawa Centralna | Śródmieście | station | `_find_centralna` + `_build_centralna` + `_centralna_shells`: the whole station from its OSM parts (spec centralna.md): glass hall, wings and roof boxes, vestibules, end pillars, the hypar shell tier and the flat slab over it, turned -19.4 deg | yes | check_landmarks, check_mesh_quality | AO ignores canopy; photo check on the Mac |
| Most Poniatowskiego (towers) | Vistula, Śródmieście/Praga | bridge (towers) | `_find_towers` (bake seats 4 towers `data["towers"]`) + `_build_towers`: plinth, shaft with cornice, open arcade, pointed roof, finial; deck itself is map_builder decks | yes | check_landmarks (special-cased); no budget | Tower heights are a guess (top 15 m over deck); thin pale lines along deck |
| Most Świętokrzyski | Vistula, Śródmieście/Praga | bridge | `_find_swieto`/`_build_swieto`: concrete pylon leaning back 7 m (70 m top), 12+9 stays in one plane along the median; deck is map_builder's | yes | check_landmarks (needs 6 rays, not 10) | none listed |
| Kolumna Zygmunta | Plac Zamkowy, Old Town | hand-built monument | `_find_zygmunt` (circle zone r=4) + `_build_zygmunt`: stepped granite base, pedestal, 12 m shaft, capital, bronze king with cross and sabre | yes | check_landmarks | none |
| Grób Nieznanego Żołnierza | Plac Piłsudskiego | hand-built monument | `_build_grob`: granite platform, 2 rows x4 piers, round arches (`_arch`), entablature, tomb slab, wreaths, eternal flame M_LAMP glow | yes | check_sites BUDGET 600 | none beyond photo re-pass |
| Muzeum Narodowe | Al. Jerozolimskie east end | museum | `_find_muzeum` + `_build_muzeum`: `_simplify`d outline, plinth, wings 18.5 m with `_bays` (M_GLASS) and `_parapet`, raised entrance block 25 m with portal/piers/steps, `_tank` + `_field_gun` in east court | yes | check_sites BUDGET 2500 | Heights are estimates; army-yard placement a guess |
| Hotel Europejski | Krakowskie Przedmieście / Plac Piłsudskiego | palace/hotel | `_build_europejski`: rusticated base, M_MONUMENT pilaster floors, cornice, hipped roof, two forward bays with attics | yes | check_sites BUDGET 1500 | Heights estimates |
| Metropolitan | Plac Piłsudskiego | office landmark | `_build_metropolitan`: 3 blocks, curved M_GLASS fronts behind granite `_fins`, courtyard `_inside_wall`, 3 passages (dark panels), set-back 7th storey, plant rooms, paved court + round fountain | yes | check_sites BUDGET 3200 | Passages are dark panels, not open |
| Hotel Wiktoria (parody of Sofitel Victoria) | Królewska | hotel (parody) | `_build_wiktoria`: dark-glass podium S_DARK under stone fascia, ribbon slab S_BANDS, plant room | yes (parody only) | check_sites BUDGET 900 | Slab 30 m / podium 8 m / 18 m deep are estimates |
| Hotel Polonia Palace | Al. Jerozolimskie 45 | palace/hotel | `_build_polonia` via `_palace_hotel`: rusticated plinth, balcony band, cornice, slate mansard with dormers, red-canopied door, name board; Bristol (`bristol`) shares the builder on its kept skin | yes | check_sites BUDGET 1450 | Colours, 25.5 m and the door are estimates |
| Arkadka (Westfield Arkadia) | Rondo Radosława | mall | `_build_arkadia`: outline lifted as block, lit glass storey + pale panels to 21 m, roof-deck, 37 m tower with ARKADKA sign | yes | check_landmarks | Roof car-park race (DEMO 6.4) needs modelling |
| Forest (office) | north of Rondo Radosława | office | `_find_forest` (box) + `_build_forest`: tallest part = 120 m dark green glass tower with fins, other wings pale glass bands, planted roofs | yes | check_landmarks | none |
| Biblioteka Uniwersytecka (BUW) | Powiśle, Dobra | library | `_find_buw` + `_buw_beds` + `_build_buw`: glass block to LoD2's 15 m deck, 12 copper plates with text lines on Dobra, 4 philosophers on columns, the green band, the roof from the orthophoto: flat glass field and tail (out of the roof grid, so the cassette lands on the garden), oculus, mound and glass pyramid, formal beds, pavilions, vents, the south garden's paths, the 10 m court on Collegium Iuridicum II (spec buw.md) | yes | check_landmarks, check_mesh_quality | photo check on the Mac: the philosophers' front |
| Centrum Nauki Kopernik + Planetarium | Powiśle, Wybrzeże Kościuszkowskie | science centre | `_find_kopernik` + `_build_kopernik`: block to LoD2's 13 m in warm panel strips with slits and glazed bays (`_kop_front`), glass SE end with a steel frame (`_kop_frame`), dark cantilever (`_kop_cantilever`), roof garden with craters, teal strip, pavilion (`_kop_roof`), copper-red faceted planetarium drum with clerestory and dome (`_kop_planet`) (spec kopernik.md, Mac photo check applied) | yes | check_landmarks, check_mesh_quality | the frame's stairs |
| Ministerstwo Finansów | Świętokrzyska 12, between Czackiego and Krakowskie Przedmieście | ministry | `_find_mf` + `_build_mf` (spec mf.md): `_simplify`d outline on a rusticated floor, `_bays` in two rows, cornice and parapet, central risalit with pilasters, three doors and steps, hipped south pavilions | yes | check_mesh_quality 1870 | Heights from OSM; pavilion roofs, risalit rise and colours are a first pass; Mac photo check parked |
| Flaga na rondzie Radosława | Rondo Radosława | monument/prop | `_build_flag`: steel mast 57.8 m + 16x10 m flag in light wind (not in OSM; circle zone) | yes | check_landmarks | none |
| Pawilony (Pawilony za Nowym Światem) | Nowy Świat 22/28, the courtyard | bar pavilions | `_find_pawilony` (the two OSM strips) + `_build_pawilony` (2026-10-31, spec `docs/landmarks/specs/pawilony.md`): each strip cut into 37 pavilions 3.4-5.6 m wide, 2.7-3.6 m tall, back to back in the 12 m strip; own wall and roof colour, eave, fascia, door, lit window or shutter, neon words PIWO/BAR/SHOTY/KLUB/DISCO/KARAOKE/OTWARTE or warm bulbs; PAWILONY over the gate on Nowy Świat | yes | check_mesh_quality BUDGET 2100 (1740 tris) | no photos used (cloud): art-director check vs `refs/pawilony/` open; gate sign spot from the OSM outline |

#### 1b. Towers, generic builder `_build_tower` from `TOWERS` (skin, glass hex, roof hex, crest). All have cards. Check: check_landmarks only; no budget.
| Name (real name if parody) | Skin | Special | Open issues |
|---|---|---|---|
| Złota 44 | S_SAIL | custom `_zlota_sail`: curved east front, 8 rings, sloped crown 192->158 m, red aviation | looks revisited after phone feedback |
| Warsaw Spire | S_DIAMOND | custom `_spire`: lofted leaf, taper, open crown frame 196 m, mast 220 m, SAMSONG sign (parody) | - |
| Q22 | S_BANDS | - | - |
| Rondo 1 | S_FINS | crest "frame" (open crown to 192 m) | tenant names / PHN unlit |
| Emilii Plater 49 (InterContinental, "INTERKONTI" sign) | S_GRID | crown sign | grid cells cold/many vs warm sparse in photos |
| Cosmopolitan | S_RIBBON | - | - |
| Warsaw Trade Tower | S_BANDS | - | - |
| Skyliner | S_FINS | - | - |
| Warsaw Unit | S_BANDS | - | - |
| The Warsaw HUB B and C (found by point `_tallest_at`) | S_FINS | crest slope; two cards share a name | - |
| Mennica Legacy Tower | S_FINS | crest slope | - |
| Generation Park Y | S_DARK | crest slope | - |
| Skysawa | S_BANDS | - | - |
| Błękitny Wieżowiec | S_GOLD | gold glass | - |
| Warszawskie Centrum Finansowe | S_DARK | - | Bank Polski/PHN crown unlit |
| Centrum LIM (Marriott; "PREZYDENT" sign, SAMSONG on mid band) | S_GRID | `_marriott`: dark bands, lattice mast, red lamp; crown name | lit cells too cold/many |
| Chałubińskiego 8 | S_FINS | mapped colours kept | antenna / dark-glass refit unlit |
| Spektrum Tower | S_BANDS | mapped colours | - |
| The Bridge | S_FINS | - | - |
| Chilton (Hilton Warsaw City, Grzybowska 63) | S_BANDS | parody sign CHILTON | - |
| Westynka (The Westin, Jana Pawła II 21) | S_GRID | mapped, sign WESTYNKA | - |
| Nowotel (Novotel, Marszałkowska 94/98) | S_TILE (white tiled shaft, floodlit; 2026-10-31 Rondo photos) | vertical blue neon N-O-W-O-T-E-L (`vsign`, one letter per sign), two setbacks at the top (`chamfer`); the ACCOR line is not built | - |
| Central Tower | S_DARK | - | - |
| Ilmet | S_BANDS | brown glass | - |
| Platinum Tower A / B | S_RIBBON | two entries | - |
| Łucka City | S_RIBBON | - | - |
| Widok Towers | S_GRID (green glass #5d8478, white grid; Mac photo check 2026-11-01) | - | - |
| PZU Tower | S_RIBBON (pale green-blue glass #8fb5bd; 2026-11-01, spec `pzu_jm.md`) | - | - |
| JM Tower | S_FINS on dark navy glass, mapped grey pilasters (spec `pzu_jm.md`) | - | - |
Not covered: Pekao Tower, Warsaw Towers, Atlas Tower, Prosta Tower, V Tower, Concept Tower, Sienna Center etc. (generic).

#### 1c. Skin-only (kept LoD2/OSM massing, own wall + roof colour + facade mode; `SKINS` via `_find_skins`, `skin_at`, `_mark_zone`)
All with a card; check_landmarks only (except where noted). Open issue common to all (BACKLOG "Left"): colour-only, no portico/gables/towers modelled.
| Name | Mode | Wall / roof | Note |
|---|---|---|---|
| Teatr Wielki | M_MONUMENT + portico model | #ddd2b6 / #7fa894 | 8-column portico, steps, attic (spec teatr.md, 2026-11-01; photo check on the Mac: column count, attic sculpture) |
| Zamek Królewski | M_MONUMENT | #c87560 / #6e5a4e | no tower/clock |
| Barbakan | M_GOTHIC | #ab5a42 / #6b4a3c | |
| Archikatedra św. Jana | M_GOTHIC | #9a4b38 / #6e3a2e | |
| Kościół św. Anny | M_MONUMENT | #e6dcc4 / #8a5a44 | `_build_anna` (spec anna.md, 2026-11-01): four-column portico, pediment, wings, bell-tower trim, terrace balustrade; 586 tris |
| Pałac Prezydencki | M_MONUMENT | #ece3cc / #6a7a77 | facade to model |
| Kościół Świętego Krzyża | M_MONUMENT + front model | #e3d9c0 / #5d6e64 | `_build_krzyz` (spec krzyz.md, 2026-11-01): four-column portico, upper storey, pediment, two towers with copper onion helms; dome over the crossing not modelled |
| Pałac Staszica | M_MONUMENT + front model | #e2d6b8 / #5f6f6a | `_build_staszic` (spec staszic.md, 2026-11-01): plinth band, cornice with corner pilasters, four-column portico with pediment, Thorvaldsen's seated Copernicus; heights estimated (no LoD2 in the cloud) |
| Zachęta | M_MONUMENT | #d9b98c / #7d7466 | |
| Kościół Wszystkich Świętych | M_MONUMENT | #ddcfaa / #6e7f6e | |
| Kościół św. Aleksandra | model (M_MONUMENT drum) | #ebe4d2 / #7f8f88 | `_build_aleksander` (spec aleksander.md, 2026-11-01): drum, windows, copper dome, lantern, cross, a six-column portico on each end; heights estimated |
| Hala Gwardii | model (not a skin) | #a85c40 / #6d7470 | `_build_gwardii` (spec gwardii.md, 2026-11-01): Mirowska's twin, symmetric, a portal at both ends, 16 pilasters a side measured from the outline; 1212 tris |
| Hala Mirowska | model (not a skin) | #a85c40 / #6d7470 | `_build_mirowska` (spec mirowska.md, 2026-11-01): brick walls with round-headed windows between pilasters, nave roof with glazed lantern, gable ends, four corner turrets, red-roofed west annex; 1458 tris |
| Sejm RP | M_MONUMENT + hall model | #e2e0d8 / #8d8f8c | `_build_sejm` (spec sejm.md, 2026-11-01): plinth ring, fifteen-column curved colonnade, entablature, attic and eave cornice round the plenary hall's arc (fitted r 21.75 m, centre -> world 277.1, 967.5); heights estimated |
| MDM (all tall unnamed blocks around Plac Konstytucji + Marszałkowska to Plac Zbawiciela) | M_MONUMENT | #cdbfa3 / #7f7b74 | `_find_mdm`, one card; candelabras = street furniture |
| Dom bez Kantów | window seed 0.37 (modernist rows) | #d3cec2 / #85837e | PLAC_SKINS; check_sites (skin) ; colours are guesses |
| Departament Wojskowej Służby Zdrowia | M_MONUMENT | #dccfb2 / #7c7871 | PLAC_SKINS; check_sites (skin) |
| Unnamed block at Królewska (-660,-790) "krolewska" | M_MONUMENT | #d9d0bb / #7f7c76 | NO card, not on picking grid |
Plus the Old Town / New Town tenements: `map_builder._tenement_facades` (each LoD2 wall takes colour + window seed of the OSM house under it, 9-colour palette, tile-red roofs; HISTORIC circles (-760,-1680,r200), (-830,-1920,r170), plus the MARIENSZTAT polygon (2026-11-01: the 1949 estate's 47 houses, edges along streets and party walls so no house is split); churches excluded). Dormers and chimneys on the slopes (OldTownRoofs.dress), stepped gables on the Old Town square's east side only.

#### 1d. Other bridges (map, no landmark site)
Decks are generic: `map_builder._build_bridge_structures` + `_decks`/`_deck_gaps`, `_build_guard_rails`, `_build_banks`, `_build_fill_sides`, approaches `fills`, abutments from bake_roads/bake_structures; concrete #b8b2a7, piers for road/rail. Which named bridges exist in the map: ? (no names in decks data; the DEVELOPMENT.md mentions Poniatowski and Świętokrzyski only; Gdański, Łazienkowski, Śląsko-Dąbrowski, Siekierkowski are probably in bbox but have no model and no card: ?). Backlog items: "stadium, the bridges" are in the re-pass list.

### 2. Named outlines in centrum.json `landmarks` with no site / skin / tower / case (generic LoD2/OSM only)
`landmarks` has 870 entries (837 distinct names). 782 distinct names are NOT referenced by landmarks.gd (all but ~55). Most are small (embassies, Kamienica ..., shops, kebab bars). The notable ones still generic (by type):
- **Churches / religious**: Bazylika Katedralna św. Michała i św. Floriana (Praga cathedral), Katedra polowa Wojska Polskiego, Kościół Zbawiciela (Najświętszego Zbawiciela), Kościół Matki Bożej Jerozolimskiej, Kościół Wizytek, Kościół św. Karola Boromeusza, Kościół św. Ducha, Kościół św. Jacka, Kościół św. Marcina, Kościół Piotra i Pawła, Kościół Matki Boskiej Zwycięskiej, Kościół Ewangelicko-Reformowany, Kościół Świętej Trójcy (x2), Kościół Przemienienia Pańskiego, Kościół Wniebowzięcia NMP i św. Józefa, Kościół św. Antoniego Padewskiego, Cerkiew Zaśnięcia NMP, Synagoga Nożyków, Klasztor Dominikanów, Kapucynów, Wizytek, Pallotynów, Krzyż Papieski.
- **Palaces / historic**: Zamek Ujazdowski, Zamek Ostrogskich, Biały Pałacyk, Pałac Branickich (x2), Pałac Czapskich, Pałac Kazimierzowski, Pałac Krasińskich, Pałac Potockich, Pałac Zamoyskich (x2), Pałac Mostowskich, Pałac Prymasowski, Pałac Blanka, Pałac Paca, Pałac Lubomirskich, Pałac Jabłonowskich (Urząd Miasta), Pałac Pod Blachą, Pałac Ślubów, Pałac Błękitny, Pałacyk Wielopolskich and ~30 more pałacyk/pałac, Baszta Prochowa, Brama Zachodnia, Wieża Zegarowa, Biblioteka Królewska, Arsenał, Collegium Nobilium.
- **Culture / civic**: Teatr Narodowy, Teatr Polski, Teatr Powszechny, Filharmonia Narodowa, Warszawska Opera Kameralna, Muzeum Sztuki Nowoczesnej (new MSN, spec in BACKLOG/first-scene.md), POLIN, Muzeum Niepodległości, Planetarium Niebo Kopernika, Poczta Główna, Narodowy Bank Polski, Gmach Giełdy, Senat RP, Kancelaria Senatu, Sąd Najwyższy, NSA, ministries (Finansów DONE 2026-11-01, spec `mf.md`; Sprawiedliwości, Obrony Narodowej etc.), Polskie Radio, Telewizja Polska, Politechnika main building (Gmach Główny PW), UW faculties (Pałac Kazimierzowski etc.), Biblioteka Publiczna.
- **Stations / sport / halls**: Dworzec Gdański, Powiśle, Stadion, Warszawa Wschodnia, Śródmieście, Ochota; Torwar, Hala Gwardii, Hala Koszyki, Narodowe Centrum Sportu (the stadium's name; stadium is found by masts, not this outline), Elektrownia Powiśle, Elektrownia Tramwajów.
- **Hotels / towers / malls not in TOWERS**: Hotel Bristol, Polonia Palace, Metropol, Mercure Grand/Centrum, Radisson Blu Sobieski, Sheraton, Holiday Inn, Pekao Tower, PZU Tower, JM Tower, Warsaw Towers, Atlas, Prosta Tower, V Tower, Concept Tower, Crown Tower/Square/Point, North Gate, Sienna Center, Vitkac, Feniks, Żyletkowiec, Pasaż Saski, Hala Koszyki, Wola Center, Centrum Marszałkowska, Atrium Plaza/Centrum, Equator, Ethos.
(A dump of all 782 names can be regenerated with: python3 -I script comparing `landmarks[].name` to the `"osm"` and `_landmark("...")` strings in landmarks.gd.)
Handled outlines (found by `_landmark("name")`): Pałac Kultury i Nauki, Złote Tarasy (Lumen and Skylight built inside it), Rotunda PKO, Varso Tower, Westfield Arkadia, Hotel Europejski, Grób Nieznanego Żołnierza, Metropolitan, Sofitel Victoria, plus TOWERS/SKINS/PLAC_SKINS names. Found by point or box instead (no named outline): Muzeum Narodowe, MDM, Forest, HUB B/C, Krolewska block, Zygmunt, flag, Świętokrzyski, Poniatowski towers, Stadion, Centralna.

### 3. Street furniture and props (how built)
| Type | Where | Built how | Notes |
|---|---|---|---|
| Street lamp | map `lamps` (+ bake-added bridge lamps) | `_make_shared` "lamp", box mesh, head marked by `_mark_head` (UV.x=1, glows at night via fixture.gdshader); halo sprites `_build_lamp_halos` | MultiMesh; car drives through |
| Historic lantern (cast-iron, 4-sided lantern, finial) | Royal Route + Old Town (`_royal_segments`, HISTORIC) | shared "lantern" boxes | |
| Candelabra (3 lanterns, stone plinth) | Plac Konstytucji, CANDELABRAS (-533.8,1282.4, r75) | shared "candelabra" | MDM's |
| Traffic signal | map `signals` | shared "signal" boxes (3 lamps) | |
| Bench, bin, bike rack | `benches`, `bins`, `bikes` | shared boxes (wood slats, green bin, rack), `_props`, no shadow, not obstacles | easy-driving loop |
| Advertising column (litfaza) | `columns` | green foot/cap cylinder, gold cap, per-column poster tint (POSTER) | not obstacle |
| Bus/tram shelter | `shelters` | glass roof, back/side glass, lit poster box (SHELTER_POSTER, glow), bench, blue D-15 stop sign; solid (4 m) | landmarks loop redo; `buses.gd shelters_in` places |
| Trees | `trees`/`trees3d`/palm | broadleaf + conifer meshes MultiMesh; Palma de Gaulle'a = `props.palm()` with neon ring | |
| Parked cars | `parked` | `Models.parked_mesh()` ~40 tris, tinted PARKED_PAINT | |
| Neon shop signs | ground floors facing streets | `neon_signs.gd` 5x7 pixel font atlas, words KEBAB 24H, BAR MLECZNY, APTEKA, KWIATY, HOTEL, KANTOR, PIZZA, KLUB, NOCNY + LANDMARK_WORDS (SAMSONG, ARKADKA, PREZYDENT, NOWOTEL, WESTYNKA, CHILTON, INTERKONTI) | `_build_neon`, `_build_landmark_signs` |
| Frogs shop (Żabka parody) | junction corners (storefronts.gd) | `props.frogs_shop()` ~430 tris + FROGS fascia, lily-pad sign | stamp card |
| Venue neon fascias (17+1) | storefronts.gd `_venue_neon` | rows in neon atlas | |
| Leżak (e-scooter) + parking zone | storefronts.gd | `props.lezak()` <=120 tris; `add_scooter_zone` | |
| Metro entrance | by metro stations | `props.add_metro_entrance` 330-830 tris (2026-11-01, M1/M2 at the 81 street `subway_entrance` pois, form by `f`: vaulted glass canopy / granite stairwell / footway passage mouth; treaded opening, handrail, red lit M post, glass lift on 3 in 5); sector mesh, no draw call added; Mac look check parked | |
| Payphone | Plac Konstytucji | `props.add_payphone` 120 tris | |
| Kebab stand (+named: U Zdzicha, Na Cienkim) | jobs / storefronts | `props.kebab_stand()`, `named_kebab_stand()`; pixel KEBAB board lit | |
| Pędzik courier + bike | roads/kebab stands | `props.pedzik_rider()` <=300 tris, morph family | |
| Mermaid / Syrenki (20) | by kerbs (syrenki.gd) | `props.mermaid()` scaled, one MultiMesh | |
| Syrenka of the Old Town Market Square | in the fountain (landmarks.gd `_build_syrenka`, spec rynek.md) | hand-built bronze figure on a pedestal, 394 tris, card "Syrenka" | |
| Pigeons, roadwork barrier, cone, dig, REMONT sign, billboard frame+poster, standing person, armchair man | eggs/jobs | `props.gd` boxes | |
| Vehicles (car, taxi, van, bus, tram, police, rivals, player hatchback), pedestrians | traffic.gd etc. | `models.gd` Shape/loft kit, not street furniture | |
| Kiosks, tram stop platforms, green bins | | NOT in baked data / only platforms (`_build_platforms`) | listed as "next candidates" in BACKLOG |
| Kerbs, medians, islands, guard rails, steps, rails, crossings, markings, symbols, walls, garage doors, bridge piers | ground builders in map_builder | `_build_kerbs/_medians/_islands/_guard_rails/_steps/_rails/_crossings/_markings/_symbols/_walls/_garage_doors/_bridge_structures` | |

### Counts (by category, from landmarks.gd)
- Info cards: 66 (Rynek Starego Miasta and Syrenka added 2026-11-01). Sites in code: ~66 (TOWERS 29 + Varso/Palace/Tarasy/Rotunda/Stadium/Centralna/Poniatowski + SKINS 15 + PLAC_SKINS 2 + Krolewska + MDM + 9 hand-built extra).
- Hand-built hero/building models: 16 (Palace, Tarasy, Rotunda, Varso, Stadium, Centralna, Muzeum Narodowe, Europejski, Metropolitan, Wiktoria, Arkadka, Forest, plus Poniatowski towers, Świętokrzyski, Zygmunt, Grób, Flaga as monuments/bridges: total 17 with flag).
- Towers by TOWERS table: 29 (2 custom builders: Złota 44, Spire). Hand-built tower: Varso (+Forest).
- Skin-only: 15 (SKINS) + 2 (PLAC_SKINS) + 1 uncarded + MDM = 19 sites.
- Monuments: 3 (Zygmunt, Grób, flag). Bridges with a model: 2 (Poniatowski towers, Świętokrzyski pylon).
- Triangle budgets exist only for 5 sites (muzeum, europejski, grob, metropolitan, wiktoria).
