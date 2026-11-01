# Centrum Nauki Kopernik: spec

Site key `kopernik` in `game/scripts/landmarks.gd` (`_find_kopernik`, `_build_kopernik`,
`_kop_windows`, `_kop_roof`, `_kop_planet`). Written 2026-11-01 in a cloud thread from the
OpenStreetMap outlines and parts in `centrum.json` (the centre, the planetarium, the low wings
and the overhanging corner, mapped from 3.3 m) and GUGiK's LoD2 roof (a flat roof 13 m over the
street, 0.3 m steps at most). The reference photos in `refs/` live on the Mac and were not
reachable from the cloud: the values marked *(photo check)* are the ones the side-by-side check
on the Mac should confirm or move. Until now the centre was a skin (LoD2's massing in dark grey
with a green roof) and the planetarium a plain OSM box.

## 1. Identity

The Copernicus Science Centre (RAr-2, opened 5 November 2010) on Wybrzeże Kościuszkowskie, over
the Wisłostrada tunnel, and its planetarium (June 2011) on the river side. What makes a
passer-by say its name:

1. **The long dark block**: one low box the length of a city block (140 m), dark grey-brown
   panels with windows scattered over them like pixels *(photo check: the panels' pattern and
   colour, how many windows)*.
2. **The roof garden**: the whole roof is a garden, lawns between paved paths, seen from the
   bridge and the heli.
3. **The overhang on the river corner**: the corner by the boulevard hangs over a glazed ground
   floor (OSM maps it from 3.3 m) *(photo check: its depth and height)*.
4. **The black planetarium**: a faceted black boulder beside the block, lower than its roof
   *(photo check: its height and facets)*.
5. **At night**: the windows lit warm in the dark panels, the glass wings and the ground floor
   under the overhang glowing.

## 2. Massing

World plan (x east, z south), heights over the street on the city side (the highest ground
under the outline, about -12.6 m; the river side lies 4 m lower, so the walls there are taller).

| Volume | Plan | Heights | Source |
| --- | --- | --- | --- |
| Block | the outline less the low wings, straightened 0.8 m: x 259..379, z -950..-786 | ground to 13 m | OSM outline, LoD2 roof (OSM says 7.6 m) |
| Overhanging corner | OSM part x 325..369, z -950..-904 (the river corner) | soffit 5 m over its own ground, to 13 m | OSM part h 7.6, mh 3.3 |
| West wing | OSM part x 253..272, z -906..-888 (the city corner) | ground to 4.5 m | OSM part h 4.3; LoD2 4-6 m |
| Link to the planetarium | OSM part x 329..363, z -904..-874 | ground to 4.5 m over the street | OSM part h 4.3 |
| Planetarium | its outline (convex), x 347..391, z -904..-866 | walls to 6.5 m, facets to 8.3-9.9 m, apex 11.5 m over its own ground | OSM outline h 7.6 *(photo check: height)* |

## 3. Facade, base to top

- **Block walls**: plain dark panels (M_STONE) from the ground (below the terrain) to the roof.
- **Windows ("pixels")**: rows every 2.6 m from 1.4 m over the local ground to 1 m under the
  roof, panes 1.6 m tall and 2, 4 or 6 m wide on a 2 m grid, about four in ten slots filled by a
  steady hash per front and row (so no front repeats), 7 cm proud of the wall, dark glass by day
  and lit warm at night (M_PAVILION).
- **Under the overhang**: the ground floor's glass wall (M_PAVILION, lit) on the line where the
  overhang starts, from the ground to the soffit; the soffit itself dark grey.
- **Low wings**: glass all round (M_PAVILION) to 4.5 m, a paved roof.
- **Parapet**: 0.9 m round the roof, a darker band of the panels.

## 4. Roof

Flat at 13 m, paved (the paths' colour). The garden: the roof inset 3 m, cut by one path along
the block (3.2 m wide, along x 0.62, z 0.78, through the roof's centre) and four across it
(2.8 m, at -44, -14, 14 and 40 m along); every bed is a raised lawn 0.45 m high with a kerb, in
two greens in turn *(photo check: the real garden's paths, the trees on it)*. No skylights or
roof houses are mapped. The planetarium's top: from its walls' head, facets lean in to a ring
45 % of the way to the centre at 8.3-9.9 m, then to one apex 3 m east and 2 m north of the
centre, at 11.5 m.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Block panels | #5f5a54 (the old skin's) | M_STONE |
| Parapet, soffit | #57524c | M_STONE |
| Windows | #3b4347 | M_PAVILION (lit warm at night) |
| Glass wings, ground floor under the overhang | #8fa3a8 | M_PAVILION |
| Roof paths, wing roofs | #a49e92 | M_STONE |
| Bed kerbs | #7d786e | M_STONE |
| Lawns | #6f9a4c and #87a659 | M_STONE |
| Planetarium walls | #24272b | M_STONE |
| Planetarium facets | #30343a, each a little lighter or darker | M_STONE |

No new material, no draw call of its own: everything goes into the city's building surface.
The far skyline proxy takes the panels' colour (`tower_colour`).

## 6. Ground and night

The squares, the boulevard, the tunnel and the ramps round it stay the map's (check_roads C5
allows the Wisłostrada tunnel's portal and the garden's ramps inside the site). The car collides
with the centre's whole outline and the planetarium's (`tools/check_roads.py` mirrors these).
The dog's ball (`city_life.gd`, egg "Aport") lands on the garden: the roof is the highest flat
spot near the entrance, and the planetarium's top is lower and sloped. At night the pixel
windows glow warm, the glass wings and the ground floor under the overhang glow, the planetarium
stays black. Card: "Centrum Nauki Kopernik", PL "Otwarte w 2010 roku. Na dachu ogród, obok
czarne planetarium.", EN "Opened in 2010. A garden on the roof, the black planetarium beside it."

## 7. Detail level and budget

L2 (a named landmark on the river, seen from the bridge and the boulevards), triangle budget
560 (467 measured after the build, plus about 20 %, in `check_mesh_quality.gd` BUDGET; the
windows are about 200 of them, the garden about 120). Shots: `--solo=kopernik --solo-look=flat`
and `lit`, then in the city by day and night from the river side.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| block | mapped prism, straightened | 120 x 164 m, 0-13 m | the outline less the wings | M_STONE #5f5a54 | 1 long dark block |
| windows | 7 cm panes on a 2 m grid | 2-6 x 1.6 m, rows every 2.6 m | every front | M_PAVILION #3b4347 | 1 pixels, 5 night |
| overhang | the mapped corner over a soffit | 46 x 45 m, 5-13 m | the river corner | M_STONE #5f5a54, soffit #57524c | 3 overhang |
| ground glass | glass wall | 0-5 m | where the overhang starts | M_PAVILION #8fa3a8 | 3 overhang, 5 night |
| wings | 2 mapped glass prisms | 19 x 18 and 34 x 30 m, 0-4.5 m | the city corner, the link | M_PAVILION #8fa3a8 | 5 night |
| parapet | thin wall | 0.9 m | round the roof | M_STONE #57524c | 1 long dark block |
| garden | raised beds between paths | 0.45 m, 1 path along, 4 across | the roof, inset 3 m | M_STONE #6f9a4c / #87a659 | 2 roof garden |
| planetarium | convex prism, faceted top | 44 x 38 m, walls 6.5 m, apex 11.5 m | its outline | M_STONE #24272b / #30343a | 4 black boulder |
