# Złota 44: spec

Site key `zlota44` in `game/scripts/landmarks.gd` (TOWERS row `zlota44`, `_build_tower`,
`_zlota_sail`, `_zlota_point`, `_zlota_flare`, `_zlota_garden`; facade skin `S_SAIL` in
`building.gdshader`). Rebuilt 2026-11-02 in a cloud thread from F's two photos (the street view
from the east, by the curved Lumen block; the aerial from the Palace, looking south-west) and the
OpenStreetMap plan and parts in `centrum.json`. Facts: 192 m, 52-54 storeys, Daniel Libeskind,
the "sail" (Żagiel); cladding about 60 % silver aluminium cassettes and 40 % glass (Greisch's
project sheet). No terrain or LoD2 heights were needed: the tower is built from its own numbers.
Values marked *(photo check)* have not been compared on the Mac.

## 1. Identity

1. **The wing**: the south-east corner leans out as the tower climbs, a long concave curve that
   ends in an overhang at the top; at the foot a thin glass wedge, a waist in between.
2. **The tip**: the roof is cut on one slope, so the south-east corner ends in a sharp point,
   the highest thing on the tower.
3. **The crown box**: a darker glazed screen on the north and west part of the roof, nearly as
   high as the tip, set back from the east face.
4. **The white facade**: silver-white cladding in floor bands, the glass between them broken and
   staggered, so the tower reads white with fine grey stripes, never as blue glass.
5. **The podium garden**: a low block in front of the east face with lawn and trees on its roof.

## 2. Massing

World plan (x east, z south). The mapped core: NE (-1469.5, 291.8), SE (-1462.1, 325.6),
SW (-1488.5, 334.8), NW (-1501.1, 298.5), about 30 x 37 m.

| Volume | Plan | Heights | Source |
| --- | --- | --- | --- |
| Shaft | the core, east face bowed out 2.5 m, SW and NW corners rounded (r 4 m), lofted through 14 rings | ground to the roof slope | OSM core and the east "192 m" part (the curve) |
| Wing | the SE corner pushed out along (east normal + 0.4 south normal): 2.6 m at the foot, 0 at 64 m, then 9 m x ((h - 64) / 128)^1.7 | 0 to 192 m | photo 2 (left edge), OSM 99 m and 192 m skin parts |
| Roof slope | one plane from the tip (SE corner at the top) down to the north face's middle | 192 m to 150 m | photo 2: the east face's top falls about 35 m |
| Crown box | the roof plan from 45 % of the slope on, 4.5 m back from the east face | from the slope to 184 m | photos 1 and 2 *(photo check: height, extent)* |
| Podium | the mapped low parts (32 m east, 28 m north) | as mapped | OSM parts |

## 3. Facade, base to top

- **Base**: the podium's mapped parts in the same banded skin; the tower runs to the ground on
  the south and west.
- **Shaft**: floors every 3.55 m; per floor a white cassette band (half the floor) and a glass
  slot; each 4.5 m panel picks a tall pane (25 %), the usual slot or a solid panel (14 %), so the
  bands stagger; white mullions every 1.5 m (S_SAIL).
- **Top**: the slope cut with no parapet; the crown box above it in dark glass with fins every
  2.4 m (S_FINS).

## 4. Roof

The sloped roof is glazed in the tower's glass (lighter towards the roof grey); the crown box has
a flat top in a darker blue-grey. No orthophoto in the cloud (Geoportal is blocked), and towers
lean in it anyway, so the plan is OSM's. Aviation lights: three on the crown box, one on the tip.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Shaft glass | #bccdd8 | M_SKIN + S_SAIL (cassettes white 0.93) |
| Sloped roof | glass lerped 30 % to #e4e8ea | M_SKIN |
| Crown box | #58788c | M_SKIN + S_FINS |
| Crown top | #58788c lerped 60 % to #e4e8ea | M_STONE |
| Garden | deck, beds, trees as Varso's terraces | M_STONE, M_PAVILION rail |

## 6. Ground and night

The tower stands on the lowest ground under its plan (the site's `g`). At night the apartments
light floor by floor (the skin's lit windows), the crown box stays dark glass, red lights on the
crown and the tip. The garden is lit only by the city's light.

## 7. Detail level and budget

L3 (skyline tower in the hero view from the Palace), triangle budget 1800: the shaft 14 rings x
22 sides (about 570), the slope 40, the crown box 40, lights 50, the podium parts and the garden
about 700. No new materials and no new draw calls (one building mesh).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| shaft | lofted rings, 14 | 30 x 37 x 192 | the mapped core | M_SKIN S_SAIL | the white banded tower |
| wing | the SE corner's offset in every ring | 9 m out at the top | SE corner | M_SKIN S_SAIL | the flaring wing |
| slope | one planar cap | 40 x 37 | the top ring | M_SKIN | the sharp tip |
| crown | prism from the slope | about 25 x 30 x 4-34 | north and west of the roof | M_SKIN S_FINS | the crown box |
| lights | five 0.7 m boxes | 0.7 x 0.7 x 0.9 | crown corners and the tip | M_LAMP | night |
| garden | deck, rail, beds, trees, benches | the podium roofs less the tower | the 28-32 m podium | M_STONE | the podium garden |
