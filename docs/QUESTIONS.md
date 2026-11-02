# Parked questions and lanes in progress

The work doesn't stop for a question (docs/WORKFLOW.md "Backlog mode", the backlog-loop
skill): a question for the user is parked here with the default that was built, and the
session takes the next item. The user answers here, in a PR comment or in chat, in one batch.

## In progress

One session per lane. Add a row when you start an item, remove it when the item lands.

| Lane | Item | Session | Since |
| --- | --- | --- | --- |
| landmarks | One landmark per thread (now the Cathedral and the Barbican); order in BACKLOG "Landmarks lane, hand-over" | fresh Sonnet threads | 2026-10-31 |
| landmarks, map, gameplay | The railway: stations, track, catenary, trains (docs/design/railway.md) | cloud thread "Build railway stations and city rail lines" | 2026-11-01 |
| all | The audit beyond the landmarks: BACKLOG "Audit: what is verified beyond the landmarks", its P0 items handed out next | cloud thread "Audit what's left beyond landmarks" | 2026-11-01 |

## Waiting
- **2026-11-02 · content · Classic cinemas** — Mac look check for the seven cinema marquees (`Storefronts.CINEMAS`): is each sign on the right street and wall (positions are approximate, snapped to the nearest road and a wall within reach), readable by night? Also: where is Kino Wisła, and should Iluzjon (Narbutta, south of the map) get a pin on the full map? Default built: signs only, real names, no queue, no notebook card.
- **2026-11-02 · landmarks · Plac Bankowy** — Mac look check (the cloud has no photos, LoD2 or terrain): is the Blue Skyscraper's blue right (default #5f94c6 mirror, silver spandrels, cool podium; real photos show sky-blue to steel-blue), is the Treasury palace's yellow right (#e6d8a0 with grey-green roof; real is a pale yellow with white columns), what colour the Voivodeship wing really is (built as palace yellow; OSM says teal), the Arsenal's plaster and roof, Landau's house. Prebuilt path not baked in the cloud (`bake_city` fails on main's known site mismatches); skins use the same landmark outlines on both paths.
- **2026-11-02 · landmarks · Gdański Business Center** — Mac look check (site `gbc`, spec `gbc.md`): is this the right complex (tower at Inflancka, 74 m, two 45 m blocks, a 31 m block), the tower crown's slant direction and depth, the blocks' colour (pale blue-green here), logo boxes (AWIWA on the tower, NIELZEN on the blocks; the plaza between them is the map's own, unplanted extras not built). Default built from OSM and the four photos.
- **2026-11-01 · landmarks · Ujazdowski Castle** — Mac look check for Zamek Ujazdowski (`ujazdowski`): the facade's real colour (built cream), the copper roofs and tower caps (spire to 26.5 m), the entrance side (built west, onto the park path), the courtyard (built open; OSM maps an 8.8 m roof patch in it), the east bay. Also the `--prebuilt` look and bench. Built: the model in cream with copper roofs; look shots in the thread. Phone: drive Al. Ujazdowskie south to the castle, stop in its ring for the notebook card.
- **2026-11-01 · driving · Heli camera** — Phone feel check: does the helicopter's camera now turn with it while the stick is held (gain 1.1, as the car's Point), without the held direction circling? Built: camera follows while flying; a held direction keeps the screen it was set against, re-aimed at 20° (like drive_controls.gd). Not run in Godot (none in the cloud).
- **2026-11-01 · visuals · Bulwary life** — Phone look check: do the groups on the boulevard's steps and benches (Karowa to Kopernik, evening) sit where people would, and do the fast cyclists (30-41 km/h) read as fast, not as a glitch? Built: 9 chill spots, 45 % fast riders; default kept.
- **2026-11-01 · visuals · Retro filter** — Phone look check: does the new vaporwave Retro filter (Settings → Obraz, V key; the old VHS tape) read as 80s Miami neon, not muddy, by day and at night? Default built: pink and teal split-tone, soft bloom, light scanlines and grain; the Styl obrazu picker is removed (always Ostry). Where: PR "Rework retro filter".
- **2026-11-01 · landmarks · Grand hotels** — Mac look check for Hotel Bristol (colour of the facade, mansard, door position on Krakowskie Przedmieście) and Hotel Polonia Palace (colour, 25.5 m height, door on Al. Jerozolimskie); built: sand and cream walls, grey slate mansards, door at the middle of the longest street front.

- **2026-11-01 · landmarks · Old Town hotels** — Which tenements are the real Hotel Bellotto (Brukowa 12),
  Castle Inn (Świętojańska 2) and the Rynek aparthotel? Default built: the nearest tenement to each
  address's published spot, parody names KASZTEL INN, CANALETTO, STARÓWKA (`HOTELS` in landmarks.gd,
  `o` and `out` per hotel). Mac look check: is each front on the right house and street face, is
  the neon readable at night. Canaletto's front was not seen in the cloud render.

Newest first. One entry per question.

- **2026-11-01 · gameplay pass · phone checks** — F's six screenshots drive BACKLOG "Gameplay pass" G1-G13. Phone checks: (G1) a fresh save shows HELI at 0:00 and the map hold teleports; (G2) the Low default feels calm and the slider moves it; (G3) the zoom buttons clear the minimap and the pill; (G4) is Cruise easy enough (grip 16, turn pull 10, steer 0.14 s, soft gas; lane change at 50 km/h slides under 1.1 m/s), is Sport still wanted, how the Czułość slider (0.6x to 1.4x turn rate, middle = as is) feels at both ends, and do Settings → Jazda → Prowadzenie and the moved Tryb gry (now in Świat) read well; (G5) which wall-like blocks F meant (a photo of one helps). Defaults built: heli and teleport free, Low traffic, Cruise handling.

- **2026-11-01 · driving · photo mode and POMOC DROGOWA: phone check** — Fixed in the cloud
  (headless check and a game run: the car moved 0.00 m under Fotka; the button towed it onto the
  lane). Default built: the button is the last row of JAZDA's left column, always available on
  the ground (also mid-job or mid-chase; in the water it calls the water tow, in the air it does
  nothing). Phone check: open FOTKA by a wall for a minute and close it, the car stays; press
  POMOC DROGOWA, the card closes and the car is on the road with the "Towed free" toast.

- **2026-11-01 · landmarks · metro entrances: Mac look check** — Built in the cloud (flat
  ground). Default built: `Props.add_metro_entrance` per bake form (`canopy` vaulted glass over
  steel ribs with a red lit fascia, `steps` granite stairwell, `footway` stepped concrete walls),
  treads painted down the dark opening (the terrain has no hole, so the stairs are drawn, not cut),
  a 3.4 m red M post, a glass lift on 3 in 5 (hash of the position, not a real lift list). For F on
  the Mac: do the canopies sit right on slopes, is the red M readable at the default zoom, should
  every canopy have a lift, are the 3 `u` passage-only entrances fine without a canopy.

- **2026-11-01 · map · the land past the map's edge: Mac look check** — Built in the cloud,
  where the ground is flat. Default built (`scripts/map_edge.gd`): bare ground in the city's
  ground colour for the first ~40 m past the outline, then scrub green, fading into the sky's
  colour by 520 m; a tree line 10-70 m out; low blocks (8-30 m, a few to 60 m) 90-400 m out
  with lit windows at night; the rails and the main roads run 320 / 240 m on. On the Mac please
  look at Warszawa Wschodnia (`--at=1950,-1990`) and Dworzec Gdański (`--at=-2009,-2740`) by day
  and night: does the ring meet the real ground without a step or a gap, does the fade read as
  distance (not fog), are the blocks the right scale. Shots of the cloud look are in the PR.

