# Nocna Warszawa (prototype)

Arcade driving and flying through the real Warsaw, isometric pixel art, built in Godot 4.7.2
from OpenStreetMap and GUGiK open data. This prototype has real road shapes (mapped
carriageways, kerbs, stop lines, turn arrows, bus and cycle lanes, raised bridge decks), day, dusk and night (lit windows,
street-lamp pools, neon shop signs, headlights, the Palace of Culture floodlit), a vaporwave
title screen, grade and VHS overlay, a car radio, one car, a rescue helicopter and rescue
missions, AI traffic with working traffic lights, trams, pedestrians, rival drivers to race,
side jobs (3 a.m. kebab delivery, the Sunday słoiki run), a wallet that is saved, a city that
talks back, five easter eggs and Warsaw's landmarks built by hand in code (the Palace of
Culture, Złote Tarasy, the Rotunda, Varso Tower, Stadion Narodowy, Warszawa Centralna, the
towers of Most Poniatowskiego; tap one for its card): about 3.5 × 1.8 km from Śródmieście to
the National Stadium.

v0.9 adds sound (engine, tyres, rotor, collisions, the city by day and night, trams' bells,
horns, rain: all synthesised here), rain with wet streets and reflections, a river that flows
and mirrors its bridges, a Live time of day with the real sun over Warsaw, a performance
overlay and a quality setting for the device pass (see Water, weather and sound).

Loop 1 (polish) makes the occlusion ghost a light, thin dither that shows the street at
its own brightness, calms the river (deeper, slower, few glints; dark at night with the
lamps' reflections carrying it), puts the Palm where the laser scan found it, stops
Varso 2's top from floating, sets the Palace of Culture's clock to the time in Warsaw,
makes the roadworks read (red-and-white barriers, bigger cones, blinking amber lamps) and
puts joke posters on one advertising column in six (see Loop 1 below the water section).

Loop 2a (after the first play on an iPhone: "steering feels strange") fixes the steering, which
circled when the stick was held (the follow camera turned with the car, so the direction a held
stick meant kept turning too), adds three control schemes (Point, Classic, Fixed camera), a
settings panel behind a gear in the top left corner (controls, traffic, quality, sound, the
performance overlay; saved), a little less traffic by default with a Traffic setting, and a
closer default view (see Loop 2a: controls and settings).

Loop 2b (the iPhone showed 13–16 fps) takes the frame from ~6,800 draw calls to ~125–250: the
minimap drew every street of the map as its own polyline under a clip, every frame (6,500 draw
calls), and the sun's shadow covered a slab 2 km deep because Godot ignores the shadow distance
for an orthographic camera. It also adds a 60 fps cap with a 30 fps battery saver, a TEST ·
BENCH button with a result card to copy, real Medium and Low steps, a fix for the parked car
being "pinned" while the player flies, and the performance budgets for the next rounds (see
Loop 2b: frame rate on the iPhone, and Performance budgets).

Loop 10a (the user drove onto the Vistula, and across it at 91 km/h) makes the water
off-limits: a new whole-map check found 807 m of the water's edge open in 45 places (under
all four bridges, round all the fountains) and a helicopter that landed on the river and left
the car there; now a low granite edge runs round the river, the ponds and the fountains, the
helicopter won't land on the water, and a car that still gets in splashes, settles and is
towed back to a lane on dry land a second later with a line from the tow crew (see Loop 10a:
the river is off-limits).

Loop 2e (the HUD was sized for a 720-line window: ~24 pt buttons and ~8 pt text on the phone,
and a crowded top row) sizes the whole HUD in points (every control at least 44 pt, text 11 pt
and up, inside the safe area), thins the first screen to the gear, the speed, RADIO and
HELI / AUTO (plus a WEZWANIE button when a rescue call comes in; no call card and no
"prototype" label at the start), moves time of day, rain, VHS, the picture style and the camera
into a tabbed Settings panel, lays out every passing panel so none covers another (the kebab
bubble no longer hides under the radio ticker), puts every surface on one dark card recipe with
Polish above English, and adds `check_hud.gd` (see Loop 2e: the HUD at phone size).

The first-minute look (after the art review: in the first minute the eye found lime grass,
coral cycle lanes and an azure river before the player's car, which at night was darker than
the road) lights the red car from within at night and keeps red for it alone in traffic, calms
the day (no saturation boost by day, quieter grass, brick-red cycle lanes, a grey-green-blue
river with fewer glints), lets nothing glow inside the occlusion ghost, turns the lamp pools
into banded pixel light under the lit windows' brightness, gives half the LoD2 walls back their
windows (a sign test drew them as blank roofs) and makes the trees lumpier with rust and olive
autumn colours (see The first-minute look).

The camera loop (the user: "the follow camera is not working"; their phone had Classic with the
following switched off by CAM, so that part was the setting) rebuilds the follow camera on
measured laws (`follow_camera.gd`): it never turns faster than 64°/s (Classic turned at up to
108°/s, the helicopter's camera at 135°/s, and a Classic game began with a ~155° swing at
182°/s), eases in and out with no overshoot, still waits while Point's finger is down, starts
behind the car, looks further ahead at speed, no longer slides back when you brake (8 m before)
and ignores tiny wiggles. With Phantom Camera (Ramokz, MIT, the first add-on) it adds a fly-in
from over the city when the title screen goes and a short look at a new rescue or delivery
target and back, both skipped by any touch (see Camera loop: the follow camera).

## Run it on your iPhone

1. `tools/export_ios.sh` (only needed after changing the game).
2. Open `build/ios/NocnaWarszawa.xcodeproj` in Xcode.
3. Pick your iPhone as the run destination, check Signing & Capabilities
   (team S6PVT5UP7G, automatic signing), press Run.
   The iPhone needs Developer Mode on (Settings → Privacy & Security).
4. For frame-rate numbers, stop it in Xcode and start the game from the iPhone's home screen:
   under Xcode's Run the debugger is attached, and Xcode's Metal API validation (on by default;
   `tools/export_ios.sh` now switches it and GPU frame capture off in the scheme) makes every
   draw call several times slower. Then Settings (the gear) → TEST, or the TEST · BENCH button
   on the performance overlay, and paste the card's text (KOPIUJ · COPY) into the chat.

## Run it on the Mac

`godot --path game` (or open `game/project.godot` in the Godot editor and press F5).

## Controls

| | iPhone | Mac |
| --- | --- | --- |
| Start (title screen) | Tap anywhere | any key / click |
| Settings (driving, camera, time of day, weather, traffic, picture style, quality, VHS, frame rate, overlay, TEST, sound; the game pauses) | the gear, top left | Esc |
| Drive, **Point** (the default) | Drag anywhere on the left side: the car heads where you point, gas by how far you push; the camera waits while your finger is down | W A S D / arrows point in screen directions |
| Drive, **Classic** | Drag left / right on the left side to steer; GAS bottom right, BRAKE beside it (slide your thumb between them) | A / D steer, W gas, S brake |
| Drive, **Fixed camera** | As Point, the camera never turns | as Point |
| Brake, reverse when stopped | BRAKE button | Space (Classic: S too) |
| Camera follows the car / stays put (in Point and Fixed it switches between the two schemes; a toast says which, loop 2e) | Settings → Jazda → Kamera za autem · Camera follows the car: Wł. / Wył. (On / Off) | C |
| Rotate the camera 90° (the fixed camera) | a two-finger twist (loop 2e; with the camera following it does nothing) | Q / E (switches to fixed) |
| Zoom out / in (30–320 m view, default 80 m; 110 before loop 2a) | pinch with two fingers on the right | mouse wheel, `-` `=` |
| Switch visual style (Ostry · Sharp, Drobny · Fine, Czysty · Clean, Toporny · Chunky; saved) | Settings → Obraz → Styl obrazu | T |
| Time of day: Day → Dusk → Night → Live (the real sun now) (1.5 s blend) | Settings → Świat → Pora dnia | N |
| Radio: next station → … → Off | RADIO, top right (the station under the word) | R |
| VHS tape overlay on / off (saved) | Settings → Obraz → Kaseta VHS | V |
| Rain on / off (it sets in over 4 s; the streets dry slower) | Settings → Świat → Pogoda | O |
| Performance overlay on / off | three fingers down at once, or Settings → Obraz | P |
| Frame rate: 60 (default) or 30 (battery saver), loop 2b | Settings → Obraz → Klatki na sekundę · Frame rate | Settings (Esc) |
| Benchmark: a minute on the bench route, then a result card to copy (loop 2b) | Settings → Obraz → TEST | the same (or `--bench-button`) |
| Quality: High → Low → Medium → High | Settings → Obraz → Jakość obrazu | U |
| Car ↔ helicopter (from the start) | HELI / AUTO, top right | H |
| Fly (helicopter) | Drag on the left side: it flies where you point | W A S D / arrows (screen directions) |
| Climb / sink (helicopter) | ▲ ▼ pads (where HAMULEC · brake is) | Space / Shift (or F) |
| Open a rescue call that came in (loop 2e: 60 s into play, then 90 s after each one) | WEZWANIE · rescue call, top centre | M |
| Accept a rescue call / next call | PRZYJMIJ · Accept, NASTĘPNE · Next call | M |
| Skip a call | POMIŃ · Skip | K |
| Challenge the rival in front to a race | MRUGNIJ ŚWIATŁAMI · flash your lights | L |
| Take a side job | drive slowly (under ~30 km/h) into the dashed ring by a kebab stand or at Dworzec Centralny | |
| Job card: JEDZIEMY! · Go! / NIE TERAZ · Not now, then OK | the card's buttons (or just drive off: that is GO) | M / K |
| Give up a race, a rescue or a job | ✕ on the status panel | |
| A landmark's info card | tap it (a short tap; a drag still steers) | click it |

**The camera** in each scheme (camera loop; `follow_camera.gd`): in **Point** it holds still
while your finger is on the stick (so the direction you point stays put), then 0.6 s after you
let go eases round behind the car (in ~3 s, at most 64°/s); in **Classic** with CAM on it turns
with the car, easing in and out, at most 64°/s (Settings → Jazda, "Kamera za autem" off, or C:
it doesn't turn); with the camera **fixed** (Point with "Kamera za autem" off) it never turns by
itself (a two-finger twist turns it; on the Mac the `<` `>` keys turn it 90°). In every scheme the view looks ahead the way you go (more
at speed, about 4 s of road at 90 km/h), never slides back when you brake, ignores tiny wiggles,
and widens a quarter at top speed (back in slowly). The helicopter's camera waits while its
stick is held, then comes round the same way. A following camera starts behind the car. When
the title screen goes, the camera flies in from over the city (2.6 s); a new rescue call or
delivery address gets a short look (out ~1.2 s, a moment on the target, back ~1 s) when you
are slow and not touching the controls. Any touch, click or key skips either.

The helicopter takes off above the car and rises to 45 m; the car waits, parked. It holds its
height above the ground, never goes below the ground or through a building (roofs are solid:
it stops at walls and can land on flat roofs), and its blob shadow shows how high it is. CAR
lands it where it is and gives the car back next to it; over a roof it asks for open ground first.

Styles: **Sharp** (480-line pixel image, the default), **Fine** (360), **Clean** (240),
**Chunky** (170 lines, fewer colours).

Keys changed in v0.7: N now switches the time of day (skip a call moved to K), and R tunes
the radio (the helicopter climbs with Space and sinks with Shift or F). Loop 2e: the top row
holds only the gear and the speed (left), WEZWANIE when a call came in (centre), RADIO and
HELI / AUTO (right); the keys are unchanged.

## Night and vaporwave

- **Day** is the original look, calmed in the look loop (no saturation boost by day, quieter
  grass, brick-red cycle lanes, a grey-green-blue river; see The first-minute look). **Dusk**: a low orange sun from the south-west
  with long shadows, a violet fill light, a pink-purple sky behind the diorama, glass towers
  reflecting it, and the first windows and lamps on. **Night**: deep navy-violet ambient, a
  cold moon (no shadows, which pays for the glow), stars, and the lit city. A switch blends
  over 1.5 s.
- **Lit windows** (`building.gdshader`): a seeded share of each building's windows (some
  buildings mostly dark, some busy; offices more than flats), warm, cool or flickering
  TV-blue; whole floors and runs of bays in the curtain-wall towers; most shop fronts lit;
  neon tubes along the fascia over about 30% of buildings.
- **Neon shop signs** (`neon_signs.gd`, `neon.gdshader`): 361 signs in a 5×7 pixel font with
  generic Polish shop words only (KEBAB 24H, BAR MLECZNY, APTEKA, KWIATY, HOTEL, KANTOR, PIZZA,
  KLUB, NOCNY), on the street side of a third of the buildings, some on a dark plate, a few
  with a tired, flickering tube. Readable from about 70 m zoom in.
- **Street lamps**: the 1,822 mapped lamps plus 224 added along the bridges (Most Poniatowskiego
  has none in OpenStreetMap) light the ground from a baked light map (`tools/bake_lights.py`,
  no real lights): warm sodium pools, cold white LED in parks, along footpaths and on about a
  quarter of the streets; pools stop at walls. The same map lights the lower facades, the tree
  crowns from below, parked cars and traffic. Lamp heads glow and wear a soft halo. The look
  loop made the pools on the ground pixel light: four hard bands with a one-pixel checker
  dither along each step (`night.gdshaderinc` `lamp_pool`, `pool_glow`), never brighter than
  ~80 % of a lit window (pale paving included), and on grass and cycle lanes the lamp tints
  the surface's own colour (sodium on grass reads warm olive, not chartreuse).
- **The player's car** (the look loop) lights from within at night (`actor.gdshader`'s hero
  part, `car.gd` `HERO_PAINT`): its red-orange paint and white stripes read over the dark road
  (it was 30-60 luma darker than the road), with tail lamps that wrap over the rear deck so the
  camera sees them, and a stronger, longer headlight cone than traffic's.
- **Vehicles**: head and tail lamps glow on every car, van, bus, tram and rival, with soft light
  on the road ahead and a red glow behind; bus and tram windows and taxi signs light up; Seba's
  underglow spills onto the road. The player's car also has one real spotlight. Signal lamps
  get halos; the helicopter blinks a red beacon and a white strobe and throws a searchlight.
- **The Palace of Culture** is floodlit: warm from below, violet up the tower, its gilded
  spire and clock dials glowing (v0.8 model, see Landmarks).
- **Grade and sky** (`post.gdshader`): magenta/cyan split-tone at dusk and night (none by day)
  and a dithered sky gradient where the map ends, with stars at night; a light bloom at night.
- **VHS** (`vhs.gdshader`, V): scanlines at screen resolution, red/blue pulled apart, faint
  noise and a tracking wobble that rolls up the picture every few seconds. It runs on the
  container that scales the pixel image up, so the scanlines stay sharp; the HUD stays clean.
