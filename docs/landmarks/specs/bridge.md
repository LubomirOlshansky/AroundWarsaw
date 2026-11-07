# The Bridge and Grzybowska 77 (Plac Europejski, by Towarowa): spec

Site keys `bridge` and `grzybowska77` in `game/scripts/landmarks.gd` (`_find_bridge`,
`_build_bridge`, `_br_face`, `_br_lobby`, `_br_sign`; `_build_bellona`, `_g77_windows`,
`_g77_ground`, `_g77_balcony`). Rebuilt 2026-11-06 from F's nine photos (an aerial from over
Towarowa, two street views of the shaft, a render, a dusk view, the atrium lobby during fit-out,
the low block from Towarowa and two of its street front; copies in the project files,
`bridge/photos/`) and the OSM outlines (The Bridge 174 m, the low block "Bellona" 20.8 m). The
tower left the TOWERS table (it was a plain S_FINS box). The bank's real name is never used: the
crown says ERZATZ.

## 1. Identity

1. **The Bridge**: a 174 m blue glass shaft whose faces fold along long diagonal seams into big
   triangular facets (the aerial: one seam from the north top corner down to the base, one from
   the crown's foot down and across, a vertical one in the middle, a crease over the base).
2. **The notched crown**: the south 13 m of the tower stops at 149 m and a dark block (149-168 m)
   stands set in over it, against the north part's glass that runs on to the roof.
3. **ERZATZ** (F: the tower is now the Erste bank's) in blue at the top of the long faces.
4. **The atrium**: a 12 m glazed lobby set back under the shaft, timber soffit and slats, leaning
   concrete columns in V pairs.
5. **Grzybowska 77**: a warm tan brick block of four storeys over a pale stone ground floor of
   square piers, a long balcony with a black rail over Towarowa, stone-framed windows, a stone
   cornice and a set-back pale attic.

## 2. Massing

The Bridge: the mapped outline simplified (1.6 m), about 49 x 35 m, cut across its long axis at
u 30 m (BR_CUT, frame BR_O / BR_U along the west face from its north corner): the north part to
174 m, the south part to 149 m, the dark block 0.9 m in from the south part, 149 to 168 m.
Grzybowska 77: the "Bellona" outline (52 x 25 m), ground floor 5.6 m, a 0.6 m stone band, four
storeys of 3.35 m to the cornice at 19.4 m (0.35 m proud, 0.7 m tall), an attic 2 m in, 3 m tall
(about 23 m in all; OSM says 20.8 m, the photos show the attic over the cornice).

## 3. Facade, base to top

- The Bridge, 12 m to the top: glass #5a7d9c (M_SKIN S_FINS: mullions and floor lines, lit rooms
  at night) in facets; each facet a step lighter or darker (up to 13 %) and its normal turned up
  to 15 degrees, so the folds catch the light. Seams: 0.5 m dark beams #1e252c, 0.1-0.35 m proud (each seam and leg a step prouder),
  along the folds (BR_FOLDS_LONG on the long faces, BR_FOLDS_SHORT on the ends).
- The Bridge, 0 to 12 m: warm glass #9a8c76 (M_PAVILION, lit at night) 1.6 m in, timber soffit
  #b0824e, concrete columns #5e6266 0.8 m square leaning 2.2 m each way every 9 m.
- Grzybowska 77: stone piers #d9d2c3 0.9 m wide, 0.4 m proud every 3.3 m; between them dark
  glazing #4a5560 over brown spandrels #7a5038; brick #b08a6a above; each storey a 1.4 x 1.85 m
  pane (M_GLASS, lit at night) in a 1.9 m stone frame, one per 3.3 m bay; none on the wall it
  shares with the tower.

## 4. Roof

The Bridge: flat roof #646b70 at 174 m with a 6 m plant box; the 149 m ledge round the dark
crown block (#24282c, M_SKIN S_DARK); three red aviation lights. Grzybowska 77: the cornice's
flat top, a 0.9 m stone parapet, the attic's roof and two plant boxes.

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Tower glass | #5a7d9c and facet shades | M_SKIN S_FINS |
| Seams | #1e252c | M_STONE |
| Crown block | #24282c | M_SKIN S_DARK |
| Lobby glass | #9a8c76 | M_PAVILION |
| Soffit | #b0824e | M_STONE |
| Columns | #5e6266 | M_STONE |
| ERZATZ | blue neon (0.2, 0.55, 1) | neon word |
| G77 brick | #b08a6a | M_STONE |
| G77 stone | #d9d2c3 | M_STONE |
| G77 panes | #4a5560 | M_GLASS |

## 6. Ground and night

Both stand on their mapped outlines, ground from `_ground_under`; the car's walls on the mapped
outlines (`_collide`, also handed to `pocket_rings`, so the slit between the two stays bridged).
At night the shaft's skin and the block's panes show lit rooms, the lobby glows warm, ERZATZ is
a blue neon word, the roof carries red aviation lights. Shots: `--at=-2830,125 --yaw=270
--lift=95 --size=280` (F's aerial), the low block `--at=-2815,110 --yaw=270 --lift=10 --size=60`.

## 7. Detail level and budget

L3, triangle budget 2700 for both buildings (check_mesh_quality: `bridge` 700, about 550 measured
for the facets, seams, lobby and crown; `grzybowska77` 2000, about 1650 measured for the piers,
windows and rail), one landmark mesh, no new draw call.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| facets | faces split along seams | 12-174 m | the outline's faces | M_SKIN S_FINS | 1 shaft |
| seams | beams | 0.5 m | on the folds | M_STONE | 1 shaft |
| step face | wall | 149-174 m | north part at u 30 | M_SKIN S_FINS | 2 crown |
| crown | inset prism | 149-168 m | south part, 0.9 m in | M_SKIN S_DARK | 2 crown |
| sign | neon word | 62 % of the face | long faces, 4 m under the roof | neon | 3 sign |
| lobby | inset prism | 0-12 m, 1.6 m in | under the shaft | M_PAVILION | 4 atrium |
| soffit | down-facing cap | outline | 12 m | M_STONE | 4 atrium |
| columns | leaning beams | 0.8 m, every 9 m | faces, 0.8 m in | M_STONE | 4 atrium |
| g77 piers | prisms | 0.9 x 0.4 x 5.6 m | every 3.3 m | M_STONE | 5 block |
| g77 windows | frame + pane | 1.9 / 1.4 m wide | 4 storeys, 3.3 m bays | M_STONE, M_GLASS | 5 block |
| g77 balcony | slab + rail | 1.1 m deep | longest street face, 6.2 m | M_STONE | 5 block |
| g77 attic | inset prism | 3 m, 2 m in | over the cornice | M_STONE | 5 block |
