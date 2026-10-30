# Backlog — issues found along the way

Small problems that agents reported or that showed up in screenshots. They are fixed in the
"loop" stage after the roadmap versions (or earlier, when an agent is already in that file).

## From v0.6 (traffic, trams, pedestrians, rivals)
- ~~Cars can overlap briefly in complex junctions~~ (fewer by three quarters, the traffic loop
  2026-10-30: junction cars watch each other's body and path, `--traffic-overlaps` counts them;
  left: two cars entering a short merging curve in the same frame); a racing rival stuck in
  traffic passes through other cars when off screen.
- Trams and crossing cars can touch nose to nose.
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
- **No toast** says the fallback came in (the brief made it optional): the Obraz tab's
  `auto · High ×2` and the `quality:` log line say it. A one-time toast ("Obraz prostszy, bo
  telefon się grzał · A coarser picture: the phone was struggling") is a game-designer call.
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

- **Part two (loop 3g-2)**: the city guards on foot and the guard car's behaviour (the mesh's
  shape 1 and SIREN's amber 1.5 Hz beat are ready; `police_unit.gd` takes a branch each), the
  pedestrian-zone cap and the clamp, the escort on rescues (accepting a rescue in a chase should
  end it), the race and side-job ties (the race marked +20 % for an escape, the kebab's heat
  frozen during the card), Phantom Camera's chase framing (11.3), the sounds in `make_sfx.py`
  (the siren, whoop, megaphone chirp, whistle, stamp: placeholders now from the far siren, the
  tram bell and the soft knock), the scripted first contact after the first race (the `routine`
  conversation exists: `--pullover=routine`), the escort and guard lines (`police_escort`,
  `guard` from police.md section 6, not merged yet).
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
- **The officer's legs swing** like a walker's (the people's shader swings every instance's legs;
  the swing is about one image pixel at 80 m). A standing pose would need a constant in
  `actor.gdshader` (part two, with the guards).
- **The trap's car turns round when it pulls out** (it parks facing the traffic, as police.md
  asks, and joins its lane the traffic's way; the turn takes ~10 frames behind the passing car).
- **The 2D pass**: the minimap's marks are now one triangle array (they were a draw call each);
  the rival dots, side-job places and target look the same. The pill (a panel and two labels) is
  three 2D draw calls while shown.
- **Memory**: Dialogue Manager's scripts are ~4 MB of static memory, loaded at the start (on first
  use they were a ~70 ms hitch on the Mac, likely ~0.3 s on the phone, as the card opened).
