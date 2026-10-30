> **Development notes**, moved here from `README.md` on 2026-10-30 and otherwise unchanged: how every part of the game works, loop by loop. Where other docs, scripts and comments say "README", they mean this file; paths in it are from the repo root.

# Around Warsaw (prototype; Nocna Warszawa until 2026-10-30)

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

Loop 2c (the user asked for nicer car models) rebuilds every vehicle from shaped pieces instead
of boxes (`models.gd`): a body lofted from its side profile with a sloped bonnet, a glasshouse
narrower at the roof with side windows and pillars, wheels in dark arches with hub caps,
bumpers, plates and lamps. The player's red hatch is the one retro hot hatch in town (white
stripes over the nose, bonnet, roof and tailgate, round lamps, a roof spoiler); traffic shows
hatches, saloons, estates, SUVs, a city taxi in an invented livery, Podwózka's app taxi with a
phone on the roof, panel and box vans and the bus, with no red or orange paint; the police
estate and the city guards' car are built for loop 3g; the rivals, the trams and the parked
cars get the new shapes too. Still one MultiMesh per kind: each draws several shapes, picked
per car in the vertex shader, and draws only the cars in use, so the frame costs the same draw
calls and fewer triangles at the default view (see Loop 2c: car models).

Loop 3g-1 (the police, part one, after docs/design/police.md and the user's choice of the
gentler police) puts patrol cars in the traffic and three speed traps ("suszarki") on the day's
roads, with an officer who waves the lizak at a speeder. A slip is a joke over a megaphone; two
in 45 s, a ram or an ignored lizak start a chase (koguty 1 to 3, with a blocker and a roadblock)
that always ends by itself ("Koniec zmiany!" at 30 / 40 / 45 s), or when you lose them (+15
respect), or when you stop and get a funny talking-to ending in a caution in the joke notebook.
Never a fine: nothing ever touches the złoty. Two new add-ons run it, beehave and Dialogue
Manager (see Loop 3g-1: the police, part one).

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

## Android (Google Play)

```zsh
tools/export_android.sh              # split the map, prebuild the sectors, then the signed AAB
tools/export_android.sh --skip-city  # the AAB only (the tracked prebuilt sectors as they are)
tools/export_android.sh --apk        # a debug APK for `adb install` on a test phone
```

It writes `build/android/nocnawarszawa-<version name>-<version code>.aab` (0.1 and 2 now; ~68 MB:
the arm64 engine library ~71 MB uncompressed and the game's files ~45 MB, the same files as the
iOS `.pck`) and prints its size, package and version. The version lives in the **Android** preset
in `game/export_presets.cfg` (`version/name`, `version/code`): raise the code for every upload,
Play refuses a code it has seen. The city step is the same as `tools/export_ios.sh`'s and
rewrites the tracked `game/map/sectors/*.scn`, `index.res` and `proxies.scn` with a few bytes of
noise each; use `--skip-city` when the map hasn't changed.

The preset: package `com.olshanskysoft.nocnawarszawa`, Gradle build, AAB, arm64-v8a only, min
SDK 24, target SDK 36, sensor landscape (from the project's orientation; Godot writes
`userLandscape`, which follows the phone's rotation lock), the VIBRATE permission only (the
haptics; no INTERNET: the game makes no network calls), app backup off, the project icon
(`game/icon.svg`) as the launcher icon.

**Vulkan is required** (the user's choice, 2026-10-29): the Mobile renderer needs Vulkan, and
`rendering/rendering_device/fallback_to_opengl3` stays off, so Google Play must not offer the
game to phones with only OpenGL ES. Godot writes `android.hardware.vulkan.level` (1) and
`android.hardware.vulkan.version` (0x401000, Vulkan 1.1.0 in Godot 4.7) as *not required*; the
project's own editor plugin `game/addons/nw_android_export` (on in `project.godot`, editor only,
excluded from both exports) writes a build-variant manifest
(`android/build/src/standardRelease/` or `standardDebug/`) on every Android export that marks
both required, and Gradle's manifest merger ranks it above Godot's. It is tracked code, so a
fresh `--install-android-build-template` keeps the rule. `tools/export_android.sh` refuses an AAB
whose merged manifest doesn't have both required at the Vulkan version Godot asks for (after a
Godot upgrade that raises it, change `VERSION` in the plugin). **Expect Play Console's device
catalogue to list fewer supported devices** than before: the OpenGL-only phones (mostly old or
very cheap ones, and some with Vulkan 1.0 only) drop out. That is the point, not a fault.

**A fresh clone** (loop 3d-1: the map's derived files aren't in git) builds with the same
command: the script imports the project when Godot never has, makes `lod2.*` and
`terrain.json` when missing (`tools/setup_map.sh --full`, which needs GUGiK's raw data; or copy
the three files from a checkout that has them), then splits the map and prebuilds the sectors.
Checked 2026-10-30: `nocnawarszawa-0.1-2.aab`, 150 MB, upload-key SHA-256 fingerprint
`29:45:ED:ED:…:87:BF:59:9E`, `jarsigner -verify` "jar verified". Play needs a new
`version/code` (Android preset) for every upload: raise it before the next export once code 2
is on Play. A CI build isn't possible today: the map's GUGiK files need the raw downloads, and
the upload key must stay off GitHub (it would have to be a repository secret).

**The upload key** is `~/.android-keys/nocnawarszawa-upload.jks` (alias `upload`, RSA 2048,
10,000 days), outside every repo. Its password is only in the macOS login keychain (service
`nocnawarszawa-android-upload`, account `upload`; Keychain Access shows it). The script reads it
into `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `_USER` and `_PASSWORD`, which Godot reads at export:
no key, user or password is ever in `export_presets.cfg`. Play App Signing holds the key that
signs what users install; this one only proves an upload is yours. **Back it up**: copy the
`.jks` and its password (from Keychain Access) to a password manager or an encrypted disk.
If it is lost, Play can reset the upload key (Play Console → Test and release → App integrity),
but that takes a support request and a few days.

**One-time setup on a new Mac** (already done on this one):
1. Godot 4.7.2's official export templates (github.com/godotengine/godot/releases, tag
   `4.7.2-stable`, `Godot_v4.7.2-stable_export_templates.tpz`, ~1.3 GB, checked against the
   release's `SHA512-SUMS.txt`): only `android_debug.apk`, `android_release.apk` and
   `android_source.zip` are needed, in `~/Library/Application Support/Godot/export_templates/4.7.2.stable/`.
2. The Android SDK (platform android-36, build-tools, platform-tools; no NDK or cmdline-tools
   needed) and a JDK 17 or 21, set in Godot's editor settings as `export/android/android_sdk_path`
   and `export/android/java_sdk_path`. Godot makes its own debug keystore the first time.
3. The Gradle build template: the script's first run passes `--install-android-build-template`,
   which puts it in `game/android/build/` (gitignored, kept out of the project by its own
   `.gdignore`). Gradle downloads itself and its libraries on the first build (a few hundred MB,
   cached in `~/.gradle`).
4. The upload key, as above (`keytool -genkeypair -keystore ~/.android-keys/nocnawarszawa-upload.jks
   -alias upload -keyalg RSA -keysize 2048 -validity 10000`, the password into the keychain with
   `security add-generic-password -a upload -s nocnawarszawa-android-upload -w`).

Play Console's forms (app details, content rating, target audience, data safety, the store
text) have ready answers in `docs/store/play-console.md`; the privacy policy is
`docs/privacy.md`. Nothing has run on an Android phone yet (see that file's checklist).

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
| Quality: Auto → Low → Medium → High → Ultra → Auto (loop G1; Auto, the default, picks a level for the device) | Settings → Obraz → Jakość obrazu | U |
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
  with a tired, flickering tube. Readable from about 70 m zoom in. Sweep 2: ghosted with
  their wall (they never were: a sign on a ghosted wall floated over the ghost, lit and
  mirrored); in the ghost's core a sign goes altogether, over its rim it is dithered.
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
- **Title screen** (`title.gd`): chrome AROUND WARSAW (`WORDMARK`; NOCNA WARSZAWA until
  2026-10-30) with the tagline under it, Polish above English (`TAGLINE_PL`, `TAGLINE_EN`), over a striped setting sun with the
  Palace of Culture in silhouette (drawn from the v0.8 model's tiers, in metres), the skyline, the palm from Rondo de Gaulle'a and a neon grid;
  the city builds behind it, then TAP TO DRIVE / DOTKNIJ, BY JECHAĆ. Test runs skip it.
- **Radio** (`radio.gd`, R): 87,3 KEBAB FM, 86,6 RONDO FM, 108,8 MORDOR FM, then Off; on by
  default at a moderate level. The stations and their tracks are in `game/data/radio.json`
  (loop radio-playlists; the built-in names are the fallback when the file is missing). A
  station with one track loops it (today each of the three: *Palma de Gaulle'a*, *Rondo
  Dmowskiego 3 A.M.*, *Mordor Mall Muzak*); a station with several plays them in an order
  shuffled by the date and the station (a day has its own, every run of it the same), each to
  its end, then the next, round and round. Tracks are Ogg Vorbis, decoded as they play (never a
  whole song in memory). A burst of tuning static covers a station change; a now-playing ticker
  at the bottom left shows "87,3 KEBAB FM · Title (Artist)" on a tune and at every new track.
  Between two songs the host (`dialogue.gd`, `radio_host` lines) speaks with a one in two
  chance, 5 s after the title's caption, through the same timer, so a Podwózka card still keeps
  him quiet. Hooks: `radio.announce(text)` puts any line on the ticker,
  `radio.station_changed(index, station)` fires on every change and
  `radio.track_changed(info, track, natural)` on every new track (`natural`: the last one ran
  out); `radio.next_track()` skips (no button yet). Silent in headless runs (no audio device).
  Adding songs: "Adding music" below.
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

- **Traffic**: cars (hatches, saloons, estates, SUVs), taxis (the city taxi: a white saloon
  with a lit roof sign and a band of dark squares; Podwózka, the app taxi: a hatch with a phone
  on the roof), delivery vans (panel and box vans) and red-and-yellow city
  buses (main roads only; loop 2c: the shapes) drive on a lane graph baked from OpenStreetMap (`graph` in
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
- Hit a car and it is shoved: rear-ended it rolls on, hit from the side it slides off its line,
  and it coasts to a stop for a moment; rivals complain (the driving-feel loop, below).

## Side jobs, the wallet and the city's chatter (v0.65)

- **Wallet** (`wallet.gd`): złoty and respect, shown under the minimap (a coin and a star; a
  payment floats up as "+46 zł"). Races pay the rival's stake (60–300 zł) and +100 respect,
  rescues pay 8% of the score in złoty and +40 respect, side jobs pay fares and tips. Wallet,
  respect, jobs done, best times and easter eggs found are kept in `user://save.cfg` (a
  ConfigFile; on the Mac `~/Library/Application Support/Godot/app_userdata/Around Warsaw/`;
  `.../Nocna Warszawa/` before the rename of 2026-10-30, so a Mac's older save stays there; the
  phones keep theirs, as `user://` follows the unchanged bundle ID).
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
van with a pickle-green stripe and mum's jars on the rack), **Taksiarz Zbyszek** (black taxi, every shortcut
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
  Loop 3b-2: spiral lane lines on Rondo Dmowskiego, no arrows on roundabout rings, chevrons
  pointing at the oncoming traffic, wider-celled combined arrows (see Loop 3b-2).
- **Kerbs**: a 14 cm granite kerb (light top, darker face) wherever the carriageway meets
  something that isn't road: pavements, medians, tram beds, islands (121 km). Traffic islands
  are raised to kerb height with a kerb all round. Dual carriageways (two one-way roads running
  opposite ways side by side) get their median: raised grass, or paving at road level where
  trams run in it (mapped grass, islands and hatching stay as mapped). Loop 3b-2: the car feels
  them (lifted onto islands and grass medians, a jolt over a kerb), and the tram bed is a
  concrete track slab.
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
  you can see, under the bridges too and round the fountains (see Loop 10a). Loop 3b-2: granite
  only where the bank is built; natural banks get wet sand and a foam line (see Loop 3b-2).

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
one or two Polish lines, the English under them. Landmark card fix: the note and landmark cards
stand first in the right-hand column under the top row, beside the car (the status panel's and
the ride card's column), at most 236 pt wide and no wider than the room right of the car's spot
(`side_card_width()`); on a 375-pt phone they used to find no room and never showed.
`--tap=X,Y` taps a screen pixel at frame 60.
Sweep 2: the walk steps on through whatever the occlusion ghost has made see-through (half its
pixels or more gone, ghost.gdshaderinc's test on the frame's values, main.gd
`_pick_unghosted`), so a tap on the cut-away part of a tower in front of the car picks what
shows through the cut (a landmark, or nothing on the street), not the tower.

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
- Checks: `python3 -I tools/make_sfx.py game/audio/sfx` prints peak, RMS,
  the loop seam (step and slope across the loop point against the 99.9th percentile
  elsewhere), the share of energy under 2 kHz and the roll-off for every file; `godot --headless --path game --script res://tools/check_sfx.gd` checks the
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
the frame did.) Loop 2e cut it to four lines; loop G1 made the last one the quality, its pixel
scale and the governor (`High ×2 · gov GPU 2/2 · CPU 2/2 · wide`); objects and the shadow pass's
triangles are on the BENCH card.

**Quality** (QUALITY, U, Settings, `--quality=auto|low|medium|high|ultra`; saved since loop 2a;
loop 2b made Medium and Low real steps; loop G1 added **Auto**, the default, and **Ultra**,
`tiers.gd`):

