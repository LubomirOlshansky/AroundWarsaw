# Audit: Marszałkowska, Rondo Dmowskiego to Świętokrzyska (2026-11-05)

Agent `street-unslopper` (Opus), read against the street record (docs/streets/marszalkowska-centrum.md)
and Mapillary photos. The photos are saved under refs/road-marszalkowska-centrum-*/ (gitignored, with
SOURCES.md). Frame: `s` metres along the street from Rondo (south, negative) to Świętokrzyska (north),
`t` across it (east is +). No orthophoto was used yet: that needs the Mac.

**Evidence age.** Every fresh photo comes from one drive, on 2026-08-30, southbound on the **west**
carriageway (s 322 down to s -217). The **east carriageway's newest photos are from 2024-09-07**, so
everything said about it below is history and marked CHECK.

## Today against the game

### West carriageway (southbound), from the 2026-08-30 photos

| Stretch | Today | Game | Cause |
| --- | --- | --- | --- |
| A, Rondo to s≈-150 | 4 lanes; arrows L, L, T, R | 4 lanes (12 m); arrows L, T, T, TR | arrows from tags; ortho CHECK |
| A, s -150..≈40 | 3 lanes; the 3rd (right) lane starts just south of the Złota crossing; no BUS paint seen | 3 lanes s -233..0, then 2 lanes from s 0 | OSM way join at s 0 |
| B, s 40..80 | 2 lanes | 2 lanes | ok |
| B, s 80..135 | 2 lanes, a left pocket for the U-turn link (s 77-82), a parking lane on the right | a full 3rd lane, 9.75 m, over the whole way | pocket and parking not mapped as such |
| B, s 135..172 | 2 lanes, a parking lane | 2 lanes on 6.5 m, no parking, no parked cars | `parking:*` not read |
| C, s 172..200 | zebra ≈ s 195, zebra with a cycle crossing ≈ s 180 | zebra s 190, cycle crossing s 183 | ortho CHECK |
| C, s 200..315 | 2 lanes, a parking lane with parked cars and a disabled bay | 2 lanes | `parking:*` not read |
| C, s 330..372 | no fresh photo | 3 lanes s 340..365, then 2 | CHECK |

### Between the carriageways (tram)

- The game draws one ballast surface for s -233..359.
- Today the track is embedded or paved in block A and in block B up to about s 105.
- From about s 140 to s 330 there is a **new planted strip** between the west carriageway and the
  tram: grass, a low hedge, a young tree every 8-10 m, behind a low black railing.
- The 2023 tree scan has none of those trees; the planting is newer than the scan.

### East carriageway (northbound): CHECK, newest photos 2024-09-07

- In 2024: 3 lanes at s -100 (bus stop, a broken thick line at the kerb), s 20 and s 100.
- The game has:
  - 3 lanes at s -173..38;
  - 2 lanes on 9.2-9.4 m (4.6 m lanes) at s 38..203;
  - 3 lanes on 7.81 m (2.6 m lanes) at s 203..364. `lane_split` keeps a lane while width/n ≥ 2.6.

### Zebras

- The game **paints lane lines straight through the zebras** (19 places on this street, check L4).
- The Złota crossing is a signalled zebra across the west carriageway and the tram. It is at about
  s 46-49 by the photo's GPS; the data puts it at s 54. CHECK on the ortho.

### Trees

- T1 = 0: none of the 45,192 scanned trees stands on this street's carriageways. Here the trees are
  missing (the new strip), not in the road.

## Causes (bake rules)

1. `bake_lane_lines` (tools/bake_roads.py) paints each OSM way on its own (`lw = (cl + cr) / total`).
   Where the lane count changes at a join, the lane boundary jumps 1-1.6 m sideways and lines end
   there (L1, L2).
   - City-wide: 354 main-road joins with a lane-count step and 369 with a width step over 1.5 m.
2. `_paint_along` / `_crossed` cut lines only at road strips and junction boxes, never at zebras (L4).
   - City-wide: 643 of 2,177 zebras have a lane or centre line across them.
3. `lane_split` has no limit on lane width: 7 one-way main ways are drawn with lanes under 2.75 m.
4. The OSM `lanes` here count the pocket and the parking strip differently, and `parking:*` is not read.
5. Width tapers (RS3) don't exist yet.

## Fix list, in order

1. **Stop lane lines at zebras**: add the zebras to `_crossed`, 1 m each side. City-wide rule.
   Verify with L4 → 0.
