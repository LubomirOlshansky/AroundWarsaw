# The 1960s slabs behind Junior (unnamed): spec

Site key `slabs` in `game/scripts/landmarks.gd` (`_find_behind`, `_build_slabs`,
`_roof_frame`). Written 2026-11-01 from the Mac photo check of the start area (spec D; main
ed7e873, start spot `--at=-961.6,95.0 --heading=339.8`) and the four OpenStreetMap outlines
(apartments, h 37.3 m) at (-862, 86), (-853, 190), (-813, 207) and (-778, 308) in
`centrum.json`. Left unnamed: no card, not on the picking grid.

## 1. Identity

1960s residential slabs of the Eastern Wall's second line, behind the stores. What makes them
read:

1. **Long pale cream-ochre slabs**, 12-13 storeys, plain ochre end walls.
2. **Continuous loggia bands** on the long faces: a light balustrade line every floor over dark
   recesses with windows.
3. **Flat roofs with lift and stair houses**.
4. **A big rooftop billboard** on the slab behind Sawa.

## 2. Massing

| Volume | Plan | Heights above ground |
| --- | --- | --- |
| Slab | each outline (simplified at 0.6 m) | -0.4 to 37.3 m |
| Lift and stair houses | two 6 x 4.4 m boxes on the long axis at ±45 % of the length | 37.3 to 40.5 m |
| Billboard (slab 2, behind Sawa) | the edge facing south-south-east, 4.5 m in, up to 25 m wide | 37.3 to 42.8 m |

The zone is each outline grown 3 m (the LoD2 models stand a little off them).

## 3. Facade, base to top

- **Long faces** (edges over half the longest): new skin S_SLAB: plaster #d8c9a6, floors of
  2.85 m; each floor a light balustrade band (the lower third, #e6e0d4), then the loggia recess
  (the plaster darkened) with a window in each 3.6 m bay between thin piers; the ground floor and
  the top 0.6 m plain plaster.
- **End walls**: plain ochre #c9a96a (M_STONE).

## 4. Roof

Flat, #8c8a84; two lift and stair houses in plaster with roofs #7d7b75. On the slab behind
Sawa a steel frame (posts every ~8 m, two rails) with a dark blue panel and ORANZADA (a generic
drink, not a brand) in orange, lit day and night, 5.5 m tall.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Long faces | #d8c9a6 | M_SKIN + S_SLAB / 16 |
| End walls | #c9a96a | M_STONE |
| Roof | #8c8a84 | M_STONE |
| Lift and stair houses | #cdbd9b, roof #7d7b75 | M_STONE |
| Billboard frame, panel | #5b6166, #1d3d6b | M_STONE |
| Billboard word | orange (1.0, 0.62, 0.15) | neon atlas (LandmarkSigns) |

No new material: the building surface (+0 draw calls) and the signs' MultiMesh (+0).

## 6. Ground and night

The car stops at each outline. At night about 45 % of the windows glow warm, about 10 % of
the loggias glow faintly (lit balconies), the billboard stays lit.

## 7. Detail level and budget

L1 (massing, colour and the loggia rhythm in the shader), triangle budget 270 (225 measured on
2026-11-01, `check_mesh_quality.gd` BUDGET).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| long | walls along the long edges | 37.7 m tall | each slab | M_SKIN S_SLAB #d8c9a6 | 1 slabs, 2 loggias |
| ends | walls along the short edges | 37.7 m tall | each slab | M_STONE #c9a96a | 1 slabs |
| roof | cap of the outline | each slab | y 37.3 | M_STONE #8c8a84 | 3 roof |
| houses | two boxes | 6 x 4.4 x 3.2 m | the long axis, ±45 % | M_STONE #cdbd9b | 3 roof |
| billboard | posts, rails, panel, word | up to 25 x 5.5 m | slab 2, south-south-east edge | M_STONE #1d3d6b, neon atlas | 4 billboard |