| | Ultra | High | Medium | Low |
| --- | --- | --- | --- | --- |
| Auto picks it on (model id, `OS.get_model_name()`) | 15 Pro and newer: `iPhone16,x`, `iPhone17,1`–`4`, `iPhone18,x` and up | 11 to 15, SE 2 / 3, 16e (`iPhone12,x`–`15,x`, `17,5`); iPads, Macs, anything unknown | XS / XR (`iPhone11,x`) | 8 / X (`iPhone10,x`) |
| Pixel size (whole screen pixels per image pixel): the style's own scale (Sharp: the most that keep 480 lines), Low and Medium one coarser, then coarser until the image fits the budget | budget 1.6 MP: the iPhone 11 at 1 (1792×828), the Pro Max at 2 (1434×660) | budget 0.96 MP (the Pro Max's 1434×660): 2 on every iPhone, the iPhone 11 and SE included (896×414, 667×375). **Under Auto (loop G1b)** the iPhone 11 and the SE 2 / 3 draw Sharp at 1 (1792×828, 1334×750) with High's effects, and at 2 for the next launches after a session there struggled (the fallback, below) | one coarser, budget 0.5 MP (956×440 / 844×390 / 896×414) | as Medium |
| Sun shadows | **4096** map, everything over a metre tall | 2048 map, everything over a metre tall | 1024 map, buildings and trees only | off |
| Night glow | on | on | on | off |
| Rain streaks | all | all | 70% | 40% |
| Mirror reflections (steps per pixel) | **16** | 10 | 6 | off |
| Traffic (share of the usual, × the Traffic setting) | 100% | 100% | 80% | 55% |
| Pedestrians (most at once, × the Traffic setting's share) | 60 | 60 | 40 | 24 |
| Draw calls at the default view (river, iPhone 16 Pro Max, loop 2b) | as High | 124 | 118 | 99 |

Before loop 2b Medium's 0.85 render scale gave High's image on a 1170-line phone and Low's on a
1320-line one, and its shadow map was 2048 against High's 4096 over a 2 km slab. Before loop G1
High was the default and drew the iPhone 11's 828 lines at 1 (1792×828, 1.48 MP, the most pixels
of any phone); a settings file saved before G1 that says High loads as Auto, once (High was the
default then, not a choice). The **frame governor** and the **view rule** (loop G1, below) take
extras away when frames are missed and in wide views, never the pixel size or the shadow map.
Loop G1b: **Auto starts sharp, with a fallback** (section "Loop G1b" below): where High's budget
would make Sharp coarser than its own scale (only the iPhone 11 and the SE 2 / 3, and Mac windows
under 960 lines over 0.96 MP), Auto draws the style's own scale with High's effects (not Ultra's);
if a session there struggled (the governor's GPU extras down a minute and a tenth of the play, or
3 minutes in a row missing over 2 % of refreshes GPU-bound), the next launches draw the budget's
×2, and the sharp image comes back after 2 calm sessions, the wait doubling (to 16) each time it
struggles again on trial. The manual levels keep G1's rule (Wysoka ×2 on the iPhone 11, Ultra ×1).
Settings → Obraz's Auto button says what it draws: `auto · High ostry` (sharp), `auto · High ×2`
(the fallback), `auto · High` (where the budget doesn't bind); the overlay's last line
`High ×1 sharp` / `High ×2 fallback`; the BENCH card `Auto→High sharp (iPhone12,1)`.

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
way ("Pomoc drogowa: wyciągnięci! · Towed free"). Point follows only fixed walls, not cars
(since the driving-feel loop it also goes round a car it has pushed into for 0.35 s).

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
47 and 21); any other window is taken as a phone 390 pt tall with no insets, or 667 pt wide when it is
narrower than that (a 4:3 window); the iPads the store screenshots use (2752×2064, 2732×2048,
2420×1668, 2360×1640) are known at 2 px a point with 20 pt at the bottom. iOS insets both
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
(the user's decision, 2026-10-28). Sweep 2: the haptic engine is built while the city loads
and started 2 s before each call (`missions.gd` `warm_haptics`): on iOS the first buzz built
and started Core Haptics' engine inside the call's frame (the call's 61–117 ms hitch on the
phones; the log's `haptics:` line at load, and `rescue call ringing (buzz N ms)`).

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

## Loop 3b: roads II, the builder (2026-10-28)

The builder's side of docs/DEMO.md section 4 (R2, R5-R7, buildings under decks, the tunnels),
so that **every rule C1-C10 passes over the whole map** (allowlist entries only with a reason and
a source) and **a car and a bus drive every lane without hitting anything**. The structures are
placed in the bake, on the finished map data (`tools/bake_structures.py`, run at the end of
`bake_osm.py`): the game draws what the data says, and `check_roads.py` and the new
`check_drive.gd` check the same data.

| Rule (DEMO.md 4.5) | Before (loop 3a) | After | Allowed, why |
| --- | --- | --- | --- |
| C1 grade | 32, all allowed | 32, all allowed | as loop 3a |
| C2 joints | 0 | 0 | |
| C3 clearance | 54 in 7 places, allowed | 36 in 6, allowed | the decks rose (R2); schematic footbridges, the WKD cutting |
| C4 piers | 31 of 171 | 0 of 174 (8 portal legs) | |
| C5 solids | 50 | 18 in 14 places, allowed | courtyard driveways ending at a gate (each with its OSM way) |
| C6 deck ends in the air | 0 (+5 rim) | 0 (+5 rim) | |
| C7 dropped ways | 0 | 0 | Warecka's 7 m `tunnel=yes` counts as a gate now |
| C8 lanes | 5, allowed | 5, allowed | as loop 3a |
| C9 through decks | 57 | 4 in 3 places, allowed | a footway deck grazing buildings (2-8 % of a footprint), the science centre's roof ramps |
| C10 landmarks | 1 | 0 | |

`check_drive.gd`: 2,276 lanes, 36,177 spots every 4 m, 0 car and 0 bus boxes in collision (the
first run on this loop's bake: 407 car + 1,171 bus boxes in 341 places); the autopilot over 20
routes (every deck and tunnel edge, both ways, 3 outer-lane repeats), 45,067 frames, 0 height
jumps over 0.3 m (first run: 3 on 10 routes).

**What changed** (DEMO.md 4.8 has the numbers per item):

- **Piers (R5)** are the bake's (`decks.piers`): a candidate every 38 m slides up to 12 m along
  its deck to a footprint 1.1 m clear of what runs under it (roads at half their width, trams,
  rail beds, kerbs, carriageway areas, lower decks, every lane's drive corridor); else a portal
  frame (two legs outside the road, the slab as the cross-head, a cap beam out to a leg past the
  deck's edge); else none. Solid. `--debug-roads` shows them.
- **Retaining walls (R6)** (`walls`): where an approach stands 0.35 m or more over the ground
  beside it, along its sides and across an end: stone (roads) or concrete (tracks), a light
  coping, a 0.9 m parapet from a 1 m drop, solid from 0.6 m, open where a way joins the approach
  or a tunnel passes under it. The same runs line the tunnels and their open ramps.
- **Most Poniatowskiego's towers (R7)** (`towers`, landmarks.gd): the outline by the deck, its
  footprint trimmed clear of the road decks, approaches, roads and lanes, base at the boulevard,
  shaft from the solved deck + 1.2 m; the zone grown 6 m, so the stair annex OpenStreetMap maps
  ~6 m out is no longer drawn as a building fused into the tower. Solid from the boulevard to
  over the deck.
- **Buildings under decks** (`cut`, `cutd`, `pil`, `lod2_cuts`): cut to the slab's bottom - 0.5 m
  under a road, rail or tram structure (the Poniatowski viaduct's LoD2 arcades and the Arkada;
  `_build_lod2` clips the LoD2 triangles and lays the roofs over the cut flat); a viaduct's
  mapped pillars fitted to the slab; a building only grazed (under 20 % of it) isn't cut.
- **True deck heights (R2)**: `tools/geotiff.py` reads the demo fetch's GeoTIFF corridors
  (`data/raw/demo/gugik/nmpt05`, `nmt1`; 17 windows reach this map) and `bake_roads.SurfaceModel`
  gives the solver the measured deck. Most Poniatowskiego's river span now has its camber (-5.6 /
  -4.5 m at the ends, -3.2 m mid-river; the solver alone had it nearly level), the Jana Pawła II
  viaduct rose 1-2 m onto its pillars, the viaduct over Powiśle stays within 0.3 m of loop 3a's.
- **Tunnels** are drawn and driven: the floor's road, dark walls (solid inside), portal frames,
  walls along the open ramps; `drive_height` drives a tunnel's floor (`map_builder.tunnel_floor`),
  traffic routes through them and is hidden deeper than 15 m from a portal; the car shows
  through the ground as a warm silhouette (`tunnel_xray.gd`); `--tunnel` starts inside one.
  Garage doors at the 27 ramp tops.
- **Clearing the lanes** (what `check_drive` found, by class): tram-stop platforms are kerb
  height and not solid any more; fences, walls, hedges and mapped guard rails are cut out of
  carriageways and lanes; benches, racks, shelters, parked cars and kiosks standing in one are
  left out; building colliders end at the building's top; deck parapets are solid only over a
  1 m drop; road decks narrowed (at most 0.4 m) beside a ground lane; LoD2 walls a metre into a
  lane not solid there; approaches widened to hold their lanes; `aprons` blend the ground at
  structure ends (the 10 m grid's cross slope made a car step 0.3-0.4 m off a deck or out of a
  tunnel); no pit fill in a tunnel's open ramp.
- `tools/verify.sh`: `roads` FAILs on any rule; new steps `drive` and `drive-prebuilt`.

**Cost** (Mac, README's commands; the loop 3a code and data in a copy, `game_before/`, run
alongside). Draw calls, probe at 2868x1320, before → after: spawn 153 → 154 (3D 53 → 53, shadow
35 → 35, 2D 65 → 66), the default view over the river 124 → 125, zoomed out 190 → 186, the
helicopter 242 → 245, Most Poniatowskiego's east end 123 → 122, the Wisłostrada portal 135 →
135, the Jana Pawła II viaduct 137 → 136; main-pass triangles unchanged (0.25 → 0.24 M at the
spawn, 0.37 → 0.36 M zoomed out). Every new piece (piers, walls, portals, garage doors) goes into
the existing tile meshes: no new material or draw call; the tunnel silhouette costs a draw call
per car mesh only while the car is in a tunnel. Vertices 6,144,280 → 6,060,970 (-1.4 %; meshes
3,771,594 → 3,766,836, instances 2,372,686 → 2,294,134: the parked cars and props cleared out of
the lanes). Scripts on the bench route (5 interleaved runs, medians): traffic + trams + people
0.65 → 0.63 ms, all 0.93 → 0.91 ms; the frame is capped at the display's 120 Hz on this Mac
(8.33 ms both), and other agents' Godot runs overlapped, so frame times say nothing. The runtime
city build 7.7 → 8.4 s (the LoD2 cut, the walls, the aprons in `terrain_height`); the prebuilt
city loads in 0.8 s as before. `centrum.json` 5.04 → 5.14 MB, `city.scn` 36.5 → 36.4 MB.

**Not done** (BACKLOG "From loop 3b"): the minimap's dashed tunnels (hud.gd), the art items
(natural banks, sandbars, tree crowns by roads) and the triage's 3b row (kerbs solid, markings);
loop 3b-2.

Screenshots: `shots/loop3b/` (the road spots before and after on both city paths, the tunnel
portal and the car in the tunnel, the towers, a pier beside a road; `c9_spots.png`).

## Loop 2c: car models (2026-10-28)

The user asked for nicer car models; the art review and the user had decided that red belongs
to the player's car (red-orange, white roof stripes, the hero material at night), that traffic
has no saturated red or orange (Warsaw's buses and trams keep their livery), that the police are
white with a blue band and a blue/red light bar, and the city guards mustard and dark red.
Every vehicle was built from boxes (`models.gd`, the player's in `car.gd`).

**The kit** (`models.gd` `Shape`, flat-shaded, vertex colours, the actors' material): a body
lofted from its side profile (front, nose, a sloped bonnet up to the windscreen's foot, the
waist, the rear deck or hatch, the rear), a glasshouse lofted on it and narrower at the roof
(a raked windscreen, the roof, the rear window), glass panes laid on it with pillars between
them (two side windows a side, the B pillar between), six-sided wheels (eight on the player's)
with a flat bottom and hub caps, standing in dark arches cut into the sides, black bumpers,
number plates, a grille, head and tail lamps. One table of measurements per body (`spec()`):
hatch, saloon, estate, SUV, panel van, box van, the player's hatch, a coupé and a city car.

**A family per traffic kind.** Traffic keeps one MultiMesh per kind (cars, taxis, vans, the
bus; same count as before). Each kind's mesh is a family of shapes with the same parts in the
same order (`family()`): the first shape is the mesh itself, up to three more ride in each
vertex's CUSTOM0..2 (position, and the normal packed into one float), and the vertex shader
(`actor.gdshader`, UV.x + 16 marks such a vertex) takes the shape the instance's custom alpha
names. A part one shape lacks shrinks to a point in that shape. So:

| Kind (MultiMesh, pool) | Shapes (share) | Triangles | Paints |
| --- | --- | --- | --- |
| CAR (112) | hatch 36 %, saloon 26 %, estate 22 % (roof rails), SUV 16 % (tall, high sill, rails) | 194 | greys, white, black, navy, slate, beige, green, olive, steel blue, plum |
| TAXI (16) | the city taxi 50 % (a white saloon, our own livery: a yellow band of dark squares on the doors, a lit yellow roof sign), Podwózka 50 % (parodies.md: a hatch in greys, black or navy with a phone on the roof, its screen lit, five dark stars) | 268 | |
| VAN (16) | panel van 60 % (a high roof, glass in the cab only), box van 40 % (a short cab under a box that reaches over it) | 228 | whites, greys, navy, slate, green |
| BUS (8) | the city bus: red below, yellow above, a window band with pillars (lit at night), a destination display, three doors on the right, the roof's air-conditioning box | 198 | fixed |

Each car's shape comes from its own random stream (`_looks`), so where and which kind of car
spawns is as before; its size (the gap it keeps, its body near the player) is the shape's
(`models.gd` `TRAFFIC`). Each MultiMesh now draws only up to its highest slot in use
(`visible_instance_count`; a freed slot is the next one taken), not its whole pool, so the
frame's triangles fell even though each model has more.

**The player's car** (`Models.player_meshes()`, still body + head lamps + tail lamps = 3 draw
calls): the same kit with shorter overhangs, a lower roof with more rake and a wider stance,
the twin white stripes over the nose, the bonnet, the roof and the tailgate, black bumpers, a
roof spoiler, round head lamps, light hub caps; the hero material, the tail lamps over the rear
deck and the lean and squat as before. 292 triangles (240 before). No mirrors: at the 80 m
view they would be one image pixel.

**The police and the city guards** (`Models.police_mesh()`, for loop 3g, not in traffic): one
family, so 3g's POLICE kind can draw both in one MultiMesh. Shape 0 is the patrol estate (4.7 m,
paint `POLICE_WHITE`): a blue band on the doors with "POLICJA" in the game's 5×7 pixel font
(5 cm pixels, white; it reads from views of ~15 m and closer, at 80 m it is a white streak), a
light bar with a blue and a red lamp that blink in turns (BLINK, UV.y shifts the beat; they
glow at night). Shape 1 is the guards' car, the same estate at 0.88 (paint `GUARD_MUSTARD`)
with a dark red band and two amber lamps. 636 triangles.

**The rivals** (their own meshes, all colours fixed, no saturated red): Seba's lowered purple
coupé with pink bonnet stripes and a big wing, Mordor Mike's grey estate with dark glass and a
roof box, Pani Halina's tiny mint city car with a cream roof and a basket (a cabbage and a loaf),
Słoik's white panel van with a pickle-green stripe (it was red) and the jars on a rack, Zbyszek's
long black saloon with a yellow sign and chequers, Bartek's neon-green hatch with a magenta wing
and the speaker. 204–288 triangles each.

**Trams**: the same kit, Warsaw's yellow over red kept: the cab's big windscreen leans back over
a rounded nose with a destination display above, two doors a side, the window band lit at
night, dark gangways where the cars join, an air-conditioning box on the cab cars and the
pantograph on the middle car. 98 triangles a cab car (120 before).

**Parked cars**: `map_builder.gd` now takes their mesh (`parked_mesh()`: a small saloon, 40
triangles, was 24) and their paints (`PARKED_PAINT`, no red) from `models.gd`. city.scn was not
re-baked (the map side's): when it loads, `main.gd` replaces its parked cars' shared mesh in
place (`Models.renew_parked`), so both city paths look the same; the old red instance colours
in the bake stay repainted slate by `foliage.gdshader` until the next bake. They stay one shape:
more kinds would cost a MultiMesh per kind per 512 m tile (BACKLOG).

**The actors' shader** (`actor.gdshader`, no new shader or material): the family shapes (a
vertex with UV.x ≥ 16 reads CUSTOM0..2 when INSTANCE_CUSTOM.a is 1..3), and BLINK (7) shifts its
beat by UV.y (0 for the roadwork lamps: unchanged).

**Testing aid**: `--lineup` puts every model round the car (the flags table), and prints each
one's triangles.

**Cost** (`--probe` at 2868×1320, Metal, Mobile, `--controls=classic`, High, Normal traffic,
day; the code before this loop from a copy, interleaved):

| View | Draw calls, all passes (main / shadow) | Main pass triangles | Shadow pass triangles | Ceiling after 2c |
| --- | --- | --- | --- | --- |
| Spawn | 134 → 132 (53 / 35 → 53 / 35) | 0.25 → 0.24 M | 0.14 → 0.13 M | 165, 0.32 M / 0.18 M |
| Default view over the river | 105 → 105 (35 / 24 → 35 / 24) | 0.19 → 0.17 M | 0.12 → 0.10 M | 140 |
| Zoomed out (`--size=220`) | 171 → 171 (64 / 60 → 64 / 60) | 0.37 → 0.37 M | 0.27 → 0.28 M | 215, 0.50 M / 0.35 M |
| Helicopter | 222 → 222 (98 / 86 → 98 / 86) | 0.32 → 0.32 M | 0.22 → 0.23 M | 270 |
| Bench route, day / night | 113 → 113 / 82 → 82 | 0.18 → 0.17 M | 0.15 → 0.14 M | |

(The 2D pass, the HUD, draws 44 or 46 from one run to the next, before and after alike.)

Triangles a model (before → after): a traffic car 144 → 194 (each of the four shapes), the taxi
300 → 268 (and Podwózka), a van 144 → 228, the bus 156 → 198, the player's car 240 → 292 (≤ 3,000),
the police and guards' car 636 (≤ 800), the rivals 144–336 → 204–288, a tram cab / middle car
120 / 108 → 98 / 102, a parked car 24 → 40.

Bench (Metal, 1280×720; 3 runs each, interleaved with the code before, medians): scripts
0.73 → 0.75 ms (traffic 0.28 → 0.29), draw calls 113 → 113; night (1 run each) 82 → 82 draw
calls, scripts 1.34 → 1.21 ms. Vulkan GPU at 1920×1080: 3.03 → 1.88 ms, but another agent's
Godot ran beside these runs (loop 2b measured 0.80–0.87 ms on a quiet Mac), so read it only as
"not worse".

Vertices of the city (`count_vertices.gd`): 6,144,280 → 6,200,700 (+0.9 %: the parked cars,
72 → 86 vertices each). The Metal frame times can't be compared this time (the runs were held
at the display's 120 Hz, 8.33 ms, and other agents ran Godot): the draw calls, triangles and
script times are the comparison.

Shots: `shots/loop2c/` (gitignored): `*_before_*` from the code before this loop, `*_after_*`,
at 2532×1170, 2868×1320 and 1792×828 (the iPhone 11): the spawn by day and at night (prebuilt
city), Marszałkowska in Busy traffic, the line-up at 25 m and 14 m (`after_lineup*`, and at night),
rival race starts (Seba, Zbyszek), the parked cars by the spawn.

What only the phone can tell: whether the hatch is found first in Busy traffic at 80 m (bar C1;
the marker helps), whether the shapes read at the iPhone 11's 2× pixel (585-line image), the
police lettering's legibility, and the frame at the zoomed-out and helicopter views with many
cars in view (the model has more triangles, the frame draws fewer).

## Loop 3b-2: map art and road details (2026-10-28)

The map side of the art review (items 4, 8, 9 and the tram-bed note) and the road details loop 3b
left (the triage's 3b row). New bake step `tools/bake_banks.py` (run by `bake_osm.py`), new check
`game/tools/check_drape.gd` (verify step `drape`).

**The class behind the "torn paper" sandbars and the beige patches, measured first.** The flat
areas (water, grass, parks, plazas) were laid on the ground in pieces up to 12 m whose planes
cut under the 10 m terrain grid's folds; where the bare-earth grid rises (the river's real
sandbars and a ridge along Most Poniatowskiego's piers in the GUGiK grid, lumps in the parks)
the ground poked through as jagged beige patches. `check_drape.gd` samples every area triangle
against the drawn ground: before **85,624 m² of grass and parks, 9,893 m² of plazas and 2,813 m²
of water** under the ground by more than 0.1 m; after **0 / 0 / 0** (and 0 of 57,354 m² of
sand). The areas are now laid on the grid's own triangles (`map_builder._fill_on_grid`: whole
cells where the outline doesn't cross, the cells it crosses clipped), never under the drawn
ground. Exact on the ground, they need almost no depth bias (0.05 → 0.01; their few millimetres
of height order them).

**The same class the other way round** (found in the orchestrator's review of the first beach
shots: the Praga beach's footpath came out dashed once the beach was sand): a footway is a
strip of 10 m pieces, each a plane through terrain points, that sags under the grid's folds;
where it sagged further than its depth bias lifted it over the area under it, the area hid it.
`check_drape.gd` part 2 samples every footway, cycle path, step, wet band, rim and foam strip
against the area triangles under it: with the areas at 0.05 **3,035 m² of footways and paving,
172 m² of cycle paths, 562 m² of steps and 22 m² of wet bands** were hidden; now **2 / 0 / 0 /
0 m²** (the 2: one footbridge's ramp ending 0.46 m under the park it lands in, the deck solver's,
allowed). Footways, cycle paths and steps on the ground are now laid on the grid's triangles too
(`_strip`, depth bias up to 0.12), and the areas' bias is 0.01.

**The pale band south of Most Poniatowskiego** was neither a reflection nor a sandbar: the
bridge's two pavements (`area:highway=footway`) and its tram bed (`landuse=railway`) are mapped
as areas, mostly without a layer, and were drawn on the ground, that is on the river under the
bridge (a pale and a grey band). `bake_roads.level_surfaces` puts a mapped surface on a deck
when most of it lies in the corridor of that deck's pieces of its own kind (paving on a footway
piece, ballast on a tram or rail piece) standing 2 m over the ground: 3 surfaces (all on Most
Poniatowskiego); what lies under a bridge (a pitch, Centralna's platforms, the pier shoals)
matches no such piece and stays on the ground.

1. **Natural banks.** `bake_banks.classify_shore` splits the water's edge (bake_roads' shore runs)
   into built and natural stretches every 2 m from OpenStreetMap: built where a footway or
   cycleway runs along the edge within 9 m (the Bulwary), a road within 10 m, paving or a plaza
   on the land side, a wall or embankment along it within 4 m, or a bridge deck within 20 m (the
   abutments); a sand, beach, shoal, wetland, scrub or wood polygon on the land side beats a
   promenade; stretches under 14 m take their neighbours' kind. **2.68 km built, 4.99 km
   natural** (the Praga bank, the beaches, the reeds north of the railway bridge, the west bank's
   natural stretch south of the bridge; park ponds with grass banks). Built stretches keep the
   granite edge (4.2 km with the bridges' and the fountains'); a natural one gets a wet band and
   a damper one (0.9 m each, sand, or dark earth on a green bank) inland from the waterline and a
   1-px foam line (0.22 m) on the water; `n` on the shore run (1 sandy, 2 green). **The car**
   is held back on a natural bank by the same collider on the waterline as before (invisible
   there): it stops at the foam, on the wet sand; nothing changed for the splash and tow
   (`check_water` 0 everywhere). The bake also dropped the seam between the Vistula's two
   multipolygons, which had put a granite edge and a wall across the river at z ~820. Sand
   (natural=beach / sand / shoal / shingle, 74 polygons, `sand` in `centrum.json`) is drawn as
   sand under the water, so nothing of it shows past the edge; the beige patches in the water
   were the ground poking through (above). OpenStreetMap leaves thin strips between its sand
   polygons (a beach cut round a groyne, a shingle bank mapped a few metres off the beach, two
   beaches split under the bridge); bare ground while the beach was bare ground, they showed as
   straight pale bands on the sand. `bake_banks.sand_gaps` fills the gaps up to 6 m wide in a
   group of sand polygons of 400 m² or more (closed by 3 m, less anything mapped there: grass,
   parks, plazas, paving), 103 fills, 1,885 m² (`f` on `sand`, drawn just under the sand). **At night** sand and the wet bands are 0.6× (the
   beach's luma 76 → 58 at night; by day 182 → 183), the foam 0.32×.
2. **Sandbars** (`sandbars`, 15, 5,874 m²): the sand polygons' part on the river, rasterised at
   0.5 m, opened by 1 m (nothing narrower than 2 m survives), traced, smoothed (Chaikin ×3) and
   simplified (0.12 m), pieces under 6 m² dropped; drawn over the water on the grid's triangles
   with a darker wet rim (1.1 m) inside the outline and a foam line round it; gravel shoals
   (surface=gravel: the rubble round Most Poniatowskiego's piers, `g`) in grey.
   For the car and the helicopter they stay river (water.bin is unchanged).
3. **Tree crowns by the roads.** `bake_osm.crown_scales` writes one scale per scanned tree
   (`trees3d_crown`, hundredths; `trees3d` keeps its 75,324 values): 0.75 within 12 m of a
   drivable road's edge, rising to full size at 20 m (parks, courtyards). 5,443 of 12,554 trees
   are at 0.75, 7,044 scaled at all. `map_builder` shrinks the crown's radius and depth (its base
   stays, so it still clears a bus), `bake_ao.py` its shade.
4. **Kerbs you feel.** `map_builder.drive_height` lifts the car 0.14 m onto a traffic island or a
   grass median at street level; `kerb_feel` (cells of the islands, medians and kerb lines, kept
   in `city.scn` for the prebuilt city) tells `car.gd` when a move crossed a kerb (the car keeps
   92 % of its speed and the body bounces 7 cm) and when it rolls on the raised ground (0.6/s
   drag; the driving-feel loop made it 97 %, once per 0.5 s, and 0.25/s). Driven at 40 km/h onto 30 islands: 35.3 km/h after 1.5 s (38.4 without), 0.14 m up.
   Not for a car with its collision off (the autopilots) or parked, not on decks; traffic keeps
   to its lanes and never feels them (`check_drive` 0 collisions, 0 height jumps).
5. **Markings.**
   - **Rondo Dmowskiego's spiral** (and the 4-lane ring by Centralna, the only other ring with 3+
     lanes and a 25 m radius): between two exits each lane line holds its lane for the first
     35 % of the way, then sweeps out by a lane into the exit; the outermost line meets the outer
     edge at the exit and a new one starts at the island (`bake_roads._spiral_rings`,
     `_paint_spiral`). The ring's own lane lines and **its turn arrows** (the arrow confetti from
     the ring's `turn:lanes`) are gone: arrows 491 → 442, none on any roundabout ring.
   - **Chevrons with the traffic**: 53 long hatched areas with the traffic going one way on both
     sides get chevrons whose points face the oncoming traffic (26 were turned round); 14 between
     opposite flows (or with no road alongside) get plain diagonals.
   - **Deck gaps**: two pieces of one bridge up to 6 m apart (road, tram bed, footway) no longer
     each get a parapet with the river showing between them: the slabs meet half way across the
     gap, and a low kerb marks each piece's edge (2,087 m of deck edges; the parapet's collider
     stays where there is a drop, so the car can't drive into the gap).
   - **Turn arrows**: the combined arrows (left + right, left + through + right) 9 cells wide
     (were 11) and the cells up to 0.3 m, so strokes and gaps stay whole at the default view.
   - **The tram bed** (a median with trams): a concrete track slab (`#8c887f`, a joint across it
     every 3 m, layer 19), darker than the pavements; tram rails thinner (0.16 m) and closer to
     it in tone: no longer pale pavement with a barcode on it.
   - **Medians on two-way roads**: no two-way road on today's map has its median mapped as a line
     (no `divider`, no barrier or kerb line along a two-way road's centre; the 3 gaps between a
     two-way road's carriageway areas are not medians), so nothing was built (BACKLOG).
6. **Parked cars' red**: city.scn is re-baked with `models.gd` `PARKED_PAINT` (no red), and the
   red-paint remap in `foliage.gdshader` is gone (the constants and two branches in its vertex
   function); `Models.renew_parked` in main.gd is harmless now.

**Shaders** (exactly): `ground.gdshader` layers 16 (sand: grain and soft drifts, 0.6× at night),
17 (wet bands and rims: vertex colour, grain, 0.6× at night), 18 (foam line: a slow shimmer,
0.32× at night), 19 (tram bed slabs, wet in the rain like the islands); `foliage.gdshader` the
parked-car red remap removed. The water shader (the water branch of `ground.gdshader`) is
unchanged.

**Checks.** `check_drape.gd` (above, both parts; verify step `drape`, ~11 s). `check_roads` C1-C10 unchanged
(all allowed as before), `check_drive` 0 / 0, `check_water` 0 on both city paths, the splash run
towed in 1.00 s. `check_map_data.py` expects `trees3d_crown` (12,554).

**Cost** (`--probe` at 2868×1320, Metal, Mobile, `--controls=classic`, High, Normal traffic, day;
the code before this loop from a copy): draw calls, all passes, spawn 135 → 134 (main 53 → 52,
shadow 35 → 35), the default view over the river 106 → 105, zoomed out 169 → 169, helicopter
223 → 223; main-pass triangles 0.23 → 0.23 M at the spawn, 0.18 → 0.18 M over the river, 0.36 →
0.37 M zoomed out. No new material, mesh or draw call: everything new is in the ground's tile
meshes. Vertices 6,111,678 → 6,119,007 (+0.1 %: meshes 3,766,836 → 3,774,165; the areas on the
grid's triangles took ~370 k off, the footways, cycle paths and steps on them put it back;
instances unchanged). `city.scn` 36.4 → 37.1 MB. The runtime city build 8.2-8.4 → ~10.7 s (the
clipping to the grid), the prebuilt city (the phone) loads in 0.9 s as before. Scripts: one
`kerb_feel` call per physics frame for the player's car (a cell lookup and a few segment tests).

Shots: `shots/loop3b2/` (gitignored), `*_before_*` from the code before this loop and
`*_after_*`, at 2868×1320 and 1792×828: the Praga beach by day and night (`beach_*`, and
prebuilt; `*_v1regressed_*` the first version with the pale bands and the dashed footpath), a
park footway on the grid's folds by the Bulwary (`footway_bulwary_after`), the Bulwary by day and night (`bulwary_*`, night prebuilt), the sandbars by Most
Poniatowskiego (`poni_river_day*`, and prebuilt), Marszałkowska (trees, tram bed), Rondo
Dmowskiego (`rondo_day*`, `rondo_top*`, and prebuilt), a chevron area (`chevron_day`), a kerbed
island (`island_day`), the bridge deck close up (`deckgap_*`); overlays `ov_banks_overview.png`
(built red, sandy yellow, green lime, sandbars pink), `ov_rondo_markings_after.png`.

What only the phone can tell: whether the kerb bump reads (and is not annoying) under a finger,
whether the 1-px foam line survives the 2× pixel on the iPhone 11, and whether the spiral reads
at the default view.

## Loop G1: device tiers and the frame governor (2026-10-28)

The iPhone 11 (`iPhone12,1`, A13, 1792×828, 60 Hz) is the minimum target. Sharp's whole-pixel
rule (`floor(828 / 480)` = 1) gave it the biggest pixel image of any phone, 1792×828 (1.48 MP,
against the Pro Max's 1434×660, 0.95 MP, with about half its GPU), and the orchestrator's first
bench there read 58.2 fps, 1 % low 25.1, worst frame 44 ms (docs/design/graphics.md predicted
it). What changed (`tiers.gd`, `governor.gd`, `main.gd`, `bench.gd`, `settings.gd`,
`settings_panel.gd`):

1. **The pixel image is a budget per level** (`Tiers.image_scale`): the style's own scale, Low
   and Medium one step coarser (as in loop 2b), then coarser until the image fits the level's
   megapixels: High 0.96 (the Pro Max's own image), Medium and Low 0.5, Ultra 1.6. So the iPhone
   11 at High draws 896×414 with High's shadows and effects (and the SE 2 / 3 667×375); every
   phone that already scaled by 2 or more is unchanged (the Pro Max 1434×660, the 6.1" 1266×585),
   and so are all four styles and Low and Medium everywhere (`check_tiers.gd` compares 48 sizes ×
   styles × levels with loop 2b's rule).
2. **Auto and Ultra** (the Quality table above): Auto, the default, picks the level from the model
   id at launch (`Tiers.for_model`); the settings panel's Obraz tab shows Auto (with the level it
   picked under it), Niska, Średnia, Wysoka, Ultra, now in three rows so five choices fit the SE.
   Ultra is High plus the 4096 shadow map and 16 reflection steps, with a budget that keeps a ×1
   image where a phone had one (the iPhone 11's look before G1, for anyone who picks it).
3. **The frame governor** (`governor.gd`, docs/design/graphics.md 4.3): it counts **missed
   refreshes** (each frame's time against the display's clock: a 61 ms frame misses 3, steady
   20 ms frames one in six, a 20 ms frame followed by a 13 ms one none) and, when more than 5 %
   of the refreshes in the last 3 s (and the last half second) were missed, drops one level of
   extras: the CPU's (traffic 100 → 80 → 60 %, pedestrians 100 → 70 → 50 %) when the late
   frames' own CPU work was over 12.5 ms, else the GPU's (reflection steps × 0.6, then the small
   things' sun shadows); it raises the last one back after 30 s with under 0.5 % missed, never
   in a wide view, at most one change every 10 s, the wait doubling (to 240 s) when a drop
   follows a raise within it. It never touches the pixel size, the shadow map, glow, the
   landmarks, the ghost, the river or the night lights. It runs in a normal launch; the bench,
   the probe, the BENCH minute and test runs hold it (`--governor=on|off|log`). Every change is a
   `governor:` line in the log; the overlay's last line shows its levels.
4. **The view rule** (fixed, not adaptive): in a view over 150 m (back under 135 m) or flying,
   the small things' sun shadows are off (lamps, signals, parked cars, columns, shelters: one or
   two pixels wide there): shadow pass −15 draw calls zoomed out (220 m), −11 from the helicopter.
5. **The BENCH card** shows the image and its scale, the quality as `Auto→High (iPhone12,1)`,
   frames **late** more than 1 ms past the frame interval, the **missed refreshes**, and the
   governor's state on the fps-per-10-s line; the log adds loop 2b's measure (0.5 ms past) and
   the late frames by how late, with the slowest and when they came. No rescue call comes in
   during the minute any more: the first call (60 s into play) landed in it and was every card's
   worst frame (61 ms on the iPhone 11, 100–117 ms on the Pro Max).

**On the phones** (started with `devicectl`, no debugger; the bench route's minute, day, traffic
Normal, Point; the iPhone 11 at room temperature, thermal state nominal; before = main at
`6d4629a`):

| Phone, build, quality | Image | fps | 1 % low | Worst frame | Late (> 17.7 ms) | Missed refreshes | > 17.2 ms (loop 2b's measure) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| iPhone 11, before, High (3 runs) | 1792×828 ×1 | 59.9 / 60.0 / 60.0 | 49.6 / 49.4 / 51.3 | 79.4 / 61.0 / 61.6 ms | | (the call's 61 ms frame: ~3) | 6.8 / 13.0 / 6.0 % |
| iPhone 11, after, Auto → High (3 runs) | 896×414 ×2 | 60.0 | 50.3 / 50.2 / 50.2 | 60.8 / 61.5 / 61.1 ms | 1.4 / 1.6 / 1.7 % | 3 (the call) | 7.0 / 7.6 / 7.0 % |
| iPhone 11, after, Auto, call held (final build) | 896×414 ×2 | 60.0 | **56.6** | **18.7 ms** | 0.4 % | **0** | 2.2 % |
| iPhone 11, after, High at ×1 (`--lines=480`, 2 runs) | 1792×828 ×1 | 59.9 | 48.9 / 53.1 | 61.1 / 66.6 ms | 6.3 / 0.1 % | 3 (the call) | 14.7 / 1.0 % |
| iPhone 11, after, High at ×1, 3 minutes, call held | 1792×828 ×1 | 60.0 | 57.2 | 18.0 ms | 0.1 % | 0 | 3.2 % |
| iPhone 11, after, Medium | 896×414 ×2 | 59.9 | 49.4 | 77.7 ms | 2.2 % | 4 (the call) | 3.1 % |
| iPhone 11, after, Ultra | 1792×828 ×1 | 59.9 | 53.0 | 66.7 ms | 0.0 % | 3 (the call) | 1.2 % |
| Pro Max, before, High | 1434×660 ×2 | 59.9 | 47.5 | 117.4 ms | | | 10.0 % |
| Pro Max, after, High | 1434×660 ×2 | 59.9 | 48.7 | 115.8 ms | 0.0 % | 6 (the call) | 5.9 % |
| Pro Max, after, Auto → Ultra | 1434×660 ×2 | 59.9 | 50.1 | 100.6 ms | 0.1 % | 5 (the call) | 2.2 % |
| Pro Max, after, Auto → Ultra, call held (final build) | 1434×660 ×2 | 60.0 | **57.3** | **18.1 ms** | 0.2 % | **0** | 1.5 % |

Probes on the iPhone 11 (30 s standing): helicopter (150 m) before ×1 60.0 fps, 1 % low 58.7,
222 draw calls (shadow 85); after Auto ×2 60.0, 52.9, 0 missed, 211 (shadow 74); zoomed out
(220 m) after 60.0, 58.8, 0 missed, 145 (shadow 45). Video memory: Ultra 360 MB on the Pro Max
against High's 336 (the 4096 map, +24 MB).

**What the numbers say.** A cool iPhone 11 no longer stutters at ×1 on the bench route (the
orchestrator's 25 fps 1 % low didn't come back in nine runs): the 1 % low and the worst frame on
the cards were the first rescue call's hitch and the display's pacing, not the frame. The GPU's
own time says why ×1 is still the wrong default: a Metal System Trace (`xcrun xctrace record
--template 'Metal System Trace' --device ID --all-processes`, 6 s at the spawn) shows the A13
busy **88 % of the time at ×1 (14.5 ms a frame: fragment 12.8, vertex 3.1), in its Medium GPU
performance state 95 % of the time**, and frames spanning 16.25 ms (p90 17.2, worst 21.4) on the
GPU; at ×2 it **sits in its Minimum state 99.9 % of the time** (78 % busy at that clock, frames
spanning 15.1 ms, worst 16.5). So ×1 holds 60 only by clocking the GPU up, with no room left for
heat (the A13 keeps ~76 % of its peak in UL's 20-minute stress test), the content loops (2d,
police) or the G2 per-pixel pack; ×2 holds it at the GPU's lowest clock. On the Pro Max the trace
reads High at the Minimum state 100 % of the time and Ultra 86 % (Medium 14 %): Ultra costs GPU
the Pro Max has. The trace's start stalls the app for ~11 s on iOS 27 (the trace windows were
2–3 s there); attaching by name or pid fails on both phones.

**Pacing modes.** A launch on the iPhone runs in one of two modes: the main thread waits for
the display inside "draw" (11.6 ms of it), and then 1.6–16 % of frames come 1–8 ms late with the
next as much early (every refresh still drawn: 59.95 fps over the minute), or it waits outside
the frame's phases (draw 1.1–1.9 ms) with almost no such jitter. Which one varies by launch at
either image size; ×1 jitters four times as often as ×2 in the first mode. That is why the card
counts missed refreshes and the governor reads only those: a governor on "frames over 17.7 ms"
would read 1.6 % late at ×2 and never come back up (it raises under 0.5 %).

**The governor on the phone** (`--notitle --free --governor=log --stress=wait:40
--stress-from=15 --stress-to=35`: 20 ms of waiting in the draw phase from 15 to 35 s): dropped
the GPU's level 0.8 s after the load began (7.1 % missed) and again 10 s later (25 %), none once
the load ended, then raised them back at 64.9 s and 95.0 s (0.28 % and 0.17 % missed over 30 s).
On the Mac the same. In ten minutes of calm frames, or of the display's jitter, it changes
nothing (`check_governor.gd`).

**On the Mac** (M4 Pro, Metal Mobile, the four budget views at 2868×1320, before → after, High):
draw calls spawn 3D 53 / shadow 35, river 36 / 24 unchanged (the 2D pass moves ±5 with what the
HUD shows); zoomed out shadow 59 → 44, helicopter 87 → 76 (the view rule). Bench (three
interleaved runs each, uncapped): traffic + trams + people 0.48 / 0.50 / 0.55 → 0.45 / 0.51 /
0.45 ms, the game loop (the governor's per-frame work is inside it) 0.08 / 0.08 / 0.07 → 0.06 /
0.09 / 0.06 ms. At High the Pro Max's image is pixel for pixel the same (0.00–0.01 % of pixels
differ at the spawn by day, by night and over the river at night); from the helicopter 0.39 %
(the small things' shadows). Ultra against High: 2.5 % by day, all on shadow edges (the 4096
map's finer texels), 0.23 % over the river at night (16 reflection steps), 0.01 % at night.

Screenshots: `shots/g1/` (1792×828 before / after Auto, 2868×1320 before / High / Auto→Ultra and
2532×1170 before / after, day, night, the river at night, the helicopter; the Obraz tab at
1792×828 and on the SE; the overlay).

## Loop G1b: a sharp picture with a fallback (2026-10-29)

The user's decision after the iPhone 11 before/after crops: the iPhone 11 gets the **sharp**
picture by default, with a fallback. G1 gave it High's 0.96 MP budget, so Sharp's ×1 (1792×828)
became ×2 (896×414); a cool iPhone 11 holds ×1 (G1's 3 minutes: 0 missed refreshes) but with the
A13 88 % busy in its Medium GPU state, and the governor never changes the pixel size live. What
changed (`tiers.gd`, `governor.gd`, `settings.gd`, `main.gd`'s quality and image code,
`settings_panel.gd`; docs/design/graphics.md 4.5):

1. **Auto starts sharp** (`Tiers.budget_binds`, `auto_scale`): under Auto, where the level's
   budget makes the image coarser than the style's own scale, Auto draws the style's own scale
   with that level's effects ("High ×1": not Ultra's 4096 shadows or 16 reflection steps). On
   the phones that is only High with Sharp on the iPhone 11 (`iPhone12,1`, 1792×828) and the SE
   2 / 3 (`iPhone12,8`, `iPhone14,6`, 1334×750); the iPhone 8 and the XR have those screens but
   Low / Medium (already ×2 by their step); every other phone and style has one scale either way
   (`check_tiers.gd` walks all 40 iPhone ids × 4 styles). Mac windows under 960 lines over
   0.96 MP (1366×768, 1440×900, the shots' 1792×828) are sharp too. Manual levels keep G1's rule
   (Wysoka ×2 on the iPhone 11, Ultra ×1); the Pro Max is Auto→Ultra ×2 as before.
2. **Struggled**, from the governor's own data (`governor.gd`'s session **tally**, counted only at
   Auto's image, past the 5 s settle after a start, a load or a pause, outside wide views and
   the helicopter): the GPU's extras dropped by a **GPU-bound** load for 60 s in all and a tenth
   of the counted play (one drop that a calm half minute undoes is 30 s, a passing load; a
   second, or one that didn't calm the frames, is the image; a 15-minute drive needs 90 s), or
   **3 counted minutes in a row** missing over 2 % of their refreshes GPU-bound (a steady loss
   under the governor's 5 % drop line). CPU-bound misses don't count, nor a GPU drop a CPU-bound
   load made once the CPU's extras were gone. **Calm**: 3 minutes counted without that. The
   verdict is written the moment it is known (iOS kills a backgrounded app without notice).
3. **The fallback and coming back** (`Tiers.sharp_*`, kept in `settings.cfg` `[auto_image]`):
   after a struggle the next launches draw the level's budget (×2); 2 calm sessions there bring
   the sharp image back on trial; a struggle on trial doubles the wait (2 → 4 → 8 → 16, capped),
   a passed trial (as many calm sessions as the wait) puts it back to 2, a struggle at the
   fallback restarts its count. A phone that struggled on one hot day is sharp again a day or
   two later; one that can't hold ×1 spends one launch in 17 on it once capped, with the governor
   guarding that one. The switch is per launch, never live.
4. **Never written** by `--nosave`, test runs (bench, probe, autopilot, shots) or
   `--last-session=struggled|calm` (start as if the last session struggled / was calm). The log's
   `quality:` lines say what Auto picked and why (`quality: Auto→High ×1 sharp (iPhone12,1) ·
   image 1792x828`; `quality: Auto→High ×2 fallback (last session: GPU extras down 74 s of 410) ·
   iPhone12,1 · the sharp image again after 2 calm sessions (0 so far) · image 896x414`) and the
   session's verdict (`quality: this session at High ×1 sharp was calm · tally …`).
   `--governor=log` adds the tally to its status lines and a `governor minute N:` line a minute.
5. **Where the player sees it**: Settings → Obraz's Auto button `auto · High ostry` / `auto · High
   ×2` (`auto · High` where the budget doesn't bind, e.g. the Fine style), kept up to date when the
   style changes; the overlay's last line `High ×1 sharp · gov …` / `High ×2 fallback · gov …`; the
   BENCH card `quality Auto→High sharp (iPhone12,1)` / `Auto→High fallback (iPhone12,1)` beside
   its `image 1792x828 (×1)`. No toast (optional in the brief; BACKLOG).
6. **Thermal state**: still not readable from Godot 4.7.2 (no OS, DisplayServer, Engine,
   RenderingServer or Performance method), so it isn't part of the rule.

**On the iPhone 11** (iOS 26.5, started with `devicectl`, no debugger, day, traffic Normal, Point,
`--nosave`: the phone's own settings and save untouched; in run order):

| Run | Image | fps | 1 % low | Worst frame | Late (> 17.7 ms) | Missed refreshes | Governor |
| --- | --- | --- | --- | --- | --- | --- | --- |
| BENCH minute at Auto (`--bench-button`), phone cool | 1792×828 ×1 sharp | 60.0 | 54.4 | 19.0 ms | 3.7 % | **0** | held |
| 15-minute drive, Auto, `--autopilot --governor=log` (17.7 min, 1062 s counted) | 1792×828 ×1 sharp | **60.0 every minute** (17 of 17) | | | | **5 of 63,728** (all in minute 1; 1 GPU-bound) | on: **0 changes**; calm at 180 s; the struggle rule never close (0 s down, no bad minute) |
| BENCH minute, `--last-session=struggled` (forced), after the drive | 896×414 ×2 fallback | 60.0 | 56.9 | 18.6 ms | 0.3 % | 0 | held |
| BENCH minute at Auto, final build, after both (phone warm) | 1792×828 ×1 sharp | 60.0 | 58.7 | 17.1 ms | 0.0 % | 0 | held |

The drive's per-minute lines (fps, missed refreshes, GPU-bound, GPU extras down) are 60.0 / 0 / 0
/ 0 s in every minute from 2 to 17 (minute 1: 5 missed, the arrival). Draw calls on the BENCH
cards 124 / 125 (main 45, shadow 41), as in G1; video memory 307 MB at ×1 against 276 at ×2. So
a room-temperature iPhone 11 drives 17 minutes of day traffic at ×1 without the governor
stepping in: the first data point for graphics.md's G0 soak (still to do: night, rain at night,
the 20-minute H3 bar, a warm room). The 1 % low and "late" on the first card are the display's
pacing mode (late frames with no refresh missed, Loop G1 "Pacing modes"), not the frame.

**On the Mac** (M4 Pro, Metal Mobile, `--bench` at 2868×1320, 3 runs each, before = `613ff38`):
the change adds no geometry, materials or draw calls (116–120 before, 116–118 after: traffic
varies); scripts 0.86 / 0.85 / 0.92 → 0.95 / 0.84 / 0.84 ms, the game loop (the governor and
the tally inside it) 0.11 / 0.11 / 0.14 → 0.16 / 0.12 / 0.13 ms, within the runs' spread (the
before runs came after the after runs, not interleaved). Per frame the tally adds a comparison
in `frame()` and a few additions in `tick()`; the verdict check is two booleans until a verdict
is due; a `minute` line is built once a minute.

Screenshots: `shots/g1b/` (the Obraz tab at 1792×828 at Auto sharp, `auto · High ostry`, and in
the forced fallback, `auto · High ×2`, with the ×2 city behind it).

## Loop 3g-1: the police, part one (2026-10-28)

The design is docs/design/police.md (the user chose the gentler police: warnings and jokes,
**never a fine, nothing taken from the wallet**, nobody arrested, nothing rammed, short chases
that end by themselves). Part one builds the patrol cars, the speed traps, the chases and the
pull-over; part two (loop 3g-2) the city guards, the guard car, the pedestrian-zone cap, the
clamp, the escort on rescues, the race and side-job ties, the chase framing (Phantom Camera),
the synthesised sounds and the PixelLab portraits.

**Who.** Patrol cars ("radiowóz": the white estate with the blue band and POLICJA from loop 2c)
drive in the traffic, main and secondary roads only, at most 0 / 1 / 2 / 3 at a time for the
Traffic levels Empty / Low / Normal / Busy (`traffic.gd`'s new POLICE kind). After one you met
leaves, the next comes 90-180 s later (*guess*: a 10-minute drive should meet two to four), after
one you never met 10 s later, and never within 200 m of you in a cooldown. **Speed traps**: the
seven spots of police.md, four of them in today's map (`game/data/police_traps.json`, found by
road name on the lane graph: Aleje Jerozolimskie by the National Museum, the Wisłostrada north
of the cross-city rail bridge, Jana Pawła II south of Rondo ONZ, Wybrzeże Szczecińskie); three
are out each day, picked by the date like the roadworks (`--barriers=YYYYMMDD` picks that day's).
A trap is a patrol car parked on the kerb facing the traffic, lights off, with an officer in
lemon hi-vis 3 m upstream (a pedestrian instance: +0 draw calls). Loop 3d moves the spots into
the bake.

**What they see** (`police.gd`, 5 times a second, every unit in one pass): distance, a 180° cone
in front of a patrol car, and sight along the roof grid (no raycasts); your lane, its speed limit
and the stop lines you cross from the lane graph. Offences: speeding past a patrol car (limit +
25 km/h within 40 m, in its cone), a red light within 60 m in sight, 3 s the wrong way up a
one-way street, bumping a police car (2-6 m/s); a ram (> 6 m/s) counts double. The helicopter is
never an offence; a rescue in pickup or drop-off is never seen.

**What happens** (police.md section 4):

| | Numbers |
| --- | --- |
| A warning | a megaphone bubble ("Policja"), a whoop, the first rooster's outline blinks 2 s, one strike; one fades every 45 s; at most one line every 8 s in the city and 20 s a unit |
| Koguty 1 | two strikes within 45 s, an ignored lizak, or a ram; one chaser, lights and siren on; cap 30 s |
| Koguty 2 / 3 | a ram (once in 10 s) or a second unit seeing you within 60 m (once the level has held 5 s, *guess*): + a blocker parked across the far lane at a junction 250-400 m ahead / + a two-car roadblock in a V at the next junction (a gap in the middle) and, at night, a searchlight; caps 40 / 45 s from the chase's start; no level rises in a cap's last 10 s |
| Chasers | the player's top speed × 0.92, 1.2 × traffic's acceleration, at least 10 m behind you (they never ram; they stop when you stop), through reds at 30 km/h, on the lane graph only (re-planned once a second, one unit a frame, `distances_to(…, 800 m)`; beyond that, the way whose end lies nearest you); cars ahead give way (the kerb lane, 5 m/s for 3 s) |
| Search | 120 m from every chaser, or 4 s out of sight: they drive to where they saw you, then round there; 8 s later (4 s under a bridge deck or in a tunnel) you escaped: +15 respect (`wallet.add_respect`), the toast *UCIECZKA! · ESCAPED!*; seen again within 50 m: back to the chase |
| End of shift | the cap: *KONIEC ZMIANY · END OF SHIFT*, nothing won or lost; taking off in the helicopter ends it too (its own line) |
| Lizak | over the limit + 20 km/h in a trap's 40 m: the officer turns and waves the paddle, two whistles, the pill *ZATRZYMAJ SIĘ PRZY POLICJANCIE*; stop within 20 m of the officer under 8 km/h: the pull-over; 30 m past the officer: koguty 1, the trap's car pulling out; the trap re-arms after 60 s |
| Pull-over | under 1 m/s with a chaser within 15 m (bumper to bumper) for 1.5 s, or the lizak stop: the car is held, the chaser stops behind with its lights on, the radio ducks 6 dB, the pedals step aside for the card; the conversation ends in a caution, one more in the **Zeszyt pouczeń** (the joke notebook in the save, counted per day; the fifth of a day has its own line) |
| Cooldown | 180 s after any of them: warnings still, no chase but for a ram |
| Start grace | no chase in the first 180 s of a session (no warnings at all in the first 60 s), unless the police have already met you |

**The pull-over** is a Dialogue Manager conversation (`game/dialogue/police.dialogue`: only the
flow, compiled at runtime; the words are in `dialogue.json`, picked by `police/police_talk.gd`):
the opener (Sierżant Bogdan, or Posterunkowy Kacper at a trap; tagged for the first contact, a
kebab or słoiki run, a trap, or generic), one or two reply buttons (the first is picked after
5 s), the caution. Every beat can be tapped through; about 7.5 s in all. The card
(`police/police_balloon.gd`) is the HUD's one card recipe: Polish over English, a police-blue
edge, the speaker's face from simple shapes (the PixelLab portraits come in part two).

**On screen** (`hud.gd`): the koguty (three light-bar domes beside the wallet: lit blue and red
in a chase, grey and blinking while searching), the pill with the end-of-shift countdown
(*POŚCIG · KONIEC ZMIANY ZA 0:27*), the edge breath (blue and red at the screen's edges, 10 % at
most, once a second), a rooster at the screen's edge for a chaser out of sight, the lizak paddle
over the officer, chasers and the known traps (after the radio host read them, or once you passed
one) on the minimap. The light bars flash in `actor.gdshader` (SIREN: off, the lenses dim; on,
blue and red in turns at 2.5 Hz, glowing by day too); at night their blue and red pools on the
road and the koguty-3 searchlight are one glow MultiMesh, shown only while a light bar flashes.
The sounds are placeholders from the ones already here (the far siren on one positional voice of
the six; the whoop, whistle and stamp pitched from the siren, the tram bell and the soft knock).

**The add-ons.** beehave (bitbrain, 2.9.3) gives each police unit a behaviour tree
(`police/police_unit.gd`: pull-over, roadblock, blocker, search, chase, trap, patrol), ticked by
hand at 5 Hz right after the perception pass; escalation stays in `police.gd`, the trees only
move their car through the traffic API. Dialogue Manager (Nathan Hoad, 4.1.0) runs the
conversation. Both editor plugins are off: the trees use a lean `police/police_tree.gd` (no
debugger registration, no autoloads); `police.gd` creates Dialogue Manager and has it compile the
`.dialogue` text (~70 ms on the Mac, done while the city builds), and clears a reference cycle
Dialogue Manager 4.1.0 leaves in its resource (it leaked at exit). One local line in beehave: no
debugger messages without a debugger (headless runs printed an ERROR at every tree interrupt).

**Cost** (`--probe` at 2868×1320, Metal, Mobile, Classic, High, Normal traffic; before = the code
at `6d4629a`; "koguty 3" = `--police=3 --police-auto=still`, the chaser standing behind, the
blocker and the roadblock out of sight):

| View | Draw calls, all passes: before → after → koguty 3 | Main / shadow / 2D in koguty 3 (before) |
| --- | --- | --- |
| Spawn | 133 → 133 → 135 | 54 / 36 / 45 (53 / 35 / 45) |
| Default view over the river | 106 → 104 → 109 | 37 / 25 / 47 (36 / 24 / 46) |
| Zoomed out (`--size=220`) | 169 → 167 → 170 | 65 / 60 / 45 (64 / 59 / 46) |
| Helicopter | 223 → 222 → 225 | 100 / 87 / 37 (99 / 86 / 38) |
| Night: spawn / river | 110 / 91 → 107 / 88 → 112 / 94 | the halos +1 while a light bar flashes |

The POLICE MultiMesh is +1 in the main and +1 in the shadow pass (a small caster: none on Medium),
the halos +1 at night while lights flash: at most +3 at every view. The HUD's police shapes are
drawn as one triangle array a surface, and so are the minimap's marks now (they were a draw call
each: the 2D pass fell by 3-4 at every view, which pays for the pill). Triangles: 636 a police
car, at most five drawn in a koguty 3 chase (≤ +3.2 k a pass). Scripts (bench, Mac, three runs
each interleaved, capped at 120 Hz): police 0.03 ms calm, 0.07-0.08 ms in a koguty 3 chase, the
HUD +0.04 ms then; traffic unchanged (0.62-0.65 ms). Memory: +2 MB static, +4 MB more for
Dialogue Manager's scripts (loaded at the start). No new shader.

**Testing aids** (flags in the table below; the log with `--police-log`: `police: warn speed
(unit 2)`, `police: L1 (lizak ignored, 30.4 m past the officer)`, `police: escaped after 16.7 s`,
`police: caution n=1 today`, `police: wallet 0 zł → 0 zł`). `game/tools/check_police.gd`
(verify step `police`): P11, every group and tag in `dialogue.json` with Polish and English and
the lengths (bubbles ≤ 70 characters, replies ≤ 28), the flow compiles; P12, the state machine on
a synthetic road with a stand-in car, traffic, HUD and a wallet that fails on any write but
respect and the notebook (19 cases: grace, strikes, caps, the last-10-s rule, escape, hiding,
seen again, pull-over, cooldown, ram, helicopter, the złoty, starts = ends), and a scan of the
police's code for anything writing the złoty. `police-runs` (P1-P7 on the prebuilt city, each
judged by its `police:` lines and the wallet line) and `police-soak` (P13: the autopilot roaming
Busy traffic at twice the limit with the police on at once; 3 minutes in the verify set, the full
10: `NW_SOAK_MINUTES=10 tools/verify.sh --only=police-soak`, ~70 s).

**The frame governor** (loop G1) lowers the traffic's density when frames are CPU-bound; a police
car is never thinned out for it (`traffic.gd`), and a unit in a chase, a trap or a block is kept
until `police.gd` lets it go. The officers stand in the people's MultiMesh after the walkers'
slots, which the people's limit doesn't touch.

What only the phone can tell: the siren against the radio (a placeholder), how a chase feels at
60 fps (the chasers' 0.92 speed, the 30 km/h at reds, the 10 m gap), whether the edge breath is
too much or too little, whether the light bar reads by day at 80 m on the 2× pixel, and whether
the card's tap-through feels right.

Shots: `shots/loop3g1/` (gitignored), at 2868×1320 and 1792×828: a koguty 2 chase with the HUD by
day and at night (and close: the lenses taking turns, the blue pool at night), the four trap
spots close up, a trap at night, the lizak over the officer, the pull-over card (at a trap, and
the first contact).

## Sectors and streaming (loop 3c, 2026-10-29)

The city is built and loaded in 512 m sectors (docs/DEMO.md 2.4), keyed `floor(x / 512),
floor(z / 512)` from the map's origin: today's map is 8 × 4 = 32 of them (i −4..3, j −2..1).
The demo's bigger box (loop 3d) only adds sectors.

- **The split** (`tools/bake_sectors.py`, after the bake chain, ~1 s): `game/map/index.json` holds
  what the whole map needs at once (the lane graph, decks, approaches, aprons and tunnels, the
  water's edge, the kerbs and islands the car feels, the points of interest and addresses, the
  landmark outlines and `site_parts`, and what traffic, trams, people, missions, the minimap and
  the easter eggs read: roads, paths, areas, trams, platforms, signals, guard rails, columns,
  parked cars, scanned trees), and `sectors/<i>_<j>.json` each sector's features in
  centrum.json's shape: every way, area or building within 48 m of the sector, with its full
  geometry (a way crossing a border is in both), every point thing within 8 m, a floating
  part's supports, each building's surroundings for its shop sign (roads within 40 m, roofs
  within 8 m), the LoD2 buildings near it (`lod2_runs`: vertex ranges of `lod2.bin`). The AO,
  lamp-light and surface maps stay whole, one texture each shared by every sector (see below).
- **One sector** (`map_builder.gd` `build_sector`) runs the same stages as the whole city over its
  file and keeps only the triangles (by their centre, so each 256 m tile is in exactly one
  sector), MultiMesh instances (by position, 512 m tiles = sectors) and collider faces (by centre)
  that lie in it, and its cells of the roof and picking grids. `build` (the whole city at once,
  `--monolithic`) is unchanged. **The sectors together are the whole city exactly**:
  `game/tools/check_streaming.gd` compares every tile mesh's vertices, every MultiMesh's instances,
  every collider face, the roof and picking grids and the landmark cards (559 meshes and
  MultiMeshes, 232,521 faces: identical).
- **The prebuilt city** (`tools/bake_city.gd`, with a renderer, ~16 s): `sectors/s_<i>_<j>.scn`
  (28.8 MB for 32), `proxies.scn` (2.7 MB), `index.res` (2.3 MB: the map node with its heights,
  decks, tunnels, water test, roof and picking grids, kerbs, sector heights and the game's part of
  the index) and `shared/*.res` (6 MB: the materials, textures and meshes every sector shares,
  saved once so all sectors use one copy and the per-frame uniforms reach them all).
- **Proxies** (`sector_proxies.gd`): one mesh and one material per sector from the index alone:
  the ground as a 32 m grid coloured by what covers it, the main roads as strips, the buildings
  and landmarks as a skyline of boxes from the roof grid (8 m, merged along rows), trees as blobs
  per 24 m; at most 14,724 triangles and 84 KB a sector, no shadows, visibility range 2,400 m with
  fade Disabled. A sector's proxy shows only while the sector is not in full detail
  (`--sectors=proxies` to see them).
- **The streamer** (`sector_streamer.gd`): full detail for the 3 × 3 round the camera's focus,
  the next row once the focus is within 192 m of its sector's edge (a square of 704 m round the
  focus), and every sector the view needs (its box from its lowest ground to its tallest roof,
  grown by 128 m, meets the camera's frustum: a tower two sectors off can stand in the view);
  out again 256 m past that (and out of the view grown by 256 m). One sector at a time, a
  thread loads and instantiates its scene (runtime path: builds it from its file); the main thread
  adds its nodes under a hidden root a few a frame (each kind's recent cost must still fit the
  frame's 3 ms), colliders first, and shows it (hiding the proxy) once all are in; the next load
  starts after that. The car's own sector and any within 40 m of it load at once if a jump put
  the car somewhere new (`forced`; the governor counts afresh after one). At the start the
  sectors within 320 m of the start go in at once, the rest of the ring streams in.
- **Both city paths**: the exported game and `--prebuilt` load the prebuilt sectors; the editor
  (runtime) path sets up the index from `index.json`, runs a roof pass over every sector's file
  (missions, eggs and the helicopter read the roof grid over the whole map at the start) and
  builds the sectors round the start, then the rest on a thread as the camera moves.
- **What the game's systems see**: the map node is the same object as before (heights,
  `drive_height`, the water test, `top_height`, the pick grid are global); traffic, rivals and
  missions live on the global lane graph; new sectors get the time of day, the quality's and the
  governor's small-caster shadows, the fine detail and `--exp` from main.gd (`_on_sector_ready`).
  The minimap stays one global mesh (today's map is small; loop 3d's pre-rendered image waits).
- **The AO, lamp-light and surface maps** stay one texture each (24 MB of video memory today):
  the post pass (water reflections) and the moving vehicles sample the light and surface maps
  anywhere on screen, so per-sector slices need a resident window texture, which on today's
  3.5 × 1.8 km map would be bigger than the whole maps. Loop 3d (6 × 6 km: ~150 MB as whole
  textures) needs that window: see docs/BACKLOG.md.

| Loop 3c numbers (Mac, Metal, mobile renderer) | Before (monolithic `city.scn`) | After (streamed) |
| --- | --- | --- |
| Pixel diff, 10 spots at 2868×1320 (5 on borders), `--monolithic` vs prebuilt streamed | | at most 0.015 % of the pixels (the minimap's random markers); 3D view identical |
| Draw calls at the four probe views (3D + shadow): spawn, river, zoomed out, helicopter | 89, 61, 109, 175 | 87, 59, 108, 174 |
| Memory at the spawn (probe): static / video | 140 / 336 MB | 140 / 263 MB (−22 % video; the city's own buffers 158 → 86 MB) |
| Start, runtime path (`city built`, 3 runs) | 11.0, 10.9, 10.9 s | 5.99, 5.73, 5.75 s (2.0 s of it the roof pass over every sector) |
| Start, prebuilt path (3 runs) | 1.07, 1.07, 1.04 s | 0.61, 0.57, 0.58 s |
| Exported .pck | 47.3 MB (city.scn 37.1 + centrum.json 5.3) | 46.5 MB (sectors 28.8, shared 6.0, proxies 2.7, index 2.3; no JSON); 47.2 MB with loop 3g-1 merged |

Commands: `tools/verify.sh --only=streaming` (the identity, the pixels at 10 spots and a
3-minute soak, ~2-4 min, a window opens); the 15-minute soak:
`godot --path game --resolution 1280x720 --script res://tools/check_streaming.gd -- --only=soak --soak=15`.
On the phone (loop G0+): `tools/device_run.sh --label=stream_soak --wait=600 --done='^stream soak
stats:' -- --notitle --prebuilt --stream-soak=6 --stream-log` (each load's main-thread ms and the
soak's numbers; see Loop G0+ for the phone's).

## Map review A: the bridges, flyovers and tunnels (2026-10-29)

Every deck group (19: 73 pieces, 174 piers), the 3 tunnel roads and their 4 portals looked at
one by one at 1792×828 by day (both ends, the span from the side, from above), the lit ones by
night, and driven. What was wrong and is fixed, all in the bakes (no builder change):

- **A kerb and an edge line across the road at a deck's joint** (`bake_roads.bake_edges`, new
  `JOINT_ALONG` / `JOINT_SIDE`): where a deck's carriageway meets the next one across its pinned
  end, each side saw only its own level's road beyond it and ran a kerb and an edge line across
  the carriageway (Most Poniatowskiego's east end on both carriageways, its Praga ramps, the
  viaduct's west end, the Jana Pawła II viaduct's north end: 9 kerb runs, 49 m). It read as a
  stop line, and the ground side's kerb was in `kerb_feel`'s lines, so the car took a kerb's
  bump driving onto the bridge. Now open (135 m of joint).
- **A footbridge lying across Al. Jerozolimskie** at the viaduct's west end (`UNDER_END` in
  `solve_decks`): a footway bridge mapped on a lower layer (OSM 1172263249, layer 0) crossing
  a road deck within 15 m of its pinned end was held up to the road's height and drawn across
  the carriageway (a paving strip, parapet stubs and their shadow). It stays on the ground,
  where the road hides it.
- **Tram stop shelters on the tracks** (`bake_structures.clear_carriageways`): 14 shelters
  mapped at a stop's position on the rails (one on the viaduct's tram deck at its east end) are
  left out where the track runs at the ground's height.
- **Tree crowns through a deck's edge** (`bake_structures.trim_crowns`): 7 scanned trees beside
  the viaduct, Most Poniatowskiego and Most Średnicowy reached 2-11 m up through the deck's edge;
  their crown scale (`trees3d_crown`) shrinks until they clear the slab (floor 40 %; one 24 m
  tree on the Praga bank still brushes the footway, allowed). A crown over a deck higher than
  the head room (3.5 m, footways 2.5 m) stays.

`check_roads.py`: **C2** also finds a kerb or edge line across the road at a deck's joint with
the ground (3 m or more within 4 m of the end; 12 before, 1 allowed sliver after), **C9** a
scanned crown into a deck (7 before, 1 allowed after); a C3 entry allows the passage under the
viaduct's west end (0.8-2.2 m under the decks' first metres). `check_drive` 0 / 0,
`check_drape` 0. Draw calls at the four views unchanged in the 3D passes (spawn 132 → 134, the
2 in the HUD's 2D pass; river 105 → 105, zoomed out 152 → 154 (2D), helicopter 212 → 212);
vertices 6,119,007 → 6,115,605. Left for later (BACKLOG "From map review A"): aprons that sink
the road under the drawn 10 m ground at five structure ends (the beige wedge at the viaduct's
west end), the night's lamp pools on the ground beside and under decks, Most Poniatowskiego's
unlit approaches, rail tracks ending at different heights, the Tamka footbridge's dip.

## Map review B: the streets (2026-10-29)

Every street at grade, junction and roundabout looked at one by one (the bridges, flyovers, ramps
and tunnels are map review A's). The report with the shots is local (`.handoff/review/`); what
changed in the bake (`tools/bake_roads.py`, street-level functions in a commented block, run by
`bake_osm.py`), each counted over the whole map by the new `tools/check_streets.py` (verify step
`streets`; rules S1-S4, before → after):

- **Junction boxes between dual carriageways** (`Roadbed._junction_boxes`). Where two dual
  carriageways cross, OpenStreetMap maps the halves and leaves the junction's middle unmapped:
  `bake_medians` laid the tram bed (or grass) and its kerb across the junction, and the halves'
  short pieces inside it got lane lines. The quadrilateral where the halves cross is now a
  junction box (a carriageway area with `jn`: no median, no kerb, no lane lines in it): 3 on
  today's map (Al. Jerozolimskie × Emilii Plater, Marszałkowska × Królewska, Świętokrzyska ×
  Emilii Plater). S3 (medians inside a junction, reported only: it also counts real median noses
  at a junction's edge) 20 → 18.
- **Tram beds, not grass** (`bake_medians`): a median is the tram bed when a track runs anywhere
  across it (it looked only at the strip's middle, which a double track straddles): Al.
  Poniatowskiego's tram bed was raised grass with rails on it. S4 (grass medians on tram tracks)
  78 cross-sections → 0; median strips 137 → 134 (48 → 54 with trams).
- **Zebras on the asphalt only** (`clip_crossings`): crossing ways run from pavement to pavement
  and the road's width is an estimate, so the stripes ran on over the kerb, the pavement, tram
  beds and medians (1.0 m an end on average). The stripes are now cut to the carriageway (a red
  cycle path across the road keeps them), pieces under 1.5 m left out: 5,371 → 3,654 m of zebra.
  S2 (zebras with 0.75 m or more off the asphalt) 457 → 0.
- **Poles off the asphalt** (`clear_poles`): a street lamp mapped in a median the bake doesn't
  draw, or a signal pole placed beside the kerb of a width estimate, stood in a lane or a
  junction; each one on the ground's asphalt moves to the nearest spot within 6 m that is 0.5 m
  off it (pavement, island, median, clear of the tracks). 60 moved (the signals keep their order:
  the lane graph's `poles` refer to them by index). S1 58 → 0.

Unchanged: `check_roads` C1-C10, `check_drive`, `check_drape`, the lane graph, stop lines, arrows
and the counts `check_map_data.py` checks. Draw calls at the four probe views unchanged in the 3D
passes (spawn 52 + 35, river 35 + 24, zoomed out 65 + 44, helicopter 100 + 76; the 2D pass moves
by ±4 between runs of the same code), vertices 6,119,007 → 6,109,860 (-0.1 %: shorter zebras).

## Loop 2d-1: Podwózka, the app-taxi side job (2026-10-29)

*Podwózka* ("a lift") is the game's own app-taxi (docs/design/parodies.md section 3; no real app,
name or logo). The joke is the app and its GPS, never the driver or the passenger. Code:
`rides.gd` (the job), `ride_rules.gd` (the stars, the pay and the cards' words as plain rules),
`gps_moments.gd` (the app-taxis in traffic); lines in `data/dialogue.json` (`podwozka_*`).

- **How it's offered**: in the car with nothing else on (one activity at a time, like the kebab
  and słoiki jobs), never in the first 2 minutes of a session (the title screen doesn't count).
  A request card every 75–120 s (not modal; it goes after 10 s), or the top row's
  context button reads **PODWÓZKA · ride app** and a tap brings a request within 2 s. A rescue
  call ringing keeps the button (WEZWANIE) but not the card; taking a ride puts the call off, as
  any job does. Never during a race, a rescue or from the helicopter.
- **The request card** stands beside the car, never over it (`hud.gd` `show_side_card`: the
  right-hand column under the top row, as wide as the room right of the car's spot): `PODWÓZKA ·
  NOWY KURS` (at night `PODWÓZKA · MNOŻNIK ×1,5`, ×1,2 in the rain, ×1,8 both; the English in
  the title row says why), the passenger and their own stars, how far the pin is and the ride's
  length (`Kasia ★ 4,9 · 350 m · 1,8 km`), their note (`podwozka_request`) with its English;
  PRZYJMIJ · Accept, POMIŃ · Skip (M / K). Your rating is on the result card (on a 390-pt phone
  the request card has room for five lines of text beside the car).
- **Pickup**: the app's pin (a teal ring and column, the minimap dot and a dotted teal line) at a
  real address door 150–600 m by road. Half the time the passenger isn't there: they wait 30–60 m
  away along the street or across it, waving under a teal "!" (one mesh each), and say a
  `podwozka_pickup` line; near the pin the hint says "the pin is here, the passenger isn't" and
  the arrow turns to them. Stop within 7 m under 2.5 m/s for 1 s.
- **Passengers** (*guess*): normal 65 %, GPS believer 25 %, in a hurry 10 % (ETA × 0.8, tip ×
  1.2); first names from the jobs' list; they chat every 25–40 s (`podwozka_passenger`, half the
  time the słoiki passengers' `passenger` lines).
- **Where to**: a real address 600–2,500 m by road (west bank), or (30 %) a race finish (not the
  far end of a bridge, not one on the map's edge: Centrum Nauki Kopernik's lies on it). The beacon
  and the arrow always point at the real door.
- **The app's route** is the minimap's dotted teal line: the shortest road, except that 35 %
  of rides get one quirk, which "Nawigacja" announces 200 m before it (`podwozka_gps`):
  - `river`: out to the Vistula's edge and back. River spots come from the map's global water
    test (loop 3c: the streamed city's exported index has no shore runs): `shore_distance` on an
    8 m grid over the map, 3 rows a frame after the city is built (~48 ms in all), each dry-to-wet
    step a point on the edge; the water past it still deep 60 m out (the river, not a pond or a
    fountain), a waypoint 5 m in from the edge with no water within 3 m and no roof over it, a
    road within 70 m in a straight line over dry, open ground; one spot per road edge, both
    carriageways (9 on today's map, by Most Poniatowskiego and along Wybrzeże Kościuszkowskie,
    the same on both city paths). The ride takes the spot that adds least, at most 1.5 km.
  - `zone`: through a park's middle (in from the road on the passenger's side, out on the
    destination's; the city guards' reaction is loop 3g's). `oldtown` falls back to it: today's
    map has no Old Town square.
  - `reroute`: 40 % of the way in the app recalculates once and draws a new line that first turns
    back to the junction behind the car.
  - `rechotka` ("turn at the Rechotka") only by flag until loop 2d-2 places the shops.
  Ignoring the app is always allowed.
- **Stars** (live in the status panel, `★★★★½ 4,5`, a short toast for each change): from 5.0,
  −½ for a hard bump (closing speed over 4 m/s), braking over 18 m/s² or a corner over 15 m/s²
  (2 s apart, at most −2 in all; the słoiki's limits are 16 and 14), −½ per 15 s past the ETA
  (road / 9 m/s + 20 s; at most −1½), −1 for a police pull-over, +½ for arriving within 0.8 of
  the ETA, +½ when a believer's app leg is driven (the waypoint within 15 m; "No widzisz,
  aplikacja wie"). A believer whose leg you skip only grumbles. The final rating is the nearest
  half, 1 to 5.
- **Pay** (*guess*, between kebab and słoiki): fare 15 zł + 9 zł a km of road from the pickup ×
  the MNOŻNIK; tip 40 % of the fare at 5 ★, 25 % at 4½, 10 % at 4, none below; the 5-star streak
  pays +10 zł for each 5-star ride in a row before this one (at most +50; a 4½ keeps the streak,
  below 4½ or a cancel ends it); respect +25 at 5 ★, +10 at 4–4½. A 1.8 km ride by day at 5 ★:
  31 + 12 = 43 zł. **Your rating** is the average of the last 20 rides, the ones a new save
  hasn't driven counted as 4,87 (nobody has a 5.0); it and the streak are kept in
  `user://save.cfg` (`[keep]`, `wallet.gd`).
- **The end**: at the door (7 m, under 2.5 m/s) Nawigacja's "you have arrived" line, then 2.6 s
  later the result card beside the car (one thing at a time): the stars, the passenger's
  `podwozka_rating` comment (5, 4, low, or police if pulled over), the pay (the fare with the
  MNOŻNIK, the tip, the streak), your rating and what moved the stars. It has no button: it goes
  after 12 s or once the car is 25 m off (M closes it). While a ride's request or result card is
  up, the app-taxis' GPS bubbles and the radio host's next line wait (a caption already up slides
  out); they come after. **Cancel**: the ✕ on the status panel any time, or the passenger gives up after
  3 × the ETA (pickup and ride each): no pay, no stars lost, the streak ends.
- **The police**: `police.gd` calls `rides.on_pulled_over()` when a pull-over's conversation ends
  (police.md 8.3): exactly one star from a running ride (none while picking up), and the result's
  comment becomes the `police` one. Escaping a chase costs nothing. Verify step `ride-police`:
  ride 8 with `--pullover=generic --pullover-frame=1500` on the prebuilt city prints
  `ride: stars 4.0 (police −1.0)` once.
- **GPS moments in traffic** (`gps_moments.gd`, parodies.md 3.2): every 45–90 s one Podwózka car
  (the hatch with the phone on its roof, loop 2c) on screen within 80 m of the view's centre (and not behind a building)
  stops dead for 4 s ("you have arrived": the cars behind wait, one may shout), takes the way back
  at the next junction where a U-turn is possible (recalculating), or, on a road by the river,
  pulls up where it comes nearest the water, waits 3 s and turns away; its driver says a
  `podwozka_driver` line. Never two at once; no new geometry (`traffic.gd` `turn_next`).
- **Checks**: `game/tools/check_rides.gd` (verify step `rides`, under a second) feeds the rules
  synthetic events: the star table, the pay table (with the design's 43 zł), the streak, the
  cancel rules and the rating, and every dialogue group and tag the code asks for (Polish and
  English, bubbles ≤ 70 characters, buttons ≤ 28). The verify step `ride` drives ride 8 (a
  believer waiting 34 m from the pin, the river quirk) with the autopilot and `--parody-log`.
  `check_hud.gd` lays out the request card, the ride's status and two result cards at their
  longest, and fails a ride card that covers the car's spot.
- **Cost** (probe, Metal, 2868×1320, Classic, traffic Normal, day; before = 613ff38 from a copy
  in the same session, measured before the 3c streaming merge): the spawn view 134 draw calls (main 52, shadow 35, 2D 46) before and
  after, side jobs + eggs 0.039 → 0.044 ms. During a ride (ride 19 on the autopilot, Powiśle):
  126 draw calls (37 / 30 / 60), side jobs + eggs 0.088 ms; a kebab delivery measured the same
  way: 140 (46 / 29 / 65), 0.068 ms. Nothing new in the 3D passes but the ride's pin (the job
  beacon's ring and column), the waiting passenger (one mesh) and the "!" (one mesh), fewer than
  a kebab customer's beacon person; the minimap's dots draw in its overlay's existing canvas
  item. The river spots are found a few shore samples a frame after the city is built (683
  samples, 24 a frame).
- **Screenshots**: `shots/loop2d1/` at 2868×1320 and 1792×828: the request card (`pro`, `i11`
  frame 60), the pickup with the passenger under the "!" (`pickup_*`), the ride mid-way with the
  app's dotted route and Nawigacja's river line (`pro`, `i11` 1500 and 3000), the result card
  (`pro2`, `i112`; after the merge, beside the car: `end_i11`, `end_pro`), a GPS moment by the
  spawn (`gps_*`).

## Map round 2: the ground under structure ends, the night streets (2026-10-29)

What reviews A and B left, by rule (the demo box comes later, loop 3d):

- **D5, the road under the drawn ground** at structure ends. An apron holds `terrain_height`
  under a deck's or tunnel's end below the 10 m grid, but `_build_ground` drew the raw grid, so
  the road, its carriageway area, kerbs and rail beds lay under bare ground: the beige wedge at
  the viaduct's west end (0.65 m), the Wisłostrada portal (1 m), the abutment link's portals,
  the Kruczkowskiego rail viaduct, two ramps' feet. Now (`map_builder.gd`, the "map round 2
  (D5)" block) the grid cells an apron reaches are drawn as 1 m sub-cells at
  `min(grid, terrain_height)` (`_drawn_height`), the areas and footways laid on the grid use the
  same sub-cells, and an apron fades out over `APRON_TAPER` 3 m past its corridor's sides
  instead of a step inside a carriageway wider than the deck. **`check_roads` C11** (new): a
  road's, carriageway's, tram's or rail's surface on the ground more than 0.1 m under the drawn
  ground (`Map.drawn` mirrors the builder); 43 in 7 places → 0. `check_drape.gd` compares with the
  drawn ground too.
- **Tram-stop shelters**: the 14 that review A took off the rails are put beside their track
  (`bake_structures` `TRAM_SIDE`: 2.4-4.5 m out, clear of tracks, carriageways and lanes): 13
  placed, 1 left out (no clear spot). OpenStreetMap maps them on the stop position and none has a
  platform mapped within 25 m.
- **The night streets** (`bake_lights.street_lamps`): where OpenStreetMap maps no street lamps
  (Al. Jerozolimskie east of Rondo Dmowskiego, Nowy Świat at (-331, 18)), a lamp every 34 m at the
  kerb of every primary, secondary and tertiary street and of the named residential through
  streets (600 m or longer) wherever none stands within 22 m (not in a building, on a
  carriageway, a tram track or under a deck); Most Poniatowskiego's abutments between the towers
  (road `fills` meeting a deck's end, D7) get one every 20 m: 404 lamps in all. Sodium or LED by the
  street's name, as its mapped lamps; `map_builder` reads each added lamp's kind back from the
  light map. Lit map 13.7 → 16.8 %.
- **D6, deck lamps' pools on the river**: a lamp on a deck (2 m or more over the ground) lights
  only its deck's corridors (the pools fell on Most Poniatowskiego's gravel shoals); a bridge lamp
  just off a narrowed deck (the Jana Pawła II viaduct) moves in onto it instead of standing in the
  road under the viaduct. `check_streets` S1 now also checks the added lamps (14 on asphalt in the
  first try → 0).

Checks: `check_roads` C1-C11 all allowed or 0; `check_streets` S1 0, S2 0, S4 0; `check_drive` 0 / 0;
`check_drape` 0. Draw calls at the four probe views: the 3D passes +0 / +0 / +2 / +1 (lamp
MultiMeshes in a few more tiles); vertices 6,106,458 → 6,249,198 (+2.3 %: the subdivided cells
under the aprons, 404 lamps and their halos). Left (BACKLOG "From map round 2"): L1, D8-D10,
L4, L5, L2 and the Podwózka river spots.

## Map round 2b: river spots you can drive, the reviews' last items (2026-10-29)

- **The Podwózka river spots** (`bake_structures.place_bank`, index `drivable_bank`): loop 2d-1's
  `rides.gd` found a dry waypoint 5 m in from the river with a straight line to a lane over dry
  ground with no building (9 spots), but never tested whether a car can drive that line. The bake
  walks each of 832 candidates' lines to its nearest lane points (up to 10) every 0.5 m against
  retaining walls, fence, wall and hedge lines, guard rails, steps, piers, solid props, buildings,
  decks overhead and steps in the ground over 0.6 m in 2 m: 19 lines drive (blocked first by
  guard rails 51, steps in the ground 32, walls 32, decks 12, steps 10). `rides.gd` reads them
  (the "map round 2b" block, `_bank_spots`; a map without the list keeps the scan).
- **Lamp colour along a street**: a street that carries on from a bridge (a ground road sharing
  an end with a bridge road) is lit sodium like its bridge (Al. Poniatowskiego changed from the
  bridge's sodium to LED at the towers); a mapped lamp takes its kind from the nearest named
  street within 14 m (`bake_lights` `street_is_led`). 16 lamps LED → sodium.
- **D9** (`bake_roads`, `STUB_MAX`): a bridge footway of 8 m or less off another footbridge's
  middle with a free end (OpenStreetMap's stairs left out) is left out: its free end was pinned
  to the ground and pulled the Tamka footbridge down 2.2 m. 1 stub; the footbridge is level.
- **L5** (`bake_medians`): a median piece on the mapped tram bed (`landuse=railway`) is paved like
  it: the green rectangle on the tracks by Jerozolimskie × Krucza.
- **L1** judged: the lines in the three junction areas (Plac Trzech Krzyży, the Poniatowski
  ramps, Wał Miedzeszyński) are dashed lane guides through the junction and edge lines along its
  sides; the orthophoto (about 0.5 m a pixel) can't show painted lines, and Warsaw paints guide
  dashes through such junctions: kept. **L4** (Emilii Plater's weaving median walls), **L2**,
  **D8**, **D10**: not changed (BACKLOG).

## Loop 3d-1: the demo map, the 20.1 km² box (2026-10-29)

The map is docs/DEMO.md 2.1's box (south 52.2183, west 20.9780, north 52.2525, east 21.0560;
the east edge moved from 21.0500 with the user's yes so Most Łazienkowski is whole),
baked from the demo fetch already on disk (no downloads; README "Map data" for the chain,
`tools/bake_all.sh` to run it). The origin stays at 52.2340 N 21.0240 E (`bake_osm.py`
`ORIGIN`), so every coordinate written before means the same place.

- **Committed vs derived** (item 0, the user's decision): the split and the prebuilt sectors are
  no longer committed; a fresh clone runs `tools/setup_map.sh` once ("Map data").
- **The terrain from the 1 m NMT** (the user's yes: `tools/fetch_demo.py nmt1box`, 12 tiles,
  83 MB, `data/raw/demo/gugik/nmt1_box/`): `tools/prepare_demo.py` builds the 10 m grid's nodes
  from it: each node the median of the 1 m cells within 5 m, or, where 12 or more of them lie on a
  drivable road at grade, the median of those road cells (a node no longer reads an embankment's
  top or foot by chance: the old point samples moved up to 3 m with the demo fetch's lattice).
  Wybrzeże Kościuszkowskie's 2.4 m step at (625, −453) is real: the 1 m data shows the road in a
  5-6 m trench meeting the ground over the Wisłostrada tunnel's south portal; it is listed as
  loop 3e's (the portal's trench). A deck over a service way needs 2.6 m, not 5 m
  (`bake_roads.CLEAR_SERVICE`, check_roads C3 the same: garage ramps the 1 m data shows).
- **New steps**: `tools/prepare_demo.py` (the raw downloads cut to the box into `data/work/demo/`;
  `data/raw` is only read), `tools/bake_terrain.py` (the terrain on its own, first),
  `tools/bake_traps.py` (police traps 5-7 placed on the new graph by the first four's rules:
  Aleja „Solidarności” at (−778, −1390), Aleja Armii Ludowej (Trasa Łazienkowska) at (673, 1399),
  Aleje Ujazdowskie at (57, 1404); the blocks give 157-825 m runs, not police.md's 250 m).
  `bake_osm.py` runs twice (its structures read the box's LoD2). Its two quadratic loops (outlines
  holding parts, props facing their road) got grids: 240 s → 110 s for the whole bake.
- **Pedestrian zones** (police.md 5.6, 13): `bake_osm.py` `PED_ZONES` (the Old Town box, one
  small commented list) writes `ped_zones` (83 polygons: the `highway=pedestrian` ways as strips,
  the squares and pedestrian areas: the Old Town and New Town, Plac Zamkowy, Krakowskie
  Przedmieście's north end); traffic never enters (pedestrian ways are not in the lane graph);
  `game/scripts/ped_zones.gd` and `car.gd` `zone_cap` hold the player's car to 20 km/h there
  (`zone:` log lines). The pill, the guards and the clamp are loop 3g-2's.
- **Classes fixed over the whole map** (each counted before → after): a vertex within 0.3 m of the
  one before it got no node in the deck solver (a crash on the box's rails: 1 → 0); a rail way with
  no layer between cutting tracks is in the cutting (Żelazna's crossover, an R3 failure that
  stopped the bake: 1 → 0); poles on the asphalt (S1 15 → 0: a lamp with no spot off the asphalt
  is left out, a signal looks 16 m out, the added lamps and a last pass use S1's own test); a deck
  lookup past a piece's end at a joint with the next piece (Most Świętokrzyski dropped the car
  7.6 m at its pylon: check_drive jumps there 2 → 0); building walls standing in a lane open by
  their triangles' edges, not centres, and for OpenStreetMap buildings too (lod2_open 92 → 140
  places; check_drive lane collisions outside the structures 6 → 1, a pillar, allowed); a point
  of interest in water moves to the nearest road point (Skwer Hoovera's fountain, check_water 5d:
  2 moved); a mapped Mermaid 150 m or more from the river isn't the egg's (a small "Syrenka"
  1.5 km inland had taken the boulevard spot's place); the map's edge walls stand on the map's
  edge, not the grid's, and the sector grid covers what the builder draws (`bake_sectors.reach`;
  check_streaming's identity: 26 ground and building tiles in no sector → 0).
- **What the checks found** in the new area (all listed in the allowlists with place and reason,
  `tools/check_roads_allow.json` and the new `tools/check_drive_allow.json`; 27 entries of the
  first box no longer matched and were dropped): the structures of DEMO 4.6, loop 3e's work: Trasa
  W-Z's tunnel and portals, Trasa Łazienkowska's trench at Plac Na Rozdrożu and its interchange,
  the Wisłostrada tunnel's north portal under the Copernicus Science Centre, Most Świętokrzyski's
  pylon, Most Śląsko-Dąbrowski's Praga end, Wiadukt Markiewicza, the railway cutting west of
  Centralna under Żelazna, Towarowa and Kasprzaka, the Praga viaducts by the zoo; and two classes
  of the 10 m grid: service ways and steep escarpment streets as before, and (new) roads whose
  ends meet a hump or pit of the new grid, which samples the NMT 3.5 m east and 5 m south of the
  old grid's nodes (Wybrzeże Kościuszkowskie by Tamka steps 2.4 m in 6 m: an open question).

| Loop 3d-1 numbers | First box (loop 3c) | Demo box (east edge 21.056, the 1 m terrain) |
| --- | --- | --- |
| Area, sectors | 3,545 × 1,769 m = 6.3 km², 32 | 5,318 × 3,782 m = 20.1 km², 108 (i −7..4, j −5..3: 96 for the box and a sliver row of 12 north of z −2,048 for the terrain and the buildings that reach 4-6 m past the edge) |
| centrum.json; lod2.bin, ao / lights / water.bin | 5.0; 26, 12 / 12 / 6 MB | 16.4; 87 (derived since loop 3d-1), 40 / 40 / 20 MB |
| Roads, paths, buildings (OSM kept / LoD2) | | 8,038, 19,464, 12,610 (4,667 kept / 6,025 LoD2, 1.55 M vertices) |
| Scanned trees, pois, addresses | 12,554, 1,020, 973 | 42,578 (every OSM tree replaced), 3,548, 3,332 |
| Lane graph | 966 nodes (96.3 % strongly connected), 1,497 edges | 2,714 nodes (2,615: 96.4 %), 4,427 edges, 183 signal controllers |
| Vertices (`count_vertices.gd`) | 6.25 M | 19.49 M (0.97 M a km²) |
| Sector files / index.json | 9.2 / 3.3 MB | 29.4 / 10.2 MB |
| Prebuilt: sectors, index.res, proxies.scn | 29.3, 2.3, 2.7 MB | 91.3, 7.7, 8.5 MB |
| check_roads findings (all allowed) | C1 32, C2 1, C3 40, C5 18, C8 5, C9 5 | C1 81, C2 1, C3 137, C5 72, C6 4, C8 30, C9 12, C11 1 (in the 18.6 km² of the first demo bake: C1 84 → 72, C8 32 → 25 with the 1 m terrain) |
| check_drive (both paths) | 0 | 0 not allowed (174 allowed, at loop 3e's structures, one pillar and one median fence) |
| check_streets | S1 0, S3 18 | S1 0, S3 40 |
| Probe draw calls (spawn, river, zoomed out, helicopter) | 132, 103, 153, 211 | 134, 103, 148, 217 |
| Memory at the spawn (probe): static / video | 147 / 263 MB (textures 24) | 244 / 421 MB (textures 94: the AO, light and surface maps 100 MB whole) |
| check_water, check_drape | OK | OK (2 places listed in check_water's `ALLOWED`, 1 in check_drape's `EXCUSED`: loop 3e) |
| Exported .pck | 47.2 MB | 140.0 MB (budget 300) |
| check_streaming | identity, ≤ 0.015 % at 10 spots | identity OK (108 sectors), soak OK; spot 8 at 0.789 % under its own limit of 1 % (`SPOT_MAX`: single texels of lamp-pole shadow edges, 0.14 % by more than 8/255; in the game the 12 streamed sectors against all 108 differ in 0.07 % visibly, nothing moves) |

## Adding music (loop radio-playlists, 2026-10-29)

The radio plays songs you make yourself (a synth, or an AI music tool such as Suno). Three steps:

1. **Make the song** and export a WAV or MP3 (flac, m4a and aiff work too).
2. **Put it in `data/raw/music/<station>/`**, where `<station>` is a station's `id` in
   `game/data/radio.json`: `nocna_fm`, `rondo_fm` or `mordor_fm` (the folder is ignored by
   version control: raw music is never committed). The song's file name is its title on the
   radio: `Night_on_Smolna.wav` shows as "Night on Smolna". To say more, put a text file with
   the same name next to it, `Night_on_Smolna.txt`, with one line (the licence), or lines
   starting `licence:`, `title:` and `artist:`:
   ```
   licence: Suno Pro plan, owned
   title: Noc na Smolnej
   artist: Lubomir
   ```
3. **Run `python3 -I tools/add_music.py`** (needs `ffmpeg`; `oggenc` from vorbis-tools makes the smallest files). Then `tools/verify.sh --only=radio`,
   and commit `game/audio/radio/`, `game/data/radio.json` and the new `.import` files.

What the tool does to each new song (the docstring of `tools/add_music.py` has the details):
decodes to 44.1 kHz stereo, trims silence at both ends (below -50 dBFS, 0.2 s kept), measures
the loudness (EBU R128) and applies **one static gain** so the song sits at the radio's level,
**-14.0 LUFS** (the mean of the three original loops: -14.6, -14.2 and -13.2), lowered further
if its true peak would pass -1 dBTP. No limiter, compressor or loudnorm: they flatten music. It
encodes Ogg Vorbis to `game/audio/radio/<station>/<name>.ogg` and appends the track to
`radio.json` (file, title, artist, seconds, gain_db, licence, source). `--station=<id>` limits it
to one station, `--force` converts every file again, `--dry-run` says what it would do, `--list`
prints the stations and tracks with their sizes, `--licence="..."` sets the licence of this
run's files. A folder in `data/raw/music/` that is not a station in radio.json is not turned
into one: the tool prints the line to add to radio.json (id, name, frequency, colour).

A station with one song loops it; with two or more it plays them in a shuffled order (the date
seeds it), each to its end, with the host's lines between songs now and then.

**Sizes.** The tool encodes with `oggenc` (vorbis-tools: `brew install vorbis-tools`) when it
is on PATH: ffmpeg decodes, trims and applies the gain to a temporary 44.1 kHz stereo 16-bit
WAV, `oggenc -b 96` writes the Ogg (about 96 kbps on average, about 2 MB for a 3-minute song),
and the WAV is deleted. Without `oggenc` it uses ffmpeg's `libvorbis` if `ffmpeg -encoders`
lists it. The Homebrew ffmpeg on the Mac has no libvorbis, and its built-in `vorbis` encoder,
the last fallback (the tool says so), ignores the bitrate and writes about 185 kb/s, 4.1 MB for
3 minutes. The three original loops (2.4 minutes together) were 12.6 MB as WAV; encoded with
`oggenc` they are 1.5 MB as Ogg (0.56, 0.50 and 0.44 MB).

**Licences.** A song whose licence is not given stays `unknown`; the radio check
(`tools/verify.sh`, step `radio`) lists those as a WARN. **Check every `unknown` track before a
release**: an AI music tool's free plan may not allow its songs in a published game (paid plans
usually do, by the tool's current terms: keep the plan's receipt or the song's page). CREDITS.md
lists every track and its licence line; update it when you add songs.

## Loop G0+: streaming and heat on the iPhone 11 (2026-10-29)

Loop 3c's streaming and G1b's sharp ×1 picture, measured on the iPhone 11 (`iPhone12,1`, iOS
26.5, started with `devicectl`, no debugger, Auto = High ×1 sharp 1792×828, `--nosave`: the
phone's own settings and save untouched).

1. **Why the phone's log had no streaming lines.** devicectl swallows the `--`, so on the phone
   the game's flags arrive among the engine's own. `main.gd`'s `_parse_args` fell back to those
   (loop 2b); `_parse_stream_args` read only the user args, so `--stream-soak` and
   `--stream-log` did nothing: the game just played (traffic, a rescue call) until
   `device_run.sh` stopped it, and the log held only its start-up lines (the governor's lines
   in the first run came from that play). Now both parsers read one `game_args()`. The soak also
   writes `user://stream_soak_result.txt` (on the iPhone `get_tree().quit()` does nothing and the
   app is stopped from outside), `print` flushes the log file
   (`application/run/flush_stdout_on_print`), and `tools/device_run.sh` keeps each run's log as
   `<label>_<date-time>.log`, never lets a short copy replace a longer one, copies once more 3 s
   after the done line, copies the soak's result file, and exits 3 when the done line never came.
2. **Sector adds were 60× over the budget on the phone; the cause was physics interpolation.**
   The project has it on (for the cars); the sectors inherited it, and adding a MultiMesh node
   under an interpolated parent cost the main thread 14 ms on average (37 ms at worst; the Mac
   1.4 ms, which loop 3c read as "a busy Mac"), a sector 188 ms spread over its load frames, and
   the 6-minute soak's CPU-bound misses walked the governor down to GPU 0/2 · CPU 0/2.
   `sector_streamer.gd` now sets `Sectors` and `Proxies` to `PHYSICS_INTERPOLATION_MODE_OFF`
   (nothing in them moves on the physics tick; the people, pigeons and police halos already had
   it off): 0.002 ms a MultiMesh, 0.35 ms a sector, 0 frames over 3 ms.
3. **What is left: one slow frame per load** (19-22 in a 6-minute soak, 25-65 ms, none with any
   of the streamer's own work in it). `--stream-log`'s new `worker` lines show it is the render
   server creating the sector's meshes and MultiMeshes (~1-1.6 MB of GPU buffers) on the main
   thread as the worker's load ends: the stall lands wherever the main thread next touches the
   render server (after the streamer's process, in the draw, before the next physics frame);
   with `--render-thread separate` it moves into the draw (the main thread waits for the render
   thread), 16-58 ms: no better. A fix needs the sector's resources in pieces the worker can load
   one a frame (a `bake_city.gd` change; BACKLOG "From loop G0+").

| Streaming soak, 6 min (`--stream-soak=6 --stream-log --prebuilt`, governor on) | Before (A1 / A2) | After (B1 / B2) |
| --- | --- | --- |
| A streamed sector's main-thread ms (43 of 49 loads): median / p99 / max | 188 / 247 / 247 · 182 / 235 / 235 | 0.35 / 0.55 / 0.55 · 0.34 / 0.53 / 0.53 |
| Streaming ms a frame: p99 over all frames / max | 16.4 / 37.1 · 16.5 / 32.4 | 0.82 / 1.17 · 0.82 / 1.45 |
| Frames whose streaming took over 3 ms | 493 · 485 | **0 · 0** |
| Adding a node, mean / worst ms: MultiMesh (428 adds), Node3D (83), mesh (298), collider (43) | 14.4 / 36.9, 16.0 / 29.1, 0.009 / 0.05, 0.018 / 0.03 | 0.002 / 0.02, 0.003 / 0.01, 0.002 / 0.01, 0.018 / 0.04 |
| Frames over 33 ms past the warm-up (of them with streaming work) | 78 (47) · 87 (59) | 22 (0) · 19 (0): the load hitch above |
| Frames missing a needed sector, forced loads | 0, 0 | 0, 0 |
| Governor | 10 changes, ended GPU 0/2 · CPU 0/2 (CPU-bound drops from 6 s) | **0 changes**, GPU 2/2 · CPU 2/2 |
| Start: 6 sectors in full / `city built in` | 242, 225 ms / 865, 832 ms | 189, 187 ms / 797, 871 ms |

| BENCH at Auto (`--bench`, 600 frames; the phone cool, before then after) | Before | After |
| --- | --- | --- |
| fps · 1 % low · worst · late · missed refreshes | 60.0 · 57.1 · 17.8 ms · 0.3 % · 0 | 60.0 · 58.7 · 17.1 ms · 0.0 % · 0 |
| Draw calls (main / shadow / 2D) · objects · triangles | 131 (52 / 45 / 34) · 310 · 0.40 M | 130 (51 / 45 / 34) · 305 · 0.40 M |
| Scripts · traffic · memory static / video | 4.28 · 1.68 ms · 132 / 233 MB | 4.17 · 1.56 ms · 134 / 233 MB |
| Start (the bench's launch): 6 sectors / `city built in` | 221 / 1079 ms | 185 / 1044 ms |

**G0's 20-minute soaks** (graphics.md §2.3 item 9; G1b asked for them): `--autopilot
--governor=log`, traffic Normal, governor on, Auto ×1 sharp, the build after the fix; each after
8 minutes of rest with the app stopped (day after the two benches), in this order:

| 20 min at Auto ×1 | fps every minute | Missed refreshes (GPU-bound) | Worst minute | Governor | G1b's rule |
| --- | --- | --- | --- | --- | --- |
| Day | 59.9–60.5 (60.0 in 16 of 20) | 23 of 72,308 (9): 0.03 % | minute 4: 6 missed | 0 changes | calm at 180 s; never close (GPU extras down 0 s, no minute over 2 %) |
| Night | 59.9–60.3 (60.0 in 17 of 20) | 18 of 72,206 (5): 0.025 % | minute 4: 7 missed | 0 changes | calm at 180 s; never close |
| Rain at night | 59.9–60.5 (60.0 in 17 of 20) | 20 of 72,283 (8): 0.028 % | minute 4: 7 missed | 0 changes | calm at 180 s; never close |

The first rain run was cut off at minute 18 (the session stopped and the app ran on its own for
2.5 hours before it was stopped); its 18 minutes read the same (11 missed of 65,102). The rain
row above is a second run after 15 minutes of rest. The soaks ran on the map before map round
2 (merged afterwards: +0.8 % vertices, the same 32 sectors).

Godot 4.7.2 can't read the thermal state, so how warm the phone got is the user's to feel; the
logs show no throttling (fps by minute flat, the governor never stepping in, the misses not
growing with time).

**On the Mac** (M4 Pro, Metal Mobile, `--bench`, before = the same code without the two
interpolation lines, interleaved, medians of 5 day / 3 night / 3 rain-night runs, uncapped):
frame 6.40 → 6.47 ms, 6.90 → 6.90, 8.33 → 8.33; scripts 1.25 → 1.20, 1.21 → 1.21, 1.40 →
1.43 ms; draw calls 114 → 114, 82 → 82 (the typical night run), 81 → 81; Vulkan GPU (1920×1080,
3 each) 1.11 → 1.14 ms. Draw calls, scripts and GPU unchanged; the phone's per-load main-thread
time is the change. Shots (`shots/g0/`, 2532×1170: spawn, Marszałkowska, the Palace, the river
by day and night, Rondo Dmowskiego in rain at night, the helicopter; runtime and prebuilt, day
and night): the 3D view identical before and after, only the minimap's random job markers differ
(≤ 0.019 % of the pixels); `check_streaming` pixels ≤ 0.015 % as in loop 3c.

Why it matters more on the phone than the Mac: the add's cost was main-thread work the A13 does
~10× slower (14 ms against the Mac's 1.4 ms), and the governor reads CPU-bound misses as a
reason to drop the extras; on the Mac the same frames fit inside 16.7 ms and nothing showed.

## The driving-feel loop: less sticky (2026-10-30)

The user: "driving is heavy, there are a lot of tiny objects on the road, and the car gets stuck
each time it hits another car". What did it, in the code:

- **A hit traffic car stopped dead in front of you** for 2.5 s (`traffic.gd` set `stun`, which
  forces its speed to 0 at once), and the car never steered round a car (Point follows fixed
  walls only), so rear-ending one was a 2.5 s stop behind it.
- **Every touch of a front corner was a dead stop**: Godot's slide takes the speed going into the
  contact out, so a bollard, a bench end or a parked car's corner caught at 40 km/h stopped the
  car as a wall would.
- **Kerbs**: each kerb line crossed kept 92 % of the speed, so an island (two kerbs) cost 15 %,
  and the raised ground dragged at 0.6/s; the roadworks' barriers and cones took 15 % each.

What changed:

1. **Corner slip** (`car.gd` `_corner_slip`): when every contact of a step is at one front corner
   (within 0.6 m of the side, in the front 1.2 m) and the way beside it is open (`test_move`
   0.6 m on from the side-stepped spot), the car steps sideways past it at up to 7 m/s and keeps
   96 % of its speed (100 % on the next frames of the same slip); the bump it reports is 35 % of a
   full one, once (traffic, the słoiki jars and ride stars read it). A square hit, a touch along
   the flank, both corners at once and a wall met at an angle don't slip.
2. **Cars are pushed, not walls** (`traffic.gd` `_shove`): the car it hit takes 70 % of the
   player's speed it lacks along its lane and slides off its line at 40 % of the player's
   sideways speed (≤ 4 m/s, slowing at 6 m/s², ≤ 1.6 m off); dazed for 2.5 s (police 1.5 s) it
   brakes at 4 m/s² instead of stopping at once and stays where it was pushed, then drifts back
   to its lane. `stun` stays the app taxi's hold (`gps_moments.gd`).
3. **Going round a car**: pushed into a car or a tram for 0.35 s with the gas on and getting
   nowhere, Point follows its side as it follows a wall; still pinned 1.5 s, it is turned out,
   but never towed to a free spot for it (that stays for walls).
4. **Kerbs and cones lighter**: a kerb keeps 97 % of the speed, once per 0.5 s (an island is one
   jolt), the raised ground drags at 0.25/s; barriers and cones keep 95 % (`eggs.gd` KNOCK_KEEP).

`check_steering` gains `post_clip`, `car_clip` (every scheme) and `car_behind` (Point, Fixed):
the car must get past each. Before → after (Point; Classic in brackets):

| Test (from 40 km/h, 25 for car_behind) | Before | After |
| --- | --- | --- |
| `post_clip`: a 0.3 m bollard under the right front corner | 36 km/h 1 s after the touch, past at 1.6 s (Classic: stopped, turned out, never past) | 91 km/h, past at 0.8 s (Classic the same) |
| `car_clip`: a stopped car's corner 0.5 m into the car's path | 32 km/h, past at 2.1 s (Classic: stopped, never past) | 93 km/h, past at 1.2 s (Classic the same) |
| `car_behind`: a stopped car square ahead | 22 km/h, past at 2.6 s | 26 km/h, past at 2.3 s |

Every older test (holds, turns, walls, the corner, the camera) reads the same as before. Street furniture stays solid (benches, racks, columns, shelters,
parked cars): on today's map 7 benches, 11 bike racks and 3 shelters overlap a carriageway
(BACKLOG).

## The roadworks loop: traffic and the helicopter knock the barriers (2026-10-30)

The day's roadworks (barriers and cones round a dig, `eggs.gd`) moved only for the player's car;
AI cars drove through the ones knocked into their lane, and the helicopter's downwash left them
standing. Now `_barriers` also takes every moving traffic car within 30 m of the roadworks: a
barrier or cone under its box (its length plus 0.4 m, 1.3 m either side of its centreline) is
knocked along at 75 % of the car's speed and 1.5 m/s out to the side. The helicopter under
14 m over the ground within 30 m blows the ones within 9 m outwards, up to 3.5 m/s at its centre.
Checked headless at Drewniana (the 2026-10-30 roadworks, `--at=145,-626`): 4 knocks by traffic in
60 s with the player parked, 14 gusts in 15 s with `--heli`, 0 errors. The cost is one pass over
the active drivers per frame, only on a day the roadworks are on the map.

## The ram test: traffic was a wall to the car (2026-10-30)

A new game run, `--ram-test` (verify step `ram`), drives the car into the back of a moving
traffic car in the real city. On main after the first driving-feel loop it showed the car still
stopping dead: hit at 65 km/h, 4 km/h a frame later, and never past in 10 s. The cause: Godot's
`AnimatableBody3D` (traffic's and the trams' bodies) is a `StaticBody3D`, so `car.gd` counted
every car and tram as a fixed wall (`_fixed_contact`): the slide took all the speed going into
it, Point followed it as a wall, and pinned against one the car was towed. Now:

- An `AnimatableBody3D` is not fixed. Hitting a car or a tram keeps half of the speed that went
  into it for the next frame (`CAR_KEEP` 0.5; something that doesn't move takes the rest on the
  next frames), and towing is for walls only.
- Rammed from behind, the traffic car also swerves away from the player's side at 0.35 of the
  closing speed (`SHOVE_SWERVE`), up to 2.0 m off its line (`SHOVE_ACROSS`, was 1.6), and takes
  40 % of the speed it lacks (`SHOVE_ALONG`, was 70 %: it shot off ahead and was hit again).

Ram test, same car at -918, 263 (23 km/h, the car from 29 km/h, Point at 65 km/h): before, hit
and 4 km/h after, never past (0.5 m behind after 10 s); after, 28 km/h after the hit, past it
2.6 s after, never unstuck. `check_steering` stays OK (`car_behind` 2.3 → 2.7 s now that the
stopped car is not followed as a wall until the 0.35 s push).

## Moja Warszawa notebook (loop MW-1, 2026-10-30)

MOJA WARSZAWA, the city notebook (docs/design/vision.md 4.1): the 72 places of
`game/data/places.json` (designer-owned; 9 chapters of 8) found by driving or flying past them,
kept in the save, read in the settings card's fifth tab. Code: `notebook.gd` (places, finding,
rewards, the minimap's marks), `notebook_page.gd` (the page), small hooks in `main.gd`
(`_build_notebook`, `_place_start`, `_put_at_place`, the flags), `hud.gd` (`set_minimap_unknown`,
`notebook_changed`, the "?" in the minimap's triangle array), `wallet.gd` (`notes`,
`chapters_done`) and `settings_panel.gd` (the ZESZYT tab, `show_notebook`).

- **Where a place is.** No bake resolves the places yet (BACKLOG "From loop MW-1": the map lane's
  `pois` kind `place`). At load (~35 ms, once) each place's `near` [lat, lon] goes through the
  bake's flat projection (`tools/bake_osm.py` `project`: the map's `origin`, 110 574 m a degree of
  latitude, 111 320 · cos(lat0) of longitude), then the first of these within reach of the hint
  wins: an `address` poi with the same number on a street whose last word matches ("Al.
  Jerozolimskie 6" finds "Aleje Jerozolimskie 6"; 600 m); a named square, park or landmark with the
  place's Polish name, or a landmark whose name starts with it ("Pałac Kultury i Nauki"; never a
  parody venue or a street; 600 m); a poi of the place's own kind (the Mermaid, Patelnia, Plac
  Defilad, the stadium; the nearest kebab stand for a kebab place; 300 m). Today: 5 by address,
  16 by name, 6 by poi, 45 on the hint; the furthest from their hints Smoła 359 m, Stara
  elektrownia 331 m, U Zdzicha 264 m. `--notes-log` prints a `notes: place <id> <source> N m from
  the hint (x, z)` line for each.
- **Finding** (`Notebook.finds`): in the car within `radius` (25 m; 40 m for squares, parks,
  bridges) at ≤ 30 km/h, or stopped inside it for 1 s; in the helicopter within `heli_radius` (60 m
  when the place has none) below 60 m over the ground. Checked twice a second through a 100 m grid
  of the places: one cell is looked at, so nothing runs per frame but a timer. Never on the title
  screen or during TEST · BENCH (its wallet is put back after; `--bench`'s route does find places); the game paused (settings) pauses it.
- **A new entry**: the save (`[notes]` id = yyyymmdd in `user://save.cfg`; with `--nosave` in
  memory only), +5 respect through the wallet's `pay`, a toast "NOWY WPIS · <name>" over "NEW
  ENTRY · <name> · k/8", the UI blip and a short buzz (25 ms). A chapter's eighth card: +50 zł and
  +30 respect once, a note card ROZDZIAŁ GOTOWY · CHAPTER DONE, and `[notes_chapters]` chapter id =
  yyyymmdd (MW-5's track unlocks will read it).
- **On the minimap**: the places not found yet within 400 m of the car as a gold "?" (3 × 5 pixels
  of 1.3 pt on a dark plate), never a name; drawn in the minimap's one triangle array, so no draw
  call of its own. (vision.md says "in a discovered district"; districts don't exist yet.)
- **The page** (Settings → ZESZYT · notebook; the card's title says MOJA WARSZAWA and "zeszyt
  miasta · k/72"): a row of the 9 chapters (the number stands in for the chapter's icon until
  PixelLab's; k/8 under it; gold when complete), the chapter's name, then its 8 cards in 4 × 2: a
  found card shows its name (Polish over English), a night venue's hours and the day found, one
  not found yet "?" and the chapter. A tap
  opens a card: name, fact and joke (Polish over English), the address (not for a venue: it could
  name the real business), the hours of a night venue (`otwarte PT–ND 04:00–12:00` over `open
  Fri–Sun …`) and the day found; WRÓĆ · back returns to the grid. At least 476 × 254 pt (as wide as
  the card's inside); every target at
  least 44 pt; the card fits the SE (633 × 349 pt of 667 × 375) without shrinking (`check_hud`
  walks the notebook's grid, a found card and an unfound one on all four screens). The settings
  card's line under its title is now two lines (Polish over English), so the fifth tab fits.
  The page is drawn by hand: its boxes in one triangle array, its words grouped by size, so it
  costs a handful of 2D draw calls whatever it shows, and nothing when the panel is closed.
- **Check**: `game/tools/check_places.gd` (verify step `places`, in the quick set and in CI: it
  reads only `centrum.json` and `places.json`): Polish and English for every name, fact and joke,
  Polish ≤ 70 characters (the toast too), 8 places a chapter, the hint inside the demo box and the
  place inside the map, no denylisted name in anything the notebook shows, reachability (a lane
  or footway within radius + 10 m: the misses are printed as a `check_places: WARN` line, not
  failed: 70/72 today), the finding rule on 11 synthetic cases, the 2 Hz tick through the grid
  (speed, away, distance, the helicopter's height) and a chapter paying once.

## The traffic loop: cars overlapping in junctions (2026-10-30)

A new testing aid, `--traffic-overlaps`, has the traffic count, every frame, the pairs of its
cars whose boxes overlap (a 2D separating-axis test with 0.15 m of slack) and prints one line at
the end: `traffic overlaps: N car-pair frames in F frames (J with a car on a junction curve),
S spots; worst W frames at x, z; K knots given up`. Cars in a junction used to look only at the
other car's centre in a 1.9 m strip ahead, so a car crossing at an angle was seen when its centre
reached the strip, too late, and two turn lanes merging into one lane were never checked against
each other (both are registered in the lane they merge into). Now (`traffic.gd` `_path_gap`):

- Each car looks for the other's whole body plus where it goes in the next 0.8 s (`PATH_LOOK`),
  sampled every metre, in its own corridor (both half widths and `PATH_MARGIN` 0.2 m) from beside
  its front half to 14 m ahead (`PATH_AHEAD`); the gap is to the nearest such point.
- Two cars on different junction curves are checked even when both end in the same lane.
- A car within 6 m of the start of the lane it came out on (`PATH_EXIT`) is still in the box.

Measured with `--traffic=busy --no-police --traffic-overlaps`, 3600 frames at `--fixed-fps 60`,
car-pair overlap frames before → after: the start 62 → 32, `--at=-918,263` 352 → 156,
`--at=145,-626` 395 → 27 (809 → 215 in all), no knot given up in either. What is left is mostly
two cars entering a short (3.5 m) merging curve in the same frame near -940, 210 and -890, 350.

## Performance budgets

Set in loop 2b from the measurements above; loop 2c (the player's car and the traffic as nicer
models) and loop 2d (many more props and jokes: corner shops, e-scooters, delivery riders,
app taxis) must stay inside them and report the same numbers before and after.

**How to measure** (on the Mac, at the iPhone's 2868×1320, Metal; the counters are the ones
the phone's overlay shows and match it):
`godot --path game --rendering-driver metal --rendering-method mobile --resolution 2868x1320 --fixed-fps 60 -- --probe --nosave --controls=classic [view]`
(without `--rendering-method mobile` Godot picks Forward+ on the Mac, not the phone's Mobile renderer)
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
| Metal frame, bench (Mac, uncapped; since 2026-10-30 at `--resolution 1920x1080`, see below) | 1.5–1.9 ms | 2.2 ms | 2.6 ms |
| GPU, Vulkan bench (Mac, 1920×1080) | 0.80–0.87 ms | 1.0 ms | 1.2 ms |
| GPU, Vulkan zoomed out at 2868×1320 (`--gpu-profile`) | 1.65 ms | 1.9 ms | 2.2 ms |
| iPhone TEST · BENCH at High, 60 fps cap | 60 fps, 1 % low ≥ 56 | 60, 1 % low ≥ 55 | 60, 1 % low ≥ 55 |
| Loop 3c: streaming, main thread a frame (Mac, `check_streaming.gd` soak, p99 of the frames that load) | | ≤ 3 ms | ≤ 3 ms |
| Loop G0+: the same on the iPhone 11 (6-minute `--stream-soak`, max of any frame) | 1.2–1.5 ms (was 32–37) | ≤ 3 ms | ≤ 3 ms |
| Loop 3c: a frame that loads a sector | | ≤ 33 ms | ≤ 33 ms |
| Loop G0+: the same on the iPhone 11 | **over**: 19–22 frames of 25–65 ms in 6 minutes, one per load (the render server building the sector's GPU buffers; BACKLOG) | ≤ 33 ms | ≤ 33 ms |
| Loop G0+: the iPhone 11 at Auto ×1, 20 minutes each by day, night and rain at night (`--autopilot --governor=log`) | 60.0 fps every minute (59.9 at worst), 18–23 missed refreshes of ~72,000, 0 governor changes, calm | no struggle verdict | no struggle verdict |
| Loop G1: TEST · BENCH at Auto on the iPhone 11 (High, 896×414) and the Pro Max (Ultra, 1434×660), 60 fps cap | 60 fps, 1 % low 56.6 / 57.3, 0 missed refreshes | 60, 0 missed refreshes, 1 % low ≥ 55 | 60, 0 missed refreshes, 1 % low ≥ 55 |
| Loop G1b: the iPhone 11 at Auto, now High ×1 sharp (1792×828): BENCH minute, and a 15-minute day drive with the governor on (missed refreshes, governor changes) | BENCH 60 fps, 0 missed, 1 % low 54.4 / 58.7 (cool / warm); drive 60.0 every minute, 5 missed in 17.7 min, 0 governor changes | 60, 0 missed refreshes, 1 % low ≥ 55; the drive with no struggle verdict | 60, 0 missed refreshes, 1 % low ≥ 55; the drive with no struggle verdict (else the content costs the iPhone 11 its sharp default) |

**The bench's window (performance lane, 2026-10-30).** On macOS 27 a small window waits about
4 ms in the draw/present step whatever is drawn: at the default 1280×720 the bench's frame
reads 5.6–6.3 ms (main-thread "draw" 4.0–4.6 ms) both before and after loop 3d-1, while at
1920×1080 and up "draw" is 0.6–1.1 ms. It doesn't follow pixels (1920×1080 at ×1 has 4.5× the
pixels and is 5× faster) or objects (`--size=40` against `200`). So the Metal frame row is now
measured with `--resolution 1920x1080`: 2.4 ms before loop 3d-1, 2.5–2.7 ms after (at the
ceiling). What 3d-1 really added: +0.5–0.7 ms of main-thread process (1.14 → 1.64–1.81 ms; with
`--no-traffic` it is 0.60), main-pass triangles 0.17 → 0.20 M, static memory 173 → ~330 MB (the
prebuilt city 241 MB). Draw calls 73–139 at every view measured, well inside.

Loop 3g-1 (the police; police.md section 12 allowed ≤ +3 draw calls at any view, ≤ +8 k
triangles, ≤ 0.15 ms of script, ≤ +2 MB) spent, in a koguty 3 chase: +1 to +3 draw calls at the
four views and at night (the POLICE MultiMesh in the main and shadow passes, the halos at night;
the HUD's 2D pass no higher than before, the minimap now drawing its marks in one call), ≤ +3.2 k
triangles a pass, 0.07-0.08 ms of police script plus 0.04 ms of HUD, and +2 MB (+4 MB more for
Dialogue Manager's scripts); see Loop 3g-1: the police, part one.
Loop 2c spent none of it: +0 draw calls at every view, and the triangles at the default view
went down (the traffic pools draw only the cars in use); its numbers are in Loop 2c: car models.
What 2c may spend: ~15–25 draw calls (a few traffic kinds' MultiMeshes in the main and shadow
passes, the player's lamps), 70 k triangles at the default view (150 k zoomed out), 0.1 ms of
script. What 2d may spend: ~65–90 draw calls (about six new kinds of things, each one MultiMesh
per 512 m tile, in the main pass and, if over a metre tall, the shadow pass), 130 k triangles at
the default view, 0.3 ms of script. The phone has more GPU room at the default view than when
zoomed out or flying (there the main thread already waits ~11 ms of the 16.7 for the GPU), so
anything seen from far away (roof clutter, more trees, more cars when zoomed out) is the
expensive kind. (Loop G1: the ~11 ms is mostly waiting for the display, not the GPU: the same
"draw" reads 1–2 ms in another launch at the same view. The GPU's own time comes from a Metal
System Trace: the iPhone 11 at ×2 holds 60 at its lowest GPU clock, Loop G1 above.)

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
8. Don't push `cam.far` out (it sizes the sun's shadow: `_camera_far`), the shadow map back up
   (Ultra's 4096 is loop G1's, measured on the Pro Max: 0 missed refreshes, +24 MB), or the
   tiles (`chunked_surface.gd` 256 m, instances 512 m) back down.
9. Report before and after: the `draw calls` / `main pass` lines at the four views above, the
   bench medians, and a TEST · BENCH card from the phone: since loop G1 from **both phones at
   Auto** (the iPhone 11 at High, the Pro Max at Ultra), with its missed refreshes.
10. Loop G1: the pixel image belongs to `tiers.gd` (the level's budget): don't make it finer for a
   look. A new extra that only the stronger phones can pay for is a level's (a `tiers.gd`
   QUALITY field, a uniform, not a shader define); one the governor may take away when frames
   are missed goes into `governor.gd`'s levels; a per-object one that can't be seen in a view
   over 150 m goes under the view rule (`main.gd` `_apply_extras`, WIDE_VIEW). Never the
   landmarks, the ghost, the river or the night lights.

## Map data

**Loop 3d-1: the demo box.** The map is the box of docs/DEMO.md 2.1: south 52.2183, west
20.9780, north 52.2525, east 21.0560 (map metres x −3,136 to +2,182, z −2,046 to +1,736;
5,318 × 3,782 m = 20.1 km², 12 × 8 = 96 sectors and a sliver row). `bake_osm.py` `BBOX` is the box and `ORIGIN`
(52.2340 N 21.0240 E) the origin, no longer the box's centre, so every coordinate written down
before (allowlists, `GUGIK_NOT_TREES`, `EXTRA_KEBAB`, landmark search boxes, police traps, test
spots, this README) still means the same place. Everything comes from the demo fetch already on
disk (`data/raw/demo/MANIFEST.md`; nothing downloaded since) and `data/raw` is only read:
`tools/bake_all.sh` runs the whole chain (~10 min), in this order:

1. `python3 tools/prepare_demo.py` (Pillow, for the photo) → `data/work/demo/` (gitignored):
   the Overpass export cut to the box (`osm_demo.json`: nodes within 0.003° of it, the ways and
   multipolygons that reach it with all their nodes, no route relations: 76 MB of 187), the
   aerial photo's four tiles joined and cut (`ortho.bmp`, 6,112 × 4,346 px), the terrain
   (`terrain_10m.json`: the 10 m lattice, each node from the 1 m NMT of `data/raw/demo/gugik/nmt1_box`,
   see "Loop 3d-1"), links to the 9 LoD2 and 30 tree sheets that meet the box.
2. `python3 -I tools/bake_terrain.py` → `game/map/terrain.json` (its own step now: bake_osm
   reads it for the decks, and bake_gugik reads centrum.json, a circle once the box grew).
3. `python3 -I tools/bake_trees_gugik.py data/work/demo/trees data/work/demo/trees_area.json` (~5 min).
4. `W=data/work/demo/osm_demo.json && python3 -I tools/bake_osm.py $W $W game/map/centrum.json $W $W`.
5. `python3 -I tools/bake_gugik.py data/work/demo game/map` → `lod2.bin`, `lod2.json`.
6. Step 4 again: its structures read `lod2.*` (the outlines bake_gugik keeps LoD2 by don't change).
7. `bake_ao.py`, `bake_lights.py`, `bake_water.py` (below), then `tools/setup_map.sh` (the split
   and the prebuilt sectors).

The steps below are the chain as it was for the first box; their order and what each writes
still hold, with the paths above.

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
   Loop 3b: it ends with `tools/bake_structures.py` (`decks.piers`, `walls`, `towers`, `cut` /
   `cutd` / `pil` on buildings, `lod2_cuts`, `lod2_open`, `aprons`, `tunnels.frames`,
   `garage_doors`, the graph edges' `po`; it reads `game/map/lod2.*`, so bake GUGiK first), and
   when `data/raw/demo/gugik/nmpt05` and `nmt1` are there (the demo fetch's 0.5 m surface model
   and 1 m terrain, float32 GeoTIFF; `data/raw/demo/MANIFEST.md`) the deck solver follows the
   measured decks (R2). Then `godot --headless --path game --script res://tools/check_drive.gd`.
   Laser-scan records that are not trees are left out (`GUGIK_NOT_TREES`: the Palm, written
   as `palm`). After a re-bake run steps 3-5 again.
   Loop 3b-2: `tools/bake_banks.py` (after the shore runs) marks natural banks on `shore` (`n`)
   and writes `sand` and `sandbars` (`g`: gravel); `crown_scales` writes `trees3d_crown` (one
   crown scale per scanned tree, 12,554 values on the first box, 38,570 since loop 3d-1, checked by `check_map_data.py`);
   `level_surfaces` puts a bridge's mapped pavements and tram bed on its deck (`dk` on
   `surfaces`). See Loop 3b-2.
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
   bridges. Run it after the bakes above. Like `ao.bin` it ends up in the prebuilt city (the map
   builder puts it in the materials, saved as `map/shared/light_map.res`), so the export leaves
   the raw file out.

5. `python3 -I tools/bake_water.py game/map` → `water.bin`, the surface map (v0.9: shore distance,
   the river's flow, what reflects, bridge-deck heights); a second or two. Only needs
   `centrum.json`; like `lights.bin` it ends up in the prebuilt city (`map/shared/surface_map.res`
   and the index's water test), and the export leaves it out.

6. Loop 3c: `python3 -I tools/bake_sectors.py` → `index.json` and `sectors/<i>_<j>.json`, the map
   in 512 m sectors (about a second; see "Sectors and streaming"). After any of the steps above.
   Loop 3d-1: it also writes `sectors/split.stamp` (the SHA-256 of centrum.json, lod2.* and itself).
7. Loop 3c: the prebuilt city, **with a renderer** (`--headless` drops MultiMesh and texture
   data): `godot --path game --resolution 320x180 --script res://tools/bake_city.gd` →
   `sectors/s_<i>_<j>.scn` (32), `proxies.scn`, `index.res` and `shared/*.res` (~16 s; it checks
   the landmark sites found from the index against the whole map's). Also needed after any
   change to `map_builder.gd`, `chunked_surface.gd`, `landmarks.gd`, `neon_signs.gd`,
   `sector_proxies.gd`; `tools/export_ios.sh` runs 6 and 7. `city.scn` is gone (loop 3c).
   Loop 3d-1: it ends by writing `sectors/city.stamp` (the split's digest and the SHA-256 of the
   maps and scripts it builds from: `bake_city.gd` / `check_map_data.py` `CITY_INPUTS`).

**What is committed (loop 3d-1, the user's decisions 2026-10-29).** The bake chain's output that
carries OpenStreetMap is committed: `centrum.json`, `ao.bin`, `lights.bin`, `water.bin` (the
derived database under ODbL; the three maps mix OSM with LoD2, and a clone without raw data
needs them). What comes from GUGiK's data alone is derived like the sectors: `lod2.bin`,
`lod2.json` (the LoD2 buildings) and `terrain.json` (the NMT), gitignored; `tools/setup_map.sh
--full` (or their absence) rebuilds them from `data/raw` (`prepare_demo.py`, `bake_terrain.py`,
`bake_gugik.py`), and on a clone without the raw data it says what to fetch
(`tools/fetch_demo.py` for the demo fetch, the Warsaw LoD2 package, `data/raw/demo/MANIFEST.md`). Steps 6 and 7's files (`index.json`, `index.res`,
`proxies.scn`, `sectors/`, `shared/`) are gitignored: re-bakes grew the pack 194 → 340 MB in a
day. **A fresh clone runs `tools/setup_map.sh` once** (steps 6 and 7, then the check; ~20 s, a
small window opens; it imports the project first if Godot never opened it); `--if-needed` does
nothing when they are there and match their inputs. `tools/verify.sh` runs it when they are
missing, `tools/export_ios.sh` rebuilds them every time, and the game says "run
tools/setup_map.sh" instead of starting without a city. `check_map_data.py` reports missing ones
as a WARN ("missing: run tools/setup_map.sh") and stale ones by content: a stamp whose hashes
don't match today's inputs (a checkout scrambles file times, so they aren't used).

Audio: `python3 -I tools/make_sfx.py game/audio/sfx` (v0.9: every sound effect
and bed, with the numbers; loops imported Forward, loop end = the full length, QOA;
`res://tools/check_sfx.gd` checks them); `python3 -I tools/make_music.py data/raw/music/<station_id> shots`
(the three original radio loops, as WAV; they are not in the game as WAV any more: put them
through `tools/add_music.py`, "Adding music"; `godot --headless --path game --script
res://tools/check_radio.gd` checks radio.json, the Ogg files, the playlists and each looping
station's loop point) and `python3 -I tools/make_ui_sounds.py game/audio/ui`.

LoD2 is from 2018, so newer towers (Varso and others) come from OpenStreetMap; LoD2 buildings
no longer on the map are dropped. The terrain is bare earth, so bridges and viaducts get decks
solved from what they cross (see Real roads).

## The website (aroundwarsaw.app, 2026-10-29)

`site/` is the game's landing page (English at `/`, Polish at `/pl/`) and the privacy policy
and support pages the stores link to (`https://aroundwarsaw.app/privacy/`, `/support/`). All four
pages are built by `python3 -I tools/site_build.py` from `site/src/` (template and copy),
`docs/privacy.md` and `docs/support.md`. The store listings: `docs/store/`.
Plain HTML and CSS, self-hosted fonts, one small script for the beta and feedback form
(Formspree), no cookies, no analytics. It is a Cloudflare Worker with static assets only
(`site/wrangler.jsonc`, custom domains `aroundwarsaw.app` and `www.aroundwarsaw.app`);
`.github/workflows/site.yml` deploys it on a push to `main` once the repository has the
`CLOUDFLARE_API_TOKEN` and `CLOUDFLARE_ACCOUNT_ID` secrets. Beta sign-ups and feedback arrive by
email through the form. Deploying by hand, the secrets and where the
beta links go: `site/README.md`.

## Layout

**One-command checks.** `tools/verify.sh` runs the verification set and prints one
PASS/WARN/FAIL table: the map-data invariants (`tools/check_map_data.py`), the road check
(`tools/check_roads.py`, loop 3a), the check scripts
(steering, settings, the HUD at phone size, landmarks, sfx, radio, the water on both city paths) and eight headless game runs, each with

(the drape check (loop 3b-2), the drive check on both city paths (loop 3b), steering, settings, landmarks, sfx, radio,
the water on both city paths) and eight headless game runs, each with
`--nosave` (`--quick` for a short set, `--ios` adds the export and the unsigned Xcode build,
`--only=` picks steps). `tools/shots.sh` renders standard screenshots at a phone's size
(`--list` names them). `tools/device_run.sh` builds, installs and launches the game on a
connected iPhone and copies its log back (loop G0+: each run's own copy,
`build/device/<label>/<label>_<date-time>.log`, with the bench's and the streaming soak's result
files beside it; it exits 3 when the `--done` line never came). A guard hook (`tools/hooks/guard_godot.py`, on in
`.claude/settings.json`) stops Claude Code from running the game without `--nosave` or a quit
flag. How the work is run: `docs/WORKFLOW.md`, `CLAUDE.md`.

- `tools/bake_osm.py`: turns the Overpass export in `data/raw/` into `game/map/centrum.json`
  (the command is in "Map data", step 1).
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
- Loop 3c: `tools/bake_sectors.py` (the map split into 512 m sectors: `index.json`,
  `sectors/<i>_<j>.json`), `map_builder.gd` `setup_streamed` / `build_sector`,
  `game/scripts/sector_streamer.gd` (loads the sectors round the camera, both city paths),
  `game/scripts/sector_proxies.gd` (one low-detail mesh per sector), `game/tools/bake_city.gd`
  (the prebuilt sectors, proxies, index and shared resources), `game/tools/check_streaming.gd`
  (step `streaming`); see "Sectors and streaming".
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
  `bubbles.gd` (speech bubbles and name tags in the HUD layer), `models.gd` (vehicles and people;
  loop 2c: the shape kit, the traffic families and their table `TRAFFIC`, the player's,
  rivals', police, parked and tram models) and `shaders/actor.gdshader` (per-instance paint,
  walking legs; loop 2c: the family shapes and the BLINK beat).
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
- Loop 3g-1: `police.gd` (perception, strikes, the chase's state machine, the traps and the lizak,
  the pull-over, the HUD and halos, the test drivers), `police/police_unit.gd` (a unit and its
  beehave tree), `police/police_tree.gd`, `police/bt/` (the trees' leaves), `police/police_talk.gd`
  (the conversation's `talk`), `police/police_balloon.gd` (the card); `data/police_traps.json`,
  `dialogue/police.dialogue`; `tools/check_police.gd`; add-ons `addons/beehave/`,
  `addons/dialogue_manager/`.
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
| `--shots=60,240` / `--out=DIR` | save screenshots at those frames (counted from when the city is built), then quit (sweep 2: the sounds are stopped 0.15 s before, so a windowed run no longer ends with leaked audio streams) |
| `--style=N` / `--lines=N` | visual style 0–3 (loop 2e: wins over the saved style for this run) / override the pixel image's line count |
| `--size=M` / `--yaw=deg` / `--fixed` | view height in metres (default 80) / camera turn / fixed camera (in Point: the Fixed camera scheme) |
| `--at=x,z` | start at map coordinates (metres, +x east, +z south), on top of a bridge deck if there is one |
| `--heading=deg` | the car's heading at the start (0 north, 90 east), for testing: with `--demo` it drives off that way |
| `--nohud` | hide the controls |
| `--no-touch` | desktop (trailer loop, 2026-10-29): no touch-only controls on screen (the pedals and HAMULEC, the stick's knob and Classic's strip hint, the helicopter's ▲/▼ pads, the title's "tap to drive"); the top row, minimap, wallet, cards, bubbles and the radio caption stay, and the panels get the pedals' room; the keys still drive. For recording on the computer (`tools/check_hud.gd` checks it) |
| `--no-input` | loop 3d-1: the window never takes the keyboard focus (`WINDOW_FLAG_NO_FOCUS`): test renders whose windows hold the focus for minutes (`check_streaming.gd` passes it; keys typed in another app had toggled the time of day, the overlay and the radio) |
| `--prebuilt` | load the prebuilt sectors like the exported game (loop 3c: `map/index.res`, `map/proxies.scn`, `map/sectors/s_<i>_<j>.scn`; `city.scn` before) instead of building each sector from its file |
| `--monolithic` | loop 3c: build the whole city at once from `centrum.json`, as before loop 3c (no sectors, no streaming): the pixel diff's reference |
| `--sectors=all` / `--sectors=proxies` | loop 3c: load every sector at the start and keep them all (the old behaviour) / only the sectors the car stands in, every other one as its proxy (to look at the proxies) |
| `--stream-log` | loop 3c: print every sector load (`stream: frame N in s_i_j, X ms on the main thread ...`), unload, any frame whose streaming went over 3 ms and any node that took over 1 ms to add; loop G0+: each worker load (`stream: frame N worker s_i_j: load X ms, instantiate Y ms, K frames; slowest frame Z ms (overlapping the load end + instantiate; process after …, draw …, to physics …, physics …, process before …)`) |
| `--spots=X,Z,H/X,Z,H/...` | loop 3c, with `--shots=F1,F2,...`: the car jumps to spot k (heading H) 90 frames before shot k, the sectors the view needs are finished 30 frames before it (`tools/check_streaming.gd`) |
| `--stream-soak=MIN` | loop 3c: the car on autopilot over every sector's middle (row by row, through buildings), the view 80 m then 220 m every 20 s, the helicopter for the last third; then `stream soak:` lines and the game quits (no traffic); loop G0+: the same two lines also go to `user://stream_soak_result.txt` (`tools/device_run.sh` copies it back), and `stream soak stats:` adds `frames_over_budget` (frames whose streaming took over 3 ms), `slow_frames` (each frame over 33 ms past the warm-up: frame, ms, the streaming ms in it), `sector_ms` (median, p99, max of a streamed sector's main-thread ms) and `kinds` (per node class added, the hand-over, the finish and the unload: count, total and worst ms) |
| `--debug-ao` / `--no-ao` | show / switch off the baked ground shadows |
| `--heli` | start in the helicopter |
| `--mission=N` | start rescue call N at once (N = 1, 5, 9… streets, 2, 6… roofs, 3, 7… river, 4, 8… parks) |
| `--autopilot` | testing aid: fly (or, ghosting through walls, drive) to each mission target; in a race or a side job, drive the route; with `--rival`, tail the rival |
| `--no-traffic` | no traffic, trams, pedestrians or rivals |
| `--lineup` | loop 2c: every vehicle model standing round the car, all facing its way (beside it the taxi, Podwózka, the police and guard cars and the two vans; a row ahead the cars' four shapes; behind, the six rivals, then the bus and a tram cab car), no traffic, and each model's triangles printed (`lineup:` lines). Close-ups: `--at=-1113.2,-263.4 --heading=160 --size=14 --nohud` (Marszałkowska) |
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
| `--ride=N` | loop 2d-1: Podwózka ride N's request, the car on the road 60 m before its passenger (the same N gives the same ride; with `--ride-quirk=river` or `zone` the passenger is picked near river spot / park N, so the leg fits); with `--autopilot` it is accepted after 2 s and driven |
| `--ride-quirk=river\|zone\|oldtown\|rechotka\|reroute` | loop 2d-1: force the ride's quirk (`oldtown` becomes `zone` on today's map; `rechotka` only by flag until the shops exist) |
| `--passenger=normal\|believer\|hurry` | loop 2d-1: force the passenger type |
| `--stars=X` | loop 2d-1: the live rating starts at X (1–5; for card shots) |
| `--ignore-app` | loop 2d-1: the autopilot drives the shortest road to the door, not the app's route |
| `--parody-log` | loop 2d-1: print `ride:` lines (the offer, the pickup, the quirk and its waypoint, every star change and why, the arrival, the pay with the wallet before and after, cancels, the autopilot's legs) and `gps:` lines (each GPS moment in traffic) |
| `--gps-in=S` | loop 2d-1: the app-taxis' first GPS moment is looked for S seconds in (screenshots) |
| `--pullover-frame=N` | loop 2d-1: the `--pullover=TAG` conversation at frame N instead of 60 (e.g. during a `--ride`) |
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
| `--quality=auto\|low\|medium\|high\|ultra` | the quality for this run (not saved; loop G1: default Auto, the level `tiers.gd` picks for the device; 0–3 are Low–Ultra) |
| `--model=ID` | loop G1: pick Auto's level as if on that device (`--model=iPhone12,1` is the iPhone 11: High; since loop G1b Auto draws it sharp, 1792×828 ×1, and 896×414 ×2 in the fallback; `iPhone17,2` the Pro Max: Ultra) |
| `--last-session=struggled\|calm` | loop G1b: start Auto as if the last session at the sharp image struggled (this launch is the ×2 fallback) or was calm (the sharp image), whatever the settings file says; nothing of it is written. The `quality:` lines say what Auto picked and why (`quality: Auto→High ×1 sharp (iPhone12,1) · image 1792x828`, `quality: Auto→High ×2 fallback (last session: GPU extras down 74 s of 410) · …`) |
| `--governor=on\|off\|log` | loop G1: the frame governor on or off for this run (default: on in a normal launch, held in test runs, the bench, the probe and the BENCH minute; `on` lets it act in those too); `log` is on plus a `governor status:` line every 5 s (loop G1b: with the session's tally where Auto's sharp rule applies) and a `governor minute N:` line per counted minute (fps, missed refreshes, GPU-bound ones, GPU extras down) |
| `--stress=cpu:N\|wait:N`, `--stress-from=S`, `--stress-to=S` | loop G1 testing aid: N × 0.5 ms of busy work a frame from S to S2 seconds after the city is up, in the game loop (`cpu`: the CPU's extras go first) or in the draw phase (`wait`: how waiting for the GPU looks to the main thread, the GPU's go first), to watch the governor drop and come back |
| `--sound-check` | play every sound once and print the bus meters, then quit (needs an audio device) |
| `--ghost-debug=1\|2` | loop 1: paint the occlusion ghost (1: ghosted magenta, other buildings green) or cut it fully (2), and print its ellipse in screen pixels with each screenshot |
| `--controls=point\|classic\|fixed` | loop 2a: the control scheme for this run (not saved) |
| `--traffic=empty\|low\|normal\|busy` (or 0-3) | loop 2a: the traffic level for this run (not saved) |
| `--settings` | loop 2a: open the settings panel at the start (screenshots) |
| `--settings-tab=N` | loop 2e: open the settings panel at tab N (0 Jazda · Driving, 1 Świat · World, 2 Obraz · Picture, 3 Dźwięk · Sound; loop MW-1: 4 Zeszyt · the notebook) |
| `--notebook` / `--notebook=CHAPTER\|ID` | loop MW-1: open the settings card on MOJA WARSZAWA, the notebook (a chapter by id or number 1-9, or a place's card by its id; screenshots) |
| `--found=all\|none\|CHAPTER[:K],…` | loop MW-1: the notebook's record for this run, in memory, no rewards (a chapter by id or number, `:K` its first K places; `--found=1:4,9` half of the first chapter and all of the ninth). Use with `--nosave` (a later save would keep it) |
| `--place=ID` | loop MW-1: start at a notebook place (`places.json` id): the sectors round its hint first, then the car on the nearest lane if that is inside the place's radius, else on the place (found within a second, standing) |
| `--notes-log` | loop MW-1: print `notes:` lines: each place's resolution at load (`notes: place <id> address\|name\|poi\|near N m from the hint (x, z)`), each find (`notes: found <id> (chapter N, k/8)`) and each chapter completed |
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
| `--debug-roads` | loop 3a: draw the bridge decks, approaches, tunnels, lane heights and piers round the car (Debug Draw add-on); loop 3b: the piers, portal legs and cap beams the bake placed |
| `--tunnel` | loop 3b: with `--at`, start on the floor of the tunnel under that point (the car shows through the ground as a silhouette) |
| `--drive-into-water=X,Z` | loop 10a: start at X,Z and drive flat out at the nearest water (within 120 m), the collision off until 3 m past the edge as if the car had jumped it; prints `water test:`, `water: splash at …` and `water: towed after … s …` (where to, how far from a lane, dry or not, the job / rescue / race / wallet), each with its frame. With `--kebab=0` a delivery is running (`tools/verify.sh` step `splash`) |
| `--ram-test` | the driving-feel loop: after 2 s, the car is put 14 m behind the moving traffic car with the longest straight lane ahead, 6 m/s faster, and drives on along that lane (Point, 65 km/h); prints `ram test:` lines: the hit (speed, the rammed car shoved to), then `past it N s after the hit` or `NEVER PAST it after 10 s` (`tools/verify.sh` step `ram`, with `--no-police`) |
| `--traffic-overlaps` | the traffic loop: the traffic counts the pairs of its cars whose boxes overlap each frame and prints `traffic overlaps:` at the end (car-pair frames, how many on a junction curve, the spots and the worst one, knots given up); use with `--traffic=busy --no-police` and an engine `--quit-after` |
| `--no-police` | loop 3g-1: no police, traps or patrol cars |
| `--police=1\|2\|3` | loop 3g-1: a chase at that level at frame 60, the chaser 40 m behind on your lane (and the blocker / the roadblock for 2 / 3) |
| `--trap=N` | loop 3g-1: start 150 m before speed trap N (1-4 in today's map), heading into it, and make it one of the day's; with `--pedal=gas` the car drives flat out along the road into the radar (through the traffic) |
| `--pullover=routine\|trap\|kebab\|sloik\|generic` | loop 3g-1: open that conversation at frame 60 with a patrol car stopped behind (screenshots; `--clicks` for the replies) |
| `--police-auto=escape\|stop\|hold\|still` | loop 3g-1: in a chase the car drives away flat out on the lane graph / stops at once (with a lizak waving: stops by the officer) / creeps along without escaping (cap tests) / stands without being pulled over (probes) |
| `--police-now` | loop 3g-1: no start grace, no cooldown (tests; with `--autopilot` the car roams at twice the limit: the soak) |
| `--police-log` | loop 3g-1: print every police state change with its frame (`police: …` lines; in a chase the car's place on screen each second, `police: b4 x … y …`) |
| `--police-offence=F:kind,…` | loop 3g-1: an offence at frame F (`speed`, `red`, `oneway`, `bump`, `ram`), seen by the nearest unit (the cooldown test P7) |

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

## The web build (2026-10-30)

The game in a browser at **https://play.aroundwarsaw.app** (aroundwarsaw.app/play/ redirects
there; the landing's "Play online" / "Zagraj online" button links to it). Same game, same
prebuilt city, desktop keyboard and the phone's touch controls as they are.

```zsh
tools/export_web.sh            # derived map files when missing, then the export in build/web
python3 -I tools/web/serve.py  # look at it: http://localhost:8060 (sends the COOP/COEP headers)
tools/export_web.sh --deploy   # also upload it (the user's yes first: it is public)
```

- **Preset "Web"** (`export_presets.cfg`): the iOS preset's file filters, threads on (the sector
  streamer keeps its worker thread), S3TC/BPTC and ETC2/ASTC textures. Godot draws the web with
  the **Compatibility** renderer (WebGL 2) whatever the project's renderer is, so the look is
  close to the phone's, not the same.
- **Threads need cross-origin isolation**: `tools/web/_headers` (copied into the build) sends
  `Cross-Origin-Opener-Policy: same-origin` and `Cross-Origin-Embedder-Policy: require-corp`.
  That is why the game has its own origin and Worker: the landing's CSP and Formspree form
  stay as they are, and the landing's deploys (site/, also from GitHub) never touch the game.
- **Cloudflare's 25 MiB a file**: the pack is ~140 MB and the engine ~40 MB.
  `tools/web/split_parts.py` gzips each and cuts it into 20 MiB parts in `parts/` (names carry
  the contents' hash, so they are cached for a year) with a `<file>.parts.json` manifest;
  `tools/web/split_loader.js`, in the page's head, wraps `fetch` so Godot's loader gets the
  parts joined and unzipped as one file with the right size for its loading bar. The download
  is ~141 MB (the sector scenes barely compress); R2 is not enabled on the account and not needed.
- **The Worker**: `site/play/wrangler.jsonc`, `aroundwarsaw-play`, static assets from
  `build/web`, custom domain `play.aroundwarsaw.app` (wrangler makes the DNS record and the
  certificate on the first deploy).
- **Compatibility renderer fix** (`scripts/instance_buffers.gd`): Godot 4.7.2's gles3
  `scene.glsl` multiplies an instanced mesh's vertex COLOR by the instance colour even in a
  MultiMesh without colours, and `multimesh_set_buffer` leaves the custom data's raw bits in that
  slot, so traffic, pedestrians and the splash came out bright green. On that renderer those
  MultiMeshes carry white colours too and their 16-float buffers are widened to 20 floats when
  sent (traffic, pedestrians, splash); on Mobile (the phones) the helper passes straight through.
- **What the browser test covered** (Chrome in the desktop app's browser pane): the title, the
  fly-in, the prebuilt city, traffic colours, keyboard driving (WASD), the touch stick from
  synthetic touch events at 844×390. Not covered: a real phone's browser (iOS Safari's memory
  with a 140 MB pack, the safe area: `OS.has_feature("mobile")` is false on the web), frame rate
  on a weak laptop, Firefox.