- **The soak's B4 check** logs the car's place on screen each second during a chase; the camera
  follows the car, so it stays near the middle (closest to an edge 0.46 of the screen in the soaks).

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
- **Loop 2d-2 (after 3c's streaming)**: the `rechotka` quirk joins the random pool once the
  Rechotka shops exist (today it is flag-only and names a shop nobody can see), and the `detour`
  passenger (a stop at any Rechotka, +½) needs them too; Pędzik, Leżak, the kebab stands and the
  billboards are 2d-2's; the `signs` and `column_posters` Podwózka lines (parodies.md 7) wait for
  the billboards. `oldtown` falls back to a park until the map has the Old Town square.
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
- **Loop 3e's structures, all allowlisted with place and reason** (`tools/check_roads_allow.json`,
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
  Kościuszkowskie by Tamka (625, −453) 2.4 m in 6 m and (642, −548). A rule for a road's end on a
  hump of the grid, or the 1 m NMT along the river (one download, ~125 MB for the whole box,
  DEMO 3.1's optional line), would fix the class.
- **The AO, lamp-light and surface maps** are 37 + 37 + 19 MB (93 MB of video memory as whole
  textures; the probe's textures 24 → 87 MB). Over the brief's 60 MB, but a window kept in RAM
  saves nothing on the iPhone's shared memory: it needs per-sector slices read from disk as the
  focus moves (the streamer's job, where the perf loop works now). Loop 3d-2.
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

## From the radio playlists loop (2026-10-29)
- Done: radio.json, shuffled playlists, `tools/add_music.py`, the radio check, README "Adding music",
  CREDITS "Music".
- **No libvorbis in this Mac's ffmpeg** (Homebrew's build lacks it): `add_music.py` falls back to
  ffmpeg's built-in `vorbis` encoder, which ignores the bitrate and writes about 185 kb/s (4.1 MB
  for a 3-minute song instead of 2 MB). Fix: an ffmpeg with libvorbis (the brief's `-c:a libvorbis
  -b:a 96k` is already what the tool uses when it finds one), or `oggenc`; nothing else changes.
- **Licences before a release**: any track whose licence is `unknown` (a WARN in the radio check)
  must be cleared; AI music tools' free plans may not allow a published game.
- **No skip button**: `radio.next_track()` exists, but hud.gd and main.gd (not touched in this loop)
  have no control for it; a tap on the ticker, or a key, would do.
- **`--radio=N`** clamps to the built-in three stations (`Radio.STATIONS.size()` in main.gd): a
  fourth station added to radio.json is reached with R, not by the flag.
- **A station's order restarts a track on re-tune**: tuning away and back starts the track it was
  on from its beginning (a looping single track still joins in the middle). A real radio would
  have moved on; a decision for the user if it grates.
- **The three original loops exist only as Ogg now**: their raw WAVs were in the repo and are gone;
  `tools/make_music.py data/raw/music/<station_id> shots` regenerates them, then
  `add_music.py --force`. The Ogg files are lossy copies of the lossless loops.

## From loop G0+ (streaming and heat on the iPhone 11)
- **A sector's load still makes one slow frame on the iPhone 11** (19-22 frames over 33 ms in a
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
- **`tools/device_run.sh` copies `Documents/bench_result.txt` from any earlier bench** when the
  run made none (the bench doesn't clear it at the start, as the streaming soak now does): read
  the card's date line.
- **The night bench sometimes has a sun-shadow pass** (on the Mac, 2 of 6 `--time=night` benches:
  57-69 shadow draws where the others have 0; before and after loop G0+'s change alike): the
  sun's shadow at night should be off from the first frame. Not looked into.
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
- **The export prints Dialogue Manager's C# errors** (`No loader found for resource:
  ...DialogueLabel.cs`, `ExampleBalloon.tscn` parse errors): the add-on's C# example and label
  files can't load in a non-.NET Godot. Harmless (the game uses its own balloon); the iOS
  export prints the same 11 lines (checked in this loop's `verify.sh --only=ios`). An exclude
  filter for `addons/dialogue_manager/example_balloon/*` and the `.cs` files would quiet it.
- **The city step rewrites 34 tracked files with byte noise** (`bake_city.gd` isn't
  byte-deterministic: the sector `.scn` files differ by a few bytes each run with no map
  change), in both export scripts. `--skip-city` avoids it for Android; a deterministic bake or
  a "bake only when the map changed" check would fix it for both.
- **Store graphics are not made yet**: the 512 px icon, the 1024 × 500 feature graphic and
  1920 × 1080 screenshots (Play's 2:1 limit rules out 2532 × 1170); `docs/store/play-console.md`
  lists what each needs.

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
- `--time=night --nohud` runs quit without writing the shot about one time in three (the log
  ends after "city built", clean exit); by day, or without `--nohud`, every run wrote it.
  `tools/shots.sh` would report MISSING.
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

## From the driving-feel loop (less sticky, 2026-10-30)

- Street furniture is still solid and unknockable: benches, bike racks, advertising columns,
  shelters and parked cars. On today's map 7 benches, 11 bike racks and 3 shelters overlap a
  carriageway (measured against the roads' half widths); the bake could keep them off the
  asphalt as map review B did for lamps and signal poles, or they could be knocked about like
  the roadworks' cones.
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
