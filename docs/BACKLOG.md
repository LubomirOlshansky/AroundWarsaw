# Backlog — issues found along the way

Small problems that agents reported or that showed up in screenshots. They are fixed in the
"loop" stage after the roadmap versions (or earlier, when an agent is already in that file).

## From v0.6 (traffic, trams, pedestrians, rivals)
- Cars can overlap briefly in complex junctions; a racing rival stuck in traffic passes
  through other cars when off screen.
- Trams and crossing cars can touch nose to nose.
- Name tags and bubbles show faintly through the translucent WIN/LOSE card.
- From the spawn point only two race finishes (the Palace, Złote Tarasy) fall inside the
  600–1800 m road window; add more finish places or widen the window by rival.
- The race and tail autopilots leave the car's collision off (like the mission autopilot);
  fine for screenshots, but autopilot runs can't test crashes.
- ~~Races pay respect only; the v0.65 side jobs add a shared złoty wallet (races, tips, rescues).~~
  Fixed in v0.65: races pay the rival's stake into the saved wallet.

## From earlier versions
- Rescue mission time limits are untuned.
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
- Roadwork barriers are pushed by a distance check, not physics: the helicopter's downwash and
  traffic don't move them, and AI cars drive through the ones knocked into the lane.
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
- Kerbs are visual only: the car drives over islands, medians and kerbs as if flat.
- The terrain grid stops ~9 m short of the map's south edge and ~5 m short of the east edge;
  carriageway areas and kerbs are cut there, but road strips, footways and areas (as before)
  run on to the map's edge and hang over the diorama's earth wall.
- Turn arrows are small pixel shapes; combined arrows (left + through + right) are cramped at the
  default zoom, and arrows on a roundabout ring follow the ring's `turn:lanes`.
- Rondo Dmowskiego's ring gets straight lane lines, not the real spiral markings.
- Bus lanes only where the lanes are tagged per lane or counted on one-way roads; AI traffic
  doesn't keep the bus lanes free.
- Hatched chevrons point along the area's long side, not with the traffic.
- Medians are found only between pairs of one-way roads; a two-way road with a median mapped
  as one line gets none.
- Where two deck pieces of one bridge are more than ~3 m apart (road, tram bed, footway on Most
  Poniatowskiego) each gets its own parapet and the gap shows the river below.
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
- Tapping walks the roof grid, so a tap on the cut-away part of a tower in front of the car picks
  that tower, not what shows through the cut.
- The Palace's roof rescue now lands on a 28 m annex roof: every tier is crowned by attics and
  pinnacles, so no 3 x 3 cells are flat up the tower. A rescue from the 30th-floor terrace would
  need a landing spot designed in.
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
- Puddles are a noise mask on the road layer: lane markings and stop lines are drawn over them,
  so a painted line crosses a puddle unbroken.
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
- Night water is a flat deep navy away from the lamps: calm, maybe too plain at the widest
  zoom; a faint sky sheen could come back if the device pass wants it.
- The bench ran uncapped (220-280 fps) for most of loop 1 instead of at the display's 120 Hz:
  frame times and GPU readings are not comparable with earlier sessions' numbers, so loop 1
  ran the v0.9 code alongside for its before/after. Fewer cars fill in over 600 faster frames.

## From loop 2a (controls and settings)
- Only the user can judge the feel on the phone: the hold-then-ease camera in Point, the turn
  rates (calmer at speed than before: 23.5 m full-lock radius at 90 km/h), the 0.15 dead zone
  and full gas from three quarters out on the stick (70 HUD units, ~38 pt radius on an iPhone
  13), the 80 m default view, and whether the 44 pt panel controls feel right. Touch was emulated from the mouse and driven by
  `--clicks` / `--drag` / `--stick` on the Mac; nothing ran on a device.
- Point with a finger that never lifts behaves like a fixed camera at whatever angle the
  camera had (it only comes round after a release). The zoom (− + / pinch) is not saved.
- In a dense spot the car can be pinned between a wall and a stopped traffic car that waits for
  it; the unstick turns it out after 1.5 s, and a second pin within 5 s tows it back onto the
  nearest lane on its level (next to a kerb that can be almost where it was, turned the lane's
  way).
  Traffic still stops for a player that only brushes it.
- Busy's traffic target is more than the spawner can place in the band round the view (70 vs
  ~44 at 80 m): the levels are calibrated on real counts. If the spawner changes, re-measure
  (bench `--traffic=`).
- The like-with-like GPU reading (110 m, Busy, Classic) was 2.43 ms by day against 2.27 before
  (night 2.20 vs 2.21): within the run-to-run spread (2.06-2.90 ms for one code), and the 3D
  view's GPU time can't include the HUD; the new defaults read 2.24 / 2.01.
