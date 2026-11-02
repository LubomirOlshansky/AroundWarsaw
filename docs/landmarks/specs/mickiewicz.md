# Pomnik Adama Mickiewicza (Mickiewicz's monument): spec

Site key `mickiewicz` in `game/scripts/landmarks.gd` (`_build_mickiewicz`). Written 2026-11-01 in a cloud thread (BACKLOG K2) from the OpenStreetMap outline in `centrum.json`; no photo, no LoD2 here. Values marked *(photo check)* wait for the Mac's `refs/`. The spot is the lawn's centre (the OSM point of Skwer Adama Mickiewicza), *not* confirmed.

## 1. Identity

The 1898 monument by Cyprian Godebski (unveiled 1898, the poet's centenary), in Skwer Mickiewicza at Krakowskie Przedmieście: a bronze poet, his right hand raised, on a tall granite pedestal with bronze plaques, in a ring of lamp posts.

## 2. Massing

Free-standing; frame: origin (-626.6, -1073.6), u along the street (axis (0.259, 0.966), south), +v to the street (west). Three granite steps (6 x 6 m down to 4 x 4 m), plinth 1.2..1.8 m, pedestal 2.3 m square to 5.2 m, cornice to 5.7 m, figure to 8.15 m *(photo check: real height about 4 m of bronze)*.

## 3. Facade

Pedestal faces carry a bronze plaque each (1.4 x 2 m, 2.4..4.4 m up). The figure: a cloaked body (frustum r 0.7 to 0.3 m, 5.7..7.7 m), a head (r 0.17 m) and a raised right arm (a thin box).

## 4. Roof

No roof. Four lamp posts (iron, r 0.1 m, 2.4 m) with pale lantern heads at the steps' corners (3.6 m out).

## 5. Colour and material

| Part | Colour | Material code |
| --- | --- | --- |
| Granite | #8d8a86 | M_STONE |
| Bronze (figure, plaques) | #4a4a42 | M_STONE |
| Posts | #3a3d40 | M_STONE |
| Lantern heads | #f0dfae | M_STONE |

No new material or draw call.

## 6. Ground and night

Car stopped by a ring round the steps. Card: "Pomnik Adama Mickiewicza". The lawn's trees and lamps inside the 5.2 m zone are dropped. Open *(photo check)*: the exact spot on the lawn, the facing, the fence and corner lanterns' real shape.

## 7. Detail level and budget

L2; 282 triangles measured, budget 340 (`check_mesh_quality.gd`).

Shot: `--at=-626.6,-1073.6 --yaw=245 --pitch=-25 --size=22 --nohud --no-ghost`.

## 8. Parts table

| id | shape | size | position | material | feature |
| --- | --- | --- | --- | --- | --- |
| steps | 3 boxes | 6, 5, 4 m square, 0.4 m each | centre, -0.4..0.8 m | M_STONE | 2 massing |
| plinth, pedestal, cornice | 3 boxes | 2.9, 2.3, 2.8 m square | 1.2..5.7 m | M_STONE | 2 massing |
| plaques | 4 thin boxes | 1.4 x 2 m | four faces, 2.4..4.4 m | M_STONE | 3 facade |
| figure | 2 frustums, prism, box | r 0.7 m to 0.3 m; head r 0.17 m | 5.7..8.15 m | M_STONE | 2 massing |
| lamp posts | 4 posts, 4 heads | r 0.1 m, 2.95 m high | corners, 3.6 m out | M_STONE | 6 night |
