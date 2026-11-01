# Backlog — issues found along the way

Small problems that agents reported or that showed up in screenshots. They are fixed in the
"loop" stage after the roadmap versions (or earlier, when an agent is already in that file).

## Quest pickups and drop-offs too hard to stop on (the user, 2026-10-31)
- **Landed** (thread "Make quest pickup and dropoff easier"): stop_assist.gd, one shared 9 m
  ring and ~16 km/h "stopped" for every car stop zone, and car.gd's stop assist (brakes into the
  ring when heading in, holds for the quest's hold, never touches a car passing by;
  check_stop_assist.gd). Left: F to feel it on the phone (is the glide-in too firm or too
  soft: StopAssist.DECEL 9 m/s²; does a 9 m ring reach across the road at narrow doors).

## Top priority: a game-like full map with teleport (the user, 2026-10-31)
- **Landed** (thread "Make the map fun and game-like"): the full map in its own poster style
  (map_art.gd), 25 landmark pins (map_icons.gd), hold 0.6 s to teleport, the cards behind ≡.
  Left: street names along the main roads close in; F to judge the icons and colours on the
  phone (maybe hand-drawn or PixelLab icon art later); the first open on an older phone (the
  art is made on a worker thread at start, ~0.1-0.7 s on a computer).

## High priority: the main line and quest markers (the user, 2026-10-31)
- **Landed** (thread "Shape main line and quest markers", docs/design/main-line.md): the main line
  in three chapters (the guide, the ladder, the final) as `main_line.gd`; its marker a gold star on
  the minimap (pinned to the rim at any distance) and the full map (a goal card under the title, a
  legend); side quests keep a ringed dot in their colour and the start squares (now on the full map
  too); the ladder's gates lowered to 0/100/220/340/480/640/850 for a ~1 h main line.
  Left: a timed fresh-save run on the phone (the hour is an estimate); the edge arrow on the screen
  could carry the star too; maybe a short goal line on the driving screen (QUESTIONS.md).

## High priority: landmark and skyscraper models (the user, 2026-10-30)
- **The user dislikes how several models look** (2026-10-30): Złote Tarasy, Złota 44 and the
  other skyscrapers (Varso, Pałac Kultury, Warsaw Spire, Q22), Muzeum Narodowe (and Stadion
  Narodowy), the bus stops, and other weak models. Goal: keep the game's own pixel and
  low-poly style, but with colours, proportions and silhouettes that clearly read as the real
  buildings. Before/after shots at phone size. Lane "landmarks/models" (docs/QUESTIONS.md).
  **First pass landed (2026-10-30, ROADMAP "landmark models")**: 18 towers in their own
  colours, skins and crowns (Złota 44's white exoskeleton and sloped top, Warsaw Spire's
  diamonds, Rondo 1's open crown, Q22 at its real 155 m, Chałubińskiego 8's white ribs and the
  rest), each with an info card; Złote Tarasy's glass golden; Muzeum Narodowe in its pale stone
  with tall windows and a card; new bus shelters (glass roof, poster box lit at night, the
  blue D-15 sign). The Palace and the stadium were already detailed models and keep their look.
  **Second pass landed (2026-10-30)**: 9 more (Grzybowska 63, Jana Pawła II 21, Marszałkowska
  94/98: the hotels, now under parody names Chilton, Westynka and Nowotel; Central Tower, Ilmet, the Platinum Towers, Łucka City,
  Widok Towers): 27 towers in all. **Third pass (2026-10-30)**: 15 low-rise landmarks
  (Teatr Wielki, Zamek, Barbakan, Kopernik, BUW, churches, Sejm, Zachęta…) in their real colours.
  **Street furniture**: historic lanterns on the Royal Route and in the Old Town (2026-10-30). MDM's blocks and
  Plac Konstytucji's candelabras (2026-10-30).
  **Muzeum Narodowe and Plac Piłsudskiego (2026-10-31, the museum and Plac loop)**: ~~the museum
  only recoloured~~ is a real model (straightened outline, tall window bays, the raised entrance
  block with its portal, a parapet, a tank and a gun in the east courtyard); Hotel Europejski
  (rusticated base, cornice, hipped roof, central bays) and the Tomb of the Unknown Soldier
  (three arches, the eternal flame) are built, each with a card (`check_sites`). ~~Left there:
  the Metropolitan's fin skin, Sofitel Victoria and Królewska LoD2 only, the museum at 14.2 m~~
  **Plac Piłsudskiego part 2 (2026-10-31)**: the Metropolitan is a model (glass behind real
  granite fins, the round courtyard and fountain, three passages, the set-back seventh storey);
  the hotel on Królewska is **Hotel Wiktoria** (a slab of ribbon windows on a dark podium, a
  card under the parody name); the Królewska edge (Dom bez Kantów, the Departament, the unnamed
  south-east block) in its own stone; the museum's wings 18.5 m and entrance block 25 m.
  **Left**: Hotel Wiktoria's heights (slab 30 m, podium 8 m, 18 m deep), the museum's and
  Europejski's are estimates to set from photos; the Królewska-edge colours are guesses; the
  unnamed south-east block has no card (its name isn't mapped); the Metropolitan's passages are
  dark panels, not open; the army museum's yard placement is a guess (east courtyard).
  Next candidates: tram stop platforms, kiosks (not in the baked data yet), Warsaw's green bins. **Left**: PZU Tower and JM Tower (oddly mapped) keep the
  generic glass, and any model the user names next (docs/QUESTIONS.md).
  **Landmarks lane, hand-over (2026-10-31)**: since the first passes the lane also landed: the Rondo
  Daszyńskiego towers (The Warsaw HUB found by a point, `_tallest_at`; sloped crowns), the Old
  Town's and New Town's tenements split into their OSM houses' colours and tile roofs
  (`map_builder._tenement_facades`), brick Gothic for the Cathedral and the Barbican
  (`M_GOTHIC`), Sigismund's Column, map north (Arkadka with its lit sign, the Forest tower, the
  flag on Rondo Radosława) and Most Świętokrzyski's pylon and stays. **Left, for fresh threads**:
  St Anne's classical facade (a portico of four columns and a pediment on its west face; it is
  a kept skin today, outline in `centrum.json` landmarks "Kościół pw. Świętej Anny", centre
  (−658, −1350), the free-standing bell tower is a separate building to its north-east), the other
  churches (Holy Cross, All Saints, St Alexander's rotunda, the Visitationists) and the Palace
  on the Isle's neighbours, Staszic's facade (a colour-only skin today; Zachęta, Holy Trinity
  and the Presidential Palace became models on 2026-10-31, specs in docs/landmarks/specs/), the Old Town's gables and dormers (the LoD2 roofs have none), PZU/JM Tower. How the
  lane works: `landmarks.gd` sites (`TOWERS`, `SKINS`, fixed-position circle zones like
  `_find_zygmunt`), each needs a card in `INFO` and `check_landmarks`; a site found in
  `data["buildings"]` also needs its box in `bake_sectors.py` `SITE_AREAS`; after a change
  rebuild the prebuilt sectors with `bake_city.gd` (a renderer, never `--headless`); render
  before/after with the Mobile renderer on lavapipe (docs/DEVELOPMENT.md "Cloud rendering").

- **From the dusk loop (2026-10-31)**: still unlit after the user's 16:20 photos: Rondo 1's
  tenant names, PHN and the Bank Polski tower's crown (not sure which building wears which; the
  cloud has no network to check), Złote Tarasy's dome lit from inside, Varso's antenna lattice,
  Chałubińskiego 8's antenna and dark-glass refit (photo IMG_7104), the screens on the Marriott's
  podium. The canopy lamps and the crown names are small at the widest zoom; look on the phone.
  Art review (art-director, Opus): Centrum LIM's lit cells (the `S_GRID` skin, shared with the
  InterContinental and the Westin) are cold white and many, the photos show sparse warm ones
  (`#ffcf7a`, ~12 %, upper third); the landmark signs still glow inside the occlusion ghost.

## High priority: the first scene and the Museum of Modern Art (the user, 2026-10-31)
- **Muzeum Sztuki Nowoczesnej as it is** (the user, 2026-10-31): the new white box on Plac
  Defilad's east edge (Thomas Phifer, opened 2024). Today it is plain white LoD2 parts with no
  model and no card. Wanted: one long, low, matte white box, the arcade of square columns at its
  base with the glazed lobby behind, one long ribbon of windows at mid-height, a few big upper
  windows, long skylights on the flat roof, a card. Spec and the values still to set:
  docs/design/first-scene.md "Spec for item 1". Landmarks lane: Opus spec, `object-modeler`
  builds, `art-director` accepts. **Built 2026-10-31** (site `msn`, spec
  `docs/landmarks/specs/msn.md`, from the museum's OSM 3D parts). Left: the photo check on the
  Mac (the two city-room windows' faces and sizes and the skylight count are estimates; the
  photos in `refs/` were not reachable from the cloud), and TR Warszawa next door.
- **TR Warszawa's building site** (F, 2026-10-31): built as site `tr` on the empty plot west of
  the museum (a messy site: hoarding, dirt, heaps, old foundations, cabins, a digger, one
  crane). Left for the map lane: a mapped tree stands on the hoarding's north corner.
- **Złote Tarasy, the museum's way** (the user, 2026-10-31): **Built 2026-10-31** (site
  `tarasy`, spec `docs/landmarks/specs/tarasy.md`): the whole complex from its OSM 3D parts,
  the glass wave, the terraced sandstone podium, Lumen's crescent, Skylight with a lit crown,
  the drum, the planted south terraces. Left: the photo check on the Mac (Lumen's ribbons,
  Skylight's crown, the red entrance boxes), `tools/check_roads.py` on the Mac (needs
  terrain.json; its tarasy zone now mirrors the outline).
- **Recheck with the museum's approach** (the user, 2026-10-31): rebuild each from its real 3D
  map data, a spec in `docs/landmarks/specs/` passing `tools/check_spec.py`, the `--solo`
  silhouette and flat renders, zero defects in `check_mesh_quality`, a photo check on the Mac.
  In this order unless the user says otherwise: Pałac Kultury i Nauki, Warszawa Centralna, the
  Warsaw University Library (BUW, its green roof garden and the copper-green facade panels),
  the Copernicus Science Centre, Stadion Narodowy. **Warszawa Centralna built 2026-10-31**
  (site `centralna`, spec `docs/landmarks/specs/centralna.md`): the glass hall, the wings, the
  flat slab overhanging to 140 x 86 m and the hyperbolic paraboloid shells under it, all from
  the OSM parts. Left: the photo check on the Mac (OSM puts the shells in a 1.5 m tier wholly
  under the flat slab, so from the 30-degree camera they show only as a small zigzag at the
  two ends: if the photos show more of them, say so and the tier grows; the wings' walls; warm
  or cool hall light). **Stadion Narodowy built 2026-11-01** (site `stadium`, spec
  `docs/landmarks/specs/stadium.md`, PR #103's eyeball flag): the pitch was a 60 m blob under
  stands too deep; now a 105 x 68 m striped pitch along the masts' axis in two tiers with the
  boxes between, the skin red below and white above (the mapped rings), the raised rim, a
  rounded opening, the needle's hub and folded-roof drum from the OSM parts. Left: the photo
  check on the Mac (where the red ends, the opening's size). The others not started.
- **Models from real photos, more detail** (the user, 2026-10-31): specs were written from the
  OSM outline, LoD2 heights and memory; nobody compared a model with a photo. Now: reference
  photos per building in `refs/` (Wikimedia Commons, gitignored; fetched on the Mac, the cloud
  gets 403), specs written from them at a detail level (L2 for named landmarks, L3 for the
  heroes), triangle budgets instead of minimal geometry, and `art-director` scoring matched
  shots against the photos (the model-from-photos skill). Next: re-pass the hero landmarks
  (the first scene's buildings, the Palace, the Old Town square, the Castle, the towers, the
  stadium, the bridges) against their photos, worst score first. Wanted later: an automatic
  check for coplanar faces (z-fighting) in a site's mesh.
- **Model checks from the research** (2026-10-31; item (1) DONE the same day as `check_mesh_quality.gd`, the z-fighting, zero-area, floating and budget parts; its `KNOWN` ratchet is empty since 2026-10-31 (the z-fighting in the towers and the Palace is fixed); parts inside parts and T gaps are still open, report in the project files "Детальніші моделі
  будівель"): (1) `game/tools/check_mesh_quality.gd`, run on each landmark site's mesh arrays:
  coplanar overlapping faces (z-fighting: group triangles by plane, test 2D overlap, ~0.01 m²),
  zero-area and flipped triangles, parts touching neither the ground nor another part (FAIL);
  parts inside parts and T-junction gaps (WARN, for the art-director); per-site allow-lists;
  joins `tools/verify.sh`. (2) A game flag that renders one landmark alone, unlit and as a
  silhouette, for the judge's shots. (3) DONE 2026-10-31: `tools/check_spec.py`, which checks a landmark spec has every section and parts-table
column filled and a triangle budget, so a Sonnet build never starts from an open spec.
(4) OPEN (plan in the skill, section 7): evals for the model-from-photos skill: the Palace, the Rotunda and the Museum of Modern
Art (their photos exist) built with and without the skill, scored the same way. (5) Later:
golden-image shots runtime vs `--prebuilt`,
  a flicker probe (two frames, a tiny camera move, diff), the Old Town's gables and a
  straight-skeleton roof bake (map lane), fewer directional shadow splits (perf lane). The
  rubric anchors, photo-first judging, the parts table and the two-round cap are in the
  model-from-photos skill already.
- **The first scene, polished to the maximum** (the user, 2026-10-31): the place the player sees
  first must make a "wow". Default place: Marszałkowska by Plac Defilad (the Palace, the museum,
  the Eastern Wall, the towers), where the spawn and DEMO 6.2's first minutes already are; the
  choice is parked in docs/QUESTIONS.md. The plan, its eight items (the museum, the opening shot,
  the Eastern Wall and Rotunda, Plac Defilad's ground, Marszałkowska's street, life, sound,
  light), the `first` shot set, performance and the order of work: docs/design/first-scene.md.
  The dusk and night look there belongs to the thread "Match landmarks to Warsaw at dusk"; the
  hints, first order and first race to loop 3h item 6.

## Lore: coffee raves and arthouse cinemas (the user, 2026-10-31)
- **Shisha lounges** built (five parody signs, `Storefronts.LOUNGES`): only the phone can show the sign size on each wall and whether the spots read as lounges. Not notebook places; add smoky window glow or a door scene if wanted.
- **Asked**: add *coffee raves* and *arthouse cinemas* to Warsaw's lore. Content item, not built;
  the designer (`game-designer`, Sonnet for the text) specs it, `warsaw-tone` rules apply (real
  brands only as parodies, affectionate, Polish with English).
- **Coffee raves** (poranne kawowe imprezy): daytime, sober-ish dance mornings, a flat white in
  one hand and a DJ on a pallet stage. Real Warsaw has them in cafes, courtyards and on the
  Vistula boulevards (Sunday 10:00-14:00). Fiction: a morning counterpart to the five clubs. Two
  or three parody venues, e.g. **Kawa Zero** (a courtyard in Praga), **Flat Biały** (a
  Powiśle cafe with a terrace) and a pop-up on the Bulwary. Crowd: cargo bikes, oat-milk jokes,
  strollers with headphones, a queue for the barista rather than the door. Shut at night.
- **Arthouse cinemas** (kina studyjne): small screens in old halls, a bar, a repertory board.
  Parody names for the real ones: **Kino Muranek** (for Muranów), **Iluzja** (Iluzjon),
  **Kultura 24** (Kultura), **Elektroniczne** (Elektronik), **Kinoteka Pałacowa** (Kinoteka, in
  the Palace of Culture). Facade = a hand-painted poster board and a neon title strip; a hush
  rather than a crowd; a small queue before the evening show (18:00-21:00).
- **Fit with existing systems** (no new system needed):
  - *Notebook places*: each venue is a `places.json` entry with a card (`hours`, `district`,
    a note line), unlocked when you stop at it, like the Wiralek and the clubs.
  - *Venues with queues*: reuse MW-3's queue and hour curves: coffee raves peak Sun/Sat
    morning, cinemas in the evening. Neon fascia through `storefronts.gd`.
  - *Day/night schedule*: raves open 08:00-14:00 and are dark at night; cinemas the reverse.
    That gives the day a nightlife of its own, so a Day run is not empty.
  - *Eggs*: a DJ who plays only the horn tune; a film that is "three hours of a pigeon" on a
    Kino Muranek board; a cinema bar that only serves coffee at a rave and wine at a premiere.
  - *Radio / dialogue*: a morning DJ spot on the radio and one-liners in `dialogue.json`
    (rave-goers, ushers).
  - *Jobs*: a possible courier or taxi run: carry a DJ's crate to the rave, or a film reel to
    the cinema before the show (uses `rides.gd` finishes).
- **Open**: the final parody names (F's pick), whether raves are Sunday-only, and the
  locations (map lane: pick real addresses from `centrum.json` POIs). Default if unanswered:
  the names above, daily 08:00-14:00 at weekends only.

## From v0.6 (traffic, trams, pedestrians, rivals)
- ~~Cars can overlap briefly in complex junctions~~ (fewer by three quarters, the traffic loop
  2026-10-30: junction cars watch each other's body and path, `--traffic-overlaps` counts them;
  left: two cars entering a short merging curve in the same frame); a racing rival stuck in
  traffic passes through other cars when off screen.
- ~~Trams and crossing cars can touch nose to nose.~~ Down by nine tenths (the traffic loop
  2026-10-30: trams follow their rails ahead for cars' boxes, cars stop clear at any angle, no
  spawning beside a tram; `--tram-watch=N` with `--traffic-overlaps`); about 70 tram-car frames in
  three minutes remain near -1830, -220.
- ~~Name tags and bubbles show faintly through the translucent WIN/LOSE card.~~ Fixed by loop 2e:
  the result card is one of the HUD's floating panels, so it is in `hud.gd` `panel_rects()`, and
  `bubbles.gd` skips a name tag that touches one and places bubbles clear of them (checked
  2026-10-30 in the code; `check_hud` covers the layout).
- From the spawn point only two race finishes (the Palace, Złote Tarasy) fall inside the
  600–1800 m road window; add more finish places or widen the window by rival.
- The race and tail autopilots leave the car's collision off (like the mission autopilot);
  fine for screenshots, but autopilot runs can't test crashes.
- ~~Races pay respect only; the v0.65 side jobs add a shared złoty wallet (races, tips, rescues).~~
  Fixed in v0.65: races pay the rival's stake into the saved wallet.

## From earlier versions
- Rescue mission time limits are untuned. **Measured 2026-10-30** (a cloud thread, Linux headless,
  `--mission=N --autopilot --fixed-fps 60` from the spawn, calls 1-12): the car autopilot used
  31-39 % of the limit (call 4 Autonomia 50 of 145 s, call 3 Vistula shore 128 of 325 s), the
  helicopter 41-51 % on the roofs (call 6 Sheraton 59 of 135 s, call 2 Nowogrodzka Square 120 of
  235 s) and 31 % on street calls. The autopilot ghosts through traffic and drives the best line, so
  a player at 1.5-2x its time still lands at 50-80 %: the car's limits are generous, the roofs
  fair. Left as they are until the 3h playtests say a call feels slack (then tighten the car's
  9.5 m/s pace in `missions.gd` `_limit_for` first; the helicopter's 17 m/s has the least slack).
- ~~iPhone frame time is unmeasured~~: measured in loop 2b on an iPhone 16 Pro Max: 60 fps (the
  cap) at the default, zoomed-out and helicopter views; GDScript there takes 4–5× the Mac's time
  at 60 Hz (iOS runs the CPU slower when there is time to spare).
- GUGiK terms checked 2026-10-28: the LoD2 buildings page says free for any use; the elevation
  model (NMT) and the orthophoto are free under Prawo geodezyjne art. 40a ust. 2 pkt 1 lit. d/e;
  the trees are CC BY 4.0. Keep the in-game GUGiK credit. Optional before release: a written
  confirmation from foto@gugik.gov.pl.

## From v0.65 (side jobs, dialogue, easter eggs)
- Five of the seven kebab stands are added corners, not mapped places.
- No Syrenka statue is mapped inside the area: she stands on the Powiśle boulevard by the foot
  of Tamka; the flood wall there is not in the roof grid, so placement relies on a short step
  towards the water.
- ~~Roadwork barriers are pushed by a distance check, not physics: the helicopter's downwash and
  traffic don't move them, and AI cars drive through the ones knocked into the lane.~~ Fixed in
  the roadworks loop (2026-10-30): moving traffic knocks the ones under its box (along at 75 %
  of its speed, out to the side), and the helicopter under 14 m blows the ones within 9 m out.
  Still a distance check, not physics; the AI still never brakes for them.
- The kebab/słoiki autopilot (like the race one) ghosts through traffic, so autopilot runs can't
  test jar breaks from real crashes (`--sloik=K` starts with K broken for screenshots).
- Pay rates (kebab 30–110 zł, słoiki 50–260, races 60–300, rescues ~120–200) are first guesses.
- Kebab stands and the station person are drawn on top of whatever the bake put on the pavement
  (a bench or a bin can poke through the kiosk).

## From v0.75 (real roads)
- The Praga streets join the network only through an off-map link at the east edge (they meet
  the rest of the city out there): route planning and the autopilot (which jumps it) use it, but
  the player has to drive in the wrong way down a one-way street or across the lot at the west
  end of Jakubowska. A real in-map way in needs a design call (a drawn link road?).
- The terrain grid stops ~9 m short of the map's south edge and ~5 m short of the east edge;
  carriageway areas and kerbs are cut there, but road strips, footways and areas (as before)
  run on to the map's edge and hang over the diorama's earth wall.
- Bus lanes only where the lanes are tagged per lane or counted on one-way roads; AI traffic
  doesn't keep the bus lanes free.
- Medians are found only between pairs of one-way roads; a two-way road with a median mapped
  as one line gets none. Loop 3b-2 counted the class: 0 on today's map (no `divider`, no kerb,
  barrier or hedge line along a two-way road's centre; the 3 gaps between a two-way road's
  carriageway areas, on Ludna and Czerniakowska, are not medians). Build it when the bigger map
  (loop 3d) brings one.
- Most Świętokrzyski is cut by the map's edge mid-river: its deck ends in the air at the rim.
- 13 signal controllers still run as lone crossing lights; they look like real mid-block
  crossings, but a few (Emilii Plater, Świętokrzyska by Mazowiecka) may be unmapped junction
  approaches.
- `--kebab=N` maps to stand N mod 7 now (seven stands), so the same N gives a different order
  than in v0.65.

## Seen in screenshots (orchestrator, 2026-10-28)
- Fixed in loop 1: the barriers and cones read (red-and-white 2 m barriers, bigger cones,
  blinking amber lamps); joke posters on one column in six; the occlusion ghost's dark stain;
  Varso I/II's floating part.

## Decided after v0.8 (orchestrator defaults, 2026-10-28; the user may still change them)
- Done in loop 1: the Palm stands where the scanned "tree" stood (the record is left out of
  the bake); the ghost stays a dither with its dark patch fixed (judge the dither size on the
  phone); the Palace clock shows the time in Warsaw.
- The info-card facts are confirmed as written (Varso Tower at 310 m is the tallest building
  in the EU).
- The renamed race finish ("Stadion Narodowy") may drop old best times; nobody has saved one
  yet, so no migration.

## From v0.8 (landmarks)
- The ghosted tower's shadow still lies on the street (the shadow pass is unchanged, by
  design): behind the Palace the car's surroundings stay in its shade (ghost/ring 0.83 there,
  loop 1). Worth a device look: on an iPhone screen the 4 x 4 dither may want a coarser
  pattern.
- ~~Tapping walks the roof grid, so a tap on the cut-away part of a tower in front of the car picks
  that tower, not what shows through the cut.~~ Done in sweep 2: the walk steps on through what
  the ghost has made see-through (main.gd `_pick_unghosted`; behind the Palace, a tap on the
  street seen through its cut tower picked the Palace, now nothing).
- The Palace's roof rescue now lands on the 30 m north block's roof (since the 2026-11-01 re-pass built it whole): every tier is crowned by attics and
  pinnacles, so no 3 x 3 cells are flat up the tower. A rescue from the 30th-floor terrace would
  need a landing spot designed in.
- Palace photo check on the Mac (spec docs/landmarks/specs/palace.md): whether the shaft steps in at
  the 30th-floor terrace (114 m; OSM has one shaft 67-139 m), the crown's patina and the spire's gold,
  the Congress Hall's roof, the east portico's width and columns.
- The baked ground AO and the lamp light map still use the LoD2 footprints: Centralna's canopy
  (wider than the LoD2 hall) casts no AO, and lamp pools are not cut by the stadium's skin.
- Most Poniatowskiego's towers have no mapped height: plinth to 1.2 m over the deck, top 15 m
  over it, a guess; Varso I and II stay OSM extrusions (loop 1 lowered Varso 2's floating
  80-90 m top to the ground; Varso 1's 71-81 m top rests on its 71 m part for a little over
  half its footprint and overhangs a 10 m part for the rest, so it stays).
- Stadion Narodowy's embankment is bare terrain with its mapped surfaces (patchy beige and
  grass) outside the paved promenade ring.
- The title skyline's Varso stays shorter than the Palace (in the city it is 310 m to 237 m).

## From v0.9 (water, weather, sound)
- Fixed in v0.9: lamp pools lit the water and the ground under bridge decks (the surface map
  knows the deck heights; the water gets reflections instead of pools).
- The sounds were judged by numbers only (peaks, RMS, loop seams, spectra, bus meters); nobody
  has heard them on a phone. The engine is tuned for a phone speaker (little below 150 Hz).
- ~~Puddles are a noise mask on the road layer: lane markings and stop lines are drawn over them,
  so a painted line crosses a puddle unbroken.~~ Fixed 2026-10-30 (loop 3i item, a cloud thread):
  the markings layer gets the same puddle mask as the asphalt in `ground.gdshader`, so a line goes
  dark and mirrors the sky where it crosses a puddle (the post pass already reflected on them).
- The mirror reflections are screen-space: only what stands on screen above a surface
  reflects (nothing past the top edge), and thin posts reflect as broken dashes. (By day the
  water now shows a bridge as a darker band, loop 1.) The light concrete slab edges of Most
  Poniatowskiego still draw thin pale lines along the deck by day.
- Rain streaks are screen-space: they fall inside the Rotunda's glass and under bridges, and
  keep their pixel size at every zoom.
- No spray or splashes behind cars in the rain (at the default zoom a car is ~18 pixels long;
  a convincing spray needs particles: not cheap enough for this pass).
- Medium quality's render scale (0.85) gives the same whole-pixel image as High on a 1080-line
  Mac screen and an iPhone's 1170 lines: only Low makes the image smaller there. Quality and
  weather are not saved (settings are v1.0).
- Live mode: at night the moon keeps the Night look's fixed direction.
- The perf overlay's CPU "process" time is Godot's whole idle step (it includes waiting on the
  render thread on some frames), not only the scripts; GPU time is n/a on Metal.
- `--race=0` maps to rival 1 (the flag takes 1-6; 0 is clamped up), as before.

## Decided after v0.9 (orchestrator defaults, 2026-10-28; the user may still change them)
- Weather stays a RAIN toggle beside VHS; QUALITY stays on the hidden perf overlay until the
  v1.0 settings screen (the device pass decides whether Low is needed by default).
- The iOS audio session stays Ambient: the silent switch mutes the game, radio included, and
  the player's own music keeps playing.
- Live keeps the sun's pitch between 20° and 55° and is not the starting mode (daytime first).
- Rain starts only from the button or flag for now. Idea for later: rain on some days, picked
  by the date like the roadworks street, never by the network.
- Seen in screenshots: the river camouflage, the white flecks, the bridge's pale "wake" and the
  ghost over the glass tower in Live 08:00: fixed in loop 1.

## From loop 1 (polish)
- The v0.8 Palace shots (`--at=-1170,300`, `--at=-1180,300`) put the car inside the Palace's
  footprint, which driving never does; the real spawn is on Marszałkowska by the glass tower
  east of Plac Defilad. Loop 1 measured the Palace from the north-west (`--at=-1290,170`).
- The ghost keeps 3 pixels in 16 in its core: thin enough to see the street, enough to keep a
  tower's shape. Judge it on the phone (and whether a coarser 2-pixel dither reads better).
- A ghosted footprint gets its sunlight back by the sun's height, a guess at how much of the
  street round it is sunlit; in a low sun a footprint can read a little lighter or darker than
  the shaded street beside it (Live 08:00: ghost/ring 1.06).
- The post pass leaves out the ghost's outlines from the same region test; the inner faces of
  a cut building (dropped a little past the car) still get outlined at their edges.
- Floating parts: parts that start below 10 m with nothing under them (canopies, passages,
  pilotis, a few probably unmapped podiums: at -939,-751, -1511,-867, -93,-305) stay as mapped.
- The roadwork lamps all blink in one beat (simple, and their halos keep in step); real ones
  often run in sequence.
- Column posters hold four lines of eight letters (4 cm letter pixels); the letters read only
  close up, so the passing bubble carries the joke. Lines repeat across the 24 columns
  (16 lines).
- The AO map is twice the size (two channels: 12.5 MB as a texture); `city.scn` grew 0.8 MB.
- ~~Night water is a flat deep navy away from the lamps: calm, maybe too plain at the widest
  zoom; a faint sky sheen could come back if the device pass wants it.~~ Done 2026-10-30 (loop 3i
  item, a cloud thread): after dark the river gets a faint sky sheen as light (broad 40-80 m
  patches along the flow, so it reads at 320 m, plus the slow crests) and a warm city glow within
  ~40 m of the banks; off above dusk's daylight, so dusk is unchanged. Judge it on the phone.
- The bench ran uncapped (220-280 fps) for most of loop 1 instead of at the display's 120 Hz:
  frame times and GPU readings are not comparable with earlier sessions' numbers, so loop 1
  ran the v0.9 code alongside for its before/after. Fewer cars fill in over 600 faster frames.

## From loop 2a (controls and settings)
- Only the user can judge the feel on the phone: the hold-then-ease camera in Point, the turn
  rates (calmer at speed than before: 23.5 m full-lock radius at 90 km/h), the 0.15 dead zone
  and full gas from three quarters out on the stick (70 HUD units, ~38 pt radius on an iPhone
  13), the 80 m default view, and whether the 44 pt panel controls feel right. Touch was emulated from the mouse and driven by
  `--clicks` / `--drag` / `--stick` on the Mac; nothing ran on a device.
- ~~Point with a finger that never lifts behaves like a fixed camera at whatever angle the
  camera had (it only comes round after a release). The zoom (− + / pinch) is not saved.~~ The
  follow-camera loop (2026-10-30): Point's camera turns with the car while held, the zoom has five
  saved steps. Not tested headless: the 20° re-aim, and how it feels on the phone.
- In a dense spot the car can be pinned between a wall and a stopped traffic car that waits for
  it; the unstick turns it out after 1.5 s, and a second pin within 5 s tows it back onto the
  nearest lane on its level (next to a kerb that can be almost where it was, turned the lane's
  way).
  ~~Traffic still stops for a player that only brushes it.~~ A brush dazes it for 0.4 s, a
  real hit up to 2.5 s (the traffic loop, 2026-10-30).
- Busy's traffic target is more than the spawner can place in the band round the view (70 vs
  ~44 at 80 m): the levels are calibrated on real counts. If the spawner changes, re-measure
  (bench `--traffic=`).
