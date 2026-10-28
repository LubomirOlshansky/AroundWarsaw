# Nocna Warszawa — roadmap to an "AAA indie" Warsaw centre

Written 2026-10-27, after re-reading the Isometric Warsaw write-up
(bedirhanyildirim.com/pixel-art-map-of-warsaw) and comparing it with this game.
The goal: the centre of Warsaw — Śródmieście, Powiśle, the Vistula and the
National Stadium — looking and feeling like a polished indie game, playable on
an iPhone, with driving, a helicopter, and missions.

## Where we are (v0.4)

- Map: 3.55 × 1.78 km, Śródmieście to PGE Narodowy, as a diorama slab.
  1,753 GUGiK LoD2 buildings (real roofs, aerial-photo roof colours, rooftop units),
  2,158 OpenStreetMap extrusions where LoD2 is missing or outdated (Varso), terrain from
  the GUGiK elevation service, the Vistula with sandbars, Most Poniatowskiego with
  girders and piers, 23.5k trees, 4k parked cars, 1.8k lamps, 340 signal poles,
  1.7k benches, 141 advertising columns, 123 shelters, hedges, fences, walls, steps,
  rails in the WKD cutting, platforms, traffic islands, fountains, flowerbeds.
- Look: pixel-art pass (4 styles), depth outlines, per-building facade rhythm, paving,
  asphalt, grass and water textures, baked ground AO, cloud shadows, tree sway.
- Play: one arcade car, follow camera, zoom 30–320 m, minimap, skid marks, haptics.
- Tech: Godot 4.7.2, city prebuilt into `map/city.scn` at export, 128 m tiles for culling,
  ~7.1M vertices total. iPhone build compiles; **never run on a device yet**.

## What still separates us from the reference and from a polished game

| Area | Gap | Why it matters |
| --- | --- | --- |
| Landmarks | Palace of Culture, Złote Tarasy, Rotunda, Kinoteka, Sala Kongresowa, PGE Narodowy, the Poniatowski towers are LoD2 lumps | These are what make it *Warsaw* at a glance; the reference hand-built ~240 |
| Roads | No stop lines, turn arrows, bus lanes, kerb edges, medians; widths guessed from lanes | Roads are most of the screen while driving |
| Life | Nothing moves except the player | A city with no traffic, trams or people reads as a model |
| Gameplay | Free drive only | No reason to play for more than a minute |
| Light | One fixed sun; no time of day, night, or weather | Night Warsaw is the reference's best view and the game's name |
| Water | Flat blue with speckles (v0.9: flowing, depth colour, foam, reflections) | The river is a third of the eastern screen |
| Audio | None (v0.9: engine, tyres, rotor, city, rain, bells, horns) | Feel and polish are half sound |
| Performance | Untested on a phone; 7M vertices resident | Must hold 60 fps on an iPhone 13 and up |

## Versions

### v0.5 — "Something to do" (gameplay)
- Helicopter mode: switch car ↔ helicopter, fly over the city (altitude, banking,
  rotor wash on trees, shadow on the ground, landing pads = flat roofs and open plazas).
- Missions: rescue runs — a person needs help at a real address (roof, riverbank,
  stuck in traffic); fly or drive there within a time limit, pick up, deliver to a
  hospital/helipad. Timer, score, mission card, success/fail screens.
- HUD: mission arrow, distance, timer.
- Acceptance: a mission can be started, completed and failed with both vehicles.