- **2026-11-01 · landmarks · Krakowskie Przedmieście's photo check (K1-K6, M2)** — Built from
  the OSM outlines alone, so every height and a few spots are guesses (Default built, the specs'
  "photo check" notes list them). For F on the Mac, in order of how much they could be wrong:
  (1) Mickiewicz's monument: where on the lawn (today the lawn's centre) and which way it faces;
  (2) the University gate: whether the entrance is at (-494,-684) (the east frontage by Pałac
  Tyszkiewiczów-Potockich), its width and pylons; (3) Hotel Bristol: is the dome on the rounded
  north-east corner, and its height; (4) the Carmelite front's colours and number of pilasters;
  (5) Potocki's court front and the Kordegarda's height and roof; (6) Prus's and Wyszyński's
  statues (built from published coordinates, facings guessed): spots, facings, bronze colour;
  the granite setts' extent and tone on Krakowskie Przedmieście; Pałac Czapskich's colour; (7) Mariensztat's real reliefs' subjects and places, and the
  Rynek's well or fountain.
- **2026-11-01 · landmarks · the Old Town Market Square, the Syrenka and the decks: Mac look check**
  Built in the cloud with no photos (free-licence sources are not reachable from there). Default
  built: sand-grey paving with a border band and a pale disc, 58 café umbrellas in nine colours,
  the Syrenka 6.4 m tall (taller than life, to read from the camera) in lit-patina green bronze,
  Varso's deck on the crown's roof (the real deck is glazed, ~230 m) and St Anne's terrace on the
  tower's cornice at 25 m (the real one is higher, ~40 m, above the louvres). On the Mac please
  look at: the paving's colour with the real terrain under it, the umbrellas against the houses'
  plaster colours, the statue's pose (sword hand, shield side, which way she faces), the rim
  wall against the mapped pond, whether Varso's visitors stand on the crown's roof. Photos of
  the square's four sides (one per house front) would let the plaster colours be set per house.
- **2026-11-02 · content · the Zagłębie's names and Femina** — Default to build: KEBAB KRÓL MAZOWSZA, STAMBUŁ 24, DONER PASZA, U WUJKA ERDALA and the craft ZAKWAS I ROŻEN (spec `zaglebie-kebabowe.md`, section 2); Kino Femina keeps its real name with a red KINO / FEMINA fascia on the mapped building. Say if you want other names, or if the real shops' names should show instead. The Mac photo check of Femina's front is parked (BACKLOG).

- **2026-11-01 · content · the Norblin milk bar's name** — Default to build: **KROWA 2.0** (a bar
  mleczny rebuilt as a start-up, sign "BAR MLECZNY / KROWA 2.0", pale-blue tube, open 8-18 with a
  long lunch line). Say if you want another name. Also parked: the Mac look check of the four
  sites (BACKLOG "Norblin, Browary, Koszyki, Elektrownia").

- **2026-11-01 · content · the trains' parody names** — Default to build: KOLEJE MAZOWE (the
  green and white suburban units), SKiM (the red and yellow city line), INTERSZYBKO (the
  long-distance coaches). Say if any should change. docs/design/railway.md section 4.

- **2026-11-01 · store release · the Mac version** — Default: the native Mac App Store version is
  post-v1.0 (after the iPhone demo and TestFlight), on the same App Store Connect record as a
  universal purchase. Two calls for F: (1) say if the Mac should come before v1.0; (2) the iPhone
  build can also be offered on Apple Silicon Macs as it is (Pricing and Availability → "iPhone and
  iPad Apps on Apple Silicon Macs"): keep it on for the beta, or off until the native Mac build?
  Default: decide after trying the first TestFlight build on the Mac. Lane:
  docs/store/mac-and-gamepad.md.
- **2026-11-01 · driving · the gamepad's buttons** — Default built (gamepad.gd): RT gas, LT or B
  brake, Y car / helicopter, A / X the mission card, LB / RB turn the view, Start Settings, Back
  the map, D-pad zoom / radio / flash. Say if any should move once you try a pad.
- **2026-11-01 · content · parody names for the food-hype lore** — Default built: TIMBER (dating
  app, F's pick), Cringulo (food blogger, F's pick) with his grade MLASK (not the real catchphrase),
  KUKŁA (crêpes), KOSZTA COFFEE, GREEN CAFFE NERWO, HOTEL PIURE with its rooftop bar LUŹNO, ROBUR on
  Dom Partii's roof, the bars NEWTWICE, ZAMĘT and PIONEK. Say if any should change (fallback for
  Cringulo: "Mlaskacz"). docs/design/gaulle-and-food-hype.md section 2.

- **2026-11-01 · visuals · pavement colour** — R3 (docs/design/start-area-real.md) made the mapped
  footways Warsaw's grey concrete pavers. The wide pavements and squares drawn as plaza areas
  stay the warm granite beige the game always had. Default built: grey footways only.
  Alternatives: grey for every pavement and square (more like the street, less warm), or back to
  beige footways.

- **2026-11-01 · driving · does the vibration feel right on the phones?** — Crash sparks and the
  vibration fix (haptics.gd) were built and checked without a phone. Default built: every buzz at
  least 45 ms at 55 % strength, a crash up to 160 ms at full strength, on by default with the
  DOSTĘP switch to turn it off. Needs a device run on the iPhone (and an Android phone if one is at
  hand): crash into a few cars and walls, take a job; say if it's too weak, too strong or missing,
  and whether the first crash after a pause hitches.
- **2026-10-31 · gameplay · opening flyover** — How long the first launch's camera flight over
  the Palace down to the car should be. Default built: 7.5 s (skippable with a tap), with a
  WARSZAWA caption. Alternatives: 5 s, or 10 s with one more pass (the Eastern Wall and the
  Rotunda). docs/design/opening-flyover.md.
- **2026-10-31 · gameplay · opening flyover** — The guide's beats count from the flight's end, so
  the stand's arrow comes 10 s after you get control (17.5 s after the tap). Default built: that.
  Alternative: the arrow at once after the flight, since the flight already showed the square.
