# The first scene: the street the player sees first

The user's ask (2026-10-31): decide where the game starts, take that street at the moment the
player first sees it, and polish that square to the maximum so the first look is a "wow".
This plan picks the place, says what "the maximum" means there, and splits the work into
items for the lanes. It is the look and the opening shot of the "first 10 minutes" in
docs/DEMO.md 6.2 and docs/design/loop-3h-handover.md item 6 (that item owns the hints, the
first order and the first race; this plan owns the place and the camera's first seconds).

## 1. Where: Marszałkowska at Plac Defilad (the default; parked in QUESTIONS.md)

| | Place | For | Against |
| --- | --- | --- | --- |
| **A (default)** | **Marszałkowska by Plac Defilad**, between the Museum of Modern Art and the Rotunda | The Palace, the city's symbol, fills the frame; the new white museum, the Eastern Wall and the Złota 44 / Varso skyline sit round it; the spawn is already here (`SPAWN_LATLON`, centrum.json spawn −911.6, 278.6); DEMO 6.2's whole script starts here (the kebab stand at Świętokrzyska 150 m ahead, the first order past the Rotunda, the race to the Palm); the dusk thread is already polishing the Palace, Centralna and Złota | The busiest view on the map, so the heaviest frame for the phone (section 4) |
| B | Plac Zamkowy and the Old Town | The prettiest postcard; the Column and the Castle are built | Off the demo's script (a 2 km detour to the kebab stand and the Palm); narrow streets for a first drive; no towers |
| C | Rondo Daszyńskiego, among the towers | Spire, HUB, Złota 44's neighbours: a "big city" look | Far from the script's places; a roundabout is a hard first corner |
| D | Most Świętokrzyski over the Vistula | The river, the pylon, the stadium on the far bank | A bridge deck is a poor first drive (no turns, the river is off-limits); the river reads empty by day |

A wins because the first frame and the first minute of play happen in the same place: the
"wow" isn't a postcard the player drives away from.

## 2. The first moment, beat by beat

1. **Title (0:00)**: the title screen over the square, the radio's first song starting. The
   fly-in that exists (`camera_shots.gd`, Phantom Camera) starts high by the Palace's spire.
2. **The fly-in (about 3 s)**: down past the spire and the clock, across Plac Defilad, over the
   museum's white roof, to the small red car at the kerb on Marszałkowska. A tap skips it.
3. **The first frame of play (the "square")**: the car on Marszałkowska level with the museum's
   east face, the Palace to one side, the museum's long white wall and arcade behind, the
   Eastern Wall's department stores across the street, a tram passing, people on the
   pavement, the kebab stand's steam ring ahead. This is the frame to polish to the maximum.
4. **The first 30 s of driving**: south along Marszałkowska to Świętokrzyska and the stand,
   then on past the Rotunda (DEMO 6.2). Everything in view on that route is in scope.

The exact spawn point and heading are set by eye on shots (section 5), not guessed here: the
frame must show the Palace and the museum together at the default zoom on a 19.5:9 phone.
A spawn move is a runtime start point in `main.gd`, not a re-bake of `SPAWN_LATLON` (a re-bake
runs the whole chain); the sector prefetch (`sector_streamer.gd`, `sector_packs.gd`) reads the
spawn too and must use the same point.

## 3. "To the maximum": what the square needs

The box: Plac Defilad's east half and Marszałkowska from Świętokrzyska to Aleje Jerozolimskie,
about 600 × 350 m, plus the Palace as the backdrop. In priority order:

| # | Item | What | Lane / agent |
| --- | --- | --- | --- |
| 1 | **Muzeum Sztuki Nowoczesnej** | The white box as it is (BACKLOG, high priority; spec below) | landmarks: Opus spec, `object-modeler`, `art-director` |
| 2 | **The opening shot** | The spawn point and heading, the fly-in's path ending on that frame, a skip by tap. **Built 2026-10-31**: the start (PR #115) and the flyover (docs/design/opening-flyover.md) | gameplay-dev (Opus) |
| 3 | **The Eastern Wall** | Domy Towarowe Centrum (the three glass stores and the pavilions in front) and the Rotunda: real shapes, parody names and lit signs | landmarks + content (signs) |
| 4 | **Plac Defilad's ground** | The square's paving and the new park strip (A-A Collective) in front of the museum, trees, benches, lamps; the metro entrances (Centrum, Świętokrzyska) | object-modeler; map-engineer if the ground areas change |
| 5 | **Marszałkowska's street** | Clean kerbs, crossings, the tram tracks and stops, bus shelters, the kiosk and the kebab stand reading well up close | map lane (markings) + object-modeler (props) |
| 6 | **Life** | A tram in the first frame, pedestrians on both pavements, a few cars: denser here than the city average, still inside the traffic budgets | gameplay-dev |
| 7 | **Sound** | The radio's first song, the city bed, a tram bell in the first seconds | gameplay-dev (audio) |
| 8 | **Light** | Day stays the start (decided 2026-10-28). Dusk and night here come from the dusk thread | the "Match landmarks to Warsaw at dusk" thread |

**Not in this plan (coordination).** The thread "Match landmarks to Warsaw at dusk" owns the
dusk and night look of the Palace, Centralna and Złota (lights, shaders, the landmarks' lit
windows): this plan doesn't touch the light setup, and its shots use that thread's result once
it lands. Loop 3h item 6 owns the hint finger, the first order and the first race.

### Spec for item 1: Muzeum Sztuki Nowoczesnej (MSN)

Thomas Phifer's museum, opened 25 October 2024, on Plac Defilad's east edge facing
Marszałkowska. What makes it read:

- **One long, low white box**: poured white concrete inside and out, matte, almost no joints.
  The OSM outline in `centrum.json` landmarks ("Muzeum Sztuki Nowoczesnej") is about
  104 m along Marszałkowska by 40 m deep; today it is built from many LoD2 parts in plain white
  (a 26 m top over 5 m strips), with no model and no card.
- **An arcade at the base**: the ground floor set back behind square white columns on both long
  faces, a glazed lobby, café and bookshop behind (warm light at night).
- **A horizontal slot at mid-height**: one long ribbon of windows across each long face (the
  second-floor galleries' clerestory), dark glass, otherwise a blank wall.
- **A few large "city room" windows** on the upper floor, looking at the Palace and the city.
- **A flat roof** with long skylights over the top galleries (they show from the isometric view).
- **Next door**: TR Warszawa, a black steel-clad cube (building after the museum); the outline
  near (−1062, 54) in `centrum.json` should be checked against it.

Detail level L3 (the model-from-photos skill): the spec is written from the photos in
`refs/muzeum_sztuki_nowoczesnej/`, and acceptance scores matched shots against them. Values left
for the spec writer (Opus) to set from photos, not for the modeler to guess: the
height (LoD2 says 26 m), the arcade's height and column spacing, the slot's height and depth,
which face gets the big windows, the skylight count. The card text (Polish + English) goes to
the game-designer. Pitfalls from the landmarks lane apply (BACKLOG "Landmarks lane, hand-over"):
a site found in `data["buildings"]` needs its box in `bake_sectors.py` `SITE_AREAS`; rebuild the
prebuilt sectors with a renderer; check both city paths.

## 4. Performance

The first frame is probably the heaviest on the map: the Palace, the towers and the museum in
one view. Every item adds draw calls, so: a bench at the spawn before item 1 and after each
item (DEVELOPMENT.md "Performance budgets"); the museum as few meshes as the Palace's model
uses per part; the life (item 6) inside the traffic and pedestrian budgets. If the frame goes
over, perf-engineer (Opus) cuts before more is added. The phone shows what the bench can't:
the iPhone 11 at the first frame is the check that matters (a device run, the user's yes).

## 5. How it is accepted

- A new shot set `first` in `tools/shots.sh`: the first frame of play, 5 s and 30 s into the
  drive, the fly-in's middle; at 2532x1170 and 2868x1320; day, plus dusk once the dusk thread
  lands; both city paths.
- `art-director` (Opus) judges the before/after against the art bible and the question "would a
  stranger stop scrolling at this frame?"; anything it returns goes back to the item's owner.
- `tools/verify.sh` PASS, bench within budget, and a device run on the iPhone 11 and 16 Pro Max
  when the user allows one.

## 6. Order of work (one thread per item)

1. The MSN model (item 1): the spec on Opus, built by `object-modeler` (Sonnet), accepted by
   `art-director` (Opus).
2. The opening shot (item 2) and the `first` shot set: gameplay-dev (Opus). From here on every
   item is judged on the `first` shots.
3. The Eastern Wall and the Rotunda (item 3), then Plac Defilad's ground (item 4), then
   Marszałkowska's street (item 5): object-modeler with an Opus spec each.
4. Life and sound (items 6, 7): gameplay-dev, after loop 3h item 6 lands (same first minute).
5. A perf pass and a device run on the first frame.
