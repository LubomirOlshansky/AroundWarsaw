# Osiedle Za Żelazną Bramą (Jerzy Skolimowski and team, 1965-72): spec

Site key `zelazna` in `game/scripts/landmarks.gd` (`_find_zelazna`, `_build_zelazna`), skin
`S_ESTATE` in `game/shaders/building.gdshader`. Written 2026-11-01 in a cloud thread from F's ask
("the estate should be modelled, as Hala Mirowska") and the eleven OpenStreetMap outlines in
`centrum.json` (no photo here). Values marked *(photo check)* wait for the Mac's `refs/`.

## 1. Identity

The estate between ul. Żelazna and Aleja Jana Pawła II, built over the ghetto's ruins as one of
the city's big modernist housing schemes. What makes it read:

1. **Long large-panel slabs of 12-15 floors**, pale concrete, in a row from Żelazna eastwards.
2. **Saw-toothed long faces** on the Sienna-side slabs (the outlines step every few metres).
3. **Loggia stacks with coloured parapets** (blue, ochre, brick) running up the facade *(photo
   check: the real colours and whether they stack in bays or run in bands)*.
4. **Blank end walls** with a single stair-window slot.

## 2. Massing

Eleven blocks, each its own OpenStreetMap outline (simplified at 0.6 m) and mapped height above
the ground: five slabs 43.9 m at (-2086, 304), (-2035, 287), (-1979, 271), (-1927, 255) and
(-2046, 349); the high block 60.4 m at (-1996, 322); four slabs 37.3 m at (-1857, 316),
(-1858, 260), (-1844, 218), (-1873, 382); one 40.6 m at (-1843, 377). Lift and stair houses
3 m high on each roof at 40 % of the long axis either side of the centre. Each zone is the
outline grown 3 m (the LoD2 models stand a little off the outlines).

## 3. Facade, base to top

- **Long faces** (edges not across the long axis): skin S_ESTATE, 3 m bays on floors of 2.8 m;
  the ground floor plain and darker, a thin attic band; each floor a ribbon window (the middle
  three quarters of the bay, dark glass), the fourth bay of each four a loggia: a coloured
  parapet (the lower 40 %, blue #456e9e, ochre #c79945 or brick #9e4c3d by stack) over a dark
  recess; panel joints every bay and floor.
- **Entrance** at the middle of each long face of 14 m or more: a dark glazed door 2.6 x 2.4 m
  and a flat grey canopy 4.4 x 1.9 m at 2.7 m.
- **End walls** (normal along the long axis): blank concrete #b9b5aa with a 1 m dark glazed stair
  slot from 3.2 m to 3 m under the roof.

## 4. Roof

Flat, #77777a; two lift and stair houses in the panel colour, roofs #6a6a6d.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Long faces | #d2cfc6, #cbcdc6, #d6cfc0, #c8cbc9 (by block), the high block #bfc4c6 | M_SKIN + S_ESTATE / 16 |
| End walls | #b9b5aa | M_STONE |
| Stair slot, door | #3b4650 | M_GLASS |
| Canopy | #8d8b86 | M_STONE |
| Roof | #77777a | M_STONE |

No new material or draw call (the building surface and the glass already exist).

## 6. Ground and night

The car stops at each outline. At night about 40 % of the ribbon windows glow warm and 18 % of
the loggias glow faintly. Card: "Osiedle Za Żelazną Bramą", PL "Jedenaście bloków z wielkiej
płyty, zaprojektowanych przez Skolimowskiego.", EN "Eleven large-panel blocks of the 1960s-70s,
designed by Jerzy Skolimowski." Open: the estate's low pavilions and the courtyards between the
slabs (the trees and benches are the map's).

## 7. Detail level and budget

L2 (outline, height, facade rhythm in the shader, entrances, stair slots, roof houses), triangle
budget 1500.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| blocks | 11 prisms | outline x 37-60 m | the OSM outlines | M_SKIN | 2 massing, 3 long faces |
| end walls | walls | the short edges | across the long axis | M_STONE | 3 end walls |
| stair slots | strips | 1 m x height - 6 m | middle of each end | M_GLASS | 3 end walls |
| entrances | door + canopy | 2.6 x 2.4 m, 4.4 x 1.9 m | middle of long faces | M_GLASS, M_STONE | 3 entrance |
| roof houses | 22 boxes | 5.6 x 4 x 3 m | the roofs | M_STONE | 4 roof |