- The keyboard in Point points in screen directions: on the diagonal opening view, W turns the
  car off the road's line (it goes up the screen). Classic keeps the old car-relative keys.
- The old `--fixed` flag now picks the Fixed camera scheme in Point (as CAM does).

## From loop 2b (frame rate on the iPhone)
- The device log starts with `ERROR: Mouse is not supported by this display server`
  (display_server.cpp:536), once, from the engine before any game script runs (no script asks
  for the mouse; switching touch-from-mouse emulation off on mobile didn't stop it). Harmless.
- The phone's GPU time can't be read (Metal has no timestamps in Godot 4.7), and at 60 Hz the
  main thread waits for the display inside "draw" (2–12 ms depending on the run), so the headroom
  under 16.7 ms isn't visible. A build that allows 120 Hz would show it as fps above 60 (not made
  this round; the old build did 64 fps from the helicopter with four times the GPU work).
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
- High stays the default quality on the phone (60 fps there); Medium is the first step down.
- The BENCH runs at the current settings and cap (not uncapped) from the spawn at the default
  view, 5 s settle + 55 s measured; the card's numbers are in English (Polish header/buttons).
- Shadow edges are a little finer than before (0.37 m texels on High instead of 0.49 m).

## From the project setup (agents, skills, checks; 2026-10-28)
- `check_landmarks.gd` exits 0 even when a check fails; `tools/verify.sh` reads its OK line
  instead. It should end with `quit(0 if failures == 0 else 1)`.
- README gives two different `bake_osm.py` command lines ("Map data" step 1 and "Layout").
- README names the Apple team ID. It isn't a secret (every signed build carries it); keep or
  drop before the first public commit.
- Device-run permission in CLAUDE.md stays per loop ("when the user said so for the current
  loop"); the user allowed phone test builds on 2026-10-28.
- Haptics fail on the phone: `Could not vibrate using haptic engine: (null)` in the device log
  (nine `Input.vibrate_handheld` calls). Rule out Low Power Mode / System Haptics off first;
  else a small iOS plugin with `UIImpactFeedbackGenerator`.
- The once-only `ERROR: Mouse is not supported by this display server.` at start on iOS comes
  from the engine before any script runs (loop 2b); harmless, but it keeps the device log from
  being clean.

## From loop 10a (the river is off-limits)
- The splash, the tow and the stone's look were judged on the Mac (screenshots, logs); the feel
  on the phone (does the splash read at the default view, is 1 s the right wait, is the toast
  readable) is the user's to say. The splash's sound (the hard knock pitched down + the rain
  bed's noise) was never heard: headless runs have no audio.
- The stone is the same granite edge everywhere, the Praga beaches included; a natural bank
  might read better with a lower timber or riprap edge (a look call for the art director).
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
- The helicopter's roof toast ("Land on open ground to take the car") is still English only;
  the new water one is Polish over English.
- `map_builder.bounds` isn't stored in `city.scn` (the prebuilt path had a zero rectangle);
  main.gd now sets it from the map data. Other code reading `map.bounds` on the prebuilt path
  was getting zeros before.
- The bench route's ghost car drives with its collision off, so the water test never runs on
  the bench; it was measured with the probe (car physics 0.05 → 0.05 ms at the river) and a
  micro-benchmark (0.8 µs a call, one call per physics frame).
- Windowed `--prebuilt --shots=` runs sometimes end with "8 ObjectDB instances were leaked at
  exit" / "4 resources still in use" (seen on the code before this loop too; not in headless
  runs).

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
- The neon sign quads (`neon.gdshader`, 361 signs) are not ghosted (they never were): a sign on
  a ghosted wall stays lit, mirrored, over the ghost. Feeding them the ghost's uniforms is one
  more material in main.gd `_update_ghost` (outside this loop's main.gd scope).
- Parked cars: map_builder.gd `CAR_PAINT` still has the red "#a83a2e"; `foliage.gdshader`
  repaints it (body and cabin) slate on both city paths. Change the palette at the next city
  bake (map side) and drop the remap.
- The pale jagged band south of Most Poniatowskiego by day is geometry (it stays with the
  mirror off, `--quality=low`): an area polygon on the water, map side with the sandbars
  (loop 3b), not the deck's reflection (which by day is a darker band, now half as strong).
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
- The minimap still shows the azure water and lime parks (HUD side).
- Buses and trams keep their Warsaw red-and-yellow livery and the rivals their looks (Słoik's
  red stripe and his orange name tag): street-level Warsaw is on the review's protect list.
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
- Not done in loop 3b (the triage's 3b row and item 9, for loop 3b-2): kerbs, islands and medians
  flat to the car; cramped turn arrows, Rondo Dmowskiego's spiral, chevrons, medians on two-way
  roads, deck pieces > 3 m apart showing the river; natural river banks, sandbars, tree crowns by
  roads.
