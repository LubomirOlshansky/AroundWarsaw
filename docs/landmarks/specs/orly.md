# Dom pod Orłami and Skwer Linearny na Złotej: spec

Site key `orly` in `game/scripts/landmarks.gd` (`_find_orly`, `_build_orly`); the square is
`tools/car_free.py` (data) and `game/scripts/skwer_zlota.gd` (furniture). Written 2026-11-02 from
F's five photos (the building from the square, the square from above and from the ground, the
city's render) and the news of the opening (3 August 2026: Złota between Marszałkowska and Jasna,
the squares in front of Dom pod Orłami and the Philharmonic; RS Architektura Krajobrazu, Skanska).

## 1. Identity

Dom pod Orłami (Jasna 1; Jan Heurich, 1912-17; rebuilt 1948-50): the national cooperative
council's house at the corner of Jasna and Zgoda. What makes it read:

1. **Two round corner towers** framing a seven-bay front, each stepping up in three drums over the
   cornice to a **bronze eagle with spread wings**.
2. **Mottled sandstone** (blocks from cream to ochre), a tall ground floor with big windows and
   **two portals**, four floors of dark mullioned windows.
3. An attic band with **a round window in a carved panel** by each tower and **metal letters** in the
   middle; a **low pediment** with a flagpole.

## 2. Massing

Frame: u along the front from the west tower to the Jasna corner, +v out of the front (towards the
square); origin (-824.9, 48.35), u = (0.937, -0.349). The OSM outline (front wing on Zgoda, Jasna
wing, west wing) is the plan, simplified at 0.3 m; the zone is the outline grown 1.5 m plus its hull.

| Part | Where | Heights above ground |
| --- | --- | --- |
| Ground floor | the outline | -0.6 to 7.0 m, string course 6.9-7.3 m |
| Upper floors | the outline | 7.0 to 24.0 m (four floors of 3.9 m, attic band 22-24 m) |
| Cornice | the outline grown 0.45 m | 23.5 to 24.0 m, parapet to 24.6 m, roof at 24.08 m |
| Towers | centres u = ±15.6, v = 0 (the outline's round corners) | drums r 3.7 / 3.0 / 2.3 / 1.3 m from 24.0 to 27.4 m |
| Eagles | on the top drum | 27.4 to 29.7 m, wings 4.2 m across |
| Pediment | u -11 to 11 on the cornice line | 24.0 to 25.7 m; flagpole to 32.2 m |

Heights come from the photo's proportions (the towers' centres 31 m apart), not from LoD2 (20.8 m).

## 3. Facade

- Windows (`_bays`, M_GLASS, #353b42): ground floor 1.0-6.0 m, 2.2 m wide; upper floors 2.5 m tall,
  1.9 m wide; 3.5 m bays. Three per floor round each tower's outer quarter, on the outline.
- The front's ground floor by hand: windows at u -7, 0, 7 (2.5 m wide), portals at u ±3.5 (stone
  frames 3.1 x 5.4 m, dark doors 2 x 4.4 m).
- Attic panels at u ±10.6 (3.4 x 1.9 m, darker stone) with round windows (r 0.82 stone, 0.62 glass).
- Letters (the landmark signs, lit day and night, dim warm grey): KRAJOWA / RADA SPÓŁDZIELNI ORŁÓW,
  0.72 m tall, at 22.5 and 21.55 m. A parody of the real name (the council of the eagles' coops).

## 4. Colour and material

Wall #cdb48a, base #b99d72, cornice and frames #ddcca8 (M_STONE); roof #77706a; doors #3a332c;
bronze #5e5548. Card "Dom pod Orłami".

## 5. The square (Skwer Linearny na Złotej)

- **Data** (`tools/car_free.py`, run by bake_osm.py and on its own): Złota's old one-way loop,
  its service stubs, road-bed walls and fills are taken out; the three graph edges are `cf: 1`
  (lane_graph.gd: no traffic, no routes); a `ped_zones` polygon "zlota" (20 km/h); a lime in each
  mapped tree pit that had no tree (27) and 9 on the lawns' edges (9 m tall, crown r 2.0 m).
- **Furniture** (`skwer_zlota.gd`, one mesh, both city paths): 19 pale stone blocks (7 round the
  rock fountain's pool, the rest loose on the lawns; solid), two water jets, 10 larch benches
  between the limes, a curved bench of five pieces facing the fountain on the old tunnel ramp, 12
  café sets under the limes by the facades, retractable bollards across the Jasna end.

## 6. Open (Mac look check, docs/QUESTIONS.md)

The eagles' pose and size, the letters' size and colour, the tower drums' steps, the portals'
spacing; the blocks, benches and cafés against the real square; whether Zgoda in front of the
building is still open to cars (kept as the map has it).