- **Title screen** (`title.gd`): chrome NOCNA WARSZAWA over a striped setting sun with the
  Palace of Culture in silhouette (drawn from the v0.8 model's tiers, in metres), the skyline, the palm from Rondo de Gaulle'a and a neon grid;
  the city builds behind it, then TAP TO DRIVE / DOTKNIJ, BY JECHAĆ. Test runs skip it.
- **Radio** (`radio.gd`, R): 87,3 NOCNA FM (*Palma de Gaulle'a*), 86,6 RONDO FM (*Rondo
  Dmowskiego 3 A.M.*), 108,8 MORDOR FM (*Mordor Mall Muzak*), then Off; on by default at a
  moderate level. A burst of tuning static covers the switch and a now-playing ticker slides in
  at the bottom left. Hook for the v0.65 radio host: `radio.announce(text)` puts any line on the
  ticker, and `radio.station_changed(index, station)` fires on every change. Silent in headless
  runs (no audio device).
- Synth UI sounds (`tools/make_ui_sounds.py`): a blip for TIME and VHS, the tuning static, a
  rising chord when the title is dismissed.

## Rescue missions

A call names a real place from the map data and the hospital to bring the person to:

| Call | Where | Vehicle |
| --- | --- | --- |
| Street rescue | the middle of a named street or square (OpenStreetMap road names) | car or helicopter |
| Roof rescue | the highest flat spot on a named building's roof, at least 20 m up | helicopter only |
| River rescue | a Vistula beach (Poniatówka and others), the shore, or a sandbar island in the river | island: helicopter only; others: either |
| Park rescue | a named park or square (a child, so the children's hospital if it's closer) | car or helicopter |

Drop-off is the nearest of the two hospitals inside the map, at the road point nearest each:
Samodzielny Szpital Kliniczny im. prof. Witolda Orłowskiego (Czerniakowska) and Warszawski
Szpital dla Dzieci (children only). To pick up or hand over, stop the car within 6 m of the
beacon, or bring the helicopter within 8 m and less than 4 m above the person, and hold still
for 2 s. The clock is set from the straight-line trip; score is 500 + 10 per second left +
a bonus for the distance, and 8% of it is paid in złoty (+40 respect). The person (first names
only) says a line when picked up (roof, street, river, child or square lines), the crew another
at the hospital. Out of time: TRY AGAIN, NEXT CALL or FREE ROAM.

## A living city

- **Traffic**: cars, taxis (roof sign, chequered band), delivery vans and red-and-yellow city
  buses (main roads only) drive on a lane graph baked from OpenStreetMap (`graph` in
  `centrum.json`): right-hand traffic, the lane counts and one-way rules of the real streets,
  free-flow speed from `maxspeed` (or the road class), curves across each junction box. They keep
  their distance (an intelligent-driver model), give way to cars already crossing a junction and
  to trams, stop for red lights and for the player's car, and drive round it when it blocks the
  lane. Cars exist only in a band around the view: they appear and vanish out of sight, about
  40–50 on screen at the default zoom (more on main roads). Loop 2a: fewer by default and a
  Traffic setting (about 15 on screen at the new default view; see Loop 2a). At the map's edge they slide out
  under the diorama's rim. Roads that leave the map join the roads coming back in nearby on the
  same side through off-map links (`portals` in the graph, the streets out there): route
  planning uses them and a rival that drives off the map comes back in through one (the little
  Praga streets only meet the rest of the network out east, so this is how they connect).
- **Traffic lights**: 59 junction controllers from the mapped `traffic_signals` stop lines (signal
  nodes protecting the same junction share one controller; a lone stop line just before or at a
  signalled junction joins its cycle, and the two directions of one crossing share a light).
  Two groups of approaches (the two crossing axes; on a signalled roundabout the ring and the
  entries take turns): 18 s green, 3 s amber, 2 s all-red, then the other axis, with Polish
  red+amber before green; crossing lights give cars 26 s green in 40 s. The signal poles' lamps
  show the current colour.
- **Trams**: eight three-car trams in Warsaw yellow and red on the real tracks (Marszałkowska,
  Jerozolimskie, Świętokrzyska, Most Poniatowskiego), choosing a branch at random at points. They
  stop about 10 s at the platforms beside the track, obey the lights of the road running
  alongside, keep apart, brake for the player's car on the rails, and slide in and out at the
  map's edge. They are solid: give way.
- **Pedestrians**: up to 60 tiny people (48 at the Normal traffic level since loop 2a) (shirt, trousers, swinging legs) on the footways near
  the camera (bridge footways included, on the deck), turning into joining footways or back at
  dead ends.
- Hit a car and it stops for a moment; rivals complain.

## Side jobs, the wallet and the city's chatter (v0.65)

- **Wallet** (`wallet.gd`): złoty and respect, shown under the minimap (a coin and a star; a
  payment floats up as "+46 zł"). Races pay the rival's stake (60–300 zł) and +100 respect,
  rescues pay 8% of the score in złoty and +40 respect, side jobs pay fares and tips. Wallet,
  respect, jobs done, best times and easter eggs found are kept in `user://save.cfg` (a
  ConfigFile; on the Mac `~/Library/Application Support/Godot/app_userdata/Nocna Warszawa/`).
  No shop yet.
- **Kebab delivery** (`jobs.gd`): seven stands (a kiosk with a pixel KEBAB board, a striped
  awning and a lit hatch; the board glows pink and gold at night) at the two mapped kebab places
  (by Dworzec Centralny, under the Jana Pawła II viaduct, and in the Powiśle food hall) and on
  five busy corners (Rondo Dmowskiego by the Rotunda, Nowy Świat at Świętokrzyska, Solec at the
  foot of Most Poniatowskiego, Marszałkowska at Świętokrzyska, and Al. Poniatowskiego opposite
  Stadion Narodowy on the Praga bank); a stand is never put on a bridge. They blink orange on the
  minimap and wear a dashed ring on the road while nothing else is on. Pull into the ring and the
  vendor talks, then reads the order: a real address ("Wspólna 47/49") 400–1500 m away by road,
  or now and then across the river ("basically the centre", up to 3.6 km by road; from the Rondo
  Dmowskiego stand to Praga and from the Narodowy stand to the west bank). The Praga streets are
  reached through an off-map link from Al. Poniatowskiego (they join the rest of the city east
  of the map): the order's distance counts it; the player drives in however they can, and the
  autopilot jumps it. Same stand and order number, same order (`--kebab=N` takes stand N mod 7). No hard clock: a steam icon and heat bar fade on the way (HOT, WARM, COLD), the
  tip goes with the heat, nights pay ×1.5. The customer waits at the door and tells you how it
  arrived (`kebab_hot` / `kebab_cold`).
- **Słoiki run**: a newcomer with two bags of mum's jars waits by Dworzec Centralny (teal ring).
  Take them to a rented flat in Powiśle (1–2.4 km by road). Six jars in the status panel: hard
  bumps (closing speed over 3 m/s), braking harder than 16 m/s² and cornering over 14 m/s²
  stress them, and a jar breaks when the stress fills (the jars rattle first and the passenger
  warns you). A full stop from 50 km/h or a corner at 30 km/h is fine; slamming the brakes from
  90 or throwing it round a corner at 50 is not. The passenger chats on the way (`passenger`);
  pay is 50 zł + 35 zł a jar, +30 respect with all six.
- **One activity at a time**: a job starts only with no rescue or race under way and not from
  the helicopter; while it runs, rescue calls and race challenges wait, and the helicopter
  stays parked (the order rides in the car).
- **Dialogue** (`dialogue.gd`): loads `data/dialogue.json` (95 original Polish lines with
  English subtitles; a line can be tagged for a situation, e.g. roof-rescue or across-the-river
  lines) and picks lines per group from a shuffled bag, never the same twice in a row. An AI
  driver you hit, or hold up for a few seconds, sometimes shouts a `traffic` line from its car
  (9 s cooldown); the rescued person talks at pickup and the crew at the hospital; the radio
  host reads a `radio_host` line on the ticker (with the English underneath) every 60–120 s on
  a station.
- **Easter eggs** (`eggs.gd`, 5 to find, a small card counts them): **the Palm** on the island
  of Rondo de Gaulle'a (13 m, pink neon ring and violet uplight at night); **pigeons** in front
  of the Palace of Culture's east side on Plac Defilad, pecking, bursting into the air when the
  car or the helicopter comes close and landing again later; **roadworks** (barriers, cones, a
  dig, REMONT and OBJAZD signs) on a different street every day, seeded by the date, that the car
  knocks about (loop 1: 2 m red-and-white barriers, four a side and one at each end, 0.75 m
  cones with a white band, amber lamps on the barriers that blink at dusk and at night, with
  halos); a **crowd at Patelnia** by Metro Centrum; **the Mermaid** with sword and shield on
  the Powiśle boulevard (no Syrenka is mapped inside the area, so she stands on the promenade
  nearest the foot of Tamka). Each says a line the first time you come close. Five joke
  billboards in pixel letters (`signs`: UWAGA: GOŁĘBIE, PALMA · NIE PODLEWAĆ, KEBAB 24H ·
  NAPRAWDĘ 24H, the Marszałkowska roadworks phase 47 of 312, OBJAZD → OBJAZD → OBJAZD) stand
  nearby and show their line with the English when you pass.
- **Joke posters** (loop 1): one green advertising column in six (24 of 141, picked by a
  hash of where each stands) wears a poster wrapped round its band with a `column_posters`
  line from `dialogue.json` (16 original lines: a missing pigeon, a 9 m² room for 3999 zł,
  the tram that just left, Mordor hiring orcs, quiet hours 3:00-3:05...) in the 5×7 pixel
  font, twice (one copy faces the nearest road); passing within 12 m shows the line with the
  English. The letters read close up; at the default zoom the poster is a splash of colour
  and the bubble carries the joke, like the billboards. One shared material (an atlas).

## Rivals and street races

Six made-up rivals cruise the city in their own cars (dots in their colours on the minimap,
name tags up close): **Seba z Pragi** (lowered purple coupe with a neon underglow), **Mordor Mike** (grey
company estate with a roof box, an office guy from Domaniewska), **Pani Halina** (tiny mint
hatch with a basket on the roof, a pensioner late for the bazaar), **Słoik z Radomia** (white
van with a spoiler and mum's jars on the rack), **Taksiarz Zbyszek** (black taxi, every shortcut
since '87) and **Bulwar Bartek** (neon-green hatch with a speaker on the roof). Seba always
starts near you.

Drive up close behind one (within 15 m, both moving) and FLASH LIGHTS appears (L). Flash, and
the rival names a finish 600–1800 m away by road at a real place: Pałac Kultury, Rondo
Dmowskiego, Stadion Narodowy, the far end of Most Poniatowskiego, the Palm on Rondo de Gaulle'a, Plac
Trzech Krzyży, Kopernik, Złote Tarasy, Rondo ONZ, Varso, Dworzec Powiśle. 3-2-1, then the rival
takes the shortest path on the lane graph (Dijkstra), changes lanes past slower traffic and runs
some reds; you take any route. A beacon, the edge arrow, the distance, the clock and your
position (1ST / 2ND) show the race; reach the beacon (within 16 m) first to win. A card and a
trash-talk bubble end it: win and you get the rival's stake in złoty (Pani Halina 60, Słoik 90,
Bartek 120, Seba 150, Zbyszek 200, Mordor Mike 300) and +100 respect. Only one activity at a
time: no race during a rescue or a side job, rescue calls wait while a race is on, and the
helicopter waits until it is over.

Rivals talk in speech bubbles, Polish with English subtitles (`bubbles.gd`, reusable: anything
can talk, `bubbles.say(node_or_callable, speaker, polish, english)`; `bubbles.tag()` for name
labels).

## Real roads (v0.75)

Roads are most of the screen while driving, so they follow the real streets
(`tools/bake_roads.py`, run by `bake_osm.py`):

- **Carriageway shapes**: where OpenStreetMap maps the carriageway as an area (`area:highway`:
  the main arteries, junction boxes, Rondo Dmowskiego, bus bays; 202 areas), that polygon is
  the road surface and the road's own strip is hidden under it ("hide" ranges on the road).
  Under an area the carriageway's left and right edges are measured from the centreline, so the
  strip, the painted lines and the lane graph's lanes all sit on the drawn asphalt even where
  the mapped line is off-centre (`w` and `c`, the shift right of the line). Elsewhere the width
  comes from `width`, then `lanes:forward` + `lanes:backward` (or `lanes`) at 3.25 m a lane on
  main roads and 3 m on others, plus 1.5 m per painted cycle lane, then the road class.
- **Markings**, all cut where other roads cross and kept off islands and hatched areas: edge
  lines along the carriageway's edges (main roads), lane lines on the lane boundaries (the
  direction line solid on big roads), stop lines at every signal-controlled approach (where the
  cars stop), turn arrows from `turn:lanes` 7 m (and 38 m on long approaches) before the junction
  (left, right, through and their combinations, as pixel shapes), bus lanes from `bus:lanes` /
  `psv:lanes` / `lanes:psv` (a wide solid line and BUS every 60 m), painted cycle lanes
  (`cycleway*=lane`: a line, red surface and a bike every 40 m), hatched areas
  (`area:highway=emergency/prohibited`: an outline and stripes, chevrons in long thin ones).
- **Kerbs**: a 14 cm granite kerb (light top, darker face) wherever the carriageway meets
  something that isn't road: pavements, medians, tram beds, islands (121 km). Traffic islands
  are raised to kerb height with a kerb all round. Dual carriageways (two one-way roads running
  opposite ways side by side) get their median: raised grass, or paving at road level where
  trams run in it (mapped grass, islands and hatching stay as mapped).
- **Bridges**: a deck solver gives every bridge road a height profile that clears what runs
  under it (5 m over roads, rails and tram tracks, 7.5 m over the river), ramps at 6 % and meets
  the roads at its ends (12 % at most); bridge footways, tram tracks and rails take the height of
  the deck beside them, and a bridge with no road (the railway bridge, footbridges) solves its
  own. Decks are pieces with a height every 6 m, in groups (one structure each, `decks` in
  `centrum.json`); everything baked onto a bridge carries its group (`dk`). Under every piece a
  concrete slab, parapets on the outer sides and piers; the car drives the deck it is on
  (`map_builder.drive_height`: a deck 5 m overhead is not the road), traffic, trams and
  pedestrians use their own deck. The Jana Pawła II viaduct now rises over Al. Jerozolimskie
  (its OSM 3D model, `man_made=bridge` building parts, is skipped: `br` on those buildings).
  Loop 3a replaced the deck solver: structures are solved with their approaches as chains, the
  clearance is a hard minimum, approaches correct the ground (`fills`), tunnels are kept (see
  Loop 3a).
- **Guard rails**: a steel beam on posts along the carriageway's edges on every bridge and along
  the mapped `barrier=guard_rail` ways (9.6 km), solid for the car.
- **The river's edge** is solid too: the car stops at the water. Loop 10a: a low granite edge
  you can see, under the bridges too and round the fountains (see Loop 10a).

Check against the aerial photo: `python3 tools/overlay_ortho.py OUT.png X Z HALF` draws the
road areas (red), kerbs (cyan), lines, and the lane graph's lanes (magenta) over the GUGiK
orthophoto (`shots/v075_overlay_*.png`). `godot --path game --resolution 320x180 --script
res://tools/count_vertices.gd` prints the city's vertex count.

## Landmarks (v0.8)

The buildings that make it Warsaw at a glance are built in code (`landmarks.gd`), sized and
placed from the real footprints and heights in `centrum.json` (OpenStreetMap outlines and
`building:part`s with `height` / `min_height`), and replace their LoD2 / OpenStreetMap lumps:
whole LoD2 buildings whose middle lies in a landmark's zone are left out (the bake writes each
building as one run of triangles sharing its style seed, UV2.x), and so are the OpenStreetMap
outlines and parts centred in it (and their neon shop signs). Checked over the GUGiK orthophoto
(`tools/overlay_landmarks.py`, `shots/v08_overlay_*.png`).

- **Pałac Kultury i Nauki**: in its own frame (the Śródmieście grid, from the mapped 139-168 m
  clock tier): the base round its two courtyards and the Congress Hall's drum, the corner
  pavilions, the annexes and the east portico; the four corner towers to 67 m, the ribbed shaft
  to 139 m, the clock tier to 168 m with a dial (6.3 m) on every face showing the time in
  Warsaw (loop 1),
  the lantern's dark arches to 188 m, the patina crown and the gilded spire to 237 m. Every
  tier ends in a crenellated attic (the shader cuts the merlons: one quad per wall) with
  pinnacles at the corners. Its stone wears tall windows between piers with a pilaster every
  fourth bay; at night it is floodlit as before.
- **Złote Tarasy**: the glass wave is one surface over the eight mapped glass domes, each a cap
  to its mapped height (35 m by the offices, 22 m towards the station), blended where they meet
  (log-sum-exp, 2.6 m) so it rolls instead of creasing, laid on the ground's slope, with glass
  walls round its rim; a diamond lattice by day, glowing gold at night. Lumen and Skylight stay
  LoD2.
- **Rotunda**: a granite plinth, two storeys of glass lit from inside, a lit band under the
  overhanging white roof, which rises in ribs to a glass oculus.
- **Varso Tower**: from its mapped parts (the glass slabs, the dark spines at both ends, the glass
  crown 193-234 m, a lantern lit cool white at night); the spire's thin parts become one mast to
  310 m with its five rings and a red beacon.
- **Stadion Narodowy**: its outline at every angle from the 72 pairs of mapped masts: the woven
  red-and-white skin leaning out like a basket from the old embankment's crest to the roof's
  edge (two families of diagonal strips, red over white then white over red, lit at night),
  72 masts leaning with it and spiking over the roof, the white membrane round the open middle,
  red stands with grey gangways down to a striped pitch, the needle hanging over the centre
  (30-100 m, a red light on its tip) on its cables, a paved promenade on the crest. The
  embankment is the terrain (the old Stadion Dziesięciolecia's bowl); the mapped 14 m podium
  that covered the bowl is dropped.
- **Warszawa Centralna** (mapped in 3D, its outline underground): a 140 x 57 m roof of
  hyperbolic-paraboloid shells on the mapped pillars (saddles whose corners rise and fall in
  turn, so the eaves zigzag), the glass hall under it, the canopy round it to 140 x 86 m.
- **Most Poniatowskiego**: its four towers at the ends of the river span (mapped outlines, no
  heights): plinth, shaft and cornice to 15 m over the deck, an arcade, a pointed roof, a finial.

Materials (`building.gdshader`): UV2.x >= 2 is a material code (`landmarks.gd` `M_*`: monument
stone with windows, plain stone, crenellated attic, gold, clock dial, woven skin, glass wave,
lit glass pavilion, curtain wall, lamp, membrane), its fraction a parameter; UV2.y the wall's
top; UV the metres along and up a wall. Every landmark triangle also goes into the helicopter's
roof grid (the Palace's spire stands 236 m in its cells, so it can't be flown through; roofs
can be landed on) and into a grid of which landmark covers each 4 m cell; their walls at street
level stop the car. Roof rescues still come from the landmarks' outlines and the roof grid (on
the Palace now a 28 m roof: the tiers are crowned by attics and pinnacles).

**Info cards**: a short tap (under 0.35 s and 16 px, not on a control, not a pinch) goes out as
`hud.tapped`; the game walks the ray from that pixel through the roof grid (1 m steps) and, if
the first thing standing is a landmark, shows its card in the note card's place for 8 s: name,
one or two Polish lines, the English under them. `--tap=X,Y` taps a screen pixel at frame 60.

