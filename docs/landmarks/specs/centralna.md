# Warszawa Centralna: spec

Site key `centralna` in `game/scripts/landmarks.gd` (`_find_centralna`, `_build_centralna`,
`_centralna_shells`, `_tier_ends`). Written 2026-10-31 in a cloud thread from the
OpenStreetMap parts in `centrum.json` (the station is mapped in 3D: the hall, the wings and
their roof boxes, the vestibules, 28 pillars and the roof in two tiers, all with heights) and
the earlier shell-roof model. The reference photos in `refs/` live on the Mac and were not
reachable from the cloud: the values marked *(photo check)* are the ones the side-by-side
check on the Mac should confirm or move.

## 1. Identity

Arseniusz Romanowicz's and Piotr Szymaniak's main station (opened 1975) on Al. Jerozolimskie,
between Złote Tarasy and the Marriott. What makes a passer-by say its name:

1. **The glass box**: the main hall, 71 x 51 m of glass from the pavement to the roof, lit
   from inside at night.
2. **The flat overhanging roof**: one thin white-edged slab, 140 x 86 m, far wider than the
   hall, overhanging both long sides by about 15 m and carried past the hall's ends on
   pillars.
3. **The hyperbolic paraboloid shells**: between the pillars' heads and the slab, the roof's
   shells, which are the station's face from either end (photo-checked on the Mac 2026-11-01,
   refs/centralna 1-2): under the straight top edge the underside sweeps down like wings from
   the long edges to the pillar rows and rises between them in a shallow arch over the hall.
4. **The night glow**: the hall's glass glowing cool white floor by floor, the lower wings
   warm, a line of lamps along the slab's edge.

## 2. Massing

