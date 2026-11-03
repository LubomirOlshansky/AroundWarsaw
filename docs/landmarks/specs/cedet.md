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
diagonal face on Bracka, to v -67). Corners rounded: Krucza x Jerozolimskie r 11 m (F's look check,
2026-11-03: 10-12 m; OSM and LoD2 barely round it), the east end r 4 m (softened in the front photo,
its radius unclear).

| Part | Where (local) | Heights above ground |
| --- | --- | --- |
| Ground floor | the ring moved 1.8 m in (shop glass), piers on the line | -0.6 to 6.7 m |
| Glass storeys | the ring | 6.7 to 25.2 m (five storeys of 3.7 m) |
| Floor slabs | the ring moved 0.35 m out | 0.52 m at 6.7, 10.4, 14.1, 17.8, 21.5 m |
| Cornice | the ring moved 0.25 m out | 25.2 to 26.7 m, the roof deck at 26.7 m |
| Pavilion (recessed) | u -17..17, v -25.6..-0.6 | 26.7 to 29.6 m |
| Roof plate | u -19..19, v -27.4..1.2 (2 m over the glass) | 29.6 to 30.05 m |
| Wings | u ±19..±30, the plate's full depth | curving up 2.4 m to ~32.5 m at the tips |
| Plant screen | u -14..14, v -26.2..-19 | on the plate, to 35.0 m |

Heights from LoD2 read again on 2026-11-03 (ground ~10.4): the eave all round is at 26.7 m, the roof
storey at 29-30 m, the wings rise from 30.6 m at u ±20 to 31.5 m at u ±28 with their tips at u ±30,
and a box at the back of the pavilion reaches 35.5 m. The first build read the wings' 31 m as the
main roof and stretched the storeys to 4.6 m; F's 3.7 m storeys (look check) over a 6.7 m ground
floor meet the 26.7 m eave exactly.

## 3. Facade

- Ground floor: shop glass (#28303a, M_GLASS) 1.8 m behind the line; granite piers 1 x 1 m every
  7.2 m along the avenue wing's walls (the avenue, Krucza and the east end), 0.55 m in; a pale soffit.
- Upper: one band of glass (#2e4660, M_GLASS: mullions every 1.5 m, a transom every 4 m), the 7.2 m
  bays marked by bronze mullions (#4a4742, 0.3 m wide, 8 cm proud) over the piers.
- Slabs: cream (#e6dfcf) 0.52 m tall, 0.35 m proud, with a top and a shaded underside.
- Cornice: cream band 1.5 m.

## 4. Roof

Grey flat roof deck (#6a6f76) inside the cornice. The pavilion (dark glass #2a3340) is recessed 2 m
under its cream roof plate (#d9d4c8), whose soffit is in shade (#2f3033). At each end the plate
sweeps up into a wing (F, 2026-11-03: "restore the two upswept roof wings and their underside
shadows first"): 11 m long, flat at first then steeper (rise 2.4 m, t^1.7, four pieces), open
underneath, with a dark underside (#2f3033), shaded long edges and a cream tip edge; under each wing
a shadow (#3e4248) on the roof deck, shifted 1 m north. A light grey plant screen (#a9adb0) at the
back of the pavilion (LoD2's box), and six fans on the north wing (from the orthophoto).

## 5. Colour and material

Slabs and cornice #e6dfcf (shade #cfc8b8), M_STONE; glass #2e4660 and shop glass #28303a, M_GLASS;
frames #4a4742; granite #b9b2a4; roof #6a6f76; pavilion #2a3340 (M_GLASS); plate #d9d4c8; loop
#7a7264, muted metallic grey-bronze by day (F's look check, 2026-11-03), in M_LAMP + 0.5: the
shader's neon variant keeps the tube's own colour by day and glows blue (0.17, 0.34, 1.0) at night,
as photo 6 shows.

## 6. Ground and night

The pavement, trees, tram stop and crossing are the map's. Night (photo 6): the loop glows blue;
the glass storeys take the city's lit-window glow, shops lit on the ground floor (M_GLASS). The
cornice and pavilion stay dark. Car collision on the OSM outline, with the Krucza corner cut to the
model's 11 m curve (the car reaches the glass there).

## 7. Detail level and budget

L3 (the start area's south, the crossing the player sees first), 1862 triangles, budget 2300
(check_mesh_quality BUDGET "cedet"). No new material, node or draw call. Shots: the front
(`--at=-482,322 --yaw=20 --lift=10`), the Krucza corner (`--at=-515,330 --yaw=315`), night, solo.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| shop | prism | ring - 1.8 m, 7.1 m tall | ground floor | M_GLASS #28303a | 4 open ground floor |
| soffit | strip | 1.8 m wide | 6.5 m, facing down | M_STONE #cfc8b8 | 4 overhang |
| piers | prisms | 1 x 1 x 7.1 m, every 7.2 m | avenue wing's walls, 0.55 m in | M_STONE #b9b2a4 | 4 granite piers |
| glass | prism | ring, 18.5 m tall | 6.7 to 25.2 m | M_GLASS #2e4660 | 1 ribbon glass |
| mullions | quads | 0.3 m wide, 18.5 m tall | over each pier | #4a4742 | 1 bronze frames |
| slabs | prisms + strips | ring + 0.35 m, 0.52 m tall, 5 | every 3.7 m storey | M_STONE #e6dfcf | 1 cream slabs |
| corners | arcs | r 11 m and 4 m, 6 pieces | Krucza corner, east end | (the ring) | 2 rounded corners |
| cornice | prism | ring + 0.25 m, 1.5 m tall | 25.2 m | M_STONE #e6dfcf, roof #6a6f76 | 3 cornice |
| pavilion | prism | 34 x 25 x 2.9 m | u -17..17, v -25.6..-0.6 | M_GLASS #2a3340 | 3 recessed pavilion |
| plate | prism + soffit | 38 x 28.6 x 0.45 m | over the pavilion, 2 m beyond its glass | M_STONE #d9d4c8, soffit #2f3033 | 3 roof plate |
| wings | quads, 4 pieces each | 11 x 28.6 m, curving up 2.4 m | u ±19..±30 | M_STONE #d9d4c8, under #2f3033 | 3 upswept wings |
| wing shadows | quads | 11 x 27.4 m | the roof deck under each wing, 1 m north | M_STONE #3e4248 | 3 underside shadows |
| plant screen | box | 28 x 7.2 m, to 35 m | u -14..14, v -26.2..-19, on the plate | M_STONE #a9adb0 | roof plant |
| fans | cylinders | r 1 m, 0.8 m, 6 | north wing | M_STONE #8e9298 | roof plant |
| loop | beams | 0.35 m tube, 3 coils 35 m across, arrow | front, u 4, v 2.3-3.4, 11.3-20.3 m | M_LAMP + 0.5 #7a7264 | 5 loop and arrow |