- The like-with-like GPU reading (110 m, Busy, Classic) was 2.43 ms by day against 2.27 before
  (night 2.20 vs 2.21): within the run-to-run spread (2.06-2.90 ms for one code), and the 3D
  view's GPU time can't include the HUD; the new defaults read 2.24 / 2.01.
- ~~The keyboard in Point points in screen directions: on the diagonal opening view, W turns the
  car off the road's line (it goes up the screen). Classic keeps the old car-relative keys.~~
  Sweep 2: already fixed by the camera loop, which starts a following camera behind the car
  (`--cam-log` at a normal start: heading 159.7°, camera 159.7°, so W is straight ahead along
  the road). The 45° view stays only where it is meant to: the Fixed scheme (following off,
  W up the screen by design) and the test views (`--shots`, `--bench`, `--probe`, `--yaw=`).
- The old `--fixed` flag now picks the Fixed camera scheme in Point (as CAM does).

## From loop 2b (frame rate on the iPhone)
- The device log starts with `ERROR: Mouse is not supported by this display server`
  (display_server.cpp:536), once, from the engine before any game script runs (no script asks
  for the mouse; switching touch-from-mouse emulation off on mobile didn't stop it). Harmless.
- The phone's GPU time can't be read (Metal has no timestamps in Godot 4.7), and at 60 Hz the
  main thread waits for the display inside "draw" (2–12 ms depending on the run), so the headroom
  under 16.7 ms isn't visible. A build that allows 120 Hz would show it as fps above 60 (not made
  this round; the old build did 64 fps from the helicopter with four times the GPU work). Loop G1: a Metal System Trace reads the GPU (From loop G1).
- The Mac's worst single frame in the bench reads 17–20 ms after against 9–20 before (the
  averages fell by half): one-off spikes, probably first-sight pipeline compiles (2–3 a run).
- With the 60 cap on the Mac's 120 Hz display (`Engine.max_fps`) frames alternate unevenly
  (~20 % a little late); on the iPhone the display itself runs at 60 Hz and paces it.
- The shadow's texels follow the zoom now (the far plane is set from the view): pinching or
  zooming changes their size; the speed zoom doesn't (held constant on purpose).
- Medium and Low share the pixel size (one step coarser than High); they differ by shadows
  (1024, buildings and trees, vs none), glow, reflections, rain, traffic and people.
- The user's 13–16 fps came from Xcode's Run (debugger + Metal API validation, ~9 µs per draw
  call): the old build read 18.9 fps with validation on and 120 Hz without; the new one 60 either
  way. `tools/export_ios.sh` now turns
  validation and GPU frame capture off in the scheme; the debugger is still attached under Run.
- Thermal state isn't readable from Godot; the BENCH card shows fps per 10 s instead.
- Device runs launched with `devicectl`: the launcher may eat the `--` before the game's
  options, so `main.gd` also reads them from the engine's own arguments. On iOS `quit()` doesn't
  end the app at once: `--bench` / `--probe` print once and stop measuring (the old code printed
  its result every frame after, 20 MB of log).

## Decided in loop 2b (orchestrator-free defaults; the user may still change them)
- 60 fps is the default cap, 30 the battery saver; no 120 Hz option.
- ~~High stays the default quality on the phone~~ Loop G1: Auto is the default (the level for the device); Medium is still the first step down from High.
- The BENCH runs at the current settings and cap (not uncapped) from the spawn at the default
  view, 5 s settle + 55 s measured; the card's numbers are in English (Polish header/buttons).
- Shadow edges are a little finer than before (0.37 m texels on High instead of 0.49 m).

## From the project setup (agents, skills, checks; 2026-10-28)
- ~~`check_landmarks.gd` exits 0 even when a check fails.~~ Fixed: it ends with
  `quit(0 if _check() == 0 else 1)` (tidied 2026-10-30, checked in the code).
- ~~README gives two different `bake_osm.py` command lines.~~ Gone: the map chain moved to
  DEVELOPMENT.md and `tools/setup_map.sh`; README has no bake line (tidied 2026-10-30, checked in the code).
- ~~README names the Apple team ID.~~ README no longer does; the ID stays in
  `export_presets.cfg` (not a secret, decided: BACKLOG-TRIAGE "Decided since") (tidied 2026-10-30, checked in the code).
- Device-run permission in CLAUDE.md stays per loop ("when the user said so for the current
  loop"); the user allowed phone test builds on 2026-10-28.
- Haptics fail on the phone: `Could not vibrate using haptic engine: (null)` in the device log
  (nine `Input.vibrate_handheld` calls). Rule out Low Power Mode / System Haptics off first;
  else a small iOS plugin with `UIImpactFeedbackGenerator`.
- ~~The once-only `ERROR: Mouse is not supported by this display server.`~~ Duplicate of the
  loop 2b entry above (tidied 2026-10-30, checked in the code).

## From loop 10a (the river is off-limits)
- The splash, the tow and the stone's look were judged on the Mac (screenshots, logs); the feel
  on the phone (does the splash read at the default view, is 1 s the right wait, is the toast
  readable) is the user's to say. The splash's sound (the hard knock pitched down + the rain
  bed's noise) was never heard: headless runs have no audio.
- The bake still leaves the shore open within 6 m of every bridge deck (`tools/bake_roads.py`
  `bake_shore`); the map builder fills those stretches at build time where the deck is at
  least 3.2 m up (`_shore_under_decks`). Moving the rule into the bake (map-engineer) would
  make `shore` in centrum.json say what the game builds.
- Godot's `cast_motion` misses some thin walls of the city's one big concave collision shape
  (`check_water.gd` steps an overlap test every 0.5 m instead). The car's own `move_and_slide`
  holds (0 of 631 cars through at 91 km/h), but any future check that sweeps shapes should
  step too.
- A car that gets less than 2.5 m past the edge (the shallow first metres; only reachable past
  the stone through a glitch) doesn't count as in the water, so it isn't towed until it rolls
  further in.
- The tow goes to the nearest lane to where the car last stood on dry land; from the middle of
  a wide beach that can be a junction ~100-200 m inland (the check's worst case, from mid-river
  with no bank known, is 491 m).
- A beach path's paving still draws past the stone into the water where OpenStreetMap maps it
  so; people now turn back a metre short of the water.
- ~~The helicopter's roof toast is still English only.~~ Fixed: "Wyląduj na otwartym terenie,
  żeby wziąć auto." over the English (`main.gd`) (tidied 2026-10-30, checked in the code).
- ~~`map_builder.bounds` isn't stored in `city.scn`.~~ Fixed: `bounds` is `@export_storage`
  in `map_builder.gd`, so the prebuilt index carries it (tidied 2026-10-30, checked in the code).
- The bench route's ghost car drives with its collision off, so the water test never runs on
  the bench; it was measured with the probe (car physics 0.05 → 0.05 ms at the river) and a
  micro-benchmark (0.8 µs a call, one call per physics frame).
- ~~Windowed `--prebuilt --shots=` runs sometimes end with "8 ObjectDB instances were leaked at
  exit" / "4 resources still in use" (seen on the code before this loop too; not in headless
  runs).~~ Done in sweep 2: `--verbose` named them, the four sounds playing at the quit (the
  radio's station, the engine's idle and mid loops, the city bed: an AudioStreamWAV and its
  playback each), still held by the audio server when the tree went (1 run in 4 before); a
  shots run now stops its sounds and quits 0.15 s later (main.gd `_quit_quietly`; 0 in 6).
  The bench's and `--quit-after`'s quits are unchanged (they may show the same race).

## From loop 3a (roads I: the check and the bake)
- Fixed in loop 3b: R2 (the GeoTIFF corridors are read), decks too low over the Jana Pawła II
  viaduct's pillars and the Poniatowski viaduct's arcades, the approaches' plain faces (retaining
  walls), tunnels and garage doors data only (drawn and driven), C4/C5/C9/C10. Kept below for
  the record; still open: the minor service ways' and junction pits' steep bits (C1 allowlist),
  the schematic footbridges (C3 allowlist), C10's other landmarks by their outlines, the runtime
  build's time.
- ~~**R2 is waiting for its data.**~~ `bake_roads.SurfaceModel` reads the 0.5 m surface model and the
  1 m terrain as ASCII grids once `data/raw/demo/MANIFEST.md` exists; the corridors arriving in
  `data/raw/demo/gugik/nmpt05/` and `nmt1/` are GeoTIFF, which it doesn't read yet (a small
  stdlib TIFF reader, or a one-off conversion to .asc in the fetch). Untested on real data.
- **Decks still too low where something stands under them** (C9 57, C5 50): the Jana Pawła II
  viaduct's 48 mapped pillars (OSM buildings 4 m high) poke through its ramps, so the real
  viaduct is level further out; the Poniatowski viaduct over Powiśle sits ~5 m over the streets
  while the Arkada (7.6 m) and the LoD2 arcades under it are taller. Either the surface model
  (R2) or mapped pillars as lower bounds in the solver; then loop 3b's building cut.
- The approaches' sides where they stand above the 10 m grid are plain concrete faces (no
  collider): loop 3b's retaining walls (R6). The sidewalks beside an approach stay on the grid,
  so at an abutment's blur they sit lower than the road.
- Tunnels are data only: not drawn, not driven, not on the minimap; their lane-graph edges stay
  out of routing and traffic (`lane_graph.gd` `TUNNELS_DRIVEN`). The Wisłostrada trench at
  (637, -554) is still a dead end for the car (marked: `tunnels.portals`). The tunnel on
  Warecka (OSM `tunnel=yes`, 7 m under a building) may be a gate, not a tunnel.
