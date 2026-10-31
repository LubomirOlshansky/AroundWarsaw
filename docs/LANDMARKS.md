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
| 0.1 | `check_mesh_quality.gd`: z-fighting, zero-area and flipped triangles, floating parts, per site, in `verify.sh` | gameplay-dev (Opus brief, Sonnet build) | the defects a judge misses; BACKLOG "Model checks from the research" |
| 0.2 | Triangle budgets in `check_sites.gd` for every hand-built site (only 5 of 17 have one) | object-modeler | detail without a limit can't be accepted |
| 0.3 | A flag rendering one landmark alone, unlit and as a silhouette, and the `first` shot set | gameplay-dev | the judge's shots (skill section 5) |
| 0.4 | `tools/check_spec.py` and the skill's evals (Palace, Rotunda, MSN) | main session | no build from an open spec |

### P1. Heroes to L3 (the first minute, the skyline, the postcards)

| # | Object | Today | To do | Photos |
| --- | --- | --- | --- | --- |
| 1.1 | Muzeum Sztuki Nowoczesnej | generic white LoD2 parts, no card | new model: white box, arcade, window slot, skylights, card (docs/design/first-scene.md) | 4 + ortho (no Marszałkowska front yet) |
| 1.2 | Pałac Kultury i Nauki | model (tiers, pinnacles, spire, clocks) | re-pass against photos: proportions of the tiers, attics, the side wings and the Congress Hall | yes |
| 1.3 | Rotunda + Domy Towarowe Centrum (the Eastern Wall) | Rotunda model; the stores generic | Rotunda re-pass (today's teal glass); the three glass stores and the pavilions as a model | yes |
| 1.4 | Złote Tarasy | model (glass wave) | re-pass: the wave's shape against the orthophoto, lit dome at night | yes |
| 1.5 | Varso, Złota 44, Warsaw Spire, Rondo 1, Q22 | Varso, Złota 44 and Spire own geometry; Rondo 1 and Q22 from the tower table | re-pass of the skyline against photos, crowns first | Varso, Złota 44, Spire, Rondo 1 yes |
| 1.6 | Zamek Królewski + Plac Zamkowy | skin only (colour) | model: the clock tower, the facade's bays, the roof; the square's paving round the Column | yes |
| 1.7 | Stadion Narodowy | model (weave, masts, membrane) | re-pass against photos and the orthophoto; the embankment round it | yes |
| 1.8 | Most Poniatowskiego | towers model, heights guessed | towers from photos; the deck's arches and balustrades | yes |
| 1.9 | Warszawa Centralna | model (shell roof) | re-pass; the canopy's AO | yes |

### P2. Named landmarks to L2 (today skins: colour only on LoD2)

| # | Object | To do |
| --- | --- | --- |
| 2.1 | Kościół św. Anny | portico of four columns, pediment, the bell tower (BACKLOG hand-over) |
| 2.2 | Teatr Wielki | the colonnade and the portico on Plac Teatralny |
| 2.3 | Old Town and New Town tenements | gables and dormers (map lane: `_tenement_facades`, the LoD2 roofs) |
| 2.4 | Archikatedra, Barbakan | the Cathedral's stepped gable; the Barbican's towers and walls |
| 2.5 | Pałac Prezydencki | the forecourt wings, the portico, the statue of Poniatowski in front |
| 2.6 | Kościół Świętego Krzyża, Wszystkich Świętych, św. Aleksandra | twin towers; the towers; the rotunda and dome |
| 2.7 | Sejm, Zachęta, Pałac Staszica, Kopernik, BUW, Hala Mirowska | facades and roofs from the photos |
| 2.8 | MDM and Plac Konstytucji | the blocks' arcades, reliefs, the corner towers |
| 2.9 | Towers missing from the table | PZU Tower, JM Tower, Pekao Tower, Warsaw Towers, Atlas, Prosta |
| 2.10 | Dom bez Kantów, Departament, the Królewska block | colours from photos (guesses today); a name for the block |

### P3. Still generic (L1 from LoD2), by how often a player sees them

| # | Group | Objects |
| --- | --- | --- |
| 3.1 | On the demo's routes | Teatr Narodowy, Hotel Bristol, Polonia Palace, Poczta Główna, NBP, Filharmonia, Hala Koszyki, Pałac Krasińskich, Arsenał |
| 3.2 | Churches and religious | Praga cathedral, Kościół Zbawiciela, Wizytek, Synagoga Nożyków, Katedra polowa, Cerkiew, the rest |
| 3.3 | Stations and halls | Gdański, Powiśle, Stadion, Wschodnia, Śródmieście; Torwar, Elektrownia Powiśle |
| 3.4 | Culture and civic | POLIN, Planetarium, Politechnika's main hall, Zamek Ujazdowski, the palaces (about 40) |
| 3.5 | Other bridges | Śląsko-Dąbrowski, Gdański, Łazienkowski: generic decks today |
| 3.6 | Street furniture | kiosks, tram stop platforms, Warsaw's green bins (BACKLOG "next candidates") |

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
| Pałac Kultury i Nauki | Śródmieście | landmark model | `_build_palace`: tiers from OSM parts (P_WINGS, P_COURTS, P_HALL), M_MONUMENT, M_STONE pinnacles, M_GOLD spire to 237 m, `_dial` clocks (M_DIAL, hands from shader, Warsaw time), M_ATTIC; Congress Hall drum | yes | check_landmarks (+ roof-rescue / spire-cell probe); no budget | Roof rescue lands on 28 m annex; user disliked "Palace" once, re-pass vs photos wanted |
| Złote Tarasy | Śródmieście | landmark model | `_build_tarasy` + `_wave`: glass wave over 8 mapped domes, M_GLASS_ROOF, glass rim walls; Lumen and Skylight kept | yes | check_landmarks | Dome not lit from inside at night (dusk list); user disliked look earlier |
| Rotunda (Rotunda PKO) | Marszałkowska x Al. Jerozolimskie | landmark model | `_build_rotunda`: granite plinth, 2 lit glass storeys M_PAVILION (warm), white overhanging roof with oculus, ribs; Rondo photos 2026-10-31: 24-tooth white zigzag crown, red and blue light in the glass under it, lit parody name BANK POLSKA on the south and east faces | yes | check_landmarks | none listed |
| Varso Tower | Chmielna / Rondo ONZ side | tower (hand-built) | `_build_varso`: M_GLASS slabs 177/205/230 m, dark spines, lit glass crown 193-234 m (M_PAVILION cool), one mast to 310 m, 5 rings, beacon | yes | check_landmarks | Antenna lattice unlit (dusk); Varso I/II OSM extrusions elsewhere |
| Stadion Narodowy (PGE Narodowy) | Praga, Saska Kępa side | stadium | `_find_stadium` (72 mast pairs give outline) + `_build_stadium`: M_WEAVE skin leaning out, 72 masts, M_MEMBRANE roof ring, red seats, needle on cables; `_beam` | yes | check_landmarks | Embankment bare terrain; AO/lamp maps still on LoD2 footprint |
| Warszawa Centralna | Śródmieście | station | `_find_centralna` + `_build_centralna`: grid of hyperbolic-paraboloid shell roof on mapped pillars, glass hall, canopy 140x86 m, turned -19.4 deg | yes | check_landmarks | AO ignores canopy |
| Most Poniatowskiego (towers) | Vistula, Śródmieście/Praga | bridge (towers) | `_find_towers` (bake seats 4 towers `data["towers"]`) + `_build_towers`: plinth, shaft with cornice, open arcade, pointed roof, finial; deck itself is map_builder decks | yes | check_landmarks (special-cased); no budget | Tower heights are a guess (top 15 m over deck); thin pale lines along deck |
| Most Świętokrzyski | Vistula, Śródmieście/Praga | bridge | `_find_swieto`/`_build_swieto`: concrete pylon leaning back 7 m (70 m top), 12+9 stays in one plane along the median; deck is map_builder's | yes | check_landmarks (needs 6 rays, not 10) | none listed |
| Kolumna Zygmunta | Plac Zamkowy, Old Town | hand-built monument | `_find_zygmunt` (circle zone r=4) + `_build_zygmunt`: stepped granite base, pedestal, 12 m shaft, capital, bronze king with cross and sabre | yes | check_landmarks | none |
| Grób Nieznanego Żołnierza | Plac Piłsudskiego | hand-built monument | `_build_grob`: granite platform, 2 rows x4 piers, round arches (`_arch`), entablature, tomb slab, wreaths, eternal flame M_LAMP glow | yes | check_sites BUDGET 600 | none beyond photo re-pass |
| Muzeum Narodowe | Al. Jerozolimskie east end | museum | `_find_muzeum` + `_build_muzeum`: `_simplify`d outline, plinth, wings 18.5 m with `_bays` (M_GLASS) and `_parapet`, raised entrance block 25 m with portal/piers/steps, `_tank` + `_field_gun` in east court | yes | check_sites BUDGET 2500 | Heights are estimates; army-yard placement a guess |
| Hotel Europejski | Krakowskie Przedmieście / Plac Piłsudskiego | palace/hotel | `_build_europejski`: rusticated base, M_MONUMENT pilaster floors, cornice, hipped roof, two forward bays with attics | yes | check_sites BUDGET 1500 | Heights estimates |
| Metropolitan | Plac Piłsudskiego | office landmark | `_build_metropolitan`: 3 blocks, curved M_GLASS fronts behind granite `_fins`, courtyard `_inside_wall`, 3 passages (dark panels), set-back 7th storey, plant rooms, paved court + round fountain | yes | check_sites BUDGET 3200 | Passages are dark panels, not open |
| Hotel Wiktoria (parody of Sofitel Victoria) | Królewska | hotel (parody) | `_build_wiktoria`: dark-glass podium S_DARK under stone fascia, ribbon slab S_BANDS, plant room | yes (parody only) | check_sites BUDGET 900 | Slab 30 m / podium 8 m / 18 m deep are estimates |
| Arkadka (Westfield Arkadia) | Rondo Radosława | mall | `_build_arkadia`: outline lifted as block, lit glass storey + pale panels to 21 m, roof-deck, 37 m tower with ARKADKA sign | yes | check_landmarks | Roof car-park race (DEMO 6.4) needs modelling |
| Forest (office) | north of Rondo Radosława | office | `_find_forest` (box) + `_build_forest`: tallest part = 120 m dark green glass tower with fins, other wings pale glass bands, planted roofs | yes | check_landmarks | none |
| Flaga na rondzie Radosława | Rondo Radosława | monument/prop | `_build_flag`: steel mast 57.8 m + 16x10 m flag in light wind (not in OSM; circle zone) | yes | check_landmarks | none |

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
| Widok Towers | S_FINS | - | - |
Not covered: PZU Tower, JM Tower (oddly mapped, generic glass), Pekao Tower, Warsaw Towers, Atlas Tower, Prosta Tower, V Tower, Concept Tower, Sienna Center etc. (generic).

#### 1c. Skin-only (kept LoD2/OSM massing, own wall + roof colour + facade mode; `SKINS` via `_find_skins`, `skin_at`, `_mark_zone`)
All with a card; check_landmarks only (except where noted). Open issue common to all (BACKLOG "Left"): colour-only, no portico/gables/towers modelled.
| Name | Mode | Wall / roof | Note |
|---|---|---|---|
| Teatr Wielki | M_MONUMENT | #ddd2b6 / #7fa894 | no portico |
| Centrum Nauki Kopernik | M_STONE | #5f5a54 / #6f9a4c | green roof |
| Biblioteka Uniwersytecka (BUW) | M_STONE | #7f9e8a / #6a9a52 | no rooftop garden detail |
| Zamek Królewski | M_MONUMENT | #c87560 / #6e5a4e | no tower/clock |
| Barbakan | M_GOTHIC | #ab5a42 / #6b4a3c | |
| Archikatedra św. Jana | M_GOTHIC | #9a4b38 / #6e3a2e | |
| Kościół św. Anny | M_MONUMENT | #e6dcc4 / #8a5a44 | portico + pediment + bell tower to model (centre -658,-1350) |
| Pałac Prezydencki | M_MONUMENT | #ece3cc / #6a7a77 | facade to model |
| Kościół Świętego Krzyża | M_MONUMENT | #e3d9c0 / #5d6e64 | towers, columns to model |
| Pałac Staszica | M_MONUMENT | #e2d6b8 / #5f6f6a | |
| Zachęta | M_MONUMENT | #d9b98c / #7d7466 | |
| Kościół Wszystkich Świętych | M_MONUMENT | #ddcfaa / #6e7f6e | |
| Kościół św. Aleksandra | M_MONUMENT | #ebe4d2 / #7f8f88 | rotunda/dome to model |
| Hala Mirowska | M_STONE | #a85c40 / #6d7470 | |
| Sejm RP | M_MONUMENT | #e2e0d8 / #8d8f8c | |
| MDM (all tall unnamed blocks around Plac Konstytucji + Marszałkowska to Plac Zbawiciela) | M_MONUMENT | #cdbfa3 / #7f7b74 | `_find_mdm`, one card; candelabras = street furniture |
| Dom bez Kantów | window seed 0.37 (modernist rows) | #d3cec2 / #85837e | PLAC_SKINS; check_sites (skin) ; colours are guesses |
| Departament Wojskowej Służby Zdrowia | M_MONUMENT | #dccfb2 / #7c7871 | PLAC_SKINS; check_sites (skin) |
| Unnamed block at Królewska (-660,-790) "krolewska" | M_MONUMENT | #d9d0bb / #7f7c76 | NO card, not on picking grid |
Plus the Old Town / New Town tenements: `map_builder._tenement_facades` (each LoD2 wall takes colour + window seed of the OSM house under it, 9-colour palette, tile-red roofs; HISTORIC circles (-760,-1680,r200), (-830,-1920,r170); churches excluded). No gables/dormers.

#### 1d. Other bridges (map, no landmark site)
Decks are generic: `map_builder._build_bridge_structures` + `_decks`/`_deck_gaps`, `_build_guard_rails`, `_build_banks`, `_build_fill_sides`, approaches `fills`, abutments from bake_roads/bake_structures; concrete #b8b2a7, piers for road/rail. Which named bridges exist in the map: ? (no names in decks data; the DEVELOPMENT.md mentions Poniatowski and Świętokrzyski only; Gdański, Łazienkowski, Śląsko-Dąbrowski, Siekierkowski are probably in bbox but have no model and no card: ?). Backlog items: "stadium, the bridges" are in the re-pass list.

### 2. Named outlines in centrum.json `landmarks` with no site / skin / tower / case (generic LoD2/OSM only)
`landmarks` has 870 entries (837 distinct names). 782 distinct names are NOT referenced by landmarks.gd (all but ~55). Most are small (embassies, Kamienica ..., shops, kebab bars). The notable ones still generic (by type):
- **Churches / religious**: Bazylika Katedralna św. Michała i św. Floriana (Praga cathedral), Katedra polowa Wojska Polskiego, Kościół Zbawiciela (Najświętszego Zbawiciela), Kościół Matki Bożej Jerozolimskiej, Kościół Wizytek, Kościół św. Karola Boromeusza, Kościół św. Ducha, Kościół św. Jacka, Kościół św. Marcina, Kościół Piotra i Pawła, Kościół Matki Boskiej Zwycięskiej, Kościół Ewangelicko-Reformowany, Kościół Świętej Trójcy (x2), Kościół Przemienienia Pańskiego, Kościół Wniebowzięcia NMP i św. Józefa, Kościół św. Antoniego Padewskiego, Cerkiew Zaśnięcia NMP, Synagoga Nożyków, Klasztor Dominikanów, Kapucynów, Wizytek, Pallotynów, Krzyż Papieski.
- **Palaces / historic**: Zamek Ujazdowski, Zamek Ostrogskich, Biały Pałacyk, Pałac Branickich (x2), Pałac Czapskich, Pałac Kazimierzowski, Pałac Krasińskich, Pałac Potockich, Pałac Zamoyskich (x2), Pałac Mostowskich, Pałac Prymasowski, Pałac Blanka, Pałac Paca, Pałac Lubomirskich, Pałac Jabłonowskich (Urząd Miasta), Pałac Pod Blachą, Pałac Ślubów, Pałac Błękitny, Pałacyk Wielopolskich and ~30 more pałacyk/pałac, Baszta Prochowa, Brama Zachodnia, Wieża Zegarowa, Biblioteka Królewska, Arsenał, Collegium Nobilium.
- **Culture / civic**: Teatr Narodowy, Teatr Polski, Teatr Powszechny, Filharmonia Narodowa, Warszawska Opera Kameralna, Muzeum Sztuki Nowoczesnej (new MSN, spec in BACKLOG/first-scene.md), POLIN, Muzeum Niepodległości, Planetarium Niebo Kopernika, Poczta Główna, Narodowy Bank Polski, Gmach Giełdy, Senat RP, Kancelaria Senatu, Sąd Najwyższy, NSA, ministries (Finansów, Sprawiedliwości, Obrony Narodowej etc.), Polskie Radio, Telewizja Polska, Politechnika main building (Gmach Główny PW), UW faculties (Pałac Kazimierzowski etc.), Biblioteka Publiczna.
- **Stations / sport / halls**: Dworzec Gdański, Powiśle, Stadion, Warszawa Wschodnia, Śródmieście, Ochota; Torwar, Hala Gwardii, Hala Koszyki, Narodowe Centrum Sportu (the stadium's name; stadium is found by masts, not this outline), Elektrownia Powiśle, Elektrownia Tramwajów.
- **Hotels / towers / malls not in TOWERS**: Hotel Bristol, Polonia Palace, Metropol, Mercure Grand/Centrum, Radisson Blu Sobieski, Sheraton, Holiday Inn, Pekao Tower, PZU Tower, JM Tower, Warsaw Towers, Atlas, Prosta Tower, V Tower, Concept Tower, Crown Tower/Square/Point, North Gate, Sienna Center, Vitkac, Feniks, Żyletkowiec, Pasaż Saski, Hala Koszyki, Wola Center, Centrum Marszałkowska, Atrium Plaza/Centrum, Equator, Ethos.
(A dump of all 782 names can be regenerated with: python3 -I script comparing `landmarks[].name` to the `"osm"` and `_landmark("...")` strings in landmarks.gd.)
Handled outlines (found by `_landmark("name")`): Pałac Kultury i Nauki, Złote Tarasy, Lumen, Skylight (kept), Rotunda PKO, Varso Tower, Westfield Arkadia, Hotel Europejski, Grób Nieznanego Żołnierza, Metropolitan, Sofitel Victoria, plus TOWERS/SKINS/PLAC_SKINS names. Found by point or box instead (no named outline): Muzeum Narodowe, MDM, Forest, HUB B/C, Krolewska block, Zygmunt, flag, Świętokrzyski, Poniatowski towers, Stadion, Centralna.

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
| Metro entrance | by metro stations | `props.add_metro_entrance` ~250 tris, own M post | |
| Payphone | Plac Konstytucji | `props.add_payphone` 120 tris | |
| Kebab stand (+named: U Zdzicha, Na Cienkim) | jobs / storefronts | `props.kebab_stand()`, `named_kebab_stand()`; pixel KEBAB board lit | |
| Pędzik courier + bike | roads/kebab stands | `props.pedzik_rider()` <=300 tris, morph family | |
| Mermaid / Syrenki (20) | by kerbs (syrenki.gd) | `props.mermaid()` scaled, one MultiMesh | |
| Pigeons, roadwork barrier, cone, dig, REMONT sign, billboard frame+poster, standing person, armchair man | eggs/jobs | `props.gd` boxes | |
| Vehicles (car, taxi, van, bus, tram, police, rivals, player hatchback), pedestrians | traffic.gd etc. | `models.gd` Shape/loft kit, not street furniture | |
| Kiosks, tram stop platforms, green bins | | NOT in baked data / only platforms (`_build_platforms`) | listed as "next candidates" in BACKLOG |
| Kerbs, medians, islands, guard rails, steps, rails, crossings, markings, symbols, walls, garage doors, bridge piers | ground builders in map_builder | `_build_kerbs/_medians/_islands/_guard_rails/_steps/_rails/_crossings/_markings/_symbols/_walls/_garage_doors/_bridge_structures` | |

### Counts (by category, from landmarks.gd)
- Info cards: 64. Sites in code: ~66 (TOWERS 29 + Varso/Palace/Tarasy/Rotunda/Stadium/Centralna/Poniatowski + SKINS 15 + PLAC_SKINS 2 + Krolewska + MDM + 9 hand-built extra).
- Hand-built hero/building models: 16 (Palace, Tarasy, Rotunda, Varso, Stadium, Centralna, Muzeum Narodowe, Europejski, Metropolitan, Wiktoria, Arkadka, Forest, plus Poniatowski towers, Świętokrzyski, Zygmunt, Grób, Flaga as monuments/bridges: total 17 with flag).
- Towers by TOWERS table: 29 (2 custom builders: Złota 44, Spire). Hand-built tower: Varso (+Forest).
- Skin-only: 15 (SKINS) + 2 (PLAC_SKINS) + 1 uncarded + MDM = 19 sites.
- Monuments: 3 (Zygmunt, Grób, flag). Bridges with a model: 2 (Poniatowski towers, Świętokrzyski pylon).
- Triangle budgets exist only for 5 sites (muzeum, europejski, grob, metropolitan, wiktoria).
