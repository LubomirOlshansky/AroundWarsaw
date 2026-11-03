# Cedet (the 1951 Central Department Store): spec

Site key `cedet` in `game/scripts/landmarks.gd` (`_find_cedet`, `_build_cedet`). Written 2026-11-02
from the Mac's reference set `refs/cedet/` (Wikimedia Commons, 10 photos, of which 3, 4, 5, 6 and 8
show the building after the 2016-18 rebuild, plus the GUGiK orthophoto; SOURCES.md and REPORT.md
there, not in git) and the GUGiK LoD2 heights in the map pack.

## 1. Identity

Zbigniew Ihnatowicz and Jerzy Romański's CDT (1948-51), later Smyk, rebuilt as Cedet in 2018:

1. A long **glazed department-store block**: **continuous ribbon glass** in dark bronze frames
   between **cream rounded floor slabs** at every storey.
2. **Rounded street corners**: the glass bands run round the Krucza corner.
3. The **crown**: a cream cornice band, then a **set-back glass pavilion** whose roof plate
   **sweeps up into two wings** at its ends.
4. A **tall open ground floor on granite piers** with shop glass set back under the first slab.
5. The **steel loop with an arrow** on the Jerozolimskie front, **blue neon** at night.

## 2. Massing

Frame: u along Al. Jerozolimskie from Krucza (west) to Bracka (east), +v out of the front (south);
origin (-480.85, 314.3), u = (0.950, -0.312). The plan is the OSM outline "Cedet" straightened to
14 corners (CD_RING): the avenue wing (u -36..36, v -28..2, its Krucza and east faces slanted),
a link (u -16..16, v -40..-28) with notches either side, and the north wing (a pentagon with its long
diagonal face on Bracka, to v -67). Corners rounded: Krucza x Jerozolimskie r 5 m, the east end r 4 m.

| Part | Where (local) | Heights above ground |
| --- | --- | --- |
| Ground floor | the ring moved 1.8 m in (shop glass), piers on the line | -0.6 to 6.5 m |
| Glass storeys | the ring | 6.5 to 29.5 m (five storeys of 4.6 m) |
| Floor slabs | the ring moved 0.35 m out | 0.52 m at 6.5, 11.1, 15.7, 20.3, 24.9 m |
| Cornice | the ring moved 0.25 m out | 29.5 to 31.0 m, roof cap at 31.0 m |
| Pavilion | u -20..20, v -24..-5 | 31.0 to 35.0 m |
| Roof plate | u -22..22, v -26..-3 | 35.0 to 35.45 m; wings out to u ±28.5, up to 38.2 m |

Heights from LoD2 (the main roof 42-44, its top 46, ground ~11) rather than the photos' 3.7 m storey
guess, which gives a roof ~6 m lower than the survey.

## 3. Facade

- Ground floor: shop glass (#28303a, M_GLASS) 1.8 m behind the line; granite piers 1 x 1 m every
  7.2 m along the avenue wing's walls (the avenue, Krucza and the east end), 0.55 m in; a pale soffit.
- Upper: one band of glass (#2e4660, M_GLASS: mullions every 1.5 m, a transom every 4 m), the 7.2 m
  bays marked by bronze mullions (#4a4742, 0.3 m wide, 8 cm proud) over the piers.
- Slabs: cream (#e6dfcf) 0.52 m tall, 0.35 m proud, with a top and a shaded underside.
- Cornice: cream band 1.5 m.

## 4. Roof

Grey flat roof (#6a6f76) inside the cornice; the pavilion (dark glass #2a3340) with its cream roof
plate (#d9d4c8); at each end the plate rises 2.75 m over 6.5 m beyond the plate (the "ski-jump"
wings), dark undersides (#3a3a3a) and a cream tip edge. Four round hoods (r 0.9 m) on the avenue
wing's inner edge and a field of six fans on the north wing (from the orthophoto).

## 5. Colour and material

Slabs and cornice #e6dfcf (shade #cfc8b8), M_STONE; glass #2e4660 and shop glass #28303a, M_GLASS;
frames #4a4742; granite #b9b2a4; roof #6a6f76; pavilion #2a3340 (M_GLASS); plate #d9d4c8; loop
#3a5c9e in M_LAMP (steel blue by day; the photos' patina green-grey #6f8478 by day and #2d5bff at
night cannot both come from one colour, so the blue was kept).

## 6. Ground and night

The pavement, trees, tram stop and crossing are the map's. Night (photo 6): the loop glows blue;
the glass storeys take the city's lit-window glow, shops lit on the ground floor (M_GLASS). The
cornice and pavilion stay dark. Car collision on the OSM outline.

## 7. Detail level and budget

L3 (the start area's south, the crossing the player sees first), 1894 triangles, budget 2300
(check_mesh_quality BUDGET "cedet"). No new material, node or draw call. Shots: the front
(`--at=-482,322 --yaw=20 --lift=10`), the Krucza corner (`--at=-515,330 --yaw=315`), night, solo.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| shop | prism | ring - 1.8 m, 7.1 m tall | ground floor | M_GLASS #28303a | 4 open ground floor |
| soffit | strip | 1.8 m wide | 6.5 m, facing down | M_STONE #cfc8b8 | 4 overhang |
| piers | prisms | 1 x 1 x 7.1 m, every 7.2 m | avenue wing's walls, 0.55 m in | M_STONE #b9b2a4 | 4 granite piers |
| glass | prism | ring, 23 m tall | 6.5 to 29.5 m | M_GLASS #2e4660 | 1 ribbon glass |
| mullions | quads | 0.3 m wide, 23 m tall | over each pier | #4a4742 | 1 bronze frames |
| slabs | prisms + strips | ring + 0.35 m, 0.52 m tall, 5 | every storey | M_STONE #e6dfcf | 1 cream slabs |
| corners | arcs | r 5 m and 4 m, 6 pieces | Krucza corner, east end | (the ring) | 2 rounded corners |
| cornice | prism | ring + 0.25 m, 1.5 m tall | 29.5 m | M_STONE #e6dfcf, roof #6a6f76 | 3 cornice |
| pavilion | box | 40 x 19 x 4 m | u -20..20, v -24..-5 | M_GLASS #2a3340 | 3 crown pavilion |
| plate | box | 44 x 23 x 0.45 m | over the pavilion | M_STONE #d9d4c8 | 3 roof plate |
| wings | quads | 6.5 x 23 m, rising 2.75 m | u ±22..±28.5 | M_STONE #d9d4c8, under #3a3a3a | 3 swept wings |
| hoods | cylinders | r 0.9 m, 1.2 m, 4 | u -8..10, v -26 | M_STONE #9a9ea4 | roof plant |
| fans | cylinders | r 1 m, 0.8 m, 6 | north wing | M_STONE #8e9298 | roof plant |
| loop | beams | 0.35 m tube, 3 coils 35 m across, arrow | front, u 4, v 2.3-3.4, 14.5-23.5 m | M_LAMP #3a5c9e | 5 loop and arrow |