Local plan: the frame `CENTRALNA` (-1420, 572.5) turned -19.4 degrees, u along Al.
Jerozolimskie (ENE), v across it (towards the tracks' south side). Heights above the site's
ground (the lowest terrain under the roof). All from the mapped parts inside the 146 x 92 m
zone.

| Volume | Plan (u, v) | Heights | Source |
| --- | --- | --- | --- |
| Glass hall | 49-point outline, u -37.4..33.6, v -25.1..26.0 | 0 to 16.5 m (mapped 3.3 to 15 on a 0 to 3.3 storey; carried up to meet the slab) | OSM part h 15, mh 3.3 + the 87-point storey h 3.3 |
| West wing | u -57.5..-37.2, v -25.4..25.8 | 0 to 11.5 m | OSM part #BCBAAB h 11.5 |
| East wing | u 33.3..59.0, v -28.7..30.4 | 0 to 11.5 m | OSM part #BCBAAB h 11.5 |
| Wing roof boxes | 9 x 31 m on each wing | 11.5 to 15 m | OSM parts h 15, mh 11.5 |
| Vestibules | 10 x 1.2 m boxes on the hall's long walls | 0 to 3.3 m | OSM parts dimgray h 3.3 |
| Pillars | 28, 1.1 m square, rows v -20.5 and 21.2, u -65.4 to 64.6 every 10 m | 0 to 12.3 m (into the shells) | OSM parts h 15; photo 1 puts the heads at about 12 m |
| Shells (underside) | across the whole slab: v -42.8..43.6, to the slab's bowed ends | 16 m at the long edges, 12 m at the pillar rows, 14.2 m at the arch's crown | photo 1 (the end view); OSM's shell tier (15 to 16.5 m) is not used |
| Slab | 28-point outline, u -70..70, v -42.8..43.6 | fascia 16 to 18 m | OSM roof part h 18, mh 16.5 |

## 3. Facade, base to top

- **Hall (0-16.5 m)**: glass curtain wall, mullions every 1.6 m, a line every 4.2 m (M_PAVILION
  +0.5): lit cool white bay by bay at night *(photo check: the mullion rhythm, warm or cool)*.
- **Wings (0-11.5 m)**: grey-blue glass in a light concrete grid (skin S_GRID) *(photo check:
  what the wings' walls really are)*.
- **Wing roof boxes (11.5-15 m)**: plain light concrete, mapped #BCBAAB.
- **Vestibules (0-3.3 m)**: dark glass boxes at the hall's doors.
- **Pillars**: plain light concrete; only the ones beyond the hall and the wings (the ends) are
  built.
- **Shells' end faces**: grey (#b9b7b0) from the underside's curve up to the fascia's foot at
  16 m, at both ends (the winged shape).
- **Slab edge (16-18 m)**: straight, white, with small warm lamps every ~5 m, 0.6 m under
  its top (the dusk loop's lamps, kept).

## 4. Roof

The shells, as the end views show them: one curved underside across the whole slab, falling
from the long edges (16 m, the wing tips 2 m thick) to the pillar rows (12 m) like a wing
(power 0.8) and rising between the rows in a parabola to 14.2 m over the hall; 6 pieces a half
bay, straight along u to the slab's bowed ends, lit at night. The hypar saddles along u (the
pillars every 10 m) are left out: from outside only the end profile reads.
The slab: flat at 18 m, the mapped roof colour #638898 in a faint checker of 10 m panels
over the shells' bays.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Hall glass | #7f9fb2 | M_PAVILION +0.5 (cool at night) |
| Wings | glass #8d9aa2, roof #9c9a90 | M_SKIN S_GRID, M_STONE |
| Wing roof boxes | #bcbaab, roof #9c9a90 | M_STONE |
| Vestibules | #3f4c55 | M_GLASS, top M_STONE |
| Pillars | #bdb8ad | M_STONE |
| Shells' underside | #9a968c | M_LAMP (lit at night) |
| Slab edge | #e4e2dc (mapped white) | M_STONE |
| Shells' end faces | #b9b7b0 | M_STONE |
| Slab top | #638898 (mapped), panels 3 % darker | M_STONE |
| Lamps | warm white | M_LAMP |

No new material, no draw call of its own: everything goes into the city's building surface.

## 6. Ground and night

The forecourts under the slab and the pavements stay the map's. The car collides with the
hall, the wings, the vestibules and the end pillars (`tools/check_roads.py` mirrors these).
At night the hall glows cool white through its glass, the wings warm, the lamps line the
slab's edge, and the shells' underside is lit (seen only from below). Card: "Warszawa
Centralna", PL "Dworzec otwarty w 1975 roku: szklana hala pod płaskim, wysuniętym dachem na
paraboloidach hiperbolicznych.", EN "The main station, opened in 1975: a glass hall under a
flat overhanging roof on hyperbolic paraboloid shells."

## 7. Detail level and budget

L2 (a named landmark on the first scene's edge), triangle budget 1650 (1370 measured after the
build, plus about 20 %, in `check_mesh_quality.gd` BUDGET; 990 after the Mac photo check, the
shells 48 and their end faces 92 of them, the lamps about 180). Shots: `--solo=centralna --solo-look=sil` and `flat` (the `first` set),
then in the city at day and night from Al. Jerozolimskie.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| hall | mapped prism | 71 x 51 m, 0-16.5 m | centre of the site | M_PAVILION +0.5 #7f9fb2 | 1 glass box |
| wings | 2 mapped prisms | 20 x 51 and 26 x 59 m, 0-11.5 m | either end of the hall | M_SKIN S_GRID #8d9aa2 | 4 night glow |
| boxes | 2 mapped prisms | 9 x 31 m, 11.5-15 m | on the wings | M_STONE #bcbaab | 1 glass box |
| vestibules | mapped prisms | 10 x 1.2 m, 0-3.3 m | the hall's long walls | M_GLASS #3f4c55 | 1 glass box |
| pillars | mapped boxes | 1.1 m, 0-12.3 m | the ends, u ±65 | M_STONE #bdb8ad | 2 overhanging roof |
| shells | curved underside, 24 strips | 140 x 86 m, 12-16 m | under the slab | M_LAMP #9a968c | 3 shells |
| ends | profile faces | from the curve to 16 m | both ends | M_STONE #b9b7b0 | 3 shells |
| slab | mapped prism, panel checker | 140 x 86 m, 16-18 m | over everything | M_STONE #e4e2dc, top #638898 | 2 overhanging roof |
| lamps | 0.8 m quads every 5 m | 0.6 m under the top | the slab's edge | M_LAMP warm | 4 night glow |