- **2026-10-31 · gameplay · first-10 polish** — Where a new game starts: on Marszałkowska's
  northbound side level with the Museum of Modern Art, facing north to the Świętokrzyska stand
  ~350 m ahead (the Palace on the left). Only a run that gets the guide starts there; the map's
  spawn (southbound by the Rotunda) stays for everything else. Default built: that. Alternative: a
  start nearer the stand (~150 m, DEMO's figure) at the cost of the museum in the first frame.
- **2026-10-31 · gameplay · first-10 polish** — The first mixtape lies on the University Library's
  roof (the roof garden by the boulevards) and gives the next PÓŁNOC FM track, +10 respect. Default
  built: that. Alternative: the Copernicus Science Centre's roof, right on the boulevards.

- **2026-11-01 · landmarks · the Eastern Wall stores' banners and west names** — The photo
  check's optional items: printed ad banners (A4) are built on the faces the game's camera sees
  (each south end and east face, 3 per store; since 2026-11-01 the 2025/26 mix: DO WYNAJĘCIA, FROGS XXL, KAPCIE, SAMSONG, LODY, PROMOCJA, WYPRZEDAŻ), not on the
  street (west) faces where the real ones hang, because the iso camera never sees those. The
  second small name on the west top-storey face (A6) is not built for the same reason. Default
  built: those. Alternatives: no banners, or banners on the west faces too.


- **2026-10-31 · landmarks · University Library (BUW)** — The four philosophers' columns stand
  on Dobra before the copper pages (the orthophoto can't show them; the Mac check kept them).
  The height follows LoD2 since 2026-11-01 (deck 15 m), the roof the orthophoto. Open: the
  south garden's beds are drawn as shrub, heather or lawn by a hash, not plant by plant; the
  four mapped vents at the north corner stand outside the outline as the city's plain drums.
  Default built: those. F to check against a photo or the street (docs/landmarks/buw.md).

- **2026-11-01 · landmarks · Ministerstwo Finansów** — Built from the outline and public facts only
  (no photo): pale pink-grey stone, rusticated ground floor, three storeys of bays, a cornice, a
  central risalit with three doors, hipped roofs on the two south pavilions (the court's fountain is
  the map's own). Mac photo check wanted: the real colour, whether the pavilions and the entrance
  rise above the roofline, the window rhythm and the entrance's column or pilaster count. Default
  built as above (spec docs/landmarks/specs/mf.md).

- **2026-11-01 · landmarks · the Palace's stone colour** — The Mac photo check (PR #128) finds the
  Palace's stone too warm: the photos show a cooler grey-beige (about #cfc6b5 in sun) than the
  game's sandstone #d8c49c (SANDSTONE in landmarks.gd, also the LoD2 bake's colour). Default
  built: the warm sandstone kept (it carries the golden-hour landing shot and the Dusk floodlight).
  Alternative: move SANDSTONE towards #cfc6b5 and re-shoot the landing.

- **2026-11-01 · landmarks · Copernicus Science Centre** — The Mac's photo check is applied
  (copper-red planetarium drum and dome, warm strip facade, craters and paths on the roof, the
  cantilever), and the re-check's roof layout (all seven craters, 2 + 3 + 2 with the stair head)
  and faceted planetarium with its dark clerestory. Still parked: the river corner's glazed
  ground floor (kept as built), the steel frame's stairs. Details:
  docs/landmarks/kopernik.md.

- **2026-10-31 · driving · quest stop assist** — Every pickup and drop-off (rescue, Podwózka,
  kebab and słoiki doors, "Na czasie", the Leżak depot) now has a 9 m ring (was 6-7), counts
  under ~16 km/h as stopped (was 4-9 km/h), and the car brakes itself into the ring when it heads
  in and holds still ~1.5 s; BRAKE at a standstill reverses out. Always on, no setting. Default
  built: that, plus (2026-11-01) a Settings → DOSTĘP switch to turn the auto-brake off (default on).
  Still open: the assist only on touch controls (keyboard players get it too).
- **2026-10-31 · gameplay · the main line** (docs/design/main-line.md) — The main line is the
  guide (first 10 min), then the ladder's next rival (a gold star on the minimap and the full map,
  pinned to the rim at any distance), then the final at night; the respect gates are lowered to
  0/100/220/340/480/640 and 850 (was ... 850 and 1100) so the final comes in about an hour, an
  estimate from the pay tables. Default built: that. To check: F times a fresh save on the phone;
  whether the on-screen edge arrow should also show the star, and whether a short goal line belongs
  on the driving screen (today it is on the full map only).

- **2026-10-31 · gameplay · the game map** — Teleport: free and unlimited, by holding a spot for
  0.6 s; refused during a race, a job, a rescue, a police chase and the first-drive guide. The
  districts' and ladder cards now sit behind a ≡ button (hidden when the map opens) so the map
  shows. Default built: those. Alternatives: a price or a cooldown on teleports, only to places
  already discovered, or the cards shown at open.

- **2026-10-31 · gameplay · loop 3h slice 4** — Who gets the guide: a save with no job done, no
  złoty, no rung beaten and the guide not finished; quitting before the first delivery repeats it.
  Default built: that. Alternative: once per install whatever happens.
- **2026-10-31 · gameplay · loop 3h slice 4** — On a fresh save the helicopter waits for the first
  rescue (the HELI chip hidden, H explains), or a helicopter-only call, or 7:00 of play. Old saves
  never see it locked. Default built: that. Alternative: never lock it.
- **2026-10-31 · gameplay · loop 3h slice 4** — Halina's first-race rubber band: pace 1.15 aiming
  25 m behind, ±0.012 a metre, 0.4-1.5, lifting off in her last 140 m for a close player; a player
  150 m behind races her plain. Default built: those (a 1-D model: 34 km/h wins by 2.4 s). F to judge
  on the phone.
- **2026-10-31 · gameplay · loop 3h slice 4** — Halina rolls up 6 s after the first delivery's card
  (or at 3:00 without one), waits 20 s for the flash back, tries 3 times 60 s apart; the finish is
  the Palm unless it is over 1.6 km by road. Default built: that.
- **2026-10-31 · gameplay · loop 3h slice 4** — The end card's "10 jobs" are every paid job kind
  (kebab, słoiki, rescue, Podwózka, round-up, "Na czasie") but races and the courier's bonus; old
  saves count from their totals. Default built: that; kept by the designer pass
  (2026-11-01, docs/design/pay-tables.md).
- **2026-10-31 · gameplay · loop 3h slice 4** — In the guide, Mirek's garage waits for 9:30 (and the
  first earnings), then its toast and an arrow; outside the guide it opens at the first earnings as
  before. Default built: that.
- **2026-10-31 · gameplay · loop 3h slice 4** — The spawn faces south on Marszałkowska, and the
  Świętokrzyska stand is ~530 m north (behind the car), so 6.2's "ring 150 m ahead" is an arrow at
  0:10. Default built: the arrow. For the first-scene thread: a spawn facing north, or a nearer stand.
- **2026-10-31 · content · loop 3h slice 4** — New words: the guide's toasts (first10.gd LINES),
  Halina's three first-race lines (rivals.gd FIRST_LINES), the ghost finger's hint and the end card
  ("Dzięki za grę! … a Palma… dalej sztuczna."). Default built: mine, reviewed in the designer
  pass of 2026-11-01 (player-neutral Polish, docs/design/pay-tables.md).
