# The 75 m tower behind Sawa and Wars (unnamed): spec

Site key `tower75` in `game/scripts/landmarks.gd` (`_find_behind`, `_build_tower75`,
`_roof_frame`). Written 2026-11-01 from the Mac photo check of the start area (spec C; main
ed7e873, start spot `--at=-961.6,95.0 --heading=339.8`) and the OpenStreetMap outline at
(-819, 254) in `centrum.json` (15 points, 31 x 24 m, h 75 m). Left unnamed: no card, not on
the picking grid.

## 1. Identity

A 1970s point block re-clad in light metal, standing over the Eastern Wall's stores between
Sawa and Wars, seen in the lower part of the frame from the start. What makes it read:

1. **A light grey-white shaft** of horizontal metal cladding among the glass towers.
2. **Punched windows in bands**: a regular grid of small dark windows in white frames.
3. **Big red parody letters** on a steel frame on its roof, lit at night.
4. **A dark glass podium**: two storeys in a square grid under the shaft.

## 2. Massing

| Volume | Plan | Heights above ground |
| --- | --- | --- |
| Podium | the outline (simplified at 0.6 m) | -0.4 to 7 m |
| Shaft | the outline drawn in 1.2 m (the ends read slightly narrower) | 7 to 74.1 m |
| Parapet and roof | the shaft | 74.1 to 75 m |
| Plant room | 6.4 m square at the roof's centre | 75 to 78 m |
| Letters' frame | along the roof edge facing down the street (south-south-east) | 75 to 81 m |

The zone is the outline grown 3 m (the LoD2 model stands a little off it).

## 3. Facade, base to top

- **Podium (0-7 m)**: dark grey-blue glass #3e4e5e in a fine square grid (M_SKIN S_DARK).
- **Shaft (7-74 m)**: new skin S_PUNCHED: light cladding #d9dcdc with a faint horizontal seam
  every 0.74 m; per floor (2.95 m, about 23 storeys) a band of windows 2 x 1.4 m every 3.2 m
  (8-10 a face), white frames, dark glass with a little sky in it. The corners are not kept
  plain (the shader has no distance to a corner) *(photo check)*.
- **Parapet**: a paler band, 0.9 m.

## 4. Roof

Flat, #8b9296, a plant room in the middle. A steel frame (posts every ~8 m, two rails) stands
1.2 m in from the edge facing south-south-east and carries KOKA-KOLKA (a parody) in big red
letters, lit day and night, up to 6 m tall. A small billboard on the next edge round (east): a
blue panel with LODY in white, 3.2 m tall.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Podium glass | #3e4e5e | M_SKIN + S_DARK / 16 |
| Shaft cladding | #d9dcdc, frames white, glass dark | M_SKIN + S_PUNCHED / 16 |
| Parapet | #e2e5e5 | M_STONE |
| Roofs | #8b9296, podium #6e767b | M_STONE |
| Plant room | #b9bdbe | M_STONE |
| Frames | #5b6166 | M_STONE |
| Billboard panel | #2a6fb0 | M_STONE |
| Letters | red (1.0, 0.16, 0.12); LODY white | neon atlas (LandmarkSigns) |

No new material: the building surface (+0 draw calls) and the signs' MultiMesh (+0).

## 6. Ground and night

The car stops at the podium's outline. At night about 42 % of the punched windows glow warm,
the podium shows its lit grid, the red letters and the billboard stay lit.

## 7. Detail level and budget

L2, triangle budget 220 (180 measured on 2026-11-01, `check_mesh_quality.gd` BUDGET).

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| podium | prism of the outline | 31 x 24 m, 7.4 m tall | y -0.4..7 | M_SKIN S_DARK #3e4e5e | 4 podium |
| shaft | prism of the outline drawn in 1.2 m | 67 m tall | y 7..74.1 | M_SKIN S_PUNCHED #d9dcdc | 1 shaft, 2 windows |
| parapet | prism of the shaft, roof | 0.9 m | y 74.1..75 | M_STONE #e2e5e5, roof #8b9296 | 1 shaft |
| plant | box | 6.4 x 6.4 x 3 m | roof centre | M_STONE #b9bdbe | 1 shaft |
| frame | posts and two rails | 90 % of the edge, 6 m tall | south-south-east edge, 1.2 m in | M_STONE #5b6166 | 3 letters |
| letters | neon word KOKA-KOLKA | up to 6 m | on the frame | neon atlas, red | 3 letters |
| billboard | frame, panel, word LODY | 45 % of the edge, 3.2 m tall | east edge | M_STONE #2a6fb0, neon atlas | 3 letters |
