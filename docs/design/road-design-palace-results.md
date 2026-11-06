# Road design POC: the Palace streets rebuilt from zero (results)

2026-11-06. The research and the design are in [road-design-system.md](road-design-system.md); the
workflow is the skill `road-design`. This page says what the proof of concept built, how it looks next
to main, and what is left.

**Not applied to the shipped map in this PR.** Apply it locally to see it:
`python3 -I tools/road_design.py palace` (writes `game/map/centrum.json`; refused on a map that has it
already), then `python3 -I tools/bake_sectors.py`. Where a designed street ends mid-block the old lane
lines carry on beside the new ones (up to 2.4 m off), which the road ratchets catch (7 more line jogs
for `road_smooth --check`, street_pass K2/L2 up on the three streets). Round 2 closes the area on
junctions first.

## What was rebuilt

Spec: `docs/roads/palace.json` (about 200 lines). Generator: `tools/road_design.py palace`. Pictures:
`tools/road_design_plot.py`.

| Street | Stretch | Length | What the spec says |
| --- | --- | --- | --- |
| Marszałkowska | 57 m north of Świętokrzyska | 57 m | tram bed in the middle, 3 + 3 lanes, T T R arrows |
| Marszałkowska | Świętokrzyska to Złota | 493 m | tram bed, 3 + 3 lanes; parking strip from s 73; a bus lane and a hatched gap from s 360; two zebras with cycle crossings (s 177 and 303, from OSM: the photo predates them); Fangora, Sienkiewicza and a service road open into it |
| Świętokrzyska | 85 m east, 120 m west of Marszałkowska | 205 m | 5 lanes with T T L arrows and a cycle lane east; TR LT arrows, a hatched gap and parking west |
| Emilii Plater | Pańska/Śliska to 170 m short of Jerozolimskie | 400 m | two carriageways of 3 lanes + a red cycle lane, a raised median with trees, two U-turn gaps, two zebras with refuges, 9 side roads and driveways |
| Junction | Marszałkowska × Świętokrzyska | | 4 arms, 6 m kerb returns, 4 zebras (8.5, 9.5, 7, 8 m wide, as painted), 4 cycle crossings, stop lines, solid lines before them |

In total 1,155 m of street and one big junction: 265 carriageway pieces, 58 kerb runs, 149 lane lines,
40 arrows and words, 14 zebras, `--check` 0 problems. Applying it hid 62 old OSM road ribbons where
they ran inside the new streets, and dropped or clipped the old layers there (223 marking pieces, 109
kerb pieces, 70 symbols, 27 zebras and cycle crossings, 25 old median grass patches, 16 planter walls).

## Before and after

All shots: cloud renderer (`--quality=low`), daylight, no traffic, `--yaw=20.2 --size=40`, the same
spots on main's map and on the designed map. The images are on the POC's before/after page (linked
from the PR); they are not committed.

| Spot | Where | Before (main) | After (design) |
| --- | --- | --- | --- |
| `ms` | Marszałkowska × Świętokrzyska from the south | short zebra bars, the stop line far behind the zebra, lane lines running on through the junction box | one asphalt shape with round corners; each arm a full-width zebra as painted (8.5-9.5 m) beside a red cycle crossing; stop line, solid lines and T T R arrows on the approach |
| `ms2` | Marszałkowska 150 m south | a slip road with a pavement triangle, an asphalt flare on the east kerb | Fangora opens with kerb returns; zebra and cycle crossing over both carriageways and the tram |
| `ms3` | Marszałkowska by the metro | a U-turn through the tram bed with kerb bulges and lane lines bending round it | zebra and cycle crossing, straight kerbs; the U-turn is not designed yet (below) |
| `ep` | Emilii Plater by the Palace | small jogs in the median edge and a grass patch where two OSM ways meet | straight kerbs, median and cycle lanes along the whole stretch |
| `ep2` | Emilii Plater U-turn | two noses of different shapes | a gap with matching round noses |
| `ep3` | Emilii Plater zebra by the Palace | turn arrows painted past the zebra, a median gap behind it, zebras 3.5 m | the zebra across both carriageways with a refuge in the median, side roads opening into the street |
| `ep4` | Emilii Plater at Śliska | similar to after | the same gap; the side street gets kerb returns |

Flat views (from `road_design_plot.py flat`, the old map on the left): the junction shows the main
difference best. The old one is the overlap of 9 ribbons with an island left over by the tram stop;
the new one is one shape drawn from the four arms.

## What it fixed and why it stays fixed

- No joins: each street is one axis with cross-sections, so there is nothing to stitch. A lane that
  starts or ends is paint; the kerbs only move where the real kerb moves, over a 12-25 m taper.
- The junction is built from its arms (mouths, kerb returns, crossings, stop lines), so its lines cannot
  cross each other.
- Changing a street is an edit of its spec and a rebuild, checked by `road_design.py --check-all` (the
  new verify step `design`).

## What is left

1. **The two ends of Emilii Plater** that IMG_7264 and IMG_7266 show (the "Y" north of Jerozolimskie,
   the stepped widening by Świętokrzyska) are not rebuilt yet. They need the Emilii Plater ×
   Jerozolimskie and Emilii Plater × Świętokrzyska junctions, with the 4-lane left|left|through|right
   approach and the island at s 495-600 measured on the ortho. Next, with Aleje Jerozolimskie from
   Emilii Plater to Marszałkowska.
2. **Tram U-turns**: Marszałkowska has two links through the tram bed (s 191 and 283-291 from the
   junction) that the old map drew; the spec has no way to say "a paved gap in a tram median" yet.
3. **Traffic**: the AI lane graph still comes from the OSM ways (shots use `--no-traffic`). The cars
   follow lanes that are still in the right places on these stretches, but the graph should be made
   from the spec's lanes (phase 2).
4. **Bake integration**: the design is applied to `centrum.json` by hand after the bake (and not yet in this PR).
   `apply_all()` is ready for `bake_osm.py` to call after `road_smooth`.
5. **Phone check**: none yet. The draw call count is unchanged in kind (the same layers), but the
   carriageway comes in 8 m pieces, so a bench run is due before this goes beyond a POC.