- Garage doors (`garages`, 27) are written but not drawn: the service way just ends at the ramp's
  top. 21 minor service ways still have a steep bit of the 10 m grid (C1, allowed with one shared
  reason, not looked at one by one); 5 pits at junctions too (the pit fill stops where another
  way enters a road's corridor). Both want the 1 m terrain.
- Footbridges mapped schematically keep short clearance (Centralna's access=no footbridge over a
  covered aisle, the science centre's roof-garden ramps, one footbridge whose stairs don't touch
  it); the WKD cutting by Centralna has no known depth (C3 allowlist).
- check_roads' C10 knows Most Poniatowskiego's towers' colliders exactly; the other landmarks'
  colliders are approximated by their outlines.
- The runtime city build is ~0.5 s slower (7.3 → 7.8 s on the Mac): every draped vertex asks
  `terrain_height`, which now looks the fills up; the prebuilt path doesn't build.
- CLAUDE.md still says no add-on is installed: Debug Draw is (game/addons/debug_draw, CREDITS.md).

## From loop 2e (the HUD at phone size)
- Everything was judged on the Mac at the phones' sizes (the window stands in for the phone:
  `screen_points.gd` gives 2868×1320 the Pro Max's points and insets); nothing ran on a device.
  The safe area on the phone comes from iOS (`get_display_safe_area`): if a model's landscape
  insets differ from the table, the phone wins and the Mac shots differ.
- On a 390-pt-tall phone (the 6.1" class) the screen is full when a card, a status and the
  radio host's long line coincide: the ticker, a note or landmark card, a speech bubble or the
  performance overlay then waits for room (`check_hud.gd` lists 26 such waits over its 96
  states, none on the Pro Max without the overlay). A waiting bubble is dropped after 6 s;
  the vendor's line at a kebab stand usually waits until the job card goes.
  Landmark card fix (2026-10-29): the note and landmark cards now take the right-hand column
  first, so a tapped landmark's card shows beside the car with the ticker up (`check_hud.gd`
  checks it on all four screens); they no longer count among the waits above.
- The passing panels keep out of a 110×84 pt box in the middle of the screen; at speed the view
  leads and the car can sit outside it (up to a fifth of the view off centre), so a toast can
  still cover a fast car for a moment. Cards and the status may cover the car on a 390-pt phone.
- First rescue call 60 s into play, then 90 s after each (`missions.gd` `FIRST_CALL`,
  `NEXT_CALL`): first guesses; DEMO.md 6.2's scripted first ten minutes put it at 4:00.
- The two-finger twist (40° for a 90° turn) works only with the fixed camera; with following
  on it does nothing (an accidental twist while pinching would otherwise switch the saved
  scheme). Not tried on glass.
- The stick's reach is 42 pt everywhere (it was 43 pt on the Pro Max, 38 on a 6.1"): the
  6.1" gets 11 % more travel for full lock and full gas.
- The DEMO.md loop-2e row asked for ≤ 30 2D draw calls; the 2D pass is 38–46 at the four probe
  views (README's budget: 80). The bubbles, the minimap's overlay and the labels are most of it.
- Most mission, job and race text now has Polish over an English gloss written in this loop
  (not yet reviewed by the game designer); the radio host's lines, the rivals' and customers'
  lines come from `dialogue.json` as before. The egg note's Polish names are in `eggs.gd`
  `EGGS_PL`. A few toasts still carry both languages on one line ("Najpierw wyląduj · Land
  first").
- `tools/export_ios.sh` doesn't create `build/ios/`: in a fresh checkout or worktree
  `tools/verify.sh --ios` fails with "Target folder does not exist" until `mkdir -p build/ios`
  (a one-line fix in the script, left for its owner). It also re-bakes `game/map/city.scn` on
  every run, so a loop that must not touch the map puts the committed city.scn back afterwards.
- The TWIST, the 6 s bubble wait and the 110×84 pt car box are first guesses (`hud.gd`
  `TWIST`, `CAR_ZONE`; `bubbles.gd` `MAX_WAIT`).
- The art bible's "Phone sizes" line still says the HUD is in 720-line units (left as is: the
  art bible changes only with the user's yes).
- The landmark info card and the egg note use 13 pt for both languages; the speech bubbles 15 /
  13 / 11 pt. A "Text size" setting (Small / Normal / Large) was not built.

## From the first-minute look (2026-10-28, after the art review)
- The gold wall the review saw "inside the cut tower" at the Palace by night is the shaft's
  own floodlit north-west face beyond the car (a debug render: front faces past the car, not
  back faces); the cut's real inner faces (back faces) are now unlit and flat. Dimming walls
  beyond the car inside the ghost would need to know that something is ghosted there (else a
  dark hole would follow the car along every street at night): main.gd could pass it.
- ~~The neon sign quads (`neon.gdshader`, 361 signs) are not ghosted (they never were): a sign on
  a ghosted wall stays lit, mirrored, over the ghost. Feeding them the ghost's uniforms is one
  more material in main.gd `_update_ghost` (outside this loop's main.gd scope).~~ Done in sweep
  2: neon.gdshader includes ghost.gdshaderinc and `_update_ghost` feeds it (a mirrored BAR
  MLECZNY over the ghost is gone, both city paths; draw calls unchanged).
- On a lamp-lit bridge deck the car's paint reads ~20 luma under the lit deck: a saturated red
  tops out at ~110-130 luma, and the value ladder puts lit ground above the car. It stands out
  there by chroma (paint saturation ~0.85 against ~0.35). A brighter hero would have to turn
  orange (the jobs' colour) or pink.
- Inside-out LoD2 walls (the few the building shader is double-sided for) that fall inside
  the ghost's region on screen go flat and dark like a cut building's inner faces.
- The pools' bands are concentric rings; on big lawns (the Rondo's islands) they read as
  targets. Judge on the phone (options: three bands, or less contrast between them).
- Lumpy crowns are shader lumps on the 12-vertex icosahedron: irregular crowns, not 2-3
  separate blobs; real blobs need a new crown mesh (map side, with the crown sizes near roads).
  Conifers share the material and get gentle lumps too.
- Cycle lanes under sodium at night still read red (dimmer, tinted, not added), under the car.
- ~~The minimap still shows the azure water and lime parks (HUD side).~~ Done 2026-10-30: the
  water is the river's grey-green-blue (`#70a0ac`, was azure `#7fb8de`); the parks were measured
  against the lawns by day (`#a9cf7c` vs `#9fca6a` in sun) and match, so they stay.
- Buses and trams keep their Warsaw red-and-yellow livery and the rivals their looks (loop 2c:
  Słoik's stripe is pickle green now; his orange name tag stays): street-level Warsaw is on the
  review's protect list.
- Half the LoD2 walls now run the facade code instead of the roof grain: the bench numbers are
  in README (The first-minute look); the phone's 60 fps is the orchestrator's to confirm.

## From the camera loop (follow camera, Phantom Camera)
- Only the phone can tell the feel: the 64°/s Classic camera (it lags up to ~40° behind the car
  in a 90° turn at 50 km/h, more in a full-lock circle), Point's 2.9 s return, the look-ahead
  that builds up over ~4–5 s from a standing start to 90 km/h (capped at 3.5 % of the view a
  second, so the car never slides fast across the screen), the car resting ~46 px below the
  middle after a hard stop, and the cinematic moments.
- Classic's camera rests up to 1° off the car's heading after a turn (the yaw dead zone).
- The Fixed camera's 90° turns (`<` `>`, Q / E, switching CAM off) are still a quick 8/s lerp
  (up to ~360°/s at the start), as before: they are the player's own command.
- The look at a target only plays under 30 km/h with nothing held; a target that appears while
  driving fast or steering gets none (the minimap and the arrow show it as before). A rescue's
  timer runs during the ~2.9 s look.
- The moments' widest views draw ~217–219 draw calls for a second or two at the spawn (the
  zoomed-out budget view is 190–215); the shadow's texels change size during them (the view's
  height changes), and benches, bins and racks pop in as the fly-in passes 153 m.
- Phantom Camera's editor plugin is not switched on (it checks GitHub for updates whenever the
  editor starts, headless exports included). The add-on's two Nunito fonts crashed Godot 4.7.2
  once in this worktree's first headless import after the copy (a threaded font import touching
  the scene tree); a second `--import` finished, and a later re-import of just the fonts was fine.
- Phantom Camera's manager sets `Engine.physics_jitter_fix = 0` when it starts (no effect with
  physics interpolation on).