- **2026-10-31 · visuals · the dusk loop** — Dusk now matches the user's 16:20 photos: an overcast blue hour (slate-blue sky, flat cool light, no sun shadows, a soft glow) instead of the pink-violet sunset; Dawn, which reuses Dusk's palette, turns blue too. Default built: that. Alternative: keep the pink sunset as Dusk and add the blue hour as a sixth look.
- **2026-10-31 · landmarks · the dusk loop** — The towers' lit names are parodies: PREZYDENT (the Marriott tower's crown), SAMSONG (its band, as on the Spire), NOWOTEL, WESTYNKA, CHILTON, INTERKONTI. Rondo 1's tenants, PHN and the Bank Polski tower got no lit name (not sure which building wears which; no network to check). Default built: that. Alternative: name those too.
- **2026-10-31 · design · the first scene** — Where the game starts (the street the player sees first, to be polished for a "wow"). Default planned: Marszałkowska by Plac Defilad (the Palace, the new Museum of Modern Art, the Eastern Wall, the towers), where the spawn and the first-10-minutes script already are. Alternatives: Plac Zamkowy and the Old Town, Rondo Daszyńskiego's towers, Most Świętokrzyski. Plan: docs/design/first-scene.md.
- **2026-10-31 · design · the first scene** — The light of the first frame. Default planned: day, as decided on 2026-10-28. Alternative: a late-afternoon golden light for the first minutes, once the dusk thread's work lands.
- **2026-10-31 · gameplay · loop 3h slice 3** — "Trzy mosty" is 10.1 km by road (Rondo Daszyńskiego → Most Śląsko-Dąbrowski east → Most Świętokrzyski west → Most Poniatowskiego east → the stadium's south stands); the autopilot needs ~14.5 min of play, a player maybe 7–10. Default built: the full DEMO route. Alternative: a start nearer the river (e.g. Rondo ONZ) or two bridges.
- **2026-10-31 · gameplay · loop 3h slice 3** — Ladder thresholds 0/100/250/400/600/850, the final 1100 respect; race wins +100; the final pays 500 zł + 250 respect (rematches too). Default built: that, numbers for the designer to tune.
- **2026-10-31 · gameplay · loop 3h slice 3** — Rival pace: Halina 1.25, Słoik 1.3, Bartek 1.35, Seba 1.4, Zbyszek 1.45, Mike 1.5 (× the street's limit; was 1.45 for all); Seba in the final 1.45. Default built: those, guesses until F races Halina on the phone.
- **2026-10-31 · gameplay · loop 3h slice 3** — Once the final is open, at night Seba waits at the start held still (so his own rung can't be re-raced at night). Default built: that. Alternative: he cruises and only the marker waits.
- **2026-10-31 · content · loop 3h slice 3** — Six refusal lines (one per rival) and Seba's four final lines (`rivals.gd` RIVALS `refuse`, FINAL_LINES). Default built: mine, reviewed in the designer pass of 2026-11-01.
- **2026-10-31 · gameplay · loop 3h slice 4** — DEMO 6.2's first race: **decided, Pani Halina** (the
  ladder's first rung, stake 60; a win counts as her rung beaten), so Seba stays the boss of the
  final "Trzy mosty". DEMO 6.2's 1:30 row says so. Alternative: a Seba race outside the ladder.
- **2026-10-31 · gameplay · loop 3h slice 2** — The Palace's and the stadium's Syrenki stand 148 m and 211 m from their anchors (no ground street nearer). Default built: that (a 260 m fallback). Alternative: anchor them elsewhere in `syrenki.json`.
- **2026-10-31 · gameplay · loop 3h slice 2** — No hint for the Syrenki (no "?" marks, no minimap dot, no chime); only a cyan diamond over each and "Syrenki n/20" on the full map. Default built: that. Alternative: a chime under ~40 m or a dot once the district is discovered.
- **2026-10-31 · gameplay · loop 3h slice 2** — Rewards: 5 Syrenki open the "Łuska Syreny" paint, 10 give 150 zł and 50 respect, 20 open "Srebro Syreny" and 300 zł; +5 respect a find. Default built: that, numbers for the designer to tune with the ladder.
- **2026-10-31 · content · loop 3h slice 2** — The 20 Syrenki's names and lines (`game/data/syrenki.json`) and their places (one real statue, the Old Town's; the Powiśle statue stays an egg only). Default built: mine, for the designer's review.
- **2026-10-31 · gameplay · loop 3h slice 1** — District list: nine districts (Praga, Stare Miasto, Muranów, Śródmieście, Trakt Królewski, Powiśle, Wola, Śródmieście Południowe, Ujazdów i Łazienki); Śródmieście Południowe is not in DEMO 2.3, Mokotów left out (off the map). Default built: that. Alternative: fold Południe into Śródmieście.
- **2026-10-31 · gameplay · loop 3h slice 1** — District completion counts notebook places too (vision 4.1), plus eggs, Syrenki and jobs up to `jobs_goal` (3 hero, 2 other). Default built: that. Alternative: jobs, eggs and Syrenki only.
- **2026-10-31 · gameplay · loop 3h slice 1** — The starting district is discovered quietly, so its card never shows. Default built: that. Alternative: show it after the first 30 s.
- **2026-10-31 · gameplay · loop 3h slice 1** — +10 respect per discovered district. Default built: that; a guess, for the designer to tune with the ladder.
- **2026-10-31 · gameplay · loop 3h slice 1** — The discovery card reuses the note card (5.5 s). Default built: that. Alternative: a bigger centred card with its own sound (visuals lane, 3i).
- **2026-10-31 · gameplay · loop 3h slice 1** — The Palm (Rondo de Gaulle'a) counts in Śródmieście, not Trakt Królewski. Default built: that.
- **2026-10-31 · gameplay · loop 3h slice 1** — A save from a newer version is read but never overwritten, so that session's progress isn't kept. Default built: that. Alternative: write a side file.
- **2026-10-31 · gameplay · loop 3h slice 1** — Map lane ask: places for Ujazdów i Łazienki (it has none, so no "?" there and jobs-only completion) and a baked river line (the Praga line north of Śląsko-Dąbrowski is extrapolated). Default built: as is.
- **2026-10-31 · content · L-shaped map** — The notebook's 9 chapters × 8 cards rule: the new places
  (Rondo Radosława in `kiedys`, Arkadia in `codziennie`, Forest in `bary`) went in as ninth cards, the
  rule is now 8–10 per chapter and a chapter of 9 is drawn 5 × 2. Default built: that. Alternative: a
  10th chapter "Północ · Up north" (the chips row is already tight). The words for the 3 places are
  mine, for the designer's review.
- **2026-10-31 · visuals · L-shaped map** — The off-map tan (#c8b48e) is drawn on the minimap and the
  full map past the bounds as well as over the corner, so the edge reads the same everywhere.
  Default built: that. Alternative: tint only the corner. Wants an art-director look.
- **2026-10-31 · content · L-shaped map** — The streamed and prebuilt paths with the L were not seen
  here (derived index stale; every shot is `--monolithic`). Check on the Mac after
  `tools/setup_map.sh --if-needed`.
- **2026-10-31 · landmarks (content thread) · Plac Piłsudskiego 2** — Sofitel Victoria is shown as
  **"Hotel Wiktoria"** (Sofitel is a brand). Default built: Hotel Wiktoria, a 30 m slab on an 8 m
  podium (estimated). F can veto the name.
- **2026-10-31 · landmarks (content thread) · Plac Piłsudskiego 2** — Muzeum Narodowe raised to
  18.5 m wings and a 25 m entrance block (OSM's 4 levels gave 14.2 m). Default built: the new heights
  (estimates). Alternative: back to 14.2/20 m.
- **2026-10-31 · landmarks (content thread) · Plac Piłsudskiego 2** — Dom bez Kantów's card plays on
  "kant" (an edge, or a swindle): "Kantów tu nie ma." Default built: the pun. The unnamed block
  south-east of Europejski has no card (no name in the data).
- **2026-10-31 · landmarks (content thread) · museum and Plac Piłsudskiego** — Built from mapped
  footprints only, no photos: the museum at the mapped 14.2 m with a 20 m entrance block, the army
  museum's tank and gun in the east courtyard, Hotel Europejski's cornice at 19 m (estimated). Default
  built: as listed. With F's photos or a quick "taller/shorter" these are a few constants.
- **2026-10-31 · landmarks (content thread) · Plac Piłsudskiego** — Sofitel Victoria (a brand: would
  be "Hotel Victoria") and the Metropolitan's curved fins are not modelled; two black 2.5 m mapped
  boxes stand beside the Tomb. Default built: left as they are.
- **2026-10-31 · content · couriers** — The courier race's pace: the rider's time is the order's
  road distance at 10 m/s, so a player averaging 30–50 km/h wins about 2 in 3. Default built: that.
  Alternative: a fixed speed (e.g. 8.5 m/s), or tune after phone runs.
- **2026-10-31 · content · couriers** — Kerb riders ride 0.45 m from the kerb (parodies.md says 0.6 m;
  at 0.6 m AI cars would clip them). Default built: 0.45 m. Alternative: 0.6 m with AI cars nudging
  past riders (a traffic.gd change).
- **2026-10-31 · content · couriers** — Kerb riders: 3 by day, 5 at night, on top of the 4/6 path
  riders, all in the pool of 16. Default built: that. Alternative: read "3–6" as the total.
- **2026-10-31 · content · garage** — When does Mirek's garage open? Default built: after the first
  earnings (a job, any złoty, or an owned paint), not the 10:00 clock beat.
- **2026-10-31 · content · garage** — Prices: cream 150, pea green 180, Vistula blue 200, tram
  yellow 250, black 300, doughnut pink 350 zł; factory red free; Mermaid gold free at 5 eggs found.
  Default built: as listed (a guess to tune).
- **2026-10-31 · content · garage** — Black at night reads as a dark teal slate with silver stripes
  (a stronger glow so it doesn't vanish). Default built: that. Art director / visuals to judge.
- **2026-10-31 · content · garage** — The garage is on Brzeska (narrow, one-way; the ring fills the
  street). Default built: Brzeska. Alternative: a wider kerb on Ząbkowska or Targowa.
- **2026-10-31 · content · garage** — Mirek's 12 lines (dialogue group `garage`) were written in this
  loop. Default built: as written, for the designer's review.
- **2026-10-31 · content · vintage tram** — Without Live the clock's looks are always Friday, so the
  vintage tram (weekends 09:00–19:00) almost never runs and E39 is hard to find. Default built: the
  game's weekend only. Alternative: one run an hour in the Day look whatever the day.
- **2026-10-31 · content · vintage tram** — Hours and pace are guesses. Default built: 09:00–19:00,
  one 25-minute run an hour, 29 km/h (modern trams 40).
- **2026-10-31 · content · vintage tram** — E39 gives +30 and its line; the then card T13 waits for
  the older decades (F's "from 2010"). Default built: no card.
- **2026-10-31 · content · night buses** — The horn's key is **B**, because H already toggles the
  helicopter. Default built: B.
- **2026-10-31 · content · night buses** — The horn button's icon (a bell with sound arcs) reads like
  a volume button. Default built: the icon, no label. Alternatives: a "KLAKSON" label or a trumpet icon.
- **2026-10-31 · content · night buses** — E25's race against the night bus starts quietly. Default
  built: no card. Alternative: a "WYŚCIG Z NOCNYM · RACE THE NIGHT BUS" pill.
- **2026-10-31 · content · night buses** — A stop's random bubble can say the request line ("Żądam.")
  without a honk. Default built: left random. Alternative: keep that line for E24 only.

- **2026-10-31 · content · jobs-2 (courier race, round-up, payphone, armchair)** — The Leżak
  round-up follows parodies.md 5.3 (collect into the boot, unload at the depot), not pushing
  scooters with the car. Default built: the spec.
- **2026-10-31 · content · jobs-2** — Pędzik rides at 6.5 m/s and rarely beats a player; tune
  with `--courier-v=` on the phone. The race's gap reads high at the start when the order's
  lane is the far carriageway (jobs.gd's order picker, BACKLOG). Default built: 6.5 m/s.
- **2026-10-31 · content · jobs-2** — E40's card shows T17's line (+10) rather than adding a
  21st KASETA then card (that set is 2010–today). Default built: as said.
- **2026-10-31 · content · jobs-2** — The payphone (a small grey post by the bus shelter at Plac
  Konstytucji) and the armchair man (rust shirt, teal chair, Mokotowska, 1 day in 3, 08–20) are
  hard to spot in shots; art-director pass and a phone look. Default built: as made.

- **2026-10-30 · content · MW-2 (storefronts and parodies)** — The Frogs stamp card reaches 8 m
  from the door (parodies.md says 6 m), and 15 % of Podwózka passengers are `detour` (ask for a
  Frogs). Default built: 8 m, 15 %.
- **2026-10-30 · content · MW-2** — Pędzik couriers have their own MultiMesh (+1 draw call in view)
  rather than sharing the bikes'. The courier race and the Leżak round-up job aren't built (not
  cheap; BACKLOG). Default built: as said.
- **2026-10-30 · content · MW-2** — Billboards are text only until PixelLab pictograms can be
  made; the metro sign is a generic cream M on navy (no operator logo). Default built: as said.
- **2026-10-30 · content · MW-2** — `easter_lezak`'s English is trimmed to fit 70 characters: "A
  Leżak standing up. In its own zone. Someone should report this." Default built: trimmed.
- **2026-10-30 · map · MW-2's asks** — The bake should add `shop=convenience`,
  `railway=subway_entrance`, `amenity=bicycle_rental` and scooter-zone pois, and an address for
  Kruczkowskiego 3B; the shops find their walls at runtime today. Default: runtime placement.

- **2026-10-30 · content · F's asks** — LEVEL 26 costs +2 draw calls at night in view (the
  violet band and the crowd cell with the roof crowd and the door queue) against a +1 target.
  Default built: both kept; 0 by day and beyond 350 m.
- **2026-10-30 · content · F's asks** — With the pedestrian slow zones off (the new default),
  should the guards still whistle as flavour? Default built: no whistle, run or guards' car; the
  clamp stays.
- **2026-10-30 · content · F's asks** — The full map shows "?" marks only within 400 m of the
  car (the minimap's rule) so it doesn't spoil the notebook. Default built: 400 m.
- **2026-10-30 · content · F's asks** — The shop sign: "FROGS" with the blade disc keeping
  "24", or "Frogs 24" as the name? Default built: Frogs, the disc says 24.
- **2026-10-30 · store release · Android back** — `quit_on_go_back` is Godot's default (true):
  the back gesture may quit the app instead of closing the full map. Check on an Android phone.
  Default built: unchanged.
- **2026-10-30 · performance · full map** — The 3D city still renders under the open full map
  (paused). Stop it while the map is open? Default built: not done.

- **2026-10-30 · content · MW-4 (everyday life and trends)** — How often does a trend move
  without Live? Vision says every third session. Default built: every 4 sessions. Live counts
  8-day cycles from 2026-01-05 rather than the ISO week.
- **2026-10-30 · content · MW-4** — E28 is built as "follow a Rowerilo rider 400 m" (vision: "to
  a dock"). The "Na czasie" job pays 51 zł on time, 21 late, no tip on days 6–7; the offer shows
  within 60 m of a slot, then waits 240 s. Default built: as said.
- **2026-10-30 · content · MW-4** — Kolka and Hyrax show only in Live (or `--zajac`), plus Hyrax
  in the fixed Day look before noon. Dogs are drawn 1.35× so they read. Default built: as said.
- **2026-10-30 · content · MW-4** — The player has no horn signal (car.gd, driving lane), so the
  AI cars' horns make the dogs bark for now. Default built: AI horns.
- **2026-10-30 · content · MW-4** — Cost cut: movers within 15 m of the car step at full rate
  (was 30 m); off-screen ones at 3.75 Hz. Default built: as said.

- **2026-10-30 · content · Podwózka's name** — F is thinking of renaming Podwózka (the lift
  app) to something like "zUber". Take: a near-Uber name carries trademark risk (the rule is
  parodies that don't lean on a real name or logo), and Podwózka already reads as a joke in
  Polish. Options: keep Podwózka / **Hopka** ("hop in") / **Wiozę** ("I'm driving you") /
  **Szofer** / "zUber" anyway. Default built: Podwózka, nothing renamed until F picks.

- **2026-10-30 · content · MW-3 (night and river crowds)** — A real sitting pose? Sitters are
  squashed standing figures; a real pose needs `actor.gdshader` work (visuals lane) or a second
  mesh (+1 draw call). Default built: squashed.
- **2026-10-30 · content · MW-3** — Guessed curves: Plan C's hours, the dawn curve (20 at the
  window's edges, 40 at 06–07), weekday factors, the guitarist 16:00–01:00, rain 0.1. Tune by eye
  on the phone. Default built: as listed in DEVELOPMENT "The night and the river".
- **2026-10-30 · content · MW-6 (eggs, KASETA, Spacer, Fotka)** — Words written in this loop
  need a designer pass: egg lines vision doesn't quote, the English egg names, and the 15 Kadr
  photo spots (`game/data/eggs.json`, `kadr.json`). Default built: as written.
- **2026-10-30 · content · MW-6** — The KASETA ghost is faint (dithered, reusing the building
  shader) and dim at night. Brighter needs a visuals-lane shader uniform. Default built: faint.
- **2026-10-31 · map · loading fix** — Far-target looks: the camera's look at a new target waits
  up to 1.5 s for its sectors, and on the iPhone 11 a few city-coloured proxies still flash past in
  flight (25 frames over 6 looks). Alternatives (camera lane): cut instead of flying for targets past
  ~1.5 km, or a shorter look; or 28 map slots (+5 MB). Default built: the 1.5 s wait.
- **2026-10-31 · map · loading fix** — "Tap to drive" waits for the start's sectors (870 ms on the
  iPhone 11, at most 8 s). Default built: on (the old way showed far-tower proxies at the start).
- **2026-10-31 · map · loading fix** — Jumps (tow, race start) load the view's sectors at once:
  1-2 extra frames over 33 ms per cut, instead of 0.5-1 s of proxies at the new place. Default built: at once.
- **2026-10-31 · map · content POIs** — Place addresses OSM has on non-home buildings (11, Kruczkowskiego
  3B among them) are baked as `address` pois with `v` = 1, so places and venues find them with no
  code change, but the job shuffles move (the kebab run's first order changed). Or a separate kind
  that leaves jobs as they were? Default built: `address` + `v`.
- **2026-10-31 · map · content POIs** — Leżak zones: "one per ~400 m" read as at least 400 m apart
  (56 zones), not one per 400 m of street (several hundred). Default built: 56.
- **2026-10-31 · map · content POIs** — Leżak density: parodies.md's guess of 30 / 12 per km²
  (468 scooters; about 3 per 300 m square, sparse at street scale). Default built: the guess.
- **2026-10-31 · map · content POIs** — Corner shops store no names, only `fr` for the chain the
  Frogs parody; or a parody-name field per chain? Default built: `fr` only.
- **2026-10-31 · map · map north** — Shape of the growth: only the west side of the north edge
  (an L, 1.04 km²), or the whole north strip (~3.9 km², Praga north and Dworzec Gdański too)?
  Default built: the L.
- **2026-10-31 · map · map north** — North edge at 52.2591 cuts the Jana Pawła II and Andersa
  viaducts; taking them in whole needs a new OSM, orthophoto and tree fetch past 52.2595.
  Default built: cut at 52.2591.
- **2026-10-31 · map · map north** — Looser LoD2 match: footprint share 50 % (8 models kept), or
  30 % (27 models, 44 blocks)? Default built: 50 %.
- **2026-10-31 · map · map north** — Outdated 2018 LoD2 models under much taller mapped buildings
  give way to OSM map-wide (46 models, mostly Wola: low sheds become the mapped towers as plain
  blocks), or only in the new area? Default built: map-wide.
- **2026-10-31 · map · map north** — Arkadia's roof car park: ~~left out of the bake~~ modelled 2026-11-01 as parked-car boxes on the deck (no ramps, no drivable deck); DEMO 6.4's car-park race would still need a drivable deck. Default built: static cars.
- **2026-11-01 · landmarks · Arkadia and Forest** — Mac photo check: Arkadia's real facade colours (cream/terracotta is a guess), whether the roof skylights are pyramids, where the real entrances are (canopies sit on the three longest faces); the Forest terrace: which wing really has it, its real size, BANK PEPEO's real height on the tower. Default built: that.
- **2026-10-31 · map · map north** — The flag mast on Rondo Radosława isn't in OSM: no placeholder,
  left to the landmarks lane (spot in DEMO.md 2.1). Default built: none.
- **2026-10-31 · map · 3e** — Ground under trenches: 1 m sub-cells only at tunnel portals and
  road cuttings (keeps the +1 % vertex budget), or a new builder feature that cuts the ground along
  a lowered corridor and draws the floor as one strip (would also fix the rail cutting and ~40 more
  findings for a few vertices per cell)? Default built: sub-cells; the strip is a follow-up loop.
- **2026-10-31 · map · 3e** — check_drive now drives all 98 structure routes (~2 s more), which
  surfaced allowlisted jumps at Poniatowski deck 13, Łazienkowski deck 20 and Towarowa. Default
  built: keep 98 routes (the alternative was back to 20, hiding them).
- **2026-10-31 · map · 3e** — Plac Na Rozdrożu's tube ends stop a few metres short of the street
  over them: extend a tunnel under any way crossing its open road within 15 m of the portal?
  Default built: OSM geometry kept, allowlisted with its cause.
- **2026-10-31 · map · 3e** — Portal headwalls are plain concrete; the new tall W-Z east headwall
  reads as a dark slab at night. An art pass on portal frames (lining, lamps)? Default: none
  until the art director picks it up.
- **2026-10-31 · map · 3e** — Parked cars at `PARKED_FILL` 0.27 (14,637 → 4,927) as asked. If
  it now looks too empty, it's one constant in `bake_osm.py`. Default built: 0.27.
- **2026-10-30 · map · 3d-2b** — A far level by zoom: draw the helicopter's highest views (above
  ~200 m) as painted proxies? Over the centre ~357 draw calls would drop to a few dozen, but those
  views lose their 3D detail. Default built: no far level, full detail everywhere (the orthographic
  camera shows no proxies today). Where: BACKLOG "From loop 3d-2b".
- **2026-10-30 · map · 3d-2b** — Map slots for the per-sector AO/light maps: keep 24 (32 MB) or
  raise to 28–32 for headroom (+5–11 MB)? The 3-minute soak reached 24 with no waits. Default: 24.
- **2026-10-30 · map · 3d-2b** — check_streaming's spot 8 limit (1 %): lower it now that it
  measures 0.015 %? Default: leave it until more runs agree.
- **2026-10-30 · map · 3d-2b** — Landmarks in the proxies need a LOD1 model from `landmarks.gd`
  (landmarks lane). Default: none until round 3f's landmark factory.
- **2026-10-30 · map · 3d-2a** — Clean the terrain at bake time (snap near-flat 20 m blocks within
  15 cm) so flat ground can merge into bigger quads? It would let ~47 % of cells merge but moves
  driving heights by up to 15 cm and needs a full re-bake. Options: snap / keep exact heights.
  Default built: keep exact heights. Where: BACKLOG "From loop 3d-2a".
- **2026-10-30 · map · 3d-2a** — Cut the ground along road edges (with skirts) rather than only
  dropping 10 m triangles fully under a cover? Default built: only whole covered triangles go;
  the full cut waits for a phone Metal trace showing ground fill under streets costs something.
- **2026-10-30 · map · 3d-2a** — Next flat-mesh target: footways (1.88 M vertices), grass (1.39 M),
  roads (1.21 M), kerbs (0.80 M). Default: footways first, after 3d-2b.

- **2026-10-30 · content · MW-5 (PÓŁNOC FM)** — Listen to the 7 new tracks (attached in the
  thread, or `--unlock=all --station=polnoc`): mood, balance, does the bass reach the phone's
  speaker? They're 22 kHz, 40 kbps to stay under 4 MB; raise it if you hear artifacts.
  Default built: as made.
- **2026-10-30 · content · MW-5** — New words for a designer pass: the day caption "powtórka ·
  rerun · the host is back at 22:00" and the unlock toast "Kuba ma nową płytę: „…”".
  Default built: as written.

- **2026-10-30 · content · 3g-2 (police, part two)** — Rescue escort: how often after the first
  rescue, and how fast? Default built: the first rescue always, then one in two; 45 km/h, 15–25 m
  ahead. Tell back after a phone run.
- **2026-10-30 · content · 3g-2** — The pedestrian-zone cap only cuts the gas: a car entering
  faster coasts down to 20 km/h. Brake it harder? Default built: coast down.
- **2026-10-30 · content · 3g-2** — The clamp card reads BLOKADA NA KOLE · ZDEJMUJĘ ZA 0:10 /
  WHEEL CLAMP ON · OFF IN 0:10. Wording for a game-designer pass? Default built: as written.

- **2026-10-30 · landing · beta form** — The aroundwarsaw.app sign-up form still posts to
  Stillplace's Formspree form (`mykaeqjp`), so beta sign-ups land in that inbox. Make a form
  for Around Warsaw on your Formspree account (free) and send its id, or keep the shared one?
  Default built: shared form, nothing changed. The id is one string in `site/src/index.html`
  (and the Polish page); then a redeploy. Where: BACKLOG "From the website".
- **2026-10-30 · performance · phone runs** — May I run the bench and a streaming soak on the
  iPhone 11 (a test build through Remote Control)? The Mac work is done (PR #27 memory −20 MB,
  #33 traffic, #35 bench result); what's left needs the phone: static memory on the iPhone 11
  (BENCH's memory line, before the beta), and whether a sector's load still makes a 25–65 ms
  frame there. Default built: nothing run on the phone. Where: BACKLOG "From the performance
  baseline", "From loop G0+".
- **2026-10-30 · landmarks/models · landmark models** — Do the towers now read as the real
  ones? Look at the before/after shots in the PR. Default built: 18 towers in their own skins
  and colours, Złote Tarasy golden, Muzeum Narodowe in stone, new bus shelters. Say which
  still look wrong and how. Where: PR (landmark models).
- **2026-10-30 · landmarks/models** — Złota 44's top is cut on a slope, high at its north end.
  Options: keep / high at the south end / flat. Default built: high at the north end.
- **2026-10-30 · web · deploy** — May I deploy the web build? It creates the Worker
  `aroundwarsaw-play` with the custom domain play.aroundwarsaw.app (a new DNS record in the
  aroundwarsaw.app zone) and uploads build/web (~141 MB), then redeploys the landing so the
  "Play online" button and the /play/ redirect go live. Both are public; `wrangler rollback` and
  deleting the Worker undo them. Default built: everything ready and tried locally; nothing
  deployed. Where: docs/DEVELOPMENT.md "The web build".
- **2026-10-30 · content · MW-1** — The chapter-complete card reads ROZDZIAŁ GOTOWY · CHAPTER
  DONE with "+50 zł, +30 ★". Wording for a game-designer pass? Default built: as written.
- **2026-10-30 · store release · app IDs** — The iOS bundle ID is still
  `com.olshanskysoft.nocnawarszawa`. Change it to `com.olshanskysoft.aroundwarsaw` before the
  App Store Connect record exists, or keep it? Nobody ever sees it (the home-screen and store
  name is "Around Warsaw" on both platforms). The Android package can't change: Play has had
  version code 1 under `com.olshanskysoft.nocnawarszawa` since October, and a new package
  would be a new app. Options: keep (both platforms match) / change iOS only. Default built:
  keep, as the rename of 2026-10-30 decided. **Answered 2026-10-31 by the user: change iOS only; done in `game/export_presets.cfg`** (Android stays). Where: `game/export_presets.cfg`, ROADMAP
  "rename + open source".

- **2026-10-30 · store release · store listings** — Ship the iOS app for iPhone and iPad, or
  iPhone only? Once an iPad version is on the App Store, later versions can't drop iPad.
  Options: iPhone and iPad (needs an iPad device pass) / iPhone only. Default built: nothing
  changed (the preset still says iPhone and iPad, which is fine for TestFlight; iPad
  screenshots are rendered). Decide before the first App Store release. Where:
  docs/store/app-store-connect.md section 10.
- **2026-10-30 · store release · store listings** — Account steps only you can do: create the
  App Store Connect app record and the Play listing from docs/store/, pick the support email
  (not written in the public repo), upload the first builds, invite testers. And a yes to
  redeploy aroundwarsaw.app so `/support/` goes live (the store forms link to it). Default
  built: everything written; nothing submitted.
- **2026-10-30 · visuals · night water (PR #11)** — Is the river's new night sheen right on the
  phone's OLED: too faint, right, too strong? Options: keep / stronger / fainter. Default built: the
  faint version (`ground.gdshader`, the `0.16 * broad` and `0.1` shore terms).

<!--
- **2026-10-30 · HUD · radio skip** — On the phone, holding RADIO for 0.5 s skips to the
  station's next track; a tap changes the station as before. Nothing on screen tells the
  player about the hold. Options: A: leave it hidden / B: a one-time hint on the ticker
  ("przytrzymaj RADIO: następny utwór · hold RADIO: next track") / C: a separate ⏭ button.
  Default built: A (the ticker shows the new track's name, so a skip explains itself).
- **2026-10-30 · HUD · fallback toast** — The first launch at Auto's coarser picture (after a
  session that struggled at the sharp one) now shows once: "Obraz prostszy, żeby było płynnie ·
  A coarser picture for a smoother ride · Settings → Obraz". It doesn't mention heat, because
  the struggle is measured frame time, not temperature. Options: A: as built / B: the backlog's
  "Obraz prostszy, bo telefon się grzał · the phone was struggling" / C: no toast. Default built: A.
- **2026-10-30 · performance · compressed map textures** — May I run one bench on the iPhone
  with the AO and lamp-light maps VRAM-compressed (BACKLOG "Memory still on the table")? On the
  Mac they look the same and textures drop 42 MB, but video memory rises 23 MB from a one-time
  allocation; only the phone shows which way it goes there. Options: A: one device bench, before
  and after / B: drop it. Default built: nothing landed (the code waits on its branch).
- **YYYY-MM-DD · lane · item** — The question in one line? Options: A / B. Default built: A
  (or "nothing built: waits"). Where: PR #N, BACKLOG "section".
-->

## Answered

Move an entry here with the user's answer and the date; its item goes back to the top of the
backlog. Lasting decisions also go into BACKLOG's "Decided" sections, DEMO.md or ROADMAP.

- **2026-10-30 · content · MW-3** — Queues stand at the place's point and the nearest footway
  until MW-2's storefronts exist; Smoła's queue lands in a passage hidden by a block from
  `--club=smola`. Default built: as said.
  **Answered 2026-10-30 (F):** as said (kept).
- **2026-10-30 · content · MW-3** — Night buses (E23, E25) need a small bus API in `traffic.gd`
  (driving lane), e.g. `spawn_bus(route, sign)`. Default built: not built, BACKLOG.
  **Answered 2026-10-30 (F):** not built, BACKLOG (kept).
- **2026-10-30 · content · MW-3** — Dawn is the last entry of Settings → TIME (so saved settings
  keep their meaning); E15's "three different days" uses the real date without Live. Default
  built: as said.
  **Answered 2026-10-30 (F):** as said (kept).
- **2026-10-30 · content · MW-6** — E31's reward was track 2, which is free from the start: it
  opens the next locked track instead. The 5 old eggs now pay +10 respect each. Default built:
  as said.
  **Answered 2026-10-30 (F):** as said (kept).
- **2026-10-30 · content · MW-6** — Spacer (wander mode) is a row in Settings → JAZDA, offered
  once by a toast; FOTKA is a button in Settings → OBRAZ. Default built: there.
  **Answered 2026-10-30 (F):** there (kept).
- **2026-10-30 · content · MW-5** — Chapters 1–5 unlock tracks 3–7; chapters 6–9 unlock nothing
  yet (vision: a horn tune and the gold cover later). Default built: as said; BACKLOG.
  **Answered 2026-10-30 (F):** as said (kept).
- **2026-10-30 · content · MW-5** — Until you pick a station, the radio follows the clock:
  PÓŁNOC FM at night, KEBAB FM otherwise. Keep, or switch only at launch? Default built: follow.
  **Answered 2026-10-30 (F):** follow the clock (kept).
- **2026-10-30 · content · 3g-2** — Stopping by a guard ends in a caution in the joke notebook.
  The routine first contact takes no Podwózka star. Keep both? Default built: as said.
  **Answered 2026-10-30 (F):** kept. F is also thinking of renaming Podwózka (e.g. "zUber"): parked as its own question above.
- **2026-10-30 · landmarks/models** — Hotel towers are named by address, not brand (rule:
  brands only as parodies): the InterContinental's card says "Emilii Plater 49", the Hilton's
  "Grzybowska 63", the Westin's "Jana Pawła II 21", the Novotel's "Marszałkowska 94/98".
  Default built: as said. Options: keep /
  parody names for the hotels.
  **Answered 2026-10-30 (F):** **parody names** for the hotel towers, not addresses (changed; landmarks lane's item).
- **2026-10-30 · content · MW-1 (the notebook)** — The minimap shows "?" for undiscovered
  places within 400 m of the car, because districts don't exist yet. Switch to "in a discovered
  district" once DEMO 6.3's districts land? Default built: 400 m.
  **Answered 2026-10-30 (F):** 400 m kept. F also wants the minimap to open full screen: BACKLOG "From loop MW-1" (HUD item).
- **2026-10-30 · content · MW-1** — Venue cards hide the street address (a venue's real address
  can name the real club, e.g. "Jasna 1" is on the denylist). Add a designer-written "safe to
  show" address per place? Default built: no address on venue cards.
  **Answered 2026-10-30 (F):** no address (kept).
- **2026-10-30 · content · MW-1** — The settings tab is ZESZYT · notebook, and the card's title
  becomes MOJA WARSZAWA on that tab (the full name doesn't fit as a fifth tab on the iPhone SE).
  Keep? Default built: ZESZYT.
  **Answered 2026-10-30 (F):** ZESZYT kept (it means "notebook").
- **2026-10-30 · content · MW-1** — Stadion Narodowy (115 m from any road) and Most
  Śląsko-Dąbrowski (65 m) can't be found by car with today's anchors: wider radius, or wait for
  the map lane's bake resolution? Default built: nothing changed; BACKLOG "From loop MW-1".
  **Answered 2026-10-30 (F):** wait for the map lane's bake (kept).
- **2026-10-30 · content · MW-0 (Moja Warszawa data)** — Where is the real "Apteka" bar you
  meant? Options: name the street / keep the default. Default built: APTECZKA in a Nowy Świat
  22/28 courtyard pavilion, marked `guess` in `game/data/places.json`. If the "Apteka" came from
  the song with "apteką" in its title, say so and it gets an invented name instead. Where: PR (MW-0).
  **Answered 2026-10-30 (F):** APTECZKA in the Nowy Świat courtyard (kept).
- **2026-10-30 · content · MW-0** — The then-and-now cards start in 2010 (the demo's "time
  tape"), so vision.md's 2009 blue hall and the 1990s items wait for later. Allow the blue hall
  as an exception? Default built: 20 cards from 2010 to 2024 (`game/data/then_cards.json`).
  **Answered 2026-10-30 (F):** from 2010, no blue-hall exception (kept).
- **2026-10-30 · content · MW-0** — Historic hall names "Hala Koszyki" and "Hala Gwardii" are
  kept as place names (they are also the halls' trade names); the new tower and museum are
  never named. Rename the halls descriptively ("Hala na Koszykowej")? Default built: kept.
  **Answered 2026-10-30 (F):** kept.
- **2026-11-02 · gameplay · G12** — Rescues are on the HELI line in the spec, but most calls are street/park rescues the ambulance car does well. Default built: rescue calls follow the vehicle (flying: roof/sandbar, driving: street/park/shore, heli-only ones in violet); the notebook does not list quests yet. Make every rescue heli-only and give the car only jobs? Default built: no.
- **2026-11-02 · gameplay · G10** — START KURS appears within 25 m of the waiting passenger and boards at once (the car is not auto-braked). Phone check: is a tap enough, or should driving through the ring start it too?
- **2026-11-02 · landmarks · Warsaw Spire** — Rebuilt from F's three photos and the map alone, so these are guesses to check on the Mac: (1) which rim the roof fin stands on (built: the east rim, peaking over the north half); (2) the entrance side (built: north, towards the plaza between the wings); (3) the canopy's size and the V legs' spread; (4) how much narrower the lobby is (built: 0.74 of the roof plan); (5) the wings' colour and top storey. Default built: that. Alternative: move the fin or canopy to the side the photos show.