2. **Paint markings per chained carriageway**: chain consecutive ways with the same name and
   direction, keep the lines at fixed offsets from the tram-side edge, and open or close an extra
   lane on its real side with a 20-30 m taper (RS3). City-wide rule. Verify with L1 and L2.
3. **Today's lanes for this street**:
   - By an override that re-applies after every bake (the car_free.py pattern).
   - West: A 4 lanes; 3 lanes from s -150 to ≈40; B 2 lanes plus the left pocket (s 80..120) and a
     parking lane (s 80..172); C 2 lanes plus a parking lane (s 200..315).
   - East: wait for fresh evidence.
   - Plus a `lane_split` sanity rule: lane width 2.75-4.2 m, else the count comes from the width.
4. **Classify B2b, tram railing**: a fence parallel to a tram line or platform edge within 4 m.
   Built in tools/street_pass.py. 252 such fences city-wide, 124 within 3 m of a lane.
5. **Narrow B5**: only a barrier that wraps a stair (at most 25 m, both ends by it). Built.
6. **Tram bed and the new green strip** (RS5 surfaces; young trees through the override). Bench.
7. **Arrows**: a left arrow in the U-turn pocket; the Rondo approach after an ortho look.
8. **P1**: the bin on Sienkiewicza's strip (s 172, t 30) snapped clear in `snap_props`.

## Objects (verdicts and models)

| Object | Verdict | Model | Evidence |
| --- | --- | --- | --- |
| `barrier:fence:-856:424`, `-870:392` (tram stop) | RETEXTURE | `tram_railing` (wanted) | black steel railing at the Centrum tram platform, 2026-08-30 |
| `barrier:fence:-1024:-64` (s 245..328) | RETEXTURE, solid or soft A/B | `tram_railing` | low black railing by the tram, 2026-08-30 |
| `barrier:wall:-916:190`, `-922:174` (metro Centrum 8 and 7) | REPLACE | `balustrade`, granite | grey granite parapet about 1 m with a flat coping, 2024-09-07 (before the skwer) |
| `barrier:wall:-862:416`, `-882:408` (platform and underpass stairs) | REPLACE | `balustrade`, rail | concrete upstand with a black rail, 2026-08-30 |
| `barrier:wall:-886:402` (59 m along the west kerb) | RETEXTURE, CHECK | `tram_railing` style | a continuous black pedestrian railing about 1.1 m, not a wall |
| `guard_rail:ground:-882:396`, `-878:440` | KEEP solid, look RETEXTURE | `tram_railing` style | vertical black bars, not a W-beam; ortho CHECK |
| shelters | KEEP | `instanced:shelter` | 2024 and 2026 photos |

## Wanted models (specs from the photos)

- **`tram_railing`**:
  - Black or very dark grey steel (#22262a), 1.1 m high, with a top and a bottom rail.
  - Vertical bars about every 12 cm, as a texture or alpha on one quad strip, and a round post every 2 m.
  - It reads open (you see the platform through it). One material.
- **`balustrade`**, 1.0-1.1 m high, following the stair's U outline, in two kinds:
  - (a) granite for metro Centrum: a 0.3 m solid parapet in mid-grey granite (#8f8f8a) with a lighter
    4 cm coping (#b5b3ad);
  - (b) rail for platform and underpass stairs: a 0.4 m concrete upstand (#a9a59d) with the
    tram_railing bars above it.

## Building fronts, east side

| Front | Rung | Note |
| --- | --- | --- |
| Rotunda | A, `landmark:rotunda` | look check only |
| Wars, Sawa, Junior | A, existing landmark | photo-way only; the south end of Wars is under scaffolding (2026-08-30): don't model it |
| s 165..185, the corner with Sienkiewicza | C | a construction site; CHECK |
| s 184..244, the Eastern Wall row | B | red-brick grid frame with tall blue-green glass bays, about 8 storeys, bank and shop fronts, flat roof |
| s 264..335, Centrum Marszałkowska | B | glass curtain-wall office, about 10 storeys, staggered silver fins, a glass pavilion at street level |

## Open questions for F (default built if no answer)

1. East carriageway lanes (no photo since 2024-09): 3 lanes of at least 3 m all the way.
2. The west lane that starts south of the Złota crossing: a plain lane (no BUS paint seen).
3. Parking lanes on the west side (B, C): an asphalt strip with blocky dashes and parked cars.
4. The Złota crossing: s 54 (data) until the ortho says otherwise.
5. Tram railings: solid, 1.1 m (the real platform edge); soft is the A/B.
6. Rondo arrows: L, L, T, R after an ortho look.