- `--cam-test` ghosts the car through walls; on Marszałkowska (the README's spot) the Point
  release drives through buildings, so its frames show the occlusion ghost.
- `check_steering.gd`'s px/s numbers changed meaning: every test now starts with the camera
  settled for the starting speed (loop 2a's README numbers started it at the car).

## From loop 3b (roads II: the builder)
- **The minimap doesn't draw the tunnels yet** (DEMO 4.4: dashed). It is `hud.gd`
  `_minimap_mesh` (the HUD agent's file): after the roads loop, the `tunnels.roads` as 8 m
  dashes in the road colour. The snippet is in the loop 3b report.
- **The car in a tunnel is a silhouette, not the plan's dithered ghost.** `tunnel_xray.gd` draws
  the car's meshes once more with an unshaded material that ignores depth (after the post pass);
  the ground over the tunnel stays whole. A dither in `ground.gdshader` would need `discard` in
  the ground's shader (a cost on the phone's tile GPU for the whole ground); the look is the
  user's to judge on the phone.
- The portal frames are simple (a headwall, two posts, a dark mouth 3 m in); the 10 m grid's
  slope over the first metres of a tunnel covers part of the mouth. The open ramp's walls stand
  on the grid's blurred trench sides.
- Tunnel 2 (the link under Most Poniatowskiego's west abutment) is shallow (30 m long, ramps of
  8 % from both portals, ~1.5 m under the grid): it passes under the abutment's approach fill,
  whose retaining walls open over it (the wall's foot at the mouth's top).
- Most Poniatowskiego's towers keep their guessed heights (top 15 m over the deck); their
  footprints come from the outline by the deck (16 x 3.5-5 m), thinner than the photo suggests.
  The rounded second outline (a stair annex down to the boulevard) is no longer drawn.
- The bus is swept on main roads and links only (lane classes 0-1): traffic sends a bus into a
  residential or living street with a 5 % weight (`traffic.gd _choose_next`), where a rigid
  12 m box at OpenStreetMap's square corners hits walls. For gameplay-dev: keep buses to classes
  0-1 when there is a choice.
- check_drive's routes cover every deck and tunnel edge (17 routes) plus 3 outer-lane repeats;
  20 distinct structures don't exist on today's map.
- Clearing the lanes left out 169 benches, racks, columns and shelters, 408 parked cars, 34
  kiosks (< 30 m2) and cut 2.2 km of fences, walls, hedges and mapped guard rails where they
  stood in a carriageway or a lane (OpenStreetMap's fences across gates, a car park mapped over a
  street's edge). Some may be real (a gate's fence); the lane graph wins.
- LoD2 walls a metre into a lane (17 places, `lod2_open`) are drawn but not solid there; the car
  drives through the corner of the building (the lane is where OpenStreetMap's road is).
- R2 uses the surface model for road and rail decks only; footbridges keep the chain solver.
  The surface model also gives the 1 m bare earth (`SurfaceModel.ground`), not used yet for
  pins or approaches (the 10 m grid keeps the joints with the ordinary streets exact).
- Aprons blend the ground at 15 structure ends; a fill's (approach's or pit's) own ends were
  tried and dropped (their side edges made new steps).
- Not done in loop 3b (the triage's 3b row and item 9): done in loop 3b-2 (README "Loop 3b-2"),
  except medians on two-way roads (none mapped on today's map, under "From v0.75").

## From loop 2c (car models)
- **Parked cars are one shape** (a small saloon, `models.gd` `parked_mesh()`, 40 triangles): the
  traffic's kinds would need a MultiMesh per kind per 512 m tile (+1 draw call per tile in view,
  per pass) or `foliage.gdshader` (outside this loop) learning the actors' shape morph. The three
  512 m tiles round the spawn hold ~550 of them, so they stay cheap. Default: one shape, the
  traffic's paints.
- **The prebuilt city.scn held the old parked boxes** until loop 3b-2 re-baked it (now native,
  no red; `foliage.gdshader`'s red remap removed). `main.gd`'s `Models.renew_parked` swap is
  harmless now and can go in a main.gd loop.
- **Police and guards** (`Models.police_mesh()`, for loop 3g): one family, shape 0 the patrol
  estate (paint `POLICE_WHITE`), shape 1 the guards' car at 0.88 (paint `GUARD_MUSTARD`), so 3g's
  POLICE kind can draw both in one MultiMesh. The light bar's lamps use BLINK (alternating by
  UV.y): they glow and blink only when the city's lights are on; a daytime chase needs police.md's
  SIREN part, whose code must be **9** (8 is the player's HERO since the look loop), driven by the
  instance's custom data, not by UV.y. "POLICJA" reads from ~6–15 m views only (5 cm pixels).
- **Podwózka shares the TAXI MultiMesh** (pool 16) with the city taxi, half each (~5 % of cars
  each on main and secondary roads): parodies.md planned a kind of its own (pool 12, +2 draw
  calls) for loop 2d; as a shape it costs nothing. 2d's GPS moments can key on `shape == 1`.
- **Mirrors were left out** (one image pixel at the 80 m view); the player's car has round head
  lamps, a spoiler and hub caps instead, which read zoomed in.
- `check_water.gd` 5a counted every roof refusal as "refused on dry land" (5517) after sweep 1
  gave that refusal an English line; it now tells the water's by its words. `verify.sh --quick`
  doesn't run the water steps, which is how it slipped through.
- DEMO.md row 10 asks "≤ +20 % vertices for vehicles": a model grew more than that (a traffic
  car 144 → 194 triangles, a van 144 → 228, the player's 240 → 292), but the pools now draw only
  the cars in use, so the frame's triangles fell at the default view (README "Loop 2c");
  README's per-model caps (≤ 800, ≤ 3,000) were followed.
- The bus has doors on its right only; the tram cars on both sides (Warsaw's newer trams are
  two-sided).
- A traffic car's shape is picked by its own random stream, so where and which kind of car
  spawns is as before; its size (and the gap it keeps) is now the shape's.

## From loop 3b-2 (map art and road details)
- **The main checkout's Godot class cache had lost Phantom Camera's classes**
  (`game/.godot/global_script_class_cache.cfg` held only DebugDraw3D, dated before this loop):
  every Godot step of `verify.sh` failed with "Could not find type PhantomCameraHost" until
  `godot --headless --path game --import` rebuilt it. Worth a line in the verify-game skill (or a
  check in verify.sh) if it recurs after merges.
- The natural/built split is OpenStreetMap's: a stretch of the west bank south of Most
  Poniatowskiego reads natural (no promenade or wall mapped along it), the park ponds with grass
  banks get a dark-earth band; `bake_banks.py` prints the km and `shots/loop3b2/ov_banks_overview.png`
  shows them over the photo. If the art director wants a third kind (riprap, timber), the
  classifier has the place for it.
- The beaches are only sand where OpenStreetMap maps sand (Poniatówka, Plaża Saska, the shoals);
  elsewhere the bank is the bare ground's colour with the wet bands.
- Sandbars stay river for the car and the helicopter (water.bin unchanged): a car can't reach
  one and the helicopter won't put the car down on one. The sandbar rescue's place (a sandbar
  outside the drawn river, the POI bake) is unchanged.
- Kerbs are felt at street level only (not on decks or in tunnels), and pavements are not raised
  (only the kerb's hop); the player's car only (traffic and rivals follow their lanes).
- Joined deck gaps keep the parapet's collider on each piece's edge (with a low kerb drawn there),
  so the car can't drive across from the road deck to the tram bed on Most Poniatowskiego; the
  gap's slab is drawn, not driveable.
- The spiral rule (3+ lanes, radius 25 m+) also caught the 4-lane ring by Centralna at
  (-1505, 695); Warsaw paints its big rondos that way, but it wasn't checked against the photo.
- 8 mapped pavements by Centralna and the Jana Pawła II viaduct lie under road decks (not on a
  footway deck) and stay on the ground; they look right in the shots, not checked one by one.
- The runtime city build is ~2.4 s slower (8.3 → ~10.7 s: the areas, footways, cycle paths and
  steps clipped to the grid's cells, in GDScript); the prebuilt city (the phone) is unchanged at
  0.9 s. A faster clip (whole runs of cells along a strip) is possible if the Mac's build time
  matters.
- The sand gap fills (`bake_banks.sand_gaps`, up to 6 m) also bridge a few gaps that are real:
  a path mapped only as a line between two beach polygons now has sand under it (its own strip
  is drawn on top). check_drape's footway part allows 2 m2: one footbridge ramp at (-18, -281)
  ends 0.46 m under the park it lands in (the deck solver's end, not the drape's).
- The chevrons' direction (points towards the oncoming traffic) follows the Polish P-21 drawings
  as remembered; if they should point the other way it is one sign in `bake_roads._hatch_flow`'s
  caller (`flow < 0` flips).

## From loop G1 (device tiers and the frame governor)
- ~~**The first rescue call's arrival is a hitch**~~: 61 ms on the iPhone 11, 100–117 ms on the Pro
  Max (one frame, 3–6 refreshes), 60 s into play (`missions.gd` `_ring`, the context button and
  what comes with it; the BENCH minute's "3 pipeline compilations" may be it). The BENCH minute
  now holds the call clock, so cards don't show it; play does. Gameplay lane: warm the call's
  pieces up at the start, or build them a frame or two before they show.
  Sweep 2: on the Mac the call is 0.3 ms of script (pill 0.02-0.06, toast 0.27-0.37 ms), no
  pipeline compiles (85 before and after) and an ordinary frame (8.3-8.8 ms against medians of
  8.35-8.39, uncapped, Mobile, 2868×1320); the only part that differs on the phone is the buzz:
  Godot's iOS template builds CHHapticEngine on the first `vibrate_handheld` (initAndReturnError,
  auto-shutdown on) and starts it inside that player's startAtTime. Fixed at that cause, unproven
  on the phone: missions.gd `warm_haptics` builds and starts the engine (without waiting) at
  load and 2 s before each call; the log shows `haptics: engine built and starting in N ms` and
  `rescue call ringing (buzz N ms)`. If the call still hitches on the phone with a buzz under
  a millisecond, the buzz wasn't it: time `_ring`'s pieces there. Other buzzes (bumps) after a
  long quiet may still restart the engine inside their frame (auto-shutdown).
- **The iPhone's frame pacing has two modes per launch**: the main thread waits for the display
  inside "draw" (11.6 ms of it, frames jittering 1–8 ms either way, 1.6–16 % of frames over
  17.7 ms with every refresh still drawn) or outside the frame's phases ("draw" 1.1–1.9 ms, no
  jitter). Which one varies by launch, at either image size. Harmless to the eye as far as the
  numbers go (no refresh missed); it made "draw" useless as a GPU reading and "% over 16.7 ms"
  useless as a stutter reading, hence the missed-refresh count.
- **The orchestrator's 25 fps 1 % low at ×1 didn't come back** in nine runs on a cool iPhone 11
  (thermal state nominal; ×1 held 60 with 0 missed refreshes for 3 minutes). It was probably a
  warm phone or the first call's hitch inside the minute. G0's 20-minute SOAK on the iPhone 11 at
  Auto (High ×2) is what proves the heat margin.
- **The GPU's time on the phone** comes from `xcrun xctrace record --template 'Metal System
  Trace' --device ID --all-processes --time-limit 6s` while a `--probe` runs, then `xctrace
  export --xpath '…/table[@schema="metal-gpu-intervals"]'` and `gpu-performance-state-intervals`
  (the A13: Medium state 95 % at ×1, Minimum 99.9 % at ×2). Attaching by name or pid fails on
  both phones, and starting the trace stalls the app ~11 s on iOS 27. G0 should script it.
- The governor's GPU levels hold only two things today (reflection steps × 0.6, then the small
  things' shadows); G2–G5's extras (FX count, lamp cones, dusk glow) join them as they land.
  Glow at night stays out of it (the night lights).
- The view rule takes the small things' shadows off in views over 150 m and in the helicopter
  (0.4 % of pixels from the helicopter at 2868×1320; shadow pass −11 to −15 draw calls). A
  zoom across 150 m switches them at once (no fade), masked by the zoom itself.
- `--stress=wait:N` busy-waits in the draw phase: on the phone it shows only from N ≈ 40 (20 ms),
  because the wait for the display shrinks to make room. G0's `--stress=gpu:N` (real GPU work)
  is still to build.
- The SE 2 / 3 (1334×750, 1.0 MP at ×1) land at ×2 (667×375) at High, by 4 % over High's
  budget; nobody has run them. The 11 Pro and 11 Pro Max (A13, ×2 at 0.68 / 0.83 MP) keep their
  ×2 image at High: the same GPU as the iPhone 11 with twice its ×2 pixels, unmeasured.
- Mac windows over 0.96 MP at a scale of 1 (e.g. 1366×768) now draw at 2 at High.

## Decided in loop G1 (perf-engineer defaults; the user may still change them)
- The iPhone 11 at High (and so at Auto) draws 896×414 (×2), as the brief asked; ×1 (1792×828)
  is Ultra on that phone (it held 60 on a cool phone, at a higher GPU clock). **Loop G1b:** the
  user chose ×1 under Auto (High's effects) with a ×2 fallback; Wysoka stays ×2.
- Ultra is High + the 4096 shadow map + 16 reflection steps; Auto picks it on A17 Pro and newer
  (and the 16 / 16 Plus, A18), the 16e stays High (4-core GPU). The iPhone 17e's id isn't in the
  table (unknown → treated by its family: `iPhone18,x` → Ultra).
- A saved "High" from before G1 becomes Auto once (the file then carries `tiers=1`).
- The governor counts missed refreshes, not frames over the interval + 1 ms (the card shows
  both); a raise needs under 0.5 % missed over 30 s.
- The BENCH minute holds the governor (the card is the level's own cost) and the rescue calls;
  `--governor=on` lets the governor act during a bench or probe.

## From loop G1b (Auto's sharp image with a fallback)
- **The ×1 drive was by day only**: 17.7 minutes of autopilot, traffic Normal, at room
  temperature, 60.0 fps every minute, 5 missed refreshes, no governor change. Night, rain at
  night (the river's reflections, glow), Busy traffic and the helicopter at ×1 are unmeasured,
  and so is a warm room; G0's 20-minute SOAK (DEMO H3) should now run at Auto = ×1 on the
  iPhone 11, since that is the default. Every content loop (2d, police, 3c streaming, G2) now
  costs the iPhone 11 its sharp default if it pushes the A13 over: its bench at Auto ×1 is the
  number to watch.
- **Nobody has run the SE 2 / 3 at Auto**: since G1b they draw 1334×750 at ×1 (1.0 MP, the A13 /
  A15 with fewer pixels than the iPhone 11's 1.48 MP), with the same fallback. The iPhone 11 is
  the only phone measured at ×1.
- **The fallback is per launch, never live**: a session that struggles keeps its sharp image
  until the next launch (the governor's extras guard it meanwhile), since switching the pixel
  size mid-drive is a visible pop and reallocates the image. If a long first session on a hot
  phone turns out to look bad, a live switch at a natural cut (a load, the settings panel, the
  helicopter) is the next step.
- ~~**No toast** says the fallback came in (the brief made it optional): the Obraz tab's
  `auto · High ×2` and the `quality:` log line say it. A one-time toast ("Obraz prostszy, bo
  telefon się grzał · A coarser picture: the phone was struggling") is a game-designer call.~~
  Built (2026-10-30): a one-time toast at the first fallback launch, wording in QUESTIONS.md.
- **Thermal state** is still not readable from Godot 4.7.2 (checked: no OS, DisplayServer, Engine,
  RenderingServer or Performance method); graphics.md 4.4's plugin would add it to the struggle
  rule as a third signal.
- The Mac counts too: a window under 960 lines over 0.96 MP (1366×768, 1440×900, the shots'
  1792×828) draws Sharp at ×1 under Auto since G1b (screenshots at 1792×828 show the iPhone 11's
  sharp look; `--last-session=struggled` shows its fallback).

## Decided in loop G1b (perf-engineer defaults; the user may still change them)
- **Struggled** = GPU extras down (GPU-bound drops only, outside wide views) for 60 s and a tenth
  of the counted play, or 3 counted minutes in a row over 2 % of refreshes missed GPU-bound.
  **Calm** = 3 counted minutes without that. Counted only at Auto's sharp image or its fallback,
  past the settle, outside loads, pauses and wide views.
- **Back-off**: 2 calm sessions at the fallback, then the sharp image on trial; a struggle on
  trial doubles the wait (to 16); a passed trial (as many calm sessions as the wait) resets it
  to 2; a struggle at the fallback restarts its count.
- The Auto button's English line reads `auto · High ostry` (the brief's wording; "ostry" is the
  Sharp style's Polish name, on the row above) and `auto · High ×2`.

## From loop 3g-1 (the police, part one)

- ~~**Part two (loop 3g-2)**: the guards, the guard car, the zone cap and the clamp, the escort,
  the race and side-job ties, the sounds, the first contact, the `police_escort` and `guard`
  lines.~~ Done in loop 3g-2 (Phantom Camera's chase framing stays: the camera is the driving
  lane's).
- **PixelLab assets for part two** (police.md section 9, ≤ 38 generations): the three 64 px
  portraits (Sierżant Bogdan, Posterunkowy Kacper, Strażnik Henio; the card draws simple faces
  now), the 24 px rooster icon lit and outlined (the koguty draw light-bar domes now), the 24 px
  lizak (drawn as discs now), the 16 px hair-dryer minimap icon (a small blue mark now).
- **Trap spots in the bake** (loop 3d): `pois` kind `trap` replaces `game/data/police_traps.json`;
  spots 5-7 come with the demo area. The Wisłostrada trap sits on `graph` edge 502 at the
  carriageway named Wybrzeże Kościuszkowskie, east of police.md's guessed x 400-650 (that stretch
  is the tunnel), and 40 m north of the cross-city rail bridge, which hid the officer.
- **The parked trap car's kerb offset** (outer lane's edge + 1.5 m) is from the lane graph; where
  the drawn carriageway is narrower than its lanes the car stands half on the road, where a cycle
  lane runs by the kerb (Wybrzeże Szczecińskie) it stands on the cycle lane. Loop 3d's `trap` POI
  should carry a spot checked against the kerbs.
- **The officer's legs swing** (the guards' too, loop 3g-2) like a walker's (the people's shader swings every instance's legs;
  the swing is about one image pixel at 80 m). A standing pose would need a constant in
  `actor.gdshader` (part two, with the guards). (Loop MW-3's crowds stand still without a shader
  change: their own copy of the material with `walk = 0`. The trap officer and the guards ride the
  walkers' MultiMesh and still swing; moving them into a still MultiMesh is +1 draw call.)
- **The trap's car turns round when it pulls out** (it parks facing the traffic, as police.md
  asks, and joins its lane the traffic's way; the turn takes ~10 frames behind the passing car).
- **The 2D pass**: the minimap's marks are now one triangle array (they were a draw call each);
  the rival dots, side-job places and target look the same. The pill (a panel and two labels) is
  three 2D draw calls while shown.
- **Memory**: Dialogue Manager's scripts are ~4 MB of static memory, loaded at the start (on first
  use they were a ~70 ms hitch on the Mac, likely ~0.3 s on the phone, as the card opened).
- **The soak's B4 check** logs the car's place on screen each second during a chase; the camera
  follows the car, so it stays near the middle (closest to an edge 0.46 of the screen in the soaks).

## From loop 3g-2 (the police, part two)

- **Phantom Camera's chase framing** (police.md 11.3) is still owed: the camera is the driving
  lane's.
- **PixelLab assets** (above) still owed: the PixelLab server wasn't connected in the cloud
  session; Strażnik Henio's face on the card is drawn from shapes (mustard jacket, round glasses).
- **The guards' trousers** are the people's near-black palette entry: police.md's dark red needs a
  palette entry in `actor.gdshader` (visuals lane), and so does a standing pose.
- **The guard posts** live in `game/data/police_guards.json` (four posts, two guards each) until
  loop 3d's `guard_post` POIs; the Krakowskie Przedmieście zone in today's map is only the
  pedestrian way's ~8 m strip, so the cap there holds only on that strip.
- **The escort waits at the hospital's lane-graph node**, which can be 100-200 m short of the
  hospital's ring when the hospital sits back from the road (rescue 9: ~180 m); it leaves when the
  rescue ends. A node nearer the door (or the ring's own edge) would bring it to the door.
- **The escort in Normal traffic** keeps behind the cars ahead like a chaser (it doesn't push
  through): on a crowded road it can sit at 18 km/h for a minute (rescue 9 failed by the clock in
  one headless run with traffic; it made it with the road empty). Cars ahead giving way to a light
  bar (3g-1) is the traffic lane's; check on the phone whether it needs more.
- **The speech bubble's tail** can't reach a guard right next to the car: the bubble steps aside
  from the car and its tail points at the bubble's edge (the bubbles are shared with the police).
- **The clamp box** (a yellow box on the front left wheel, +1 draw call while shown) is a few
  pixels at the default zoom; the card says it.
- **Pedestrians stepping aside** from a car in the zone (police.md 5.6) is not built: the walkers
  are the city lane's.
- **The first contact** is its own parked car 150 m ahead (not one of the day's traps): the lizak
  log line names it "trap 0".

## Decided in loop 3g-1 (gameplay-dev defaults; the user may still change them)

- police.md section 17's open questions went with the spec's defaults (the brief): +15 respect
  for an escape; the helicopter allowed mid-chase and ending it; guard colours mustard and dark
  red; no roof marking; seven trap spots.
- **The start grace ends once the police have met the player** (a chase or a pull-over), so a
  scripted chase isn't followed by 3 minutes in which a ram can't start one. police.md says only
  "in the first 180 s of a session".
- **A second unit raises the level only after the level has held 5 s** (*guess*): a patrol that
  happens to be near when a chase starts would otherwise make it koguty 2 at once.
- **Patrol pacing**: 90-180 s after a patrol you met leaves the band, 10 s after one you never met
  (police.md gives only the count per Traffic level; with the band alone, two patrols would be
  in view all the time at Normal). They spawn ahead of a moving player.
- **The pedals step aside during the pull-over** (the car is held; the card needs the bottom of a
  375 pt tall screen).
- **Megaphone lines** keep the 20 s per unit of police.md, so the "every 10 to 12 s" chase lines
  come every ~20 s from one chaser.
- **The halos** are 5 m pools, blue at full and red at 0.8 brightness (4 m at half read too faint
  at night in the shots).

## From loop 3c (sector streaming on today's map)
- ~~**Adding a MultiMesh node costs the main thread 0.1–4 ms** on the Mac, whatever its instance
  count~~ Fixed in loop G0+: the cost was **physics interpolation** (on project-wide; the sectors
  inherited it). On the iPhone 11 a MultiMesh add cost 14 ms on average (37 ms at worst), a
  sector 188 ms, 490 frames of a 6-minute soak over the 3 ms budget and the governor dropped to
  GPU 0/2 · CPU 0/2; with `Sectors` and `Proxies` set to `PHYSICS_INTERPOLATION_MODE_OFF`,
  0.002 ms and 0.35 ms, 0 frames over budget, 0 governor changes (README "Loop G0+").
- **The AO, lamp-light and surface maps stay one texture each** (24 MB of video memory today,
  ~150 MB at the demo's 6 × 6 km). Per-sector slices can't be per-sector material uniforms:
  the post pass's water reflections and the moving vehicles sample the light and surface maps
  anywhere on screen. Loop 3d: a resident window texture (e.g. 2048 m at 1 m, ~20 MB for the
  three) composed from per-sector slices on a worker thread when the focus moves half a sector,
  uploaded one map a frame, the rects updated with it; or a texture array with a slot per loaded
  sector and an instance uniform (a shader change in ground, building, foliage, actor, poster,
  post).
- **Resident memory at the spawn**: video 336 → 263 MB (−22 %), the city's own buffers 158 →
  86 MB; static 140 → 140 MB (the index's game data, 32 proxies and the per-sector nodes and
  colliders cost what the whole city's unloaded part saved; `--sectors=all` is 165 MB static).
  The brief's "≥ 30 % lower" holds for the city's own share (~155 → ~85 MB), not the process.
  Loop 3d: the index's game data (roads, paths, areas, trees3d as Variant arrays of floats, ~20
  MB) should move into the sectors or packed arrays; the minimap into the pre-rendered image.
- **The runtime path's start** (5.7–6.0 s, was 10.9): ~2 s is the roof pass over every
  sector's file (missions, eggs and the helicopter read the roof grid over the whole map at the
  start). A cached roof grid (written by bake_city, checked against its inputs) or a lazy one
  would make it ~3.8 s; at the demo's 144 sectors the pass alone would be ~9 s.
- **Residual pixel differences** (≤ 0.2 %, at most 0.015 % at 2868×1320): the minimap's random
  markers (job offers), and a few sun-shadow edge pixels where fewer sectors are loaded (the
  directional shadow fits its depth range to the casters it sees).
- **Proxies** are a lag cover (shown only while a sector loads, or with `--sectors=proxies`):
  one wall and one roof colour, landmarks tinted. With the view test counting each sector's
  tallest roof, the far view loads sectors in full rather than showing proxies; at the demo's
  size the helicopter may need a cheaper far tier (proxies in view past ~1 km).
- The streamer's worker is a `Thread` per sector, not WorkerThreadPool: a GDScript callable run
  on a pool thread leaves one RefCounted per pool thread at exit (`ObjectDB instances were
  leaked`), which `tools/verify.sh` reads as a failure; a joined `Thread` doesn't.
- ~~The sector files and the prebuilt sectors are committed~~ Loop 3d-1 (the user's decision,
  2026-10-29): no longer committed (the pack grew 194 → 340 MB in a day of re-bakes); a fresh
  clone runs `tools/setup_map.sh` once, freshness is by content (README "Map data").

## Decided in loop 3c (map-engineer defaults; the user may still change them)
- The split is a new `tools/bake_sectors.py` after the chain (bake_osm.py is unchanged); the
  margins are 48 m for ways, areas and buildings (a road's reach), 8 m for point things, plus a
  floating part's supports and each building's shop-sign surroundings.
- The view needs a sector when its box up to its tallest roof meets the frustum, grown by 128 m
  (DEMO 2.4 said the ground footprint): no proxy ever stands where the whole city had detail.
- `--monolithic` keeps the whole-city build as the reference; `city.scn` is removed.
- The minimap stays one global mesh (brief item 7).

## From map review A (bridges, flyovers and tunnels, 2026-10-29)
- **Aprons sink the road under the drawn ground** at structure ends where the 10 m grid stands
  above the end's height: `terrain_height` lowers the ground there (`min` under an apron), but
  `_build_ground` draws the raw grid, so the road, its carriageway area, kerbs and rail beds lie
  under the ground mesh: the viaduct's west end (road 52 m², up to 0.65 m, the beige wedge on the
  westbound carriageway at `--at=188,104`; tram 28 m²), the west abutment's north ramp foot (991, -2: 52 m²,
  0.25 m), the Kruczkowskiego rail viaduct's west end (394, -55: 45 m², 0.45 m), and the four
  tunnel portals (20-89 m², hidden by the trench walls as far as the shots show). Fix (bake, the
  default): the chain solver's lower bound at a deck's end = the highest grid value across its
  carriageway, so the end stands at or above the ground across its width and no apron has to
  lower it; or (builder, after loop 3c) subdivide the grid cells an apron touches with
  `min(grid, terrain_height)`, with the draped areas and footways in them following. A check:
  a drawn road or rail corridor more than 0.05 m under the raw grid.
- **Lamp pools under and beside decks at night**: `lights.bin` is 2D, so a deck lamp's pool also
  lands on the water and shoals beside and under the bridge (orange arcs on Most Poniatowskiego's
  gravel shoals). Fix (shader, after loop 3c): scale the lamp light by whether the fragment is
  within ~2 m of the deck height `water.bin` already holds for that pixel.
- **Most Poniatowskiego's approaches are unlit at night**: `bake_lights.bridge_lamps` lights only
  `bridge=*` roads of 40 m or more; the abutments between the towers are approaches (`fills`).
  Fix: give the fill JSON the structure membership (`blurred abutment`, `between two bridges`)
  and light those too.
- **Rail tracks ending at different heights**: at the Solec viaduct's west end one track's deck
  starts 1.2 m under its neighbours (piece of OSM 1480623763), at Kruczkowskiego 0.5 m (each
  track's measured R2 profile). Fix: hold the parallel tracks of one deck group to a common
  profile at their ends.
- **The Tamka footbridge dips 2.2 m** 4 m from its north end (`--at=-20,-288`): an interior node
  shared with the footway under it is pinned to the ground. Fix: in the path family a node where
  a lower way passes under is a crossing, not a pin.
- **The Praga ramp's joint** (1493, -301): the ground strip and the ramp's strip meet at an angle
  and leave a ~3 m² sliver outlined by edge lines (C2 allowed). Fix: strips meeting at a deck
  joint share one end line.
- **Tram stop shelters** left out where mapped on the rails (14): place them on the stop's
  platform instead (the nearest `platforms` edge on the track's side).
- **River piers** (art): Most Poniatowskiego (an arch bridge on masonry piers) and Most
  Średnicowy stand on the same thin concrete posts as the viaducts; a river-pier style (wider,
  stone, cutwaters) would read more like Warsaw. A design call.
- Most Świętokrzyski, the Jana Pawła II viaduct and the Wisłostrada tunnel end at the map's rim
  (the diorama's void beyond): the bigger map moves the rim past them (known, DEMO.md 4.4).

## From map review B (the streets, 2026-10-29)
- Lines inside junctions mapped without a junction-box area: ~1.6 km of edge line and 0.4 km of
  lane line lie inside the clusters of junction nodes (most at Plac Trzech Krzyży (-77, 670), the
  Poniatowski ramps (1381, -344), Wał Miedzeszyński (1514, -147)); measured, not yet checked
  against the photo one by one (many are a real edge line along a wide junction's side).
- At night Al. Jerozolimskie at (-615, 394) and Nowy Świat at (-331, 18) read much darker than
  Marszałkowska and Świętokrzyska, though lamps are mapped along them (one per 42 m and 22 m of
  way): not judged in review B (the pools in `lights.bin` there, sodium or LED, cut by the
  buildings?); shots `shots/review_roads/after/n2_*`, `n4_*` (local).
- `check_streets` S3 also counts real median noses at a junction's edge (Świętokrzyska by Mariańska,
  18 cross-sections): reported, not failed.

## From loop 2d-1 (Podwózka, the app-taxi side job)
- **The pull-over is wired** (merge with 3g-1): `police.gd` `_talk_done` calls
  `rides.on_pulled_over()`; one star, verify step `ride-police`. 3g-2 may want its own opener for
  a pull-over with a passenger on board (police.gd `_opener` knows kebab and słoiki only).
- **The request card lost "your rating"** to fit beside the car on 390-pt phones (five lines of
  text above the pedals); the rating is on the result card. A request could show it on the
  PODWÓZKA button instead.
- ~~**Loop 2d-2 (after 3c's streaming)**: the `rechotka` quirk joins the random pool once the
  Frogs shops exist (was Rechotka 24; renamed 2026-10-30) (today it is flag-only and names a shop nobody can see), and the `detour`
  passenger (a stop at any Frogs, +½) needs them too; Pędzik, Leżak, the kebab stands and the
  billboards are 2d-2's; the `signs` and `column_posters` Podwózka lines (parodies.md 7) wait for
  the billboards.~~ Done in loop MW-2 (2d-2 folded in; "From loop MW-2"). `oldtown` falls back
  to a park until the map has the Old Town square.
- **PixelLab (not in this session)**: the Podwózka pickup icon (16 px), the "Nawigacja" avatar
  (32 px, it speaks as a plain bubble now), a believer and a student passenger portrait, the
  Podwózka billboard (parodies.md 9). The passenger figure is `props.gd`'s person with a hop and
  a bobbing "!" (2 draw calls), no waving arm.
- **River spots are few** (10, along Wybrzeże Kościuszkowskie and by Most Poniatowskiego): the
  river quirk only happens on rides from Powiśle and Solec (it must add at most 1.5 km). The
  waypoints are 30–70 m off the road across the boulevard; whether a player can actually drive
  there (steps, walls, benches) is unchecked: the autopilot ghosts through. Worth a look in the
  device pass; the map engineer could flag drivable promenade.
- **The ETA (road / 9 m/s + 20 s) is tight** with the lights: the test drive at 1.3× traffic
  speed took 178–190 s of a 195 s ETA. A careful player may often be late (−½ per 15 s). Tune on
  the phone with how long a ride feels.
- **Rivals' Centrum Nauki Kopernik finish lies on the map's north edge** (the landmark's
  centroid at 324,-879; the nearest node 328,-885): rides skip it; the race finish is probably
  odd too.
- **GPS moments on today's map are mostly "you have arrived"**: around the spawn the app-taxis
  drive dual carriageways (no U-turn), and the river moment needs the view by the river. A
  5-minute busy run at the spawn: 4 moments, all stops.
- **Driving penalties aren't measured under `--autopilot`** (the ghost's turns are steps, not
  driving); the rules are covered by `check_rides.gd`, the measuring copies the słoiki's.
- `hud.gd`'s context button is shared now (`pill_owner`: "call" or "ride"); a third owner
  (police?) should use the same `show_pill(pl, en, owner)` and `context_pressed`.

## Decided in loop 2d-1 (gameplay-dev defaults; the user may still change them)
- A rescue call ringing (WEZWANIE on the button) doesn't stop a ride request card; taking the
  ride puts the call off (90 s), as any job does. An ignored call would otherwise block rides
  for the whole session.
- A 4½-star ride keeps the 5-star streak (the spec: "below 4.5 or a cancel ends it").
- The tip is a share of the fare after the MNOŻNIK.
- Your rating counts the rides a save hasn't driven as 4,87, so one perfect ride makes 4,88,
  twenty make 5,00.
- The passenger gives up after 3 × the ETA in the pickup (the pickup's own ETA) and in the ride.
- The request card sits at the bottom, the result card top centre (the longest result didn't fit
  beside the pedals on a 390-pt screen).
- `podwozka_driver`'s two untagged lines are tagged `arrive` and `reroute` so each moment says
  its own; the offset pickup line ("the pin was a bit off") is tagged `offset`; "No widzisz,
  aplikacja wie" (the design's table) is a `followed` line.

## From map round 2 (2026-10-29)
- Done: D5 (the drawn ground follows the aprons; `check_roads` C11), the 14 tram-stop shelters
  beside their tracks (13; 1 with no clear spot), L3 (lamps on the main streets' unlit
  stretches), D6 (deck lamps light their deck only), D7 (the abutments lit). README "Map round 2".
- **Mapped lamps change colour along one street**: a mapped lamp whose nearest road is an unnamed
  way (a ramp, a service road) is LED by `bake_lights`' name rule even on a sodium street (seen on
  Al. Poniatowskiego by the towers). Fix: take the kind from the nearest *named* street within 14 m.
- **L1** (review B): lines inside junctions mapped as one carriageway area without `junction=yes`
  (Plac Trzech Krzyży, the Poniatowski ramps, Wał Miedzeszyński); orthophoto overlays drawn
  (`shots/review_structures/round2/ov_p3k.png`, `ov_ponir.png`, `ov_walm.png`), not judged or fixed.
- **D8** rail track ends at different heights (Solec 1.2 m, Kruczkowskiego), **D9** the Tamka
  footbridge's dip, **D10** the Praga ramp joint's sliver, **L4**, **L5**, **L2** (review B):
  not done this round; specs in `.handoff/review/structures_2026-10-29.md` and B's report.
- **The Podwózka river spots** (loop 2d-1 `rides.gd`, not merged): a waypoint 5 m in from the
  water, a straight line to a lane within 70 m over dry ground with no building. Not checked
  against the colliders yet: the line can cross a retaining wall, a shore stone, a fence or a
  boulevard's 3-5 m drop (the Bulwary below Wybrzeże Kościuszkowskie). Spec: a `drivable_bank`
  list in the index (bake_structures: dry points 3-8 m from the water whose straight line to the
  nearest lane crosses no solid wall, barrier line or shore stone and no height step over 0.5 m
  in 2 m), that `rides.gd` reads instead of scanning `shore_distance`.

## From map round 2b (2026-10-29)
- Done: the Podwózka river spots from the bake (`drivable_bank`, 19), the lamp colour along a
  street from a bridge, D9 (Tamka), L5 (Krucza), L1 judged and kept. README "Map round 2b".
- **Only 19 river spots** (most lines to a lane cross a guard rail along the Wisłostrada and
  Wybrzeże Szczecińskie, a retaining wall or a boulevard's drop): river rides cluster by Most
  Poniatowskiego's west abutment and south of it. More need a way in (service roads to the
  beaches) or a passenger who walks the last metres.
- **L4** Emilii Plater's three mapped median walls (`barrier=wall`, 41 barrier pairs over the map
  cross each other twice or more) still weave as dark lines; the orthophoto can't show low walls.
  Spec: draw a `barrier=wall` inside a median as a 0.4 m planter edge, or leave weaving walls out.
- **L2** kerbs within 0.9 m of a lane centre: not judged (kerbs are not solid for traffic,
  `check_drive` 0); spec as in review B.
- **D8** rail track ends 1.2 m apart (Solec) and **D10** the Praga ramp joint's sliver: as in map
  review A's specs.

## From loop 3d-1 (the demo map, the 18.6 km² box, 2026-10-29)
- ~~**Loop 3e's structures, all allowlisted with place and reason**~~ Loop 3e: W-Z's tunnel and
  portals, the Wisłostrada's portals (and the two Wybrzeże Kościuszkowskie steps), Plac Na
  Rozdrożu's tubes, Wiadukt Markiewicza and the Copernicus building done; what is left is in
  "From loop 3e". Was: **Loop 3e's structures, all allowlisted with place and reason** (`tools/check_roads_allow.json`,
  `tools/check_drive_allow.json`, README "Loop 3d-1"): Trasa W-Z's tunnel and portals (Aleja
  Solidarności, Grodzka, Nowy Zjazd, the tram's abutment), Trasa Łazienkowska's trench at Plac Na
  Rozdrożu (its ways are layer -1 with no tunnel tag: a cutting the grid doesn't show; 0.3-0.8 m
  height steps a frame in its tunnels) and its interchange with Czerniakowska, the Wisłostrada
  tunnel's north portal under the Copernicus Science Centre, Most Śląsko-Dąbrowski's Praga end,
  Wiadukt Markiewicza, the railway cutting west of Centralna (Żelazna, Towarowa, Kasprzaka and
  their footbridges, whose stairs aren't mapped), the Praga viaducts by the zoo (0.1-0.7 m short of
  the clearance).
- **The new 10 m grid moved the old map's ground** (the demo fetch samples the NMT 3.5 m east and
  5 m south of the old grid's nodes; ±0.7 m at p1/p99, up to 3 m on embankments): 27 allowlist
  entries no longer matched and went, new ones came, and two main-road spots now step: Wybrzeże
  Kościuszkowskie by Tamka (625, −453) 2.4 m in 6 m and (642, −548) (~~fixed in loop 3e: the
  Wisłostrada's south portals on the 1 m trench floor~~). A rule for a road's end on a
  hump of the grid, or the 1 m NMT along the river (one download, ~125 MB for the whole box,
  DEMO 3.1's optional line), would fix the class.
- ~~**The AO, lamp-light and surface maps** are 37 + 37 + 19 MB (93 MB of video memory as whole
  textures; the probe's textures 24 → 87 MB). Over the brief's 60 MB, but a window kept in RAM
  saves nothing on the iPhone's shared memory: it needs per-sector slices read from disk as the
  focus moves (the streamer's job, where the perf loop works now). Loop 3d-2.~~ Done in loop 3d-2b:
  per-sector slices in 24 array layers, textures 94 → 38 MB, video at the spawn 406 → 300 MB.
- **Static memory at the spawn 147 → ~220-315 MB** (the index's game data: roads, paths, areas,
  trees3d as Variant arrays, now 3× bigger; index.json 9.6 MB): packed arrays or per-sector game
  data (3c's note). Loop 3d-2.
- **The runtime path's start**: the roof pass over 88 sector files (3c measured 2 s for 32) and the
  monolithic build (`count_vertices.gd` 36 s): a cached roof grid. Loop 3d-2.
- **Most Łazienkowski is cut by the east edge** (x 1,773 mid-river): its deck ends in the air at the
  rim like Most Świętokrzyski's did on the first box. DEMO 2.1 said no bridge is cut; that held
  for the 30 km² box only. Move the east edge to ~21.056 (the fetch reaches it) or accept.
- **Speed traps 5-7** (`tools/bake_traps.py`): Warsaw's blocks give straight runs of 157-195 m
  (police.md asks 250 m with no junction within 80 m: the officer stands mid-run, the junctions
  78-98 m away); trap 6's road is named Aleja Armii Ludowej in OSM (radio phrase unchanged),
  its graph speed 79 km/h. police.md 13 wants them as `pois` kind `trap` in the bake.
- **Pedestrian zones**: `ped_zones` (83 polygons, the Old Town box) and the 20 km/h cap are in;
  the pill, guards, clamp and the guard car (police.md 5.6) are loop 3g-2's; Łazienki and the
  boulevards (police.md 13) are outside the box or need their own `PED_ZONES` line.
- **Scanned crowns into decks** (C9, 4 places: by Most Świętokrzyski's pylon one 15 m tree
  reaches 8.9 m into the slab at the 0.40 floor of trim_crowns): leave such a tree out, or let the
  floor go lower.
- **Police P3 on the demo map** (fixed): the test escape's random turns looped back past the
  chaser's side, a traffic patrol saw it within 60 m at 20 s (the second-unit rule: L2, cap 40 s)
  and the escape came at 34.2 s. The test autopilot (`--police-auto=escape`) now rides a route to a
  node ~900 m away from the chaser (`police.gd` `_escape_route`): escaped after 23.2 s at L1.
- `verify.sh` kebab: 15000 frames (order 0 goes 1,023 m on the demo map, delivered at 219.8 s).
- **CI after the merge (2026-10-30)**: the map is no longer in git (lod2.bin alone is 87 MB), so
  GitHub's `verify` job runs only the steps that need no map (steering, settings, tiers, governor,
  hud, rides, sfx, radio, police); the map, road, drape and drive checks and the game runs stay on
  the Mac. To bring them back: a release asset with the derived pack that CI downloads, or a small
  test map. `shots.sh`'s `settings_panel` shot is MISSING (the paused game never reaches the shot
  frame): a shot-script issue, not the map.

## From loop 3e (the structures, 2026-10-30)
- **Most Łazienkowski's Praga end and the Czerniakowska interchange (R8)**: where two ramps of one
  deck group part, a ramp's guard rail runs into the other's lanes and a bus brushes the slab of a
  neighbouring piece (check_drive 28 lane spots, 2 jumps at (2125, 805); C1/C8 at the ramps' joints).
  Spec: each ramp's rails and slab from its own piece, cut where another piece's lanes run (the
  deck-end rule, `GUARD_END`, everywhere two pieces part), and lanes sampled on their own piece.
- **The rail cutting west of Centralna** stays on the 10 m grid (C3 72 under its footbridges and
  Żelazna/Towarowa, Towarowa's deck joint 0.3 m). On its 1 m level (the WKD 7 m under the grid) it is
  24,000 m² of 1 m ground sub-cells (+0.5 M vertices), and its 8 m service bridges are shorter than
  the cutting the 1 m data shows. Needs the ground cut along a corridor (below) and "a way that
  crosses a cutting with no shared node holds its own level over it".
- **The ground cut along a corridor**: the trenches lower the drawn ground in 1 m sub-cells (633
  cells, +0.89 % vertices); the deck seeds (every structure's way) would fix Nowy Zjazd's pits and
  ~40 abutment findings more for +0.4 M vertices. Draw a lowered corridor's floor as one strip and
  clip the grid's triangles round it (a few triangles a cell) instead.
- **Plac Na Rozdrożu's tubes end short of the street over them** (OpenStreetMap ends T2-T5 a few
  metres before the street's edge): the open road's last metres pass under the street's corridor,
  its lanes step 0.6 m there (C8 2, C1 1, check_drive 9 lane spots at the west portals, 4 jumps at
  the rim west of them). Spec: extend a tube under a way that crosses its open road within 15 m of
  the portal with no shared node.
- **Wybrzeże Szczecińskie's deck over the Port Praski inlet (deck 4)** by Most Śląsko-Dąbrowski's
  Praga end: a bus on the outer lane at its west end brushes the neighbouring piece's parapet (the
  gap between pieces keeps a collider where there is a drop): 6 lane spots. The new footbridge to
  Karowa (deck 19, mapped `living_street`) still ends 2.2 m in the air at its Praga end (C6).
- **Nowy Zjazd under the W-Z approach**: a bus on its inner lane brushes the tram approach's
  0.6 m side wall at (−357, −1419) (6 lane spots).
- **check_drive's routes**: 98 now (every deck group and tunnel both ways); they found jumps at Most
  Poniatowskiego's north ramps (deck 13: 0.4-0.6 m at (920, 16) and (988, −13)), allowed with that
  reason.
- **The W-Z tunnel's trams**: OpenStreetMap's tram tracks through the tunnel are not drawn (tram
  tunnels are left out); the tram approach ends at the east portal.
- Build time: the monolithic build 58 → 75 s (the set fills' corridor tests in `terrain_height`).

## From map north (Rondo Radosława, Arkadia, Forest; 2026-10-31)
- **For the landmarks lane** (docs/DEMO.md 2.1 "Hand-over"): Rondo Radosława's flag mast (not in
  OpenStreetMap; the surface model has a 57.8 m column at (−2,850, −2,295)) and the island round it,
  Forest's tower (OSM part 923445779, 120 m; drawn today as OSM blocks), Arkadia (LoD2 today; its roof
  car park, OSM way 91341678 and ramps, is left out of the bake: the car-park race of DEMO 6.4 needs
  it modelled). Their parts are in the index's `site_parts` (`bake_sectors.py` SITE_NAMES "Westfield
  Arkadia", a SITE_AREAS box for Forest).
- ~~**For the gameplay lanes** (not built here; the map has a corner left `outside` since map north):
  the helicopter's clamp (`heli.gd`, `bounds.grow(-12)`), the car's off-map test (`main.gd`
  `_node_spot`), Podwózka's named finishes and river scan (`rides.gd`), the missions' and eggs'
  random spots (`missions.gd`, `eggs.gd`) and the minimap's frame (`hud.gd`, `full_map.gd`) still
  use the bounding rectangle: the helicopter can fly over the empty north-east corner (nothing is
  drawn there; the edge walls stop the car), and a random spot there snaps to the nearest road.
  `map_builder.gd` `in_map(p, pad)`, `map_outline()` and `clip_to_map()` give the shape. A notebook
  place for Rondo Radosława / Arkadia is the content lane's (`game/data` places).~~ **Done (the
  L-shaped map loop, 2026-10-31)**: all of them use the outline (DEVELOPMENT.md "The L-shaped map in
  gameplay"); the minimap and full map shade the corner as off the map; Rondo Radosława, Arkadia and
  Forest are notebook places (a ninth card in `kiedys`, `codziennie` and `bary`: the 9 x 8 rule is
  now 8 to 10 a chapter, QUESTIONS); `check_edge` proves the clamp, the spots and the mask.
- **From the L-shaped map loop**: the barriers' day street (eggs.gd) may differ near the corner for
  some dates (the pool of segments 120 m inside the outline is smaller); the helicopter's clamp is
  only in heli.gd: an autopilot target in the corner (none today) would be chased along the edge.
- **Rondo Radosława's ring has no spiral lane lines** (`bake_roads._spiral_rings`: its pieces carry 2
  and 3 lanes, and the first piece decides): plain lane lines; cosmetic.
- **The committed maps grow with the bounding box** (ao.bin and lights.bin 40 → 48 MB, water.bin
  20 → 24 MB, most of the growth zeros over the corner left outside): the export leaves them out
  (the prebuilt sectors carry their slices); a per-part layout would save ~16 MB in the repository.
- **The looser LoD2 match is cautious**: half the footprint in OSM outlines (8 models); at 30 % it
  would be 27 models touching 44 plain blocks (the diagnostic's 59 counted any touch). What stays:
  L1 15 OSM blocks drawn inside a model whose centroid misses them (towers' podiums, courtyard
  wings), L2 73 big outlines a small model's centroid falls in (the outline hidden, the model
  small); `tools/check_lod2.py` lists them with `--at=`.
- ~~**check_police P12 "guard car follows 15 s" failed once** in the full `verify.sh --ios` run
  (map north, 2026-10-31) and passed 3 of 3 alone: a timing-sensitive case under load (gameplay lane).~~
  **Fixed (the L-shaped map loop)**: not load but chance (1 run in 12 alone): the guards' car's
  random spot missed the check's one road 4 tries running; each case now seeds the random numbers
  (`FRESH_SEED`): 20/20 alone, 21/21 three at a time.
- **The viaducts at the north edge**: Jana Pawła II's and Andersa's decks over the ring railway end
  in the air at the edge (C6 allows the rim; the edge walls stop the car 5 m before). The ring railway
  and Dworzec Gdański's platforms lie just past it; the next growth north takes them in whole
  (needs the ortho, trees and OSM past 52.2595: a new fetch).

## From loop 3d-2a (the ground, part one, 2026-10-30)
- **The full cut under roads** (clip the ground along the road surface, close it with skirts) is
  not built: of the ground under roads only whole 10 m triangles go (1,109 under the road surface
  alone, the rest under areas). Cutting the partly covered cells adds triangles on every one of them
  to save overdraw the iPhone's tile GPU mostly hides already (the flat mesh is opaque, one draw
  call a tile). Worth it only if a Metal System Trace on the phone shows the ground's fill under
  the streets: measure first (perf-engineer), then `_build_ground` can clip by the same cover lists.
- **Coarser ground needs the terrain cleaned** (Slop New York's "survey pits and bumps removed"):
  the 10 m grid has almost no flat blocks within the 2 cm that keeps the heights (1.9 % of the
  cells in 20 m blocks), but 47 % within 15 cm. Snapping near-planar blocks in `bake_terrain.py`
  changes the driving heights by up to that, so the whole chain re-bakes (decks, lanes, check_roads
  allowlists). A decision for the user (docs/QUESTIONS.md); it would also merge the areas laid on
  the grid.
- **The flat mesh's big layers now**: footways and paving 1.88 M vertices (exact strips clipped to
  every grid triangle since loop 3b-2), grass and parks 1.39 M, roads 1.21 M, islands and kerbs
  0.80 M, markings 0.68 M; the ground 0.99 M. The footways are the next one to look at (10 m
  pieces where the grid under them is flat, as roads are laid).
- **Build time**: the cover tests cost the monolithic build 44 → 58 s and bake_city 75 → 90 s
  (~0.13 s a sector on the runtime path's streaming thread). A per-sector cover cache in the split,
  or Clipper on a cell's union once, would win it back.
- `check_ground` leaves 6 triangles it calls covered (a test point on a seam between two pieces;
  `HIDDEN_MAX` 30).
- Fixed on the way: `bake_city.gd` printed 12 `ERROR`s counting the empty proxies of sectors with
  nothing to show (since loop 3d-1).
- The brief's 18.19 M vertices was the 18.6 km² box; the demo box since Q3's re-bake counts
  19,488,688 (now 19,052,803).
- `shots.sh`'s `settings_panel` shot (3d-1: MISSING) came out in 8 of 9 runs this loop, one MISSING
  then fine on a rerun: flaky, not broken. Three prebuilt spot shots with `--time=day` once came out
  at night while other Godot runs were going; fine on a rerun.

## From the loading fix (the view's sectors first, city-coloured proxies, 2026-10-31)
- **A look at a far target still shows proxies in passing on the iPhone 11** (25 frames over 5 %
  of the view in six looks, 0 on the Mac): the camera flies over sectors on its way that load only
  as it reaches them. Expecting the whole way too was tried and dropped: the 24 map slots fill
  (265 slot waits on the Mac) and the target's own sectors then wait. A shorter or cut look for
  targets past ~1.5 km, or more map slots (QUESTIONS 3d-2b), would end it: the camera's lane.
- **Jumps load the view's sectors at once** (the frame of the cut): on the iPhone 11 the jump pass
  has 15 frames over 33 ms against 11 (one or two at each cut); the alternative is a second of
  proxies at the new place.
- **Fotka's camera isn't the streamer's**: `fotka.gd` orbits its own camera while
  `sector_streamer.gd` is fed the main one; its views stay within the 704 m square loaded round the
  car today, but a wider Fotka zoom would show proxies (content lane: feed the streamer the current
  camera).
- **The proxies at night** use a plain lit material: no lamp light or lit windows (the city's
  night look comes from its own shaders). Rarely seen now; a night tint is the next step if it is.
- **The proxies' boxes are 8 m cells**: a building reads as a stack of coloured blocks up close
  (`shots/loadfix/proxy_close_after`). LoD2 outlines would be truer but cost triangles (15,000 a
  sector).
- **Turning-aware look-ahead not built**: the helicopter at 360 m turning shows a proxy's edge at
  499 m (0.3 % of the view) at worst; the 704 m square round the focus already covers any turn.

## From loop 3d-2b (the map engine, part two, 2026-10-30)
- **Far levels are not built** (measured: with the orthographic camera every sector drawn has its
  ground on screen; the proxies show only while a sector loads). A far level by zoom, the
  helicopter's highest views drawn as painted proxies (357 → a few dozen draw calls over the
  centre), changes the look of those views: the user's call (docs/QUESTIONS.md). Landmarks would
  need a LOD1 from `landmarks.gd` (the landmarks lane).
- **The helicopter is ~33 draw calls a pass** (26 boxes and the lights under its body,
  `heli.gd`): one mesh with vertex colours (rule 2 of "Performance budgets") would save ~60 draws
  in every flying view, more than any far level. Gameplay or performance lane.
- **Map slots**: `CityMaps.SLOTS` 24 (32 MB); the 3-minute soak reached 24 sectors in full at once
  (the 220 m view with the hysteresis), the passes 15-20; a load with no free slot takes one from a
  sector kept only by the hysteresis (`evictions`), else waits (`slot_waits`; 0 in every run). A
  bigger map or wider views may want 28-32.
- **The runtime path** (the editor) still builds a sector's meshes and colliders on the worker and
  hands them over at once (its load-end frame keeps the old cost); its start still runs the roof
  pass over every sector file (23 s on the demo map: BACKLOG "From loop 3d-1"). The phone's path
  is the prebuilt one.
- **check_streaming spot 8** came down to 0.015 % (it was 0.789 %, `SPOT_MAX` 1 %); the limit is
  left until a few more runs agree.
- `verify.sh` streaming takes ~8 minutes now (the two passes).

## From the radio playlists loop (2026-10-29)
- Done: radio.json, shuffled playlists, `tools/add_music.py`, the radio check, README "Adding music",
  CREDITS "Music".
- **No libvorbis in this Mac's ffmpeg** (Homebrew's build lacks it): `add_music.py` falls back to
  ffmpeg's built-in `vorbis` encoder, which ignores the bitrate and writes about 185 kb/s (4.1 MB
  for a 3-minute song instead of 2 MB). Fix: an ffmpeg with libvorbis (the brief's `-c:a libvorbis
  -b:a 96k` is already what the tool uses when it finds one), or `oggenc`; nothing else changes.
- **Licences before a release**: any track whose licence is `unknown` (a WARN in the radio check)
  must be cleared; AI music tools' free plans may not allow a published game.
- ~~**No skip button**: `radio.next_track()` exists, but hud.gd and main.gd (not touched in this loop)
  have no control for it; a tap on the ticker, or a key, would do.~~ Shift+R skips on the desktop,
  and holding RADIO for 0.5 s skips on the phone (2026-10-30; a tap still changes the station;
  `check_hud.gd` covers it). Nothing on screen says so yet (QUESTIONS.md).
- ~~**`--radio=N`** clamps to the built-in three stations (`Radio.STATIONS.size()` in main.gd): a
  fourth station added to radio.json is reached with R, not by the flag.~~ Fixed (2026-10-30): the flag
  clamps to radio.json's stations once they are read.
- **A station's order restarts a track on re-tune**: tuning away and back starts the track it was
  on from its beginning (a looping single track still joins in the middle). A real radio would
  have moved on; a decision for the user if it grates.
- **The three original loops exist only as Ogg now**: their raw WAVs were in the repo and are gone;
  `tools/make_music.py data/raw/music/<station_id> shots` regenerates them, then
  `add_music.py --force`. The Ogg files are lossy copies of the lossless loops.

## From loop G0+ (streaming and heat on the iPhone 11)
- **A sector's load still makes one slow frame on the iPhone 11** (loop 3d-2b: on the Mac the cause
  was the collider, built by the physics server on the main thread at once; now 1,000-face patches
  and every piece one a frame, the slowest load frame 23.8 → 13.0 ms; the phone's numbers are still
  to measure with a `--stream-soak` device run) (19-22 frames over 33 ms in a
  6-minute soak, 25-65 ms each, none with any of the streamer's own work in it): the render
  server creates the sector's meshes and MultiMeshes (its GPU buffers) on the main thread when the
  worker's load ends (with `--render-thread separate` the same time moves into the frame's draw,
  the main thread waiting for the render thread: no better). A frame-sized piece would need the
  sector's resources split so the worker can load them one a frame: each tile mesh and
  MultiMesh of `s_<i>_<j>.scn` as its own resource (or the sector as four 256 m scenes), a
  `bake_city.gd` change (map-engineer; loop G0+ didn't touch the bakes). Other options: keep the
  last few unloaded sectors' roots (not freed, out of the tree) so a sector seen again minutes
  later comes back without a load (memory against hitches), or load further ahead so the hitch
  falls while the view is calm (it doesn't remove it).
- ~~**`tools/device_run.sh` copies `Documents/bench_result.txt` from any earlier bench** when the
  run made none.~~ Fixed (performance lane, 2026-10-30): a bench (`--bench` or the BENCH
  button) removes the last result when it starts.
- ~~**The night bench sometimes has a sun-shadow pass** (on the Mac, 2 of 6 `--time=night`
  benches: 57-69 shadow draws where the others have 0).~~ Not reproducible on main 81de932
  (performance lane, 2026-10-30): 12 night benches (runtime and prebuilt, 1920×1080 and the
  default window) with a watcher on the sun's shadow, every light's shadow and the shadow pass's
  draws per frame: the sun's shadow off from frame 1, no light casting one, 0 shadow draws in
  every run. The code path hasn't changed since; those runs likely had other flags or a saved
  time. If it shows again, the watcher's shape: print `sun.shadow_enabled`, `tod.mode`, `tod._t`
  and the shadow pass's `VIEWPORT_RENDER_INFO_TYPE_SHADOW` draws per frame.
- The streamer's `(unload)` time is only the call to `queue_free()`; freeing a sector's nodes
  happens at the end of that frame and isn't in the streaming numbers (no slow frame showed it).
- **check_streaming spot 8 (512, −740) at 0.789 % of its pixels** (the limit is 0.5 %; 0.472 % with
  the east edge at 21.050 and the 10 m terrain). Deterministic. The differing pixels are ragged
  shadow-edge patches on the ground, as many darker on each side (1,208 vs 959 sampled): the
  directional shadow fits its depth range to the casters it sees, and the whole city (the
  reference) has more of them than the streamed one, not a sector missing geometry (the identity
  part passes). Judged in the game (shots/spot8: the streamed sectors against all of them, 0.07 %
  visible, single texels of lamp-pole shadow edges, nothing moves): spot 8 has its own limit of
  1 % in `check_streaming.gd` `SPOT_MAX`, the reason there.
- `verify.sh` ride: 30000 frames (the river quirk's legs run 1.7-1.8 km on the demo map).


## From the first Android build (2026-10-29)

- **Nothing has run on an Android phone.** The AAB is built and signed, but the game has never
  started on Android: touch, haptics (`Input.vibrate_handheld`), the save path, the frame rate,
  the governor's tiers (`tiers.gd` knows iPhone model ids only, so an Android phone gets its
  default level) and the HUD's safe area round a camera cutout are all unseen.
- ~~**Vulkan is "not required" in the manifest**~~ **Decided and done (code 2)**: the user chose
  to require Vulkan; `game/addons/nw_android_export` marks both Vulkan uses-features required and
  `tools/export_android.sh` checks it (README, "Android (Google Play)"). `fallback_to_opengl3`
  stays off. The version is Godot 4.7's own, 0x401000 (Vulkan 1.1.0), not 1.0.3: on a Godot
  upgrade, match the plugin's `VERSION` to what Godot writes (the script fails until it does).
  Whether a phone with Vulkan 1.1 but a weak driver runs the game well is still unseen.
- ~~**The export prints Dialogue Manager's C# errors** (`No loader found for resource:
  ...DialogueLabel.cs`, `ExampleBalloon.tscn` parse errors).~~ Fixed (store-release lane,
  2026-10-30): the iOS, Android and Web presets exclude the add-on's `.cs` files, its C#
  `DialogueLabel.tscn` and `example_balloon/*` (the game uses its own balloon; the add-on's
  editor plugin, the only reader of the example, is off).
- ~~**The city step rewrites 34 tracked files with byte noise**~~ Moot since loop 3d-1: the
  prebuilt sectors are derived and gitignored, and `setup_map.sh --if-needed` rebuilds them
  only when their inputs' digests change (tidied 2026-10-30).
- ~~**Store graphics are not made yet**~~ Done 2026-10-30: `docs/store/graphics/` (the 512 px
  icon, the 1024 × 500 feature graphic) and `docs/store/screenshots/play-phone/` (ROADMAP "play
  graphics").

## From the website (aroundwarsaw.app, 2026-10-29)
- ~~The four beta links say "soon"~~ (website v2: the form collects emails for invites; add the
  public TestFlight and Play links to the beta section when they exist).
- The site's form posts to the Stillplace Formspree form (`mykaeqjp`); give Around Warsaw its own
  form, and check the form isn't restricted to stillplace.app.
- ~~The game still calls its station NOCNA FM (`radio.gd`); the site says Kebab FM, as the user
  asked on 2026-10-29.~~ Renamed in the game too (KEBAB FM, 2026-10-30).
- ~~The screenshots are from the prototype~~ (website v2: eight new `--nohud` shots, 2026-10-30).
- From the landing's screenshot session (2026-10-30, runtime city, 2868×1320): the map's edge
  shows in wide views (about `--size=220` and up): a flat light-blue void by day east of the
  stadium and west/south of Varso, a sunset band at dusk, a dark slab at night, and a brown
  streaked "skirt" south of Varso (`--at=-1602,717 --yaw=0 --size=240`). It matters for any
  wide or marketing camera and for the helicopter high up.
- ~~`--time=night --nohud` runs quit without writing the shot about one time in three (the log
  ends after "city built", clean exit); by day, or without `--nohud`, every run wrote it.
  `tools/shots.sh` would report MISSING.~~ Not reproduced on the big map (2026-10-30, 37 runs on
  the Mac, the landing's own flags included: all saved). Suspected cause: keys typed in another
  app landing in the freshly focused game window (two renders came out in the helicopter or at
  dusk). `--shots=` now keeps the window from taking the focus, as `--no-input` does, and a run
  that ends without a requested shot prints `shots: missing [...]` with the frame and pause state.
- The occlusion dither cuts a visible hole in towers in stills (Rondo Dmowskiego
  `--at=-806.3,446.4 --heading=335`, Varso with `--yaw=250`, the Palace's wing looking north
  from Emilii Plater).
- A thin dark crack-like line across the plaza at the Palace's south-east corner at night
  (`--at=-1410,159 --yaw=90 --size=260 --time=night`, visible at full size).

## From the store listings (2026-10-30)

- `https://aroundwarsaw.app/support/` exists in the repo (`docs/support.md`) but goes live only
  with the next deploy; the store forms link to it.
- iPad: the iOS preset targets iPhone and iPad (`targeted_device_family=2`); keep or drop
  before the first App Store release (QUESTIONS.md). Nobody has played on an iPad yet.
- ~~The App Store wants a privacy manifest~~ (checked 2026-10-30: Godot's export writes
  `PrivacyInfo.xcprivacy` with file timestamps, boot time and disk space, no tracking, no
  collected data; app-store-connect.md section 4). Still read App Store Connect's email after
  the first upload for an ITMS-91053 warning.
- The store screenshots show the HUD; they need redoing when the HUD changes  (re-rendered with KEBAB FM
  on 2026-10-30; shot 07 from the bigger demo map, because on main's map Varso stands about
  140 m from the edge and every wide framing shows the cliff).
- The occlusion dither shows as a dark dotted patch in store shots 01 (bottom left) and 07
  (iPhone and Play, left of Varso); re-take them when the dither is fixed or loop 3d-1 lands.
- ~~**On a 4:3 screen (iPad) the pull-over's dialogue panel never appears**~~ (fixed
  2026-10-30: a 4:3 window was taken as a phone 390 pt tall, so only 520 pt wide, and the
  ~610 pt card found no room; `screen_points.gd` now takes a narrow window as 667 pt wide and
  knows the iPads. A real iPad, 1376 pt wide, never had it.) The iPad's fifth store shot is the pull-over again.
- On the ride HUD at 4:3 the distance marker ("1597 m" and its arrow) can sit on the HAMULEC
  button (`--ride=2`).
- Varso's crown runs off the top of store shot 7 (all three sizes); most shots show 0 km/h.
- The iPad set is rendered at 2440×1830 and scaled to 2752×2064 (the Mac can't open a
  2064-pixel-tall window).

## From the performance baseline (2026-10-30)

- ~~Loop 3d-1's map left +0.4–0.6 ms of main-thread process on the Mac after the lamp fix
  (traffic about 0.5 ms): find what in traffic scales with the map.~~ Timed (2026-10-30):
  nothing does; ~10 µs a car, 0.31 ms on the prebuilt path. Two small cuts landed. Left:
  `_count_target` and the first spawn fill are rare one-frame spikes (0.4–0.7 and ~1 ms) when
  the view moves far; spread them over frames if a hitch shows on the phone.
- Static memory doubled with the bigger map (173 → ~330 MB runtime, 241 MB prebuilt): check
  it on the iPhone 11 (TEST · BENCH's memory line) before the beta. The index packing cut it
  by ~20 MB on the phone path (2026-10-30, DEVELOPMENT.md "Performance budgets").
- Memory still on the table (2026-10-30, measured on the Mac):
  - The index's dictionaries (83 MB prebuilt after the packing): ~60 k small Dictionaries with
    a String kind each. Columns per list (one PackedFloat32Array of outlines with offsets, kinds
    as ints) would cut most of it, but every reader (hud, missions, eggs, pedestrians, rides)
    changes with it.
  - The three map-wide textures (~96 MB video): the light map (5318×3782 RG8, 1 m) could go to
    2 m (lamp pools are 12–15 m wide, but they stop at walls at 1 m), or AO and lights to ASTC
    4×4 at bake time (half the size, lossy). Both change the look a little: the visual lane's
    call with shots. The surface map holds data (deck heights, flow angle) and must stay exact.
    **Tried 2026-10-30 (performance lane), held back for one phone bench**: AO and lights imported
    VRAM-compressed (EAC RG11 on the phones, BC5 on desktops, a byte a texel instead of RG8's two),
    attached when the prebuilt city opens (the phones take the imports, the web keeps the RG8 .res:
    both formats in its pack would be +62 MB in the browser's memory). The code is on branch
    `claude/project-thread-ldyr9u` at 70faaca (with f613944), reverted before landing. On the Mac:
    the look is the same (by day 0 pixels differ by more than 8; at night 0.75 %, one-pixel
    outlines on the lamp pools' band edges), "textures" 138 → 96 MB, but "video" 393 → 416 MB:
    the first VRAM-compressed texture brings a one-time +65 MB of other video memory (the same
    for one map as for two; three runs each, identical). Only the phone's BENCH card can say
    whether the iPhone pays that too (−42 MB if not, +23 MB if so): QUESTIONS.md.
  - Side jobs hold 17 MB at start (rides 7.5): look for whole-map tables built from the index.

## From the driving-feel loop (less sticky, 2026-10-30)

- ~~Street furniture is still solid and unknockable: benches, bike racks, advertising columns,
  shelters and parked cars.~~ Benches, bins, bike racks and columns are driven through since the
  easy-driving loop (2026-10-30); shelters and parked cars stay solid (3 shelters overlapped a
  carriageway on the old map). Knocking them about like the roadworks' cones is still open.
- Corner slip and the shove are tuned on the flat test ground (`check_steering`) and by reading
  the numbers, not yet on the phone: how a 35 % bump feels, whether 7 m/s of sidestep reads as a
  jump at 60 fps, and whether shoved traffic overlapping the next lane looks wrong.
- A shoved car slides off its line only on a lane, not on a junction's curve.


## From loop MW-0 (Moja Warszawa: data and lines, 2026-10-30)

- ~~`game/data/brand_denylist.json` lists real business names for the audits; the export presets'
  `include_filter` (`data/*.json`) ships it inside the app.~~ Done in MW-0: both presets'
  `exclude_filter` leave it out of the bundle (the checks read it from the project).
- Title-collision rule (vision.md): an older `police_warn` line's English gloss says "the patrol
  car", and "Patrol" is the title of one of the artist's singles. Not changed in MW-0 (existing
  lines stay); reword the gloss ("the police car") in the next content pass if the rule is read
  strictly.
- `places.json` `near` hints are rough (about ±150 m), from memory of the map, not measured: the
  MW-1 bake resolves each address or anchor and should print the distance from the hint, so a
  wrong anchor shows at once.
- The places' `hours` are the game's own hours for the parody venues, not the real ones; MW-3's
  queues use vision.md 4.5's hour curves, not these strings.
- Two places share an address with another on purpose (Miłość Hipoteczna and Żwir at Kredytowa 9,
  Pawilony and Apteczka at Nowy Świat 22/28): the notebook may find both at once. If that reads as
  one find, MW-1 can offset Żwir to the upstairs door and Apteczka 30 m into the courtyard.

## From loop MW-1 (the MOJA WARSZAWA notebook, 2026-10-30)

- ~~**The minimap opens full screen** (F, 2026-10-30): a tap on the minimap opens a full-screen map
  with the notebook's "?" marks and found places; another tap or the back gesture closes it.
  HUD, content lane; 0 cost when closed.~~ Done (F's asks, 2026-10-30: `full_map.gd`).
- **The real bake resolution (map lane).** The notebook resolves the places at load from the
  `near` hints (`notebook.gd` `resolve`: the bake's projection, then an address poi, a named
  square, park or landmark, or the place's own poi kind, within 300-600 m of the hint). The 3d
  bake should resolve every `address` / `osm` anchor into `pois` kind `place` (with the place id),
  print the distance from the hint, and `notebook.gd` then take that point first. Today 45 of 72
  places sit on their rough hint (the 48 `osm` anchors mostly), and the address matches are up to
  359 m from their hints (Smoła, Smolna 38; Stara elektrownia, Dobra 42), so either the hint or
  the anchor is wrong there.
- `check_places` reachability (a lane or footway within radius + 10 m): 70 of 72. Not reached:
  Most Śląsko-Dąbrowski (65 m, on its hint) and Stadion Narodowy (115 m: the `stadium` poi is the
  bowl's middle; the helicopter's 60 m doesn't reach either). The bake's point (the west gate)
  fixes the stadium.
- ~~**PÓŁNOC FM track unlocks (MW-5).**~~ Done in loop MW-5: `notebook.gd` emits
  `chapter_done`, `radio.gd` `sync_chapters` opens the next locked track (saved in `[polnoc]`).
- The finding rule's "stop inside for 1 s" never decides anything with the car: a car stopped
  inside the radius is under 30 km/h and found at the next 2 Hz check anyway. Kept as specified
  (`Notebook.finds`, checked); if the stop is meant for a wider reach (parked at the kerb just
  outside), it needs a number.
- The shared addresses: Miłość Hipoteczna and Żwir both sit on their hint today (Kredytowa 9 is not
  an address point in the map), 18 m apart; Apteczka and Pawilony both matched Nowy Świat 22/28
  (the same point): one pass finds both, two toasts in a row (the second replaces the first).
  Not offset in MW-1 (the bake's anchors will separate them).
- ~~The minimap's "?" shows undiscovered places within 400 m of the car (vision.md: "in a
  discovered district"; there are no districts yet). Switch to districts when DEMO 6.3's exist.~~
  Loop 3h slice 1: each discovered district adds its first three unfound places as "?" anywhere
  (the 400 m marks stay).
- The card shows no district (~~places.json has none~~: loop 3h slice 1 added `district` to every
  place; notebook_page.gd doesn't show it yet) and no address for a venue (an address can name the
  real business: "Jasna 1" on the denylist).
- Chapter icons are the chapter's number on the notebook's chips until the PixelLab icons
  (vision.md section 9) exist.
- The tap-a-place-within-80-m way of finding (vision.md 4.1, the landmark card's tap) is not
  built: the landmark tap (`main.gd` `_on_tap`) doesn't know the places yet.

## From loop MW-5 (PÓŁNOC FM and the city's sounds, 2026-10-30)

- Done: the 7 PÓŁNOC FM tracks (`tools/make_music.py --set=polnoc`, 3.93 MB of Ogg at 22.05 kHz,
  40 kbps), the station (86,0; on air 22:00-06:00 and in the Night/Dawn looks, reruns at 70 % by
  day, Kuba's `radio_polnoc` lines every 60-120 s, the ident first), the unlocks (tracks 1-2 free,
  a chapter opens the next, `radio.unlock_track(n)` for the eggs), the city's sounds
  (`city_sounds.gd`: club leaks by their hours, the metro chime, the bells at the hour, the
  Patelnia busker 19:00-22:00, the 02:00 beat on Plac Trzech Krzyży), `check_radio`'s PÓŁNOC FM
  part, `check_city_sounds` (verify step `sounds`, CI too), `--station=`, `--radio-log`, `--unlock=`.
- **Judged by numbers only**: no speakers in the container. Loudness -13.8 to -14.0 LUFS, true peak
  ≤ -1.5 dBTP, seams clean, band energy like the other three loops. The levels of the city's
  sounds (`city_sounds.gd` KINDS: club -10, metro -12, bells -6, busker -11 dB on SFX) and the
  70 % rerun level are guesses until heard on the phone. A phone speaker drops most of the club
  leak's kick and the sub bass: the bass carries harmonics for that, but check by ear.
- **Chapters 6-9 open nothing yet**: vision 4.1 gives the last two a horn tune and the gold
  notebook cover (later loops); chapters 6 and 7 have no reward beyond the złoty and respect
  (7 tracks, 2 free, so 5 chapters open tracks). An egg's track (E14: 5, E31: 2, which is free
  already) is skipped by the chapters, so then one more chapter opens nothing.
- ~~**The eggs E14 and E31** only need `radio.unlock_track(5, "egg")` / `(2, ...)` (MW-6); E31's track
  2 is free from the start, so its reward is a no-op as written: a design question for MW-6.~~
  Done in loop MW-6: E14 opens track 5; E31 opens the next locked track when its own is free
  (the default built; an Open Question of the loop).
- **Skipped (their crowds are MW-3 / MW-4's)**: ~~the steps crowd's murmur, the guitarist on the
  steps, the queue murmur~~ (done in loop MW-3: `crowd_murmur` and `steps_guitar`), ~~dog barks at
  horns~~ (done in loop MW-4: three barks at the AI cars' horns), Jasna 0's grate rumble, dawn birds and the first tram's bell, the metro's ventilation
  hum, the club door "closing" between admissions.
- **The fixed looks' clock** (`time_of_day.gd` `local_clock`: Day 14:00, Dusk 19:30, Night 01:30,
  Friday night) runs on in real time from when the look was set, so the bells strike after an
  hour of play and the 02:00 beat comes 30 minutes into a Night run. MW-3's city clock should
  take this over. (Loop MW-3: `--clock=HH:MM` now sets a fixed look's start and Dawn is
  Saturday's 05:45; the clock still runs at real time and the look doesn't follow it: still open,
  "From loop MW-3".)
- **The radio follows the clock** (PÓŁNOC FM on air, KEBAB FM by day) until the player presses R or
  RADIO in the session; a station change by the clock shows the ticker. Not saved between sessions.
- **The host speaks text only** (vision Open Question 6).

## From loop MW-6 (Fotka, Spacer, KASETA and the eggs, 2026-10-30)

- Done: the 45 egg cards (`data/eggs.json`, `egg_book.gd`; 26 reachable, 19 waiting), KASETA
  (`tape.gd`, the 20 then cards with a dithered ghost each), Spacer (`spacer.gd`), Fotka
  (`fotka.gd`, `data/kadr.json`'s 15 Kadr spots), the notebook's SEKRETY / KASETA / KADR pages,
  `check_eggs` and `check_tape` (verify steps `eggs`, `tape`; quick set and CI), `check_hud`'s
  new pages and Fotka's controls, the flags (DEVELOPMENT.md "Fotka, Spacer, KASETA and the eggs").
- **The 19 waiting eggs** and what wakes each: ~~E01 E21 the garage's paint~~ (woken in the garage
  loop: 1 waits now, E35); ~~E03 the dawn crowd
  and the Dawn look (MW-3); E04 the patrol cars parked by the clubs (MW-3); E15 the guitarist
  on the steps (MW-3)~~ (woken in loop MW-3: 16 wait now); ~~E16 E27 the dog walkers (MW-4); E18 E19
  Wiralek's trend cycle (MW-4)~~; ~~E23 E25 the night buses at Centralny (MW-3 skipped them: "From
  loop MW-3"); E24 the player's horn and buses pulling in at stops~~ (woken in the night-buses
  loop: 4 wait now);
  ~~E28 the Rowerilo riders (MW-4); E29 E30 Kolka and Hyrax (MW-4)~~ (woken in loop MW-4: 9 wait
  now); ~~E34 the armchair man (MW-4 skipped it: "From loop MW-4")~~;
  E35 KASETA's older decades (T1); ~~E39 a tram in old livery~~ (woken in the vintage-tram loop: 3
  wait now; T13 stays waiting: "From the vintage-tram loop"); ~~E40 the payphone prop (with T17)~~
  (E34 and E40 woken in loop jobs-2: 7 wait now; T17 is not a then card: "From loop jobs-2").
  Each needs only its trigger in `eggs.json` (drop `waits`) once its piece exists.
  ~~The Frogs shop's two eggs are not cards yet (MW-2).~~ Done in MW-2: `easter_rechotka`,
  `easter_lezak`.
- **Words to review (designer)**: the egg lines vision's table doesn't quote and every English
  name are this loop's (marked in the generator); the 15 Kadr spots (`kadr.json`: names, places,
  looks) are this loop's picks; the KASETA ghosts are boxes from the then cards' ghost notes.
- **The ghost is dim at night**: it reuses `building.gdshader` (no new shader), whose emission
  is scaled by the same dither fade, so the then-building glows less than the city around it.
  A visuals-lane tweak (a `ghost_glow` uniform) would fix it; until then KASETA reads best by day.
- **E09's place** (`most_poniatowskiego`) resolves 330 m south of the bridge, in the river (its
  `near` hint, 52.2337, 21.044). The egg anchors on the bridge's road instead (`road` in its
  trigger); the notebook's own card still sits on the hint: map lane (the bake's anchors).
- ~~**E10 (Plac Zbawiciela)**: vision's "a crowd outside" became hours 18-02 in summer (no crowds
  yet); MW-3/MW-4's crowd can join the condition.~~ Done in loop MW-3: E10 needs Plan C's crowd
  out (`crowd: plan_c`), E14 the steps at 0.8.
- **Hocki Bloki's music rise (E09) and the fountain show (E17)** are not built: the egg finds
  and pays, the show itself is a later visual.
- **Kadr k06 wants a morning**: the fixed looks have no morning (Day is 14:00); it takes Day
  until MW-3's Dawn look. (Loop MW-3 built Świt · Dawn; k06's `look` in `kadr.json` is the
  designer's to switch to `Dawn`: not changed, existing data.)
- **Sharing a photo** waits for the Share plugin (its own yes); the photos stay in `user://photos/`
  (no cap on their number yet: a cap or a gallery is a later item).
- **Spacer's hint arrow** reuses the job target arrow; while a job's or rescue's arrow shows, that arrow wins and the hint's 15 s run out unseen.
- **The --egg rig** teleports the vehicle along its path (laps, streets, circles) at 90 % of the
  limit: it proves the trigger, not that a player can drive it in traffic. Phone check.

## From loop MW-3 (the night and the river, 2026-10-30)

- Done: the Dawn look (`--time=dawn`, Settings → TIME's Świt) and `--clock` on the fixed looks;
  the queues at the five clubs and the door (rejections, the car line); the dawn crowd (20-40
  walkers on footway routes, the `dawn_crowd` bubble, Podwózka's `club` requests at dawn); the
  steps crowd and the guitarist with their two sounds; Plac Zbawiciela's summer crowd; the
  police parked by Lusterko and Smoła; eggs E03 E04 E15 woken, E10 E14 with their crowd
  conditions (29 reachable, 16 waiting); `check_crowds` (verify step `crowds`, quick and CI);
  `--crowd=`, `--night-log`, `--club=` (DEVELOPMENT.md "The night and the river").
- ~~**Night buses at Centralny (vision 3.5) not built**: `traffic.gd` (driving lane) has no way to
  gather its buses at a stop or give one an N route and sign within a one-line hook. Needs a
  small traffic API (`spawn_bus(route, sign)` or a bus "layover" mode) from the driving lane;
  then E23 and E25 only need their triggers (drop `waits`).~~ Done in the night-buses loop
  (`buses.gd`; traffic.gd `send_to_stop`, `add_bus`, `let_go`, `night_sign`; "From the night
  buses loop").
- ~~**E01 and `car_black`** wait for the garage's paint (the car line fires; the black car's line
  and the egg need a paint the player chose).~~ Done in the garage loop ("From the garage loop").
- ~~**Level 26's roof crowd**: the roof grid (`map.roof_height`) has nothing over 40 m at
  level_26's resolved point, so no roof crowd is built.~~ Done (F's asks, 2026-10-30): the hint
  was 520 m west of the tower; `near` now on it.
- **A real sitting pose**: sitters are a lower, longer instance of the standing figure (y × 0.6,
  z × 1.35), legs still. A bent-knees pose needs `actor.gdshader` (visuals lane) or a second mesh
  (+1 draw call at the steps). Open Question of the loop.
- **Smoła's queue anchor**: the notebook resolves Smoła at its address 359 m from the places.json
  hint (MW-1's note), so its queue and door stand at (-156, 156) by the Palm's side of Smolna.
  The bake's anchors (map lane) settle it; the queue follows the place. There the queue stands in
  a passage between two blocks: from `--club=smola`'s spot the block hides it (seen through the
  occlusion dither from the north: `--at=-150,150 --yaw=180 --size=50`).
- **Not built from vision 4.5**: the bouncer's sunglasses band, the rejected one walking off down
  the street (they rejoin the queue's end or vanish "for a kebab"), the queue shuffling forward
  between admissions, the club door's light. Small visuals for a later pass.
- **The fixed looks' clock still runs in real time** and the look doesn't follow it (MW-5's note):
  a Night run's queues follow the clock from 01:00 on, but the sky stays Night after 05:00.
  Making the look follow the clock is the visuals lane's call.
- **Curves that are guesses**: Plan C's hour curve (vision gives only "up to 40, Fri/Sat
  21:00-02:00"), the dawn crowd's (20 at the window's edges, 40 at 06-07), the weekday factors,
  the guitarist's 16:00-01:00 and rain's 0.1 on the steps and Plan C. Tune on the phone.
- **The steps' rows** face the river along the shore's normal found from the water distance; in
  the dusk shots the 80 read as a scattered crowd on the boulevard by the water, not as rows on
  the steps (the map has no steps mesh there yet). Check on the phone; a landmarks-lane steps
  model would give them seats.
- **The police by the clubs**: when their window ends at 08:00 the parked car is dismissed (it
  drives off as a patrol). Their `police_club` lines go to a slow car within 15 m; they never
  start a chase and the trap's koguty rules don't apply to them.
- **Phone check**: the queue figures at 80 m are 2-3 image pixels wide; whether a queue of 24
  reads as a queue (and the dawn walkers as a crowd) only the phone shows.

## From loop MW-4 (everyday life and trends, 2026-10-30)

- Done: dog walkers (three dogs, the trees, the horn's bark and line), the influencer dog and
  E16's ball; cyclists (commuters, Rowerilo, cargo) on the cycle paths, the dock, the bell at a
  car parked on a cycle path; runners, KOLKA on Wednesdays and the Zając; Hyrax on Saturdays
  and Podwózka's `hurry` riders; the Wiralek cycle (three slots, queues, fascias), the "Na
  czasie" job, Fat Thursday's queue; eight procedural sounds; eggs E16 E18 E19 E27 E28 E29 E30
  woken (the `event` kind), E20 with the `lukrownia` crowd (36 reachable, 9 waiting);
  `check_city_life` (verify `life`, quick and CI) and the `life-soak` run; `--life=`,
  `--dogs-log`, `--trend-log`, `--life-log`, `--zajac`, `--trend-day=`, `--trend-job`,
  `--life-soak` (DEVELOPMENT.md "Everyday life and trends").
- ~~**The player has no horn** (vision's horn reactions, E24): the dogs bark at the AI cars' horns
  (`traffic.gd` signals, connected in `main.gd`). A horn button (the driving lane: a HUD
  control and `car.gd` / `sfx.horn`) then needs one line: `life.horn(car.global_position)`.~~
  Done in the night-buses loop: the HUD's horn left of the brake and B (`buses.gd` `honk`, no
  `car.gd` change).
- **No Rowerilo docks in the map data**: the bake has no `amenity=bicycle_rental` POIs, so the
  only dock is the `rowerilo_dock` place (9 bikes). Map lane: bake the docks as POIs (kind
  `bike_dock`) and `city_life.gd` `_place_fixed` can put a row at each.
- **E28's "to a dock"** is simplified to "follow a Rowerilo rider 400 m" (the rider then docks
  off screen): with docks in the data the rider could ride to the nearest one. Open Question.
- ~~**No rider MultiMesh to share** (MW-2's Pędzik riders aren't built): the bikes are their own
  MultiMesh (+1 draw call in view). When Pędzik lands, its riders can join it (a fourth bike
  shape) or the reverse.~~ MW-2: the bike family already holds its four morph shapes (commuter,
  Rowerilo, cargo, parked), so Pędzik has its own MultiMesh (+1 in view, "From loop MW-2").
- **PixelLab pictograms on the Wiralek fascias** (vision 3.4's table: a croissant cube, a cracked
  chocolate bar, …): PixelLab wasn't available this loop; the fascia shows the word only. Eight
  pictograms, then a textured quad beside the word (+0 draws if in the fascia's mesh).
- ~~**The armchair man (E34)** isn't built: the dogs' MultiMesh has no spare shape and a chair
  prop on a guest needs a fifth shape or its own mesh. Small; MW-2 or a later life pass.~~ Done in
  loop jobs-2: a guest with the chair as its own small mesh (+1 near him).
- **No running stride**: runners, Kolka and Hyrax use the walking legs (`actor.gdshader`'s `walk`;
  visuals lane). Waiting walkers and the still photographers swing their legs too (guests share
  the walkers' material); a `walk` per instance would need the shader.
- **Not built from vision 3.4 / 3.7**: one queuer in five holding a phone up (a pose), the pigeon
  on days 6-7, the influencer at the window, the courier with the square backpack, MERDAK pet
  shops (no `shop=pet` anchors in places.json), scooters (Leżak, MW-2), the cargo bike's child
  laughing and the Hyrax finish's whistle (sounds), the traffic behind honking at the Zając
  (one car horn plays instead).
- **Kolka's start**: the `kolka_start` place's pin resolves about 490 m from the boulevard (by
  the projection; in the water by the tow's test) and the footway A* from it detours north; the
  club gathers at the route's last point within 500 m of the pin (on the boulevard), 1,261 m
  from Most Poniatowskiego. Map lane: the bake's anchors (like E09's bridge pin).
- **The clock is the wall clock** (MW-3/MW-5's note): in a headless run with `--fixed-fps` the
  game runs faster than the clock, so Kolka (and every clocked thing) moves at real time while
  the car moves at game time. `--zajac --autopilot` therefore needs about 4 minutes of real time
  to pay. A game-time clock is the visuals/time lane's call.
- **Hyrax and Kolka need Live** (or `--zajac`): a fixed look is always Friday (Saturday before
  noon), so Kolka never runs and Hyrax only before 12:00 in a fixed Day look started in the
  morning (`--clock=10:00`). Open Question.
- **Guesses to tune on the phone**: the dog and rider counts, the rider mix, 3 m/s runners,
  the Hyrax ring (26 m, 24 barriers), the fascia's size, the job's tip and late rule, the 240 s
  per-slot offer cooldown.
- ~~**Script cost over budget at the busiest spots**: "city life" 0.08-0.10 ms against 0.05.~~
  Done in the MW-4 cost cut (DEVELOPMENT "Everyday life and trends", Cost): 0.04 ms at Plac
  Zbawiciela 07:30, 0.03-0.04 with Kolka running, 0.02 on the bench route. Left: the phone's
  own number (the performance lane's device bench); full packed arrays for the movers would cut
  the step again if the phone needs it.
- **Phone check**: whether a 120-triangle dog reads at 80 m (2-3 image pixels), the bikes' cream
  and basket, the fascia's word at phone size, the bark and bell levels in the mix.

## From the web build (2026-10-30)

- **Try it in a phone's browser** (iOS Safari, Android Chrome): memory with the ~140 MB pack in
  memory, the touch controls for real, the safe area (`OS.has_feature("mobile")` is false on the
  web, so the HUD uses the desktop layout rules), the frame rate.
- **Smaller download** (web loop 2 did the sectors: 141 → 59 MB at the start). What is left: the
  pack's 40 MB (shared meshes and textures 20, proxies 8.5, index 7.7), the engine's 10.
- **A sector the car reaches before its pack** shows its proxy and has no colliders; on a slow
  link a fast helicopter could outrun the downloads. Not seen in tests.
- **The Compatibility renderer's look**: compare the web against the phone shot for shot
  (night lights, water, shadows); only the green traffic was fixed.
- **Prebuilt MultiMeshes with custom data and no colours** would show the same Compatibility bug
  if a shader reads COLOR; none looked wrong in the browser (trees, parked cars).

## From F's asks (2026-10-30: Frogs, the zones' switch, LEVEL 26, the full-screen map)

- ~~**Frogs' shops** are still words only (MW-2 builds them): the fascia spec is FROGS at a 0.12 m
  letter pixel (parodies.md 2.1); the ids stay `rechotka` / `easter_rechotka`.~~ Built in MW-2.
- **The zones' switch off** also silences the guards' whistle, run and car (only the pill and the
  cap were asked about); the clamp keeps its "in a zone or on a footway" rule. If F wants the
  whistle as flavour with no cap, it is one condition in `guards.gd` `_zone_tick`.
- **LEVEL 26's band** follows the roof grid's 4 m cells (smoothed over five rays, put 0.5 m out),
  so it sits on the facade or up to a few metres out of it; the parapet figures stand 4.6 m in
  from the grid's edge. A tower-top outline from the map lane (the top floor's footprint as a poi
  or in `landmarks`) would put both exactly on the glass. The figures are dark on a dark roof and
  hard to see from the helicopter; a light shirt or two would read better (art direction).
- **LEVEL 26's cost** in view at night is +2 draw calls: the band (+1) and the crowd MultiMesh of
  its 512 m cell (+1, the roof crowd and the door queue; before, the roof crowd was never built
  and the cell stayed hidden). 0 by day and beyond 350 m.
- **The full-screen map** shows the "?" marks the minimap shows (unfound places within 400 m of
  the car), not every unfound place (that would spoil the finding). The 3D view still renders
  under it while open (the game is paused); stopping the view's updates while the map is open
  would save the phone's GPU (performance lane).
- **Android's back gesture**: `full_map.gd` closes on `NOTIFICATION_WM_GO_BACK_REQUEST`, but
  `application/config/quit_on_go_back` is Godot's default (true): check on a phone whether the
  back gesture quits the app first (store-release lane).

## From loop MW-2 (storefronts and parodies, 2026-10-30)

- ~~**What the map lane should bake** (none of it is in `centrum.json`; MW-2 places from addresses
  and the lane graph at runtime, DEVELOPMENT.md "Storefronts and parodies"): `shop=convenience`
  (the Frogs could stand where real corner shops are), `railway=subway_entrance` (the metro
  entrances are put on the pavement round nine station places, not at the real stairs: at
  Centrum one canopy stands over the map's own sunken stairs), `amenity=bicycle_rental` (the
  docks), the `scooter` / `scooter_zone` pois of parodies.md 5.2 (the odd places: grass, bench
  fronts, hedges, 1 in 40 on a shelter roof), and an address for **Kruczkowskiego 3B** (Kasa
  Biletowa resolves to Aleja 3 Maja 7A, the nearest address within 140 m).~~ Baked in the
  content-POIs loop (2026-10-31, DEVELOPMENT.md "Content POIs"): `convenience` 260 (`fr` the
  Frogs' chain, 163), `subway_entrance` 84 (`yaw` the way down, `st` the station), `bicycle_rental`
  92, `scooter_zone` 56 (one `egg`), `scooter` 468 (poses), and Kruczkowskiego 3B with 10 more
  places' addresses (`address` with `v`). **The content lane's switch** is "From the content-POIs
  loop" below. Still open: an outline per facade with its street side would replace the
  sector-load wall rays.
- **What the landmarks lane could add**: nothing blocks. The venue neon sits 0.14 m off the
  collider's face; on a LoD2 facade (no `lod2.*` in this container) the rays meet the LoD2
  walls, untested here. A real shop front (door recess, glass) on the Frogs' walls would beat
  our 5 m fascia box.
- **Wall rays at sector load**: 248 Frogs picked, ~200 find a straight 5.2 m wall with a 5 m
  roof (the rest are skipped: a Frogs needs a wall). The rays run once per sector on the main
  thread (`storefronts.gd` `_physics_process`, ~1-3 ms a sector in the headless run); the phone
  should be checked for a hitch at sector load.
- **Setup** costs ~230 ms at the city's start (headless, desktop): the address and venue lists,
  the shop picks, the Leżak and metro picks, the neon atlas. Could move to a worker thread.
- **Not built (cheap later)**: ~~Pędzik on the road's kerb edge (they ride the cycle paths and
  footways only), the 1-2 couriers waiting at each kebab stand at night, the hop over a car~~
  (done in loop couriers: "From loop couriers"),
  ~~**the courier race** (parodies.md 4.3), **the Leżak round-up** (5.3: depot, pins, boot of 5)~~
  (done in loop jobs-2: "From loop jobs-2"), Leżaks on shelter roofs.
- **PixelLab pictograms** (parodies.md 6.2 / 9): the ten billboards are text only (the five new
  ones: FROGS · TU TEŻ, PODWÓZKA · GPS WIE LEPIEJ, PĘDZIK, LEŻAK, WIRALEK); a frog, a pin, a
  backpack, a scooter and a phone pictogram each would be a textured quad beside the word.
- **Two older `kebab_order` lines** are over the Polish bubbles' 70 characters (72 and 75:
  "Zamówienie dla pana Krzysztofa…", "Powiśle, kamienica bez windy…"); `check_parodies` lists them
  as known. A designer's trim.
- **An older column poster** "CISZA NOCNA 3:00–3:05" has an en dash the pixel font lacks (it
  draws a gap); a `–` glyph in `pixel_font.gd` or a hyphen in the line.
- **Stamp reach** is 8 m from the door point (parodies.md 2.4 says 6): the door point is 1 m out
  from the wall and a car on the near lane stops a pavement's width plus half a lane away
  (`--rechotka` stops 6.4 m from Krucza 51's door). Open Question in the MW-2 report.
- **The metro M** is a cream M on a navy square: generic, no operator's logo; at the default
  view it is a few pixels. The art director may want it bigger or red.

## From the content-POIs loop (map lane, 2026-10-31)

- **check_streaming's `look` pass depends on the Mac's frame rate** (found 2026-10-31): the look
  waits `LOOK_WAIT_MS` (1.5 s) of wall-clock time while the sectors load a slice a frame, so on a
  busy Mac whose frames ran at 16.7 ms (the iOS Simulator of another project running) s_-6_0 was
  still loading when the camera arrived (24 frames over 5 %, frame 1338); at 8.4 ms and 1.5 ms
  frames the same code passed. Fix (map lane): wait in frames, or run the pass on a frame budget
  that doesn't change with the machine; the iPhone 11's 60 Hz is the case that counts.

- **The content lane's switch** (storefronts.gd, roundup_job.gd, props.gd; none of it built):
  the Leżaks from the `scooter` pois (`p` the pose: `lie` on its side as today; `stand` upright;
  `roof` at `h` 2.6 m over the ground; `grass`, `bench`, `hedge`, `frogs` lie like `lie`) instead
  of `_pick_scooters`, the zones' paint from `scooter_zone` (3 m along `yaw`), the standing one
  and `easter_lezak` from the zone with `egg`; the round-up's depots at zones as today. The metro
  canopies at the `subway_entrance` pois facing `yaw` (skip `u`: underground passages), with
  `st` instead of the nine notebook places. The Frogs from the `convenience` pois with `fr` (their
  `door` is the road point, `x, z` the shop: the wall rays still find the facade), the other
  `convenience` free for other parody shops. Bike docks (`bicycle_rental`, `yaw`, `l`) for a rack
  row of parody bikes. Today's runtime picks fail the bake's rules often (`tools/check_pois.py
  --points=`: 108 of 277 Leżaks on a carriageway, crossing, kerb ramp or something solid, 14 of 25
  metro canopies), so the switch also fixes those.
- **`address` with `v`** (11): places' addresses the job pool didn't have; `jobs.gd` and `rides.gd`
  take every `address`, so their shuffles changed (the kebab run's order 0 is now 1,266 m by road:
  verify `kebab` 15000 → 21000 frames). Skipping `v` in the two jobs gives back the old picks
  (gameplay lane), if wanted.
- **Hala Gwardii's address** (Plac Żelaznej Bramy 1) is in no OSM element: the notebook keeps
  its hint.
- `check_pois.py` isn't in CI (`.github/workflows/verify.yml`): it reads only centrum.json (and
  lod2.json and the OSM export when they are there), so it could join the CI list.

## From loop jobs-2 (the courier race, the Leżak round-up, the payphone, the armchair man, 2026-10-31)

- Done: the courier race (`courier_race.gd`, parodies.md 4.3), the Leżak round-up
  (`roundup_job.gd`, 5.3), the payphone at Plac Konstytucji (E40) and the armchair man on
  Mokotowska (E34): 40 eggs reachable, 7 waiting. `check_side_jobs` (verify `jobs2`, quick and CI);
  `--courier-race[=N]`, `--courier-v=`, `--roundup`, `--armchair` (DEVELOPMENT.md "The courier race,
  the round-up, the payphone and the armchair man").
- ~~**The courier rarely wins in play**: on today's map the footway network follows the streets, so
  his way is about as long as the road (stand 0 → Oboźna 1: 1,013 m against 1,023 m); at 6.5 m/s
  a player driving at 30-50 km/h beats him by a minute. parodies.md's "25 % shorter" needs park and
  courtyard paths the bake doesn't have, or a faster rider. The autopilot (the job's ghost: 222 s
  for 1 km with the lights) loses. Tune on the phone (Open Question: speed).~~ Loop couriers: his pace
  is the order's road at 10 m/s (6.5-11 m/s), a decent drive wins about 2 in 3 ("From loop couriers").
- ~~**The courier appears when he challenges**: parodies.md 4.2's 1-2 couriers waiting at each stand
  at night are still not built, so the challenger is drawn by the kiosk only from the challenge.~~
  Loop couriers: the challenger is one of the couriers waiting there.
- **The round-up follows parodies.md 5.3** (collect into a boot of 5, unload at the depot), not
  pushing scooters into the zone with the knock: the brief's wording; Open Question.
- **Leżaks round a depot are picked up and unloaded at once** (the zone's 2-3 lie within the 7 m
  ring): a free one or two to start. Kept (the zone's joke works: they lie round the zone).
- **A fixed Night look keeps collected Leżaks gone** for the session (they come back when the
  look leaves night: Live's morning, or a switch to Day); a session restart brings them back.
- **The autopilot round-up slides through buildings** (as the trend job's): it proves the flow,
  not that a player can reach each Leżak; some lie on footways behind railings. Phone check.
- **T17 isn't a KASETA then card**: the 20-card set covers 2010 to today and its words are the
  designer's; E40's card carries T17's line ("Karta na 25 impulsów…") and +10. A 21st then card
  (a payphone ghost, a year such as 2010) is the designer's call (Open Question).
- **The armchair man's hours** are the shops' (08-20) and his days the trend cycle's day number
  (Live's date, else the session's), so a fixed look sees him in 1 session in 3. No line of his
  own (vision quotes none); E34's card line only.
- **The payphone** stands where the pavement test finds room nearest Plac Konstytucji's point
  (32 m off its point); the real square has none today. Its look is the art
  director's to judge (no operator colours on purpose).
- **The kebab order's distance can be half the drive**: jobs.gd measures "1,023 m by road" from
  the stand's nearest lane, which can be the other carriageway; the car starting the other way
  drove about 2.3 km to Oboźna 1 (the race's gap read 2,292 m at 20 s, honest, the car's own
  lane). The race reads the car's lane, so it can say 2ND at the start of an order the card calls
  short. Snapping the stand by the car's heading in `_make_kebab_order` would fix the card.

## From loop couriers (Pędzik at the kebab stands and on the road, 2026-10-31)

- Done: 1-2 couriers waiting by each kebab stand at night (the race's challenger is one of them),
  3 / 5 kerb riders (day / night) on the roads' kerb edge, the swerve onto the footway or the hop,
  the near miss's line, the courier race's pace; `check_couriers` (verify `couriers`, quick and CI),
  `--pedzik-log`, `--pedzik-kerb` (DEVELOPMENT.md "The Pędzik couriers at the stands and on the kerb").
- **The race's pace is a model, not a measurement**: a decent player is taken as 30-50 km/h door to
  door (BACKLOG's own range above); the rider's time is the road's at 10 m/s, so such a player wins
  2 in 3. On the default route the rider rides 9.9 m/s (36 km/h, 102 s for 1,015 m). Nobody has
  timed real players: count wins on the phone (`courier:` lines) and move `CourierRace.V_ROAD`
  (Open Question). The shortcut through courtyards needs footways the bake doesn't have (map lane).
- **The kerb line is 0.45 m in, not parodies.md's 0.6 m**: a traffic car's side is 0.63 m from the
  kerb on a 3 m lane, so at 0.6 m the AI cars on the kerb lane would pass through the rider's
  handlebars. The AI traffic doesn't see the riders (a bus pulling in at a stop, or a car on a
  narrower 2.9-3 m lane, can still brush one); lanes under 2.9 m and living streets have none.
- **The waiting couriers stand still**: the car driven onto the pavement at a stand passes through
  them (they are not movers; the riders and walkers step aside). Small; a shove like the walkers'.
- **"He gets on his bike"** is a cut: at ŚCIGAJ the standing instance in the Pedzik MultiMesh goes
  and the race's own rider (riding) appears on his spot; no mounting animation. The race's rider is
  still its own MeshInstance3D (+1 draw call while a race is in view, as in jobs-2); folding it into
  the Pedzik MultiMesh would make that +0.
- **Hops are rare**: a kerb rider hops only where the footway past the kerb is a roof, another road
  or a bridge (its railing); elsewhere he swerves. The phone should say whether a hop reads at all
  (0.3 s, 0.55 m up, at the movers' 15 Hz step: ~5 frames).
- **`--courier-race` at night by a stand with nobody waiting** still draws the rider at the kiosk (forced);
  unforced, no courier waiting means no challenge (parodies.md 4.3).

## From the night buses loop (the N sign, Centralny's ring, the bus stops, the horn, 2026-10-31)

- Done: the N sign 22:30-05:00 (the BUS MultiMesh's mesh swapped, +0 draw calls), the night hub
  at Dworzec Centralny (a ring of 5-8 every half hour, 22:30-04:30, recruited from the traffic's
  buses), waiting figures at the bus stops by day and a `bus_stop` bubble, the player's horn (the
  HUD button left of the brake, B on the Mac), E23 E24 E25: 43 eggs reachable, 4 waiting.
  `check_buses` (verify `buses`, quick and CI); `--night-hub`, `--bus-log`, `--honk=`
  (DEVELOPMENT.md "The night buses, the bus stops and the horn").
- **Map lane: the shelters aren't in the index**: `tools/bake_sectors.py` keeps `shelters` sector-only
  (SECTOR_ONLY), so `buses.gd` learns a sector's stops when it loads. It reads the sector's
  `sectors/i_j.json` where that exists (the editor, the Mac), else the shelter MultiMesh's
  instance transforms (the exported game: a GPU read-back once per sector load, tested on
  software Vulkan, not on the phone). Moving `shelters` (points only) into `index.json` /
  `index.res` would give every stop at start, with no read-back.
- **Map lane: no `highway=bus_stop` / `public_transport=platform` data of its own**: the stops are
  the shelters that stand right of a bus road's kerb lane (188 of 351). A stop without a
  shelter has no figures; a shelter on a side street has none either. Baking the stop points
  (with their `name` and `route_ref` if wanted) would make the stops exact.
- **Map lane: Centralny has no bus loop or bays in the lane graph**: the ring stands in two
  rows of 4 at the kerb lanes of Aleje Jerozolimskie by the station's shelters (`HUB_ROWS`), about
  1 m over the kerb line (BAY_PULL), not in real bays. A bay or layover lane on both
  carriageways (or the real Dworzec Centralny stops' platforms) would let them pull off the road.
- **The horn is B, not H**: H was already the car ↔ helicopter key. Open Question.
- **E24's line**: vision 3.5 says "line 3", eggs.json's `line_ref` says index 2: the same line
  (the third, "Stoję na przystanku na żądanie. Żądam."), the request line; built that way.
- **A stop's own bubble can say the request line**: `dialogue.gd` picks a `bus_stop` line at
  random, so the waiting figure can say "Stoję na przystanku na żądanie…" without a honk. Harmless,
  but a `kind` to keep the request line for E24 would be the designer's call.
- **E25 has no race card**: the race starts quietly when a bus leaves the eastbound row with the
  car at the ring, and `--bus-log` is the only place that says so. A status pill ("WYŚCIG Z NOCNYM ·
  RACE THE NIGHT BUS") is the designer's call (vision gives none).
- **A bus on a route never chances a red**: `traffic.gd` lets a driver on a route (the rivals' races)
  run 60 % of reds; a bus routed to a stop, the hub or the Palm doesn't (E25 would be unfair, and a
  bus jumping a red reads wrong). Rivals are unchanged.
- **Stop figures swing their legs a little** (the walkers' MultiMesh, the trap officers' trick):
  standing figures in the walkers' buffer share their `walk` value. A per-instance stand flag is
  the visuals lane's (actor.gdshader), if it shows on the phone.
- **The prebuilt city in this container was stale** (`check_map_data.py`: the sector files and
  prebuilt sectors from another bake): the `prebuilt` step logged 1,647 `_fill_height` errors on
  main too. A scratch copy re-split and rebuilt with a renderer ran with 0 errors.
  `tools/setup_map.sh --if-needed` fixes it in place (map lane).

## From the vintage-tram loop (the old two-car set, E39, 2026-10-31)

- Done: the old set (a rounded 1960s-style motor car and trailer, red and cream, our own shape) on
  the trams' tracks, one of the eight trams recruited out of sight (its meshes swapped, the third
  car hidden: -1 draw call in view); Saturdays and Sundays 09:00-19:00 (Live: June-September), one
  25-min run an hour; its creak and its own bell; E39 (300 m followed within 40 m, +30, the egg's
  line over the tram): 44 eggs reachable, 3 waiting. `check_old_tram` (verify `oldtram`, quick and
  CI); `--old-tram[=follow]`, `--tram-log` (DEVELOPMENT.md "The vintage tram and E39").
- **T13 waits**: vision's E39 reward names the then card T13 (the rounded 1960s tram and the boxy
  1970s one), but the then cards start in 2010 (QUESTIONS, answered 2026-10-30): E39 gives +30
  and its line only. When the older decades come (with T1), T13 can be added to
  `then_cards.json` and to E39's reward (`"then": "t13_..."`).
- **Without Live the set is rare**: the fixed looks' clock is "always Friday" (Day 14:00), so the
  set runs only on the game's Saturday: Dawn's clock after 09:00 (3+ hours of play) or the Day look
  from `--clock=` before noon. Open Question: also run it in the plain Day look (e.g. one run an
  hour whatever the day) so that E39 is findable without Live? Built as the brief says.
- **The hours are a guess**: 09:00-19:00, one run an hour starting in the first half hour, 25 min
  each; the set at 29 km/h. Tune with F on the phone.
- **No boxy 1970s set**: vision's T13 pairs the rounded tram with a boxy 1970s one; only the
  rounded one runs. A second look (a 105N-like boxy set) is a mesh swap away if wanted.
- **The rails don't change**: it runs the modern trams' pieces, stops and lights; no heritage
  route (Warsaw's tourist line T) of its own. A route would need the map lane's track pieces
  named by line.
- **Night**: it runs by day only, so its hidden third car's tail glow isn't missed; with
  `--old-tram` at night the trailer shows its tail lamps but no red glow on the rails.

## From the garage loop (Warsztat u Mirka and the paint jobs, 2026-10-31)

- Done: the garage on Brzeska in Praga (a dashed blue ring, a diamond on the minimap and the full
  map; shown after the first earnings, a toast the first time), the paint card (pauses the game;
  8 paints: factory red free, cream 150, pea green 180, blue 200, yellow 250, black 300, pink 350,
  gold free at 5 egg cards), owned paints kept and switched free, saved in `[garage]`; `car.gd`
  `set_paint`; Mirek's lines (dialogue.json `garage`); E01 (black at Lusterko's door, Fri/Sat
  23-06, +50, `car_black`) and E21 (green, 2 s at Glon, +15): 46 eggs reachable, 1 waiting (E35).
  `check_garage` (verify `garage`, quick and CI); `check_hud` lays the card out; `--paint=`,
  `--garage[=ring]`, `--garage-log` (DEVELOPMENT.md "The garage").
- **The 3 cars** (DEMO 6.3: the hatchback, a boxy estate and a tiny 1970s-style city car, invented
  shapes) are not built: a later loop (models.gd's shapes, the card's second row, their feel in
  car.gd: driving lane).
- **The horn tune** (DEMO 6.3: collectibles unlock a horn tune) is not built: a later item with
  the horn's sound (buses.gd's horn button).
- **No sign on the workshop**: the venue neon fascias (storefronts.gd) come from places.json
  places; a "WARSZTAT" sign needs a place (or a sign hook of its own) and the letters in the neon
  atlas. Until then the ring and the diamond mark it.
- **Prices are a guess** (150-350 zł, black 300; the gold one at 5 egg cards): tune with F on the
  phone against how fast the złoty come in the first 15 minutes.
- **The unlock is "after the first earnings"**, not the beat's clock (10:00 of play): with the demo
  script's first order at 0:30 it shows within the first minute. Open Question for the designer.
- **The bouncer's `car` lines name a red hatchback** ("Czerwony hatchback. Dziś wchodzi tylko
  czerń.") whatever the paint: with another non-black paint it is a white lie. A `car_red` tag (the
  designer's words) would fix it.
- **Brzeska is one-way and narrow** (3 m, one lane): the ring covers the street; a car coming the
  other way still drives in. The workshop could move to a wider kerb (map lane: a service way's
  mouth on Brzeska) if F finds it awkward.

## From loop 3h slice 1 (save v2 and the districts, 2026-10-31)

Closed: save v2 (a version, the v1 migration and backup, settings' version), districts as data with
discovery, "?" marks and completion on the full map (DEMO G3). Left for the later 3h slices:
- ~~**Syrenki** (slice 2): 20 collectibles; register each with `districts.gd` `add_syrenka(id,
  district)` and mark finds in `wallet.syrenki` (saved already); then they count in completion.~~
  Done in slice 2 (see below).
- ~~**Rival ladder and "Trzy mosty"**~~ (done in slice 3, see below), ~~**the first 10 minutes** (the
  hint finger, the first order, the first race, the `--first10` replay check), **the end card** (can
  read `percent_total()` and the discovered count)~~ (done in slice 4, see below; the end card doesn't
  show the districts' %).
- Ujazdów i Łazienki has no notebook place or egg (the park lies south of the map; only the Sejm is
  in it): completion there is its 2 jobs, and it shows no "?" marks. The designer (places for the
  Sejm, Ujazdowski Castle, Plac na Rozdrożu) or the map lane (the park) would fill it. Wola has 2
  places, Stare Miasto 4: thin for "3 ?" for long.
- The notebook's place card doesn't show the place's district yet (notebook_page.gd).
- Jobs done before save v2 have no district (v1 counted jobs by kind only): they don't count
  towards any district.
- The district polygons are hand-drawn from the stale water data and the embankment roads; the
  river line north of Most Śląsko-Dąbrowski is extrapolated (the map lane could bake a river line).
- The discovery card uses the note card (5.5 s); a bigger centred card or a sound of its own
  (loop 3i's district ambiences) would make it a moment.

## From loop 3h slice 2 (the 20 Syrenki, 2026-10-31)

Closed: the Syrenki (syrenki.gd: 20 figurines by the kerb, the find, the reward ladder, the paints
"Łuska Syreny" and "Srebro Syreny", the "Syrenki n/20" line on the full map). Left:
- No hint for the Syrenki: no "?" marks, no minimap dot, no radar. A player finds them by chance or
  by a guide. A counter in the pause card or the notebook, and a sound of their own near one
  (a chime under ~40 m), would help; the designer decides how much to give away.
- The words in `data/syrenki.json` were written in this slice: the game-designer should review them.
- The figurine is `Props.mermaid()` scaled to 3 m with a cyan diamond over her (it read badly at
  1.7 m): check it on the phone; a dedicated figurine mesh (props.gd, another thread's file) and a
  slow spin or bob for the diamond (a shader: the visuals lane) would read better still.
- Placed by rule, not by eye: look at each on the street (the kerb side, trees, benches, a
  building's wall in a narrow street); `--syrenka=<id>` puts the car in front of one.
- No Syrenka on a bridge or in a tunnel (ground streets only); the real statue on the Old Town
  Market Square stands on the street ring, not in the square itself.
- The reward cards queue in `syrenki.gd`; the HUD's note card shows one at a time (a find while
  another card is up waits for it).
- Garage card: ten paints in two rows of five; on the smallest phone check it still fits.

## From loop 3h slice 3 (the rival ladder and "Trzy mosty", 2026-10-31)

Closed: the rival ladder (ladder.gd: six rungs in order of stake, opened by the rung before and by
respect 0/100/250/400/600/850, the locked prompt and the refusal lines, a pace per rival, the toast
for a new rung, the DRABINKA card on the full map, the save's `[ladder]`) and the final "Trzy mosty"
(trzy_mosty.gd: Rondo Daszyńskiego east over Śląsko-Dąbrowski, west over Świętokrzyski, east over
Poniatowskiego to the stadium; at night; three ordered checkpoints; +500 zł +250 respect;
`trzy_mosty` saved for the end card). Left:
- ~~**Slice 4: the first 10 minutes** (the hint finger after 4 s, the guaranteed first order past the
  Rotunda, the first race at 800 m to the Palm with Seba losing narrowly, the Powiśle card at ~8:00,
  the `--first10` replay check) and **the end card** (win "Trzy mosty" = `wallet.ladder` has
  `trzy_mosty` / `Ladder.final_won()`, and 10 jobs; "free roam" after). The first race in 6.2 is
  against Seba, but the ladder opens with Halina: slice 4 decides whether the scripted first race is
  Halina (the ladder's first rung) or a Seba race outside the ladder.~~ Done in slice 4 (below): the
  first race is Halina's.
- ~~The paces are guesses (Halina 1.25 … Mike 1.5, the final 1.45): tune on the phone (A-checks: the
  first race is won narrowly by an ordinary player).~~ The first race has its own rubber band now
  (slice 4); the ladder's paces are still guesses for the phone.
- The final is long: 10.1 km by road (3.8 km from Rondo Daszyńskiego to the first bridge alone). The
  autopilot's ghost (pace 1.8) needs about 14.5 minutes of game time with the city's lights and traffic
  (867 s, Seba 30 s behind);
  a player on the phone should judge whether it is an epic or a slog. A shorter cut (a start nearer
  the river, e.g. Rondo ONZ, or one bridge fewer) is one constant in `trzy_mosty.gd`.
- Players with race wins from before the ladder start at rung one (the old wins didn't record the
  rival).
- Seba waits at the start held still: no idle animation, and while he waits he isn't cruising for a
  re-race of his rung (at night only, once the final is open).
- The finish line is a beacon ring, not a set piece: a crowd or a banner by the stands (the stadium is
  the landmarks lane's) would make the end a moment.
- The refusal and final lines were written in this slice: the game-designer should review them.

## From loop 3h slice 4 (the first 10 minutes and the end card, 2026-10-31)

Closed: the guided first 10 minutes (first10.gd: a director on a fresh save, the ghost finger, the
arrow to the Świętokrzyska stand, the guided order past the Rotunda, Pani Halina's first race to the
Palm with a rubber band, the first contact's fallback, the held first call, the helicopter after the
first rescue, the boulevard tape and its song, the Powiśle arrow, the garage at 10:00; the save's
`[intro]`) and the end card ("Dzięki za grę!", free roam after). Left:
- **The opening shot is the other thread's**: the spawn faces south on Marszałkowska while the
  Świętokrzyska stand is ~530 m north of it (behind the car), so 6.2's "ring 150 m ahead" is an arrow
  at 0:10 instead. When the first-scene thread sets the spawn and heading, a spawn facing north (or
  the stand moved, `jobs.FIRST_STAND`) puts the ring on screen at once.
- **Feel on the phone**: the rubber band's numbers (pace 1.15, 25 m, 0.4-1.5) come from a 1-D model;
  F's runs should say whether Halina is close enough to feel like a race and never obviously
  waiting. The ghost finger's place and gesture likewise (it sits on the stick's side, lower left).
- **No "6.2" beat for "two jokes, the roosters explained in one line"** of the trap: the first
  contact's own conversation (police.dialogue) is what plays; the designer could add the koguty line.
- **The cassette is KASETA's then card** on the boulevards (a ground spot, not a roof), and its
  "new song" is the next locked PÓŁNOC FM track (track 3 on a fresh save). A real cassette
  collectible on a roof (DEMO 6.2, 6.3 "10 cassettes") is still to come; then the beat points there.
- The guide's words (`first10.gd` LINES, Halina's FIRST_LINES, the end card) were written in this
  slice: the game-designer should review them.
- The end card counts every paid job kind but races and the courier bonus; DEMO's "10 jobs" might
  mean kebab-style jobs only.
- **The NaN car (unexplained)**: once in ~10 headless replays the player car's position went NaN at
  the first rescue's pickup (~248 s, right as Powiśle was discovered); 20 later replays were clean.
  car.gd `_keep_finite` now puts the car back at its last good transform and logs `car: state not a
  number` (`nan_recoveries`); the replay also fails fast on a NaN. If that line ever shows up in a
  log, its position and velocity are the lead.
- The end card first didn't show at all: its four Polish lines plus English were taller than the
  HUD's room, so the layout left it unplaced. Now two Polish lines (the credits and the repo as one
  shared line) and the English paragraph; a layout assertion in check_end_card would catch it again.
- `first10-run` takes ~5 min in the container (3.4× real time headless); it stays out of `--quick`.