**Occlusion ghost** (reworked in loop 1, `shaders/ghost.gdshaderinc`): besides the small
see-through hole round the car (which opens fully), everything standing on the camera's side
of the car (more than a metre nearer the camera, measured along the ground, full from 4 m)
inside a region round the car on screen (an ellipse 0.22 x the view's height, wider than tall,
lifted a little, its upper half stretched 1.35 times so a tower's top fades out instead of
ending at a cut) turns into a thin ghost: in the core only 3 pixels in 16 stay
(`ghost_keep` 0.19), and a dithered rim (0.65-0.9 of the radius since the look loop; it was
0.55-1.0 and speckled roofs that don't hide the car) runs out to the whole wall. Every fragment
goes, near walls, far walls and roofs alike, and looking into a cut building its inner faces go
too. What the ghost keeps has no outlines (the post pass outlined every kept pixel, which turned
the ghost into a dark stipple) and nothing in it glows (the look loop: its windows, shop fronts
and neon tubes lose all their light with the ghost's fade; loop 1 kept 30 %); the inner faces
of a cut building seen through it are unlit and flat, a step darker than the street. Under the ghost the
ground lifts the buildings' baked shade (the AO map's buildings channel; the trees' and
parked cars' shade stays) and, inside a ghosted footprint, which its own building always
shades, gives back the sunlight (all of it with a sun above 40 degrees, none below 15: the
streets round it lie in long shadows then; none at night or without shadows). Not in the
shadow pass, so the ghosted towers still cast their shadows on the street. `--ghost-debug=1`
paints the ghost magenta and the other buildings green and prints the ghost's ellipse in
screen pixels with every screenshot (for measuring), `--ghost-debug=2` cuts it fully.

What showed through before loop 1, measured with debug renders (full cut, `--no-ao`, Low
quality for no shadows): the ground inside the footprint, at 0.28 of its brightness from the
baked AO and in its own building's shadow (the dark stain), plus every kept wall pixel
darkened by the depth outline; the clear colour never showed, and back faces only where the
car stood inside a footprint. Mean luma inside the ghost (the pixels a `--ghost-debug=1`
mask marks, within 0.8 of its radius) against a ring of ground 1.02-1.3 radii out (ratio,
before → after): spawn by day 0.80 → 0.99, spawn following the car
(`--demo`) 0.89 → 0.92, Live 08:00 by the glass tower 0.98 → 1.06 (pixels under 60: 9% →
7%), the Palace from the north-west 0.70 → 0.83 (the rest is the Palace's own shadow, which
lies over the car), the v0.8 Palace close-up 0.68 → 0.85, Rondo Dmowskiego at night in the
rain 1.14 → 1.14 (in v0.9's rain shot, where the ghost only catches a tower's edge, 0.68 →
0.74).

**The Palm** stands where the laser scan found it (loop 1): the 14.5 m "tree" with a 4 m
crown alone on Rondo de Gaulle'a's island is the Palm itself (about 15 m), so the bake leaves
it out of the trees (`GUGIK_NOT_TREES` in `tools/bake_osm.py`) and writes where it stands as
`palm` in `centrum.json`; `eggs.gd` stands the Palm there.

**Floating parts** (loop 1, `map_builder.gd`): an OpenStreetMap building part is drawn from
its `min_height` up; where the parts under it are not mapped it hung in the air (Varso 2's
80-90 m top over a 72 m neighbour: a broken lamp post from the south-west). A part starting
10 m or more up that rests on something (a part reaching to within 3 m of its bottom, or
within 2.5 m a LoD2 building or a landmark) under less than half of its footprint is lowered
to the highest roof below that carries half of it, or to the ground; tiny ones (under 12 m²)
are left out. In this map: 17 floating parts, 5 lowered to the ground (Varso 2's 80-90 m
top; a 78 x 19 m slab at 14-35 m beside Złote Tarasy, at -1491,522; two 12 m parts at 23 m
at -300,360; one at 25 m at -1497,-170) and 12 tiny ones left out (a stack of spire parts
at 155-195 m on the map's west edge, at -1766,-176, with no tower under them in the data).
Lower overhangs (canopies, passages, pilotis under 10 m) stay as mapped. The build prints
the count.

**The Palace clock** (loop 1): the four dials' hands are drawn by `building.gdshader` from the
disc's UVs (the point on the dial in radii) and a `clock_hands` uniform that `main.gd` sets
when the minute changes, from the device's clock in Warsaw time (or `--clock=` /
`--date=`): no geometry, nothing per frame.

`godot --headless --path game --script res://tools/check_landmarks.gd` checks each landmark: its
tallest roof-grid cell, that a tap finds it, that a car driving in from 12 directions is stopped,
that the helicopter (heli.gd stepped by hand) flying at it at half its height is stopped outside
it and then lands on open ground beside it, the roof rescues on the replaced outlines and the
cells round the Palace's spire.

## Water, weather and sound (v0.9)

**Sound** (`sfx.gd`, every file made by `tools/make_sfx.py`: oscillators, noise and filters,
no samples). Buses: Master, **Music** (the radio, player at -9 dB), **SFX** (-3 dB) and
**Ambience** (-9 dB, and 4 dB lower while a station plays, so the radio keeps priority).

- The car: three engine loops of a tired 1.2 l four-cylinder hatchback (850, 2400 and
  4500 rpm; one weak cylinder, a little timing jitter, a tinny back box), crossfaded and
  pitched by a five-speed box (upshifts at 23, 45, 68 and 92 km/h with a short dip in the
  sound, a slipping clutch from rest, a hunting idle); load from the throttle (or, for the
  autopilot, how hard it speeds up). Tyres rolling on dry asphalt by speed, a hiss instead on
  a wet road, a squeal in slides and under hard braking (quieter in the rain).
- Collisions where the haptics are (`car.impact`): a soft thump, a hard one, a crash, by
  closing speed; a guard rail clangs (a 4 m grid of the mapped rails); the słoiki run's jars
  clink at every bump and warning and shatter when one breaks.
- The helicopter's rotor (four-blade slap at 18 Hz, turbine whine, tail rotor) winds up with
  the blades after take-off and down after landing; pitched by speed and climb.
- The city: a day bed (distant traffic, cars passing far off) and a quieter night one,
  stereo; birds every 7-16 s by day (not in rain); at night, every 45-110 s, a far siren or
  a dog. Rain has its own bed.
- Positional (AudioStreamPlayer3D, a pool of six: the cap on voices; heard within 85 m of a
  listener 12 m over the camera's focus): a tram's two-tone bell when it leaves a stop or
  brakes for your car on its track, a horn (sometimes) from a driver you hold up or hit, the
  pigeons flushing on Plac Defilad.
- iOS: the audio session is **Ambient** (`audio/general/ios/session_category=0` in
  project.godot): the phone's silent switch mutes the game, and your own music keeps
  playing under it.
- Checks: `python3 -I tools/make_sfx.py game/audio/sfx game/audio/radio` prints peak, RMS,
  the loop seam (step and slope across the loop point against the 99.9th percentile
  elsewhere), the share of energy under 2 kHz and the roll-off for every file, and the radio
  loops' levels; `godot --headless --path game --script res://tools/check_sfx.gd` checks the
  imports (Forward loops, QOA) and decodes across each loop point; `godot --path game --
  --sound-check` (with an audio device) plays every one-shot and prints each bus's peak;
  the bench prints the buses' peaks while driving.

**Rain** (`weather.gd`, RAIN / O / `--weather=rain`): Clear or Rain, separate from the time of
day. `amount` (how hard it rains) drives the streaks, the rain bed and an overcast light
(the sun 45% weaker, a greyer sky and ambient, shadows at half strength); `wet` (how wet the
streets are; dries three times slower) is the shader global `wetness`:

- Streaks: three layers of one-pixel streaks in the post pass (far: short and slow; near:
  long and fast), slanting with the wind, drifting a little with the view; a grey veil by day.
  Screen-space: cheaper than particles on the Mobile renderer, and they follow the camera.
- Wet ground (`ground.gdshader`): asphalt 38% darker, paving 26%, markings 18%; a sheen of
  the sky; puddles from a noise mask on roads and paving only (never kerbs, islands, grass or
  roofs), darker, mirror-like, with rings where the drops land.
- Reflections (`post.gdshader`): on a level surface that the surface map calls water, road or
  paving, the mirrored view ray is marched up the screen through the depth buffer (10 steps on
  High) and what it hits is mixed in, smeared a little along the ray: every lamp, neon sign,
  signal, headlight and lit window stretches into a vertical streak on the wet asphalt at dusk
  and night; puddles mirror most. The street lamps' light map adds broken columns of lamp
  light on wet ground and water too (so even Low, with no mirror, has them).
- Grip: 22% less sideways grip and 15% less braking on a wet road: the tail lets go a little
  sooner. Wet tyres hiss instead of rolling.

**The river** (`tools/bake_water.py` → `map/water.bin`, the *surface map*: RGBA per 2 m, inside
`city.scn` like the light map): distance to the shore inside the water (the depth colour: light
and a little green at the edge, deep blue mid-river; ponds go deep sooner), the Vistula's flow
(north, turning with the banks: the middle of the river per row, smoothed over 120 m), what
reflects (paving, road, still water, the river) and the height of any bridge deck.

- The water slides downstream (a flow map in two crossfading phases, 0.7 m/s), stretched
  along the river; ponds and fountains are still. Shore foam laps in a broken band (thin
  round ponds and fountains); a rare sun glint flickers on the highest crests by day.
  Loop 1 calmed it to a slow lowland river: a touch deeper and greyer, the flow a
  low-contrast drift (half that again at night), the glints fewer and smaller. The look loop:
  by day the depth shading starts from a grey-green-blue (`DAY_WATER`; the mapped azure read
  as an open sea), the pale crests a third as strong and the sun sparkles a quarter as many
  (1-2 px each); at night the water is as before.
- Bridges: by day a bridge shows on the water beside it as a darker shaded band (loop 1; the
  pale mirrored copy of the concrete read as a wake; half as strong since the look loop), the
  water under the deck in its shade; at dusk and night the mirror carries the lamps and lights.
- At night the water gets no lamp pools any more: the bridge lamps and the boulevard lights
  reflect as shimmering columns of broken light, and the mirror catches their heads, the
  cars' lights and the lit windows. Loop 1: the pink and cyan glints that washed over half
  the river (the "camouflage") are gone; the water is dark and calm. (Backlog fix: nothing under a bridge deck gets the deck
  lamps' pools now, ground or water.)
- Ponds and fountains share the shader.

**Live** (TIME's fourth mode, `--time=live`): the real sun over Warsaw (52.23 N, 21.01 E) for
the device's clock, from NOAA's solar-position formulas (UTC in, so the time zone only matters
for the label and `--clock`): Day above 10 degrees of elevation, blending to Dusk round sunset
(10 to -2) and to Night below -10; the sun turned to its real azimuth with its pitch held
between 20 and 55 degrees (midday still has shadows; a low sun doesn't throw them across the
map). Rechecked every 10 s. The TIME button shows "Live 13:05" (Warsaw time: CET, CEST from
the last Sunday of March to the last Sunday of October). `--clock=HH:MM --date=YYYYMMDD` start
the clock at a Warsaw time for screenshots (it then runs on); `godot --headless --path game
--script res://tools/check_sun.gd` prints the sun for a few dates and times. Day is still the
starting mode.

**Performance overlay** (three fingers down at once, P, `--perf`, Settings; reworked in loop 2b):
updated twice a second, fps, the average and worst frame since the last update, the main
thread's split (CPU: process = every script's `_process` and the 2D redraws, physics, draw =
building and handing the frame to the GPU, which grows when the GPU is behind or the display
makes it wait), the 3D view's GPU time (n/a on Metal, so n/a on the iPhone; Vulkan on the Mac
shows it), draw calls split into the pixel image's 3D pass, its shadow pass and the 2D pass
(HUD and the scale-up), objects, triangles (and the shadow pass's), static and video memory,
the pixel image's size, time of day, weather, the frame-rate cap and sound voices, then
**QUALITY** and **TEST · BENCH**. It costs a timestamp per frame phase and one label update
every half second. (Godot's own "process" monitor, which the overlay showed before, is the
slowest whole frame of the last second, rendering included: on the iPhone it read 60 ms because
the frame did.)

**Quality** (QUALITY, U, Settings, `--quality=low|medium|high`, default High; saved since loop 2a;
loop 2b made Medium and Low real steps):

| | High | Medium | Low |
| --- | --- | --- | --- |
| Pixel size (whole screen pixels per image pixel) | Sharp's 480 lines or more: 2 on an iPhone (660 lines on 1320, 585 on 1170) | one coarser (3: 440 / 390 lines) | as Medium |
| Sun shadows | 2048 map, everything over a metre tall | 1024 map, buildings and trees only | off |
| Night glow | on | on | off |
| Rain streaks | all | 70% | 40% |
| Mirror reflections (steps per pixel) | 10 | 6 | off |
| Traffic (share of the usual, × the Traffic setting) | 100% | 80% | 55% |
| Pedestrians (most at once, × the Traffic setting's share) | 60 | 40 | 24 |
| Draw calls at the default view (river, iPhone 16 Pro Max, loop 2b) | 124 | 118 | 99 |

Before loop 2b Medium's 0.85 render scale gave High's image on a 1170-line phone and Low's on a
1320-line one, and its shadow map was 2048 against High's 4096 over a 2 km slab.

## Loop 1 (polish, 2026-10-28)

What looked worst in the screenshots, fixed (details in the sections above):

- **The occlusion ghost** is a thin, light dither that shows the street at its own brightness
  (Landmarks: Occlusion ghost, with the before/after luma).
- **The river** is a slow lowland river: deeper and a little greyer, a low-contrast drift,
  rare small glints, a darker band beside a bridge by day; dark and calm at night with the
  lamps' columns carrying it (ponds share it). (Water, weather and sound.)
- **The Palm** stands where the laser scan found it; the scanned "tree" is gone (trees3d
  12,555 → 12,554 trees). **Varso 2** no longer floats (Floating parts). **The Palace clock**
  shows the time in Warsaw.
- **Roadworks** read at the default zoom; amber lamps blink at dusk and night. **Joke
  posters** on one advertising column in six. (Side jobs, the wallet and the city's chatter.)

Screenshots: `shots/loop1_*.png` (44: before/after pairs `*_before.png` / `*_after.png`, the
before images rendered from the v0.9 code and data; the ghost and the night river also on the
prebuilt path).

Cost (bench, same session, the v0.9 code and data run alongside from a copy, before →
after): Vulkan GPU 2.40 / 2.42 → 2.39 / 2.31 ms by day, 2.10 / 2.23 → 2.08 / 2.24 at night,
2.30 / 2.36 → 2.15 / 2.32 at night in the rain; Metal frame 3.65 → 3.64 ms by day, 3.66 →
3.73 at night, 3.60 → 3.64 in the rain; traffic, trams and people 0.79-0.87 ms either way,
side jobs + eggs 0.03 → 0.04 ms (the posters' passing check, ten more knockables). The Mac
ran uncapped this time (220-280 fps), not at the display's 120 Hz as in earlier sessions,
so these numbers don't line up with the v0.9 ones below (the same v0.9 code read Vulkan GPU
1.78-1.90 ms at the start of this session, still capped). Vertices: the city 6,070,773 →
6,069,970 (the floating bits left out, the clock hands now in the shader, one tree fewer);
the runtime props (`eggs.gd`, not in that count) +3,516 (bigger barriers and cones, their
halos, the 24 posters).

## Loop 2a: controls and settings (2026-10-28)

After the first play on an iPhone ("steering feels strange"; and a little less traffic, or an
option for it).

**Why the steering felt strange.** The stick points in screen space and the car steers towards
that direction in the world, but the Follow camera (the default) kept turning towards the car's
heading, so the world direction a held stick meant kept turning with the car. Measured with the
input replay (`tools/check_steering.gd -- --legacy`, the code before loop 2a): stick held to
the right at 50 km/h, the car turned 1151° in 10 s (3.2 circles, ~115°/s, the camera chasing
~50° behind) and never settled; held 15° off the nose it drifted 155° off in 8 s; pointed
straight back, 2.6 circles. The same inputs with the camera fixed settled in 0.3-1.8 s. Also
measured: a 4 g swerve at speed (full-lock radius 2.3 m at 20 km/h, 6.4 m at 50, 11.5 m at
78), no turning at all from a standstill (it needed 5 m/s for full lock), and walls that stopped
the car dead (8 % of the speed lost every frame of contact: a glancing hit at 93 km/h was down
to 11 km/h a second later, a head-on push stayed pinned for good).

**Three control schemes** (Settings → Controls, `--controls=`; `drive_controls.gd` maps the
stick, keys and pedals for the game and the replay test alike):

- **Point** (the default, one thumb): point where you want to go. The follow camera holds still
  while your finger is down, so a held direction stays put on screen and in the world; 0.6 s
  after you let go it eases round behind the car (it reaches it in ~3 s, at most ~64°/s; it was
  up to 116°/s). Gas by how far you push (a target speed; full from three quarters out);
  pointing well behind at speed brakes first, then turns; a big turn holds the speed until it is
  done. Keys: W A S D point in screen directions (like the helicopter), Space brakes.
- **Classic** (two thumbs): drag left / right on the left side to steer (a strip, car-relative,
  a gentle curve near the middle), GAS bottom right and BRAKE / REVERSE beside it (a thumb can
  slide from one to the other); the camera turns with the car. Keys: A / D steer, W gas, S or
  Space brake.
- **Fixed camera**: Point with a camera that never turns (the v0.4 scheme). CAM / C switch
  between Point and Fixed; in Classic CAM turns the following on or off.

The helicopter keeps its own controls; since loop 2a the follow camera also waits while its
stick (or a key) is held, for the same reason.

**The car's feel** (`car.gd`, all schemes; numbers from `check_steering.gd`, before → after):

| | before | after |
| --- | --- | --- |
| Full-lock radius at 20 / 50 / 90 km/h | 2.3 / 6.4 / 11.5 m (at 78; 1.4 / 3.1 / 4.2 g) | 2.5 / 8.6 / 23.5 m (1.3 / 2.4 / 2.7 g) |
| Held stick 90° right at 50 km/h (Follow) | 3.2 circles in 10 s, never settles | within 5° in 1.2 s, 0° overshoot, stays |
| 45° / 15° off the nose (Follow) | 1.4 circles / 155° off after 8 s | settled in 0.7 / 0.4 s |
| Pointed straight back at 50 km/h (Follow) | 2.6 circles | brakes 0.4 s (to 17 km/h), turned round in 1.7 s, no overshoot |
| 90° turn from a standstill | 0.90 s circling on (Follow), 1.08 s (Fixed) | 1.00 s (Point), 0.87 s (Classic) |
| 90° turn from 50 / 90 km/h (Point, Fixed camera before) | 1.02 / 1.15 s, 10.6 / 18.4 m | 1.20 / 1.65 s, 11.0 / 26.4 m, 0° overshoot |
| Glancing wall hit at 93 km/h (30°): speed 1 s later | 11 km/h (12 %) | 86 km/h (92 %), slides 47 m along it in 2 s |
| Pushing head-on into a wall | pinned for good | Point follows the wall (0.4 s); Classic is turned out after 1.5 s |
| Into an inside corner, then pointing out | pinned 2 s | turned out after 1.5 s, drives away |
| Classic: steer, then let go | stops turning at once | stops 0.27 s later (input smoothing), 5° more |

How: the most it turns is ~2.3 rad/s when slow and 18 m/s² / speed + 0.35 rad/s at speed
(sharp when slow, calm when fast); it pivots a little from a standstill with the gas on (full
lock from 2 m/s); steering input smoothed over 0.08 s; point-to-steer turns at a rate set by
the heading error (6/s) with a touch of yaw damping, and never flip-flops when pointed straight
back. Walls: the part of the velocity going into a wall is taken off (Godot's floating
`move_and_slide` leaves it in), the rest is kept less a little scrape (1.2/s), a glancing hit
turns the nose along the wall (3 rad/s), a head-on one pushes it back a little; pointing into a
wall it touches, Point follows the wall the way the stick leans; pinned (touching something fixed,
the gas or brake on, under a metre of progress; nosing into the car ahead in a queue doesn't
count) for 1.5 s, the car is turned out of everything it touched and sent off at walking pace;
pinned again within 5 s, it is towed back onto the nearest lane on its level, facing the lane's
way ("Pomoc drogowa: wyciągnięci! · Towed free"). Point follows only fixed walls, not cars.

**The view.** The default view is 80 m high (110 before): the 4 m car is ~58 px long side-on on
an iPhone's 1170 lines (43 before; ~3.2 mm on the glass instead of 2.3), and there is still
~80 m of road above the car, ~3 s at 90 km/h, plus the 25 % zoom-out at top speed. The view
leads by half a second of the car's velocity, smoothed over 0.7 s so a turn swings it round
gently, at most a fifth of the view (it was 0.6 s of the raw velocity, up to 22 m); the car's
place on screen moves at most 73 px/s with Point and 91 px/s with the Fixed camera in the
replay's turns at 80 m (up to 143 px/s before, at the 1.4× wider 110 m view). `−` / `+` and pinching still zoom (30-320 m; not saved).

**Settings** (the gear in the top left corner, Esc; `settings_panel.gd`): a dark card like the
mission panels, Polish over English, every control at least 44 pt (on a computer the window is
taken as a 390-pt-tall phone screen, so screenshots show the phone's sizes). The game pauses
under it (the radio plays on). Controls (with a line saying what the scheme does), Traffic,
Quality (also still on the performance overlay and U), Sound (Głośność / Volume, Radio, Efekty /
Effects: − and + in tenths or drag along the bar; zero mutes), and the performance overlay.
Saved in `user://settings.cfg` (`settings.gd`; beside the wallet's `save.cfg`, which
`wallet.gd` rewrites whole); `--nosave` neither reads nor writes it; command-line flags win
for that run and are not saved.

**Traffic** (Settings → Traffic, `--traffic=`; × Quality's share). Busy is the old level. Its
target (70 cars in the band round the view at 80 m) is more than the spawner can place there
(~44, the spacing rules), so the levels are set from the cars that really appear (bench route,
default view, day):

| | traffic density | cars on screen | driving | traffic + trams + people | pedestrians (most) |
| --- | --- | --- | --- | --- | --- |
| Pustawo · Almost empty | 0.10 | 5 | 14 | 0.28 ms | 27 |
| Mało · Low | 0.22 | 9 | 21 | 0.35 ms | 39 |
| Normalnie · Normal (default) | 0.38 | 15 | 32 | 0.42 ms | 48 |
| Tłoczno · Busy (before loop 2a) | 1.0 | 25 | 52 | 0.63 ms | 60 |

(Before loop 2a, at the 110 m view: 33-36 on screen, 71-77 driving, 0.76-0.86 ms.)

**Checks.** `godot --headless --path game --fixed-fps 60 --script res://tools/check_steering.gd`
(add `-- --legacy` for the numbers before loop 2a, `-- --verbose` for a line every 0.5 s,
`-- --only=NAME`): the input replay on a flat test ground with walls, through the game's own
mapping and camera code; it exits 1 on a held direction that circles, oscillates or doesn't
settle, a 90° turn that overshoots, or a car left pinned. `godot --headless --path game --script
res://tools/check_settings.gd`: the settings round trip, the defaults, and that `--nosave`
writes nothing (scratch files only).

Screenshots: `shots/loop2a_*.png` at 1920×1080 (`_1920`) and the iPhone's 2532×1170
(`_iphone`): the settings panel, each scheme's on-screen controls (`point`, `classic`,
`fixed`, the stick held), the default driving view before (110 m, Busy) and after
(`view_before` / `view_after`), and the four traffic levels on Marszałkowska 20 s after the
start (`traffic_empty|low|normal|busy`).

## Loop 2b: frame rate on the iPhone (2026-10-28)

The user's iPhone 16 Pro Max (iPhone17,2, A18 Pro, 2868×1320, so a 1434×660 pixel image at
High) showed 16 fps at the default view over the river (6,747 draw calls, 0.34 M triangles),
14 fps zoomed out (7,191 draw calls) and 13 fps from the helicopter (7,672): the frame grew
with the draw calls (~10 µs each), not the triangles. Those readings came from a game started
with Xcode's Run. Started on the phone with `xcrun devicectl` (no debugger), the same code ran
at the display's 120 Hz with 6,771 draw calls in the street views (64 fps, 1 % low 30, from the
helicopter), and 18.9 fps with Metal API validation switched on as Xcode's Run has it: the cost
per draw call is what Xcode adds, and 6,500 of those draw calls were the minimap. `tools/export_ios.sh` now switches validation and GPU frame capture off in
the Xcode scheme, and the frame has ~125–250 draw calls either way.

**Where a frame went (before, ranked).** Measured with the new `--probe` at five places (the
spawn, Marszałkowska, the Palace from the north-west, Most Poniatowskiego over the river,
Rondo Dmowskiego), by day, at night and at night in the rain, on the Mac (M4 Pro) at
2532×1170 (and the phone's three views at its 2868×1320), Metal for the frame and the counters
(the same counters the phone's overlay shows: they match its readings within a few per cent),
Vulkan for the GPU's passes (`--gpu-profile`):

| # | Cost | Before | Why |
| --- | --- | --- | --- |
| 1 | The minimap | 6,533–6,542 of 6,590–7,044 draw calls (the 2D pass), at every place and zoom; the Mac's main thread spent 2.5 ms a frame handing them over (0.75 without the minimap), the GPU 0.9–1.0 ms | every street, park and pond of the whole map drawn as its own polyline or polygon, every frame, under a `clip_children` clip |
| 2 | The sun's shadow | shadow pass 126–347 draw calls, 2–4 × the main pass; GPU 0.5–1.0 ms by day, 2.35 ms zoomed out; a 4096 map at ~0.49 m a texel | Godot ignores the light's max distance for an orthographic camera and shadows its whole depth: the far plane was 1,500 m past the view, so the shadow map covered a sphere ~2 km across and drew every caster in it |
| 3 | The main pass's objects | 47–175 draw calls; GPU 1.1–1.8 ms (2.6 zoomed out) | the Mobile renderer has no automatic instancing: every node is a draw call. 128 m tiles × 3 meshes (ground, walls, LoD2 buildings), 256 m tiles × 11 instanced kinds, the player's car as 18 boxes with 18 materials |
| 4 | Pedestrians on bridge decks | 1.0 ms of script at the river (0.08 elsewhere) | the deck solver asked per walker per frame |
| 5 | The other scripts | 0.6–0.9 ms (traffic 0.24, trams 0.09, people 0.09, HUD and minimap 0.12–0.18, the game loop 0.1, the rest under 0.05) | |
| 6 | Transparent passes (the post pass, glow, halos) | GPU 0.18 ms by day, 0.25–0.46 at night, 0.42–0.62 in the rain | at the pixel image's size already |
| 7 | Physics, tonemap, memory | physics 0.13–0.17 ms; tonemap 0.04 ms; 221 MB static, 330–364 MB video | |

Full-screen passes at screen resolution are the scale-up container (one textured quad) and the
VHS overlay when it is on: both cheap next to the above, and VHS's scanlines are meant to be
screen pixels, so they stay.

**What changed, per cost.**

1. **Minimap** (`hud.gd`): the streets, parks, water, the map's edge and the Palace's dot are
   built once into one 2D mesh, the same triangles `draw_polyline` / `draw_colored_polygon`
   made, drawn with one call; a four-line shader cuts it to the circle (no `clip_children`).
   It looks the same (`shots/` pairs: the only differences are the city behind it). 6,540 → 1
   draw call. (A one-time texture was tried first: it smeared the lines when the map turns.)
2. **Shadow** (`main.gd` `_camera_far`): the camera's far plane now ends 130 m past the lowest
   ground the view can show (the river below the city, the slab's walls), and its depth is
   chosen so the shadow's bounding sphere keeps one size while the view widens with speed (or
   the shadows' pixel edges would crawl): it changes only with the zoom. The shadow map is
   2048 on High (was 4096) and 1024 on Medium (was 2048): over the smaller sphere 2048 gives
   0.37 m texels, finer than 4096 gave (0.49 m). Things under a metre tall (benches, bins, bike
   racks) cast no shadow (a few texels at most); on Medium only buildings and trees do. Shadow
   pass at the spawn 186 → 35 draw calls, zoomed out 347 → 60; GPU 0.55 → 0.14 ms, zoomed out
   2.35 → 0.26 ms. The look: the same shadows with slightly finer pixel edges (the day pairs
   differ in 4–6 % of pixels, mostly along shadow edges).
3. **Objects** (`chunked_surface.gd`, `map_builder.gd`, `car.gd`): city tiles of 256 m (were
   128), each tile's LoD2 buildings in the same mesh as its other walls (one draw call, not
   two), instanced things in 512 m tiles (were 256): one MultiMesh is one draw call and the
   triangles of a bigger tile cost the phone nothing it notices. The player's car is one mesh
   with vertex colours plus one per lamp pair (3 draw calls, was 18; same colours and shading).
   Benches, bins and bike racks hide in a view wider than 170 m, where a bin is under two
   pixels (`fine_detail` group). Vertices unchanged: 6,055,540.
4. **Pedestrians** (`pedestrians.gd`): a deck footway's heights are sampled every 4 m once and
   interpolated: 1.0 → 0.08 ms at the river.
5. **The overlay** is cheaper (twice a second, no per-frame clock reads of its own) and shows
   what matters (the main thread's split and draw calls by pass); see Water, weather and sound.

Not changed, measured and kept: the post pass (outlines, reflections, rain) and glow run at
the pixel image's size already; the occlusion ghost, the river, the landmarks and the night
lights are untouched.

**Before → after** (the same places, Mac M4 Pro at 2532×1170, `--probe` medians over 1,500
frames, Metal frame and counters, Vulkan GPU passes; the night has no sun shadow):

| Place | Time | Draw calls, 3D + shadow + 2D: before → after | Metal frame (ms) | Vulkan GPU (ms): total (shadows / opaque / 2D) |
| --- | --- | --- | --- | --- |
| Spawn | day | 6,847 (92 + 222 + 6,533) → 145 (53 + 35 + 57) | 3.52 → 1.86 | 3.15 (0.73 / 1.30 / 0.98) → 1.21 (0.21 / 0.60 / 0.16) |
| Spawn | night | 6,637 (104 + 0 + 6,533) → 121 (64 + 0 + 57) | 3.55 → 2.28 | 2.68 (0.00 / 1.52 / 1.01) → 1.06 (0.00 / 0.75 / 0.17) |
| Spawn | night, rain | 6,637 (104 + 0 + 6,533) → 122 (64 + 0 + 58) | 3.50 → 1.96 | 3.13 (0.00 / 1.42 / 0.98) → 1.23 (0.00 / 0.71 / 0.16) |
| Marszałkowska | day | 6,789 (87 + 167 + 6,535) → 140 (48 + 33 + 59) | 3.49 → 1.54 | 3.37 (1.00 / 1.12 / 0.91) → 1.21 (0.24 / 0.64 / 0.17) |
| Marszałkowska | night | 6,634 (99 + 0 + 6,535) → 117 (58 + 0 + 58) | 3.58 → 2.13 | 3.18 (0.00 / 1.42 / 1.05) → 1.26 (0.00 / 0.80 / 0.20) |
| Marszałkowska | night, rain | 6,634 (99 + 0 + 6,535) → 118 (58 + 0 + 59) | 3.44 → 1.71 | 3.09 (0.00 / 1.56 / 1.01) → 1.32 (0.00 / 0.68 / 0.16) |
| Palace (NW) | day | 6,740 (81 + 126 + 6,533) → 158 (62 + 39 + 57) | 3.39 → 1.50 | 3.18 (0.48 / 1.40 / 0.99) → 1.24 (0.19 / 0.63 / 0.16) |
| Palace (NW) | night | 6,624 (91 + 0 + 6,533) → 131 (74 + 0 + 57) | 3.33 → 1.49 | 3.44 (0.00 / 1.68 / 0.98) → 1.03 (0.00 / 0.68 / 0.15) |
| Palace (NW) | night, rain | 6,624 (91 + 0 + 6,533) → 131 (74 + 0 + 57) | 3.33 → 1.54 | 3.27 (0.00 / 1.50 / 0.97) → 1.33 (0.00 / 0.70 / 0.15) |
| Most Poniatowskiego | day | 6,765 (47 + 183 + 6,535) → 119 (35 + 24 + 59) | 4.36 → 1.94 | 3.42 (0.56 / 1.49 / 0.86) → 1.24 (0.15 / 0.65 / 0.13) |
| Most Poniatowskiego | night | 6,590 (55 + 0 + 6,535) → 101 (43 + 0 + 58) | 4.28 → 1.85 | 3.69 (0.00 / 1.84 / 0.91) → 1.21 (0.00 / 0.75 / 0.13) |
| Most Poniatowskiego | night, rain | 6,590 (55 + 0 + 6,535) → 102 (43 + 0 + 59) | 4.25 → 1.52 | 3.40 (0.00 / 1.77 / 0.89) → 1.33 (0.00 / 0.76 / 0.12) |
| Rondo Dmowskiego | day | 6,848 (96 + 217 + 6,535) → 163 (57 + 47 + 59) | 3.85 → 2.67 | 3.54 (0.69 / 1.38 / 0.99) → 1.22 (0.22 / 0.59 / 0.14) |
| Rondo Dmowskiego | night | 6,651 (115 + 0 + 6,536) → 132 (73 + 0 + 59) | 3.74 → 1.96 | 3.31 (0.00 / 1.64 / 1.05) → 1.06 (0.00 / 0.78 / 0.18) |
| Rondo Dmowskiego | night, rain | 6,650 (115 + 0 + 6,535) → 133 (73 + 0 + 59) | 3.61 → 2.35 | 3.47 (0.00 / 1.61 / 1.00) → 1.25 (0.00 / 0.72 / 0.15) |

The Mac is not the target: its uncapped frame halves, but the phone pays per draw call.

**On the phone** (iPhone 16 Pro Max, started with `devicectl`, no debugger; `--probe` for 10 s
after a short settle, Quality High, traffic Normal, Classic, day; "before" = the code before
this round with only the bench added; the last column with Metal API validation on, as Xcode's
Run has it, `MTL_DEBUG_LAYER=1`):

| View | Draw calls (3D + shadow + 2D) before → after | Before (no debugger) | After | Before / after with Metal validation |
| --- | --- | --- | --- | --- |
| Default, 80 m, over the river | 6,771 (47 + 182 + 6,542) → 124 (35 + 24 + 65) | 120 fps (the display's limit) | 60 fps (the cap), 1 % low 57.4, worst 17.5 ms; main thread: process 3.3, physics 0.6, draw 2.0 ms | 18.9 fps (53 ms, 47.6 of it handing over draw calls) / 60 fps, 1 % low 58.3 |
| Zoomed out, 220 m | 7,020 (131 + 347 + 6,542) → 191 (66 + 60 + 65) | 120 fps | 60 fps, 1 % low 57.9, worst 17.3 ms | |
| Helicopter, 150 m | 7,045 (175 + 334 + 6,536) → 245 (100 + 86 + 59) | 64 fps, 1 % low 29.7, 28 % of frames over 16.7 ms | 60 fps, 1 % low 57.9, worst 17.3 ms | |
| `--bench` route | never finished (it sat on the title screen: the launcher ate the `--`) | | 60 fps, 1 % low 57.5, 154 draw calls, ends by a 30 s cap | |
| TEST · BENCH, one minute | | | 60 fps, 1 % low 57.0, worst 17.9 ms, 60 in every 10 s, 168 draw calls | |

Run order on the phone: after (an earlier build of this round) default, zoomed, helicopter, the
frame-rate cap tests, `--bench`, Medium, Low; before default, zoomed, helicopter, default with
validation; then the final build: default, zoomed, helicopter, default with validation, the
one-minute BENCH. No run lasted over a minute; the BENCH's fps per 10 s stayed at 60 (no
throttling seen). Medium and Low: 118 and 99 draw calls, image 956×440, 60 fps.

So the user's 16 fps (from Xcode) was 6,800 draw calls × Xcode's Metal validation; the old
build started from the home screen held 120 Hz in the street views and dropped to 30 in the
helicopter's. With ~125–250 draw calls the game holds 60 either way.

**Frame rate** (Settings → Klatki na sekundę · Frame rate, `settings.gd` `fps`, `--fps=`): 60 by
default, 30 as a battery saver. The iPhone 16 Pro Max has a 120 Hz display; the game used to
ask for it (Godot's `display/window/ios/allow_high_refresh_rate` defaults to on) and ran its
frames twice as often, warm. `project.godot` now turns that off, so iOS runs it at 60 Hz, and the
60 setting leaves the pacing to the display: on the phone `Engine.max_fps = 60` on top of it
left 7.8 % of frames slightly late against 4.6 % without it. 30 sets `Engine.max_fps = 30`
(measured: 30.0 fps, 1 % low 27.6, worst 36 ms). On the Mac the setting is `Engine.max_fps`.
`--bench` and `--probe` run uncapped.

**TEST · BENCH** (the performance overlay, Settings → TEST, `--bench-button`): the car rides
the bench route's ghost driver from the spawn at the default view for 5 s to settle and 55 s
measured, at the current quality, traffic, time, weather and frame-rate cap; nothing else
starts on the way (no side job), the wallet is put back as it was and not saved, the car goes
back where it was. A countdown runs in the toast line; opening Settings cancels it. Then a card
(Polish over English, 44 pt buttons) shows the result, KOPIUJ · COPY puts it on the clipboard,
ZAMKNIJ · CLOSE hides it, and it is written to `user://bench_result.txt` too (the app's
Documents folder on the iPhone). The card from the phone (`bench.gd`):

```
NOCNA WARSZAWA bench (loop 2b) · BENCH button · 2026-10-28 14:52:02
device iPhone17,2 · iOS 27.0.1 · Apple A18 Pro GPU (Apple9) (metal, mobile) · Apple A18 Pro
screen 2868x1320 @ 120 Hz · image 1434x660 · view 80 m · quality High · traffic Normal · Day · Clear · cap 60 fps · Classic
thermal state: not readable from Godot; a phone that warms up shows it as falling fps per 10 s
fps 60.0 avg · 1% low 57.0 · worst frame 17.9 ms · 6.3% of frames over 16.7 ms · 3300 frames in 55 s
fps per 10 s: 60 60 60 60 60 60
frame 16.67 ms · main thread: process 3.96, physics 0.49, draw 11.55 · 3D view: render CPU 0.58, GPU n/a (Metal)
draw calls 168 · objects 796 · triangles 0.39 M (all passes, as the overlay counts them)
main pass: 46 draws, 46 objects, 0.19 M tris · shadow pass: 41 draws, 41 objects, 0.13 M tris · 2D: 82 draws
scripts 3.77 ms: traffic 1.53 · traffic bodies 0.14 · trams 0.47 · people 0.36 · rivals 0.06 · jobs+eggs 0.15 · jobs physics 0.00 · sound 0.09 · hud+minimap 0.39 · bubbles 0.05 · dialogue 0.00 · weather+time 0.00 · car physics 0.14 · heli 0.00 · game loop 0.38
cars on screen 33 · driving 51 · people 48
memory: static 114 MB · video 335 MB (textures 24, buffers 155) · 3 pipeline compilations
```

The device model is `OS.get_model_name()`; Godot 4.7 has no
thermal API, hence the fps per 10 s. GPU time is n/a on Metal; with the display at 60 Hz the
main thread waits for it inside "draw", so a big "draw" share (11.6 ms above) is waiting, not
work: process + physics is the CPU's work. A frame counts as "over" when it is more than 0.5 ms past the budget.

**Expected to matter more on the phone than on the Mac.** Draw calls above all: the Mac hands
over 6,800 draw calls in ~2.5 ms, the phone under Xcode took ~60 ms, and even without the
debugger every call costs the phone's CPU several times the Mac's; the per-call savings (the
minimap, the shadow's casters, bigger tiles, the car) are what the phone feels. The shadow map
(4096 → 2048, a quarter of the memory traffic for its depth every frame) matters more on a
tile-based phone GPU that writes it to memory than on the Mac's. The 120 → 60 Hz cap halves the
phone's work per second; the Mac has no such thing to save. The script savings (the deck
pedestrians) count about 4–5× on the phone: GPU-less GDScript time measured 0.6–0.9 ms on the
Mac and 3.2–4.6 ms on the phone at 60 Hz, where iOS runs the CPU at lower clocks.

**The parked car** (`car.gd` `parked`): while the player flies, and on the title screen, the
game parks the car with the brake on, and a held brake at a standstill reverses, so the parked
car backed ~40 m away into a wall and was "turned out of the wall" every 1.5 s for the whole
flight (99 lines in `--mission=1 --heli --autopilot --fixed-fps 60 --quit-after 12000`). A car
the game has parked now holds still and never counts as pinned; a player holding BRAKE to
reverse still does. The log is clean (0 lines) and `check_steering.gd` passes.

**Known issues.** The device log starts with `ERROR: Mouse is not supported by this display
server` (display_server.cpp:536): it comes from the engine before any game script runs (no
script asks for the mouse, and switching touch-from-mouse emulation off on mobile didn't stop
it); harmless. The phone's GPU time can't be read (Metal), and at 60 Hz the main thread waits
for the display, so the phone's headroom under 16.7 ms isn't visible (a build that allows
120 Hz would show it as fps over 60; the old build managed 64 fps from the helicopter, the new
one's GPU work there is a quarter of the old on the Mac). The Mac's worst single frame in the
bench reads 17–20 ms (9–20 before) while the averages halved: one-off spikes, probably
first-sight pipeline compiles. With the 60 cap on the Mac's 120 Hz display (`Engine.max_fps`)
~20 % of frames come a little late; on the iPhone the display paces it.

Screenshots: `shots/loop2b_*.png` at 2532×1170: before/after pairs at High (`_before` from the
code before this round) at `spawn`, `marszalkowska`, `palace`, `river`, `rondo`, `_day` and
`_night`; `quality_high|medium|low` (with the overlay); `bench_card` (the result card on the
Mac).

## Loop 10a: the river is off-limits (2026-10-28)

After the user's play on the iPhone: "the car can drive on water, why so" (the hatchback at
0 km/h in the middle of the Vistula, and crossing it at 91 km/h). Over the river the terrain is
the water's flat surface, so a car that got onto it drove anywhere on it at full speed.

**How it got there, measured** (`game/tools/check_water.gd`, the whole map, before → after):

| | before | after |
| --- | --- | --- |
| The water's edge a car drives through at ground level (every 2 m round every water body, the car's box driven at it from the land, straight and 40° either side) | 807 m open in 45 places | 0 |
| ... under or beside a bridge: the bake leaves the shore wall open within 6 m of any deck, so from the boulevard under a bridge the car rolled into the river (Most Świętokrzyski west 15 m and 8 m by the map's rim; the railway bridge 32 m west, 35 m east and 65 m round the pond under it; Most Poniatowskiego 12 m west, 43 m east) | 9 places, 209 m | 0 |
| ... fountains (no edge at all) | 35 of 40, 586 m | 0 |
| ... a road ending at a canal (1343, 763), a seam between two baked runs (1140, 105) | 8 m, 4 m | 0 |
| The real car (`car.gd`) at 91 km/h flat out at the edge every 10 m, after 1.5 s | 11 of 631 in the river (all at bridges; no wall was tunnelled through) | 0 of 631 |
| Off a bridge deck's side or end onto the water (1,353 probes) | 0 | 0 |
| Helicopter: landing to take the car back allowed over the water (every 20 m; only a roof stopped it) | at 1,251 of 1,256 points | 0 (refused at all 1,256; allowed on the 39 deck points over it) |
| The car's free spot next to a landed helicopter or a tow, round the water's edge | in the water for 1,252 of 2,478 (and mid-river: the spot itself) | 0 |
| Lane-graph lanes / tram tracks at ground level in the water | 0 / 0 (1 lane point at Świętokrzyski's end past the edge walls) | the same |
| Footways people walk into the water | 10 footways (24 points; ponds, fountains, a beach path) | 0 (5 end a metre short of it, 9 nobody walks) |
| Anything that took the car out of the water | nothing | the tow, from every point (0 of 634 tows off a lane or wet) |

So the user's car most likely came down with the helicopter onto the river (the car is put next
to it), or rolled in under a bridge from the boulevard, and then drove the river's flat surface.

**What changed.**

- **The edge** (`map_builder.gd` `_build_shore_stone`, `_build_shore`): a low granite edge
  (0.45 m over the ground, 0.5 m wide, on the water's side of the line) round the river, the
  ponds and the 40 fountains, 9.4 km, laid on the ground like the kerbs: in the ground's mesh,
  so no new draw call and no shadow. Its collider stands on the line, 3 m up, under any deck
  above it, in 2 m pieces with the ground's height at each end. Along the bake's `shore` runs
  plus the stretches the bake left open by bridges wherever the deck is at least 3.2 m up (under
  all four bridges and beside them), the canal's slipway and the seam. The map's rim stays open
  (the edge walls close it).
- **The water test** (`map_builder.shore_distance`, `in_water`): the surface map's shore
  distance (water.bin's R channel), kept on the CPU and stored zstd-packed in `city.scn`, read
  bilinearly; a vehicle is in the water 2.5 m past the edge (so a car stopped by the stone, its
  centre a metre or two inland, never counts) and down at the water's level (a bridge deck
  over the river is not the water). One call per physics frame for the player's car: 0.8 µs on
  the Mac.
- **In the water** (`car.gd`): the car splashes once (`splashed`), takes no gas or steering,
  loses speed at 4/s (from 91 km/h it stops within ~6 m), settles 0.45 m nose first and bobs.
  A car with its collision off (the testing autopilots, the bench's ghost) or parked never
  splashes.
- **The splash** (`splash.gd`): 56 droplets thrown up and forward and a ring of 22 foam pieces
  spreading on the water, 1.3 s, boxes in one MultiMesh with the actors' material (no new
  shader; one draw call while it plays, none after, no shadow); the sound (`sfx.gd` `splash`)
  is the hard knock pitched down and a 0.9 s wash of the rain bed's noise: no new file; a buzz.
- **The tow** (`main.gd` `_tow_out_of_water`): 1.0 s after the splash the car is put on the
  nearest lane on the level it came from (where it last stood on dry land or a deck), else the
  lane nearest to the nearest dry land, else the nearest junction; on the free spot there, never
  in the water. A toast from the tow crew, Polish over English (`dialogue.json` `water_tow`,
  `river` / `pond`; the HUD's toast now takes an English gloss under its line): "Wisła nie jest
  drogą krajową." / "The Vistula is not a national road." No money is taken and nothing
  fails: a rescue, a delivery or a race carries on (`splash` in `tools/verify.sh`: a kebab
  delivery running, towed after 1.00 s to a lane 51 m away, the job still on, the wallet
  unchanged).
- **The helicopter** won't come down to give the car back over the water ("Tu nie wylądujesz:
  to woda. Szukaj brzegu." / "No landing on the water: find the bank."); it still flies over
  it, and lands on a bridge deck over it. The car's free spot next to a landed helicopter or a
  tow (`_free_car_spot`) is on the level of the spot (it was the top deck over each candidate:
  a tow under a bridge put the car up on the bridge) and never in the water; the stuck tow's
  "its level" is now the ground for a car on the ground (any lane on the terrain) or within 4 m
  on a deck.
- **People** (`pedestrians.gd`): a footway that runs into the water at an end stops a metre
  short of it (people turn back there); one that crosses water in between isn't walked. Worked
  out the first time someone could walk it (every 0.5 m).

**Checks.** `godot --headless --path game --script res://tools/check_water.gd` (~17 s; `--
--prebuilt` checks the exported game's `city.scn`, its colliders and stored water map, ~10 s;
`--verbose`, `--list=OUT.txt` for every gap sample, `--debug=X,Z` for every probe step near a
point) prints the five parts above and `check_water: OK`; both are steps in `tools/verify.sh`
(`water`, `water-prebuilt`), with the game run `splash` (`--drive-into-water=1015,-85
--kebab=0`: into the river from the boulevard by Most Poniatowskiego; PASS needs the tow within
2 s, on dry land by a lane, the job still on). Godot's `cast_motion` misses some of the concave
collision shape's thin walls, so the probe steps the box 0.5 m at a time and tests for overlap.

**Cost** (README's commands; Mac): the bench route (day, medians of 3) 8.33 → 8.33 ms a frame
(120 Hz display cap), scripts 1.66 → 1.66 ms, draw calls 134 → 134 (the bench's ghost car has
its collision off, so the water test doesn't run there); the probe at the four views (Metal,
2868×1320): spawn 152 → 153, default view over the river 124 → 124, zoomed out 189 → 191 (the
3D and shadow passes equal; the HUD's 2D pass 63 → 65), helicopter 245 → 245; car physics at
the river 0.05 → 0.05 ms; main-pass triangles at the river 0.19 → 0.20 M; the city's meshes
3,697,284 → 3,742,512 vertices (+1.2 %); `city.scn` 35.9 → 36.3 MB.

**Known issues.** The splash and the tow were judged on the Mac (screenshots, logs); how they
feel on the phone, and whether the splash reads at the default view, is the user's to say (the
sound was not heard: headless runs have no audio). The stone is the same granite edge
everywhere, the Praga beach included. A car that rolls in at a few km/h can stop with its
centre less than 2.5 m past the edge (the shallow first metres) and sit there until it drives
out; the stone makes that hard to reach. The minimap is unchanged (no lane is on the water).

Screenshots: `shots/loop10a_*.png` at 2532×1170: the shore at Most Poniatowskiego's west
boulevard (`poni`), the Praga beach by the stadium (`beach`) and Most Świętokrzyski (`swieto`),
`_day`, `_night` and `_day_prebuilt`, with `_before_*_day` from the code before this loop; the
splash (`splash`, `splash_night_prebuilt`), the tow's toast (`tow_toast`) and a fountain pool's
new edge (`fountains_day`, at -1075, 170).

**On the iPhone** (16 Pro Max, launched with `devicectl`, prebuilt city): the water test from
the boulevard splashed at 62 km/h and was towed 1.01 s later onto a lane 51 m away, dry, the
kebab job still on; standing on that boulevard (`--probe --at=1015,-85 --heading=45`): 60 fps
(the cap), 1 % low 55.3, worst frame 18.6 ms, 141 draw calls, car physics 0.15 ms.

## Loop 3a: roads I, the check and the bake (2026-10-28)

After the user's play on the iPhone: "I see huge problems with the estakady and roads in some
places". Their screenshot was Most Poniatowskiego's east end: Wybrzeże Szczecińskie passed
under the deck with 1.3 m to spare. docs/DEMO.md section 4 lists the classes of defect and their
causes (R1-R9); this loop built the whole-map check and fixed the causes that live in the bakes
(the builder's side, R5-R7 and buildings under decks, is loop 3b).

**The check** (`tools/check_roads.py`, standard library, ~4 s for the whole map): rules C1-C10
of DEMO.md 4.5, mirroring the game's height rules (the terrain's triangles and the approaches'
fills, `deck_height`, `drive_height`, the tunnels, lane_graph.gd's lane heights). Each finding
prints with map coordinates and its `--at=`; allowed ones are listed with a reason and a source
in `tools/check_roads_allow.json`; it writes `shots/check_roads.json` and
`shots/check_roads.png` (the findings over the orthophoto) and exits 1 on a finding not
allowed (3 when the only ones left are in the `--later` rules). `tools/verify.sh` step `roads`:
FAIL on C1-C3 and C6-C8, WARN on C4, C5, C9, C10 until loop 3b; it prints the counts.

| Rule (DEMO.md 4.5) | Today's map before | After | |
| --- | --- | --- | --- |
| C1 grade (> 12 % over 6 m, service 20 %) | 85 roads | 32, all allowed | Oboźna (the escarpment, real); 5 pits at junctions; 21 minor service ways |
| C2 joints (> 0.15 m at a shared vertex) | 0 | 0 | |
| C3 clearance under a deck (< 4.7 m; footways < 2.5 m) | 249 samples in 17 places | 54 in 7, all allowed | footbridges mapped schematically (Centralna, the science centre's roof), a footway along the viaduct ramp, the WKD cutting |
| C4 piers on a road, tram or rail | 31 of 161 piers | 31 of 171 | loop 3b (R5) |
| C5 roads and lanes through solids | 46 | 50 | loop 3b (the Arkada and the viaduct's LoD2 arcades, palace courtyards' service roads) |
| C6 deck ends in the air (> 1 m) | 4 (+6 at the rim) | 0 (+5 at the rim) | |
| C7 drivable tunnels and cuttings dropped | 9 | 0 | |
| C8 lane steps (> 0.5 m in 4 m) / edges meeting apart (> 0.2 m) | 19 edges / 12 nodes | 5 / 0, all allowed | Złota, Salezego, Oboźna |
| C9 buildings through a deck | 58 | 57 | loop 3b (mapped pillars under the Jana Pawła II viaduct, the Poniatowski viaduct's LoD2 arcades) |
| C10 landmark colliders by a lane | 1 | 1 | loop 3b (R7: a Poniatowski tower 0.3 m from lane 2) |

**What changed in the bake** (`tools/bake_roads.py`, `tools/bake_osm.py`):

- **Structure chains (R1).** A bridge is solved together with the ways that belong to it: the
  non-bridge ways between two bridge ways within 150 m (the abutments), embankments
  (`embankment=yes`, or 2 m above the terrain 15-25 m to both sides over most of the way: the
  railway across Powiśle) and the ways onto a bridge whose terrain within 40 m is steeper than
  12 % (the 10 m grid blurs the abutment's wall into a slope). Each family (rails, roads, then
  tram tracks and footways) is one graph of nodes every 6 m, solved by projected
  over-relaxation: smooth, never under the terrain, pinned only where a structure meets an
  ordinary way, the approaches pulled onto their terrain beyond 30 m from a bridge. Most
  Poniatowskiego's deck now runs at the abutments' level, -4.6 m at the west end to -5.7 m at the
  east (it dipped to -13.5 m at the ends), the viaduct climbs evenly to the escarpment, the
  railway runs on its embankment at -5 m over Kruczkowskiego and Solec. 26 bridge roads, 24
  approach roads, 39 rail ways.
- **Approaches are fills, not decks.** A structure way that is not a bridge corrects the ground
  under its corridor (`fills` in `centrum.json`: 80 pieces): `map_builder.terrain_height` is the
  higher of the terrain grid and a fill there, so the road, its kerbs, markings, carriageway
  areas, the lanes and the car all sit on the solved profile, and the bridges' decks meet them
  exactly. Where a fill stands above the grid (the blur at an abutment) a plain concrete face
  runs down each side (loop 3b turns these into retaining walls).
- **Pits.** The same fills bridge narrow pits of the bare-earth grid a street crosses at grade
  (underground stairwells, garage and construction pits): each road's terrain profile is closed
  over 20 m and filled where it stands 0.4 m or more above the grid, except where another way
  enters (98 stretches).
- **Hard clearance (R3).** 5 m over roads, rails and trams, 7.5 m over the river, 2.6 m for a
  footbridge over a footway, as lower bounds the solver never crosses; where one can't be met
  within 12 % of a pin the road under it dips (at most 2 m, 8 % ramps: written as `dips` for
  loop 3b to lower the ground; none was needed on today's map) and anything more fails the bake
  with the list of places. Ways in a cutting (`layer` < 0, the WKD
  by Centralna) are skipped and logged; footbridges and tram tracks that fall short are logged
  (C3 judges them).
- **Tunnels (R4).** `tunnel=yes` drivable ways are kept as tunnel pieces (`tunnels` in
  `centrum.json`: `pieces`, the `roads` with their `tn`, and the `portals` where a tunnel meets
  open road): 6 m under the terrain, ramps of at most 8 % from the portals. The Wisłostrada
  tunnel (both carriageways from the portal at 637, -554 to the map's north edge), the link under
  Most Poniatowskiego's west abutment and a short tunnel on Warecka. Ways below ground that are
  no tunnel (`layer` < 0: cuttings) are ordinary roads now. The game doesn't draw or drive the
  tunnels yet (loop 3b): their lane-graph edges have their heights but stay out of the
  adjacency, routing, spawning and snapping (`lane_graph.gd` `TUNNELS_DRIVEN`), so the trench at
  the portal is still a dead end, now marked.
- **Lanes know their deck (R8).** Every lane-graph edge on a bridge carries its deck group
  (`dk`), in a tunnel its tunnel (`tn`); `lane_graph.gd` takes its heights from that piece only
  (`surface`), never "the highest deck over the point"; the side jobs' road height uses it too.
  The lane height's last 8 m knot is now at the edge's end (edges met a few tenths apart on
  slopes).
- **Garage ramps (R9).** A service way that dives into a garage (from its end that meets a road,
  the terrain falls 2 m within 30 m, somewhere steeper than 20 %) ends at the ramp's top; a
  garage door is written there (`garages`: x, z and the way in, 27 of them) for loop 3b.
- **R2 hook.** `bake_roads.SurfaceModel` reads the 0.5 m surface model and 1 m terrain (DEMO.md
  4.4) as ASCII grids once `data/raw/demo/MANIFEST.md` is there; until then the chain solver
  works alone (the plan's fallback). The corridors now arriving are GeoTIFF, which it doesn't
  read yet.

**Testing aids.** `--debug-roads` draws the decks' corridors at their height (orange roads,
yellow footways, red tracks), the approaches (green), the tunnels (magenta), every lane at the
height traffic uses (blue) and the piers (cyan boxes) round the car, with the Debug Draw add-on
(`game/addons/debug_draw`, HardPixel, MIT; CREDITS.md); `tools/road_spots.txt` lists the road
render spots and `tools/shots.sh --set=roads [--game=DIR] [--tag=...]` renders them (frame 90,
`--no-traffic --fixed --size=70`). `NW_DECK_DEBUG=X,Z,R` makes the bake print the solver's nodes
(height / terrain / lower bound) near a point.

**Cost** (Mac, README's commands, the code before this loop run alongside from a copy). Other
agents' Godot runs overlapped the bench, so its frame times spread 1.6-7 ms on both sides and
say nothing; the counts do. The probe (Metal, 2868×1320), draw calls before → after: spawn 151 →
154 (3D 53 → 53, shadow 35 → 35, the HUD's 2D pass 63 → 66), the default view over the river
126 → 126, zoomed out 191 → 190, the helicopter 245 → 242, Most Poniatowskiego's east end 126 →
126; main-pass triangles unchanged (0.25 / 0.19 / 0.36 → 0.37 / 0.31 M). Scripts on the bench
route (medians of 3, interleaved): 0.67 → 0.67 ms by day, 0.73 → 0.60 at night, 0.68 → 0.62 in
the rain at night (lane heights are still sampled once per edge). Vertices 6,115,198 →
6,144,280 (+0.5 %; meshes 3,742,512 → 3,771,594: the approaches' side faces and the new deck
slabs). `centrum.json` 4.96 → 5.04 MB, `city.scn` 36.3 → 36.5 MB. The runtime city build 7.0 →
7.8 s (`terrain_height` looks the fills up for every draped vertex); the prebuilt city loads in
0.84 s as before.

**Known issues** (BACKLOG "From loop 3a"): decks still too low where something mapped stands
under them (C9: the Jana Pawła II viaduct's pillars, the Poniatowski viaduct's arcades), which
the surface model (R2, arriving as GeoTIFF) or the pillars as lower bounds would fix; the
approaches' sides are plain faces until loop 3b's walls; tunnels and garage doors are data only;
21 minor service ways and 5 junction pits keep a steep bit of the 10 m grid (allowed).

Screenshots: `shots/loop3a/*_before_2532x1170.png` and `*_after_2532x1170.png` at the eight
road spots (`tools/road_spots.txt`), `poniatowski_{west,east}_{before,after}_prebuilt_*` on
the prebuilt path, `poniatowski_east_debug_roads_*` (`--debug-roads`);
`shots/check_roads_baseline.png` and `shots/check_roads.png` (the findings over the orthophoto,
before and after).

## Loop 2e: the HUD at phone size (2026-10-28)

Loop 2a found that, outside the settings panel, the HUD was sized in 720-line units: on the
user's iPhone 16 Pro Max its top buttons were 27 pt tall and its text 9 pt (24 pt and 8 pt on a
6.1" phone; Apple's smallest comfortable tap is 44 pt), and the top row held TIME, RADIO, VHS,
RAIN, HELI, STYLE, CAM, `<` `>` `−` `+` and a RESCUE CALLS card at the start.

**In points.** `screen_points.gd` gives the screen in points (3 px each on these iPhones) and
its safe area (the Dynamic Island or notch, the rounded corners, the home indicator). On a
computer a window the size of a known iPhone gets that phone's points and insets (2868×1320 is
the Pro Max: 956×440 pt, 62 pt each side, 21 at the bottom; 2532×1170 the 6.1": 844×390 pt,
47 and 21); any other window is taken as a phone 390 pt tall with no insets. iOS insets both
sides alike in landscape, so the layout holds turned either way. Every tappable control is at
least 44 pt; the text is on one scale (`hud.gd` `T_*`): 44 pt the race banner, 22 the status
clock, 17 titles and toasts, 15 body, 13 secondary and English lines (body text never below
13), 11 labels.

| On the phone (Pro Max / 6.1") | before | after |
| --- | --- | --- |
| Top-row buttons | 27 / 24 pt tall | 44 pt (the gear 44×44) |
| Text | 9 / 8 pt (top buttons), 6–10 pt elsewhere (cards, ticker, bubbles, the credit line) | 11–17 pt (44 the banner) |
| Settings panel text | 8.6–16 / 7.6–14 pt | 11–22 pt |
| Minimap | 88 / 78 pt across | 96 pt |
| BRAKE (Point) | 71 / 63 pt across, a 1-px ring | 72 pt on a plate (touch 92 pt) |
| Stick reach | 43 / 38 pt | 42 pt |

**The first screen** (docs/DEMO.md 6.1): the gear and the speed top left; WEZWANIE · rescue
call in the middle of the top row, only when a call has come in; RADIO (the station under it)
and HELI / AUTO top right; the minimap and the wallet under the gear; HAMULEC · brake (Classic:
GAZ · gas, HAMULEC and the steering strip's place) bottom right; the credit line bottom left.
No "prototype" label and no call card at the start: the first call comes in 60 s into play
(`--call-in=S`), the next 90 s after each one ends or is put off (`missions.gd` `FIRST_CALL`,
`NEXT_CALL`, first guesses), with a toast and a buzz. The helicopter is there from the start
(the user's decision, 2026-10-28).

**Moved into Settings** (four tabs, so the panel fits a phone 390 pt tall without shrinking):
Jazda · Driving: Controls (Point / Classic, with a line on what the scheme does) and "Kamera za
autem · Camera follows the car" On / Off (the old CAM button, now with its state in view: the
user had switched Classic's following off without noticing; Point with it off is the Fixed
camera scheme; C still toggles it and a toast says which way); Świat · World: time of day
(TIME), weather (RAIN), traffic; Obraz · Picture: style (STYLE), quality, VHS tape (VHS), frame
rate, the performance overlay and TEST; Dźwięk · Sound. Style and VHS are saved
(`display/style`, `display/vhs`); the time of day and the weather are the world's and start by
day and dry. Every key is unchanged. Zoom is a pinch (the `−` `+` buttons are gone); with the
fixed camera a two-finger twist turns the view 90° (the `<` `>` buttons are gone; Q / E stay).

**Nothing overlaps.** `hud.gd` `_layout` places the panels that come and go in order of
priority (the status, the call or job card, FLASH LIGHTS, the race banner, the toast, the
performance overlay, the note and landmark cards, the radio ticker), each at its spot or giving
way along its column (down from the top row, up from the bottom), clear of the fixed controls
(the top row, the minimap and wallet, the pedals' plates, the credit line) and of each other;
the passing ones also keep out of a 110×84 pt box in the middle of the screen, where the car
is. When there is no room even so (a 390-pt screen with a card, a status and the radio host
talking), the ticker, the note and landmark cards, a speech bubble and the overlay wait (their
time on screen starts when they show; a bubble is dropped after 6 s) rather than cover
something; the overlay first shrinks to its first two lines. Speech bubbles keep clear of every
HUD rect (the radio ticker too: the kebab stand's bubble used to hide under it), trying above
and below their speaker, beside what is in the way, and narrower or wider.

**One card recipe** (from the art director's review): every HUD surface is the settings panel's
near-black violet at 94 % with ink `#fbf7ee`, sub-text `#c9c2d8` and the accent `#ffd23f`
(nothing takes its colour from the street behind it); the radio ticker keeps its station's
colour as its left edge only; toasts (the tow crew's too) and the speed and wallet sit on
cards; speech bubbles are dark cards with the speaker's name in their colour; BRAKE, GAS, the
helicopter's pads and Classic's steering strip sit on solid plates (held: the accent); the
minimap takes a night palette as the lamps come on (light streets on a dark ground; it was the
brightest thing on a night screen).

**Polish above English** on the HUD: the top row, the cards' titles, text and buttons
(PRZYJMIJ · Accept, POMIŃ · Skip, JEDZIEMY! · Go! ...), the status panels' hints, the toasts, the
pedals, the egg note, the loading card and the title's call to action (DOTKNIJ, BY JECHAĆ over
"tap to drive"). The English under a card is a short gloss, not a second copy of the place
names, so a card fits a 390-pt screen.

**The performance overlay** is four 11-pt lines (fps, frame time, worst frame, cap · CPU process
+ physics + draw, GPU, memory · draw calls by pass · objects and triangles). Its QUALITY and
TEST · BENCH buttons are gone (Settings → Obraz has both; U still cycles the quality).

**Check.** `godot --headless --path game --script res://tools/check_hud.gd` (`tools/verify.sh`
step `hud`; `-- --verbose` prints every rect): builds the HUD at 2868×1320, 2532×1170, a
1280×720 window and the SE's 1334×750, walks it through 24 states each (the first screen in
Point, Classic and the helicopter, a call coming in, the call card, a payment, a rescue with the
radio host and an egg, a kebab offer with the stand talking, a delivery with the customer and
the stand talking where the ticker sits, a race, a rival to challenge, a landmark card, the tow
toast, six of them again with the performance overlay on), every settings tab and the bench
card, and fails on a control under 44 pt or outside the safe area, text under 11 pt (13 for
body text), words wider than their button, two HUD rects overlapping (speech bubbles
included), a passing panel over the car's spot, a panel with no room (the passing ones may
wait: it lists them), or the settings panel or bench card shrunk to fit.

**Cost** (probe, Metal, 2868×1320, Classic, traffic Normal, day; the code before loop 2e run
from a copy in the same session; draw calls are exact, frame times noisy):

| View | draw calls before → after | 2D pass before → after |
| --- | --- | --- |
| Spawn | 153 → 133 | 65 → 45 |
| Default view over the river | 124 → 105 | 65 → 46 |
| Zoomed out | 191 → 172 | 65 → 46 |
| Helicopter | 245 → 224 | 59 → 38 |

The HUD and minimap script stays at 0.06 ms a frame; the layout runs only when a panel comes,
goes or changes size. With a job card, a bubble, the ticker and the overlay all up the 2D pass
reads 53 (budget 80).

Screenshots: `shots/loop2e_*.png` at 2868×1320 and 2532×1170: the first screen before and after
(`first_day_before`, `first_day_after`) and at night (`first_night`), Point with the stick held
(`point_stick`), Classic (`classic`, `classic_steer`), the settings tabs (`settings_driving`,
`settings_world`, `settings_picture`, `settings_sound`), a call coming in (`call_ringing`), the
call card (`rescue_card`), a kebab offer with the stand talking and the ticker (`kebab_offer`),
a delivery (`kebab_delivery`), the tow toast (`tow_toast`), the overlay (`perf_overlay`), the
helicopter (`heli`).

## The first-minute look (2026-10-28)

After the art review of the day's screenshots: night had its own look, day didn't yet; in the
first minute the eye found lime grass, coral cycle lanes, an azure river and grey buttons
before the player's car, and at night the car was darker than the road. The user agreed:
calmer day colours; the car stays red, with red reserved for it; lumpier trees with rust and
olive autumn colours; today's smoother 2× pixel size kept (a retro look is a later loop). The
rules are in the art bible (`.claude/skills/screenshot-review/art-bible.md`). All measured on
the shots at 2532×1170 (luma 0-255 of the PNG, saturation = HSV), before from the code before
this loop, after from this one, same flags.

**What changed.**

1. **The player's car** (`car.gd`, `actor.gdshader`, `models.gd`): the body now uses the
   actors' material (no new shader, still one draw call) as a new *hero* part (UV.x 8): at night
   the paint and the stripes light from within (`HERO_PAINT` 1.4, `HERO_STRIPE` 0.3 of their own
   colour, a little brighter on faces that look up, the paint's glow a touch more orange so a
   saturated red can climb in luma: red-orange, hue ~13° at night, the jobs' beacon is 24°);
   the roof and bonnet stripes are a game pixel wider (0.18 → 0.3 m); the tail lamps are taller
   and wrap over the rear deck (the camera above never saw the 0.14 m lamps on the back); the
   night cone is stronger (peak 0.42 → 0.52) and longer (15 → 17 m) than traffic's. Traffic's
   red paint (`#a83a2e`, cars and vans) became slate `#6a7487`; the parked cars' red
   (map_builder.gd's palette, baked into `city.scn`) is repainted the same in `foliage.gdshader`
   on both city paths until the next bake.
2. **Calmer day ground**: the post pass's saturation boost now follows the time of day
   (`time_of_day.gd` `saturation_share`, `post.gdshader`): none by day (1.0), the style's own at
   dusk and night (Sharp 1.15), blended with the rest of the look. Grass less yellow and with
   less chroma (`ground.gdshader` `GRASS_TINT`, `GRASS_CHROMA`); cycle lanes and crossings brick
   red (`BRICK`).
3. **The river by day** starts its depth shading from a grey-green-blue (`DAY_WATER`) instead
   of the mapped azure; the pale crests a third as strong and the sun sparkles a quarter as many
   (1-2 px each); the water's mirror half as strong by day (the deck's shade band). Night water
   is untouched (the same colour path when `daylight` is 0). The pale jagged band south of Most
   Poniatowskiego that the review took for the deck's reflection stays with the mirror off
   (`--quality=low`): it is an area polygon on the water, map side (sandbars, loop 3b).
4. **The ghost** (`building.gdshader`, `ghost.gdshaderinc`): nothing it keeps glows (emission
   × (1 − fade); loop 1 kept 30 %); a cut building's inner faces (back faces inside the ghost's
   region) are unlit and flat, a step darker than the street (`INNER_DAY`, `INNER_NIGHT`); the
   dithered rim is narrower (0.65-0.9 of the radius, was 0.55-1.0: the same middle, so the
   ghost is the same size, with less speckle over roofs that don't hide the car). The gold wall
   the review saw "inside the cut tower" at the Palace by night is the shaft's own floodlit face
   beyond the car (a debug render: front faces past the car), not the cut's inner faces; it
   stays lit (see BACKLOG).
5. **Lamp pools as pixel light** (`night.gdshaderinc` `lamp_pool`, `pool_glow`; ground only):
   the baked pool strength is cut at 0.1 / 0.3 / 0.55 / 0.8 of one lamp into four hard bands
   (levels 0.07 / 0.27 / 0.52 / 0.85, the outermost a faint skirt) with a one-pixel checker
   dither along each step (the step's width from `fwidth`), every surface's top band capped at
   `POOL_CAP` (linear luma 0.3 of emission, so pale paving under an LED lamp no longer clips);
   sodium on the ground a touch more amber (dimmed, the full sodium red read pink on pale
   paving); grass, cycle lanes and flowerbeds tinted by a half-desaturated lamp colour instead
   of having it added (warm olive, not chartreuse). Facades, trees and vehicles keep the smooth
   light map.
6. **No blank walls** (`building.gdshader`): the bake writes a LoD2 wall's UV.x as its position
   along the wall's tangent in map metres (`tools/bake_gugik.py`), negative for 47,515 of the
   94,645 wall triangles (50.2 %), and the shader's wall test was `UV.x >= 0`, so half the LoD2
   walls were drawn as blank roofs: no windows, no shop band, solid navy at night (a debug
   render with UV as colour showed it). Roofs and windowless solids carry UV (−1, −1); the test
   is now `UV.x >= 0 || UV.y > −0.5`, and those walls get their window grid, the ground-floor
   shop band (lit at night), the lamp light on their lower floors and the Palace floodlight.
7. **Trees** (`foliage.gdshader`, shader side only): each crown is pushed out and in by three
   soft lobes seeded by where it stands (±20 % of its radius), with its facets' normals taken
   from the pixels so the light follows the new shape; a two-tone dapple of darker leaves in
   0.45 m cells; saturated orange crowns (hue 12-50°) turn rust, ochre or olive by their hue.

**Measured** (the review's measurements re-taken on the same shots; the car = the median luma
of its paint, the pixels in a 56×46 px box round it that are saturated red; the road = the
median of a 30 px ring round that box, lamp pools and the car's own cone included; a pool
cell = the brightest 24-px square of ground in a pool; lit windows = the median of the window
pixels over 140 in a lit facade of the same shot):

| | Before | After |
| --- | --- | --- |
| Car / road at night: the spawn (prebuilt) | 38 / 71 (−33) | 127 / 67 (+60) |
| … Marszałkowska | 38 / 97 (−58) | 126 / 90 (+36) |
| … the Praga beach (on the sand) | 38 / 76 (−38) | 115 / 76 (+39) |
| … the Palace from the north-west | 40 / 89 (−50) | 128 / 87 (+41) |
| … Rondo Dmowskiego in the rain | 30 / 30 (−1) | 126 / 27 (+100) |
| … Most Poniatowskiego (on the lamp-lit deck) | 64 / 151 (−86) | 125 / 127 (−2) |
| Car paint by day (spawn) | `#dc3002`, sat 0.99 | `#cf3e2a`, sat 0.79 (the most saturated thing near it) |
| Grass by day (two lawns at the spawn) | `#96c13c` 0.69, `#87ba2a` 0.77 (hue 79-81°) | `#98bd6b` 0.44, `#89b55d` 0.48 (hue 87-90°) |
| Cycle lane by day | `#e66d4c` 0.67 | `#ab5447` 0.58 (the review asked ~`#a9544a`) |
| The river by day (two stretches) | `#428acc` 0.68, luma 124, glints to 255 | `#517c8c` 0.42, luma 113, glints to 133 |
| Pool cells at night: the LED plaza by the spawn | 255 (clipped) | 169 (brightest pixel 172) |
| … sodium on the car park / the lawn and cycle lane | 168 / 163 | 145 / 150 |
| … Marszałkowska's pavement (two) | 207 / 117 | 157 / 87 |
| … Rondo Dmowskiego's paving ring / lawn, in the rain | 192 / 133 | 159 / 119 (brightest pixel 206 → 166) |
| … Most Poniatowskiego's deck | 200 | 153 |
| … the plaza east of the Palace | 221 | 171 (brightest pixel 233 → 176) |
| Lit windows (spawn / Marszałkowska / Rondo) | 226 / 220 / 241 | the same |

So at night every pool cell measured is under its shot's lit windows (most under 80 % of
them) and the brightest cells of the night shots are windows, lamp heads and neon, not
ground; the car is 36-100 over the road everywhere except on the lamp-lit bridge deck, where
lit ground sits above it on the value ladder and the paint stands out by colour (saturation
0.82 against the deck's ~0.35; a saturated red tops out at ~110-130 luma). LoD2 walls drawn
as roofs: 47,515 of 94,645 wall triangles → 0.

Shots: `shots/look_final/` (the core set before and after at 2532×1170 and 2868×1320, both
city paths; spawn_day_prebuilt, the night spots, dusk, the rain-day guide, the Ogród Saski
park), `shots/look_before/` (the extras before); `shots/look_probe/` (the debug renders: walls'
UVs as colour, back faces and faces past the car at the Palace, the river with the mirror off).

**Cost** (Mac M4 Pro, busy with other agents' runs; the code before this loop run alongside
from a copy, interleaved): the bench route on Vulkan Mobile at 1920×1080, uncapped, medians of
5: GPU 0.79 → 0.85 ms by day, 0.76 → 0.76 at night (B's first night run, 3.25 ms, was the new
shaders compiling once; the median leaves it out); frame 1.54 → 1.56 / 1.48 → 1.54 ms; scripts
0.54 → 0.53 / 0.52 → 0.53 ms. The zoomed-out view (220 m, Vulkan at 2868×1320, medians of 3):
GPU 1.38 → 1.39 ms by day, 1.27 → 1.30 at night. Draw calls at the budget's four views
(Metal, 2868×1320): 153 / 124 / 191 / 245, unchanged (main 53 / 35 / 66 / 100, shadow 35 / 24 /
60 / 86): the car's body changed material, not count (still 3 draw calls), and nothing new is a
shader of its own. Triangles: the car +24 (the tail lamps' deck pieces); the city's meshes
unchanged (6,100,768 vertices). The extra GPU by day is half the LoD2 walls running the facade
code instead of the roof grain, and the crowns' dapple and pixel normals.

**On the phone** (not run this loop): the frame rate at the default view and zoomed out (the
orchestrator's run), and the look at phone size: does the car read first at night and by day,
do the banded pools read as pixel light or as targets on the big lawns, is the river calm,
are the lumpy crowns better than the gumdrops.

## Camera loop: the follow camera (2026-10-28)

After the user's play on the iPhone: "now the follow camera is not working", and the wish for
the cinematic camera add-on (Phantom Camera). The phone's saved settings were Classic with
`classic_follow=false`: CAM had switched the following off, so the camera didn't turn by design
(making that setting explicit is the HUD loop's). Measured beyond the setting with a new camera
log (`--cam-log`) and scripted moments in the real city (`--cam-test=`), through the real touch
path (`--drag`, `--pedal`) on the Mac: **Point** held still while the finger was down (0°/s) and
came round 0.6 s after the release (3.2 s, at most 64°/s); **Fixed** never turned; but

- **Classic** started every game on the 45° diagonal: the first metres swung the camera ~155°
  round behind the car at up to **182°/s**; and it turned with the car at up to **108°/s** (a
  90° turn from a standstill; 91 at 20 km/h, 76 in the city at 50);
- **the helicopter's** camera waited while the stick was held, then 0.6 s later snapped round at
  up to **135°/s** (no ease, no limit);
- **braking** from 90 km/h, the view slid **8.0 m back** (7.5 m/s) as the look-ahead shrank with
  the speed, and the speed zoom came straight back in.

Docs/DEMO.md's comfort limit (Nesky) is 64°/s. All of that is fixed below; the rest is new.

**Phantom Camera** (Marcus Skov / Ramokz, MIT, 0.11.0.3 from the Godot Asset Store, 0.85 MB;
GDScript only, its C# files are optional wrappers a non-.NET Godot ignores) is in
`game/addons/phantom_camera/` without its examples folder; its manager is an autoload in
`project.godot`. The editor plugin is not switched on (it adds a dock and checks GitHub for
updates on every editor start, the headless exports included); switch it on in Project Settings
→ Plugins to see its nodes and gizmos. The follow camera itself is not a Phantom Camera follow
mode: none of them can hold still while Point's finger is down, cap the turn rate, snap to the
pixel grid, or keep the shadow's sphere through the speed zoom (`_camera_far`); it is the
game's own (`follow_camera.gd`), and Phantom Camera does the cinematic moments
(`camera_shots.gd`): its host runs in MANUAL mode under the camera, only while a moment plays,
and tweens between three of its cameras (the follow view, the target's, and a wider one
halfway). It sets `Engine.physics_jitter_fix = 0` when it starts (ignored with physics
interpolation on, as here).

**The follow camera** (`follow_camera.gd`, shared by `main.gd` and `tools/check_steering.gd`):

- **Turning**: the turn rate is the error × a gain (Classic 2.2/s as before; Point and the
  helicopter 1.1/s after a release, eased in over 0.8 s), the rate itself easing towards that
  (critically damped: no overshoot), never over **64°/s**; heading wiggles under 1° don't turn
  it. Point and the helicopter hold still while the stick (or a key) is held and 0.6 s after.
  Standing still Classic and Point hold still; the hovering helicopter's camera comes round (it
  stops within a second of a release). A following camera starts behind the vehicle (`--shots`,
  `--bench` and `--probe` keep the 45° start: their views are the reference screenshots and the
  budgets'); a tow turns it behind the car at once (not while Point's finger is down).
- **Look-ahead**: along the way the car goes, 0.40 s of its speed + 0.25 s more at top speed
  (15 m at 90 km/h, 12.5 before; 7 m at 50, as before), at most a fifth of the view, eased over
  0.7 s and never faster than 3.5 % of the view a second (2.8 m/s at 80 m, ≤ ~40 px/s on 1170
  lines), so the car drifts across the screen slowly when the way it goes turns. In Classic it
  lies along the camera's forward instead, so the car keeps its place on screen while the camera
  turns (along the car's way it swept the car round the middle by the camera's lag). **Braking**,
  it gives back at most half the car's own speed, so the view never moves back: it glides to rest
  ahead of the car and stays while the car stands.
- **Dead zone**: the view's centre follows a window 0.5 % of the view wide (0.4 m at 80 m, ~7 px
  on 1320 lines), then eases as before (6/s).
- **Speed zoom**: still a quarter wider at top speed and the 80 m default; out at 2.5/s, back in at
  0.8/s (it snapped in when braking); the zoom buttons and pinch at 2.5/s both ways. The shadow's
  sphere doesn't change through the speed zoom (unchanged, loop 2b).

**The cinematic moments** (normal launches only: never with `--notitle`, `--shots`, `--bench`,
`--probe` or the other testing flags; `--cinematic[=flyin|look]` forces them):

- **Fly-in** when the title screen goes: from a 200 m view 90 m along the car's way (the title
  still covers the cut) down to the follow view in 2.6 s (cubic in-out), turned like the follow
  camera all along, so the stick means the same on screen.
- **A look at a new target** (a rescue call's place, a delivery address; not a race's
  checkpoints) when the vehicle is under 30 km/h, nothing is held and the target is over 40 m
  away: both in one view if they fit in 220 m, else over a 220 m view halfway (out 0.6 + 0.6 s,
  0.7 s on the target, back 0.5 + 0.5 s). Not during another moment, the title or a BENCH run
  (which stops a moment at once).
- **Any touch, click or key** skips a moment: back to the car in 0.3 s (not in the first 0.25 s:
  the tap that dismissed the title arrives twice, as a touch and as Godot's mouse click).

**Numbers** (`tools/check_steering.gd`; its new `--camera=2a` runs loop 2a's camera with today's
car, and every test now starts with the camera settled for the starting speed: loop 2a's px/s
above started it at the car, which counted the look-ahead catching up; 2532×1170, 80 m):

| | Loop 2a camera | Camera loop |
| --- | --- | --- |
| Camera's fastest turn: Classic 90° turn from 0 / 20 / 50 / 90 km/h | 108 / 91 / 65 / 52°/s | 64 / 64 / 64 / 54°/s, 0° overshoot |
| Point, held 90° right at 50 km/h | settles in 1.2 s, 0° overshoot, camera 0°/s | the same (the car's law) |
| Point, let go after 2.5 s | camera behind the car 3.2 s later, at most 64°/s | 2.9 s, at most 60°/s |
| Braking from 90 km/h (Classic, Point) | view slides back 8.0 m (7.5 m/s); car on screen ≤ 47 px/s | 0.0 m; ≤ 27 px/s; zoom 96.7 → 81.5 m 2.5 s on (80.0 before) |
| Road ahead at a steady 90 km/h (to the top edge) | 105 m, 4.2 s | 107 m, 4.3 s |
| Classic, the thumb wobbling ±0.35 at 1.2 Hz at 50 km/h (car ±1.5°) | camera wobbles 0.90° (the screen's side edge 20 px) | 0.29° (6 px) |
| Car's fastest move on screen in the 90° turns, Point / Fixed / Classic (0, 20, 50, 90 km/h) | 42 43 58 73 / 40 28 36 47 / 43 42 57 66 px/s | 41 41 40 34 / 43 31 26 22 / 47 43 52 61 px/s |

Run in the real city with `--cam-test` at 2868×1320 (`shots/loopcam/`: `before_*` from the code
before this loop, `after_*`, and `sheet_*` strips every 0.25 s; `cam:` lines in each `log.txt`):
the Classic turn at 50 km/h turns the view at most 64°/s (76 before; it lags up to 41° behind the
car, 33 before), the car at most 28 px off the middle sideways (37 before); the Point release
comes round in 2.9 s (3.2), at most 60°/s (64), the car at most 83 px from the middle (115); the
stop from 90 km/h leaves the car 46 px below the middle and still (before, the view slid back
until it was in the middle, from 51 px); `after_flyin` (200 → 80 m over Rondo Dmowskiego and
Marszałkowska) and `after_look` (`--mission=1`: a rescue 843 m away, over the city and back).

**Cost**: the follow camera's math +1.1 µs a frame on the Mac (0.33 → 1.39 µs, a micro-benchmark
of the two); a moment playing 8.7 µs a frame (Phantom Camera's host), 0.2 µs idle; no node
processes between moments. Bench (`--controls=fixed`, the same view both ways, 3 interleaved
runs): scripts 0.55–0.56 → 0.56–0.61 ms, game loop 0.05 → 0.05–0.06 ms, draw calls 148 → 148.
`--probe` at 2868×1320: spawn 153 → 153 draw calls, over the river 124 → 124, helicopter 245 →
245. The fly-in's first view (200 m) draws 217 and the look's widest (220 m) 219, for a second or
two (the zoomed-out budget view draws 190–215).

## Performance budgets

Set in loop 2b from the measurements above; loop 2c (the player's car and the traffic as nicer
models) and loop 2d (many more props and jokes: corner shops, e-scooters, delivery riders,
app taxis) must stay inside them and report the same numbers before and after.

**How to measure** (on the Mac, at the iPhone's 2868×1320, Metal; the counters are the ones
the phone's overlay shows and match it):
`godot --path game --rendering-driver metal --resolution 2868x1320 --fixed-fps 60 -- --probe --nosave --controls=classic [view]`
for the four views below (the `draw calls` and `main pass` lines), the bench
(`cd game && godot --path . --disable-vsync -- --bench --nosave`, also `--time=night` and
`--weather=rain --time=night`; Vulkan with `--rendering-driver vulkan --rendering-method mobile
--resolution 1920x1080` for the GPU), and on the iPhone the TEST · BENCH card (started from the
home screen).

| Per frame (High, traffic Normal, day) | Now (loop 2b) | Ceiling after 2c | Ceiling after 2d |
| --- | --- | --- | --- |
| Draw calls, all passes: spawn (no `[view]`) | 149 (3D 53, shadow 35, 2D 61) | 165 | 230 |
| Draw calls: default view over the river (`--at=1135.7,-198.1 --heading=72`) | 124 | 140 | 200 |
| Draw calls: zoomed out (the same + `--size=220`) | 190 | 215 | 300 |
| Draw calls: helicopter (`--at=1300,-420 --heading=60 --heli --size=150`) | 245 | 270 | 360 |
| Draw calls at any view, ever | | 500 | 500 |
| Triangles, main pass (spawn / zoomed out) | 0.25 M / 0.36 M | 0.32 M / 0.50 M | 0.45 M / 0.70 M |
| Triangles, shadow pass (spawn / zoomed out) | 0.14 M / 0.27 M | 0.18 M / 0.35 M | 0.25 M / 0.45 M |
| Scripts, all systems (`scripts … ms` at the spawn, Mac) | 0.6–0.9 ms | 1.0 ms | 1.3 ms |
| Metal frame, bench (Mac, 1280×720, uncapped) | 1.5–1.9 ms | 2.2 ms | 2.6 ms |
| GPU, Vulkan bench (Mac, 1920×1080) | 0.80–0.87 ms | 1.0 ms | 1.2 ms |
| GPU, Vulkan zoomed out at 2868×1320 (`--gpu-profile`) | 1.65 ms | 1.9 ms | 2.2 ms |
| iPhone TEST · BENCH at High, 60 fps cap | 60 fps, 1 % low ≥ 56 | 60, 1 % low ≥ 55 | 60, 1 % low ≥ 55 |

What 2c may spend: ~15–25 draw calls (a few traffic kinds' MultiMeshes in the main and shadow
passes, the player's lamps), 70 k triangles at the default view (150 k zoomed out), 0.1 ms of
script. What 2d may spend: ~65–90 draw calls (about six new kinds of things, each one MultiMesh
per 512 m tile, in the main pass and, if over a metre tall, the shadow pass), 130 k triangles at
the default view, 0.3 ms of script. The phone has more GPU room at the default view than when
zoomed out or flying (there the main thread already waits ~11 ms of the 16.7 for the GPU), so
anything seen from far away (roof clutter, more trees, more cars when zoomed out) is the
expensive kind.

**Rules.**

1. Anything that repeats (five or more) is a MultiMesh: static things one per kind per 512 m tile
   (`map_builder.gd` `_tree_multimesh`, `INSTANCE_TILE`), moving things one per kind for the whole
   city, written with one `RenderingServer.multimesh_set_buffer` a frame and only near the view
   (as `pedestrians.gd` and `traffic.gd` do). Never one node per copy: the Mobile renderer has no
   automatic instancing, every node is a draw call in each pass it is in.
2. A model is one mesh with vertex colours for each material it needs; only parts that glow get
   their own material (the player's car: body + headlights + tail lights = 3 draw calls). Per
   instance colour goes in the MultiMesh's colour or custom data, never in a material per copy.
3. Triangles: the player's car ≤ 3,000, a traffic or rival car model ≤ 800 (about a hundred are
   on screen zoomed out), a person or rider ≤ 300, a prop ≤ 300, a kiosk or shop front ≤ 1,500.
4. Shadows: nothing under a metre tall or thinner than 0.3 m casts a sun shadow
   (`SHADOW_CASTING_SETTING_OFF`); casters over a metre that aren't buildings or trees join the
   `small_casters` group (`map_builder.gd` `SMALL_CASTERS`: no shadow on Medium). Things under a
   metre also join `fine_detail` (hidden in views wider than 170 m).
5. No new shaders unless the look can't be had otherwise; reuse `Models.material()` (actors and
   props, lamps and signs that glow at night) and the props' metal `StandardMaterial3D`. A new
   shader adds pipelines to compile (a first-sight hitch on the phone) and draw calls can't share it.
6. The HUD: no `clip_children`; no `_draw` that issues more than ~20 primitives a frame (build a
   mesh once and draw it with one call, like the minimap); the 2D pass stays under 80 draw calls.
7. No new full-screen passes at screen resolution; image effects go in the post pass at the
   pixel image's size.
8. Don't push `cam.far` out (it sizes the sun's shadow: `_camera_far`), the shadow map back up,
   or the tiles (`chunked_surface.gd` 256 m, instances 512 m) back down.
9. Report before and after: the `draw calls` / `main pass` lines at the four views above, the
   bench medians, and a TEST · BENCH card from the phone.

## Map data

0. Trees (optional, before step 1): the GUGiK 3D tree models, LoD1 2023, CC BY 4.0
   (`opendata.geoportal.gov.pl/InneDane/Drzewa3D/LOD1/2023/14/1465.zip`, 8.6 GB, no resume;
   stream it through `tar` keeping only the map's sheets into `data/raw/gugik/trees/1465/`), then
   `python3 -I tools/bake_trees_gugik.py data/raw/gugik/trees/1465 data/raw/gugik/trees_area.json`.
   Each tree is a trunk and a crown object; the crown gives the position, height, crown radius
   and crown base. `bake_osm.py` picks the file up by itself: inside every sheet that parsed to
   the end, the laser-scanned trees (`trees3d` in `centrum.json`) replace OSM trees and the park
   fillers; elsewhere the OSM trees stay.
1. OpenStreetMap (Overpass) → `data/raw/osm_wide.json` (the whole map: roads, trees, lamps,
   traffic lights, car parks, street furniture), then
   `W=data/raw/osm_wide.json && python3 -I tools/bake_osm.py $W $W game/map/centrum.json $W $W`.
   The public Overpass server is often busy (HTTP 502/504): retry with a back-off.
   Loop 3a: the bake also writes `fills` (approaches and pits: the ground corrected under a
   road), `tunnels` and `garages`, and the graph's `dk` / `tn`; check the result with
   `python3 -I tools/check_roads.py` (C1-C10, see Loop 3a).
   Laser-scan records that are not trees are left out (`GUGIK_NOT_TREES`: the Palm, written
   as `palm`). After a re-bake run steps 3-5 again.
   For the side jobs and easter eggs the same bake writes more `pois`: `kebab` (the mapped
   kebab places, `amenity=fast_food` with cuisine or name kebab, by position only, never their
   names, plus the extra corners in `EXTRA_KEBAB`; each with the road point a car pulls up at),
   `address` (973 homes and offices with `addr:street` + `addr:housenumber`, the road point at
   the door, `o` = office, `d` = `powisle` or `praga` across the river), `station` (Warszawa
   Centralna, shown as "Dworzec Centralny"), `patelnia`, `defilad` and `syrenka` (the boulevard
   spot facing the water, as none is mapped).
2. GUGiK: the Warsaw LoD2 package (`integracja.gugik.gov.pl/Budynki3D/pobierz.php?plik=powiaty/1465_gml.zip`),
   the four sheets that cover the map unpacked into `data/raw/gugik/sheets/`
   (`python3 -I tools/find_sheets.py data/raw/gugik/1465_gml.zip tools` lists them), then
   `python3 -I tools/fetch_gugik.py data/raw/gugik` (aerial photo + 10 m elevation grid) and
   `python3 -I tools/bake_gugik.py data/raw/gugik game/map` → `lod2.bin`, `lod2.json`, `terrain.json`.
3. `python3 -I tools/bake_ao.py game/map` → `ao.bin`, the soft ground shadows next to walls,
   under parked cars and trees. Run it after both bakes above (it reads their output). Loop 1:
   two bytes per metre, the buildings' shade and the small things' (the occlusion ghost lifts
   only the first); the map builder still loads an old one-byte map.
4. `python3 -I tools/bake_lights.py game/map` → `lights.bin`, the street-lamp light map for
   the night (1 m per pixel, sodium and LED, cut off by buildings) and the lamps it adds on
   bridges. Run it after the bakes above. Like `ao.bin` it ends up inside `city.scn` (the map
   builder puts it in the materials), so the export leaves the raw file out.

5. `python3 -I tools/bake_water.py game/map` → `water.bin`, the surface map (v0.9: shore distance,
   the river's flow, what reflects, bridge-deck heights); a second or two. Only needs
   `centrum.json`; like `lights.bin` it ends up inside `city.scn`, and the export leaves it out.

Audio: `python3 -I tools/make_sfx.py game/audio/sfx game/audio/radio` (v0.9: every sound effect
and bed, with the numbers; loops imported like the radio's, Forward, loop end = the full length,
QOA; `res://tools/check_sfx.gd` checks them); `python3 -I tools/make_music.py game/audio/radio shots` (the radio loops; import them
with loop mode Forward, loop end = the full length, QOA; `godot --headless --path game --script
res://tools/check_radio_loops.gd` checks the import and decodes across each loop point) and
`python3 -I tools/make_ui_sounds.py game/audio/ui`.

LoD2 is from 2018, so newer towers (Varso and others) come from OpenStreetMap; LoD2 buildings
no longer on the map are dropped. The terrain is bare earth, so bridges and viaducts get decks
solved from what they cross (see Real roads).

## Layout

**One-command checks.** `tools/verify.sh` runs the verification set and prints one
PASS/WARN/FAIL table: the map-data invariants (`tools/check_map_data.py`), the road check
(`tools/check_roads.py`, loop 3a), the check scripts
(steering, settings, the HUD at phone size, landmarks, sfx, radio loops, the water on both city paths) and eight headless game runs, each with
`--nosave` (`--quick` for a short set, `--ios` adds the export and the unsigned Xcode build,
`--only=` picks steps). `tools/shots.sh` renders standard screenshots at a phone's size
(`--list` names them). `tools/device_run.sh` builds, installs and launches the game on a
connected iPhone and copies its log back. A guard hook (`tools/hooks/guard_godot.py`, on in
`.claude/settings.json`) stops Claude Code from running the game without `--nosave` or a quit
flag. How the work is run: `docs/WORKFLOW.md`, `CLAUDE.md`.

- `tools/bake_osm.py`: turns the Overpass exports in `data/raw/` (map + mapped trees) into `game/map/centrum.json`:
  `python3 -I tools/bake_osm.py data/raw/osm_centrum.json data/raw/osm_trees.json game/map/centrum.json`.
  It reads `game/map/terrain.json` (for the bridge decks) and hands the road surface to
  `tools/bake_roads.py`: `carriage` (road and hatched areas), `kerbs`, `medians`, `guards`,
  `symbols` (turn arrows, BUS, bikes), `decks`, `shore` (the water's edge), the extra
  `markings` kinds and the roads' `w`/`c`/`hide`/`dk`.
- `game/scripts/map_builder.gd`: terrain with diorama edges, draped roads/markings/crossings/rails,
  carriageway areas, kerbs, raised islands and medians, turn arrows / BUS / bikes (pixel shapes),
  bridge decks (`ground_height`, `drive_height`, `deck_height`) with slabs, parapets and piers,
  guard rails, LoD2 + OSM buildings, trees, lamps, traffic lights, parked cars, collision (walls,
  guard rails, bridge parapets, the water's edge and its stone), the water test (`shore_distance`,
  `in_water`, `nearest_dry`, loop 10a). Flat layers are laid on the terrain (or their
  deck) in pieces no longer than the 10 m terrain grid. Everything is split
  into 128 m tiles (`chunked_surface.gd`) so off-screen tiles are culled.
- Loop 3a: `tools/check_roads.py` (+ `check_roads_allow.json`; the road rules C1-C10),
  `tools/road_spots.txt` (the road render spots for `tools/shots.sh --set=roads`),
  `game/scripts/debug_roads.gd` (`--debug-roads`), `game/addons/debug_draw/` (the Debug Draw
  add-on, HardPixel, MIT).
- `game/scripts/skids.gd`: tyre marks. The minimap lives in `hud.gd`. `splash.gd` (loop 10a): the
  car's splash in the water.
- `game/scripts/car.gd`: arcade car. `heli.gd`: helicopter (flight, rotor, blob shadow; it reads
  `map_builder.gd`'s 4 m grid of roof heights, so buildings are solid without physics queries).
  `missions.gd`: rescue calls, beacons (`beacon.gd`), timer and score. `hud.gd`: touch controls,
  mission card and status, target arrow. `main.gd`: camera, styles, vehicle switch, setup.
- `tools/bake_osm.py` also writes `pois` to `centrum.json`: hospitals (with the nearest road
  point), Vistula beaches, dry sandbars (`sandbar` if water surrounds it, else `shore`), named
  parks and squares, the stadium; and `graph`: the lane graph (nodes, directed edges with lanes,
  speed, junction cut-backs and stop lines, the largest strongly connected part, signal
  controllers and which controller each signal pole shows).
- The living city, all built at startup from the map data (about 0.1 s, both city paths):
  `lane_graph.gd` (lanes, junction curves, light timing, Dijkstra), `traffic.gd` (AI cars in
  MultiMeshes, spawning band, car following, lights, junction give-way, collision bodies near the
  player, signal lamps), `trams.gd`, `pedestrians.gd`, `rivals.gd` (rivals, races, their lines),
  `bubbles.gd` (speech bubbles and name tags in the HUD layer), `models.gd` (box-built vehicles
  and people) and `shaders/actor.gdshader` (per-instance paint, walking legs).
- `game/shaders/`: `common.gdshaderinc` (sRGB, noise, cloud shadows); `night.gdshaderinc` (the
  time-of-day globals `lights_on`, `daylight`, `sky_colour` from project.godot's shader globals,
  and the lamp light map; the look loop: the banded, capped lamp pools on the ground); `building` (per-building window rhythm from UV2, shop fronts, cornices,
  curtain walls, roof grain, see-through hole around the car, lit windows, neon tubes, floodlit
  Palace); `ground` (layer id in UV.y: paving slabs, asphalt, grass, worn paint, baked AO; depth
  bias in UV.x; lamp pools); `foliage` (sway, see-through, lamp light; the look loop: lumpy
  crowns, dapple, rust/olive autumn, the parked cars' red repainted); `actor` (vehicles and
  people; lamps and lit windows by UV.x; the player's car as the hero part); `fixture` (lamp posts with glowing heads); `neon`
  (signs); `glow` (additive light on the road, halos, the searchlight; drawn after the post
  pass); `post` (outlines, posterize, grading, vignette, split-tone, sky); `vhs`, `title`,
  `chrome` (the overlay and the title screen).
- `time_of_day.gd` (the three looks, the blend and Live; the post pass's saturation share), `radio.gd`, `title.gd`, `neon_signs.gd`.
- Loop 2e: `screen_points.gd` (the screen in points and its safe area; a known iPhone's on a
  computer), the HUD in points with its layout of passing panels (`hud.gd` `_layout`,
  `panel_rects`), the tabbed `settings_panel.gd`, bubbles clear of the HUD (`bubbles.gd`),
  rescue calls that come in during play (`missions.gd`), `tools/check_hud.gd`.

- `time_of_day.gd` (the three looks, the blend and Live), `radio.gd`, `title.gd`, `neon_signs.gd`.
- Camera loop: `follow_camera.gd` (the follow camera's laws: the turn, the look-ahead, the dead
  zone, the speed zoom; shared with `tools/check_steering.gd`), `camera_shots.gd` (the fly-in and
  the look at a target on Phantom Camera), `game/addons/phantom_camera/` (Phantom Camera 0.11.0.3,
  MIT, its autoload `PhantomCameraManager` in `project.godot`; the editor plugin is not switched
  on), the `--cam-log` / `--cam-test` / `--cinematic` aids and the camera's frame in `main.gd`
  (`_update_camera`, `_snap_to_pixels`, `_new_target`).
- Loop 2b: `bench.gd` (what a frame costs: frame times, the main thread's phases from the
  engine's frame signals, draw calls / objects / triangles by pass, the scripts by system,
  memory; for `--bench`, `--probe`, the BENCH button and the overlay), the minimap as one mesh
  in `hud.gd`, the camera's far plane (`_camera_far`), the fine-detail and small-caster groups,
  the frame-rate cap and the BENCH run in `main.gd`, `chunked_surface.gd`'s `add_arrays`.
- Loop 2a: `drive_controls.gd` (the control schemes: stick, keys and pedals to the car's
  controls and the finger's hold; the follow camera itself moved to `follow_camera.gd` in the
  camera loop; shared with the replay test),
  `settings.gd` (`user://settings.cfg`, the traffic levels), `settings_panel.gd` (the panel in
  the HUD), the car's turning and wall model in `car.gd`, the gear and Classic's pedals in
  `hud.gd`, `tools/check_steering.gd` (+ `tools/steering_legacy_car.gd`, the car before loop
  2a, for its `--legacy` numbers) and `tools/check_settings.gd`.
- Loop 1: `shaders/ghost.gdshaderinc` (the occlusion ghost's region, shared by the building,
  ground and post shaders), floating parts in `map_builder.gd` (`_part_bottoms`), the clock
  hands in `building.gdshader`, the column posters in `eggs.gd`, `BLINK` lamps in
  `models.gd` / `actor.gdshader`.
- v0.9: `sfx.gd` (buses, engine and tyres, rotor, beds, one-shots, positional voices),
  `weather.gd` (Clear / Rain, `wetness` and `rain` shader globals), `tools/make_sfx.py`,
  `tools/bake_water.py`, `game/tools/check_sfx.gd`, `game/tools/check_sun.gd`; the river, wet
  ground and lamp columns in `ground.gdshader`, the mirror reflections and rain in
  `post.gdshader`, the performance overlay in `hud.gd` and `main.gd`.
- v0.8: `landmarks.gd` (the hand-built landmarks, their zones, info cards and picking grid;
  map_builder.gd calls it), `tools/check_landmarks.gd`, `tools/overlay_landmarks.py`.
- v0.65: `wallet.gd` (wallet and save), `dialogue.gd` (lines from `data/dialogue.json`, drivers'
  shouts, the radio host), `jobs.gd` (kebab stands, orders, heat, the słoiki run, jars),
  `eggs.gd` (the Palm, pigeons, roadworks, Patelnia, the Mermaid, joke billboards), `props.gd`
  (their box-built models, drawn with the actors' material so lamps and signs glow at night),
  `pixel_font.gd` (a 5×7 font with Polish letters for signs and posters), `shaders/poster.gdshader`.
  All built at runtime on both city paths (nothing new in `city.scn`). The export includes
  `data/*.json`.
  Debug: `--debug-ao` shows the AO map, `--no-ao` turns it off.

Screenshots for review: `godot --path game -- --style=0 --size=380 --at=-110,-85 --shots=40 --out=$PWD/shots`.

Command-line options (after `--`):

| Option | Effect |
| --- | --- |
| `--demo` | the car drives by itself; with `--heli` the helicopter flies a slow circle |
| `--shots=60,240` / `--out=DIR` | save screenshots at those frames (counted from when the city is built), then quit |
| `--style=N` / `--lines=N` | visual style 0–3 (loop 2e: wins over the saved style for this run) / override the pixel image's line count |
| `--size=M` / `--yaw=deg` / `--fixed` | view height in metres (default 80) / camera turn / fixed camera (in Point: the Fixed camera scheme) |
| `--at=x,z` | start at map coordinates (metres, +x east, +z south), on top of a bridge deck if there is one |
| `--heading=deg` | the car's heading at the start (0 north, 90 east), for testing: with `--demo` it drives off that way |
| `--nohud` | hide the controls |
| `--prebuilt` | load `map/city.scn` like the exported game |
| `--debug-ao` / `--no-ao` | show / switch off the baked ground shadows |
| `--heli` | start in the helicopter |
| `--mission=N` | start rescue call N at once (N = 1, 5, 9… streets, 2, 6… roofs, 3, 7… river, 4, 8… parks) |
| `--autopilot` | testing aid: fly (or, ghosting through walls, drive) to each mission target; in a race or a side job, drive the route; with `--rival`, tail the rival |
| `--no-traffic` | no traffic, trams, pedestrians or rivals |
| `--race=N` | race rival N (1–6) at once: they are put just ahead of you |
| `--rival=N` | put rival N just ahead of you (with `--autopilot` you tail them, so the FLASH LIGHTS prompt shows) |
| `--bench` | drive a route through the traffic and print the average frame time over 600 frames, the scripts' cost and the 3D view's GPU time; loop 2b: also the bench's lines (see Loop 2b), a 30 s cap, the result in `user://bench_result.txt` |
| `--time=day\|dusk\|night` | start at that time of day (default day) |
| `--vhs` | VHS overlay on (for this run; Settings saves it since loop 2e) |
| `--radio=N` | radio station 1–3, or 0 / `off` (default 1) |
| `--notitle` | skip the title screen (the testing flags `--demo --shots --autopilot --race --mission --rival --bench` skip it anyway) |
| `--title` | show the title screen even with those flags (for screenshots) |
| `--kebab=N` | put the car in a stand's ring and take kebab order N (the same N gives the same order; stand N mod 7) |
| `--sloik` / `--sloik=K` | start the słoiki run at Dworzec Centralny (K jars already broken) |
| `--heat=X` | the kebab's starting heat, 0–1 (for a cold-arrival screenshot) |
| `--host-in=S` | the radio host's first line after S seconds |
| `--barriers=YYYYMMDD` | place the roadworks for that day |
| `--free` | free roam: no call (loop 2e: there's no call card at the start anyway; with `--free` the first call comes in 90 s into play instead of 60) |
| `--tap=X,Y` | tap that screen pixel at frame 60 (a landmark's info card) |
| `--reset-save` / `--nosave` | wipe the wallet and record / neither read nor write `user://save.cfg` (nor, since loop 2a, `user://settings.cfg`) |
| `--time=live` | v0.9: the real sun for the device's clock (TIME's fourth mode) |
| `--clock=HH:MM` / `--date=YYYYMMDD` | start Live's clock at that Warsaw time (and date; default today) |
| `--weather=clear\|rain` | start dry or in the rain (default clear) |
| `--perf` | show the performance overlay (loop 2e: four lines: fps, frame time, worst, cap · CPU process + physics + draw, GPU, memory · draw calls by pass · objects, triangles) |
| `--quality=low\|medium\|high` | the quality setting (default high) |
| `--sound-check` | play every sound once and print the bus meters, then quit (needs an audio device) |
| `--ghost-debug=1\|2` | loop 1: paint the occlusion ghost (1: ghosted magenta, other buildings green) or cut it fully (2), and print its ellipse in screen pixels with each screenshot |
| `--controls=point\|classic\|fixed` | loop 2a: the control scheme for this run (not saved) |
| `--traffic=empty\|low\|normal\|busy` (or 0-3) | loop 2a: the traffic level for this run (not saved) |
| `--settings` | loop 2a: open the settings panel at the start (screenshots) |
| `--settings-tab=N` | loop 2e: open the settings panel at tab N (0 Jazda · Driving, 1 Świat · World, 2 Obraz · Picture, 3 Dźwięk · Sound) |
| `--call-in=S` | loop 2e: the first rescue call comes in after S seconds of play (default 60) |
| `--stick=X,Y` / `--pedal=gas\|brake` | loop 2a: hold the stick at that deflection (-1..1, y down; Classic uses X) / a pedal, as if a finger were on it (screenshots, replays in the real city) |
| `--clicks=X:Y:F,...` / `--drag=X:Y:F:DX:DY:F2` | loop 2a testing aids: a click at screen pixel X,Y on frame F; a finger down at X,Y on frame F, moved by DX,DY over ten frames, lifted on frame F2 (through the real input path) |
| `--lift=M` | loop 1: aim the camera M metres above the vehicle (close-ups of tall landmarks: `--at=-1206,244 --lift=156 --yaw=110 --size=24 --lines=1080` looks at the Palace clock's east dial) |
| `--probe` | loop 2b: stand where `--at` / `--heading` put the car (free roam), let 240 frames (or 8 s) pass, measure the next `--bench-frames` (default 600, or `--bench-seconds`, default 30) and print the bench's lines plus what is in view (nodes, instances, shadow casters, materials, shaders, kinds); quits |
| `--bench-frames=N` / `--bench-seconds=S` | loop 2b: frames to measure for `--bench` / `--probe` (default 600) and a time cap (default 30 s; with `--bench-button`, the BENCH run's length, default 55 s) |
| `--bench-button` | loop 2b: press TEST · BENCH at frame 60 (the phone's run, at the current settings and cap) |
| `--fps=N` | loop 2b: cap the frame rate for this run (0: none; else the setting, 60 or 30). `--bench` and `--probe` run uncapped, headless runs too |
| `--exp=a,b` | loop 2b, for ranking costs: switch one off: `nohud`, `nominimap`, `nobubbles`, `noshadow`, `nopost`, `notrees`, `noprops`, `nosmallcasters` (no shadows from instanced things), `nocasters`, `shadowsize=N` |
| `--debug-roads` | loop 3a: draw the bridge decks, approaches, tunnels, lane heights and piers round the car (Debug Draw add-on) |
| `--cam-log` | camera loop: print the camera every 0.25 s (`cam:` lines: scheme, finger, speed, the car's and the camera's compass headings, the camera's fastest turn since the last line, the car's place on screen, the view's height) |
| `--cam-test=classic_turn\|point_release\|brake` | camera loop: drive one camera moment in the real city (scripted inputs through the scheme's mapping, the car ghosting through walls, no traffic, 1 s parked first; implies `--cam-log`): Classic following, a 90° right turn at 50 km/h; Point, the stick held 90° right at 50 km/h for 2.5 s then let go; Classic following, flat out to 90 km/h then braking to a stop. Frame strips: add `--shots=` every 15 frames (`--at=-1113.2,-263.4 --heading=160` is Marszałkowska) |
| `--cinematic` / `--cinematic=flyin\|look` | camera loop: the cinematic moments in a test run too (they play only in a normal launch: never with `--notitle`, `--shots`, `--bench`, `--probe`, `--demo` or the other testing flags). With `--notitle` the fly-in starts at once; `--mission=1 --cinematic=look` shows the look at a rescue target |
| `--drive-into-water=X,Z` | loop 10a: start at X,Z and drive flat out at the nearest water (within 120 m), the collision off until 3 m past the edge as if the car had jumped it; prints `water test:`, `water: splash at …` and `water: towed after … s …` (where to, how far from a lane, dry or not, the job / rescue / race / wallet), each with its frame. With `--kebab=0` a delivery is running (`tools/verify.sh` step `splash`) |

Godot's own `--time-scale 3` (before `--`) speeds a mission or race up for screenshots, and
`--fixed-fps 60` makes runs repeatable frame by frame.

Bench (`godot --path game --disable-vsync -- --bench`, MacBook, 1920×1080, default zoom): 120 fps
with and without traffic (the display's refresh caps it; macOS keeps vsync on), with the
traffic, trams and pedestrians scripts taking about 1.0–1.15 ms a frame for ~45 cars on screen and
~95 driving, by day and by night; the side jobs and easter eggs add 0.03 ms. The Metal driver reports no GPU time; run it on Vulkan to get it
(`godot --path game --rendering-driver vulkan --rendering-method mobile --resolution 1920x1080
--disable-vsync -- --bench --time=night`): the 3D view takes about 1.85 ms on the GPU by day
(1.81 in v0.65 measured the same day), 1.9–2.0 ms at dusk and 1.72 ms at night (1.71 in v0.65)
(M4 Pro; the night has no shadows, which pays for the glow). v0.75's roads cost nothing extra:
the flat layers are now cut into ≤ 10 m pieces instead of fans of slivers, so the city has
6.13 M vertices (6.19 M in v0.65) and builds in ~6 s at runtime (8.9 s), 0.9 s prebuilt.
v0.8's landmarks cost less than the lumps they replace: 6.07 M vertices (6.10 M before, same
day), 0.07 s to build; bench GPU 1.79-1.90 ms by day and 1.70-1.75 at night (1.90 / 1.73 before;
one day run read 3.13, a repeat 1.90 and 1.79), scripts 1.03-1.05 ms, worst frame 9.2-9.5 ms by
day, 9.4-9.8 at night (9.3 / 9.8 before).
v0.9 (same day, Vulkan, before → after): GPU by day 1.86-2.12 → 1.82-1.94 ms, at night 1.69 →
1.73-1.82, at night in the rain 1.82-2.11 (budget +0.6 over the dry night), by day in the rain
1.93-2.07 (the first run of a batch read 3.09-3.66 twice, like the day outliers above); scripts
1.00-1.13 ms as before, plus 0.02 ms for the sound; worst frame 9.2-9.8 ms (9.2-9.8 before);
vertices unchanged at 6.07 M (no new geometry: the river and the rain are shaders and one
texture). Quality Low at night in the rain: GPU 1.81 ms, scripts 0.72 ms (fewer cars and
people). The bench also prints the audio buses' peaks while driving (radio on, mean / loudest
dBFS): Music -18.2 / -11.5, SFX (engine, tyres) -20.0 / -17.4, Ambience -33 by day, -37 at
night, -26 in the rain; Master never above -8 dBFS.

Loop 2a (same session, the code before loop 2a run alongside from an APFS clone of `game/`
with the old scripts; five interleaved runs each, medians; the Mac ran uncapped, 200-300 fps,
with a few runs capped at 144 Hz or disturbed, left out): Vulkan GPU by day 2.27 ms before,
2.24 with the new defaults (80 m, Normal), 2.43 like with like (`--size=110 --traffic=busy
--controls=classic`); at night 2.21 before, 2.01 new, 2.20 like with like (the GPU time is the
3D view's only, so the HUD can't change it; the like-with-like spread is the view's path, as
the lead is smoothed now, and noise: one code's runs spread 2.06-2.90 ms). Scripts (traffic +
trams + people) 0.84 / 0.86 ms before → 0.43 / 0.43 with the new defaults, 0.83 / 0.83 like
with like. Frame (Vulkan) 4.69 / 4.58 ms before → 4.26 / 4.16 new; Metal 3.57 / 3.63 ms
before → 3.34 / 3.31 new, 3.65 / 3.62 like with like. GPU time is n/a on Metal.

Loop 2b (same session, the code before loop 2b run alongside from an APFS clone; three runs
each, interleaved, medians; uncapped; the commands above): Metal frame 3.61 → 1.54 ms by day,
3.58 → 1.56 at night, 3.55 → 1.85 at night in the rain; Vulkan (1920×1080) GPU 2.31 → 0.85,
2.00 → 0.80, 2.11 → 0.87 ms, frame 4.55 → 1.83, 4.32 → 1.64, 4.35 → 1.52 ms; traffic, trams and
people 0.44–0.46 → 0.39–0.45 ms; vertices 6,055,540 either way. The bench now also prints its
`bench detail:` lines (draw calls by pass, the main thread's phases, scripts by system, memory)
and writes them to `user://bench_result.txt`; with `--fixed-fps 60` the route covers the same
ground whatever the frame rate (without it, a faster run drives a shorter way in its 600 frames).

Map data © OpenStreetMap contributors, ODbL.