### Identity: Warsaw humour + vaporwave (added 2026-10-27 at the user's request)
The game should feel like a *Nocna Warszawa* vaporwave cassette: neon, pink-purple
dusk, palm trees (the real artificial palm on Rondo de Gaulle'a is in the map), synth
pads, and a lot of local Warsaw jokes told the way locals tell them. Rules: original
art, music and writing only (no copied memes, songs or samples); no real brand logos;
jokes are affectionate, about the city and its stereotypes, never about real private
people. Polish lines with English subtitles.

### v0.6 — "A living city" (traffic + rivals)
- Everything in the traffic section below, plus **street races**: rival drivers cruising
  the city; pull up behind one and flash lights to challenge; race to a landmark by any
  route; rival AI uses the lane graph and cuts corners; win money and reputation.
- Rivals trash-talk in speech bubbles before and after a race.

### v0.65 — "Warsaw jokes and side jobs"
- **Kebab delivery** (the 3 a.m. Warsaw classic): pick up at a kebab stand, deliver
  before it gets cold; the steam icon fades; tips for speed, a sad customer for a cold one.
- **Słoiki run**: Sunday evening, a newcomer ("słoik") needs their mum's jars carried from
  Dworzec Centralny to a rented flat in Powiśle without breaking any (drive smoothly!).
- **Driver dialogue**: passengers and other drivers talk in speech bubbles — Warsaw
  banter, complaints about Rondo Dmowskiego, the eternal Marszałkowska roadworks,
  "Mordor" commuters, the best view of Warsaw being from the Palace "because you can't
  see the Palace".
- **Easter eggs on the map**: the Palma de Gaulle'a (a fitting landmark), pigeons on
  Plac Defilad, orange roadwork barriers that move to a new place every day, Patelnia
  by Metro Centrum, a tiny Syrenka.
- **Radio host** lines between songs (text, later voice).

### v0.7 — "Night & vaporwave"
- Night mode: lit windows, street-lamp pools, car headlights and tail lights, neon on
  shop fronts, the Palace lit up; dusk with a pink-purple sky.
- Vaporwave look: colour grade (magenta/cyan), optional VHS overlay (scanlines, slight
  chroma shift), chrome "NOCNA WARSZAWA" title screen with the palm and a neon grid,
  synth UI sounds.
- Radio: original procedurally generated vaporwave/synthwave loops (slow jazzy 7th
  chords, detuned pads, soft drums, tape wobble), several stations.

### Traffic details (part of v0.6)
- AI cars driving on the OSM lane graph: lanes, one-way, speed limits, traffic lights
  cycling, give-way at junctions, despawn far from the camera, density by road class.
- Trams on the real tracks (Marszałkowska, Jerozolimskie, Świętokrzyska, Most Poniatowskiego),
  Warsaw yellow-red, stopping at the platforms. Later: GTFS timetables.
- Pedestrians as tiny pixel figures on sidewalks and crossings near the camera.
- Acceptance: 60 fps on a Mac at 110 m zoom with traffic; no cars through buildings.

### v0.75 — "Real roads"
- Stop lines at traffic lights, turn arrows near junctions, bus lanes, painted
  cycle lanes, kerb edges (raised curb strips), dual-carriageway medians, guard rails.
- Use OSM `area:highway` road shapes where mapped; `width`/`lanes:forward/backward`.
- Bridges: deck solver with clearance (5 m over roads, 7.5 m over the river).
- Acceptance: Rondo Dmowskiego and the Marszałkowska/Świętokrzyska junction look right.

### v0.8 — "Landmarks"
- Hand-built (procedural, in code) models: Palace of Culture (pinnacles, clock faces,
  gilded spire, the Congress Hall and theatre wings), Złote Tarasy (glass wave roof),
  Rotunda PKO, Varso spire, PGE Narodowy (red-white woven façade, roof needle),
  Most Poniatowskiego gate towers, the Vistula boulevards, Centralna's hyperbolic roof.
- Each replaces its LoD2/OSM lump; tap for a short info card.

### v0.9 — "Water, weather, sound"
- Time of day (real sun for Warsaw) between the day and night modes.
- River: flowing water with depth colour, shore foam, reflections of bridges.
- Weather: rain with wet roads and puddles (reuse skid/AO infrastructure).
- Audio: engine and rotor, tyres, city ambience, trams' bells, UI sounds.

### Agent order
1. v0.5 helicopter + rescue missions — done 2026-10-28
2. v0.6 traffic, trams, pedestrians, rival drivers + street races — done 2026-10-28
3. v0.7 night mode + vaporwave look + generated radio music — done 2026-10-28
4. v0.65 kebab delivery, słoiki run, dialogue system, Warsaw easter eggs — done 2026-10-28
5. v0.75 real roads — done 2026-10-28
6. v0.8 landmarks (Palace of Culture first, then Złote Tarasy, Rotunda, stadium, Palma) — done 2026-10-28
7. v0.9 water/weather/sound polish, then performance and the device pass — done 2026-10-28
   (the device pass itself is the user's: perf overlay and quality are ready)
After that: loop — look at the game, list what looks worst, fix it, repeat.
8. Loop 1: the occlusion ghost's dark stain, the river, the Palm's spot, Varso's floating part,
   the Palace clock, the roadworks, joke posters on the columns — done 2026-10-28
Loop 2 (the user's requests after playing on the iPhone, 2026-10-28):
9. Loop 2a: steering that feels right on the phone (the user: "steering feels strange"; the Follow
   camera turns with the car while the stick points in screen space, so a held stick keeps
   turning), switchable control schemes, a small settings panel (controls, traffic, quality,
   sound), a little less traffic by default with a Traffic option — done 2026-10-28 (the feel on
   the phone itself is the user's to judge)
10. Loop 2b: FPS on the iPhone: profile and cut the per-frame cost, and set the budgets the
    next agents must keep. The first device numbers (the user's iPhone 16 Pro Max, A18 Pro,
    2868×1320, High, 2026-10-28): 16 fps at the default view over the river (62.5 ms, CPU
    process 60.4 ms, 6747 draw calls, 7338 objects, 0.34 M triangles), 14 fps zoomed out
    (7191 draw calls, 0.90 M triangles), 13 fps from the helicopter (7672 draw calls, 1.38 M
    triangles); the frame grows with draw calls (~10 µs each), not triangles. — done 2026-10-28:
    ~6,800 → 124–245 draw calls (the minimap was 6,500 of them; the sun's shadow covered a 2 km
    slab), 60 fps on the phone at all three views with a 60 fps cap (30 as a battery saver), a
    TEST · BENCH card to copy; the budgets the next rounds must keep are in README.md,
    "Performance budgets".
10a. The river is off-limits (the user: the car drives on the water). The car follows the
    terrain height, which over the river is the water surface, and nothing marks water as
    not drivable. Next after 2b. — done 2026-10-28: a whole-map check (`check_water.gd`) found
    807 m of the water's edge open in 45 places (under all four bridges, round 35 fountains) and
    a helicopter that came down on the river and left the car there; now a low granite edge
    round the river, ponds and fountains (0 places, 0 of 631 cars at 91 km/h), no landing on
    the water, and a splash and a tow back to a lane on dry land 1 s later with a line from the
    tow crew (the feel on the phone is the user's to judge).
10b. iOS check: the iOS Simulator can't run Godot's Mobile renderer (it lacks image cube
    arrays), so it can only show layout and touch with the Compatibility renderer. Real
    numbers come from the user's iPhone: the BENCH card from 2b, or, if the user allows it,
    builds installed and launched on the connected phone from the Mac with the console read
    back (`xcrun devicectl`).
10c. A project skill for Godot mobile performance (from Godot's official docs and 2b's
    measured budgets) that every later agent reads before adding anything to the city. Done
    2026-10-28: `.claude/skills/godot-mobile-perf/` (with the project setup), pointing to
    README "Performance budgets".
11. Loop 2c: nicer car models (the player's hatchback and the traffic) that read at the
    default zoom, within 2b's budget (README.md, "Performance budgets": ≤ 3 draw calls and
    3,000 triangles for the player's car, ≤ 800 triangles a traffic model, MultiMesh per kind).
12. Loop 2d: many more local Warsaw jokes, as parodies (no real brand names or logos, the user's
    choice): an invented frog-green 24h corner shop chain on every other corner, app-taxi
    drivers who blindly follow the GPS (and an app-taxi side job with star ratings), delivery
    riders with big square backpacks, e-scooters dumped everywhere, more kebab. Within 2b's
    budget (README.md, "Performance budgets": one MultiMesh per kind per 512 m tile, ≤ 300
    triangles a prop, no shadow under a metre, ~65–90 more draw calls at most).
13. Loop 2e: the HUD at phone size (found in loop 2a: outside the new settings panel the HUD is
    sized in 720-line units, so on an iPhone 13 its buttons are about 24 pt tall and its text
    about 8 pt; Apple's minimum is 44 pt touch targets). Thin the crowded top row while at it.

Asked by the user later on 2026-10-28 (order set by `docs/DEMO.md`, being written):
- **The demo**: "the top indie game", a really good-quality demo from Rondo Daszyńskiego to
  Stadion Narodowy and from Arkadia to Łazienki Królewskie (about four times today's map; the
  downloads need the user's approval first).
- **Overpasses and roads**: "huge problems with the estakady and roads in some places" (e.g. a
  Poniatowski bridge tower standing in the deck's roadway at Wybrzeże Kościuszkowskie).
- **Police**, in the game's tone.
- **Open source**: the MIT licence for the code and the game's own sounds and art (`LICENSE`);
  the map data keeps ODbL / CC BY / GUGiK terms (`CREDITS.md`); public repo AroundWarsaw.
- **PixelLab** (pixel-art generation through its MCP server `pixellab`, added 2026-10-28):
  portraits for dialogue, HUD and minimap icons, signs, posters, UI and store art; how to use it
  is in `.claude/skills/pixellab/SKILL.md` (budget: up to 50 generations a loop without asking;
  the key stays in the user's Claude Code config, never in the repo).
- **Agents and skills** for this project (`CLAUDE.md`, `.claude/agents/`, `.claude/skills/`,
  `docs/WORKFLOW.md`), researched from current practice; being built.
- **Godot add-ons (free only)**: the user approved installing, when those rounds start,
  **Debug Draw** (HardPixel; road and overpass round) and **Dialogue Manager** (Nathan Hoad),
  **Phantom Camera** (Ramokz) and **beehave** (bitbrain) (police round), all MIT from
  store.godotengine.org, each into `game/addons/` with its licence and a line in `CREDITS.md`,
  checked on the phone. Candidates for later, not approved yet: Folder Import Rules (PixelLab
  art), Lente photo mode, In-app Review and Share (release); the Godot Foundation HLOD and
  occlusion-culling demos are references for the bigger map.

**The order from here** is `docs/DEMO.md` section 7 (loops 3a–3k, with 2c, 2d and 2e folded
in). Gaps the orchestrator added on 2026-10-28, so nothing found so far falls through:
- **Backlog sweeps.** BACKLOG.md holds ~90 open items. One sweep after loop 3c and one before
  3j: triage each item (fix, fold into a loop, or drop with a reason), mechanical fixes on
  Sonnet, judgment ones on Opus. Small known ones: `check_landmarks.gd` exits 0 on failure;
  README's two `bake_osm.py` command lines.
- **Haptics on the iPhone** (`Could not vibrate using haptic engine`): rule out the phone's
  settings, then a small iOS plugin with `UIImpactFeedbackGenerator`. Device-gated, Opus.
  With loop 3i (juice) at the latest.
- **2D art with PixelLab**, spread over the loops that need it: HUD and minimap icons in 2e,
  shop signs, posters and billboards in 2d, dialogue portraits (rivals, police, customers,
  the radio host) in 3g/3h, the app icon and store art in 3j. Up to 50 generations a loop.
- **The store page** (with 3j): app icon, App Store screenshots at the 6.9" and 6.1" sizes, a
  short trailer from the game's own camera paths (Phantom Camera), the description in Polish
  and English, the privacy answer ("no data collected"), age rating.
- **Accessibility and comfort** (with 2e and 3i): text size that follows the phone's setting,
  colour choices that read for colour-blind players (police lights, mission markers), reduced
  camera shake and flashing as options, left-handed control layout.
- **Questions waiting for the user**: the river's behaviour (splash and tow by default) comes
  back from loop 10a for a yes. (The column-poster jokes from loop 1 were approved by the user
  on 2026-10-28: keep them as they are.)
- **After the demo**: the inner districts (Śródmieście, Wola, Ochota, Mokotów, Żoliborz,
  Praga-Północ, Praga-Południe, ~122 km²) as an update delivered as background asset packs,
  then the rest of Warsaw (sizes in DEMO.md section 9).

### v1.0 — "Ship it"
- Device pass on iPhones (13 → 17 Pro): 60 fps target, memory under 1.5 GB, load < 4 s.
- Settings (style, controls, sound), onboarding, App Store assets, privacy, credits
  (OSM ODbL, GUGiK CC BY 4.0 for trees, ZTM data terms).

## How the work is run

The way of working (the loop, the agents and their models, definition of done, milestone
gates) is in `docs/WORKFLOW.md` and `CLAUDE.md`; the agents and skills are in `.claude/`. The
checks below run as one command: `tools/verify.sh` (add `--ios` for the export).

One subagent per task, one after another (the project folder is shared, so no two
agents edit at once). Each task brief gives: goal, files, constraints, acceptance,
and how to verify. Every agent must:

- Run the game headless to catch script errors:
  `cd game && godot --headless --path . --quit-after 40`
- Take screenshots and look at them: `godot --path . --resolution 1920x1080 --quit-after 900 -- [options] --shots=N --out=$PWD/../shots`
  (options: `--demo --style=0 --size=M --at=x,z --yaw=deg --fixed --nohud --lines=N`,
  and `--heli --mission=N --autopilot` for the helicopter and missions; see README).
- Keep the iOS export compiling: `tools/export_ios.sh` then
  `xcodebuild -project build/ios/NocnaWarszawa.xcodeproj -scheme NocnaWarszawa -destination 'generic/platform=iOS' CODE_SIGNING_ALLOWED=NO build`.
- Keep both city paths working: the editor builds the city at runtime; exported builds
  load `map/city.scn` (rebuilt by `godot --path game --resolution 320x180 --script res://tools/bake_city.gd`,
  with a renderer: `--headless` drops MultiMesh and texture data). Check every look on both
  (`-- --prebuilt --time=night`).
- Update README.md and this file when behaviour changes.

## Ready-made assets (made in parallel, waiting for their agent)

- `game/audio/radio/*.wav` — three original vaporwave loops from `tools/make_music.py`
  ("Palma de Gaulle'a" 72 BPM, "Rondo Dmowskiego 3 A.M." 80 BPM, "Mordor Mall Muzak" 92 BPM),
  seamless, 22 kHz stereo. Imported as Forward loops (end = full length) with QOA; in use by the
  v0.7 radio.
- `game/data/dialogue.json` — original Polish/English lines (67, grown to 95 in v0.65): radio
  host, kebab stand, orders and reactions, słoiki run, passengers, traffic shouts, joke signs,
  rescues and the hospital, and easter eggs (the Palm, pigeons, the Mermaid, Patelnia, the
  wandering barriers). In use by `dialogue.gd` since v0.65 (`data/*.json` is in the export).

## Progress log

| Date | Version | What landed |
| --- | --- | --- |
| 2026-10-27 | v0.1–v0.4 | Prototype, GUGiK data, details, wider map (see README) |
| 2026-10-28 | v0.5 | Helicopter (H / HELI: stick flight to 35 m/s, ▲▼ height, banking, spinning rotor, blob shadow, rotor wash on trees, solid roofs from a 4 m roof-height grid, lands and gives the car back); rescue missions at real places (92 roofs, 151 streets, 11 riverside spots, 22 parks/squares) delivered to the 2 hospitals in the map, with call card, beacon, edge arrow, minimap dot, timer, score, success/fail; flags `--heli --mission=N --autopilot` |
| 2026-10-28 | v0.6 | Lane graph baked from OSM (`graph` in centrum.json: 964 nodes, 1494 directed edges, right-hand lanes, junction cut-backs, largest strongly connected part, 67 signal controllers from the mapped stop lines, 170 stop lines, 330 lit poles); AI traffic (cars, taxis, vans, city buses; IDM following, junction give-way, red lights, lane change round a stopped player, spawn/despawn out of sight in a band around the view, ~45 on screen, kinematic bodies near the player, stop when hit); signal lamps cycling with Polish red+amber; 8 three-car trams (yellow/red) stopping at platforms and lights, cars give way to them; up to 60 pedestrians with walking legs; 6 rivals with their own cars and Polish/English lines, FLASH LIGHTS (L) challenge, 11 real-place finishes chosen by road distance, Dijkstra rival AI, 3-2-1, beacon/arrow/1ST-2ND HUD, WIN/LOSE cards, respect; reusable speech bubbles (`bubbles.gd`); one activity at a time with missions; flags `--no-traffic --race=N --rival=N --bench`; bench 120 fps (display cap) with life scripts ~1.1 ms/frame |
| 2026-10-28 | v0.7 | Day / Dusk / Night (N, TIME, `--time=`; 1.5 s blend; day untouched: 0.07% of pixels differ by ≤15 levels, on lamp posts and tail lamps) driven by shader globals `lights_on`, `daylight`, `sky_colour`; lit windows (seeded per building, warm/cool/TV, office floors, shop fronts, fascia neon tubes); 361 neon shop signs with generic Polish words in a 5×7 pixel font; street-lamp light map baked by `tools/bake_lights.py` (1,822 lamps + 224 added on bridges, sodium/LED, occluded by buildings) on the ground, lower facades, trees and vehicles; glowing lamp heads and halos; head/tail lamps, road light and lit windows on all vehicles, one spotlight on the player's car, signal-lamp halos, helicopter beacon, strobe and searchlight; floodlit Palace of Culture; dark river with glints; dusk/night split-tone grade, dithered sky with stars, night bloom; VHS overlay (V, `--vhs`) at screen resolution; vaporwave title screen (chrome wordmark, striped sun, Palace skyline, the Palm, neon grid; skipped by test flags, `--notitle`, `--title`); radio with 3 stations + Off (R, `--radio=`), Forward/QOA loops checked seamless, tuning static, now-playing ticker and an `announce()` hook for v0.65; synth UI sounds; keys: skip call moved to K, heli climb/sink to Space/Shift; bench: scripts ~1.0–1.1 ms day and night, GPU (Vulkan, M4 Pro) ~1.85 ms day, 2.0 dusk, 1.7 night |
| 2026-10-28 | trees | Real trees from the GUGiK 2023 laser scan (CC BY 4.0): 12,555 trees from 23 map sheets (the whole map) with their real height, crown radius and crown base replace all OSM trees and park fillers (`tools/bake_trees_gugik.py` → `trees3d` in centrum.json; OSM trees are now only a fallback outside downloaded sheets); ground shade under real crowns; radio frequencies moved off real stations (86,6 RONDO FM, 108,8 MORDOR FM) |
| 2026-10-28 | v0.65 | Wallet in `user://save.cfg` (złoty, respect, jobs done, best times, eggs found; coin and star under the minimap; races pay the rival's stake 60–300 zł, rescues 8% of the score, jobs their fares); kebab delivery from 5 stands (pixel KEBAB board, neon at night; the mapped place in the Powiśle food hall + 4 busy corners, `kebab` pois by position only) to 973 real addresses (`address` pois, "Wspólna 47/49") 400–1500 m by road, across the river up to 2.9 km, heat meter with fading steam instead of a clock, tips by heat, ×1.5 at night, customer bubble at the door; słoiki run from Dworzec Centralny to a flat in Powiśle with 6 jars broken by bumps (closing speed), hard braking and fast corners, passenger chatter; one activity at a time with rescues and races; `dialogue.gd` (95 lines, shuffled per group, situation tags), drivers' shouts when hit or held up, rescue pickup/hospital lines, radio host on the ticker every 60–120 s with English subtitles; easter eggs (the Palm with neon uplight, a pigeon flock that bursts up and lands again, roadworks on a new street every day, the Patelnia crowd, the Mermaid on the boulevard; x/5 card) and 5 joke billboards in a new 5×7 Polish pixel font; bubbles keep clear of each other and of the HUD panels; flags `--kebab=N --sloik[=K] --heat --host-in --barriers --free --reset-save --nosave`, `--autopilot` drives job routes; bench: life scripts 1.0–1.1 ms + jobs/eggs 0.03 ms, GPU (Vulkan) 1.8–2.1 ms day, 1.7 night |
| 2026-10-28 | v0.75 | Real roads (`tools/bake_roads.py`): the 202 mapped carriageway areas (`area:highway`) are the road surface, with the roads' strips hidden under them and the carriageway edges measured either side of the centreline so the lanes (lane graph) and the painted lines sit on the asphalt (checked over the GUGiK orthophoto with the new `tools/overlay_ortho.py`); widths elsewhere from `width`, `lanes:forward/backward`, `lanes` and painted cycle lanes; edge and lane lines, 170 stop lines, 491 turn arrows from `turn:lanes`, bus lanes (line + BUS), painted cycle lanes (line, red surface, bikes), 106 hatched areas (stripes, chevrons); 121 km of 14 cm granite kerbs, raised islands, 137 dual-carriageway medians (grass, or paving with trams); bridge deck solver (5 m over roads/rails/trams, 7.5 m over the river, 6 % ramps; 68 deck pieces in 18 structures incl. the railway bridge and footbridges; the Jana Pawła II viaduct now rises over Jerozolimskie), slabs, outer parapets, piers, 9.6 km of guard rails (bridges + mapped) and the water's edge as colliders; the car keeps to the surface it is on (`drive_height`), trams and pedestrians use their deck (pedestrians walk the bridge footways); 59 signal controllers (lone stop lines join their junction, crossing pairs share a light, signalled roundabout entries alternate with the ring); off-map links join roads leaving the map to roads coming back (the Praga streets are in the connected graph: 909 of 964 nodes); kebab stand on Al. Poniatowskiego opposite PGE Narodowy (across-river orders, now up to 3.6 km by road, from two stands; 7 stands with the Centralna one the 3D-mapped viaduct used to block); flag `--heading`; flat layers cut into ≤ 10 m pieces: 6.13 M vertices (6.19 M in v0.65), build 6 s (8.9 s); bench: scripts 1.0–1.15 ms, GPU (Vulkan) 1.85 ms day, 1.72 night (v0.65 same day: 1.81 / 1.71) |
| 2026-10-28 | v0.8 | Landmarks built in code (`landmarks.gd`) from the real footprints and part heights in centrum.json, replacing their LoD2/OSM lumps (whole LoD2 buildings by their triangle run, OSM outlines and parts by their centre, and their neon signs): the Palace of Culture (base round its courtyards, Congress Hall drum, corner pavilions, annexes, east portico, four corner towers to 67 m, ribbed shaft to 139 m, clock tier with four 6.3 m dials, lantern, patina crown, gilded spire to 237 m, crenellated attics and pinnacles on every tier, still floodlit), Złote Tarasy's glass wave (the eight mapped domes blended into one rolling surface, diamond lattice, gold at night), the Rotunda (glass drum lit from inside, ribbed white roof, oculus), Varso Tower (mapped slabs and spines, crown lantern, mast to 310 m with rings and beacon), Stadion Narodowy (woven red-and-white basket skin from the 72 mapped mast pairs, masts, membrane roof, stands, pitch, the needle on its cables, promenade), Warszawa Centralna (140 m hypar-shell roof on the mapped pillars, glass hall, canopy) and Most Poniatowskiego's four towers; new building-shader materials (UV2.x codes); every model in the helicopter's roof grid (spire cells 236 m) and a landmark grid; tap a landmark for a Polish/English info card (`hud.tapped`, ray through the roof grid, `--tap=X,Y`); screen-space occlusion fade turns walls on the camera's side that cover the car's surroundings into a dithered ghost; the Palm keeps clear of the scanned tree beside it; title skyline Palace redrawn from the model; `tools/check_landmarks.gd` (car walls, roof grid, taps, helicopter stopped at the walls and landing beside, roof rescues) and `tools/overlay_landmarks.py` (orthophoto check); 6.07 M vertices (6.10 M before), bench GPU (Vulkan) 1.79-1.90 ms day, 1.70-1.75 night (1.90 / 1.73 before), scripts 1.03-1.05 ms, worst frame 9.2-9.8 ms |
| 2026-10-28 | v0.9 | Sound, all synthesised by `tools/make_sfx.py` (24 files, 22.05 kHz, mono except the three stereo beds, peaks -3 dBFS, every loop seamless by the numbers and by `tools/check_sfx.gd` decoding across the loop point, Forward/QOA): a tired 1.2 l hatchback engine in three loops crossfaded and pitched by a five-speed box with a dip at each upshift, tyres rolling / hissing when wet / squealing in slides, collisions by strength where the haptics are (thump, hard thump, crash, guard-rail clang), the jars' clink and break, the rotor winding up and down, day and night city beds with birds by day and a rare far siren or dog at night, rain, trams' two-tone bell leaving a stop or at your car, horns from drivers you hold up, the pigeons; buses Music/SFX/Ambience (ambience 4 dB down under the radio), a pool of six positional voices within 85 m, iOS audio session Ambient; `--sound-check` and bench bus meters. Weather (`weather.gd`, RAIN / O / `--weather=`): screen-space rain streaks in three layers, overcast light, wet asphalt and paving with a sky sheen, noise puddles (roads and paving only) with drop rings, screen-space mirror reflections on water and wet streets (every lamp, neon sign, signal and car light as a streak at dusk and night), lamp-light columns from the light map, 22% less grip. The river (`tools/bake_water.py` → `water.bin`, RGBA per 2 m in `city.scn`): depth colour from the shore, a flow map sliding north and turning with the banks, shore foam, sun sparkles, mirrored bridges and shade under the decks, lamp reflections instead of pools at night (backlog fix: no lamp pools under bridge decks), ponds and fountains on the same shader. Live time of day (TIME's fourth mode, `--time=live --clock= --date=`): NOAA sun over Warsaw, looks blended by elevation, real azimuth, pitch 20-55 degrees. Performance overlay (three fingers, P, `--perf`) and Quality Low/Medium/High (render scale, shadows, glow, rain, reflections, traffic, people; `--quality=`). Bench (Vulkan): GPU day 1.82-1.94 ms (1.86-2.12 before), night 1.73-1.82 (1.69), rain night 1.82-2.11, rain day 1.93-2.07; scripts unchanged + 0.02 ms sound; 6.07 M vertices (unchanged) |
| 2026-10-28 | loop 1 | Polish from the screenshots. **Occlusion ghost**: debug renders (`--ghost-debug=1` mask and ellipse print, `=2` full cut, with `--no-ao` and Low quality) showed the dark stain was the ground inside the ghosted footprint at 0.28 from the baked AO and in its own building's shadow, plus every kept wall pixel darkened by the post pass's depth outline (never the clear colour; back faces only with the car inside a footprint); now `ghost.gdshaderinc` (shared by the building, ground and post shaders): a thin ghost (3 pixels in 16 in the core, a soft dithered rim, the region's upper half stretched 1.35 so a tower's top fades out instead of floating), every fragment of the occluder and the inner faces of a cut building dropped, no outlines and dimmed lit windows on what the ghost keeps, the AO split into a buildings and a small-things channel so the ghost lifts only the buildings' shade, a ghosted footprint's sunlight given back by the sun's height (calibrated against a shadowless render: 154.7 vs 159.3 luma); the v0.8 Palace close-up 0.68 → 0.85; ghost/ring luma 0.80 → 0.99 at the spawn, 0.89 → 0.92 following the car, 0.98 → 1.06 Live 08:00, 0.70 → 0.83 behind the Palace (its own shadow lies over the car), Rondo Dmowskiego at night in the rain 1.14 → 1.14. **River**: deeper, a little greyer, low-contrast drift (half again at night), rare small glints, thinner foam; the pink/cyan night glints gone (dark, calm water; the lamps' columns carry it); a bridge shows as a darker band on the water by day. **The Palm** stands where the laser scan found it (`GUGIK_NOT_TREES` in `bake_osm.py`, `palm` in centrum.json; trees3d 75330 → 75324 values, pois 1020, graph kept; AO/lights/water re-baked). **Floating parts** (`map_builder.gd`): 17 found, 5 lowered to the ground (Varso 2's 80-90 m top among them) and 12 tiny spire bits on the west edge left out. **Palace clock**: hands drawn by the building shader from the dials' UVs, set once a minute from Warsaw time (`--clock=` applies; `--lift=` for close-ups). **Roadworks**: 2 m red-and-white barriers (ten, closed fence), 0.75 m cones with a white band, amber lamps blinking at dusk and night with halos. **Joke posters**: 24 of 141 advertising columns, 16 original `column_posters` lines in `dialogue.json` (Polish with English), wrapped round the band in the 5×7 font, read out in a bubble when passing. Vertices 6,070,773 → 6,069,970 (+3,516 runtime props); bench (uncapped this session; the v0.9 copy alongside): Vulkan GPU day 2.40-2.42 → 2.31-2.39 ms, night 2.10-2.23 → 2.08-2.24, rain night 2.30-2.36 → 2.15-2.32; scripts unchanged, side jobs + eggs +0.01 ms |
| 2026-10-28 | loop 2a | Steering on the phone. **Root cause** measured with a new input replay (`tools/check_steering.gd`, real car script and the game's own mapping/camera code on a test ground; `--legacy` runs the old code): the stick points in screen space while the Follow camera turned towards the car's heading, so a held stick's world direction kept turning: held right at 50 km/h the car turned 1151° in 10 s (3.2 circles), 15° off the nose it drifted 155° off in 8 s, pointed back 2.6 circles; also a 4 g swerve at speed (full-lock radius 2.3 / 6.4 / 11.5 m at 20 / 50 / 78 km/h), no turning from a standstill, walls that stopped the car dead (8 %/frame: 93 → 11 km/h in 1 s) and pinned it for good. **Three schemes** (`drive_controls.gd`): **Point** (default; the follow camera holds while the finger is down, eases round 0.6 s after release; gas from the push as a target speed; pointing back brakes then turns; keys point in screen directions), **Classic** (left/right steering strip, GAS + BRAKE pedals, camera turns with the car; A/D/W/S), **Fixed camera**; the helicopter's follow camera also waits while its stick is held. **Car** (`car.gd`): speed-sensitive turning (2.5 / 8.6 / 23.5 m at 20 / 50 / 90 km/h), a pivot from a standstill, 0.08 s input smoothing, point-to-steer rate from the heading error with yaw damping (held 90° right: within 5° in 1.2 s, 0° overshoot; 15°: 0.4 s; back: 1.7 s), walls slide (velocity into a contact taken off, 92 % kept 1 s after a 30° hit at 93 km/h), glancing hits turn along the wall, Point follows a wall it is pointed into, unstick after 1.5 s pinned against something fixed (not a queue), tow back onto the nearest lane if pinned again within 5 s. **View**: default 80 m (110; the car 58 px instead of 43 on 1170 lines), lead smoothed over 0.7 s and capped at a fifth of the view. **Settings** behind a gear in the top left (Esc), the game paused under it: controls, traffic, quality, volume / radio / effects, perf overlay; Polish over English, ≥ 44 pt; `user://settings.cfg` (`settings.gd`, `settings_panel.gd`), `--nosave` untouched (`tools/check_settings.gd`). **Traffic**: Almost empty / Low / Normal (default) / Busy (the old level) = 5 / 9 / 15 / 25 cars on screen at the new view (Busy's target was beyond what the spawner can place, so the levels are set from real counts), scripts 0.28 / 0.35 / 0.42 / 0.63 ms; pedestrians 27 / 39 / 48 / 60. Flags `--controls= --traffic= --settings --stick= --pedal= --clicks= --drag=`. Bench (Vulkan, medians of 5 interleaved with the old code): GPU day 2.27 → 2.24 ms, night 2.21 → 2.01; scripts 0.84 → 0.43 ms; like with like (110 m, Busy, Classic) GPU 2.43 / 2.20, scripts 0.83 (noise ±0.3 ms GPU) |
| 2026-10-28 | loop 2b | Frame rate on the iPhone (16 Pro Max, A18 Pro, 2868×1320; the user read 16 / 14 / 13 fps at the default view / zoomed out / helicopter with 6,747–7,672 draw calls). **Measured** with a new `--probe` (and `bench.gd`: frame times with 1 % low, the main thread's phases from the engine's frame signals, draw calls / objects / triangles of the 3D, shadow and 2D passes, scripts by system, memory) at five places by day, night and rain night on the Mac at the phone's resolution, Vulkan `--gpu-profile` for the passes, and on the phone itself (`devicectl`). **Ranked**: (1) the minimap drew every street and park of the map as its own polyline under a `clip_children` clip every frame: 6,536 of 6,770 draw calls (the phone's counters matched); (2) the sun's shadow covered a 2 km slab: Godot ignores the light's max distance for an orthographic camera and the camera's far plane was 1,500 m past the view (shadow pass 126–347 draw calls, 2–4 × the main pass, GPU up to 2.35 ms); (3) one draw call per node (no automatic instancing on Mobile): 128 m tiles × 3 meshes, 256 m tiles × 11 instanced kinds, the player's car as 18 boxes; (4) pedestrians on bridge decks 1.0 ms. Started from the phone (no debugger) the old build ran at 120 Hz in the street views (64 fps, 1 % low 30, from the helicopter); with Metal API validation on, as Xcode's Run has it, it read 18.9 fps: the user's 16 fps was those draw calls × Xcode's per-call cost. **Changes**: the minimap as one mesh built once (1 draw call, looks the same), the camera's far plane 130 m past the lowest ground in view with the shadow sphere held constant through the speed zoom, shadow map 2048 / 1024 (finer texels than 4096 gave), no shadows under a metre tall, 256 m city tiles with the LoD2 buildings in the walls' mesh, 512 m instance tiles, the car as one vertex-coloured mesh + 2 lamp meshes, small props hidden beyond a 170 m view, deck pedestrians' heights sampled once; Medium and Low one pixel step coarser than High, Medium shadows from buildings and trees only; the Xcode scheme's validation and frame capture off (`tools/export_ios.sh`). **Draw calls** at the phone's three views 6,771 / 7,020 / 7,045 → 124 / 191 / 245; on the phone 60 fps (the cap) at all three (1 % low 57.4–57.9), 60 with Metal validation on too (1 % low 58.3), the one-minute TEST · BENCH 60 fps (1 % low 57.0, 60 in every 10 s), the bench route 60 fps (it never finished before: the launcher ate the `--`, so it sat on the title screen). Mac bench (medians of 3 interleaved with the old code): Metal frame 3.61 / 3.58 / 3.55 → 1.54 / 1.56 / 1.85 ms (day / night / rain night), Vulkan GPU 2.31 / 2.00 / 2.11 → 0.85 / 0.80 / 0.87 ms; vertices 6,055,540 (unchanged). **Frame rate**: 60 by default (iOS no longer asks for 120 Hz: `allow_high_refresh_rate` off; the 60 is the display's, which paced better on the phone than `Engine.max_fps`), 30 battery saver in Settings (`fps` in settings.cfg). **TEST · BENCH** on the overlay and in Settings: a minute on the bench route at the current settings, wallet put back and not saved, then a card with COPY and `user://bench_result.txt`; `--bench` / `--probe` end by a time cap and write the file too. The overlay shows the main thread's split and draw calls by pass, twice a second. **Parked car**: a held brake at a standstill reversed the car the game had parked while flying or on the title screen into a wall (99 "pinned" lines in the heli mission run); it now holds still and never counts as pinned (0 lines; the steering replay passes). Budgets for 2c / 2d: README.md "Performance budgets". Flags `--probe --bench-frames= --bench-seconds= --bench-button --fps= --exp=` |
| 2026-10-28 | infra | Claude Code setup for the project: `CLAUDE.md`, `docs/WORKFLOW.md`, 7 agents (gameplay-dev, map-engineer, perf-engineer, game-designer, art-director on Opus; qa-tester on Sonnet; scout on Haiku) with a three-tier model policy (Opus decides, Sonnet applies, Haiku looks up; escalate a failed cheaper run one tier up), 8 skills (verify-game, screenshot-review + art bible, bake-map, godot-mobile-perf, warsaw-tone, loop-brief, device-run, pixellab); `tools/verify.sh` (13 steps, all PASS, ~80 s; `--ios` adds the export and Xcode build), `tools/shots.sh`, `tools/device_run.sh`, `tools/check_map_data.py`, and the guard hook `tools/hooks/guard_godot.py` (on: blocks game runs without `--nosave` or a quit flag, and a headless city.scn bake). PixelLab MCP for 2D art. `docs/DEMO.md`: the demo plan (area S 52.2065 – N 52.2595, W 20.9780 – E 21.0560; road/overpass survey; police, gentler; milestones loops 3a–3k); all six data downloads approved and being fetched into `data/raw/demo/` |
| 2026-10-28 | loop 10a | The river is off-limits (the user drove onto the Vistula and across it at 91 km/h). **Measured first** with a new whole-map check, `game/tools/check_water.gd` (joined to `tools/verify.sh` as `water` and `water-prebuilt`): the car's collision box driven at the water's edge every 2 m from the land (straight and ±40°, stepping 0.5 m at drive_height with an overlap test: Godot's `cast_motion` misses some thin concave walls), bridge decks probed sideways and past their ends, lanes / tram tracks / walked footways against the surface map, the real car rammed at 91 km/h every 10 m, and main.gd's own landing, free-spot and tow decisions on a detached copy. **Before**: 807 m of the edge open in 45 places: 9 by bridges (209 m; the bake leaves the shore wall open within 6 m of any deck, so from the boulevard under Most Świętokrzyski, the railway bridge or Most Poniatowskiego the car rolled into the river), 35 fountains (586 m, no edge at all), a canal slipway and a seam (12 m); 11 of 631 rammed cars ended in the river (all at bridges, no tunnelling); landing the helicopter to take the car back was allowed at 1,251 of 1,256 points over the water and the car's free spot was in the water at 1,252 of 2,478 edge points; nothing ever took the car out; 10 footways walked into ponds and fountains; decks, lanes, trams clean. **Now** all 0: a low granite edge (0.45 m, on the water's side, in the ground's mesh like the kerbs: no draw call, no shadow) along the baked runs plus the bridge stretches where the deck is ≥ 3.2 m up, the slipway, the seam and round the 40 fountains (9.4 km; collider 3 m, under any deck, 2 m pieces); `map_builder.shore_distance` / `in_water` (water.bin's R channel, zstd-packed into city.scn; in the water 2.5 m past the edge and at the water's level: 0.8 µs a call); in the water the car splashes (`splash.gd`: 56 droplets + a foam ring, one MultiMesh with the actors' material, 1.3 s; `sfx.splash`: the hard knock pitched down + a wash of the rain bed, no new file; a buzz), slows at 4/s and settles 0.45 m, and 1.0 s later is towed to the nearest lane on the level it came from (else by the nearest dry land, else the nearest junction), never wet, with a `water_tow` line (5 new, Polish over English; the HUD toast takes a gloss line); no money, no fail, jobs / rescues / races carry on; the helicopter won't land on the water; `_free_car_spot` keeps the spot's level (a tow under a bridge used to put the car on the deck) and stays dry; pedestrians stop a metre short of the water. New flag `--drive-into-water=X,Z` (verify step `splash`: towed in 1.00 s, 51 m, on a lane, dry, the kebab job on). Bench (day, medians of 3) 8.33 → 8.33 ms, scripts 1.66 → 1.66 ms; probe draw calls 152/124/189/245 → 153/124/191/245 (2D pass ±2); meshes +45 k vertices (+1.2 %); city.scn 35.9 → 36.3 MB. `verify.sh --ios` PASS (17 steps). On the iPhone 16 Pro Max: the water test towed in 1.01 s, and 60 fps (1 % low 55.3, 141 draw calls) standing on the boulevard. Shots `shots/loop10a_*` |
